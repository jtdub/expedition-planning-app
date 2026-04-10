import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.expedition.planner", category: "GearViewModel")

enum GearSortOrder: String, CaseIterable {
    case category = "Category"
    case priority = "Priority"
    case name = "Name"
    case weight = "Weight"
    case carrier = "Carrier"
}

@Observable
final class GearViewModel {
    // MARK: - Properties

    private(set) var expedition: Expedition
    private var modelContext: ModelContext

    // Filtering and sorting
    var searchText: String = ""
    var filterCategory: GearCategory?
    var filterPriority: GearPriority?
    var filterOwnership: GearOwnershipType?
    var showUnpackedOnly: Bool = false
    var sortOrder: GearSortOrder = .category

    // Error handling
    var errorMessage: String?

    // MARK: - Initialization

    init(expedition: Expedition, modelContext: ModelContext) {
        self.expedition = expedition
        self.modelContext = modelContext
    }

    // MARK: - Computed Properties - Items

    var allItems: [GearItem] {
        expedition.gearItems ?? []
    }

    var sortedItems: [GearItem] {
        let items = allItems
        switch sortOrder {
        case .category:
            return items.sorted { item1, item2 in
                if item1.category.sortOrder != item2.category.sortOrder {
                    return item1.category.sortOrder < item2.category.sortOrder
                }
                return item1.priority.sortOrder < item2.priority.sortOrder
            }
        case .priority:
            return items.sorted { item1, item2 in
                if item1.priority.sortOrder != item2.priority.sortOrder {
                    return item1.priority.sortOrder < item2.priority.sortOrder
                }
                return item1.name < item2.name
            }
        case .name:
            return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .weight:
            return items.sorted { item1, item2 in
                let weight1 = item1.totalWeight?.value ?? 0
                let weight2 = item2.totalWeight?.value ?? 0
                return weight1 > weight2
            }
        case .carrier:
            return items.sorted {
                $0.carriedByName.localizedCaseInsensitiveCompare($1.carriedByName) == .orderedAscending
            }
        }
    }

    var filteredItems: [GearItem] {
        var items = sortedItems

        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.descriptionOrPurpose.localizedCaseInsensitiveContains(searchText) ||
                item.selection.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply ownership filter
        if let ownership = filterOwnership {
            items = items.filter { $0.ownershipType == ownership }
        }

        // Apply category filter
        if let category = filterCategory {
            items = items.filter { $0.category == category }
        }

        // Apply priority filter
        if let priority = filterPriority {
            items = items.filter { $0.priority == priority }
        }

        // Apply packed filter
        if showUnpackedOnly {
            items = items.filter { !$0.isPacked }
        }

        return items
    }

