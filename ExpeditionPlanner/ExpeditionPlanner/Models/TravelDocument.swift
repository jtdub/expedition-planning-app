import Foundation
import SwiftData

// MARK: - Document Type

enum DocumentType: String, Codable, CaseIterable {
    case passport = "Passport"
    case visa = "Visa"
    case permitCard = "Permit Card"
    case travelInsurance = "Travel Insurance"
    case vaccinationCard = "Vaccination Card"
    case healthDeclaration = "Health Declaration"
    case other = "Other"

    var icon: String {
        switch self {
        case .passport: return "book.closed"
        case .visa: return "doc.text.fill"
        case .permitCard: return "creditcard"
        case .travelInsurance: return "shield.checkered"
        case .vaccinationCard: return "syringe"
        case .healthDeclaration: return "heart.text.clipboard"
        case .other: return "doc"
        }
    }
}

// MARK: - Application Status

enum ApplicationStatus: String, Codable, CaseIterable {
    case notNeeded = "Not Needed"
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case submitted = "Submitted"
    case approved = "Approved"
    case denied = "Denied"
    case expired = "Expired"

    var icon: String {
        switch self {
        case .notNeeded: return "minus.circle"
        case .notStarted: return "circle"
        case .inProgress: return "clock"
        case .submitted: return "paperplane"
        case .approved: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .expired: return "exclamationmark.triangle"
        }
    }

    var color: String {
        switch self {
        case .notNeeded: return "gray"
        case .notStarted: return "gray"
        case .inProgress: return "blue"
        case .submitted: return "orange"
        case .approved: return "green"
        case .denied: return "red"
        case .expired: return "red"
        }
    }
}

// MARK: - Travel Document Model

@Model
final class TravelDocument {
    var id: UUID = UUID()
    var documentType: DocumentType = DocumentType.passport
    var holderName: String = ""
    var documentNumber: String = ""
    var issuingCountry: String = ""
    var issueDate: Date?
    var expiryDate: Date?
    var visaType: String = ""
    var destinationCountry: String = ""
    var applicationStatus: ApplicationStatus = ApplicationStatus.notStarted
    var applicationURL: String = ""
    var processingTime: String = ""
    var cost: Decimal?
    var costCurrency: String = "USD"
    var documentsNeeded: String = ""
    var notes: String = ""

    // Relationships
    var expedition: Expedition?

    init(
        documentType: DocumentType = .passport,
        holderName: String = ""
    ) {
        self.id = UUID()
        self.documentType = documentType
        self.holderName = holderName
    }

    // MARK: - Computed Properties

    var isExpired: Bool {
        guard let expiry = expiryDate else { return false }
        return expiry < Date()
    }

    var isExpiringSoon: Bool {
        guard let expiry = expiryDate else { return false }
        let sixMonths = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
        return expiry < sixMonths && expiry >= Date()
    }

    var daysUntilExpiry: Int? {
        guard let expiry = expiryDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiry).day
    }

    var isActionRequired: Bool {
        switch applicationStatus {
        case .notStarted, .inProgress:
            return true
        case .denied, .expired:
            return true
        default:
            return isExpired || isExpiringSoon
        }
    }

    var displayTitle: String {
        if holderName.isEmpty {
            return documentType.rawValue
        }
        return "\(documentType.rawValue) - \(holderName)"
    }

    var statusColor: String {
        if isExpired { return "red" }
        if isExpiringSoon { return "orange" }
        return applicationStatus.color
    }

    var formattedCost: String? {
        guard let amount = cost else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = costCurrency
        return formatter.string(from: NSDecimalNumber(decimal: amount))
    }

    var documentsNeededList: [String] {
        documentsNeeded
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
