import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.expedition.planner", category: "PermitViewModel")

enum PermitSortOrder: String, CaseIterable {
    case deadline = "Deadline"
    case status = "Status"
    case name = "Name"
    case type = "Type"
}

@Observable
final class PermitViewModel {
    private var modelContext: ModelContext

    var permits: [Permit] = []
    var searchText: String = ""
    var filterStatus: PermitStatus?
    var filterType: PermitType?
    var sortOrder: PermitSortOrder = .deadline
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadPermits(for expedition: Expedition) {
        let allPermits = expedition.permits ?? []

        var filtered = allPermits

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { permit in
                permit.name.localizedCaseInsensitiveContains(searchText) ||
                permit.issuingAuthority.localizedCaseInsensitiveContains(searchText) ||
                permit.permitDescription.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply status filter
        if let status = filterStatus {
            filtered = filtered.filter { $0.status == status }
        }

        // Apply type filter
        if let type = filterType {
            filtered = filtered.filter { $0.permitType == type }
        }

        // Sort
        switch sortOrder {
        case .deadline:
            permits = filtered.sorted { p1, p2 in
                let d1 = p1.applicationDeadline ?? Date.distantFuture
                let d2 = p2.applicationDeadline ?? Date.distantFuture
                return d1 < d2
            }
        case .status:
            permits = filtered.sorted { p1, p2 in
                if p1.status != p2.status {
                    return p1.status.rawValue < p2.status.rawValue
                }
                return p1.name < p2.name
            }
        case .name:
            permits = filtered.sorted { $0.name < $1.name }
        case .type:
            permits = filtered.sorted { p1, p2 in
                if p1.permitType != p2.permitType {
                    return p1.permitType.rawValue < p2.permitType.rawValue
                }
                return p1.name < p2.name
            }
        }
    }

    // MARK: - CRUD Operations

    func addPermit(_ permit: Permit, to expedition: Expedition) {
        permit.expedition = expedition
        if expedition.permits == nil {
            expedition.permits = []
        }
        expedition.permits?.append(permit)
        modelContext.insert(permit)

        logger.info("Added permit '\(permit.name)' to expedition")
        saveContext()
        loadPermits(for: expedition)
    }

    func deletePermit(_ permit: Permit, from expedition: Expedition) {
        let name = permit.name
        expedition.permits?.removeAll { $0.id == permit.id }
        modelContext.delete(permit)

        logger.info("Deleted permit '\(name)' from expedition")
        saveContext()
        loadPermits(for: expedition)
    }

    func updatePermit(_ permit: Permit, in expedition: Expedition) {
        logger.debug("Updated permit '\(permit.name)'")
        saveContext()
        loadPermits(for: expedition)
    }

    // MARK: - Computed Properties

    var overduePermits: [Permit] {
        permits.filter { $0.isOverdue }
    }

    var upcomingDeadlines: [Permit] {
        permits.filter { permit in
            guard let days = permit.daysUntilDeadline else { return false }
            return days >= 0 && days <= 30 && !permit.isComplete
        }.sorted { ($0.daysUntilDeadline ?? 0) < ($1.daysUntilDeadline ?? 0) }
    }

    var completedCount: Int {
        permits.filter { $0.isComplete }.count
    }

    var pendingCount: Int {
        permits.filter { !$0.isComplete }.count
    }

    var statusCounts: [PermitStatus: Int] {
        var counts: [PermitStatus: Int] = [:]
        for permit in permits {
            counts[permit.status, default: 0] += 1
        }
        return counts
    }

    var groupedByStatus: [(status: PermitStatus, permits: [Permit])] {
        let grouped = Dictionary(grouping: permits) { $0.status }
        return PermitStatus.allCases.compactMap { status in
            guard let list = grouped[status], !list.isEmpty else { return nil }
            return (status: status, permits: list)
        }
    }

    var groupedByType: [(type: PermitType, permits: [Permit])] {
        let grouped = Dictionary(grouping: permits) { $0.permitType }
        return PermitType.allCases.compactMap { type in
            guard let list = grouped[type], !list.isEmpty else { return nil }
            return (type: type, permits: list)
        }
    }

    var totalCost: Decimal {
        permits.compactMap { $0.cost }.reduce(0, +)
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
        filterStatus = nil
        filterType = nil
    }

    var hasActiveFilters: Bool {
        filterStatus != nil || filterType != nil || !searchText.isEmpty
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save permit changes: \(error.localizedDescription)")
        }
    }
}
