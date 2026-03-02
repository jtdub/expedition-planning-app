import SwiftUI

struct EscapeRouteRowView: View {
    let route: EscapeRoute

    var body: some View {
        HStack(spacing: 12) {
            // Route type indicator
            VStack {
                Image(systemName: route.routeType.icon)
                    .font(.title2)
                    .foregroundStyle(colorForType)
            }
            .frame(width: 40, height: 40)
            .background(colorForType.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(route.name)
                        .font(.headline)
                        .lineLimit(1)

                    if route.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                HStack(spacing: 8) {
                    if let dayRange = route.dayRangeDescription {
                        Text(dayRange)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !route.destinationName.isEmpty {
                        Label(route.destinationName, systemImage: route.destinationType.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Distance and time
            VStack(alignment: .trailing, spacing: 2) {
                if let distance = route.distance {
                    Text(formatDistance(distance))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                if let time = route.formattedEstimatedTime {
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var colorForType: Color {
        switch route.routeType.color {
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .secondary
        }
    }

    private func formatDistance(_ distance: Measurement<UnitLength>) -> String {
        let km = distance.converted(to: .kilometers)
        if km.value < 1 {
            let meters = distance.converted(to: .meters)
            return String(format: "%.0f m", meters.value)
        }
        return String(format: "%.1f km", km.value)
    }
}
