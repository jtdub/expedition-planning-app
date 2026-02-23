import SwiftUI
import SwiftData

enum PermitFormMode {
    case create
    case edit(Permit)
}

struct PermitFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: PermitFormMode
    let expedition: Expedition
    var viewModel: PermitViewModel

    // Basic info
    @State private var name = ""
    @State private var permitDescription = ""
    @State private var issuingAuthority = ""
    @State private var permitType: PermitType = .wilderness
    @State private var status: PermitStatus = .notStarted

    // Dates
    @State private var hasDeadline = false
    @State private var applicationDeadline: Date = Date()
    @State private var submittedDate: Date?
    @State private var obtainedDate: Date?
    @State private var hasExpiration = false
    @State private var expirationDate: Date = Date()

    // Contact info
    @State private var officeAddress = ""
    @State private var officePhone = ""
    @State private var officeEmail = ""
    @State private var officeHours = ""
    @State private var websiteURL = ""

    // Cost
    @State private var costString = ""
    @State private var currency = "USD"

    // Document
    @State private var permitNumber = ""
    @State private var documentFileName = ""
    @State private var notes = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingPermit: Permit? {
        if case .edit(let permit) = mode { return permit }
        return nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            // Basic Info
            Section {
                TextField("Permit Name", text: $name)
                TextField("Description", text: $permitDescription, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Issuing Authority", text: $issuingAuthority)

                Picker("Type", selection: $permitType) {
                    ForEach(PermitType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }

                Picker("Status", selection: $status) {
                    ForEach(PermitStatus.allCases, id: \.self) { stat in
                        Label(stat.rawValue, systemImage: stat.icon)
                            .tag(stat)
                    }
                }
            } header: {
                Text("Basic Information")
            }

            // Dates
            Section {
                Toggle("Has Application Deadline", isOn: $hasDeadline)
                if hasDeadline {
                    DatePicker("Application Deadline", selection: $applicationDeadline, displayedComponents: .date)
                }

                Toggle("Has Expiration Date", isOn: $hasExpiration)
                if hasExpiration {
                    DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                }
            } header: {
                Text("Dates")
            }

            // Cost
            Section {
                HStack {
                    TextField("Cost", text: $costString)
                        .keyboardType(.decimalPad)
                    Picker("", selection: $currency) {
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                        Text("CAD").tag("CAD")
                        Text("PEN").tag("PEN")
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                TextField("Permit Number", text: $permitNumber)
            } header: {
                Text("Cost & Reference")
            }

            // Office Contact
            Section {
                TextField("Office Address", text: $officeAddress, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Office Phone", text: $officePhone)
                    .keyboardType(.phonePad)
                TextField("Office Email", text: $officeEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Office Hours", text: $officeHours)
                TextField("Website URL", text: $websiteURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Office Contact")
            }

            // Notes
            Section {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Notes")
            }
        }
        .navigationTitle(isEditing ? "Edit Permit" : "Add Permit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    savePermit()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            if let permit = editingPermit {
                loadPermit(permit)
            }
        }
    }

    // MARK: - Load/Save

    private func loadPermit(_ permit: Permit) {
        name = permit.name
        permitDescription = permit.permitDescription
        issuingAuthority = permit.issuingAuthority
        permitType = permit.permitType
        status = permit.status
        if let deadline = permit.applicationDeadline {
            applicationDeadline = deadline
            hasDeadline = true
        }
        if let expiration = permit.expirationDate {
            expirationDate = expiration
            hasExpiration = true
        }
        officeAddress = permit.officeAddress ?? ""
        officePhone = permit.officePhone ?? ""
        officeEmail = permit.officeEmail ?? ""
        officeHours = permit.officeHours ?? ""
        websiteURL = permit.websiteURL ?? ""
        if let cost = permit.cost {
            costString = "\(cost)"
        }
        currency = permit.currency
        permitNumber = permit.permitNumber ?? ""
        notes = permit.notes
    }

    private func savePermit() {
        let permit: Permit
        if let existing = editingPermit {
            permit = existing
        } else {
            permit = Permit()
        }

        permit.name = name
        permit.permitDescription = permitDescription
        permit.issuingAuthority = issuingAuthority
        permit.permitType = permitType
        permit.status = status
        permit.applicationDeadline = hasDeadline ? applicationDeadline : nil
        permit.expirationDate = hasExpiration ? expirationDate : nil
        permit.officeAddress = officeAddress.isEmpty ? nil : officeAddress
        permit.officePhone = officePhone.isEmpty ? nil : officePhone
        permit.officeEmail = officeEmail.isEmpty ? nil : officeEmail
        permit.officeHours = officeHours.isEmpty ? nil : officeHours
        permit.websiteURL = websiteURL.isEmpty ? nil : websiteURL
        permit.cost = Decimal(string: costString)
        permit.currency = currency
        permit.permitNumber = permitNumber.isEmpty ? nil : permitNumber
        permit.notes = notes

        if isEditing {
            viewModel.updatePermit(permit, in: expedition)
        } else {
            viewModel.addPermit(permit, to: expedition)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        PermitFormView(
            mode: .create,
            expedition: Expedition(name: "Test"),
            // swiftlint:disable:next force_try
            viewModel: PermitViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
