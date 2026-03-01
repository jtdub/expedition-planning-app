import SwiftUI

struct ChecklistRowView: View {
    let item: ChecklistItem
    let expeditionStartDate: Date?
    var onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Status toggle button
            Button {
                onToggle()
            } label: {
                Image(systemName: item.status.icon)
                    .font(.title2)
                    .foregroundStyle(statusColor)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body)
                    .strikethrough(item.isComplete)
                    .foregroundStyle(item.isComplete ? .secondary : .primary)

                HStack(spacing: 8) {
                    Label(item.category.rawValue, systemImage: item.category.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let participant = item.assignedTo {
                        Label(participant.displayName, systemImage: "person")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let due = item.computedDueDate(expeditionStartDate: expeditionStartDate) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(due.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                    }
                    .foregroundStyle(dueDateColor)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch item.statusColor {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        default: return .secondary
        }
    }

    private var dueDateColor: Color {
        if item.isOverdue(expeditionStartDate: expeditionStartDate) {
            return .red
        }
        if let days = item.daysUntilDue(expeditionStartDate: expeditionStartDate), days <= 7 {
            return .orange
        }
        return .secondary
    }
}
