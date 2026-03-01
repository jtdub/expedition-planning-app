import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.chaki.app", category: "TransportViewModel")

enum TransportSortOrder: String, CaseIterable {
    case departureTime = "Departure Time"
    case participant = "Participant"
    case type = "Transport Type"
    case status = "Status"
}

@Observable
final class TransportViewModel {
    private var modelContext: ModelContext

    var transportLegs: [TransportLeg] = []
    var searchText: String = ""
    var filterType: TransportType?
    var filterParticipant: Participant?
    var showUpcomingOnly: Bool = false
    var sortOrder: TransportSortOrder = .departureTime
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadTransportLegs(for expedition: Expedition) {
        let allLegs = expedition.transportLegs ?? []

        var filtered = allLegs

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { leg in
                leg.carrier.localizedCaseInsensitiveContains(searchText) ||
                leg.departureLocation.localizedCaseInsensitiveContains(searchText) ||
                leg.arrivalLocation.localizedCaseInsensitiveContains(searchText) ||
                leg.flightNumber.localizedCaseInsensitiveContains(searchText) ||
                leg.bookingReference.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply type filter
        if let transportType = filterType {
            filtered = filtered.filter { $0.transportType == transportType }
        }

        // Apply participant filter
        if let participant = filterParticipant {
            filtered = filtered.filter { $0.participant?.id == participant.id }
        }

        // Apply upcoming filter
        if showUpcomingOnly {
            filtered = filtered.filter { $0.isUpcoming }
        }

        // Sort
        switch sortOrder {
        case .departureTime:
            transportLegs = filtered.sorted {
                ($0.departureTime ?? .distantFuture) < ($1.departureTime ?? .distantFuture)
            }
        case .participant:
            transportLegs = filtered.sorted {
                ($0.participant?.name ?? "") < ($1.participant?.name ?? "")
            }
        case .type:
            transportLegs = filtered.sorted {
                if $0.transportType != $1.transportType {
                    return $0.transportType.rawValue < $1.transportType.rawValue
                }
                return ($0.departureTime ?? .distantFuture) < ($1.departureTime ?? .distantFuture)
            }
        case .status:
            transportLegs = filtered.sorted {
                if $0.status != $1.status {
                    return $0.status.rawValue < $1.status.rawValue
                }
                return ($0.departureTime ?? .distantFuture) < ($1.departureTime ?? .distantFuture)
            }
        }
    }

    // MARK: - CRUD Operations

    func addTransportLeg(_ leg: TransportLeg, to expedition: Expedition) {
        leg.expedition = expedition
        if expedition.transportLegs == nil {
            expedition.transportLegs = []
        }
        expedition.transportLegs?.append(leg)
        modelContext.insert(leg)

        logger.info("Added transport leg '\(leg.displayTitle)' to expedition")
        saveContext()
        loadTransportLegs(for: expedition)
    }

    func deleteTransportLeg(_ leg: TransportLeg, from expedition: Expedition) {
        let title = leg.displayTitle
        expedition.transportLegs?.removeAll { $0.id == leg.id }
        modelContext.delete(leg)

        logger.info("Deleted transport leg '\(title)' from expedition")
        saveContext()
        loadTransportLegs(for: expedition)
    }

    func updateTransportLeg(_ leg: TransportLeg, in expedition: Expedition) {
        logger.debug("Updated transport leg '\(leg.displayTitle)'")
        saveContext()
        loadTransportLegs(for: expedition)
    }

    // MARK: - Computed Properties

    var upcomingLegs: [TransportLeg] {
        transportLegs.filter { $0.isUpcoming }
            .sorted { ($0.departureTime ?? .distantFuture) < ($1.departureTime ?? .distantFuture) }
    }

    var flightLegs: [TransportLeg] {
        transportLegs.filter {
            $0.transportType == .flight || $0.transportType == .bushPlane ||
            $0.transportType == .charter || $0.transportType == .helicopter
        }
    }

    var groundLegs: [TransportLeg] {
        transportLegs.filter {
            $0.transportType != .flight && $0.transportType != .bushPlane &&
            $0.transportType != .charter && $0.transportType != .helicopter
        }
    }

    var groupedByDate: [(date: Date, legs: [TransportLeg])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transportLegs) { leg -> Date in
            guard let departure = leg.departureTime else {
                return Date.distantFuture
            }
            return calendar.startOfDay(for: departure)
        }
        return grouped.keys.sorted().compactMap { date in
            guard let legs = grouped[date], !legs.isEmpty else { return nil }
            return (date: date, legs: legs.sorted {
                ($0.departureTime ?? .distantFuture) < ($1.departureTime ?? .distantFuture)
            })
        }
    }

    var groupedByParticipant: [(participant: String, legs: [TransportLeg])] {
        let grouped = Dictionary(grouping: transportLegs) { $0.participant?.name ?? "Unassigned" }
        return grouped.keys.sorted().compactMap { name in
            guard let legs = grouped[name], !legs.isEmpty else { return nil }
            return (participant: name, legs: legs)
        }
    }

    var totalCost: Decimal {
        transportLegs.compactMap { $0.cost }.reduce(0, +)
    }

    var unpaidCount: Int {
        transportLegs.filter { !$0.isPaid && $0.cost != nil }.count
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
        filterType = nil
        filterParticipant = nil
        showUpcomingOnly = false
    }

    var hasActiveFilters: Bool {
        filterType != nil || filterParticipant != nil || showUpcomingOnly || !searchText.isEmpty
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save transport leg changes: \(error.localizedDescription)")
        }
    }
}
