import SwiftUI
import SwiftData

struct GearListView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Bindable var expedition: Expedition

    @AppStorage("weightUnit")
    private var weightUnit: WeightUnit = .pounds

    @State private var viewModel: GearViewModel?
    @State private var showingAddSheet = false
    @State private var selectedItem: GearItem?
    @State private var isEditMode = false
    @State private var showingWeightBreakdown = false

    var body: some View {
        Group {
            if let viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Gear List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if viewModel?.itemCount ?? 0 > 0 {
                    Button {
                        isEditMode.toggle()
                    } label: {
                        Text(isEditMode ? "Done" : "Edit")
                    }
                }

                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel, viewModel.itemCount > 0 {
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu(viewModel: viewModel)
                }
            }
        }
        .searchable(
            text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { viewModel?.searchText = $0 }
            ),
            prompt: "Search gear"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel {
                GearItemFormView(
                    mode: .create(expedition: expedition),
                    viewModel: viewModel
                )
            }
        }
        .sheet(item: $selectedItem) { item in
            if let viewModel {
                GearItemFormView(
                    mode: .edit(item),
                    viewModel: viewModel
                )
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = GearViewModel(expedition: expedition, modelContext: modelContext)
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private func contentView(viewModel: GearViewModel) -> some View {
        if viewModel.itemCount == 0 {
            emptyState
        } else {
            listContent(viewModel: viewModel)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Gear Items", systemImage: "backpack")
        } description: {
            Text("Add gear items to track your expedition equipment and weight.")
        } actions: {
            Button {
                showingAddSheet = true
            } label: {
                Label("Add Gear Item", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func listContent(viewModel: GearViewModel) -> some View {
        List {
            // Weight Summary Section
            Section {
                WeightSummaryView(
                    totalWeightGrams: viewModel.totalWeightGrams,
                    packedWeightGrams: viewModel.packedWeightGrams,
                    itemCount: viewModel.itemCount,
                    packedCount: viewModel.packedCount,
                    weightUnit: weightUnit
                )

                if showingWeightBreakdown {
                    weightBreakdown(viewModel: viewModel)
                }

                Button {
                    withAnimation {
                        showingWeightBreakdown.toggle()
                    }
                } label: {
                    HStack {
                        Text(showingWeightBreakdown ? "Hide Breakdown" : "Show Weight Breakdown")
                            .font(.caption)
                        Spacer()
                        Image(systemName: showingWeightBreakdown ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Weight distribution link
            if !viewModel.groupItems.isEmpty {
                NavigationLink {
                    GearWeightDistributionView(viewModel: viewModel)
                } label: {
                    Label("Weight Distribution", systemImage: "chart.bar.horizontal")
                }
            }

            // Filter indicator
            if viewModel.hasActiveFilters {
                Section {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .foregroundStyle(.blue)
                        Text(filterDescription(viewModel: viewModel))
                            .font(.subheadline)
                        Spacer()
                        Button("Clear") {
                            viewModel.clearFilters()
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                }
            }

            // Grouped by category
            ForEach(viewModel.groupedByCategory, id: \.category) { group in
                Section {
                    ForEach(group.items) { item in
                        GearRowView(
                            item: item,
                            weightUnit: weightUnit,
                            onTogglePacked: {
                                viewModel.togglePacked(item)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !isEditMode {
                                selectedItem = item
                            }
                        }
                    }
                    .onDelete { offsets in
                        viewModel.deleteItems(at: offsets, in: group.items)
                    }
                } header: {
                    categoryHeader(group.category, count: group.items.count, viewModel: viewModel)
                }
            }
        }
        .environment(\.editMode, isEditMode ? .constant(.active) : .constant(.inactive))
    }

    // MARK: - Weight Breakdown

    @ViewBuilder
    private func weightBreakdown(viewModel: GearViewModel) -> some View {
        let weights = viewModel.categoryWeightsGrams
        let sortedCategories = weights.keys.sorted { $0.sortOrder < $1.sortOrder }

        ForEach(sortedCategories, id: \.self) { category in
            if let weight = weights[category], weight > 0 {
                CategoryWeightRow(
                    category: category,
                    weightGrams: weight,
                    totalWeightGrams: viewModel.totalWeightGrams,
                    weightUnit: weightUnit
                )
            }
        }
    }

    // MARK: - Category Header

    private func categoryHeader(
        _ category: GearCategory,
        count: Int,
        viewModel: GearViewModel
    ) -> some View {
        HStack {
            Image(systemName: category.icon)
            Text(category.rawValue)
            Text("(\(count))")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: GearViewModel) -> some View {
        Menu {
            // Clear filters
            Button {
                viewModel.clearFilters()
            } label: {
                Label("Clear Filters", systemImage: viewModel.hasActiveFilters ? "" : "checkmark")
            }

            Divider()

            // Unpacked only toggle
            Button {
                viewModel.showUnpackedOnly.toggle()
            } label: {
                Label(
                    "Unpacked Only",
                    systemImage: viewModel.showUnpackedOnly ? "checkmark" : ""
                )
            }

            Divider()

            // Category submenu
            Menu("Category") {
                Button {
                    viewModel.setFilter(category: nil)
                } label: {
                    Label("All Categories", systemImage: viewModel.filterCategory == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(GearCategory.allCases, id: \.self) { category in
                    let count = viewModel.categoryItemCounts[category] ?? 0
                    if count > 0 {
                        Button {
                            viewModel.setFilter(category: category)
                        } label: {
                            Label {
                                Text("\(category.rawValue) (\(count))")
                            } icon: {
                                if viewModel.filterCategory == category {
                                    Image(systemName: "checkmark")
                                } else {
                                    Image(systemName: category.icon)
                                }
                            }
                        }
                    }
                }
            }

            // Priority submenu
            Menu("Priority") {
                Button {
                    viewModel.setFilter(priority: nil)
                } label: {
                    Label("All Priorities", systemImage: viewModel.filterPriority == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(GearPriority.allCases, id: \.self) { priority in
                    let count = viewModel.priorityItemCounts[priority] ?? 0
                    if count > 0 {
                        Button {
                            viewModel.setFilter(priority: priority)
                        } label: {
                            Label {
                                Text("\(priority.rawValue) (\(count))")
                            } icon: {
                                if viewModel.filterPriority == priority {
                                    Image(systemName: "checkmark")
                                } else {
                                    Image(systemName: priority.icon)
                                }
                            }
                        }
                    }
                }
            }

            // Ownership submenu
            Menu("Ownership") {
                Button {
                    viewModel.filterOwnership = nil
                } label: {
                    Label(
                        "All",
                        systemImage: viewModel.filterOwnership == nil ? "checkmark" : ""
                    )
                }

                Divider()

                ForEach(GearOwnershipType.allCases, id: \.self) { ownership in
                    Button {
                        viewModel.filterOwnership = ownership
                    } label: {
                        Label {
                            Text(ownership.rawValue)
                        } icon: {
                            if viewModel.filterOwnership == ownership {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: ownership.icon)
                            }
                        }
                    }
                }
            }

            Divider()

            // Sort order submenu
            Menu("Sort By") {
                ForEach(GearSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                    } label: {
                        Label(
                            order.rawValue,
                            systemImage: viewModel.sortOrder == order ? "checkmark" : ""
                        )
                    }
                }
            }
        } label: {
            let icon = viewModel.hasActiveFilters
                ? "line.3.horizontal.decrease.circle.fill"
                : "line.3.horizontal.decrease.circle"
            Image(systemName: icon)
        }
    }

    // MARK: - Helper Methods

    private func filterDescription(viewModel: GearViewModel) -> String {
        var parts: [String] = []

        if let category = viewModel.filterCategory {
            parts.append(category.rawValue)
        }

        if let priority = viewModel.filterPriority {
            parts.append(priority.rawValue)
        }

        if let ownership = viewModel.filterOwnership {
            parts.append(ownership.rawValue)
        }

        if viewModel.showUnpackedOnly {
            parts.append("Unpacked")
        }

        if !viewModel.searchText.isEmpty {
            parts.append("\"\(viewModel.searchText)\"")
        }

        return parts.isEmpty ? "Filtered" : parts.joined(separator: " · ")
    }
}

#Preview {
    NavigationStack {
        GearListView(expedition: Expedition(name: "Test Expedition"))
    }
    .modelContainer(for: [Expedition.self, GearItem.self], inMemory: true)
}
