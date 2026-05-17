import SwiftUI
import SwiftData

// Phase 2: app runs against the in-memory mock container so all UIs render with
// realistic 12-month data. In Phase 3, swap `PreviewContainer.shared` for a real
// on-disk ModelContainer.

@main
struct NamaziApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(PreviewContainer.shared)
    }
}
