import SwiftUI

struct ContactRowView: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: contact.category.icon)
                .font(.title2)
                .foregroundStyle(categoryColor)
                .frame(width: 32)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(contact.name)
                        .font(.headline)

                    if contact.isEmergencyContact {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }

                Text(contact.displaySubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if !contact.location.isEmpty {
                    Text(contact.location)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Contact actions indicator
            VStack(alignment: .trailing, spacing: 4) {
                if contact.primaryPhone != nil {
                    Image(systemName: "phone.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                if contact.email != nil {
                    Image(systemName: "envelope.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 4)
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
    List {
        ContactRowView(
            contact: {
                let contact = Contact(name: "Park Ranger Station", role: "Emergency", category: .emergency)
                contact.phone = "+1 555-1234"
                contact.isEmergencyContact = true
                contact.emergencyPriority = 1
                return contact
            }()
        )
        ContactRowView(
            contact: Contact(
                name: "Mountain Lodge",
                role: "Accommodation",
                category: .accommodation,
                location: "Fairbanks"
            )
        )
    }
}
