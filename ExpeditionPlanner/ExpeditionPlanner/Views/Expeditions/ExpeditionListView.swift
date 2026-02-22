import SwiftUI
import SwiftData

struct ExpeditionListView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \Expedition.startDate, order: .reverse)
    private var expeditions: [Expedition]

    @ObservedObject private var syncService = SyncStatusService.shared

    @State private var showingNewExpedition = false
    @State private var searchText = ""

    var filteredExpeditions: [Expedition] {
        if searchText.isEmpty {
            return expeditions
        }
        return expeditions.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if expeditions.isEmpty {
                    ContentUnavailableView {
                        Label("No Expeditions", systemImage: "map")
                    } description: {
                        Text("Create your first expedition to get started.")
                    } actions: {
                        Button("New Expedition") {
                            showingNewExpedition = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(filteredExpeditions) { expedition in
                            NavigationLink(value: expedition) {
                                ExpeditionRowView(expedition: expedition)
                            }
                        }
                        .onDelete(perform: deleteExpeditions)
                    }
                    .searchable(text: $searchText, prompt: "Search expeditions")
                }
            }
            .navigationTitle("Expeditions")
            .navigationDestination(for: Expedition.self) { expedition in
                ExpeditionDetailView(expedition: expedition)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SyncStatusView(syncService: syncService)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewExpedition = true
                    } label: {
                        Label("New Expedition", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewExpedition) {
                ExpeditionFormView(mode: .create)
            }
        }
    }

    private func deleteExpeditions(at offsets: IndexSet) {
        for index in offsets {
            let expedition = filteredExpeditions[index]
            modelContext.delete(expedition)
        }
    }
}

// MARK: - Expedition Row View

struct ExpeditionRowView: View {
    let expedition: Expedition

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(expedition.name)
                    .font(.headline)
                Spacer()
                StatusBadge(status: expedition.status)
            }

            if !expedition.location.isEmpty {
                Label(expedition.location, systemImage: "mappin")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let startDate = expedition.startDate {
                HStack {
                    Label(startDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    if let endDate = expedition.endDate {
                        Text("–")
                        Text(endDate.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                if expedition.participantCount > 0 {
                    Label("\(expedition.participantCount)", systemImage: "person.2")
                }
                if let itinerary = expedition.itinerary, !itinerary.isEmpty {
                    Label("\(itinerary.count) days", systemImage: "calendar.day.timeline.left")
                }
                if let gearItems = expedition.gearItems, !gearItems.isEmpty {
                    Label("\(gearItems.count)", systemImage: "backpack")
                }
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: ExpeditionStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
            Text(status.rawValue)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .foregroundStyle(statusColor)
        .clipShape(Capsule())
    }

    var statusColor: Color {
        switch status.color {
        case "blue": return .blue
        case "orange": return .orange
        case "green": return .green
        case "gray": return .gray
        case "red": return .red
        default: return .blue
        }
    }
}

#Preview {
    ExpeditionListView()
        .modelContainer(for: Expedition.self, inMemory: true)
}
