import SwiftUI

// Root tab. Order chosen to mirror time-of-day flow:
//   Today (focus) → History (reflect) → Stats (progress) → Settings.

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "circle.hexagongrid.fill") }

            HistoryView()
                .tabItem { Label("History", systemImage: "square.grid.3x3.fill") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(PrayerStyle.upcoming)
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewContainer.shared)
}
