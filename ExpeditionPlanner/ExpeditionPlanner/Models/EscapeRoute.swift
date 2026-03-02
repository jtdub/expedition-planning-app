import Foundation
import SwiftData
import CoreLocation

// MARK: - Escape Route Type

enum EscapeRouteType: String, Codable, CaseIterable {
    case primary = "Primary"
    case alternate = "Alternate"
    case emergencyOnly = "Emergency Only"

    var icon: String {
        switch self {
        case .primary: return "arrow.uturn.backward.circle.fill"
        case .alternate: return "arrow.uturn.backward.circle"
        case .emergencyOnly: return "exclamationmark.arrow.circlepath"
        }
    }

    var color: String {
        switch self {
        case .primary: return "green"
        case .alternate: return "orange"
        case .emergencyOnly: return "red"
        }
    }

    var sortOrder: Int {
        switch self {
        case .primary: return 0
        case .alternate: return 1
        case .emergencyOnly: return 2
        }
    }
}

// MARK: - Escape Destination Type

enum EscapeDestinationType: String, Codable, CaseIterable {
    case trailhead = "Trailhead"
    case road = "Road"
    case airstrip = "Airstrip"
    case town = "Town"
    case ranger = "Ranger Station"
    case hospital = "Hospital"
    case shelter = "Shelter"
    case other = "Other"

    var icon: String {
        switch self {
        case .trailhead: return "figure.hiking"
        case .road: return "road.lanes"
        case .airstrip: return "airplane"
        case .town: return "building.2"
        case .ranger: return "shield.checkered"
        case .hospital: return "cross.case"
        case .shelter: return "house.fill"
        case .other: return "mappin.circle"
        }
    }
}

// MARK: - Difficulty Rating

enum DifficultyRating: String, Codable, CaseIterable {
    case easy = "Easy"
    case moderate = "Moderate"
    case strenuous = "Strenuous"
    case technical = "Technical"
    case extreme = "Extreme"

    var icon: String {
        switch self {
        case .easy: return "figure.walk"
        case .moderate: return "figure.hiking"
        case .strenuous: return "figure.climbing"
        case .technical: return "figure.climbing"
        case .extreme: return "exclamationmark.triangle.fill"
        }
    }

    var color: String {
        switch self {
        case .easy: return "green"
        case .moderate: return "blue"
        case .strenuous: return "orange"
        case .technical: return "red"
        case .extreme: return "purple"
        }
    }
}

// MARK: - Escape Route Model

@Model
final class EscapeRoute {
    var id: UUID = UUID()
    var name: String = ""
    var routeDescription: String = ""
    var routeType: EscapeRouteType = EscapeRouteType.primary

    // Segment link
    var startDayNumber: Int?
    var endDayNumber: Int?
    var segmentName: String = ""

    // Metrics
    var distanceMeters: Double?
    var estimatedHours: Double?
    var elevationGainMeters: Double?
    var elevationLossMeters: Double?

    // Terrain
    var terrainDescription: String = ""
    var hazards: String = ""
    var requiredGear: String = ""
    var seasonalNotes: String = ""
    var difficultyRating: DifficultyRating = DifficultyRating.moderate

    // Destination
    var destinationType: EscapeDestinationType = EscapeDestinationType.trailhead
    var destinationName: String = ""
    var destinationLatitude: Double?
    var destinationLongitude: Double?

    // Medical
    var nearestMedicalFacility: String = ""
    var medicalFacilityDistance: String = ""
    var communicationNotes: String = ""

    // Status
    var isVerified: Bool = false
    var lastVerifiedDate: Date?
    var notes: String = ""

    // Relationships
    var expedition: Expedition?

    @Relationship(deleteRule: .cascade, inverse: \EscapeWaypoint.escapeRoute)
    var waypoints: [EscapeWaypoint]?

    init(
        name: String = "",
        routeType: EscapeRouteType = .primary,
        segmentName: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.routeType = routeType
        self.segmentName = segmentName
    }

    // MARK: - Computed Properties

    var distance: Measurement<UnitLength>? {
        guard let meters = distanceMeters else { return nil }
        return Measurement(value: meters, unit: .meters)
    }

    var elevationGain: Measurement<UnitLength>? {
        guard let meters = elevationGainMeters else { return nil }
        return Measurement(value: meters, unit: .meters)
    }

    var elevationLoss: Measurement<UnitLength>? {
        guard let meters = elevationLossMeters else { return nil }
        return Measurement(value: meters, unit: .meters)
    }

    var destinationCoordinate: CLLocationCoordinate2D? {
        guard let lat = destinationLatitude, let lon = destinationLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var formattedEstimatedTime: String? {
        guard let hours = estimatedHours else { return nil }
        let wholeHours = Int(hours)
        let minutes = Int((hours - Double(wholeHours)) * 60)
        if wholeHours == 0 {
            return "\(minutes)m"
        } else if minutes == 0 {
            return "\(wholeHours)h"
        }
        return "\(wholeHours)h \(minutes)m"
    }

    var sortedWaypoints: [EscapeWaypoint] {
        (waypoints ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    var waypointCount: Int {
        (waypoints ?? []).count
    }

    var dayRangeDescription: String? {
        guard let start = startDayNumber else { return nil }
        guard let end = endDayNumber else { return "Day \(start)" }
        if start == end { return "Day \(start)" }
        return "Days \(start)-\(end)"
    }

    var hasCoordinates: Bool {
        destinationLatitude != nil && destinationLongitude != nil
    }
}

// MARK: - Escape Waypoint Model

@Model
final class EscapeWaypoint {
    var id: UUID = UUID()
    var name: String = ""
    var orderIndex: Int = 0
    var latitude: Double?
    var longitude: Double?
    var elevationMeters: Double?
    var waypointDescription: String = ""
    var hazards: String = ""
    var notes: String = ""

    var escapeRoute: EscapeRoute?

    init(
        name: String = "",
        orderIndex: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.orderIndex = orderIndex
    }

    // MARK: - Computed Properties

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var elevation: Measurement<UnitLength>? {
        guard let meters = elevationMeters else { return nil }
        return Measurement(value: meters, unit: .meters)
    }

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }
}
