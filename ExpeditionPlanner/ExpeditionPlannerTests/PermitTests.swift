import XCTest
import SwiftData
@testable import ExpeditionPlanner

final class PermitTests: XCTestCase {

    // MARK: - Creation Tests

    func testPermitCreation() throws {
        let permit = Permit(
            name: "Wilderness Permit",
            issuingAuthority: "National Park Service",
            permitType: .wilderness
        )

        XCTAssertNotNil(permit.id)
        XCTAssertEqual(permit.name, "Wilderness Permit")
        XCTAssertEqual(permit.issuingAuthority, "National Park Service")
        XCTAssertEqual(permit.permitType, .wilderness)
    }

    func testPermitDefaultValues() throws {
        let permit = Permit(name: "Test Permit")

        XCTAssertEqual(permit.status, .notStarted)
        XCTAssertEqual(permit.currency, "USD")
        XCTAssertNil(permit.applicationDeadline)
        XCTAssertNil(permit.cost)
        XCTAssertTrue(permit.notes.isEmpty)
    }

    // MARK: - Deadline Tests

    func testDaysUntilDeadline() throws {
        let permit = Permit(name: "Test")
        let futureDate = Date().adding(days: 30)
        permit.applicationDeadline = futureDate

        let days = permit.daysUntilDeadline
        XCTAssertNotNil(days)
        // Allow for date calculation variance depending on time of day
        XCTAssertTrue(days == 29 || days == 30, "Expected 29 or 30 days, got \(days ?? -1)")
    }

    func testNilDaysWhenNoDeadline() throws {
        let permit = Permit(name: "Test")

        XCTAssertNil(permit.daysUntilDeadline)
    }

    func testIsOverdue() throws {
        let permit = Permit(name: "Test")
        permit.status = .notStarted
        permit.applicationDeadline = Date().adding(days: -10)

        XCTAssertTrue(permit.isOverdue)
    }

    func testNotOverdueWhenStarted() throws {
        let permit = Permit(name: "Test")
        permit.status = .inProgress
        permit.applicationDeadline = Date().adding(days: -10)

        XCTAssertFalse(permit.isOverdue)
    }

    func testNotOverdueWhenFutureDeadline() throws {
        let permit = Permit(name: "Test")
        permit.status = .notStarted
        permit.applicationDeadline = Date().adding(days: 30)

        XCTAssertFalse(permit.isOverdue)
    }

    // MARK: - Completion Tests

    func testIsCompleteWhenObtained() throws {
        let permit = Permit(name: "Test")
        permit.status = .obtained

        XCTAssertTrue(permit.isComplete)
    }

    func testIsCompleteWhenApproved() throws {
        let permit = Permit(name: "Test")
        permit.status = .approved

        XCTAssertTrue(permit.isComplete)
    }

    func testNotCompleteWhenInProgress() throws {
        let permit = Permit(name: "Test")
        permit.status = .inProgress

        XCTAssertFalse(permit.isComplete)
    }

    // MARK: - Status Color Tests

    func testStatusColorForOverdue() throws {
        let permit = Permit(name: "Test")
        permit.status = .notStarted
        permit.applicationDeadline = Date().adding(days: -10)

        XCTAssertEqual(permit.statusColor, "red")
    }

    func testStatusColorForNotStarted() throws {
        let permit = Permit(name: "Test")
        permit.status = .notStarted
        permit.applicationDeadline = Date().adding(days: 30)

        XCTAssertEqual(permit.statusColor, "gray")
    }

    func testStatusColorForInProgress() throws {
        let permit = Permit(name: "Test")
        permit.status = .inProgress

        XCTAssertEqual(permit.statusColor, "orange")
    }

    func testStatusColorForObtained() throws {
        let permit = Permit(name: "Test")
        permit.status = .obtained

        XCTAssertEqual(permit.statusColor, "green")
    }

    // MARK: - Permit Type Tests

    func testAllPermitTypesCovered() throws {
        let allTypes = PermitType.allCases
        XCTAssertEqual(allTypes.count, 10)

        for type in allTypes {
            XCTAssertFalse(type.icon.isEmpty)
        }
    }

    func testPermitTypeIcons() throws {
        XCTAssertEqual(PermitType.wilderness.icon, "leaf")
        XCTAssertEqual(PermitType.border.icon, "globe")
        XCTAssertEqual(PermitType.drone.icon, "airplane")
    }

    // MARK: - Permit Status Tests

    func testAllStatusesCovered() throws {
        let allStatuses = PermitStatus.allCases
        XCTAssertEqual(allStatuses.count, 7)

        for status in allStatuses {
            XCTAssertFalse(status.icon.isEmpty)
        }
    }

    func testPermitStatusIcons() throws {
        XCTAssertEqual(PermitStatus.notStarted.icon, "circle")
        XCTAssertEqual(PermitStatus.submitted.icon, "paperplane")
        XCTAssertEqual(PermitStatus.obtained.icon, "checkmark.seal.fill")
        XCTAssertEqual(PermitStatus.denied.icon, "xmark.circle")
    }
}
