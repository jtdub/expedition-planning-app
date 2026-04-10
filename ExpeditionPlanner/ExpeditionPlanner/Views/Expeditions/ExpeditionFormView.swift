import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.expedition.planner", category: "ExpeditionForm")

struct ExpeditionFormView: View {
    enum Mode {
        case create
        case edit(Expedition)
    }

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    let mode: Mode

    @State private var name = ""
    @State private var expeditionDescription = ""
    @State private var location = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 7)
    @State private var hasDateRange = false
    @State private var status: ExpeditionStatus = .planning
    @State private var notes = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var title: String {
        isEditing ? "Edit Expedition" : "New Expedition"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Expedition Name", text: $name)

                    TextField("Location", text: $location)

                    Picker("Status", selection: $status) {
                        ForEach(ExpeditionStatus.allCases, id: \.self) { status in
                            Label(status.rawValue, systemImage: status.icon)
                                .tag(status)
                        }
                    }
                }

                Section("Dates") {
                    Toggle("Set Date Range", isOn: $hasDateRange)

                    if hasDateRange {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }

                Section("Description") {
                    TextField("Description", text: $expeditionDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Notes") {
                    TextField("Additional Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                loadExistingData()
            }
        }
    }

    private func loadExistingData() {
        if case .edit(let expedition) = mode {
            name = expedition.name
            expeditionDescription = expedition.expeditionDescription
            location = expedition.location
            status = expedition.status
            notes = expedition.notes

            if let start = expedition.startDate, let end = expedition.endDate {
                hasDateRange = true
                startDate = start
                endDate = end
            }
        }
    }

    private func save() {
        switch mode {
        case .create:
            let expedition = Expedition(
                name: name,
                expeditionDescription: expeditionDescription,
                startDate: hasDateRange ? startDate : nil,
                endDate: hasDateRange ? endDate : nil,
                status: status,
                location: location,
                notes: notes
            )
            modelContext.insert(expedition)

        case .edit(let expedition):
            expedition.name = name
            expedition.expeditionDescription = expeditionDescription
            expedition.location = location
            expedition.startDate = hasDateRange ? startDate : nil
            expedition.endDate = hasDateRange ? endDate : nil
            expedition.status = status
            expedition.notes = notes
            expedition.updatedAt = Date()
        }

        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save expedition: \(error.localizedDescription)")
        }
    }
}

#Preview("Create") {
    ExpeditionFormView(mode: .create)
        .modelContainer(for: Expedition.self, inMemory: true)
}

#Preview("Edit") {
    let expedition = Expedition(name: "Test Expedition", location: "Alaska")
    return ExpeditionFormView(mode: .edit(expedition))
        .modelContainer(for: Expedition.self, inMemory: true)
}
