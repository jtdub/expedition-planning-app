import SwiftUI

struct ItineraryDayRowView: View {
    let day: ItineraryDay
    let elevationUnit: ElevationUnit

    private var risk: AcclimatizationRisk {
        ElevationService.assessRisk(for: day)
    }

    private var activityColor: Color {
        Color(day.activityType.color)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Day number badge
            dayNumberBadge

            // Main content
            VStack(alignment: .leading, spacing: 4) {
                // Location line
                locationLine

                // Activity and date line
                detailsLine
            }

            Spacer()

            // Elevation indicators
            if day.startElevationMeters != nil || day.endElevationMeters != nil {
                elevationIndicators
            }

            // Warning indicator
            if risk != .none {
                AcclimatizationWarningBadge(risk: risk)
            }
        }
        .padding(.vertical, 4)
    }

    private var dayNumberBadge: some View {
        ZStack {
            Circle()
                .fill(activityColor.opacity(0.15))
                .frame(width: 44, height: 44)

            VStack(spacing: 0) {
                Text("Day")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(day.dayNumber)")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(activityColor)
        }
    }

    @ViewBuilder private var locationLine: some View {
        if !day.startLocation.isEmpty || !day.endLocation.isEmpty {
            HStack(spacing: 4) {
                if !day.startLocation.isEmpty {
                    Text(day.startLocation)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                if !day.startLocation.isEmpty && !day.endLocation.isEmpty {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !day.endLocation.isEmpty {
                    Text(day.endLocation)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .lineLimit(1)
        } else if !day.location.isEmpty {
            Text(day.location)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
        } else {
            Text("No location set")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .italic()
        }
    }

    private var detailsLine: some View {
        HStack(spacing: 8) {
            // Activity type badge
            Label(day.activityType.rawValue, systemImage: day.activityType.icon)
                .font(.caption)
                .foregroundStyle(activityColor)

            // Date if available
            if let date = day.date {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Duration if available
            if let hours = day.estimatedHours, hours > 0 {
                Label(formatHours(hours), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var elevationIndicators: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let end = day.endElevationMeters {
                Text(ElevationService.formatElevation(end, unit: elevationUnit))
                    .font(.caption)
                    .fontWeight(.medium)
            }

            if let gain = day.elevationGain, gain.value > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                        .font(.caption2)
                    Text(ElevationService.formatElevationChange(gain.value, unit: elevationUnit, showSign: false))
                        .font(.caption2)
                }
                .foregroundStyle(.green)
            } else if let loss = day.elevationLoss, loss.value > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                    Text(ElevationService.formatElevationChange(loss.value, unit: elevationUnit, showSign: false))
                        .font(.caption2)
                }
                .foregroundStyle(.red)
            }
        }
    }

    private func formatHours(_ hours: Double) -> String {
        let wholeHours = Int(hours)
        let minutes = Int((hours - Double(wholeHours)) * 60)

        if minutes > 0 {
            return "\(wholeHours)h \(minutes)m"
        } else {
            return "\(wholeHours)h"
        }
    }
}

// MARK: - Acclimatization Warning Badge

struct AcclimatizationWarningBadge: View {
    let risk: AcclimatizationRisk

    @State private var showingPopover = false

    var body: some View {
        Button {
            showingPopover = true
        } label: {
            Image(systemName: risk.icon)
                .font(.caption)
                .foregroundStyle(risk.color)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPopover) {
            VStack(alignment: .leading, spacing: 8) {
                Label(risk.rawValue, systemImage: risk.icon)
                    .font(.headline)
                    .foregroundStyle(risk.color)

                Text(risk.description)
                    .font(.subheadline)

                Divider()

                Text("Recommendation")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(ElevationService.recommendation(for: risk))
                    .font(.subheadline)
            }
            .padding()
            .frame(maxWidth: 280)
            .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview {
    List {
        ItineraryDayRowView(
            day: {
                let day = ItineraryDay(
                    dayNumber: 1,
                    date: Date(),
                    startLocation: "Cusco",
                    endLocation: "Soraypampa",
                    activityType: .fieldWork
                )
                day.startElevationMeters = 3400
                day.endElevationMeters = 3900
                day.estimatedHours = 6.5
                return day
            }(),
            elevationUnit: .meters
        )

        ItineraryDayRowView(
            day: {
                let day = ItineraryDay(
                    dayNumber: 2,
                    date: Date().addingTimeInterval(86400),
                    startLocation: "Soraypampa",
                    endLocation: "Salkantay Pass",
                    activityType: .summit
                )
                day.startElevationMeters = 3900
                day.endElevationMeters = 4630
                day.estimatedHours = 8
                return day
            }(),
            elevationUnit: .meters
        )

        ItineraryDayRowView(
            day: ItineraryDay(
                dayNumber: 3,
                date: Date().addingTimeInterval(86400 * 2),
                activityType: .restDay,
                clientDescription: "Rest and acclimatize"
            ),
            elevationUnit: .meters
        )
    }
}
