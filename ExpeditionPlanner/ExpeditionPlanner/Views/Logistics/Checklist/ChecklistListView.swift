import SwiftUI
import SwiftData

struct ChecklistListView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Bindable var expedition: Expedition

    @State private var viewModel: ChecklistViewModel?
    @State private var showingAddSheet = false
    @State private var selectedItem: ChecklistItem?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                checklistContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Pre-Departure Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.items.isEmpty {
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
                    viewModel?.loadItems(for: expedition)
                }
            ),
            prompt: "Search tasks"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    ChecklistFormView(
                        mode: .create,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            if let viewModel = viewModel {
                NavigationStack {
                    ChecklistDetailView(
                        item: item,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ChecklistViewModel(modelContext: modelContext)
            }
            viewModel?.loadItems(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func checklistContent(viewModel: ChecklistViewModel) -> some View {
        if viewModel.items.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Tasks", systemImage: "checklist")
            } description: {
                Text("Add pre-departure tasks to track your expedition preparation.")
            } actions: {
                Button("Add Task") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.items.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            List {
                // Summary stats
                Section {
                    summaryView(viewModel: viewModel)
                }

                // Filter indicator
                if viewModel.hasActiveFilters {
                    Section {
                        filterIndicator(viewModel: viewModel)
                    }
                }

                // Overdue section
                let overdue = viewModel.overdueItems(startDate: expedition.startDate)
                if !overdue.isEmpty {
                    Section {
                        ForEach(overdue) { item in
                            ChecklistRowView(
                                item: item,
                                expeditionStartDate: expedition.startDate
                            ) {
                                viewModel.toggleStatus(for: item, in: expedition)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedItem = item }
                        }
                        .onDelete { indexSet in
                            deleteItems(at: indexSet, from: overdue, viewModel: viewModel)
                        }
                    } header: {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                // Upcoming section
                let upcoming = viewModel.upcomingItems(startDate: expedition.startDate)
                if !upcoming.isEmpty {
                    Section {
                        ForEach(upcoming) { item in
                            ChecklistRowView(
                                item: item,
                                expeditionStartDate: expedition.startDate
                            ) {
                                viewModel.toggleStatus(for: item, in: expedition)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedItem = item }
                        }
                        .onDelete { indexSet in
                            deleteItems(at: indexSet, from: upcoming, viewModel: viewModel)
                        }
                    } header: {
                        Label("Upcoming (30 days)", systemImage: "calendar.badge.clock")
                    }
                }

                // Remaining items grouped by category
                let overdueIDs = Set(overdue.map(\.id))
                let upcomingIDs = Set(upcoming.map(\.id))
                let remaining = viewModel.items.filter {
                    !overdueIDs.contains($0.id) && !upcomingIDs.contains($0.id)
                }

                if !remaining.isEmpty {
                    let grouped = Dictionary(grouping: remaining) { $0.category }
                    ForEach(ChecklistCategory.allCases, id: \.self) { category in
                        if let categoryItems = grouped[category], !categoryItems.isEmpty {
                            Section {
                                ForEach(categoryItems) { item in
                                    ChecklistRowView(
                                        item: item,
                                        expeditionStartDate: expedition.startDate
                                    ) {
                                        viewModel.toggleStatus(for: item, in: expedition)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedItem = item }
                                }
                                .onDelete { indexSet in
                                    deleteItems(at: indexSet, from: categoryItems, viewModel: viewModel)
                                }
                            } header: {
                                HStack {
                                    Image(systemName: category.icon)
                                    Text(category.rawValue)
                                    Text("(\(categoryItems.count))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary View

    private func summaryView(viewModel: ChecklistViewModel) -> some View {
        HStack(spacing: 16) {
            StatBadge(
                value: "\(viewModel.items.count)",
                label: "Total",
                icon: "checklist",
                color: .blue
            )
            StatBadge(
                value: "\(viewModel.completedCount)",
                label: "Done",
                icon: "checkmark.circle.fill",
                color: .green
            )
            StatBadge(
                value: "\(viewModel.inProgressCount)",
                label: "In Progress",
                icon: "circle.dotted.circle",
                color: .orange
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Filter Indicator

    private func filterIndicator(viewModel: ChecklistViewModel) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.blue)
            Text("Filtered")
                .font(.subheadline)
            Spacer()
            Button("Clear") {
                viewModel.clearFilters()
                viewModel.loadItems(for: expedition)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: ChecklistViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilters()
                viewModel.loadItems(for: expedition)
            } label: {
                Label("Clear Filters", systemImage: viewModel.hasActiveFilters ? "" : "checkmark")
            }

            Divider()

            Menu("Status") {
                Button {
                    viewModel.filterStatus = nil
                    viewModel.loadItems(for: expedition)
                } label: {
                    Label("All Statuses", systemImage: viewModel.filterStatus == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(ChecklistStatus.allCases, id: \.self) { status in
                    Button {
                        viewModel.filterStatus = status
                        viewModel.loadItems(for: expedition)
                    } label: {
                        Label(
                            status.rawValue,
                            systemImage: viewModel.filterStatus == status ? "checkmark" : status.icon
                        )
                    }
                }
            }

            Menu("Category") {
                Button {
                    viewModel.filterCategory = nil
                    viewModel.loadItems(for: expedition)
                } label: {
                    Label("All Categories", systemImage: viewModel.filterCategory == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(ChecklistCategory.allCases, id: \.self) { category in
                    Button {
                        viewModel.filterCategory = category
                        viewModel.loadItems(for: expedition)
                    } label: {
                        Label(
                            category.rawValue,
                            systemImage: viewModel.filterCategory == category ? "checkmark" : category.icon
                        )
                    }
                }
            }

            Divider()

            Menu("Sort By") {
                ForEach(ChecklistSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadItems(for: expedition)
                    } label: {
                        Label(order.rawValue, systemImage: viewModel.sortOrder == order ? "checkmark" : "")
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

    private func deleteItems(
        at indexSet: IndexSet,
        from items: [ChecklistItem],
        viewModel: ChecklistViewModel
    ) {
        for index in indexSet {
            viewModel.deleteItem(items[index], from: expedition)
        }
    }
}

#Preview {
    NavigationStack {
        ChecklistListView(expedition: Expedition(name: "Test Expedition"))
    }
    .modelContainer(for: [Expedition.self, ChecklistItem.self], inMemory: true)
}
