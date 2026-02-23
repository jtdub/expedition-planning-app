import Foundation
import SwiftData

@Model
final class InsurancePolicy {
    var id: UUID = UUID()
    var provider: String = ""
    var policyNumber: String = ""
    var insuranceType: InsuranceType = InsuranceType.travelMedical
    var coverageStartDate: Date?
    var coverageEndDate: Date?
    var emergencyPhone: String?
    var claimsPhone: String?
    var coverageAmount: Decimal?
    var deductible: Decimal?
    var currency: String = "USD"
    var notes: String = ""
    var documentURL: String?

    // Relationship - must be optional for CloudKit
    var expedition: Expedition?

    init(
        provider: String = "",
        policyNumber: String = "",
        insuranceType: InsuranceType = .travelMedical,
        coverageStartDate: Date? = nil,
        coverageEndDate: Date? = nil,
        emergencyPhone: String? = nil,
        claimsPhone: String? = nil,
        coverageAmount: Decimal? = nil,
        deductible: Decimal? = nil,
        currency: String = "USD",
        notes: String = ""
    ) {
        self.id = UUID()
        self.provider = provider
        self.policyNumber = policyNumber
        self.insuranceType = insuranceType
        self.coverageStartDate = coverageStartDate
        self.coverageEndDate = coverageEndDate
        self.emergencyPhone = emergencyPhone
        self.claimsPhone = claimsPhone
        self.coverageAmount = coverageAmount
        self.deductible = deductible
        self.currency = currency
        self.notes = notes
    }

    // MARK: - Computed Properties

    var isActive: Bool {
        guard let start = coverageStartDate, let end = coverageEndDate else {
            return false
        }
        let now = Date()
        return now >= start && now <= end
    }

    var daysUntilExpiry: Int? {
        guard let end = coverageEndDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: end)
        return components.day
    }

    var isExpiringSoon: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days >= 0 && days <= 30
    }

    var isExpired: Bool {
        guard let end = coverageEndDate else { return false }
        return Date() > end
    }

    var statusText: String {
        if isExpired {
            return "Expired"
        } else if isActive {
            if isExpiringSoon, let days = daysUntilExpiry {
                return "Expires in \(days) days"
            }
            return "Active"
        } else if let start = coverageStartDate, start > Date() {
            return "Not Yet Active"
        }
        return "Unknown"
    }
}

// MARK: - Insurance Type

enum InsuranceType: String, Codable, CaseIterable {
    case travelMedical = "Travel Medical"
    case evacuation = "Emergency Evacuation"
    case tripCancellation = "Trip Cancellation"
    case gearEquipment = "Gear & Equipment"
    case liability = "Liability"
    case searchRescue = "Search & Rescue"

    var icon: String {
        switch self {
        case .travelMedical: return "cross.case.fill"
        case .evacuation: return "airplane.departure"
        case .tripCancellation: return "calendar.badge.exclamationmark"
        case .gearEquipment: return "backpack.fill"
        case .liability: return "shield.fill"
        case .searchRescue: return "figure.wave"
        }
    }

    var color: String {
        switch self {
        case .travelMedical: return "red"
        case .evacuation: return "orange"
        case .tripCancellation: return "blue"
        case .gearEquipment: return "green"
        case .liability: return "purple"
        case .searchRescue: return "yellow"
        }
    }

    var typeDescription: String {
        switch self {
        case .travelMedical:
            return "Covers medical expenses, hospitalization, and treatment while traveling"
        case .evacuation:
            return "Covers emergency evacuation to nearest medical facility or home country"
        case .tripCancellation:
            return "Reimburses non-refundable trip costs if you need to cancel"
        case .gearEquipment:
            return "Covers loss, theft, or damage to expedition gear and equipment"
        case .liability:
            return "Protects against claims from third parties for injury or damage"
        case .searchRescue:
            return "Covers costs of search and rescue operations"
        }
    }
}
