import XCTest
import SwiftData
@testable import Chaki

final class ChecklistItemTests: XCTestCase {

    // MARK: - Creation Tests

    func testChecklistItemCreation() throws {
        let item = ChecklistItem(
            title: "Book flights",
            notes: "Compare prices on Google Flights",
            category: .travel
        )

        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.title, "Book flights")
        XCTAssertEqual(item.notes, "Compare prices on Google Flights")
        XCTAssertEqual(item.category, .travel)
        XCTAssertEqual(item.status, .pending)
    }

    func testChecklistItemDefaultValues() throws {
        let item = ChecklistItem()

        XCTAssertEqual(item.title, "")
        XCTAssertEqual(item.notes, "")
        XCTAssertEqual(item.status, .pending)
        XCTAssertEqual(item.category, .logistics)
        XCTAssertNil(item.dueDate)
        XCTAssertNil(item.dueOffset)
        XCTAssertNil(item.assignedTo)
        XCTAssertNil(item.expedition)
    }

    // MARK: - Computed Due Date Tests

    func testComputedDueDateReturnsExplicitDate() throws {
        let explicitDate = Date().adding(days: 14)
        let item = ChecklistItem(title: "Test", dueDate: explicitDate, dueOffset: -30)

        let computed = item.computedDueDate(expeditionStartDate: Date().adding(days: 60))
        XCTAssertEqual(computed, explicitDate)
    }

    func testComputedDueDateFromOffset() throws {
        let startDate = Date().adding(days: 60)
        let item = ChecklistItem(title: "Test", dueOffset: -30)

        let computed = item.computedDueDate(expeditionStartDate: startDate)
        let expected = Calendar.current.date(byAdding: .day, value: -30, to: startDate)
        XCTAssertEqual(computed, expected)
    }

    func testComputedDueDateNilWhenNoDateOrOffset() throws {
        let item = ChecklistItem(title: "Test")

        let computed = item.computedDueDate(expeditionStartDate: Date())
        XCTAssertNil(computed)
    }

    func testComputedDueDateNilWhenOffsetButNoStartDate() throws {
        let item = ChecklistItem(title: "Test", dueOffset: -30)

        let computed = item.computedDueDate(expeditionStartDate: nil)
        XCTAssertNil(computed)
    }

    // MARK: - Overdue Tests

    func testIsOverdueForPastDueDate() throws {
        let item = ChecklistItem(title: "Test", dueDate: Date().adding(days: -5))

        XCTAssertTrue(item.isOverdue(expeditionStartDate: nil))
    }

    func testNotOverdueForFutureDueDate() throws {
        let item = ChecklistItem(title: "Test", dueDate: Date().adding(days: 10))

        XCTAssertFalse(item.isOverdue(expeditionStartDate: nil))
    }

    func testCompletedItemNotOverdue() throws {
        let item = ChecklistItem(title: "Test", status: .completed, dueDate: Date().adding(days: -5))

        XCTAssertFalse(item.isOverdue(expeditionStartDate: nil))
    }

    func testSkippedItemNotOverdue() throws {
        let item = ChecklistItem(title: "Test", status: .skipped, dueDate: Date().adding(days: -5))

        XCTAssertFalse(item.isOverdue(expeditionStartDate: nil))
    }

    func testNotOverdueWithNoDueDate() throws {
        let item = ChecklistItem(title: "Test")

        XCTAssertFalse(item.isOverdue(expeditionStartDate: nil))
    }

    // MARK: - Days Until Due Tests

    func testDaysUntilDueForFutureDate() throws {
        let item = ChecklistItem(title: "Test", dueDate: Date().adding(days: 15))

        let days = item.daysUntilDue(expeditionStartDate: nil)
        XCTAssertNotNil(days)
        XCTAssertTrue(days == 14 || days == 15, "Expected 14 or 15 days, got \(days ?? -1)")
    }

    func testDaysUntilDueNilWhenNoDueDate() throws {
        let item = ChecklistItem(title: "Test")

        XCTAssertNil(item.daysUntilDue(expeditionStartDate: nil))
    }

    func testDaysUntilDueNegativeForPastDate() throws {
        let item = ChecklistItem(title: "Test", dueDate: Date().adding(days: -5))

        let days = item.daysUntilDue(expeditionStartDate: nil)
        XCTAssertNotNil(days)
        XCTAssertTrue((days ?? 0) < 0, "Expected negative days, got \(days ?? 0)")
    }

    // MARK: - Status Tests

    func testIsComplete() throws {
        let item = ChecklistItem(title: "Test", status: .completed)
        XCTAssertTrue(item.isComplete)
    }

    func testNotCompleteForPending() throws {
        let item = ChecklistItem(title: "Test", status: .pending)
        XCTAssertFalse(item.isComplete)
    }

    func testIsSkipped() throws {
        let item = ChecklistItem(title: "Test", status: .skipped)
        XCTAssertTrue(item.isSkipped)
    }

    func testNotSkippedForInProgress() throws {
        let item = ChecklistItem(title: "Test", status: .inProgress)
        XCTAssertFalse(item.isSkipped)
    }

    // MARK: - Status Color Tests

    func testStatusColorPending() throws {
        let item = ChecklistItem(title: "Test", status: .pending)
        XCTAssertEqual(item.statusColor, "gray")
    }

    func testStatusColorInProgress() throws {
        let item = ChecklistItem(title: "Test", status: .inProgress)
        XCTAssertEqual(item.statusColor, "blue")
    }

    func testStatusColorCompleted() throws {
        let item = ChecklistItem(title: "Test", status: .completed)
        XCTAssertEqual(item.statusColor, "green")
    }

    func testStatusColorSkipped() throws {
        let item = ChecklistItem(title: "Test", status: .skipped)
        XCTAssertEqual(item.statusColor, "orange")
    }

    // MARK: - Enum Coverage Tests

    func testAllChecklistStatusesHaveIcons() throws {
        for status in ChecklistStatus.allCases {
            XCTAssertFalse(status.icon.isEmpty, "Status \(status.rawValue) has no icon")
        }
    }

    func testAllChecklistCategoriesHaveIcons() throws {
        for category in ChecklistCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "Category \(category.rawValue) has no icon")
        }
    }

    func testChecklistStatusCount() throws {
        XCTAssertEqual(ChecklistStatus.allCases.count, 4)
    }

    func testChecklistCategoryCount() throws {
        XCTAssertEqual(ChecklistCategory.allCases.count, 8)
    }

    // MARK: - SwiftData Persistence Tests

    func testSwiftDataPersistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Expedition.self, ChecklistItem.self, Participant.self,
            configurations: config
        )
        let context = ModelContext(container)

        let expedition = Expedition(name: "Test Expedition")
        context.insert(expedition)

        let item = ChecklistItem(title: "Apply for permits", category: .permits)
        item.expedition = expedition
        if expedition.checklistItems == nil {
            expedition.checklistItems = []
        }
        expedition.checklistItems?.append(item)
        context.insert(item)

        try context.save()

        let descriptor = FetchDescriptor<ChecklistItem>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Apply for permits")
        XCTAssertEqual(fetched.first?.category, .permits)
        XCTAssertNotNil(fetched.first?.expedition)
        XCTAssertEqual(fetched.first?.expedition?.name, "Test Expedition")
    }
}
