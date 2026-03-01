import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.chaki.app", category: "AccommodationViewModel")

enum AccommodationSortOrder: String, CaseIterable {
    case checkInDate = "Check-in Date"
    case name = "Name"
    case type = "Type"
    case status = "Status"
    case city = "City"
}

@Observable
final class AccommodationViewModel {
    private var modelContext: ModelContext

    var accommodations: [Accommodation] = []
    var searchText: String = ""
    var filterType: AccommodationType?
    var filterStatus: AccommodationStatus?
    var showUpcomingOnly: Bool = false
    var sortOrder: AccommodationSortOrder = .checkInDate
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadAccommodations(for expedition: Expedition) {
        let allAccommodations = expedition.accommodations ?? []

        var filtered = allAccommodations

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { accommodation in
                accommodation.name.localizedCaseInsensitiveContains(searchText) ||
                accommodation.city.localizedCaseInsensitiveContains(searchText) ||
                accommodation.address.localizedCaseInsensitiveContains(searchText) ||
                accommodation.confirmationNumber.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply type filter
        if let accType = filterType {
            filtered = filtered.filter { $0.accommodationType == accType }
        }

        // Apply status filter
        if let status = filterStatus {
            filtered = filtered.filter { $0.status == status }
        }

        // Apply upcoming filter
        if showUpcomingOnly {
            filtered = filtered.filter { $0.isUpcoming || $0.isCurrent }
        }

        // Sort
        switch sortOrder {
        case .checkInDate:
            accommodations = filtered.sorted {
                ($0.checkInDate ?? .distantFuture) < ($1.checkInDate ?? .distantFuture)
            }
        case .name:
            accommodations = filtered.sorted { $0.name < $1.name }
        case .type:
            accommodations = filtered.sorted {
                if $0.accommodationType != $1.accommodationType {
                    return $0.accommodationType.rawValue < $1.accommodationType.rawValue
                }
                return ($0.checkInDate ?? .distantFuture) < ($1.checkInDate ?? .distantFuture)
            }
        case .status:
            accommodations = filtered.sorted {
                if $0.status != $1.status {
                    return $0.status.rawValue < $1.status.rawValue
                }
                return ($0.checkInDate ?? .distantFuture) < ($1.checkInDate ?? .distantFuture)
            }
        case .city:
            accommodations = filtered.sorted {
                if $0.city != $1.city {
                    return $0.city < $1.city
                }
                return ($0.checkInDate ?? .distantFuture) < ($1.checkInDate ?? .distantFuture)
            }
        }
    }

    // MARK: - CRUD Operations

    func addAccommodation(_ accommodation: Accommodation, to expedition: Expedition) {
        accommodation.expedition = expedition
        if expedition.accommodations == nil {
            expedition.accommodations = []
        }
        expedition.accommodations?.append(accommodation)
        modelContext.insert(accommodation)

        logger.info("Added accommodation '\(accommodation.name)' to expedition")
        saveContext()
        loadAccommodations(for: expedition)
    }

    func deleteAccommodation(_ accommodation: Accommodation, from expedition: Expedition) {
        let name = accommodation.name
        expedition.accommodations?.removeAll { $0.id == accommodation.id }
        modelContext.delete(accommodation)

        logger.info("Deleted accommodation '\(name)' from expedition")
        saveContext()
        loadAccommodations(for: expedition)
    }

    func updateAccommodation(_ accommodation: Accommodation, in expedition: Expedition) {
        logger.debug("Updated accommodation '\(accommodation.name)'")
        saveContext()
        loadAccommodations(for: expedition)
    }

    // MARK: - Computed Properties

    var upcomingAccommodations: [Accommodation] {
        accommodations.filter { $0.isUpcoming }
            .sorted { ($0.checkInDate ?? .distantFuture) < ($1.checkInDate ?? .distantFuture) }
    }

    var currentAccommodation: Accommodation? {
        accommodations.first { $0.isCurrent }
    }

    var totalNights: Int {
        accommodations.reduce(0) { $0 + $1.numberOfNights }
    }

    var totalCost: Decimal {
        accommodations.compactMap { $0.calculatedTotalCost }.reduce(0, +)
    }

    var unpaidCount: Int {
        accommodations.filter { !$0.isPaid && $0.totalCost != nil }.count
    }

    var groupedByCity: [(city: String, accommodations: [Accommodation])] {
        let grouped = Dictionary(grouping: accommodations) {
            $0.city.isEmpty ? "Unspecified" : $0.city
        }
        return grouped.keys.sorted().compactMap { city in
            guard let list = grouped[city], !list.isEmpty else { return nil }
            return (city: city, accommodations: list.sorted {
                ($0.checkInDate ?? .distantFuture) < ($1.checkInDate ?? .distantFuture)
            })
        }
    }

    var groupedByType: [(type: AccommodationType, accommodations: [Accommodation])] {
        let grouped = Dictionary(grouping: accommodations) { $0.accommodationType }
        return AccommodationType.allCases.compactMap { type in
            guard let list = grouped[type], !list.isEmpty else { return nil }
            return (type: type, accommodations: list)
        }
    }

    var confirmedCount: Int {
        accommodations.filter { $0.status == .confirmed || $0.status == .checkedIn }.count
    }

    var needsConfirmationCount: Int {
        accommodations.filter {
            $0.status == .reserved || $0.status == .contacted || $0.status == .researching
        }.count
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
        filterType = nil
        filterStatus = nil
        showUpcomingOnly = false
    }

    var hasActiveFilters: Bool {
        filterType != nil || filterStatus != nil || showUpcomingOnly || !searchText.isEmpty
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save accommodation changes: \(error.localizedDescription)")
        }
    }
}
