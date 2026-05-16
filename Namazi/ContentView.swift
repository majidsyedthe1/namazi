import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars.fill")
                .resizable()
                .font(.system(size: 60))
                .foregroundStyle(.indigo)

            Text("Namazi")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your prayer journey starts here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
