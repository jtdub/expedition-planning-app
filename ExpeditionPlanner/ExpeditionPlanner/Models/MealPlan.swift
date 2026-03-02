import Foundation
import SwiftData

// MARK: - Meal Type

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case morningSnack = "Morning Snack"
    case lunch = "Lunch"
    case afternoonSnack = "Afternoon Snack"
    case dinner = "Dinner"

    var icon: String {
        switch self {
        case .breakfast: return "sun.horizon"
        case .morningSnack: return "cup.and.saucer"
        case .lunch: return "sun.max"
        case .afternoonSnack: return "takeoutbag.and.cup.and.straw"
        case .dinner: return "moon.stars"
        }
    }

    var sortOrder: Int {
        switch self {
        case .breakfast: return 0
        case .morningSnack: return 1
        case .lunch: return 2
        case .afternoonSnack: return 3
        case .dinner: return 4
        }
    }
}

// MARK: - Meal Plan Model

@Model
final class MealPlan {
    var id: UUID = UUID()
    var dayNumber: Int = 1
    var notes: String = ""

    // Relationships
    var expedition: Expedition?

    @Relationship(deleteRule: .cascade, inverse: \Meal.mealPlan)
    var meals: [Meal]?

    init(dayNumber: Int = 1) {
        self.id = UUID()
        self.dayNumber = dayNumber
    }

    // MARK: - Computed Properties

    var sortedMeals: [Meal] {
        (meals ?? []).sorted { $0.mealType.sortOrder < $1.mealType.sortOrder }
    }

    var mealCount: Int {
        (meals ?? []).count
    }

    var totalCalories: Int {
        (meals ?? []).compactMap { $0.calories }.reduce(0, +)
    }

    var dayLabel: String {
        "Day \(dayNumber)"
    }
}

// MARK: - Meal Model

@Model
final class Meal {
    var id: UUID = UUID()
    var name: String = ""
    var mealType: MealType = MealType.breakfast
    var ingredients: String = ""
    var calories: Int?
    var prepNotes: String = ""
    var recipeURL: String = ""
    var notes: String = ""

    // Relationships
    var mealPlan: MealPlan?

    init(
        name: String = "",
        mealType: MealType = .breakfast
    ) {
        self.id = UUID()
        self.name = name
        self.mealType = mealType
    }

    // MARK: - Computed Properties

    var ingredientsList: [String] {
        ingredients
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var hasRecipe: Bool {
        !recipeURL.isEmpty
    }
}
