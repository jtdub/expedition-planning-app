import SwiftUI
import SwiftData

struct MealPlanDetailView: View {
    @Environment(\.dismiss)
    private var dismiss

    let plan: MealPlan
    let expedition: Expedition
    var viewModel: MealPlanViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingAddMealSheet = false
    @State private var editingMeal: Meal?

    var body: some View {
        List {
            // Header
            Section {
                headerView
            }

            // Meals
            Section {
                mealsSection
            } header: {
                Text("Meals (\(plan.mealCount))")
            }

            // Notes
            if !plan.notes.isEmpty {
                Section {
                    Text(plan.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Actions
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Meal Plan", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Plan Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                MealPlanFormView(
                    mode: .edit(plan),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .sheet(isPresented: $showingAddMealSheet) {
            NavigationStack {
                MealFormView(
                    mode: .create,
                    onSave: { meal in
                        viewModel.addMeal(meal, to: plan)
                    }
                )
            }
        }
        .sheet(item: $editingMeal) { meal in
            NavigationStack {
                MealFormView(mode: .edit(meal))
            }
        }
        .alert("Delete Meal Plan?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteMealPlan(plan, from: expedition)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 16) {
            VStack {
                Image(systemName: "fork.knife")
                    .font(.title)
                    .foregroundStyle(.orange)
            }
            .frame(width: 60, height: 60)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(plan.dayLabel)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(plan.mealCount) meals")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if plan.totalCalories > 0 {
                    Text("\(plan.totalCalories) calories")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Meals

    private var mealsSection: some View {
        Group {
            ForEach(plan.sortedMeals) { meal in
                HStack(spacing: 12) {
                    Image(systemName: meal.mealType.icon)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.name)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(meal.mealType.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let calories = meal.calories {
                        Text("\(calories) cal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    editingMeal = meal
                }
            }
            .onDelete { indexSet in
                deleteMeals(at: indexSet)
            }

            Button {
                showingAddMealSheet = true
            } label: {
                Label("Add Meal", systemImage: "plus.circle")
            }
        }
    }

    // MARK: - Delete

    private func deleteMeals(at indexSet: IndexSet) {
        let sorted = plan.sortedMeals
        for index in indexSet {
            viewModel.deleteMeal(sorted[index], from: plan)
        }
    }
}
