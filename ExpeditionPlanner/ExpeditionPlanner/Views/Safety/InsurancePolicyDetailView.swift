import SwiftUI
import SwiftData

struct InsurancePolicyDetailView: View {
    @Environment(\.dismiss)
    private var dismiss

    let policy: InsurancePolicy
    let expedition: Expedition
    var viewModel: InsuranceViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            // Status Section
            Section {
                statusHeader
            }

            // Policy Info
            Section {
                LabeledContent("Provider", value: policy.provider)

                if !policy.policyNumber.isEmpty {
                    LabeledContent("Policy Number", value: policy.policyNumber)
                }

                LabeledContent("Type") {
                    Label(policy.insuranceType.rawValue, systemImage: policy.insuranceType.icon)
                }
            } header: {
                Text("Policy Information")
            }

            // Coverage Period
            if policy.coverageStartDate != nil || policy.coverageEndDate != nil {
                Section {
                    if let start = policy.coverageStartDate {
                        LabeledContent("Start Date") {
                            Text(start.formatted(date: .long, time: .omitted))
                        }
                    }

                    if let end = policy.coverageEndDate {
                        LabeledContent("End Date") {
                            Text(end.formatted(date: .long, time: .omitted))
                        }
                    }

                    if let days = policy.daysUntilExpiry {
                        LabeledContent("Days Until Expiry") {
                            Text("\(days) days")
                                .foregroundStyle(days <= 30 ? .orange : .secondary)
                        }
                    }
                } header: {
                    Text("Coverage Period")
                }
            }

            // Coverage Amount
            if policy.coverageAmount != nil || policy.deductible != nil {
                Section {
                    if let amount = policy.coverageAmount {
                        LabeledContent("Coverage Amount") {
                            Text(formatCurrency(amount))
                        }
                    }

                    if let deductible = policy.deductible {
                        LabeledContent("Deductible") {
                            Text(formatCurrency(deductible))
                        }
                    }
                } header: {
                    Text("Coverage Details")
                }
            }

            // Emergency Contacts
            if policy.emergencyPhone != nil || policy.claimsPhone != nil {
                Section {
                    if let phone = policy.emergencyPhone {
                        Button {
                            callPhone(phone)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Emergency")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(phone)
                                }
                                Spacer()
                                Image(systemName: "phone.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .tint(.primary)
                    }

                    if let phone = policy.claimsPhone {
                        Button {
                            callPhone(phone)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Claims")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(phone)
                                }
                                Spacer()
                                Image(systemName: "phone.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .tint(.primary)
                    }
                } header: {
                    Text("Contact Numbers")
                } footer: {
                    Text("Tap to call")
                }
            }

            // Document Link
            if let urlString = policy.documentURL, !urlString.isEmpty {
                Section {
                    if let url = URL(string: urlString) {
                        Link(destination: url) {
                            HStack {
                                Text("View Document")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                        }
                    } else {
                        Text(urlString)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Documentation")
                }
            }

            // Notes
            if !policy.notes.isEmpty {
                Section {
                    Text(policy.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Type Description
            Section {
                Text(policy.insuranceType.typeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About \(policy.insuranceType.rawValue)")
            }

            // Delete Button
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Policy")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Policy Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                InsurancePolicyFormView(
                    mode: .edit(policy),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .confirmationDialog(
            "Delete Policy",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deletePolicy(policy, from: expedition)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this insurance policy? This cannot be undone.")
        }
    }

    @ViewBuilder private var statusHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: policy.insuranceType.icon)
                .font(.largeTitle)
                .foregroundStyle(colorForStatus)

            VStack(alignment: .leading, spacing: 4) {
                Text(policy.statusText)
                    .font(.headline)
                    .foregroundStyle(colorForStatus)

                if policy.isActive {
                    if let days = policy.daysUntilExpiry {
                        if days <= 30 {
                            Text("Expires in \(days) days")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else {
                            Text("Valid coverage")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if policy.isExpired {
                    Text("This policy has expired")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var colorForStatus: Color {
        if policy.isExpired {
            return .red
        } else if policy.isExpiringSoon {
            return .orange
        } else if policy.isActive {
            return .green
        } else {
            return .secondary
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = policy.currency
        return formatter.string(from: amount as NSDecimalNumber) ?? ""
    }

    private func callPhone(_ number: String) {
        let cleaned = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationStack {
        InsurancePolicyDetailView(
            policy: {
                let policy = InsurancePolicy(
                    provider: "World Nomads",
                    policyNumber: "WN-123456",
                    insuranceType: .travelMedical,
                    coverageStartDate: Date(),
                    coverageEndDate: Date().addingTimeInterval(90 * 24 * 60 * 60),
                    emergencyPhone: "+1-800-555-0123",
                    claimsPhone: "+1-800-555-0124",
                    coverageAmount: 100000,
                    currency: "USD"
                )
                return policy
            }(),
            expedition: Expedition(name: "Test"),
            // swiftlint:disable:next force_try
            viewModel: InsuranceViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
