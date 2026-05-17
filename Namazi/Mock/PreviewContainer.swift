import Foundation
import SwiftData

// In-memory SwiftData container pre-populated with 12 months of mock prayer data.
// Use in SwiftUI previews:
//
//     #Preview {
//         ContentView()
//             .modelContainer(PreviewContainer.shared)
//     }
//
// All entities live in RAM only — nothing is written to disk.

enum PreviewContainer {

    /// Shared singleton — built lazily on first access.
    static let shared: ModelContainer = makePopulatedContainer()

    /// Build a fresh in-memory container populated with mock data. Useful when a
    /// preview needs an isolated copy (e.g. mutation tests).
    static func makePopulatedContainer(
        anchor today: Date = Date(),
        seed: UInt64 = 0xC0FFEEDEADBEEF
    ) -> ModelContainer {
        let schema = Schema([
            PrayerRecord.self,
            RakatRecord.self,
            SurahRecitation.self,
            PostureEvent.self,
            UserPrayerStats.self,
            UserSettings.self,
            NotificationPreference.self,
            Goal.self
        ])
        let config = ModelConfiguration(
            "PreviewContainer",
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            MockDataGenerator.populate(context, anchor: today, seed: seed)
            try context.save()
            return container
        } catch {
            fatalError("PreviewContainer failed to initialize: \(error)")
        }
    }

    /// Empty in-memory container — useful for previews of empty / first-launch states.
    static func makeEmptyContainer() -> ModelContainer {
        let schema = Schema([
            PrayerRecord.self,
            RakatRecord.self,
            SurahRecitation.self,
            PostureEvent.self,
            UserPrayerStats.self,
            UserSettings.self,
            NotificationPreference.self,
            Goal.self
        ])
        let config = ModelConfiguration(
            "EmptyPreviewContainer",
            schema: schema,
            isStoredInMemoryOnly: true
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Empty PreviewContainer failed to initialize: \(error)")
        }
    }
}
