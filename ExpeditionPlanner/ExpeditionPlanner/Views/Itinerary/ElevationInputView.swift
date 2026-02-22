import SwiftUI

struct ElevationInputView: View {
    let label: String
    @Binding var value: Double?
    let unit: ElevationUnit

    @FocusState private var isFocused: Bool

    private var unitSuffix: String {
        switch unit {
        case .meters:
            return "m"
        case .feet:
            return "ft"
        }
    }

    var body: some View {
        HStack {
            Text(label)

            Spacer()

            TextField(
                unitSuffix,
                value: $value,
                format: .number.precision(.fractionLength(0))
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 80)
            .focused($isFocused)

            Text(unitSuffix)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            if value != nil {
                Button {
                    value = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Compact Elevation Display

struct ElevationDisplayView: View {
    let meters: Double?
    let unit: ElevationUnit
    let showIcon: Bool

    init(meters: Double?, unit: ElevationUnit, showIcon: Bool = false) {
        self.meters = meters
        self.unit = unit
        self.showIcon = showIcon
    }

    var body: some View {
        if let meters {
            HStack(spacing: 4) {
                if showIcon {
                    Image(systemName: "mountain.2")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(ElevationService.formatElevation(meters, unit: unit))
            }
        } else {
            Text("--")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Elevation Change Display

struct ElevationChangeView: View {
    let gainMeters: Double?
    let lossMeters: Double?
    let unit: ElevationUnit

    var body: some View {
        HStack(spacing: 8) {
            if let gain = gainMeters, gain > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                        .font(.caption2)
                    Text(ElevationService.formatElevationChange(gain, unit: unit, showSign: false))
                        .font(.caption)
                }
                .foregroundStyle(.green)
            }

            if let loss = lossMeters, loss > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                    Text(ElevationService.formatElevationChange(loss, unit: unit, showSign: false))
                        .font(.caption)
                }
                .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    Form {
        Section("Input") {
            ElevationInputView(
                label: "Start Elevation",
                value: .constant(3500),
                unit: .meters
            )

            ElevationInputView(
                label: "End Elevation",
                value: .constant(nil),
                unit: .feet
            )
        }

        Section("Display") {
            LabeledContent("With icon") {
                ElevationDisplayView(meters: 4500, unit: .meters, showIcon: true)
            }

            LabeledContent("Without icon") {
                ElevationDisplayView(meters: 4500, unit: .feet)
            }

            LabeledContent("Nil value") {
                ElevationDisplayView(meters: nil, unit: .meters)
            }
        }

        Section("Change") {
            ElevationChangeView(gainMeters: 500, lossMeters: nil, unit: .meters)
            ElevationChangeView(gainMeters: nil, lossMeters: 300, unit: .feet)
            ElevationChangeView(gainMeters: 500, lossMeters: 200, unit: .meters)
        }
    }
}
