import SwiftUI
import SwiftData

struct PermitDetailView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.openURL)
    private var openURL

    let permit: Permit
    let expedition: Expedition
    var viewModel: PermitViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // Header
            Section {
                headerView
            }

            // Status and Dates
            Section {
                LabeledContent("Status") {
                    Label(permit.status.rawValue, systemImage: permit.status.icon)
                        .foregroundStyle(statusColor)
                }

                if let deadline = permit.applicationDeadline {
                    LabeledContent("Deadline") {
                        VStack(alignment: .trailing) {
                            Text(deadline.formatted(date: .long, time: .omitted))
                            if let days = permit.daysUntilDeadline {
                                Text(days >= 0 ? "\(days) days left" : "\(-days) days overdue")
                                    .font(.caption)
                                    .foregroundColor(days >= 0 ? .secondary : .red)
                            }
                        }
                    }
                }

                if let expiration = permit.expirationDate {
                    LabeledContent("Expires") {
                        Text(expiration.formatted(date: .long, time: .omitted))
                    }
                }
            } header: {
                Text("Status")
            }

            // Cost
            if permit.cost != nil || permit.permitNumber != nil {
                Section {
                    if let cost = permit.cost {
                        LabeledContent("Cost") {
                            Text(formatCurrency(cost, code: permit.currency))
                        }
                    }
                    if let number = permit.permitNumber {
                        LabeledContent("Permit Number", value: number)
                    }
                } header: {
                    Text("Details")
                }
            }

            // Description
            if !permit.permitDescription.isEmpty {
                Section {
                    Text(permit.permitDescription)
                } header: {
                    Text("Description")
                }
            }

            // Office Contact
            if hasOfficeInfo {
                Section {
                    if let phone = permit.officePhone {
                        Button {
                            if let url = URL(string: "tel:\(phone)") {
                                openURL(url)
                            }
                        } label: {
                            Label(phone, systemImage: "phone")
                        }
                    }

                    if let email = permit.officeEmail {
                        Button {
                            if let url = URL(string: "mailto:\(email)") {
                                openURL(url)
                            }
                        } label: {
                            Label(email, systemImage: "envelope")
                        }
                    }

                    if let address = permit.officeAddress {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Address")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(address)
                        }
                    }

                    if let hours = permit.officeHours {
                        LabeledContent("Hours", value: hours)
                    }

                    if let website = permit.websiteURL, let url = URL(string: website) {
                        Button {
                            openURL(url)
                        } label: {
                            Label("Visit Website", systemImage: "safari")
                        }
                    }
                } header: {
                    Text("Office Contact")
                }
            }

            // Notes
            if !permit.notes.isEmpty {
                Section {
                    Text(permit.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Actions
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Permit", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Permit")
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
                PermitFormView(
                    mode: .edit(permit),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete Permit?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deletePermit(permit, from: expedition)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: permit.permitType.icon)
                .font(.largeTitle)
                .foregroundStyle(statusColor)
                .frame(width: 60, height: 60)
                .background(statusColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(permit.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(permit.issuingAuthority)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Image(systemName: permit.permitType.icon)
                        .font(.caption)
                    Text(permit.permitType.rawValue)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private var hasOfficeInfo: Bool {
        permit.officePhone != nil ||
        permit.officeEmail != nil ||
        permit.officeAddress != nil ||
        permit.officeHours != nil ||
        permit.websiteURL != nil
    }

    private var statusColor: Color {
        switch permit.statusColor {
        case "red": return .red
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        case "gray": return .secondary
        default: return .secondary
        }
    }

    private func formatCurrency(_ amount: Decimal, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: amount as NSDecimalNumber) ?? ""
    }
}

#Preview {
    NavigationStack {
        PermitDetailView(
            permit: {
                let permit = Permit(name: "Wilderness Permit", issuingAuthority: "National Park Service")
                permit.status = .obtained
                permit.applicationDeadline = Date().addingTimeInterval(86400 * 30)
                permit.cost = 50
                permit.permitNumber = "WP-2026-001234"
                permit.officePhone = "+1 555-1234"
                permit.officeEmail = "permits@nps.gov"
                return permit
            }(),
            expedition: Expedition(name: "Test"),
            // swiftlint:disable:next force_try
            viewModel: PermitViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
