import SwiftUI

struct TravelDocumentRowView: View {
    let document: TravelDocument

    var body: some View {
        HStack(spacing: 12) {
            // Document type indicator
            VStack {
                Image(systemName: document.documentType.icon)
                    .font(.title2)
                    .foregroundStyle(colorForStatus)
            }
            .frame(width: 40, height: 40)
            .background(colorForStatus.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayTitle)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(document.applicationStatus.rawValue, systemImage: document.applicationStatus.icon)
                        .font(.caption)
                        .foregroundStyle(colorForApplicationStatus)

                    if !document.destinationCountry.isEmpty {
                        Text(document.destinationCountry)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Expiry warning indicator
            if document.isExpired {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            } else if document.isExpiringSoon {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    private var colorForStatus: Color {
        switch document.statusColor {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        case "gray": return .gray
        default: return .secondary
        }
    }

    private var colorForApplicationStatus: Color {
        switch document.applicationStatus.color {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        case "gray": return .gray
        default: return .secondary
        }
    }
}
