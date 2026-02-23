import SwiftUI

struct AcclimatizationWarningView: View {
    let risk: AcclimatizationRisk

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: risk.icon)
                        .font(.title2)

                    VStack(alignment: .leading) {
                        Text(risk.rawValue)
                            .font(.headline)

                        Text(risk.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(risk.color)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendation")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(ElevationService.recommendation(for: risk))
                        .font(.body)

                    if risk == .high || risk == .extreme {
                        Divider()

                        Text("Signs of Altitude Sickness")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        VStack(alignment: .leading, spacing: 4) {
                            symptomRow("Headache")
                            symptomRow("Nausea or vomiting")
                            symptomRow("Fatigue or weakness")
                            symptomRow("Dizziness")
                            symptomRow("Difficulty sleeping")
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(risk.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func symptomRow(_ symptom: String) -> some View {
        Label(symptom, systemImage: "exclamationmark.circle")
            .foregroundStyle(.secondary)
    }
}

// MARK: - Inline Warning Badge

struct AcclimatizationWarningBadgeInline: View {
    let risk: AcclimatizationRisk

    var body: some View {
        if risk != .none {
            HStack(spacing: 4) {
                Image(systemName: risk.icon)
                Text(risk.rawValue)
            }
            .font(.caption)
            .foregroundStyle(risk.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(risk.color.opacity(0.15))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Warning Summary for Multiple Days

struct AcclimatizationWarningSummary: View {
    let days: [ItineraryDay]

    private var daysWithRisk: [(day: ItineraryDay, risk: AcclimatizationRisk)] {
        days.compactMap { day in
            let risk = ElevationService.assessRisk(for: day)
            guard risk != .none else { return nil }
            return (day, risk)
        }
    }

    private var highRiskCount: Int {
        daysWithRisk.filter { $0.risk == .high || $0.risk == .extreme }.count
    }

    private var moderateRiskCount: Int {
        daysWithRisk.filter { $0.risk == .moderate }.count
    }

    var body: some View {
        if !daysWithRisk.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)

                    Text("Acclimatization Warnings")
                        .font(.headline)

                    Spacer()

                    Text("\(daysWithRisk.count) day\(daysWithRisk.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if highRiskCount > 0 {
                    Label(
                        "\(highRiskCount) high-risk day\(highRiskCount == 1 ? "" : "s")",
                        systemImage: "exclamationmark.octagon.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.red)
                }

                if moderateRiskCount > 0 {
                    Label(
                        "\(moderateRiskCount) moderate-risk day\(moderateRiskCount == 1 ? "" : "s")",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.caption)
                    .foregroundStyle(.yellow)
                }

                Divider()

                ForEach(daysWithRisk, id: \.day.id) { item in
                    HStack {
                        Text("Day \(item.day.dayNumber)")
                            .font(.caption)
                            .fontWeight(.medium)

                        Spacer()

                        if let gain = item.day.elevationGain {
                            Text("+\(Int(gain.value))m")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Image(systemName: item.risk.icon)
                            .font(.caption)
                            .foregroundStyle(item.risk.color)
                    }
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            AcclimatizationWarningView(risk: .moderate)
            AcclimatizationWarningView(risk: .high)
            AcclimatizationWarningView(risk: .extreme)

            Divider()

            HStack {
                AcclimatizationWarningBadgeInline(risk: .moderate)
                AcclimatizationWarningBadgeInline(risk: .high)
                AcclimatizationWarningBadgeInline(risk: .extreme)
            }
        }
        .padding()
    }
}
