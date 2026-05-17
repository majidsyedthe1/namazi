import SwiftUI
import SwiftData

// Per-prayer notification settings. One row per daily prayer.

struct NotificationPreferencesView: View {
    @Query(sort: \NotificationPreference.prayerName) private var prefs: [NotificationPreference]

    var body: some View {
        Form {
            ForEach(orderedPrefs) { pref in
                Section(pref.prayer.displayName) {
                    Toggle(isOn: Binding(
                        get: { pref.enabled },
                        set: { pref.enabled = $0 }
                    )) {
                        Label("Enabled", systemImage: "bell.fill")
                    }

                    Picker(selection: Binding(
                        get: { pref.timingValue },
                        set: { pref.timingValue = $0 }
                    )) {
                        Text("At start").tag(NotificationTiming.atStart)
                        Text("Minutes after start").tag(NotificationTiming.minutesAfterStart)
                        Text("Minutes before end").tag(NotificationTiming.minutesBeforeEnd)
                    } label: {
                        Label("Timing", systemImage: "clock")
                    }
                    .disabled(!pref.enabled)

                    if pref.timingValue != .atStart {
                        Stepper(
                            value: Binding(
                                get: { pref.minutesOffset },
                                set: { pref.minutesOffset = $0 }
                            ),
                            in: 1...30
                        ) {
                            HStack {
                                Label("Offset", systemImage: "timer")
                                Spacer()
                                Text("\(pref.minutesOffset) min")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(!pref.enabled)
                    }

                    Toggle(isOn: Binding(
                        get: { pref.soundEnabled },
                        set: { pref.soundEnabled = $0 }
                    )) {
                        Label(pref.soundEnabled ? "Sound" : "Vibration only",
                              systemImage: pref.soundEnabled ? "speaker.wave.2.fill" : "iphone.radiowaves.left.and.right")
                    }
                    .disabled(!pref.enabled)

                    if pref.soundEnabled {
                        Picker(selection: Binding(
                            get: { pref.sound ?? .defaultSound },
                            set: { pref.sound = $0 }
                        )) {
                            Text("Makkah").tag(AdhanSound.makkah)
                            Text("Madinah").tag(AdhanSound.madinah)
                            Text("Default").tag(AdhanSound.defaultSound)
                        } label: {
                            Label("Adhan", systemImage: "music.note")
                        }
                        .disabled(!pref.enabled)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    /// Order by daily prayer order rather than alphabetical.
    private var orderedPrefs: [NotificationPreference] {
        let order = PrayerName.fiveDaily.map { $0.rawValue }
        return prefs.sorted {
            (order.firstIndex(of: $0.prayerName) ?? .max) < (order.firstIndex(of: $1.prayerName) ?? .max)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationPreferencesView()
    }
    .modelContainer(PreviewContainer.shared)
}
