import SwiftUI
import SwiftData

struct ChecklistDetailView: View {
    @Environment(\.dismiss)
    private var dismiss

    let item: ChecklistItem
    let expedition: Expedition
    var viewModel: ChecklistViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // Header
            Section {
                headerView
            }

            // Status & Deadline
            Section {
                LabeledContent("Status") {
                    HStack(spacing: 4) {
                        Image(systemName: item.status.icon)
                        Text(item.status.rawValue)
                    }
                    .foregroundStyle(statusColor)
                }

                LabeledContent("Category") {
                    Label(item.category.rawValue, systemImage: item.category.icon)
                }

                if let due = item.computedDueDate(expeditionStartDate: expedition.startDate) {
                    LabeledContent("Due Date") {
                        Text(due.formatted(date: .long, time: .omitted))
                            .foregroundStyle(dueDateColor)
                    }

                    if let days = item.daysUntilDue(expeditionStartDate: expedition.startDate) {
                        LabeledContent("Days Until Due") {
                            Text(daysLabel(days))
                                .foregroundStyle(dueDateColor)
                        }
                    }
                }

                if let offset = item.dueOffset {
                    LabeledContent("Offset from Start") {
                        Text("\(abs(offset)) days \(offset < 0 ? "before" : "after")")
                    }
                }
            } header: {
                Label("Status & Deadline", systemImage: "clock")
            }

            // Assignment
            if let participant = item.assignedTo {
                Section {
                    LabeledContent("Assigned To", value: participant.displayName)
                    if !participant.email.isEmpty {
                        LabeledContent("Email", value: participant.email)
                    }
                } header: {
                    Label("Assignment", systemImage: "person")
                }
            }

            // Notes
            if !item.notes.isEmpty {
                Section {
                    Text(item.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Timestamps
            Section {
                LabeledContent("Created") {
                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                }
                LabeledContent("Updated") {
                    Text(item.updatedAt.formatted(date: .abbreviated, time: .shortened))
                }
            } header: {
                Text("Details")
            }

            // Actions
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Task", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                ChecklistFormView(
                    mode: .edit(item),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete Task?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteItem(item, from: expedition)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: item.category.icon)
                .font(.largeTitle)
                .foregroundStyle(categoryColor)
                .frame(width: 60, height: 60)
                .background(categoryColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(item.category.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(item.status.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())

                    if item.isOverdue(expeditionStartDate: expedition.startDate) {
                        Text("Overdue")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func daysLabel(_ days: Int) -> String {
        if days < 0 {
            return "\(abs(days)) days overdue"
        } else if days == 0 {
            return "Due today"
        } else {
            return "In \(days) days"
        }
    }

    private var statusColor: Color {
        switch item.statusColor {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        default: return .secondary
        }
    }

    private var dueDateColor: Color {
        if item.isOverdue(expeditionStartDate: expedition.startDate) {
            return .red
        }
        if let days = item.daysUntilDue(expeditionStartDate: expedition.startDate), days <= 7 {
            return .orange
        }
        return .primary
    }

    private var categoryColor: Color {
        switch item.category {
        case .permits: return .gray
        case .gear: return .green
        case .logistics: return .brown
        case .medical: return .red
        case .travel: return .blue
        case .training: return .orange
        case .communication: return .purple
        case .other: return .secondary
        }
    }
}
