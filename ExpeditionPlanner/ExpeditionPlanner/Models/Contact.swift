import Foundation
import SwiftData

@Model
final class Contact {
    var id: UUID = UUID()
    var name: String = ""
    var role: String = ""
    var organization: String?
    var phone: String?
    var cellPhone: String?
    var email: String?
    var address: String?
    var hours: String?
    var notes: String = ""
    var location: String = ""
    var category: ContactCategory = ContactCategory.localResource

    // Priority for emergency contacts
    var isEmergencyContact: Bool = false
    var emergencyPriority: Int?

    // Relationship - must be optional for CloudKit
    var expedition: Expedition?

    init(
        name: String = "",
        role: String = "",
        category: ContactCategory = .localResource,
        location: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.role = role
        self.category = category
        self.location = location
    }

    // MARK: - Computed Properties

    var primaryPhone: String? {
        cellPhone ?? phone
    }

    var hasContactInfo: Bool {
        phone != nil || cellPhone != nil || email != nil
    }

    var displaySubtitle: String {
        [role, organization].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " • ")
    }
}

// MARK: - Contact Category

enum ContactCategory: String, Codable, CaseIterable {
    case emergency = "Emergency"
    case localResource = "Local Resource"
    case accommodation = "Accommodation"
    case transport = "Transport"
    case resupply = "Resupply"
    case government = "Government"
    case medical = "Medical"
    case guide = "Guide/Outfitter"

    var icon: String {
        switch self {
        case .emergency: return "exclamationmark.triangle.fill"
        case .localResource: return "person.2"
        case .accommodation: return "bed.double"
        case .transport: return "airplane"
        case .resupply: return "shippingbox"
        case .government: return "building.columns"
        case .medical: return "cross.case"
        case .guide: return "figure.hiking"
        }
    }

    var color: String {
        switch self {
        case .emergency: return "red"
        case .localResource: return "blue"
        case .accommodation: return "purple"
        case .transport: return "orange"
        case .resupply: return "brown"
        case .government: return "gray"
        case .medical: return "pink"
        case .guide: return "green"
        }
    }
}
