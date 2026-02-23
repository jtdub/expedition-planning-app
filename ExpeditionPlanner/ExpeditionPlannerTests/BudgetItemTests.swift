import XCTest
import SwiftData
@testable import ExpeditionPlanner

final class BudgetItemTests: XCTestCase {

    // MARK: - Creation Tests

    func testBudgetItemCreation() throws {
        let item = BudgetItem(
            name: "Flight to Kotzebue",
            category: .flights,
            estimatedAmount: 850,
            currency: "USD"
        )

        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.name, "Flight to Kotzebue")
        XCTAssertEqual(item.category, .flights)
        XCTAssertEqual(item.estimatedAmount, 850)
        XCTAssertEqual(item.currency, "USD")
    }

    func testBudgetItemDefaultValues() throws {
        let item = BudgetItem(name: "Test Item")

        XCTAssertEqual(item.category, .other)
        XCTAssertEqual(item.estimatedAmount, 0)
        XCTAssertEqual(item.currency, "USD")
        XCTAssertNil(item.actualAmount)
        XCTAssertFalse(item.isPaid)
        XCTAssertFalse(item.hasReceipt)
    }

    // MARK: - Variance Tests

    func testVarianceCalculation() throws {
        let item = BudgetItem(name: "Test", estimatedAmount: 100)
        item.actualAmount = 120

        XCTAssertEqual(item.variance, 20)
        XCTAssertTrue(item.isOverBudget)
    }

    func testUnderBudgetVariance() throws {
        let item = BudgetItem(name: "Test", estimatedAmount: 100)
        item.actualAmount = 80

        XCTAssertEqual(item.variance, -20)
        XCTAssertFalse(item.isOverBudget)
    }

    func testVariancePercentage() throws {
        let item = BudgetItem(name: "Test", estimatedAmount: 100)
        item.actualAmount = 150

        XCTAssertEqual(item.variancePercentage, 50.0)
    }

    func testNoVarianceWithoutActual() throws {
        let item = BudgetItem(name: "Test", estimatedAmount: 100)

        XCTAssertNil(item.variance)
        XCTAssertNil(item.variancePercentage)
        XCTAssertFalse(item.isOverBudget)
    }

    // MARK: - Currency Conversion Tests

    func testUSDAmountWithoutExchangeRate() throws {
        let item = BudgetItem(name: "Test", estimatedAmount: 100, currency: "USD")

        XCTAssertEqual(item.amountInUSD, 100)
    }

    func testForeignCurrencyConversion() throws {
        let item = BudgetItem(name: "Test", estimatedAmount: 100, currency: "EUR")
        item.exchangeRate = 0.92 // 1 EUR = 1.087 USD

        let usdAmount = item.amountInUSD
        XCTAssertNotNil(usdAmount)
        XCTAssertEqual(usdAmount?.doubleValue ?? 0, 100 / 0.92, accuracy: 0.01)
    }

    func testNoConversionWithoutRate() throws {
        let item = BudgetItem(name: "Test", estimatedAmount: 100, currency: "EUR")

        XCTAssertNil(item.amountInUSD)
    }

    // MARK: - Formatting Tests

    func testFormattedEstimate() throws {
        let item = BudgetItem(name: "Test", estimatedAmount: 1234.56, currency: "USD")

        let formatted = item.formattedEstimate
        XCTAssertTrue(formatted.contains("1,234"))
    }

    func testFormattedActual() throws {
        let item = BudgetItem(name: "Test", estimatedAmount: 100, currency: "USD")
        item.actualAmount = 567.89

        let formatted = item.formattedActual
        XCTAssertNotNil(formatted)
        XCTAssertTrue(formatted?.contains("567") ?? false)
    }

    func testNoFormattedActualWhenNil() throws {
        let item = BudgetItem(name: "Test", estimatedAmount: 100)

        XCTAssertNil(item.formattedActual)
    }

    // MARK: - Category Tests

    func testAllCategoriesCovered() throws {
        let allCategories = BudgetCategory.allCases
        XCTAssertEqual(allCategories.count, 11)

        for category in allCategories {
            XCTAssertFalse(category.icon.isEmpty)
            XCTAssertFalse(category.color.isEmpty)
        }
    }

    func testCategoryIcons() throws {
        XCTAssertEqual(BudgetCategory.flights.icon, "airplane")
        XCTAssertEqual(BudgetCategory.lodging.icon, "bed.double")
        XCTAssertEqual(BudgetCategory.gear.icon, "backpack")
        XCTAssertEqual(BudgetCategory.emergency.icon, "cross.case")
    }
}
