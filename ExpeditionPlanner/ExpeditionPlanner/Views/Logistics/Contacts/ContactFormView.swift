import SwiftUI
import SwiftData

enum ContactFormMode {
    case create
    case edit(Contact)
}

struct ContactFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: ContactFormMode
    let expedition: Expedition
    var viewModel: ContactViewModel

    // Basic info
    @State private var name = ""
    @State private var role = ""
    @State private var organization = ""
    @State private var category: ContactCategory = .localResource
    @State private var location = ""

    // Contact info
    @State private var phone = ""
    @State private var cellPhone = ""
    @State private var email = ""
    @State private var address = ""
    @State private var hours = ""

    // Emergency
    @State private var isEmergencyContact = false
    @State private var emergencyPriority: Int = 1

    // Notes
    @State private var notes = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingContact: Contact? {
        if case .edit(let contact) = mode { return contact }
        return nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            // Basic Info
            Section {
                TextField("Name", text: $name)
                TextField("Role/Title", text: $role)
                TextField("Organization", text: $organization)

                Picker("Category", selection: $category) {
                    ForEach(ContactCategory.allCases, id: \.self) { cat in
                        Label(cat.rawValue, systemImage: cat.icon)
                            .tag(cat)
                    }
                }

                TextField("Location", text: $location)
            } header: {
                Text("Basic Information")
            }

            // Contact Info
            Section {
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Cell Phone", text: $cellPhone)
                    .keyboardType(.phonePad)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Address", text: $address, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Hours", text: $hours)
            } header: {
                Text("Contact Information")
            }

            // Emergency
            Section {
                Toggle("Emergency Contact", isOn: $isEmergencyContact)

                if isEmergencyContact {
                    Stepper("Priority: \(emergencyPriority)", value: $emergencyPriority, in: 1...10)
                }
            } header: {
                Text("Emergency")
            } footer: {
                Text("Emergency contacts are shown prominently and can be called quickly.")
            }

            // Notes
            Section {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Notes")
            }

            // Category info
            Section {
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(width: 32)

                    Text(categoryDescription(for: category))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Category Info")
            }
        }
        .navigationTitle(isEditing ? "Edit Contact" : "Add Contact")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveContact()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            if let contact = editingContact {
                loadContact(contact)
            }
        }
    }

    // MARK: - Category Description

    private func categoryDescription(for category: ContactCategory) -> String {
        switch category {
        case .emergency:
            return "Emergency services, rescue teams, and urgent contacts"
        case .localResource:
            return "Local guides, fixers, and community contacts"
        case .accommodation:
            return "Hotels, lodges, and overnight stay contacts"
        case .transport:
            return "Pilots, drivers, and transportation services"
        case .resupply:
            return "Stores, post offices, and supply points"
        case .government:
            return "Permits, customs, and official contacts"
        case .medical:
            return "Doctors, hospitals, and medical facilities"
        case .guide:
            return "Local guides and outfitters"
        }
    }

    // MARK: - Load/Save

    private func loadContact(_ contact: Contact) {
        name = contact.name
        role = contact.role
        organization = contact.organization ?? ""
        category = contact.category
        location = contact.location
        phone = contact.phone ?? ""
        cellPhone = contact.cellPhone ?? ""
        email = contact.email ?? ""
        address = contact.address ?? ""
        hours = contact.hours ?? ""
        isEmergencyContact = contact.isEmergencyContact
        emergencyPriority = contact.emergencyPriority ?? 1
        notes = contact.notes
    }

    private func saveContact() {
        let contact: Contact
        if let existing = editingContact {
            contact = existing
        } else {
            contact = Contact()
        }

        contact.name = name
        contact.role = role
        contact.organization = organization.isEmpty ? nil : organization
        contact.category = category
        contact.location = location
        contact.phone = phone.isEmpty ? nil : phone
        contact.cellPhone = cellPhone.isEmpty ? nil : cellPhone
        contact.email = email.isEmpty ? nil : email
        contact.address = address.isEmpty ? nil : address
        contact.hours = hours.isEmpty ? nil : hours
        contact.isEmergencyContact = isEmergencyContact
        contact.emergencyPriority = isEmergencyContact ? emergencyPriority : nil
        contact.notes = notes

        if isEditing {
            viewModel.updateContact(contact, in: expedition)
        } else {
            viewModel.addContact(contact, to: expedition)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        ContactFormView(
            mode: .create,
            expedition: Expedition(name: "Test"),
            // swiftlint:disable:next force_try
            viewModel: ContactViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
