import SwiftUI
import SwiftData

struct BudgetSummaryView: View {
    let viewModel: BudgetViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Main totals
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Estimated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.formatCurrency(viewModel.totalEstimated))
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("Actual")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.formatCurrency(viewModel.totalActual))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(viewModel.totalVariance > 0 ? .red : .primary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("Variance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(varianceText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(varianceColor)
                }
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Status row
            HStack(spacing: 16) {
                Label("\(viewModel.paidCount) paid", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)

                Label(viewModel.formatCurrency(viewModel.unpaidTotal) + " unpaid", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.orange)

                if viewModel.overBudgetCount > 0 {
                    Label("\(viewModel.overBudgetCount) over budget", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var varianceText: String {
        let variance = viewModel.totalVariance
        let prefix = variance > 0 ? "+" : ""
        return prefix + viewModel.formatCurrency(variance)
    }

    private var varianceColor: Color {
        let variance = viewModel.totalVariance
        if variance > 0 {
            return .red
        } else if variance < 0 {
            return .green
        }
        return .primary
    }
}

#Preview {
    List {
        Section {
            // swiftlint:disable:next force_try
            BudgetSummaryView(viewModel: BudgetViewModel(modelContext: try! ModelContainer(
                for: Expedition.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ).mainContext))
        }
    }
}
