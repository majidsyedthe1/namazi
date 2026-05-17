import SwiftUI
import SwiftData

// Real persistent SwiftData store. Mock data still lives in PreviewContainer
// for use inside #Preview blocks.

@main
struct NamaziApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            PrayerRecord.self,
            RakatRecord.self,
            SurahRecitation.self,
            PostureEvent.self,
            UserPrayerStats.self,
            UserSettings.self,
            NotificationPreference.self,
            Goal.self
        ])
    }
}
