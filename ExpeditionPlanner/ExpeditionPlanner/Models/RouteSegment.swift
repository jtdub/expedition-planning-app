import Foundation
import SwiftData

// MARK: - Terrain Type

enum TerrainType: String, Codable, CaseIterable {
    case tundra = "Tundra"
    case tussock = "Tussock"
    case riverCrossing = "River Crossing"
    case scree = "Scree"
    case glacier = "Glacier"
    case forest = "Forest"
    case trail = "Trail"
    case bushwhack = "Bushwhack"
    case ridgeline = "Ridgeline"
    case snowfield = "Snowfield"
    case other = "Other"

    var icon: String {
        switch self {
        case .tundra: return "leaf"
        case .tussock: return "leaf.fill"
        case .riverCrossing: return "water.waves"
        case .scree: return "triangle.fill"
        case .glacier: return "snowflake"
        case .forest: return "tree"
        case .trail: return "figure.hiking"
        case .bushwhack: return "leaf.arrow.triangle.circlepath"
        case .ridgeline: return "mountain.2"
        case .snowfield: return "cloud.snow"
        case .other: return "mappin.circle"
        }
    }

    var color: String {
        switch self {
        case .tundra: return "green"
        case .tussock: return "brown"
        case .riverCrossing: return "blue"
        case .scree: return "gray"
        case .glacier: return "cyan"
        case .forest: return "green"
        case .trail: return "orange"
        case .bushwhack: return "red"
        case .ridgeline: return "purple"
        case .snowfield: return "cyan"
        case .other: return "gray"
        }
    }
}

// MARK: - Route Segment Model

@Model
final class RouteSegment {
    var id: UUID = UUID()
    var name: String = ""
    var startDayNumber: Int?
    var endDayNumber: Int?
    var distanceMeters: Double?
    var elevationGainMeters: Double?
    var elevationLossMeters: Double?
    var estimatedHours: Double?
    var terrainType: TerrainType = TerrainType.tundra
    var terrainDescription: String = ""
    var hazards: String = ""
    var navigationNotes: String = ""
    var seasonalNotes: String = ""
    var waterNotes: String = ""
    var campingNotes: String = ""
    var difficultyRating: DifficultyRating = DifficultyRating.moderate
    var notes: String = ""

    // Relationships
    var expedition: Expedition?

    init(
        name: String = "",
        terrainType: TerrainType = .tundra,
        difficultyRating: DifficultyRating = .moderate
    ) {
        self.id = UUID()
        self.name = name
        self.terrainType = terrainType
        self.difficultyRating = difficultyRating
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

    var dayRangeDescription: String? {
        guard let start = startDayNumber else { return nil }
        guard let end = endDayNumber else { return "Day \(start)" }
        if start == end { return "Day \(start)" }
        return "Days \(start)-\(end)"
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
}
