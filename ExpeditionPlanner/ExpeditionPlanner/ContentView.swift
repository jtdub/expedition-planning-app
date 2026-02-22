import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext)
    private var modelContext

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ExpeditionListView()
                .tabItem {
                    Label("Expeditions", systemImage: "map")
                }
                .tag(0)

            GearLibraryView()
                .tabItem {
                    Label("Gear Library", systemImage: "backpack")
                }
                .tag(1)

            TemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "doc.on.doc")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

// MARK: - Placeholder Views

struct GearLibraryView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Gear Library",
                systemImage: "backpack",
                description: Text("Gear library coming in Phase 3")
            )
            .navigationTitle("Gear Library")
        }
    }
}

struct TemplatesView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Templates",
                systemImage: "doc.on.doc",
                description: Text("Templates coming in Phase 5")
            )
            .navigationTitle("Templates")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Expedition.self, inMemory: true)
}
