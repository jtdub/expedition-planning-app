import SwiftUI

struct WaterSourceRowView: View {
    let source: WaterSource

    var body: some View {
        HStack(spacing: 12) {
            // Source type indicator
            VStack {
                Image(systemName: source.sourceType.icon)
                    .font(.title2)
                    .foregroundStyle(colorForReliability)
            }
            .frame(width: 40, height: 40)
            .background(colorForReliability.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(source.reliability.rawValue, systemImage: source.reliability.icon)
                        .font(.caption)
                        .foregroundStyle(colorForReliability)

                    if source.needsTreatment {
                        Label(source.treatmentRequired.rawValue, systemImage: source.treatmentRequired.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Status indicators
            VStack(alignment: .trailing, spacing: 2) {
                if source.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                if source.hasCoordinates {
                    Image(systemName: "mappin.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var colorForReliability: Color {
        switch source.reliability.color {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        default: return .secondary
        }
    }
}
