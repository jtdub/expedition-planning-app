import Foundation
import SwiftData

@Model
final class RiskAssessment {
    var id: UUID = UUID()
    var title: String = ""
    var riskDescription: String = ""
    var hazardType: HazardType = HazardType.terrain

    // Risk matrix
    var likelihood: RiskLevel = RiskLevel.medium
    var severity: RiskLevel = RiskLevel.medium

    // Mitigation
    var mitigationStrategy: String = ""
    var preventionMeasures: String = ""
    var emergencyProcedure: String = ""

    // Context
    var location: String?
    var seasonalNotes: String?
    var sourceNotes: String?

    // Status
    var isAddressed: Bool = false
    var reviewDate: Date?

    var notes: String = ""

    // Relationship - must be optional for CloudKit
    var expedition: Expedition?

    init(
        title: String = "",
        hazardType: HazardType = .terrain,
        likelihood: RiskLevel = .medium,
        severity: RiskLevel = .medium
    ) {
        self.id = UUID()
        self.title = title
        self.hazardType = hazardType
        self.likelihood = likelihood
        self.severity = severity
    }

    // MARK: - Computed Properties

    var riskScore: Int {
        likelihood.value * severity.value
    }

    var riskRating: RiskRating {
        switch riskScore {
        case 1...3: return .low
        case 4...6: return .medium
        case 7...12: return .high
        default: return .critical
        }
    }

    var riskColor: String {
        riskRating.color
    }

    var needsAttention: Bool {
        !isAddressed && riskRating.rawValue >= RiskRating.high.rawValue
    }
}

// MARK: - Hazard Type

enum HazardType: String, Codable, CaseIterable {
    case wildlife = "Wildlife"
    case weather = "Weather"
    case terrain = "Terrain"
    case altitude = "Altitude"
    case water = "Water/River"
    case avalanche = "Avalanche"
    case navigation = "Navigation"
    case equipment = "Equipment"
    case medical = "Medical"
    case human = "Human Factors"

    var icon: String {
        switch self {
        case .wildlife: return "pawprint"
        case .weather: return "cloud.bolt"
        case .terrain: return "mountain.2"
        case .altitude: return "arrow.up.to.line"
        case .water: return "water.waves"
        case .avalanche: return "snow"
        case .navigation: return "location.slash"
        case .equipment: return "wrench.and.screwdriver"
        case .medical: return "cross.case"
        case .human: return "person.crop.circle.badge.exclamationmark"
        }
    }
}

// MARK: - Risk Level

enum RiskLevel: String, Codable, CaseIterable {
    case veryLow = "Very Low"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case veryHigh = "Very High"

    var value: Int {
        switch self {
        case .veryLow: return 1
        case .low: return 2
        case .medium: return 3
        case .high: return 4
        case .veryHigh: return 5
        }
    }
}

// MARK: - Risk Rating (computed from likelihood x severity)

enum RiskRating: Int, Codable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3

    var label: String {
        switch self {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        case .critical: return "Critical Risk"
        }
    }

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }

    var icon: String {
        switch self {
        case .low: return "checkmark.shield"
        case .medium: return "exclamationmark.shield"
        case .high: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
}
