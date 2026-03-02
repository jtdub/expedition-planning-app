import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.chaki.app", category: "EscapeRouteViewModel")

enum EscapeRouteSortOrder: String, CaseIterable {
    case routeType = "Route Type"
    case segment = "Segment"
    case name = "Name"
    case distance = "Distance"
}

@Observable
final class EscapeRouteViewModel {
    private var modelContext: ModelContext

    var routes: [EscapeRoute] = []
    var searchText: String = ""
    var filterRouteType: EscapeRouteType?
    var showUnverifiedOnly: Bool = false
    var sortOrder: EscapeRouteSortOrder = .routeType
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadRoutes(for expedition: Expedition) {
        let allRoutes = expedition.escapeRoutes ?? []

        var filtered = allRoutes

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { route in
                route.name.localizedCaseInsensitiveContains(searchText) ||
                route.routeDescription.localizedCaseInsensitiveContains(searchText) ||
                route.destinationName.localizedCaseInsensitiveContains(searchText) ||
                route.segmentName.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply route type filter
        if let routeType = filterRouteType {
            filtered = filtered.filter { $0.routeType == routeType }
        }

        // Apply unverified filter
        if showUnverifiedOnly {
            filtered = filtered.filter { !$0.isVerified }
        }

        // Sort
        switch sortOrder {
        case .routeType:
            routes = filtered.sorted { r1, r2 in
                if r1.routeType.sortOrder != r2.routeType.sortOrder {
                    return r1.routeType.sortOrder < r2.routeType.sortOrder
                }
                return r1.name < r2.name
            }
        case .segment:
            routes = filtered.sorted { r1, r2 in
                let s1 = r1.startDayNumber ?? Int.max
                let s2 = r2.startDayNumber ?? Int.max
                if s1 != s2 { return s1 < s2 }
                return r1.name < r2.name
            }
        case .name:
            routes = filtered.sorted { $0.name < $1.name }
        case .distance:
            routes = filtered.sorted { r1, r2 in
                let d1 = r1.distanceMeters ?? Double.infinity
                let d2 = r2.distanceMeters ?? Double.infinity
                return d1 < d2
            }
        }
    }

    // MARK: - CRUD Operations

    func addRoute(_ route: EscapeRoute, to expedition: Expedition) {
        route.expedition = expedition
        if expedition.escapeRoutes == nil {
            expedition.escapeRoutes = []
        }
        expedition.escapeRoutes?.append(route)
        modelContext.insert(route)

        logger.info("Added escape route '\(route.name)' to expedition")
        saveContext()
        loadRoutes(for: expedition)
    }

    func deleteRoute(_ route: EscapeRoute, from expedition: Expedition) {
        let name = route.name
        expedition.escapeRoutes?.removeAll { $0.id == route.id }
        modelContext.delete(route)

        logger.info("Deleted escape route '\(name)' from expedition")
        saveContext()
        loadRoutes(for: expedition)
    }

    func updateRoute(_ route: EscapeRoute, in expedition: Expedition) {
        logger.debug("Updated escape route '\(route.name)'")
        saveContext()
        loadRoutes(for: expedition)
    }

    // MARK: - Waypoint CRUD

    func addWaypoint(_ waypoint: EscapeWaypoint, to route: EscapeRoute) {
        waypoint.escapeRoute = route
        if route.waypoints == nil {
            route.waypoints = []
        }
        route.waypoints?.append(waypoint)
        modelContext.insert(waypoint)

        logger.info("Added waypoint '\(waypoint.name)' to escape route '\(route.name)'")
        saveContext()
    }

    func deleteWaypoint(_ waypoint: EscapeWaypoint, from route: EscapeRoute) {
        let name = waypoint.name
        route.waypoints?.removeAll { $0.id == waypoint.id }
        modelContext.delete(waypoint)

        logger.info("Deleted waypoint '\(name)' from escape route '\(route.name)'")
        saveContext()
    }

    func reorderWaypoints(_ waypoints: [EscapeWaypoint]) {
        for (index, waypoint) in waypoints.enumerated() {
            waypoint.orderIndex = index
        }
        saveContext()
    }

    // MARK: - Computed Properties

    var primaryRoutes: [EscapeRoute] {
        routes.filter { $0.routeType == .primary }
    }

    var unverifiedCount: Int {
        routes.filter { !$0.isVerified }.count
    }

    var routeTypeCounts: [EscapeRouteType: Int] {
        var counts: [EscapeRouteType: Int] = [:]
        for route in routes {
            counts[route.routeType, default: 0] += 1
        }
        return counts
    }

    var groupedByType: [(routeType: EscapeRouteType, routes: [EscapeRoute])] {
        let grouped = Dictionary(grouping: routes) { $0.routeType }
        return EscapeRouteType.allCases.compactMap { routeType in
            guard let list = grouped[routeType], !list.isEmpty else { return nil }
            return (routeType: routeType, routes: list)
        }
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
        filterRouteType = nil
        showUnverifiedOnly = false
    }

    var hasActiveFilters: Bool {
        filterRouteType != nil || showUnverifiedOnly || !searchText.isEmpty
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save escape route changes: \(error.localizedDescription)")
        }
    }
}
