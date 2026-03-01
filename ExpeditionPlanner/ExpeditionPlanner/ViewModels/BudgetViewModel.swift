import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.chaki.app", category: "BudgetViewModel")

enum BudgetSortOrder: String, CaseIterable {
    case category = "Category"
    case amount = "Amount"
    case date = "Date"
    case name = "Name"
}

@Observable
final class BudgetViewModel {
    private var modelContext: ModelContext

    var budgetItems: [BudgetItem] = []
    var searchText: String = ""
    var filterCategory: BudgetCategory?
    var filterPaidOnly: Bool = false
    var filterUnpaidOnly: Bool = false
    var sortOrder: BudgetSortOrder = .category
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadBudgetItems(for expedition: Expedition) {
        let allItems = expedition.budgetItems ?? []

        var filtered = allItems

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.budgetDescription.localizedCaseInsensitiveContains(searchText) ||
                (item.vendor ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply category filter
        if let category = filterCategory {
            filtered = filtered.filter { $0.category == category }
        }

        // Apply paid filters
        if filterPaidOnly {
            filtered = filtered.filter { $0.isPaid }
        }
        if filterUnpaidOnly {
            filtered = filtered.filter { !$0.isPaid }
        }

        // Sort
        switch sortOrder {
        case .category:
            budgetItems = filtered.sorted { i1, i2 in
                if i1.category != i2.category {
                    return i1.category.rawValue < i2.category.rawValue
                }
                return i1.name < i2.name
            }
        case .amount:
            budgetItems = filtered.sorted { i1, i2 in
                i1.estimatedAmount > i2.estimatedAmount
            }
        case .date:
            budgetItems = filtered.sorted { i1, i2 in
                let d1 = i1.dateIncurred ?? Date.distantFuture
                let d2 = i2.dateIncurred ?? Date.distantFuture
                return d1 < d2
            }
        case .name:
            budgetItems = filtered.sorted { $0.name < $1.name }
        }
    }

    // MARK: - CRUD Operations

    func addBudgetItem(_ item: BudgetItem, to expedition: Expedition) {
        item.expedition = expedition
        if expedition.budgetItems == nil {
            expedition.budgetItems = []
        }
        expedition.budgetItems?.append(item)
        modelContext.insert(item)

        logger.info("Added budget item '\(item.name)' to expedition")
        saveContext()
        loadBudgetItems(for: expedition)
    }

    func deleteBudgetItem(_ item: BudgetItem, from expedition: Expedition) {
        let name = item.name
        expedition.budgetItems?.removeAll { $0.id == item.id }
        modelContext.delete(item)

        logger.info("Deleted budget item '\(name)' from expedition")
        saveContext()
        loadBudgetItems(for: expedition)
    }

    func updateBudgetItem(_ item: BudgetItem, in expedition: Expedition) {
        logger.debug("Updated budget item '\(item.name)'")
        saveContext()
        loadBudgetItems(for: expedition)
    }

    // MARK: - Computed Properties - Totals

    var totalEstimated: Decimal {
        budgetItems.reduce(0) { $0 + $1.estimatedAmount }
    }

    var totalActual: Decimal {
        budgetItems.compactMap { $0.actualAmount }.reduce(0, +)
    }

    var totalVariance: Decimal {
        totalActual - totalEstimated
    }

    var paidTotal: Decimal {
        budgetItems.filter { $0.isPaid }.reduce(0) { $0 + ($1.actualAmount ?? $1.estimatedAmount) }
    }

    var unpaidTotal: Decimal {
        budgetItems.filter { !$0.isPaid }.reduce(0) { $0 + $1.estimatedAmount }
    }

    var paidCount: Int {
        budgetItems.filter { $0.isPaid }.count
    }

    var overBudgetCount: Int {
        budgetItems.filter { $0.isOverBudget }.count
    }

    // MARK: - Category Totals

    var categoryTotals: [BudgetCategory: (estimated: Decimal, actual: Decimal)] {
        var totals: [BudgetCategory: (estimated: Decimal, actual: Decimal)] = [:]
        for item in budgetItems {
            let current = totals[item.category] ?? (estimated: 0, actual: 0)
            totals[item.category] = (
                estimated: current.estimated + item.estimatedAmount,
                actual: current.actual + (item.actualAmount ?? 0)
            )
        }
        return totals
    }

    var groupedByCategory: [(category: BudgetCategory, items: [BudgetItem])] {
        let grouped = Dictionary(grouping: budgetItems) { $0.category }
        return BudgetCategory.allCases.compactMap { category in
            guard let list = grouped[category], !list.isEmpty else { return nil }
            return (category: category, items: list)
        }
    }

    // MARK: - Formatting

    func formatCurrency(_ amount: Decimal, code: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(code) \(amount)"
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
        filterCategory = nil
        filterPaidOnly = false
        filterUnpaidOnly = false
    }

    var hasActiveFilters: Bool {
        filterCategory != nil || filterPaidOnly || filterUnpaidOnly || !searchText.isEmpty
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save budget changes: \(error.localizedDescription)")
        }
    }
}
