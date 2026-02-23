import SwiftUI

struct PermitRowView: View {
    let permit: Permit

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: permit.permitType.icon)
                .font(.title2)
                .foregroundStyle(statusColor)
                .frame(width: 32)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(permit.name)
                    .font(.headline)

                Text(permit.issuingAuthority)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let deadline = permit.applicationDeadline {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text("Due: \(deadline.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                    }
                    .foregroundStyle(deadlineColor)
                }
            }

            Spacer()

            // Status badge
            VStack(alignment: .trailing, spacing: 4) {
                statusBadge

                if let cost = permit.cost {
                    Text(formatCurrency(cost, code: permit.currency))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
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

    private var deadlineColor: Color {
        if permit.isOverdue {
            return .red
        } else if let days = permit.daysUntilDeadline, days <= 7 {
            return .orange
        }
        return .secondary
    }

    @ViewBuilder private var statusBadge: some View {
        Text(permit.status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private func formatCurrency(_ amount: Decimal, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: amount as NSDecimalNumber) ?? ""
    }
}

#Preview {
    List {
        PermitRowView(
            permit: {
                let permit = Permit(name: "Wilderness Permit", issuingAuthority: "National Park Service")
                permit.status = .obtained
                permit.applicationDeadline = Date().addingTimeInterval(-86400 * 7)
                permit.cost = 50
                return permit
            }()
        )
        PermitRowView(
            permit: {
                let permit = Permit(name: "Research Permit", issuingAuthority: "BLM", permitType: .research)
                permit.status = .submitted
                permit.applicationDeadline = Date().addingTimeInterval(86400 * 14)
                return permit
            }()
        )
    }
}
