import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsList: [UserSettings]

    var body: some View {
        NavigationStack {
            Group {
                if let settings = settingsList.first {
                    Form {
                        locationSection(settings: settings)
                        prayerTimesSection(settings: settings)
                        travelSection(settings: settings)
                        Section("Notifications") {
                            NavigationLink {
                                NotificationPreferencesView()
                            } label: {
                                Label("Per-prayer preferences", systemImage: "bell.badge.fill")
                            }
                        }
                        aboutSection
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.black.ignoresSafeArea())
                } else {
                    ContentUnavailableView(
                        "No settings found",
                        systemImage: "gearshape",
                        description: Text("UserSettings is missing from the container.")
                    )
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    private func locationSection(settings: UserSettings) -> some View {
        Section("Location") {
            HStack {
                Label("City", systemImage: "location.fill")
                Spacer()
                Text("\(settings.city), \(settings.country)")
                    .foregroundStyle(.secondary)
            }
            Toggle(isOn: bindToggle(for: settings, keyPath: \.locationAutoDetect)) {
                Label("Auto-detect (GPS)", systemImage: "scope")
            }
            HStack {
                Text("Timezone")
                Spacer()
                Text(settings.timezone).foregroundStyle(.secondary)
            }
        }
    }

    private func prayerTimesSection(settings: UserSettings) -> some View {
        Section("Prayer Times") {
            Picker(selection: bindPicker(for: settings, get: \.method, set: { $0.method = $1 })) {
                ForEach(CalculationMethod.allCases, id: \.self) { m in
                    Text(m.rawValue).tag(m)
                }
            } label: {
                Label("Calculation method", systemImage: "function")
            }

            Picker(selection: bindPicker(for: settings, get: \.madhabValue, set: { $0.madhabValue = $1 })) {
                ForEach(Madhab.allCases, id: \.self) { m in
                    Text(m.rawValue).tag(m)
                }
            } label: {
                Label("Madhab (Asr calc)", systemImage: "book.closed.fill")
            }

            Toggle(isOn: bindToggle(for: settings, keyPath: \.highLatitudeMode)) {
                Label("High-latitude mode", systemImage: "globe.europe.africa.fill")
            }
        }
    }

    private func travelSection(settings: UserSettings) -> some View {
        Section {
            Toggle(isOn: bindToggle(for: settings, keyPath: \.isTravelMode)) {
                Label("Travel mode (Qasr)", systemImage: "airplane")
            }
        } footer: {
            Text("When on, four-rakat fard prayers are shortened to two.")
                .foregroundStyle(.secondary)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("Version", systemImage: "app.badge")
                Spacer()
                Text("1.0 (mock)").foregroundStyle(.secondary)
            }
            HStack {
                Label("Storage", systemImage: "internaldrive.fill")
                Spacer()
                Text("In-memory").foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Binding helpers

    private func bindToggle(for settings: UserSettings, keyPath: ReferenceWritableKeyPath<UserSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { settings[keyPath: keyPath] = $0 }
        )
    }

    private func bindPicker<Value>(
        for settings: UserSettings,
        get: @escaping (UserSettings) -> Value,
        set: @escaping (UserSettings, Value) -> Void
    ) -> Binding<Value> {
        Binding(
            get: { get(settings) },
            set: { set(settings, $0) }
        )
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewContainer.shared)
}
