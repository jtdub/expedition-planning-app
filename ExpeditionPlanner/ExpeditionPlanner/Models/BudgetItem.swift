import Foundation
import SwiftData

@Model
final class BudgetItem {
    var id: UUID = UUID()
    var name: String = ""
    var budgetDescription: String = ""
    var category: BudgetCategory = BudgetCategory.other

    // Amounts
    var estimatedAmount: Decimal = 0
    var actualAmount: Decimal?
    var currency: String = "USD"
    var exchangeRate: Decimal?

    // Payment status
    var isPaid: Bool = false
    var paidDate: Date?
    var paymentMethod: String?

    // Date
    var dateIncurred: Date?
    var dueDate: Date?

    // Receipt
    var hasReceipt: Bool = false
    var receiptFileName: String?

    // Vendor
    var vendor: String?

    var notes: String = ""

    // Relationship - must be optional for CloudKit
    var expedition: Expedition?

    init(
        name: String = "",
        category: BudgetCategory = .other,
        estimatedAmount: Decimal = 0,
        currency: String = "USD"
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.estimatedAmount = estimatedAmount
        self.currency = currency
    }

    // MARK: - Computed Properties

    var amountInUSD: Decimal? {
        guard let rate = exchangeRate, rate > 0 else {
            return currency == "USD" ? estimatedAmount : nil
        }
        return estimatedAmount / rate
    }

    var actualInUSD: Decimal? {
        guard let actual = actualAmount,
              let rate = exchangeRate, rate > 0 else {
            return currency == "USD" ? actualAmount : nil
        }
        return actual / rate
    }

    var variance: Decimal? {
        guard let actual = actualAmount else { return nil }
        return actual - estimatedAmount
    }

    var variancePercentage: Double? {
        guard let variance = variance, estimatedAmount > 0 else { return nil }
        return NSDecimalNumber(decimal: variance / estimatedAmount * 100).doubleValue
    }

    var isOverBudget: Bool {
        guard let variance = variance else { return false }
        return variance > 0
    }

    var formattedEstimate: String {
        formatCurrency(estimatedAmount)
    }

    var formattedActual: String? {
        guard let actual = actualAmount else { return nil }
        return formatCurrency(actual)
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(currency) \(amount)"
    }
}

// MARK: - Budget Category

enum BudgetCategory: String, Codable, CaseIterable {
    case flights = "Flights"
    case lodging = "Lodging"
    case transport = "Ground Transport"
    case permits = "Permits & Fees"
    case gear = "Gear & Equipment"
    case food = "Food & Supplies"
    case guides = "Guides & Staff"
    case insurance = "Insurance"
    case communication = "Communication"
    case emergency = "Emergency Fund"
    case other = "Other"

    var icon: String {
        switch self {
        case .flights: return "airplane"
        case .lodging: return "bed.double"
        case .transport: return "car"
        case .permits: return "doc.text"
        case .gear: return "backpack"
        case .food: return "fork.knife"
        case .guides: return "person.2"
        case .insurance: return "shield"
        case .communication: return "antenna.radiowaves.left.and.right"
        case .emergency: return "cross.case"
        case .other: return "ellipsis.circle"
        }
    }

    var color: String {
        switch self {
        case .flights: return "blue"
        case .lodging: return "purple"
        case .transport: return "orange"
        case .permits: return "gray"
        case .gear: return "green"
        case .food: return "brown"
        case .guides: return "teal"
        case .insurance: return "indigo"
        case .communication: return "cyan"
        case .emergency: return "red"
        case .other: return "gray"
        }
    }
}
