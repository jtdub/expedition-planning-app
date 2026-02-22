import XCTest
@testable import ExpeditionPlanner

final class SyncStatusTests: XCTestCase {

    // MARK: - SyncStatus Enum Tests

    func testSyncStatusIcons() {
        XCTAssertEqual(SyncStatus.idle.icon, "arrow.triangle.2.circlepath")
        XCTAssertEqual(SyncStatus.syncing.icon, "arrow.triangle.2.circlepath")
        XCTAssertEqual(SyncStatus.synced.icon, "checkmark.icloud")
        XCTAssertEqual(SyncStatus.error("test").icon, "exclamationmark.icloud")
        XCTAssertEqual(SyncStatus.offline.icon, "icloud.slash")
        XCTAssertEqual(SyncStatus.noAccount.icon, "person.crop.circle.badge.xmark")
    }

    func testSyncStatusDescriptions() {
        XCTAssertEqual(SyncStatus.idle.description, "Ready")
        XCTAssertEqual(SyncStatus.syncing.description, "Syncing...")
        XCTAssertEqual(SyncStatus.synced.description, "Synced")
        XCTAssertEqual(SyncStatus.error("Network failed").description, "Error: Network failed")
        XCTAssertEqual(SyncStatus.offline.description, "Offline")
        XCTAssertEqual(SyncStatus.noAccount.description, "No iCloud Account")
    }

    func testSyncStatusColors() {
        XCTAssertEqual(SyncStatus.idle.color, "gray")
        XCTAssertEqual(SyncStatus.syncing.color, "blue")
        XCTAssertEqual(SyncStatus.synced.color, "green")
        XCTAssertEqual(SyncStatus.error("test").color, "red")
        XCTAssertEqual(SyncStatus.offline.color, "orange")
        XCTAssertEqual(SyncStatus.noAccount.color, "orange")
    }

    func testSyncStatusEquality() {
        XCTAssertEqual(SyncStatus.idle, SyncStatus.idle)
        XCTAssertEqual(SyncStatus.syncing, SyncStatus.syncing)
        XCTAssertEqual(SyncStatus.synced, SyncStatus.synced)
        XCTAssertEqual(SyncStatus.offline, SyncStatus.offline)
        XCTAssertEqual(SyncStatus.noAccount, SyncStatus.noAccount)
        XCTAssertEqual(SyncStatus.error("test"), SyncStatus.error("test"))
        XCTAssertNotEqual(SyncStatus.error("test1"), SyncStatus.error("test2"))
        XCTAssertNotEqual(SyncStatus.idle, SyncStatus.synced)
    }
}
