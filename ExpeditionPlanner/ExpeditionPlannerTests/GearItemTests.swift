import XCTest
import SwiftData
@testable import Chaki

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

    // MARK: - Ownership Type Tests

    func testDefaultOwnershipType() throws {
        let item = GearItem(name: "Test")
        XCTAssertEqual(item.ownershipType, .personal)
    }

    func testGroupOwnershipType() throws {
        let item = GearItem(name: "Tent", ownershipType: .group)
        XCTAssertEqual(item.ownershipType, .group)
    }

    func testCarriedByNameWithParticipant() throws {
        let item = GearItem(name: "Stove")
        let participant = Participant(name: "Alice Smith")
        item.carriedBy = participant
        XCTAssertEqual(item.carriedByName, "Alice Smith")
    }

    func testCarriedByNameWithoutParticipant() throws {
        let item = GearItem(name: "Filter")
        XCTAssertNil(item.carriedBy)
        XCTAssertEqual(item.carriedByName, "Unassigned")
    }

    func testOwnershipTypeAllCases() throws {
        let allCases = GearOwnershipType.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.personal))
        XCTAssertTrue(allCases.contains(.group))
    }

    func testOwnershipTypeIcons() throws {
        for ownership in GearOwnershipType.allCases {
            XCTAssertFalse(ownership.icon.isEmpty)
        }
        XCTAssertEqual(GearOwnershipType.personal.icon, "person")
        XCTAssertEqual(GearOwnershipType.group.icon, "person.3")
    }

    @MainActor func testGearItemWithOwnershipPersistence() throws {
        let container = try ModelContainer(
            for: Expedition.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let expedition = Expedition(name: "Test Expedition")
        context.insert(expedition)

        let item = GearItem(name: "Bear Canister", ownershipType: .group)
        item.expedition = expedition
        context.insert(item)

        try context.save()

        let descriptor = FetchDescriptor<GearItem>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.ownershipType, .group)
        XCTAssertEqual(fetched.first?.name, "Bear Canister")
    }

    @MainActor func testGearItemCarrierAssignment() throws {
        let container = try ModelContainer(
            for: Expedition.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let expedition = Expedition(name: "Test Expedition")
        context.insert(expedition)

        let participant = Participant(name: "Bob Jones")
        participant.expedition = expedition
        context.insert(participant)

        let item = GearItem(name: "Water Filter", ownershipType: .group)
        item.expedition = expedition
        item.carriedBy = participant
        context.insert(item)

        try context.save()

        let descriptor = FetchDescriptor<GearItem>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.carriedBy?.name, "Bob Jones")
        XCTAssertEqual(fetched.first?.carriedByName, "Bob Jones")
    }
}
