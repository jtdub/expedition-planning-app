import SwiftUI
import SwiftData

enum MealPlanFormMode {
    case create
    case edit(MealPlan)
}

struct MealPlanFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: MealPlanFormMode
    let expedition: Expedition
    var viewModel: MealPlanViewModel

    // Form fields
    @State private var dayNumberText: String = ""
    @State private var notes: String = ""

    @State private var showingMealSheet = false
    @State private var editingMeal: Meal?

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var existingPlan: MealPlan? {
        if case .edit(let plan) = mode {
            return plan
        }
        return nil
    }

    var body: some View {
        Form {
            dayInfoSection
            notesSection

            if isEditing, let plan = existingPlan {
                mealsSection(plan: plan)
            }
        }
        .navigationTitle(isEditing ? "Edit Meal Plan" : "New Meal Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    savePlan()
                }
                .disabled(dayNumberText.isEmpty)
            }
        }
        .sheet(isPresented: $showingMealSheet) {
            NavigationStack {
                MealFormView(
                    mode: editingMeal.map { .edit($0) } ?? .create,
                    onSave: { meal in
                        if let plan = existingPlan, editingMeal == nil {
                            viewModel.addMeal(meal, to: plan)
                        }
                        editingMeal = nil
                    }
                )
            }
        }
        .onAppear {
            loadExistingData()
        }
    }

    // MARK: - Sections

    private var dayInfoSection: some View {
        Section {
            TextField("Day Number", text: $dayNumberText)
                .keyboardType(.numberPad)
        } header: {
            Text("Day Info")
        }
    }

    private var notesSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $notes)
                    .frame(minHeight: 60)
            }
        } header: {
            Text("Notes")
        }
    }

    private func mealsSection(plan: MealPlan) -> some View {
        Section {
            ForEach(plan.sortedMeals) { meal in
                HStack {
                    Image(systemName: meal.mealType.icon)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .frame(width: 24)
                    Text(meal.name)
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
                    showingMealSheet = true
                }
            }
            .onDelete { indexSet in
                deleteMeals(at: indexSet, from: plan)
            }

            Button {
                editingMeal = nil
                showingMealSheet = true
            } label: {
                Label("Add Meal", systemImage: "plus.circle")
            }
        } header: {
            Text("Meals (\(plan.mealCount))")
        }
    }

    // MARK: - Data Loading

    private func loadExistingData() {
        guard let plan = existingPlan else { return }

        dayNumberText = String(plan.dayNumber)
        notes = plan.notes
    }

    // MARK: - Save

    private func savePlan() {
        if let existing = existingPlan {
            existing.dayNumber = Int(dayNumberText) ?? existing.dayNumber
            existing.notes = notes

            viewModel.updateMealPlan(existing, in: expedition)
        } else {
            let plan = MealPlan(dayNumber: Int(dayNumberText) ?? 1)
            plan.notes = notes

            viewModel.addMealPlan(plan, to: expedition)
        }

        dismiss()
    }

    // MARK: - Helpers

    private func deleteMeals(at indexSet: IndexSet, from plan: MealPlan) {
        let sorted = plan.sortedMeals
        for index in indexSet {
            viewModel.deleteMeal(sorted[index], from: plan)
        }
    }
}
