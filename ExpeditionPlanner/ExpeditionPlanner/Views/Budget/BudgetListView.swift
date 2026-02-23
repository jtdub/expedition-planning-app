import SwiftUI
import SwiftData

struct BudgetListView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Bindable var expedition: Expedition

    @State private var viewModel: BudgetViewModel?
    @State private var showingAddSheet = false
    @State private var selectedItem: BudgetItem?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                budgetList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.budgetItems.isEmpty {
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
                    viewModel?.loadBudgetItems(for: expedition)
                }
            ),
            prompt: "Search budget items"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    BudgetItemFormView(
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
                    BudgetItemFormView(
                        mode: .edit(item),
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = BudgetViewModel(modelContext: modelContext)
            }
            viewModel?.loadBudgetItems(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func budgetList(viewModel: BudgetViewModel) -> some View {
        if viewModel.budgetItems.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Budget Items", systemImage: "dollarsign.circle")
            } description: {
                Text("Add budget items to track expedition expenses.")
            } actions: {
                Button("Add Budget Item") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.budgetItems.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            List {
                // Summary section
                Section {
                    BudgetSummaryView(viewModel: viewModel)
                }

                // Filter indicator
                if viewModel.hasActiveFilters {
                    Section {
                        filterIndicator(viewModel: viewModel)
                    }
                }

                // Grouped by category
                ForEach(viewModel.groupedByCategory, id: \.category) { group in
                    Section {
                        ForEach(group.items) { item in
                            BudgetRowView(item: item, viewModel: viewModel)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedItem = item
                                }
                        }
                        .onDelete { indexSet in
                            deleteItems(at: indexSet, from: group.items, viewModel: viewModel)
                        }

                        // Category subtotal
                        if let totals = viewModel.categoryTotals[group.category] {
                            HStack {
                                Text("Subtotal")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(viewModel.formatCurrency(totals.estimated))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: group.category.icon)
                            Text(group.category.rawValue)
                            Text("(\(group.items.count))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Filter Indicator

    private func filterIndicator(viewModel: BudgetViewModel) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.blue)
            Text(filterDescription(viewModel: viewModel))
                .font(.subheadline)
            Spacer()
            Button("Clear") {
                viewModel.clearFilters()
                viewModel.loadBudgetItems(for: expedition)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    private func filterDescription(viewModel: BudgetViewModel) -> String {
        var parts: [String] = []
        if let category = viewModel.filterCategory {
            parts.append(category.rawValue)
        }
        if viewModel.filterPaidOnly {
            parts.append("Paid")
        }
        if viewModel.filterUnpaidOnly {
            parts.append("Unpaid")
        }
        if !viewModel.searchText.isEmpty {
            parts.append("\"\(viewModel.searchText)\"")
        }
        return parts.isEmpty ? "Filtered" : parts.joined(separator: " · ")
    }

    // MARK: - Filter Menu

    @ViewBuilder
    private func filterMenu(viewModel: BudgetViewModel) -> some View {
        Menu {
            Button {
                viewModel.clearFilters()
                viewModel.loadBudgetItems(for: expedition)
            } label: {
                Label(
                    "Clear Filters",
                    systemImage: viewModel.hasActiveFilters ? "" : "checkmark"
                )
            }

            Divider()

            Button {
                viewModel.filterPaidOnly.toggle()
                viewModel.filterUnpaidOnly = false
                viewModel.loadBudgetItems(for: expedition)
            } label: {
                Label("Paid Only", systemImage: viewModel.filterPaidOnly ? "checkmark" : "")
            }

            Button {
                viewModel.filterUnpaidOnly.toggle()
                viewModel.filterPaidOnly = false
                viewModel.loadBudgetItems(for: expedition)
            } label: {
                Label("Unpaid Only", systemImage: viewModel.filterUnpaidOnly ? "checkmark" : "")
            }

            Divider()

            // Category filter
            Menu("Category") {
                Button {
                    viewModel.filterCategory = nil
                    viewModel.loadBudgetItems(for: expedition)
                } label: {
                    Label("All Categories", systemImage: viewModel.filterCategory == nil ? "checkmark" : "")
                }

                Divider()

                ForEach(BudgetCategory.allCases, id: \.self) { category in
                    Button {
                        viewModel.filterCategory = category
                        viewModel.loadBudgetItems(for: expedition)
                    } label: {
                        Label {
                            Text(category.rawValue)
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

            Divider()

            // Sort options
            Menu("Sort By") {
                ForEach(BudgetSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadBudgetItems(for: expedition)
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

    private func deleteItems(
        at indexSet: IndexSet,
        from items: [BudgetItem],
        viewModel: BudgetViewModel
    ) {
        for index in indexSet {
            viewModel.deleteBudgetItem(items[index], from: expedition)
        }
    }
}

#Preview {
    NavigationStack {
        BudgetListView(expedition: Expedition(name: "Test Expedition"))
    }
    .modelContainer(for: [Expedition.self, BudgetItem.self], inMemory: true)
}
