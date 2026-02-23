import SwiftUI
import SwiftData

struct ContactDetailView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.openURL)
    private var openURL

    let contact: Contact
    let expedition: Expedition
    var viewModel: ContactViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // Header
            Section {
                headerView
            }

            // Quick Actions
            Section {
                if let phone = contact.primaryPhone {
                    Button {
                        if let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                            openURL(url)
                        }
                    } label: {
                        Label("Call \(phone)", systemImage: "phone.fill")
                    }
                }

                if let email = contact.email {
                    Button {
                        if let url = URL(string: "mailto:\(email)") {
                            openURL(url)
                        }
                    } label: {
                        Label("Email \(email)", systemImage: "envelope.fill")
                    }
                }
            } header: {
                Text("Quick Actions")
            }

            // Contact Details
            Section {
                if let phone = contact.phone {
                    LabeledContent("Phone", value: phone)
                }
                if let cell = contact.cellPhone {
                    LabeledContent("Cell", value: cell)
                }
                if let email = contact.email {
                    LabeledContent("Email", value: email)
                }
                if let address = contact.address {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Address")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(address)
                    }
                }
                if let hours = contact.hours {
                    LabeledContent("Hours", value: hours)
                }
            } header: {
                Text("Contact Details")
            }

            // Organization & Location
            if contact.organization != nil || !contact.location.isEmpty {
                Section {
                    if let org = contact.organization {
                        LabeledContent("Organization", value: org)
                    }
                    if !contact.location.isEmpty {
                        LabeledContent("Location", value: contact.location)
                    }
                } header: {
                    Text("Details")
                }
            }

            // Emergency Info
            if contact.isEmergencyContact {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text("Emergency Contact")
                            .fontWeight(.semibold)
                    }

                    if let priority = contact.emergencyPriority {
                        LabeledContent("Priority", value: "#\(priority)")
                    }
                } header: {
                    Text("Emergency Status")
                }
            }

            // Notes
            if !contact.notes.isEmpty {
                Section {
                    Text(contact.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Actions
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Contact", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Contact")
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
                ContactFormView(
                    mode: .edit(contact),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete Contact?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteContact(contact, from: expedition)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: contact.category.icon)
                .font(.largeTitle)
                .foregroundStyle(categoryColor)
                .frame(width: 60, height: 60)
                .background(categoryColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.title2)
                    .fontWeight(.bold)

                if !contact.role.isEmpty {
                    Text(contact.role)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Image(systemName: contact.category.icon)
                        .font(.caption)
                    Text(contact.category.rawValue)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private var categoryColor: Color {
        switch contact.category.color {
        case "red": return .red
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "brown": return .brown
        case "gray": return .secondary
        case "pink": return .pink
        case "green": return .green
        case "teal": return .teal
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        ContactDetailView(
            contact: {
                let contact = Contact(
                    name: "Park Ranger Station",
                    role: "Emergency Services",
                    category: .emergency
                )
                contact.phone = "+1 555-1234"
                contact.email = "rangers@park.gov"
                contact.isEmergencyContact = true
                contact.emergencyPriority = 1
                contact.location = "Fairbanks, AK"
                return contact
            }(),
            expedition: Expedition(name: "Test"),
            // swiftlint:disable:next force_try
            viewModel: ContactViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
