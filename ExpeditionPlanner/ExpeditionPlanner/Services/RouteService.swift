import Foundation
import CoreLocation
import SwiftUI

// MARK: - Waypoint Type

enum WaypointType: String, CaseIterable, Codable {
    case startPoint = "Start Point"
    case endPoint = "End Point"
    case campsite = "Campsite"
    case resupply = "Resupply"
    case trailhead = "Trailhead"
    case summit = "Summit"
    case hazard = "Hazard"
    case shelter = "Shelter"
    case waypoint = "Waypoint"

    var icon: String {
        switch self {
        case .startPoint:
            return "flag.fill"
        case .endPoint:
            return "flag.checkered"
        case .campsite:
            return "tent.fill"
        case .resupply:
            return "shippingbox.fill"
        case .trailhead:
            return "figure.hiking"
        case .summit:
            return "mountain.2.fill"
        case .hazard:
            return "exclamationmark.triangle.fill"
        case .shelter:
            return "house.fill"
        case .waypoint:
            return "mappin"
        }
    }

    var color: Color {
        switch self {
        case .startPoint:
            return .green
        case .endPoint:
            return .red
        case .campsite:
            return .indigo
        case .resupply:
            return .brown
        case .trailhead:
            return .blue
        case .summit:
            return .orange
        case .hazard:
            return .yellow
        case .shelter:
            return .teal
        case .waypoint:
            return .gray
        }
    }

    var sortOrder: Int {
        switch self {
        case .startPoint: return 0
        case .endPoint: return 1
        case .summit: return 2
        case .hazard: return 3
        case .resupply: return 4
        case .trailhead: return 5
        case .shelter: return 6
        case .campsite: return 7
        case .waypoint: return 8
        }
    }
}

// MARK: - Route Waypoint

