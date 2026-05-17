import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var settings: [UserSettings]

    var body: some View {
        if hasLocation {
            placeholder
        } else {
            LocationPermissionView()
        }
    }

    /// Location is "set" once we have a UserSettings row with non-zero coordinates.
    private var hasLocation: Bool {
        guard let s = settings.first else { return false }
        return s.latitude != 0 || s.longitude != 0
    }

    // Temporary screen shown once location is set. Replaced by the real Today view
    // in the next step.
    private var placeholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("Location set")
                .font(.title2).bold()
            if let s = settings.first {
                VStack(spacing: 4) {
                    if !s.city.isEmpty || !s.country.isEmpty {
                        Text("\(s.city), \(s.country)".trimmingCharacters(in: CharacterSet(charactersIn: " ,")))
                            .font(.subheadline)
                    }
                    Text("\(s.latitude, specifier: "%.4f"), \(s.longitude, specifier: "%.4f")")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Text(s.timezone)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text("Next: compute prayer times for today")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 20)
        }
        .padding()
    }
}

#Preview("No location (permission gate)") {
    ContentView()
        .modelContainer(PreviewContainer.makeEmptyContainer())
}

#Preview("Location set (placeholder)") {
    ContentView()
        .modelContainer(PreviewContainer.shared)
}
