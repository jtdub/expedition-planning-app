import SwiftUI
import SwiftData

struct BudgetRowView: View {
    let item: BudgetItem
    let viewModel: BudgetViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: item.category.icon)
                .font(.title2)
                .foregroundStyle(categoryColor)
                .frame(width: 32)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.name)
                        .font(.headline)

                    if item.isPaid {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }

                if let vendor = item.vendor, !vendor.isEmpty {
                    Text(vendor)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let date = item.dateIncurred {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.formattedEstimate)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let actual = item.actualAmount {
                    HStack(spacing: 2) {
                        Text("Actual:")
                            .font(.caption2)
                        Text(viewModel.formatCurrency(actual, code: item.currency))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(item.isOverBudget ? .red : .green)
                    }
                }

                if let variance = item.variancePercentage {
                    Text(varianceText(variance))
                        .font(.caption2)
                        .foregroundStyle(variance > 0 ? .red : .green)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch item.category.color {
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "gray": return .secondary
        case "green": return .green
        case "brown": return .brown
        case "teal": return .teal
        case "indigo": return .indigo
        case "cyan": return .cyan
        case "red": return .red
        default: return .secondary
        }
    }

    private func varianceText(_ percentage: Double) -> String {
        let prefix = percentage > 0 ? "+" : ""
        return "\(prefix)\(Int(percentage))%"
    }
}

#Preview {
    List {
        BudgetRowView(
            item: {
                let i = BudgetItem(name: "Flight to Fairbanks", category: .flights, estimatedAmount: 1200)
                i.actualAmount = 1350
                i.isPaid = true
                i.vendor = "Alaska Airlines"
                return i
            }(),
            // swiftlint:disable:next force_try
            viewModel: BudgetViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )

        BudgetRowView(
            item: BudgetItem(name: "Wilderness Permit", category: .permits, estimatedAmount: 50),
            // swiftlint:disable:next force_try
            viewModel: BudgetViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext)
        )
    }
}
