import SwiftUI

struct RouteSegmentRowView: View {
    let segment: RouteSegment

    var body: some View {
        HStack(spacing: 12) {
            // Terrain type indicator
            VStack {
                Image(systemName: segment.terrainType.icon)
                    .font(.title2)
                    .foregroundStyle(colorForTerrain)
            }
            .frame(width: 40, height: 40)
            .background(colorForTerrain.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(segment.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let dayRange = segment.dayRangeDescription {
                        Text(dayRange)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(segment.terrainType.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(colorForTerrain.opacity(0.15))
                        .foregroundStyle(colorForTerrain)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            // Distance and time
            VStack(alignment: .trailing, spacing: 2) {
                if let distance = segment.distance {
                    Text(formatDistance(distance))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                if let time = segment.formattedEstimatedTime {
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var colorForTerrain: Color {
        switch segment.terrainType.color {
        case "green": return .green
        case "brown": return .brown
        case "blue": return .blue
        case "gray": return .gray
        case "cyan": return .cyan
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
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
