import Foundation
import CloudKit
import Combine
import os

/// Represents the current sync status with CloudKit
enum SyncStatus: Equatable {
    case idle
    case syncing
    case synced
    case error(String)
    case offline
    case noAccount

    var icon: String {
        switch self {
        case .idle:
            return "arrow.triangle.2.circlepath"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .synced:
            return "checkmark.icloud"
        case .error:
            return "exclamationmark.icloud"
        case .offline:
            return "icloud.slash"
        case .noAccount:
            return "person.crop.circle.badge.xmark"
        }
    }

    var description: String {
        switch self {
        case .idle:
            return "Ready"
        case .syncing:
            return "Syncing..."
        case .synced:
            return "Synced"
        case .error(let message):
            return "Error: \(message)"
        case .offline:
            return "Offline"
        case .noAccount:
            return "No iCloud Account"
        }
    }

    var color: String {
        switch self {
        case .idle:
            return "gray"
        case .syncing:
            return "blue"
        case .synced:
            return "green"
        case .error:
            return "red"
        case .offline:
            return "orange"
        case .noAccount:
            return "orange"
        }
    }
}

/// Service that monitors CloudKit sync status
@MainActor
final class SyncStatusService: ObservableObject {
    static let shared = SyncStatusService()

    @Published private(set) var status: SyncStatus = .idle
    @Published private(set) var lastSyncDate: Date?

    private let logger = Logger(subsystem: "com.chaki.app", category: "SyncStatus")
    private var accountStatusTask: Task<Void, Never>?

    private init() {
        startMonitoring()
    }

    deinit {
        accountStatusTask?.cancel()
    }

    /// Start monitoring CloudKit account status
    func startMonitoring() {
        checkAccountStatus()

        // Listen for account changes
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkAccountStatus()
            }
        }
    }

    /// Check the current CloudKit account status
    func checkAccountStatus() {
        accountStatusTask?.cancel()
        accountStatusTask = Task {
            do {
                let container = CKContainer.default()
                let accountStatus = try await container.accountStatus()

                switch accountStatus {
                case .available:
                    self.status = .synced
                    self.lastSyncDate = Date()
                    self.logger.info("CloudKit account available")
                case .noAccount:
                    self.status = .noAccount
                    self.logger.warning("No CloudKit account")
                case .restricted:
                    self.status = .error("Restricted")
                    self.logger.warning("CloudKit account restricted")
                case .couldNotDetermine:
                    self.status = .offline
                    self.logger.warning("Could not determine CloudKit status")
                case .temporarilyUnavailable:
                    self.status = .offline
                    self.logger.warning("CloudKit temporarily unavailable")
                @unknown default:
                    self.status = .idle
                    self.logger.warning("Unknown CloudKit status")
                }
            } catch {
                self.status = .error(error.localizedDescription)
                self.logger.error("CloudKit error: \(error.localizedDescription)")
            }
        }
    }

    /// Manually trigger a sync check
    func refresh() {
        status = .syncing
        checkAccountStatus()
    }
}
