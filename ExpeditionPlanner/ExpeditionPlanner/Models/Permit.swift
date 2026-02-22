import Foundation
import SwiftData

@Model
final class Permit {
    var id: UUID = UUID()
    var name: String = ""
    var permitDescription: String = ""
    var issuingAuthority: String = ""
    var permitType: PermitType = PermitType.wilderness

    // Dates
    var applicationDeadline: Date?
    var submittedDate: Date?
    var obtainedDate: Date?
    var expirationDate: Date?

    // Status
    var status: PermitStatus = PermitStatus.notStarted

    // Contact info
    var officeAddress: String?
    var officePhone: String?
    var officeEmail: String?
    var officeHours: String?
    var websiteURL: String?

    // Cost
    var cost: Decimal?
    var currency: String = "USD"

    // Document reference
    var documentFileName: String?
    var permitNumber: String?

    var notes: String = ""

    // Relationship - must be optional for CloudKit
    var expedition: Expedition?

    init(
        name: String = "",
        issuingAuthority: String = "",
        permitType: PermitType = .wilderness
    ) {
        self.id = UUID()
        self.name = name
        self.issuingAuthority = issuingAuthority
        self.permitType = permitType
    }

    // MARK: - Computed Properties

    var isOverdue: Bool {
        guard let deadline = applicationDeadline else { return false }
        return status == .notStarted && deadline < Date()
    }

    var daysUntilDeadline: Int? {
        guard let deadline = applicationDeadline else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: deadline).day
    }

    var isComplete: Bool {
        status == .obtained || status == .approved
    }

    var statusColor: String {
        switch status {
        case .notStarted:
            return isOverdue ? "red" : "gray"
        case .inProgress:
            return "orange"
        case .submitted:
            return "blue"
        case .approved, .obtained:
            return "green"
        case .denied:
            return "red"
        case .expired:
            return "gray"
        }
    }
}

// MARK: - Permit Type

enum PermitType: String, Codable, CaseIterable {
    case wilderness = "Wilderness Permit"
    case camping = "Camping Permit"
    case research = "Research Permit"
    case commercial = "Commercial Use"
    case border = "Border Crossing"
    case hunting = "Hunting License"
    case fishing = "Fishing License"
    case drone = "Drone/UAV Permit"
    case photography = "Photography Permit"
    case other = "Other"

    var icon: String {
        switch self {
        case .wilderness: return "leaf"
        case .camping: return "tent"
        case .research: return "magnifyingglass"
        case .commercial: return "building.2"
        case .border: return "globe"
        case .hunting: return "scope"
        case .fishing: return "fish"
        case .drone: return "airplane"
        case .photography: return "camera"
        case .other: return "doc"
        }
    }
}

// MARK: - Permit Status

enum PermitStatus: String, Codable, CaseIterable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case submitted = "Submitted"
    case approved = "Approved"
    case obtained = "Obtained"
    case denied = "Denied"
    case expired = "Expired"

    var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "pencil.circle"
        case .submitted: return "paperplane"
        case .approved: return "checkmark.circle"
        case .obtained: return "checkmark.seal.fill"
        case .denied: return "xmark.circle"
        case .expired: return "clock.badge.xmark"
        }
    }
}
