import SwiftUI
import SwiftData

struct RiskMatrixView: View {
    @Environment(\.dismiss)
    private var dismiss

    var viewModel: RiskAssessmentViewModel

    private let levels: [RiskLevel] = [.veryHigh, .high, .medium, .low, .veryLow]
    private let severityLevels: [RiskLevel] = [.veryLow, .low, .medium, .high, .veryHigh]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Legend
                legendSection

                // Matrix Grid
                matrixGrid

                // List of risks by cell
                risksByCell
            }
            .padding()
        }
        .navigationTitle("Risk Matrix")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Legend

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Risk Assessment Matrix")
                .font(.headline)

            HStack(spacing: 16) {
                legendItem(color: .green, label: "Low (1-3)")
                legendItem(color: .yellow, label: "Medium (4-6)")
                legendItem(color: .orange, label: "High (7-12)")
                legendItem(color: .red, label: "Critical (13+)")
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Matrix Grid

    private var matrixGrid: some View {
        VStack(spacing: 0) {
            // Header row (Severity labels)
            HStack(spacing: 0) {
                // Empty corner cell
                Text("")
                    .frame(width: 60, height: 30)

                ForEach(severityLevels, id: \.self) { level in
                    Text(level.rawValue)
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                }
            }

            Text("Severity \u{2192}")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 8)

            // Matrix rows (Likelihood)
            ForEach(levels, id: \.self) { likelihood in
                HStack(spacing: 0) {
                    // Row label
                    Text(likelihood.rawValue)
                        .font(.caption2)
                        .frame(width: 60, height: 50)
                        .multilineTextAlignment(.trailing)

                    // Cells
                    ForEach(severityLevels, id: \.self) { severity in
                        matrixCell(likelihood: likelihood, severity: severity)
                    }
                }
            }

            HStack {
                Text("\u{2191} Likelihood")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.leading, 8)
        }
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func matrixCell(likelihood: RiskLevel, severity: RiskLevel) -> some View {
        let score = likelihood.value * severity.value
        let assessments = viewModel.assessmentsForMatrix(likelihood: likelihood, severity: severity)
        let count = assessments.count

        return ZStack {
            Rectangle()
                .fill(colorForScore(score))
                .opacity(count > 0 ? 1.0 : 0.3)

            if count > 0 {
                VStack(spacing: 2) {
                    Text("\(count)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("\(score)")
                        .font(.caption2)
                }
                .foregroundStyle(.white)
            } else {
                Text("\(score)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .border(Color.white.opacity(0.3), width: 0.5)
    }

    // MARK: - Risks by Cell

    private var risksByCell: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risks by Rating")
                .font(.headline)

            ForEach(viewModel.groupedByRiskRating, id: \.rating) { group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: group.rating.icon)
                            .foregroundStyle(colorForRating(group.rating))
                        Text(group.rating.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("(\(group.assessments.count))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(group.assessments) { assessment in
                        HStack {
                            Image(systemName: assessment.hazardType.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(assessment.title)
                                .font(.caption)
                            Spacer()
                            if assessment.isAddressed {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                            Text("L:\(assessment.likelihood.value) S:\(assessment.severity.value)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 20)
                    }
                }
                .padding()
                .background(colorForRating(group.rating).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if viewModel.groupedByRiskRating.isEmpty {
                Text("No risk assessments added yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...12: return .orange
        default: return .red
        }
    }

    private func colorForRating(_ rating: RiskRating) -> Color {
        switch rating.color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        RiskMatrixView(
            viewModel: RiskAssessmentViewModel(
                // swiftlint:disable:next force_try
                modelContext: try! ModelContainer(
                    for: Expedition.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                ).mainContext
            )
        )
    }
}
