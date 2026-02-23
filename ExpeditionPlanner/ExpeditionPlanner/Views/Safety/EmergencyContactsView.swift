import SwiftUI
import SwiftData

struct EmergencyContactsView: View {
    @Environment(\.openURL)
    private var openURL

    let expedition: Expedition

    private var emergencyContacts: [Contact] {
        (expedition.contacts ?? [])
            .filter { $0.isEmergencyContact }
            .sorted { ($0.emergencyPriority ?? 999) < ($1.emergencyPriority ?? 999) }
    }

    private var emergencyServiceContacts: [Contact] {
        (expedition.contacts ?? [])
            .filter { $0.category == .emergency && !$0.isEmergencyContact }
    }

    var body: some View {
        List {
            if emergencyContacts.isEmpty && emergencyServiceContacts.isEmpty {
                ContentUnavailableView {
                    Label("No Emergency Contacts", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("Add emergency contacts in the Contacts section and mark them as emergency contacts.")
                }
            } else {
                // Primary Emergency Contacts
                if !emergencyContacts.isEmpty {
                    Section {
                        ForEach(emergencyContacts) { contact in
                            EmergencyContactRow(contact: contact, openURL: openURL)
                        }
                    } header: {
                        Label("Emergency Contacts", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    } footer: {
                        Text("These contacts are marked as primary emergency contacts.")
                    }
                }

                // Emergency Services
                if !emergencyServiceContacts.isEmpty {
                    Section {
                        ForEach(emergencyServiceContacts) { contact in
                            EmergencyContactRow(contact: contact, openURL: openURL)
                        }
                    } header: {
                        Label("Emergency Services", systemImage: "cross.case")
                    }
                }

                // Quick Reference
                Section {
                    quickReferenceSection
                } header: {
                    Text("Quick Reference")
                }
            }
        }
        .navigationTitle("Emergency Contacts")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Quick Reference

    private var quickReferenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Universal Emergency
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundStyle(.red)
                VStack(alignment: .leading) {
                    Text("Universal Emergency")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("112 / 911")
                        .font(.headline)
                }
                Spacer()
                Button {
                    if let url = URL(string: "tel:911") {
                        openURL(url)
                    }
                } label: {
                    Image(systemName: "phone.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }

            Divider()

            // Satellite Emergency
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading) {
                    Text("Satellite Messaging")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Garmin inReach / SPOT")
                        .font(.subheadline)
                }
            }

            Divider()

            // Important Notes
            VStack(alignment: .leading, spacing: 4) {
                Text("Remember")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)

                Text("- Stay calm and assess the situation")
                    .font(.caption)
                Text("- Know your exact location (coordinates)")
                    .font(.caption)
                Text("- Have satellite communicator ready")
                    .font(.caption)
                Text("- First aid kit location known to all")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Emergency Contact Row

struct EmergencyContactRow: View {
    let contact: Contact
    let openURL: OpenURLAction

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                if let priority = contact.emergencyPriority {
                    Text("#\(priority)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red)
                        .clipShape(Capsule())
                }

                VStack(alignment: .leading) {
                    Text(contact.name)
                        .font(.headline)
                    if !contact.role.isEmpty {
                        Text(contact.role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: contact.category.icon)
                    .foregroundStyle(.secondary)
            }

            // Quick actions
            HStack(spacing: 16) {
                if let phone = contact.primaryPhone {
                    Button {
                        let cleanPhone = phone.replacingOccurrences(of: " ", with: "")
                        if let url = URL(string: "tel:\(cleanPhone)") {
                            openURL(url)
                        }
                    } label: {
                        Label("Call", systemImage: "phone.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }

                if let email = contact.email {
                    Button {
                        if let url = URL(string: "mailto:\(email)") {
                            openURL(url)
                        }
                    } label: {
                        Label("Email", systemImage: "envelope.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }

                if let cellPhone = contact.cellPhone, cellPhone != contact.phone {
                    Button {
                        let cleanPhone = cellPhone.replacingOccurrences(of: " ", with: "")
                        if let url = URL(string: "tel:\(cleanPhone)") {
                            openURL(url)
                        }
                    } label: {
                        Label("Cell", systemImage: "iphone")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Contact details
            if let phone = contact.phone {
                HStack {
                    Image(systemName: "phone")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(phone)
                        .font(.caption)
                }
            }

            if !contact.location.isEmpty {
                HStack {
                    Image(systemName: "location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(contact.location)
                        .font(.caption)
                }
            }

            if let hours = contact.hours {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(hours)
                        .font(.caption)
                }
            }

            if !contact.notes.isEmpty {
                Text(contact.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        EmergencyContactsView(
            expedition: {
                let exp = Expedition(name: "Test Expedition")
                let contact1 = Contact(
                    name: "Park Ranger Station",
                    role: "Emergency Services",
                    category: .emergency
                )
                contact1.phone = "+1 555-1234"
                contact1.isEmergencyContact = true
                contact1.emergencyPriority = 1

                let contact2 = Contact(
                    name: "Local Hospital",
                    role: "Medical",
                    category: .emergency
                )
                contact2.phone = "+1 555-5678"
                contact2.isEmergencyContact = true
                contact2.emergencyPriority = 2

                exp.contacts = [contact1, contact2]
                return exp
            }()
        )
    }
}
