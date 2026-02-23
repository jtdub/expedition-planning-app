import SwiftUI

struct ParticipantRowView: View {
    let participant: Participant

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.2))
                Text(participant.initials)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(avatarColor)
            }
            .frame(width: 40, height: 40)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(participant.displayName)
                        .font(.headline)

                    if participant.role.isStaff {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                HStack(spacing: 8) {
                    Label(participant.role.rawValue, systemImage: participant.role.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !participant.groupAssignment.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(participant.groupAssignment)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Status indicators
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    if participant.isConfirmed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    if participant.hasPaid {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                if let date = participant.arrivalDate {
                    Text(date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var avatarColor: Color {
        switch participant.role {
        case .guide:
            return .orange
        case .assistantGuide:
            return .yellow
        case .participant:
            return .blue
        case .client:
            return .purple
        case .researcher:
            return .teal
        case .photographer:
            return .pink
        case .support:
            return .green
        }
    }
}

#Preview {
    List {
        ParticipantRowView(
            participant: {
                let participant = Participant(name: "John Doe", email: "john@example.com", role: .guide)
                participant.isConfirmed = true
                participant.hasPaid = true
                participant.groupAssignment = "Group A"
                return participant
            }()
        )
        ParticipantRowView(
            participant: Participant(name: "Jane Smith", email: "jane@example.com", role: .participant)
        )
    }
}
