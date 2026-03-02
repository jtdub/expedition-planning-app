import SwiftUI
import SwiftData

struct MealPlanListView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Bindable var expedition: Expedition

    @State private var viewModel: MealPlanViewModel?
    @State private var showingAddSheet = false
    @State private var selectedPlan: MealPlan?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                planList(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Meal Planning")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            if let viewModel = viewModel, !viewModel.mealPlans.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    sortMenu(viewModel: viewModel)
                }
            }
        }
        .searchable(
            text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { newValue in
                    viewModel?.searchText = newValue
                    viewModel?.loadMealPlans(for: expedition)
                }
            ),
            prompt: "Search meal plans"
        )
        .sheet(isPresented: $showingAddSheet) {
            if let viewModel = viewModel {
                NavigationStack {
                    MealPlanFormView(
                        mode: .create,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .sheet(item: $selectedPlan) { plan in
            if let viewModel = viewModel {
                NavigationStack {
                    MealPlanDetailView(
                        plan: plan,
                        expedition: expedition,
                        viewModel: viewModel
                    )
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = MealPlanViewModel(modelContext: modelContext)
            }
            viewModel?.loadMealPlans(for: expedition)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func planList(viewModel: MealPlanViewModel) -> some View {
        if viewModel.mealPlans.isEmpty && !viewModel.hasActiveFilters {
            ContentUnavailableView {
                Label("No Meal Plans", systemImage: "fork.knife")
            } description: {
                Text("Plan meals for each day to estimate food weight and nutrition.")
            } actions: {
                Button("Add Meal Plan") {
                    showingAddSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else if viewModel.mealPlans.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            List {
                // Summary section
                Section {
                    summaryView(viewModel: viewModel)
                }

                // Plans list
                ForEach(viewModel.mealPlans) { plan in
                    MealPlanRowView(plan: plan)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPlan = plan
                        }
                }
                .onDelete { indexSet in
                    deletePlans(at: indexSet, viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Summary View

    private func summaryView(viewModel: MealPlanViewModel) -> some View {
        HStack(spacing: 16) {
            MealPlanStatBadge(
                value: "\(viewModel.mealPlans.count)",
                label: "Days Planned",
                icon: "calendar",
                color: .blue
            )
            MealPlanStatBadge(
                value: "\(viewModel.averageCaloriesPerDay)",
                label: "Avg Cal/Day",
                icon: "flame",
                color: .orange
            )
            MealPlanStatBadge(
                value: "\(viewModel.totalCaloriesAllDays)",
                label: "Total Cal",
                icon: "fork.knife",
                color: .green
            )
        }
        .padding(.vertical, 4)
    }

    // MARK: - Sort Menu

    @ViewBuilder
    private func sortMenu(viewModel: MealPlanViewModel) -> some View {
        Menu {
            Menu("Sort By") {
                ForEach(MealPlanSortOrder.allCases, id: \.self) { order in
                    Button {
                        viewModel.sortOrder = order
                        viewModel.loadMealPlans(for: expedition)
                    } label: {
                        Label(
                            order.rawValue,
                            systemImage: viewModel.sortOrder == order ? "checkmark" : ""
                        )
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }

    // MARK: - Delete

    private func deletePlans(
        at indexSet: IndexSet,
        viewModel: MealPlanViewModel
    ) {
        for index in indexSet {
            viewModel.deleteMealPlan(viewModel.mealPlans[index], from: expedition)
        }
    }
}

// MARK: - Stat Badge

struct MealPlanStatBadge: View {
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
