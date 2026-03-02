import SwiftUI

enum MealFormMode {
    case create
    case edit(Meal)
}

struct MealFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: MealFormMode
    var onSave: ((Meal) -> Void)?

    @State private var name: String = ""
    @State private var mealType: MealType = .breakfast
    @State private var ingredients: String = ""
    @State private var caloriesText: String = ""
    @State private var prepNotes: String = ""
    @State private var recipeURL: String = ""
    @State private var notes: String = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var existingMeal: Meal? {
        if case .edit(let meal) = mode {
            return meal
        }
        return nil
    }

    var body: some View {
        Form {
            mealInfoSection
            nutritionSection
            preparationSection
            notesSection
        }
        .navigationTitle(isEditing ? "Edit Meal" : "New Meal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveMeal()
                }
                .disabled(name.isEmpty)
            }
        }
        .onAppear {
            loadExistingData()
        }
    }

    // MARK: - Sections

    private var mealInfoSection: some View {
        Section {
            TextField("Name", text: $name)

            Picker("Meal Type", selection: $mealType) {
                ForEach(MealType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }
        } header: {
            Text("Meal Info")
        }
    }

    private var nutritionSection: some View {
        Section {
            TextField("Calories", text: $caloriesText)
                .keyboardType(.numberPad)

            VStack(alignment: .leading) {
                Text("Ingredients")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $ingredients)
                    .frame(minHeight: 60)
            }
        } header: {
            Text("Nutrition")
        }
    }

    private var preparationSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Prep Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $prepNotes)
                    .frame(minHeight: 60)
            }

            TextField("Recipe URL", text: $recipeURL)
                .keyboardType(.URL)
                .textContentType(.URL)
                .autocapitalization(.none)
        } header: {
            Text("Preparation")
        }
    }

    private var notesSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $notes)
                    .frame(minHeight: 40)
            }
        } header: {
            Text("Notes")
        }
    }

    // MARK: - Data Loading

    private func loadExistingData() {
        guard let meal = existingMeal else { return }

        name = meal.name
        mealType = meal.mealType
        ingredients = meal.ingredients
        if let calories = meal.calories {
            caloriesText = String(calories)
        }
        prepNotes = meal.prepNotes
        recipeURL = meal.recipeURL
        notes = meal.notes
    }

    // MARK: - Save

    private func saveMeal() {
        if let existing = existingMeal {
            existing.name = name
            existing.mealType = mealType
            existing.ingredients = ingredients
            existing.calories = Int(caloriesText)
            existing.prepNotes = prepNotes
            existing.recipeURL = recipeURL
            existing.notes = notes
            onSave?(existing)
        } else {
            let meal = Meal(name: name, mealType: mealType)
            meal.ingredients = ingredients
            meal.calories = Int(caloriesText)
            meal.prepNotes = prepNotes
            meal.recipeURL = recipeURL
            meal.notes = notes
            onSave?(meal)
        }

        dismiss()
    }
}
