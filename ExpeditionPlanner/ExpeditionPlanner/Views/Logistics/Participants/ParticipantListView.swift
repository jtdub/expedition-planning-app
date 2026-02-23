import SwiftUI
import SwiftData

struct ParticipantListView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Bindable var expedition: Expedition

    @State private var viewModel: ParticipantViewModel?
    @State private var showingAddSheet = false
    @State private var selectedParticipant: Participant?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                participantList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Participants")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.participants.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu(viewModel: viewModel)
                }
            }
        }
        .searchable(
            text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { newValue in
                    viewModel?.searchText = newValue
                    viewModel?.loadParticipants(for: expedition)
                }
            ),
            prompt: "Search participants"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    ParticipantFormView(
                        mode: .create,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(item: $selectedParticipant) { participant in
            if let viewModel = viewModel {
                NavigationStack {
                    ParticipantDetailView(
                        participant: participant,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ParticipantViewModel(modelContext: modelContext)
            }
            viewModel?.loadParticipants(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func participantList(viewModel: ParticipantViewModel) -> some View {
        if viewModel.participants.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Participants", systemImage: "person.2")
            } description: {
                Text("Add participants to track your expedition team.")
            } actions: {
                Button("Add Participant") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.participants.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            List {
                // Summary section
                Section {
                    summaryRow(viewModel: viewModel)
                }

                // Filter indicator
                if viewModel.hasActiveFilters {
                    Section {
                        filterIndicator(viewModel: viewModel)
                    }
                }

                // Grouped content
                ForEach(viewModel.groupedByRole, id: \.role) { group in
                    Section {
                        ForEach(group.participants) { participant in
                            ParticipantRowView(participant: participant)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedParticipant = participant
                                }
                        }
                        .onDelete { indexSet in
                            deleteParticipants(at: indexSet, from: group.participants, viewModel: viewModel)
                        }
                    } header: {
                        HStack {
                            Image(systemName: group.role.icon)
                            Text(group.role.rawValue)
                            Text("(\(group.participants.count))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary Row

    private func summaryRow(viewModel: ParticipantViewModel) -> some View {
        HStack(spacing: 16) {
            StatBadge(
                value: "\(viewModel.participants.count)",
                label: "Total",
                icon: "person.2",
                color: .blue
            )
            StatBadge(
                value: "\(viewModel.confirmedCount)",
                label: "Confirmed",
                icon: "checkmark.circle",
                color: .green
            )
            StatBadge(
                value: "\(viewModel.staffCount)",
                label: "Staff",
                icon: "star",
                color: .orange
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Filter Indicator

    private func filterIndicator(viewModel: ParticipantViewModel) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.blue)
            Text(filterDescription(viewModel: viewModel))
                .font(.subheadline)
            Spacer()
            Button("Clear") {
                viewModel.clearFilters()
                viewModel.loadParticipants(for: expedition)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    private func filterDescription(viewModel: ParticipantViewModel) -> String {
        var parts: [String] = []
        if let role = viewModel.filterRole {
            parts.append(role.rawValue)
        }
        if let group = viewModel.filterGroup {
            parts.append(group)
        }
        if !viewModel.searchText.isEmpty {
            parts.append("\"\(viewModel.searchText)\"")
        }
        return parts.isEmpty ? "Filtered" : parts.joined(separator: " · ")
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: ParticipantViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilters()
                viewModel.loadParticipants(for: expedition)
            } label: {
                Label(
                    "Clear Filters",
                    systemImage: viewModel.hasActiveFilters ? "" : "checkmark"
                )
            }

            Divider()

            // Role filter
            Menu("Role") {
                Button {
                    viewModel.filterRole = nil
                    viewModel.loadParticipants(for: expedition)
                } label: {
                    Label("All Roles", systemImage: viewModel.filterRole == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(ParticipantRole.allCases, id: \.self) { role in
                    Button {
                        viewModel.filterRole = role
                        viewModel.loadParticipants(for: expedition)
                    } label: {
                        Label {
                            Text(role.rawValue)
                        } icon: {
                            if viewModel.filterRole == role {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: role.icon)
                            }
                        }
                    }
                }
            }

            // Group filter
            if !viewModel.uniqueGroups.isEmpty {
                Menu("Group") {
                    Button {
                        viewModel.filterGroup = nil
                        viewModel.loadParticipants(for: expedition)
                    } label: {
                        Label("All Groups", systemImage: viewModel.filterGroup == nil ? "checkmark" : "")
                    }

                    Divider()

                    ForEach(viewModel.uniqueGroups, id: \.self) { group in
                        Button {
                            viewModel.filterGroup = group
                            viewModel.loadParticipants(for: expedition)
                        } label: {
                            Label(
                                group,
                                systemImage: viewModel.filterGroup == group ? "checkmark" : ""
                            )
                        }
                    }
                }
            }

            Divider()

            // Sort options
            Menu("Sort By") {
                ForEach(ParticipantSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadParticipants(for: expedition)
                    } label: {
                        Label(
                            order.rawValue,
                            systemImage: viewModel.sortOrder == order ? "checkmark" : ""
                        )
                    }
                }
            }
        } label: {
            Image(systemName: viewModel.hasActiveFilters
                ? "line.3.horizontal.decrease.circle.fill"
                : "line.3.horizontal.decrease.circle")
        }
    }

    // MARK: - Delete

    private func deleteParticipants(
        at indexSet: IndexSet,
        from participants: [Participant],
        viewModel: ParticipantViewModel
    ) {
        for index in indexSet {
            viewModel.deleteParticipant(participants[index], from: expedition)
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ParticipantListView(expedition: Expedition(name: "Test Expedition"))
    }
    .modelContainer(for: [Expedition.self, Participant.self], inMemory: true)
}
