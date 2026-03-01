import SwiftUI
import SwiftData

enum ChecklistFormMode {
    case create
    case edit(ChecklistItem)
}

struct ChecklistFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: ChecklistFormMode
    let expedition: Expedition
    var viewModel: ChecklistViewModel

    // Form fields
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var category: ChecklistCategory = .logistics
    @State private var status: ChecklistStatus = .pending
    @State private var assignedToID: UUID?

    // Deadline - explicit date
    @State private var hasExplicitDate: Bool = false
    @State private var dueDate: Date = Date()

    // Deadline - offset from start
    @State private var hasOffset: Bool = false
    @State private var offsetDays: Int = 30

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var navigationTitle: String {
        isEditing ? "Edit Task" : "New Task"
    }

    private var existingItem: ChecklistItem? {
        if case .edit(let item) = mode {
            return item
        }
        return nil
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            // Basic Info
            Section {
                TextField("Title", text: $title)

                Picker("Category", selection: $category) {
                    ForEach(ChecklistCategory.allCases, id: \.self) { cat in
                        Label(cat.rawValue, systemImage: cat.icon)
                            .tag(cat)
                    }
                }

                Picker("Status", selection: $status) {
                    ForEach(ChecklistStatus.allCases, id: \.self) { stat in
                        Label(stat.rawValue, systemImage: stat.icon)
                            .tag(stat)
                    }
                }
            } header: {
                Text("Basic Info")
            }

            // Notes
            Section {
                VStack(alignment: .leading) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            } header: {
                Text("Notes")
            }

            // Deadline
            Section {
                Toggle("Specific Date", isOn: $hasExplicitDate)
                if hasExplicitDate {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }

                Toggle("Relative to Start Date", isOn: $hasOffset)
                if hasOffset {
                    Stepper(
                        "\(offsetDays) days before start",
                        value: $offsetDays,
                        in: 1...365
                    )
                    if let startDate = expedition.startDate {
                        let computed = Calendar.current.date(
                            byAdding: .day, value: -offsetDays, to: startDate
                        )
                        if let computed {
                            Text("= \(computed.formatted(date: .long, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Set expedition start date to see computed date")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            } header: {
                Text("Deadline")
            } footer: {
                if hasExplicitDate && hasOffset {
                    Text("Specific date takes priority over relative offset.")
                }
            }

            // Assignment
            Section {
                Picker("Assigned To", selection: $assignedToID) {
                    Text("Unassigned").tag(nil as UUID?)
                    ForEach(expedition.participants ?? []) { participant in
                        Text(participant.displayName).tag(participant.id as UUID?)
                    }
                }
            } header: {
                Text("Assignment")
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveItem()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            loadExistingData()
        }
    }

    // MARK: - Data Loading

    private func loadExistingData() {
        guard let item = existingItem else { return }

        title = item.title
        notes = item.notes
        category = item.category
        status = item.status
        assignedToID = item.assignedTo?.id

        if let date = item.dueDate {
            dueDate = date
            hasExplicitDate = true
        }

        if let offset = item.dueOffset {
            offsetDays = abs(offset)
            hasOffset = true
        }
    }

    // MARK: - Save

    private func saveItem() {
        let participants = expedition.participants ?? []
        let assignee = participants.first { $0.id == assignedToID }

        if let existing = existingItem {
            existing.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.notes = notes
            existing.category = category
            existing.status = status
            existing.assignedTo = assignee
            existing.dueDate = hasExplicitDate ? dueDate : nil
            existing.dueOffset = hasOffset ? -offsetDays : nil
            existing.updatedAt = Date()

            viewModel.updateItem(existing, in: expedition)
        } else {
            let item = ChecklistItem(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes,
                status: status,
                category: category,
                dueDate: hasExplicitDate ? dueDate : nil,
                dueOffset: hasOffset ? -offsetDays : nil
            )
            item.assignedTo = assignee

            viewModel.addItem(item, to: expedition)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        ChecklistFormView(
            mode: .create,
            expedition: Expedition(name: "Test"),
            viewModel: ChecklistViewModel(
                // swiftlint:disable:next force_try
                modelContext: try! ModelContainer(
                    for: Expedition.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                ).mainContext
            )
        )
    }
}
