import Foundation
import SwiftData

// MARK: - Checklist Status

enum ChecklistStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
    case skipped = "Skipped"

    var icon: String {
        switch self {
        case .pending: return "circle"
        case .inProgress: return "circle.dotted.circle"
        case .completed: return "checkmark.circle.fill"
        case .skipped: return "slash.circle"
        }
    }
}

// MARK: - Checklist Category

enum ChecklistCategory: String, Codable, CaseIterable {
    case permits = "Permits"
    case gear = "Gear"
    case logistics = "Logistics"
    case medical = "Medical"
    case travel = "Travel"
    case training = "Training"
    case communication = "Communication"
    case other = "Other"

    var icon: String {
        switch self {
        case .permits: return "doc.text"
        case .gear: return "backpack"
        case .logistics: return "shippingbox"
        case .medical: return "cross.case"
        case .travel: return "airplane"
        case .training: return "figure.hiking"
        case .communication: return "antenna.radiowaves.left.and.right"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Checklist Item

@Model
final class ChecklistItem {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var status: ChecklistStatus = ChecklistStatus.pending
    var category: ChecklistCategory = ChecklistCategory.logistics
    var dueDate: Date?
    var dueOffset: Int?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Relationships - must be optional for CloudKit
    var assignedTo: Participant?
    var expedition: Expedition?

    init(
        title: String = "",
        notes: String = "",
        status: ChecklistStatus = .pending,
        category: ChecklistCategory = .logistics,
        dueDate: Date? = nil,
        dueOffset: Int? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.status = status
        self.category = category
        self.dueDate = dueDate
        self.dueOffset = dueOffset
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    var isComplete: Bool {
        status == .completed
    }

    var isSkipped: Bool {
        status == .skipped
    }

    var statusColor: String {
        switch status {
        case .pending: return "gray"
        case .inProgress: return "blue"
        case .completed: return "green"
        case .skipped: return "orange"
        }
    }

    // MARK: - Due Date Helpers

    func computedDueDate(expeditionStartDate: Date?) -> Date? {
        if let dueDate {
            return dueDate
        }
        guard let offset = dueOffset, let startDate = expeditionStartDate else {
            return nil
        }
        return Calendar.current.date(byAdding: .day, value: offset, to: startDate)
    }

    func isOverdue(expeditionStartDate: Date?) -> Bool {
        guard !isComplete, !isSkipped else { return false }
        guard let due = computedDueDate(expeditionStartDate: expeditionStartDate) else {
            return false
        }
        return due < Date()
    }

    func daysUntilDue(expeditionStartDate: Date?) -> Int? {
        guard let due = computedDueDate(expeditionStartDate: expeditionStartDate) else {
            return nil
        }
        let fromDate = Calendar.current.startOfDay(for: Date())
        let toDate = Calendar.current.startOfDay(for: due)
        return Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day
    }
}
