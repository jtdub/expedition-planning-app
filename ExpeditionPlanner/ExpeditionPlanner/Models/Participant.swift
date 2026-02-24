import Foundation
import SwiftData

@Model
final class Participant {
    var id: UUID = UUID()
    var name: String = ""
    var nickname: String?
    var email: String = ""
    var phone: String = ""
    var role: ParticipantRole = ParticipantRole.participant
    var groupAssignment: String = ""
    var scheduleType: String = ""

    // Travel info
    var arrivalFlightInfo: String = ""
    var departureFlightInfo: String = ""
    var arrivalDate: Date?
    var departureDate: Date?

    // Accommodation
    var hotelReservation: String?
    var roomAssignment: String?

    // Personal info
    var dietaryRestrictions: String?
    var medicalNotes: String?
    var emergencyContactName: String?
    var emergencyContactPhone: String?

    // Status
    var isConfirmed: Bool = false
    var hasPaid: Bool = false
    var notes: String = ""

    // Relationships - must be optional for CloudKit
    var expedition: Expedition?

    @Relationship(deleteRule: .nullify, inverse: \TransportLeg.participant)
    var transportLegs: [TransportLeg]?

    init(
        name: String = "",
        email: String = "",
        phone: String = "",
        role: ParticipantRole = .participant,
        groupAssignment: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.phone = phone
        self.role = role
        self.groupAssignment = groupAssignment
    }

    // MARK: - Computed Properties

    var displayName: String {
        nickname ?? name
    }

    var initials: String {
        let components = name.split(separator: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.prefix(2).joined()
    }
}

// MARK: - Participant Role

enum ParticipantRole: String, Codable, CaseIterable {
    case guide = "Guide"
    case assistantGuide = "Assistant Guide"
    case participant = "Participant"
    case client = "Client"
    case researcher = "Researcher"
    case photographer = "Photographer"
    case support = "Support"

    var icon: String {
        switch self {
        case .guide: return "star.fill"
        case .assistantGuide: return "star.leadinghalf.filled"
        case .participant: return "person"
        case .client: return "person.fill"
        case .researcher: return "magnifyingglass"
        case .photographer: return "camera"
        case .support: return "wrench.and.screwdriver"
        }
    }

    var isStaff: Bool {
        switch self {
        case .guide, .assistantGuide, .support:
            return true
        default:
            return false
        }
    }
}
