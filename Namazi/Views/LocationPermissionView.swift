import SwiftUI
import SwiftData
import CoreLocation

// Onboarding screen shown when the user has no saved location yet.
// Explains *why* we need location, then triggers the system prompt.
//
// On a successful fix: writes lat/long/timezone to UserSettings (creating the
// singleton row if it doesn't exist) — ContentView then flips to the next screen.

struct LocationPermissionView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [UserSettings]
    @State private var locationService = LocationService()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "location.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.indigo)
                .padding(.bottom, 24)

            Text("Enable Location")
                .font(.largeTitle).bold()
                .padding(.bottom, 12)

            Text("Namazi uses your location to calculate accurate prayer times for your city.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button(action: handlePrimaryTap) {
                    Text(primaryButtonTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.indigo, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }

                if locationService.authState == .denied {
                    Text("Location was denied. Open Settings to enable it.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if let error = locationService.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onChange(of: locationService.lastFix) { _, newFix in
            guard let newFix else { return }
            saveLocation(newFix)
        }
    }

    private var primaryButtonTitle: String {
        switch locationService.authState {
        case .notDetermined: return "Allow Location"
        case .denied: return "Open Settings"
        case .authorized: return "Getting your location…"
        }
    }

    private func handlePrimaryTap() {
        switch locationService.authState {
        case .notDetermined:
            locationService.requestPermission()
        case .denied:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .authorized:
            locationService.requestLocation()
        }
    }

    private func saveLocation(_ fix: LocationFix) {
        // Save coords immediately so the gate flips even if geocoding fails.
        let s = upsertSettings()
        s.latitude = fix.latitude
        s.longitude = fix.longitude
        s.lastUpdated = Date()
        try? context.save()

        // Then reverse-geocode for timezone/city/country and patch in the results.
        Task { @MainActor in
            let placemark = await locationService.reverseGeocode(fix)
            s.timezone = placemark?.timeZone?.identifier ?? TimeZone.current.identifier
            s.city = placemark?.locality ?? placemark?.administrativeArea ?? ""
            s.country = placemark?.country ?? ""
            s.lastUpdated = Date()
            try? context.save()
        }
    }

    private func upsertSettings() -> UserSettings {
        if let existing = settings.first { return existing }
        let s = UserSettings(
            userId: UUID(),
            latitude: 0,
            longitude: 0,
            timezone: TimeZone.current.identifier,
            city: "",
            country: ""
        )
        context.insert(s)
        return s
    }
}

#Preview {
    LocationPermissionView()
}