    var groupedByCategory: [(category: GearCategory, items: [GearItem])] {
        let grouped = Dictionary(grouping: filteredItems) { $0.category }
        return GearCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category: category, items: items)
        }
    }

    // MARK: - Computed Properties - Counts

    var itemCount: Int {
        allItems.count
    }

    var packedCount: Int {
        allItems.filter { $0.isPacked }.count
    }

    var completionPercentage: Double {
        guard itemCount > 0 else { return 0 }
        return Double(packedCount) / Double(itemCount)
    }

    var categoryItemCounts: [GearCategory: Int] {
        var counts: [GearCategory: Int] = [:]
        for item in allItems {
            counts[item.category, default: 0] += 1
        }
        return counts
    }

    var priorityItemCounts: [GearPriority: Int] {
        var counts: [GearPriority: Int] = [:]
        for item in allItems {
            counts[item.priority, default: 0] += 1
        }
        return counts
    }

    // MARK: - Computed Properties - Weights

    var totalWeightGrams: Double {
        allItems.compactMap { $0.totalWeight?.value }.reduce(0, +)
    }

    var packedWeightGrams: Double {
        allItems.filter { $0.isPacked }.compactMap { $0.totalWeight?.value }.reduce(0, +)
    }

    var categoryWeightsGrams: [GearCategory: Double] {
        var weights: [GearCategory: Double] = [:]
        for item in allItems {
            if let weight = item.totalWeight?.value {
                weights[item.category, default: 0] += weight
            }
        }
        return weights
    }

    // MARK: - Group Gear & Weight Distribution

    var groupItems: [GearItem] {
        allItems.filter { $0.ownershipType == .group }
    }

    var groupWeightGrams: Double {
        groupItems.compactMap { $0.totalWeight?.value }.reduce(0, +)
    }

    var unassignedGroupItems: [GearItem] {
        groupItems.filter { $0.carriedBy == nil }
    }

    var unassignedGroupWeightGrams: Double {
        unassignedGroupItems.compactMap { $0.totalWeight?.value }.reduce(0, +)
    }

    func weightForParticipant(_ participant: Participant) -> Double {
        allItems
            .filter { $0.carriedBy?.id == participant.id }
            .compactMap { $0.totalWeight?.value }
            .reduce(0, +)
    }

    var weightByParticipant: [(participant: Participant, weightGrams: Double)] {
        let participants = expedition.participants ?? []
        return participants.map { participant in
            (participant: participant, weightGrams: weightForParticipant(participant))
        }
        .filter { $0.weightGrams > 0 }
        .sorted { $0.weightGrams > $1.weightGrams }
    }

    // MARK: - Weight Formatting

    func formatWeight(_ grams: Double, unit: WeightUnit) -> String {
        switch unit {
        case .kilograms:
            let kg = grams / 1000
            if kg >= 1 {
                return String(format: "%.1f kg", kg)
            } else {
                return String(format: "%.0f g", grams)
            }
        case .pounds:
            let lbs = grams / 453.592
            if lbs >= 1 {
                return String(format: "%.1f lb", lbs)
            } else {
                let oz = grams / 28.3495
                return String(format: "%.1f oz", oz)
            }
        case .ounces:
            let oz = grams / 28.3495
            return String(format: "%.1f oz", oz)
        }
    }

    // MARK: - CRUD Operations

    func addItem(
        name: String,
        category: GearCategory = .personalItems,
        priority: GearPriority = .suggested,
        descriptionOrPurpose: String = "",
        exampleProduct: String = "",
        selection: String = "",
        quantity: Int = 1
    ) -> GearItem {
        let item = GearItem(
            name: name,
            category: category,
            priority: priority,
            descriptionOrPurpose: descriptionOrPurpose,
            exampleProduct: exampleProduct,
            selection: selection,
            quantity: quantity
        )

        item.expedition = expedition
        if expedition.gearItems == nil {
            expedition.gearItems = []
        }
        expedition.gearItems?.append(item)
        modelContext.insert(item)

        logger.info("Added gear item '\(name)' to expedition \(self.expedition.name)")
        save()

        return item
    }

    func deleteItem(_ item: GearItem) {
        let itemName = item.name
        expedition.gearItems?.removeAll { $0.id == item.id }
        modelContext.delete(item)

        logger.info("Deleted gear item '\(itemName)' from expedition \(self.expedition.name)")
        save()
    }

    func deleteItems(at offsets: IndexSet, in items: [GearItem]) {
        let itemsToDelete = offsets.map { items[$0] }
        for item in itemsToDelete {
            deleteItem(item)
        }
    }

    // MARK: - Carrier Assignment

    func assignCarrier(_ participant: Participant?, to item: GearItem) {
        item.carriedBy = participant
        logger.info("Assigned carrier '\(participant?.displayName ?? "none")' to gear '\(item.name)'")
        save()
    }

    // MARK: - Status Toggles

    func togglePacked(_ item: GearItem) {
        item.isPacked.toggle()
        logger.debug("Toggled packed status for '\(item.name)' to \(item.isPacked)")
        save()
    }

    func toggleInHand(_ item: GearItem) {
        item.isInHand.toggle()
        logger.debug("Toggled in-hand status for '\(item.name)' to \(item.isInHand)")
        save()
    }

    func toggleWeighed(_ item: GearItem) {
        item.isWeighed.toggle()
        logger.debug("Toggled weighed status for '\(item.name)' to \(item.isWeighed)")
        save()
    }

    // MARK: - Filtering

    func setFilter(category: GearCategory?) {
        filterCategory = category
    }

    func setFilter(priority: GearPriority?) {
        filterPriority = priority
    }

    func clearFilters() {
        filterCategory = nil
        filterPriority = nil
        filterOwnership = nil
        showUnpackedOnly = false
        searchText = ""
    }

    var hasActiveFilters: Bool {
        filterCategory != nil || filterPriority != nil || filterOwnership != nil
            || showUnpackedOnly || !searchText.isEmpty
    }

    // MARK: - Persistence

    private func save() {
        do {
            try modelContext.save()
            expedition.updatedAt = Date()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save gear changes: \(error.localizedDescription)")
        }
    }
}
