import Foundation
import SwiftData

@Model
final class GearItem {
    var id: UUID = UUID()
    var name: String = ""
    var category: GearCategory = GearCategory.personalItems
    var priority: GearPriority = GearPriority.suggested
    var descriptionOrPurpose: String = ""
    var exampleProduct: String = ""
    var moreInfoURL: String?

    // Weight tracking
    var weightGrams: Double?

    // Selection and status
    var selection: String = ""
    var preHikeComments: String = ""
    var postHikeComments: String = ""
    var alternateItem: String = ""

    // Checklist status
    var isWeighed: Bool = false
    var isInHand: Bool = false
    var isPacked: Bool = false

    // Quantity
    var quantity: Int = 1

    // Relationship - must be optional for CloudKit
    var expedition: Expedition?

    init(
        name: String = "",
        category: GearCategory = .personalItems,
        priority: GearPriority = .suggested,
        descriptionOrPurpose: String = "",
        exampleProduct: String = "",
        selection: String = "",
        quantity: Int = 1
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.priority = priority
        self.descriptionOrPurpose = descriptionOrPurpose
        self.exampleProduct = exampleProduct
        self.selection = selection
        self.quantity = quantity
    }

    // MARK: - Computed Properties

    var weight: Measurement<UnitMass>? {
        guard let grams = weightGrams else { return nil }
        return Measurement(value: grams, unit: .grams)
    }

    var totalWeight: Measurement<UnitMass>? {
        guard let grams = weightGrams else { return nil }
        return Measurement(value: grams * Double(quantity), unit: .grams)
    }

    var isComplete: Bool {
        isWeighed && isInHand && isPacked
    }

    var statusIcon: String {
        if isPacked { return "checkmark.circle.fill" }
        if isInHand { return "shippingbox.fill" }
        if isWeighed { return "scalemass.fill" }
        return "circle"
    }
}

// MARK: - Gear Category (13 categories from Alaska 2026 Gear)

enum GearCategory: String, Codable, CaseIterable {
    case goSuitClothing = "Go Suit Clothing"
    case footwear = "Footwear"
    case elementProtection = "Element Protection"
    case stopAndSleep = "Stop & Sleep Clothing"
    case packing = "Packing"
    case shelter = "Shelter"
    case sleep = "Sleep System"
    case kitchen = "Kitchen"
    case hydration = "Hydration"
    case navigation = "Navigation"
    case toolsFirstAidEmergency = "Tools & Emergency"
    case personalItems = "Personal Items"
    case electronics = "Electronics"

    var icon: String {
        switch self {
        case .goSuitClothing: return "tshirt"
        case .footwear: return "shoe"
        case .elementProtection: return "cloud.rain"
        case .stopAndSleep: return "moon.stars"
        case .packing: return "bag"
        case .shelter: return "tent"
        case .sleep: return "bed.double"
        case .kitchen: return "fork.knife"
        case .hydration: return "drop"
        case .navigation: return "map"
        case .toolsFirstAidEmergency: return "cross.case"
        case .personalItems: return "person"
        case .electronics: return "battery.100"
        }
    }

    var sortOrder: Int {
        switch self {
        case .goSuitClothing: return 0
        case .footwear: return 1
        case .elementProtection: return 2
        case .stopAndSleep: return 3
        case .packing: return 4
        case .shelter: return 5
        case .sleep: return 6
        case .kitchen: return 7
        case .hydration: return 8
        case .navigation: return 9
        case .toolsFirstAidEmergency: return 10
        case .personalItems: return 11
        case .electronics: return 12
        }
    }
}

// MARK: - Gear Priority

enum GearPriority: String, Codable, CaseIterable {
    case critical = "Critical"
    case suggested = "Suggested"
    case optional = "Optional"
    case contingent = "Contingent"

    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .suggested: return "checkmark.circle"
        case .optional: return "questionmark.circle"
        case .contingent: return "arrow.triangle.branch"
        }
    }

    var color: String {
        switch self {
        case .critical: return "red"
        case .suggested: return "green"
        case .optional: return "blue"
        case .contingent: return "orange"
        }
    }

    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .suggested: return 1
        case .optional: return 2
        case .contingent: return 3
        }
    }
}
