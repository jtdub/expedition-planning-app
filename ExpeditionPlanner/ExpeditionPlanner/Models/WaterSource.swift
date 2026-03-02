import Foundation
import SwiftData
import CoreLocation

// MARK: - Water Source Type

enum WaterSourceType: String, Codable, CaseIterable {
    case stream = "Stream"
    case river = "River"
    case lake = "Lake"
    case pond = "Pond"
    case spring = "Spring"
    case snowmelt = "Snowmelt"
    case glacier = "Glacier"
    case well = "Well"

    var icon: String {
        switch self {
        case .stream: return "water.waves"
        case .river: return "water.waves.and.arrow.down"
        case .lake: return "drop.circle"
        case .pond: return "drop.circle.fill"
        case .spring: return "drop.triangle"
        case .snowmelt: return "snowflake"
        case .glacier: return "snowflake.circle"
        case .well: return "arrow.down.to.line.circle"
        }
    }
}

// MARK: - Reliability Rating

enum ReliabilityRating: String, Codable, CaseIterable {
    case perennial = "Perennial"
    case seasonal = "Seasonal"
    case intermittent = "Intermittent"
    case emergency = "Emergency"

    var icon: String {
        switch self {
        case .perennial: return "checkmark.circle.fill"
        case .seasonal: return "calendar.circle"
        case .intermittent: return "questionmark.circle"
        case .emergency: return "exclamationmark.triangle"
        }
    }

    var color: String {
        switch self {
        case .perennial: return "green"
        case .seasonal: return "blue"
        case .intermittent: return "orange"
        case .emergency: return "red"
        }
    }
}

// MARK: - Treatment Method

enum TreatmentMethod: String, Codable, CaseIterable {
    case none = "None"
    case filter = "Filter"
    case uv = "UV"
    case boil = "Boil"
    case chemical = "Chemical"

    var icon: String {
        switch self {
        case .none: return "hand.thumbsup"
        case .filter: return "line.3.horizontal.decrease"
        case .uv: return "sun.max"
        case .boil: return "flame"
        case .chemical: return "drop.triangle"
        }
    }
}

// MARK: - Water Source Model

@Model
final class WaterSource {
    var id: UUID = UUID()
    var name: String = ""
    var sourceType: WaterSourceType = WaterSourceType.stream
    var reliability: ReliabilityRating = ReliabilityRating.seasonal
    var treatmentRequired: TreatmentMethod = TreatmentMethod.filter
    var latitude: Double?
    var longitude: Double?
    var elevationMeters: Double?
    var seasonalNotes: String = ""
    var contaminationRisks: String = ""
    var flowRate: String = ""
    var distanceFromTrail: String = ""
    var lastVerified: Date?
    var isVerified: Bool = false
    var notes: String = ""

    // Relationships
    var expedition: Expedition?

    init(
        name: String = "",
        sourceType: WaterSourceType = .stream,
        reliability: ReliabilityRating = .seasonal
    ) {
        self.id = UUID()
        self.name = name
        self.sourceType = sourceType
        self.reliability = reliability
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

    var needsTreatment: Bool {
        treatmentRequired != .none
    }
}
