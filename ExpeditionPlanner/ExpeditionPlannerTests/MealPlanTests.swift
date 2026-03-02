import XCTest
import SwiftData
@testable import Chaki

final class MealPlanTests: XCTestCase {

    // MARK: - MealPlan Creation Tests

    func testMealPlanCreation() throws {
        let plan = MealPlan(dayNumber: 3)

        XCTAssertNotNil(plan.id)
        XCTAssertEqual(plan.dayNumber, 3)
    }

    func testMealPlanDefaultValues() throws {
        let plan = MealPlan()

        XCTAssertEqual(plan.dayNumber, 1)
        XCTAssertTrue(plan.notes.isEmpty)
        XCTAssertNil(plan.meals)
    }

    // MARK: - MealPlan Computed Properties

    func testDayLabel() throws {
        let plan = MealPlan(dayNumber: 5)
        XCTAssertEqual(plan.dayLabel, "Day 5")
    }

    func testMealCount() throws {
        let plan = MealPlan(dayNumber: 1)
        XCTAssertEqual(plan.mealCount, 0)

        plan.meals = [
            Meal(name: "Oatmeal", mealType: .breakfast),
            Meal(name: "Trail Mix", mealType: .lunch)
        ]
        XCTAssertEqual(plan.mealCount, 2)
    }

    func testTotalCalories() throws {
        let plan = MealPlan(dayNumber: 1)

        let meal1 = Meal(name: "Oatmeal", mealType: .breakfast)
        meal1.calories = 400

        let meal2 = Meal(name: "Trail Mix", mealType: .morningSnack)
        meal2.calories = 300

        let meal3 = Meal(name: "Ramen", mealType: .dinner)
        // No calories set

        plan.meals = [meal1, meal2, meal3]
        XCTAssertEqual(plan.totalCalories, 700)
    }

    func testTotalCaloriesEmpty() throws {
        let plan = MealPlan(dayNumber: 1)
        XCTAssertEqual(plan.totalCalories, 0)
    }

    func testSortedMeals() throws {
        let plan = MealPlan(dayNumber: 1)

        let dinner = Meal(name: "Pasta", mealType: .dinner)
        let breakfast = Meal(name: "Oatmeal", mealType: .breakfast)
        let lunch = Meal(name: "Wrap", mealType: .lunch)
        let snack = Meal(name: "Bar", mealType: .morningSnack)

        plan.meals = [dinner, breakfast, lunch, snack]

        let sorted = plan.sortedMeals
        XCTAssertEqual(sorted[0].mealType, .breakfast)
        XCTAssertEqual(sorted[1].mealType, .morningSnack)
        XCTAssertEqual(sorted[2].mealType, .lunch)
        XCTAssertEqual(sorted[3].mealType, .dinner)
    }

    // MARK: - Meal Creation Tests

    func testMealCreation() throws {
        let meal = Meal(name: "Oatmeal with Berries", mealType: .breakfast)

        XCTAssertNotNil(meal.id)
        XCTAssertEqual(meal.name, "Oatmeal with Berries")
        XCTAssertEqual(meal.mealType, .breakfast)
    }

    func testMealDefaultValues() throws {
        let meal = Meal()

        XCTAssertEqual(meal.mealType, .breakfast)
        XCTAssertTrue(meal.name.isEmpty)
        XCTAssertTrue(meal.ingredients.isEmpty)
        XCTAssertTrue(meal.prepNotes.isEmpty)
        XCTAssertTrue(meal.recipeURL.isEmpty)
        XCTAssertTrue(meal.notes.isEmpty)
        XCTAssertNil(meal.calories)
    }

    // MARK: - Meal Computed Properties

    func testIngredientsList() throws {
        let meal = Meal(name: "Oatmeal")
        meal.ingredients = "Oats, Dried fruit, Nuts, Honey"

        let list = meal.ingredientsList
        XCTAssertEqual(list.count, 4)
        XCTAssertEqual(list[0], "Oats")
        XCTAssertEqual(list[1], "Dried fruit")
        XCTAssertEqual(list[2], "Nuts")
        XCTAssertEqual(list[3], "Honey")
    }

    func testIngredientsListEmpty() throws {
        let meal = Meal(name: "Test")
        XCTAssertTrue(meal.ingredientsList.isEmpty)
    }

    func testHasRecipe() throws {
        let meal = Meal(name: "Test")
        XCTAssertFalse(meal.hasRecipe)

        meal.recipeURL = "https://example.com/recipe"
        XCTAssertTrue(meal.hasRecipe)
    }

    // MARK: - MealType Enum Tests

    func testMealTypeProperties() throws {
        for mealType in MealType.allCases {
            XCTAssertFalse(mealType.icon.isEmpty)
        }
    }

    func testMealTypeCaseCount() throws {
        XCTAssertEqual(MealType.allCases.count, 5)
    }

    func testMealTypeSortOrder() throws {
        XCTAssertEqual(MealType.breakfast.sortOrder, 0)
        XCTAssertEqual(MealType.morningSnack.sortOrder, 1)
        XCTAssertEqual(MealType.lunch.sortOrder, 2)
        XCTAssertEqual(MealType.afternoonSnack.sortOrder, 3)
        XCTAssertEqual(MealType.dinner.sortOrder, 4)
    }

    // MARK: - Persistence Test

    @MainActor
    func testSwiftDataPersistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Expedition.self, MealPlan.self, Meal.self,
            configurations: config
        )
        let context = container.mainContext

        let expedition = Expedition(name: "Test Expedition")
        context.insert(expedition)

        let plan = MealPlan(dayNumber: 1)
        plan.expedition = expedition
        context.insert(plan)

        let meal = Meal(name: "Mountain House Beef Stew", mealType: .dinner)
        meal.calories = 550
        meal.ingredients = "Beef, Potatoes, Carrots, Gravy"
        meal.mealPlan = plan
        context.insert(meal)

        try context.save()

        let descriptor = FetchDescriptor<MealPlan>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.dayNumber, 1)
        XCTAssertEqual(fetched.first?.meals?.count, 1)
        XCTAssertEqual(fetched.first?.meals?.first?.name, "Mountain House Beef Stew")
        XCTAssertEqual(fetched.first?.meals?.first?.calories, 550)
    }
}
