import SwiftUI

struct GearRowView: View {
    let item: GearItem
    let weightUnit: WeightUnit
    var onTogglePacked: (() -> Void)?

    private var priorityColor: Color {
        switch item.priority.color {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            priorityIndicator

            // Main content
            VStack(alignment: .leading, spacing: 4) {
                // Name and quantity
                nameRow

                // Details line
                detailsRow
            }

            Spacer()

            // Weight display
            if let weight = item.totalWeight {
                weightDisplay(grams: weight.value)
            }

            // Status button
            statusButton
        }
        .padding(.vertical, 4)
    }

    private var priorityIndicator: some View {
        Image(systemName: item.priority.icon)
            .font(.title3)
            .foregroundStyle(priorityColor)
            .frame(width: 28)
    }

    private var nameRow: some View {
        HStack(spacing: 4) {
            Text(item.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            if item.quantity > 1 {
                Text("×\(item.quantity)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var detailsRow: some View {
        HStack(spacing: 8) {
            // Category badge
            Label(item.category.rawValue, systemImage: item.category.icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Carrier badge for group gear
            if item.ownershipType == .group {
                Label(
                    item.carriedByName,
                    systemImage: "person.3"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            // Selection if available
            if !item.selection.isEmpty {
                Text(item.selection)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
    }

    private func weightDisplay(grams: Double) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(formatWeight(grams))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }

    private var statusButton: some View {
        Button {
            onTogglePacked?()
        } label: {
            Image(systemName: item.statusIcon)
                .font(.title3)
                .foregroundStyle(statusColor)
        }
        .buttonStyle(.plain)
    }

    private var statusColor: Color {
        if item.isPacked {
            return .green
        } else if item.isInHand {
            return .blue
        } else if item.isWeighed {
            return .orange
        }
        return .secondary
    }

    private func formatWeight(_ grams: Double) -> String {
        switch weightUnit {
        case .kilograms:
            let kg = grams / 1000
            if kg >= 1 {
                return String(format: "%.1f kg", kg)
            } else {
                return String(format: "%.0f g", grams)
            }
        case .pounds:
            let lbs = grams / 453.592
            if lbs >= 1 {
                return String(format: "%.1f lb", lbs)
            } else {
                let oz = grams / 28.3495
                return String(format: "%.1f oz", oz)
            }
        case .ounces:
            let oz = grams / 28.3495
            return String(format: "%.1f oz", oz)
        }
    }
}

#Preview {
    List {
        GearRowView(
            item: {
                let item = GearItem(
                    name: "Tent",
                    category: .shelter,
                    priority: .critical,
                    quantity: 1
                )
                item.weightGrams = 1500
                item.isPacked = true
                return item
            }(),
            weightUnit: .kilograms
        )

        GearRowView(
            item: {
                let item = GearItem(
                    name: "Trail Running Shoes",
                    category: .footwear,
                    priority: .suggested,
                    selection: "Altra Lone Peak 7"
                )
                item.weightGrams = 580
                item.isInHand = true
                return item
            }(),
            weightUnit: .kilograms
        )

        GearRowView(
            item: {
                let item = GearItem(
                    name: "Headlamp",
                    category: .electronics,
                    priority: .critical,
                    quantity: 2
                )
                item.weightGrams = 45
                return item
            }(),
            weightUnit: .pounds
        )

        GearRowView(
            item: GearItem(
                name: "Bear Spray",
                category: .toolsFirstAidEmergency,
                priority: .contingent
            ),
            weightUnit: .kilograms
        )
    }
}
