import SwiftUI
import SwiftData

enum InsuranceFormMode {
    case add
    case edit(InsurancePolicy)
}

struct InsurancePolicyFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: InsuranceFormMode
    let expedition: Expedition
    var viewModel: InsuranceViewModel

    @State private var provider = ""
    @State private var policyNumber = ""
    @State private var insuranceType: InsuranceType = .travelMedical
    @State private var coverageStartDate: Date = Date()
    @State private var coverageEndDate: Date = Date().addingTimeInterval(365 * 24 * 60 * 60)
    @State private var hasDateRange = true
    @State private var emergencyPhone = ""
    @State private var claimsPhone = ""
    @State private var coverageAmountString = ""
    @State private var deductibleString = ""
    @State private var currency = "USD"
    @State private var notes = ""
    @State private var documentURL = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingPolicy: InsurancePolicy? {
        if case .edit(let policy) = mode { return policy }
        return nil
    }

    var body: some View {
        Form {
            Section {
                TextField("Provider Name", text: $provider)
                TextField("Policy Number", text: $policyNumber)

                Picker("Type", selection: $insuranceType) {
                    ForEach(InsuranceType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
            } header: {
                Text("Policy Information")
            }

            Section {
                Toggle("Set Coverage Dates", isOn: $hasDateRange)

                if hasDateRange {
                    DatePicker("Start Date", selection: $coverageStartDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $coverageEndDate, displayedComponents: .date)
                }
            } header: {
                Text("Coverage Period")
            }

            Section {
                HStack {
                    TextField("Coverage Amount", text: $coverageAmountString)
                        .keyboardType(.decimalPad)
                    Picker("", selection: $currency) {
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                        Text("CAD").tag("CAD")
                        Text("AUD").tag("AUD")
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                HStack {
                    TextField("Deductible", text: $deductibleString)
                        .keyboardType(.decimalPad)
                    Text(currency)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Coverage Details")
            }

            Section {
                TextField("Emergency Phone", text: $emergencyPhone)
                    .keyboardType(.phonePad)
                TextField("Claims Phone", text: $claimsPhone)
                    .keyboardType(.phonePad)
            } header: {
                Text("Contact Numbers")
            } footer: {
                Text("Keep emergency numbers accessible in case of an incident.")
            }

            Section {
                TextField("Document URL (optional)", text: $documentURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Documentation")
            }

            Section {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Notes")
            }

            // Type description
            Section {
                Text(insuranceType.typeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About \(insuranceType.rawValue)")
            }
        }
        .navigationTitle(isEditing ? "Edit Policy" : "Add Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    savePolicy()
                }
                .disabled(provider.isEmpty)
            }
        }
        .onAppear {
            if let policy = editingPolicy {
                loadPolicy(policy)
            }
        }
    }

    private func loadPolicy(_ policy: InsurancePolicy) {
        provider = policy.provider
        policyNumber = policy.policyNumber
        insuranceType = policy.insuranceType
        if let start = policy.coverageStartDate, let end = policy.coverageEndDate {
            coverageStartDate = start
            coverageEndDate = end
            hasDateRange = true
        } else {
            hasDateRange = false
        }
        emergencyPhone = policy.emergencyPhone ?? ""
        claimsPhone = policy.claimsPhone ?? ""
        if let amount = policy.coverageAmount {
            coverageAmountString = "\(amount)"
        }
        if let deductible = policy.deductible {
            deductibleString = "\(deductible)"
        }
        currency = policy.currency
        notes = policy.notes
        documentURL = policy.documentURL ?? ""
    }

    private func savePolicy() {
        let policy: InsurancePolicy
        if let existing = editingPolicy {
            policy = existing
        } else {
            policy = InsurancePolicy()
        }

        policy.provider = provider
        policy.policyNumber = policyNumber
        policy.insuranceType = insuranceType
        policy.coverageStartDate = hasDateRange ? coverageStartDate : nil
        policy.coverageEndDate = hasDateRange ? coverageEndDate : nil
        policy.emergencyPhone = emergencyPhone.isEmpty ? nil : emergencyPhone
        policy.claimsPhone = claimsPhone.isEmpty ? nil : claimsPhone
        policy.coverageAmount = Decimal(string: coverageAmountString)
        policy.deductible = Decimal(string: deductibleString)
        policy.currency = currency
        policy.notes = notes
        policy.documentURL = documentURL.isEmpty ? nil : documentURL

        if isEditing {
            viewModel.updatePolicy(policy, in: expedition)
        } else {
            viewModel.addPolicy(policy, to: expedition)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        InsurancePolicyFormView(
            mode: .add,
            expedition: Expedition(name: "Test"),
            // swiftlint:disable:next force_try
            viewModel: InsuranceViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
