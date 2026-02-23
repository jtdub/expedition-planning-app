import XCTest
import SwiftData
@testable import ExpeditionPlanner

final class GearItemTests: XCTestCase {

    // MARK: - Creation Tests

    func testGearItemCreation() throws {
        let item = GearItem(
            name: "Tent",
            category: .shelter,
            priority: .critical,
            descriptionOrPurpose: "2-person backpacking tent",
            exampleProduct: "MSR Hubba Hubba NX",
            selection: "MSR Hubba Hubba NX 2",
            quantity: 1
        )

        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.name, "Tent")
        XCTAssertEqual(item.category, .shelter)
        XCTAssertEqual(item.priority, .critical)
        XCTAssertEqual(item.quantity, 1)
    }

    func testGearItemDefaultValues() throws {
        let item = GearItem(name: "Test Item")

        XCTAssertEqual(item.category, .personalItems)
        XCTAssertEqual(item.priority, .suggested)
        XCTAssertEqual(item.quantity, 1)
        XCTAssertFalse(item.isWeighed)
        XCTAssertFalse(item.isInHand)
        XCTAssertFalse(item.isPacked)
    }

    // MARK: - Weight Tests

    func testWeightConversion() throws {
        let item = GearItem(name: "Backpack")
        item.weightGrams = 1500

        let weight = item.weight
        XCTAssertNotNil(weight)
        XCTAssertEqual(weight?.value, 1500)
        XCTAssertEqual(weight?.unit, .grams)
    }

    func testTotalWeightWithQuantity() throws {
        let item = GearItem(name: "Water Bottle", quantity: 2)
        item.weightGrams = 200

        let totalWeight = item.totalWeight
        XCTAssertNotNil(totalWeight)
        XCTAssertEqual(totalWeight?.value, 400)
    }

    func testNilWeightWhenNotSet() throws {
        let item = GearItem(name: "Test")

        XCTAssertNil(item.weight)
        XCTAssertNil(item.totalWeight)
    }

    // MARK: - Status Tests

    func testIsCompleteWhenAllChecked() throws {
        let item = GearItem(name: "Test")
        item.isWeighed = true
        item.isInHand = true
        item.isPacked = true

        XCTAssertTrue(item.isComplete)
    }

    func testIsIncompleteWhenPartiallyChecked() throws {
        let item = GearItem(name: "Test")
        item.isWeighed = true
        item.isInHand = true
        item.isPacked = false

        XCTAssertFalse(item.isComplete)
    }

    func testStatusIconProgression() throws {
        let item = GearItem(name: "Test")

        // Not started
        XCTAssertEqual(item.statusIcon, "circle")

        // Weighed
        item.isWeighed = true
        XCTAssertEqual(item.statusIcon, "scalemass.fill")

        // In hand
        item.isInHand = true
        XCTAssertEqual(item.statusIcon, "shippingbox.fill")

        // Packed
        item.isPacked = true
        XCTAssertEqual(item.statusIcon, "checkmark.circle.fill")
    }

    // MARK: - Category Tests

    func testAllCategoriesCovered() throws {
        let allCategories = GearCategory.allCases
        XCTAssertEqual(allCategories.count, 13)

        for category in allCategories {
            XCTAssertFalse(category.icon.isEmpty)
            XCTAssertGreaterThanOrEqual(category.sortOrder, 0)
        }
    }

    func testCategorySortOrder() throws {
        let sorted = GearCategory.allCases.sorted { $0.sortOrder < $1.sortOrder }

        XCTAssertEqual(sorted.first, .goSuitClothing)
        XCTAssertEqual(sorted.last, .electronics)
    }

    // MARK: - Priority Tests

    func testAllPrioritiesCovered() throws {
        let allPriorities = GearPriority.allCases
        XCTAssertEqual(allPriorities.count, 4)

        for priority in allPriorities {
            XCTAssertFalse(priority.icon.isEmpty)
            XCTAssertFalse(priority.color.isEmpty)
        }
    }

    func testPrioritySortOrder() throws {
        XCTAssertEqual(GearPriority.critical.sortOrder, 0)
        XCTAssertEqual(GearPriority.suggested.sortOrder, 1)
        XCTAssertEqual(GearPriority.optional.sortOrder, 2)
        XCTAssertEqual(GearPriority.contingent.sortOrder, 3)
    }

    func testCriticalPriorityHasWarningIcon() throws {
        XCTAssertEqual(GearPriority.critical.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(GearPriority.critical.color, "red")
    }
}