struct RouteWaypoint: Identifiable, Hashable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let name: String
    let type: WaypointType
    let elevationMeters: Double?
    let dayNumber: Int?
    let date: Date?
    let notes: String?
    let sourceId: UUID

    init(
        id: UUID = UUID(),
        coordinate: CLLocationCoordinate2D,
        name: String,
        type: WaypointType,
        elevationMeters: Double? = nil,
        dayNumber: Int? = nil,
        date: Date? = nil,
        notes: String? = nil,
        sourceId: UUID
    ) {
        self.id = id
        self.coordinate = coordinate
        self.name = name
        self.type = type
        self.elevationMeters = elevationMeters
        self.dayNumber = dayNumber
        self.date = date
        self.notes = notes
        self.sourceId = sourceId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Route Service

struct RouteService {
    // MARK: - Waypoint Extraction

    /// Extract waypoints from itinerary days
    static func extractWaypoints(from days: [ItineraryDay]) -> [RouteWaypoint] {
        var waypoints: [RouteWaypoint] = []
        let sortedDays = days.sorted { $0.dayNumber < $1.dayNumber }

        for (index, day) in sortedDays.enumerated() {
            // Start point of first day
            if index == 0, let coord = day.startCoordinate {
                let waypoint = RouteWaypoint(
                    coordinate: coord,
                    name: day.startLocation.isEmpty ? "Start" : day.startLocation,
                    type: .startPoint,
                    elevationMeters: day.startElevationMeters,
                    dayNumber: day.dayNumber,
                    date: day.date,
                    sourceId: day.id
                )
                waypoints.append(waypoint)
            }

            // End point of each day (campsite or endpoint for last day)
            if let coord = day.endCoordinate {
                let isLastDay = index == sortedDays.count - 1
                let isCampsite = day.campName != nil || day.nightNumber != nil

                let type: WaypointType
                if isLastDay {
                    type = .endPoint
                } else if day.activityType == .summit {
                    type = .summit
                } else if isCampsite {
                    type = .campsite
                } else {
                    type = .waypoint
                }

                let name: String
                if !day.endLocation.isEmpty {
                    name = day.endLocation
                } else if let campName = day.campName, !campName.isEmpty {
                    name = campName
                } else if isLastDay {
                    name = "End"
                } else {
                    name = "Day \(day.dayNumber)"
                }

                let waypoint = RouteWaypoint(
                    coordinate: coord,
                    name: name,
                    type: type,
                    elevationMeters: day.endElevationMeters,
                    dayNumber: day.dayNumber,
                    date: day.date,
                    notes: day.guideNotes.isEmpty ? nil : day.guideNotes,
                    sourceId: day.id
                )
                waypoints.append(waypoint)
            }
        }

        return waypoints
    }

    /// Extract waypoints from resupply points
    static func extractWaypoints(from resupplyPoints: [ResupplyPoint]) -> [RouteWaypoint] {
        resupplyPoints.compactMap { point in
            guard let coord = point.coordinate else { return nil }

            return RouteWaypoint(
                coordinate: coord,
                name: point.name.isEmpty ? "Resupply" : point.name,
                type: .resupply,
                elevationMeters: point.elevationMeters,
                dayNumber: point.dayNumber,
                date: point.expectedArrivalDate,
                notes: point.servicesString.isEmpty ? nil : point.servicesString,
                sourceId: point.id
            )
        }
    }

    /// Extract all waypoints from an expedition
    static func extractWaypoints(from expedition: Expedition) -> [RouteWaypoint] {
        var waypoints: [RouteWaypoint] = []

        // Get waypoints from itinerary
        if let days = expedition.itinerary {
            waypoints.append(contentsOf: extractWaypoints(from: days))
        }

        // Get waypoints from resupply points
        if let resupply = expedition.resupplyPoints {
            waypoints.append(contentsOf: extractWaypoints(from: resupply))
        }

        // Sort by day number, then by type
        return waypoints.sorted { lhs, rhs in
            if let lDay = lhs.dayNumber, let rDay = rhs.dayNumber {
                if lDay != rDay {
                    return lDay < rDay
                }
            } else if lhs.dayNumber != nil {
                return true
            } else if rhs.dayNumber != nil {
                return false
            }
            return lhs.type.sortOrder < rhs.type.sortOrder
        }
    }

    // MARK: - Route Building

    /// Build route coordinates from itinerary days
    static func buildRoute(from days: [ItineraryDay]) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        let sortedDays = days.sorted { $0.dayNumber < $1.dayNumber }

        for day in sortedDays {
            if let start = day.startCoordinate {
                // Only add start if different from last coordinate
                if let last = coordinates.last {
                    if !coordinatesEqual(last, start) {
                        coordinates.append(start)
                    }
                } else {
                    coordinates.append(start)
                }
            }

            if let end = day.endCoordinate {
                // Only add end if different from last coordinate
                if let last = coordinates.last {
                    if !coordinatesEqual(last, end) {
                        coordinates.append(end)
                    }
                } else {
                    coordinates.append(end)
                }
            }
        }

        return coordinates
    }

    /// Check if two coordinates are approximately equal
    private static func coordinatesEqual(
        _ lhs: CLLocationCoordinate2D,
        _ rhs: CLLocationCoordinate2D,
        tolerance: Double = 0.0001
    ) -> Bool {
        abs(lhs.latitude - rhs.latitude) < tolerance &&
        abs(lhs.longitude - rhs.longitude) < tolerance
    }

    // MARK: - Statistics

    struct RouteStatistics {
        let totalDistanceMeters: Double
        let waypointCount: Int
        let campsiteCount: Int
        let resupplyCount: Int
        let summitCount: Int
        let highestElevationMeters: Double?
        let lowestElevationMeters: Double?
    }

    /// Calculate route statistics
    static func statistics(waypoints: [RouteWaypoint], route: [CLLocationCoordinate2D]) -> RouteStatistics {
        let totalDistance = DistanceService.totalDistance(along: route)

        let elevations = waypoints.compactMap { $0.elevationMeters }
        let highest = elevations.max()
        let lowest = elevations.min()

        return RouteStatistics(
            totalDistanceMeters: totalDistance,
            waypointCount: waypoints.count,
            campsiteCount: waypoints.filter { $0.type == .campsite }.count,
            resupplyCount: waypoints.filter { $0.type == .resupply }.count,
            summitCount: waypoints.filter { $0.type == .summit }.count,
            highestElevationMeters: highest,
            lowestElevationMeters: lowest
        )
    }

    // MARK: - Filtering

    /// Filter waypoints by type
    static func filter(waypoints: [RouteWaypoint], by types: Set<WaypointType>) -> [RouteWaypoint] {
        guard !types.isEmpty else { return waypoints }
        return waypoints.filter { types.contains($0.type) }
    }

    /// Filter waypoints by day range
    static func filter(
        waypoints: [RouteWaypoint],
        fromDay: Int?,
        toDay: Int?
    ) -> [RouteWaypoint] {
        waypoints.filter { waypoint in
            guard let day = waypoint.dayNumber else { return true }

            if let from = fromDay, day < from {
                return false
            }
            if let to = toDay, day > to {
                return false
            }
            return true
        }
    }
}
