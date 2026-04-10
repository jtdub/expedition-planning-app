import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.expedition.planner", category: "ChecklistViewModel")

enum ChecklistSortOrder: String, CaseIterable {
    case dueDate = "Due Date"
    case category = "Category"
    case status = "Status"
    case title = "Title"
}

@Observable
final class ChecklistViewModel {
    private var modelContext: ModelContext

    var items: [ChecklistItem] = []
    var searchText: String = ""
    var filterStatus: ChecklistStatus?
    var filterCategory: ChecklistCategory?
    var sortOrder: ChecklistSortOrder = .dueDate
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadItems(for expedition: Expedition) {
        let allItems = expedition.checklistItems ?? []

        var filtered = allItems

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.notes.localizedCaseInsensitiveContains(searchText) ||
                (item.assignedTo?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply status filter
        if let status = filterStatus {
            filtered = filtered.filter { $0.status == status }
        }

        // Apply category filter
        if let category = filterCategory {
            filtered = filtered.filter { $0.category == category }
        }

        // Sort
        let startDate = expedition.startDate
        switch sortOrder {
        case .dueDate:
            items = filtered.sorted {
                let date0 = $0.computedDueDate(expeditionStartDate: startDate) ?? .distantFuture
                let date1 = $1.computedDueDate(expeditionStartDate: startDate) ?? .distantFuture
                if date0 != date1 { return date0 < date1 }
                return $0.title < $1.title
            }
        case .category:
            items = filtered.sorted {
                if $0.category != $1.category { return $0.category.rawValue < $1.category.rawValue }
                return $0.title < $1.title
            }
        case .status:
            items = filtered.sorted {
                if $0.status != $1.status { return $0.status.rawValue < $1.status.rawValue }
                return $0.title < $1.title
            }
        case .title:
            items = filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    // MARK: - CRUD Operations

    func addItem(_ item: ChecklistItem, to expedition: Expedition) {
        item.expedition = expedition
        if expedition.checklistItems == nil {
            expedition.checklistItems = []
        }
        expedition.checklistItems?.append(item)
        modelContext.insert(item)

        logger.info("Added checklist item '\(item.title)' to expedition")
        saveContext()
        loadItems(for: expedition)
    }

    func updateItem(_ item: ChecklistItem, in expedition: Expedition) {
        item.updatedAt = Date()
        logger.debug("Updated checklist item '\(item.title)'")
        saveContext()
        loadItems(for: expedition)
    }

    func deleteItem(_ item: ChecklistItem, from expedition: Expedition) {
        let title = item.title
        expedition.checklistItems?.removeAll { $0.id == item.id }
        modelContext.delete(item)

        logger.info("Deleted checklist item '\(title)' from expedition")
        saveContext()
        loadItems(for: expedition)
    }

    func toggleStatus(for item: ChecklistItem, in expedition: Expedition) {
        switch item.status {
        case .pending:
            item.status = .inProgress
        case .inProgress:
            item.status = .completed
        case .completed:
            item.status = .pending
        case .skipped:
            item.status = .pending
        }
        item.updatedAt = Date()
        logger.debug("Toggled checklist item '\(item.title)' to \(item.status.rawValue)")
        saveContext()
        loadItems(for: expedition)
    }

    // MARK: - Computed Properties

    func overdueItems(startDate: Date?) -> [ChecklistItem] {
        items.filter { $0.isOverdue(expeditionStartDate: startDate) }
    }

    func upcomingItems(startDate: Date?, withinDays: Int = 30) -> [ChecklistItem] {
        items.filter { item in
            guard !item.isComplete, !item.isSkipped else { return false }
            guard let days = item.daysUntilDue(expeditionStartDate: startDate) else { return false }
            return days >= 0 && days <= withinDays && !item.isOverdue(expeditionStartDate: startDate)
        }
    }

    var completedCount: Int {
        items.filter { $0.isComplete }.count
    }

    var pendingCount: Int {
        items.filter { $0.status == .pending }.count
    }

    var inProgressCount: Int {
        items.filter { $0.status == .inProgress }.count
    }

    var completionPercentage: Double {
        guard !items.isEmpty else { return 0 }
        return Double(completedCount) / Double(items.count) * 100
    }

    var groupedByCategory: [(category: ChecklistCategory, items: [ChecklistItem])] {
        let grouped = Dictionary(grouping: items) { $0.category }
        return ChecklistCategory.allCases.compactMap { category in
            guard let list = grouped[category], !list.isEmpty else { return nil }
            return (category: category, items: list)
        }
    }

    var groupedByStatus: [(status: ChecklistStatus, items: [ChecklistItem])] {
        let grouped = Dictionary(grouping: items) { $0.status }
        return ChecklistStatus.allCases.compactMap { status in
            guard let list = grouped[status], !list.isEmpty else { return nil }
            return (status: status, items: list)
        }
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
        filterStatus = nil
        filterCategory = nil
    }

    var hasActiveFilters: Bool {
        filterStatus != nil || filterCategory != nil || !searchText.isEmpty
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save checklist changes: \(error.localizedDescription)")
        }
    }
}
