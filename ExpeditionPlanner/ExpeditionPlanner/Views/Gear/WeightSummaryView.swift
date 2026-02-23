import SwiftUI

struct WeightSummaryView: View {
    let totalWeightGrams: Double
    let packedWeightGrams: Double
    let itemCount: Int
    let packedCount: Int
    let weightUnit: WeightUnit

    private var completionPercentage: Double {
        guard itemCount > 0 else { return 0 }
        return Double(packedCount) / Double(itemCount)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Weight display
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                // Total weight
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Weight")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatWeight(totalWeightGrams))
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                // Packed weight
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Packed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatWeight(packedWeightGrams))
                        .font(.headline)
                        .foregroundStyle(.green)
                }
            }

            // Progress section
            VStack(spacing: 6) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)

                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * completionPercentage, height: 8)
                    }
                }
                .frame(height: 8)

                // Count label
                HStack {
                    Text("\(packedCount) of \(itemCount) items packed")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(completionPercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(progressColor)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var progressColor: Color {
        if completionPercentage >= 1.0 {
            return .green
        } else if completionPercentage >= 0.5 {
            return .blue
        } else if completionPercentage >= 0.25 {
            return .orange
        }
        return .red
    }

    private func formatWeight(_ grams: Double) -> String {
        switch weightUnit {
        case .kilograms:
            let kg = grams / 1000
            if kg >= 1 {
                return String(format: "%.2f kg", kg)
            } else {
                return String(format: "%.0f g", grams)
            }
        case .pounds:
            let lbs = grams / 453.592
            return String(format: "%.1f lb", lbs)
        case .ounces:
            let oz = grams / 28.3495
            return String(format: "%.1f oz", oz)
        }
    }
}

// MARK: - Category Weight Row

struct CategoryWeightRow: View {
    let category: GearCategory
    let weightGrams: Double
    let totalWeightGrams: Double
    let weightUnit: WeightUnit

    private var percentage: Double {
        guard totalWeightGrams > 0 else { return 0 }
        return weightGrams / totalWeightGrams
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(category.rawValue)
                .font(.caption)

            Spacer()

            Text(formatWeight(weightGrams))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text("\(Int(percentage * 100))%")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(width: 30, alignment: .trailing)
        }
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
        Section {
            WeightSummaryView(
                totalWeightGrams: 12500,
                packedWeightGrams: 8750,
                itemCount: 45,
                packedCount: 32,
                weightUnit: .kilograms
            )
        }

        Section("Weight by Category") {
            CategoryWeightRow(
                category: .shelter,
                weightGrams: 2500,
                totalWeightGrams: 12500,
                weightUnit: .kilograms
            )
            CategoryWeightRow(
                category: .sleep,
                weightGrams: 1800,
                totalWeightGrams: 12500,
                weightUnit: .kilograms
            )
            CategoryWeightRow(
                category: .kitchen,
                weightGrams: 900,
                totalWeightGrams: 12500,
                weightUnit: .kilograms
            )
        }
    }
}
