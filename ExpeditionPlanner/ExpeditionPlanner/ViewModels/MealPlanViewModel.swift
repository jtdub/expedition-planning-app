import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.expedition.planner", category: "MealPlanViewModel")

enum MealPlanSortOrder: String, CaseIterable {
    case dayNumber = "Day Number"
    case calories = "Calories"
    case mealCount = "Meal Count"
}

@Observable
final class MealPlanViewModel {
    private var modelContext: ModelContext

    var mealPlans: [MealPlan] = []
    var searchText: String = ""
    var sortOrder: MealPlanSortOrder = .dayNumber
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadMealPlans(for expedition: Expedition) {
        let allPlans = expedition.mealPlans ?? []

        var filtered = allPlans

        if !searchText.isEmpty {
            filtered = filtered.filter { plan in
                plan.dayLabel.localizedCaseInsensitiveContains(searchText) ||
                plan.notes.localizedCaseInsensitiveContains(searchText) ||
                (plan.meals ?? []).contains { meal in
                    meal.name.localizedCaseInsensitiveContains(searchText)
                }
            }
        }

        switch sortOrder {
        case .dayNumber:
            mealPlans = filtered.sorted { $0.dayNumber < $1.dayNumber }
        case .calories:
            mealPlans = filtered.sorted { $0.totalCalories > $1.totalCalories }
        case .mealCount:
            mealPlans = filtered.sorted { $0.mealCount > $1.mealCount }
        }
    }

    // MARK: - MealPlan CRUD

    func addMealPlan(_ plan: MealPlan, to expedition: Expedition) {
        plan.expedition = expedition
        if expedition.mealPlans == nil {
            expedition.mealPlans = []
        }
        expedition.mealPlans?.append(plan)
        modelContext.insert(plan)

        logger.info("Added meal plan '\(plan.dayLabel)' to expedition")
        saveContext()
        loadMealPlans(for: expedition)
    }

    func deleteMealPlan(_ plan: MealPlan, from expedition: Expedition) {
        let label = plan.dayLabel
        expedition.mealPlans?.removeAll { $0.id == plan.id }
        modelContext.delete(plan)

        logger.info("Deleted meal plan '\(label)' from expedition")
        saveContext()
        loadMealPlans(for: expedition)
    }

    func updateMealPlan(_ plan: MealPlan, in expedition: Expedition) {
        logger.debug("Updated meal plan '\(plan.dayLabel)'")
        saveContext()
        loadMealPlans(for: expedition)
    }

    // MARK: - Meal CRUD

    func addMeal(_ meal: Meal, to plan: MealPlan) {
        meal.mealPlan = plan
        if plan.meals == nil {
            plan.meals = []
        }
        plan.meals?.append(meal)
        modelContext.insert(meal)

        logger.info("Added meal '\(meal.name)' to \(plan.dayLabel)")
        saveContext()
    }

    func deleteMeal(_ meal: Meal, from plan: MealPlan) {
        let name = meal.name
        plan.meals?.removeAll { $0.id == meal.id }
        modelContext.delete(meal)

        logger.info("Deleted meal '\(name)' from \(plan.dayLabel)")
        saveContext()
    }

    // MARK: - Computed Properties

    var totalCaloriesAllDays: Int {
        mealPlans.reduce(0) { $0 + $1.totalCalories }
    }

    var averageCaloriesPerDay: Int {
        guard !mealPlans.isEmpty else { return 0 }
        return totalCaloriesAllDays / mealPlans.count
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
    }

    var hasActiveFilters: Bool {
        !searchText.isEmpty
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save meal plan changes: \(error.localizedDescription)")
        }
    }
}
