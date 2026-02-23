import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.expedition.planner", category: "ResupplyViewModel")

enum ResupplySortOrder: String, CaseIterable {
    case sequence = "Sequence"
    case name = "Name"
    case date = "Arrival Date"
}

@Observable
final class ResupplyViewModel {
    private var modelContext: ModelContext

    var resupplyPoints: [ResupplyPoint] = []
    var searchText: String = ""
    var filterHasPostOffice: Bool = false
    var sortOrder: ResupplySortOrder = .sequence
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadResupplyPoints(for expedition: Expedition) {
        let allPoints = expedition.resupplyPoints ?? []

        var filtered = allPoints

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { point in
                point.name.localizedCaseInsensitiveContains(searchText) ||
                point.resupplyDescription.localizedCaseInsensitiveContains(searchText) ||
                (point.postOfficeAddress ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply post office filter
        if filterHasPostOffice {
            filtered = filtered.filter { $0.hasPostOffice }
        }

        // Sort
        switch sortOrder {
        case .sequence:
            resupplyPoints = filtered.sorted { p1, p2 in
                let d1 = p1.dayNumber ?? 999
                let d2 = p2.dayNumber ?? 999
                return d1 < d2
            }
        case .name:
            resupplyPoints = filtered.sorted { $0.name < $1.name }
        case .date:
            resupplyPoints = filtered.sorted { p1, p2 in
                let d1 = p1.expectedArrivalDate ?? Date.distantFuture
                let d2 = p2.expectedArrivalDate ?? Date.distantFuture
                return d1 < d2
            }
        }
    }

    // MARK: - CRUD Operations

    func addResupplyPoint(_ point: ResupplyPoint, to expedition: Expedition) {
        point.expedition = expedition
        if expedition.resupplyPoints == nil {
            expedition.resupplyPoints = []
        }
        expedition.resupplyPoints?.append(point)
        modelContext.insert(point)

        logger.info("Added resupply point '\(point.name)' to expedition")
        saveContext()
        loadResupplyPoints(for: expedition)
    }

    func deleteResupplyPoint(_ point: ResupplyPoint, from expedition: Expedition) {
        let name = point.name
        expedition.resupplyPoints?.removeAll { $0.id == point.id }
        modelContext.delete(point)

        logger.info("Deleted resupply point '\(name)' from expedition")
        saveContext()
        loadResupplyPoints(for: expedition)
    }

    func updateResupplyPoint(_ point: ResupplyPoint, in expedition: Expedition) {
        logger.debug("Updated resupply point '\(point.name)'")
        saveContext()
        loadResupplyPoints(for: expedition)
    }

    // MARK: - Computed Properties

    var pointsWithPostOffice: [ResupplyPoint] {
        resupplyPoints.filter { $0.hasPostOffice }
    }

    var totalServices: [String: Int] {
        var counts: [String: Int] = [:]
        for point in resupplyPoints {
            for service in point.availableServices {
                counts[service, default: 0] += 1
            }
        }
        return counts
    }

    var upcomingResupply: [ResupplyPoint] {
        resupplyPoints.filter { point in
            guard let date = point.expectedArrivalDate else { return false }
            let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
            return daysUntil >= 0 && daysUntil <= 14
        }
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
        filterHasPostOffice = false
    }

    var hasActiveFilters: Bool {
        filterHasPostOffice || !searchText.isEmpty
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save resupply changes: \(error.localizedDescription)")
        }
    }
}
