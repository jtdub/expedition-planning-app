import SwiftUI
import Charts

struct ElevationChartView: View {
    let data: [ElevationService.ElevationPoint]
    let unit: ElevationUnit

    @State private var selectedPoint: ElevationService.ElevationPoint?

    private var displayData: [(point: ElevationService.ElevationPoint, displayElevation: Double)] {
        data.map { point in
            let elevation: Double
            if unit == .feet {
                elevation = ElevationService.metersToFeet(point.displayElevation)
            } else {
                elevation = point.displayElevation
            }
            return (point, elevation)
        }
    }

    private var minElevation: Double {
        let min = displayData.map { $0.displayElevation }.min() ?? 0
        return max(0, min - 200)
    }

    private var maxElevation: Double {
        let max = displayData.map { $0.displayElevation }.max() ?? 1000
        return max + 200
    }

    private var unitLabel: String {
        unit == .feet ? "ft" : "m"
    }

    var body: some View {
        if data.isEmpty {
            emptyState
        } else {
            chartContent
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Elevation Data", systemImage: "chart.line.uptrend.xyaxis")
        } description: {
            Text("Add elevation data to days to see the profile.")
        }
        .frame(height: 200)
    }

    private var chartContent: some View {
        Chart {
            // Area fill under the line
            ForEach(displayData, id: \.point.id) { item in
                AreaMark(
                    x: .value("Day", item.point.dayNumber),
                    y: .value("Elevation", item.displayElevation)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [activityColor(for: item.point.activityType).opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            // Line connecting elevations
            ForEach(displayData, id: \.point.id) { item in
                LineMark(
                    x: .value("Day", item.point.dayNumber),
                    y: .value("Elevation", item.displayElevation)
                )
                .foregroundStyle(activityColor(for: item.point.activityType))
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            // Points with risk indicators
            ForEach(displayData, id: \.point.id) { item in
                PointMark(
                    x: .value("Day", item.point.dayNumber),
                    y: .value("Elevation", item.displayElevation)
                )
                .foregroundStyle(pointColor(for: item.point))
                .symbolSize(item.point.risk != .none ? 80 : 40)
                .symbol(item.point.risk != .none ? .diamond : .circle)
            }

            // Selection indicator
            if let selected = selectedPoint,
               let selectedData = displayData.first(where: { $0.point.id == selected.id }) {
                RuleMark(x: .value("Day", selected.dayNumber))
                    .foregroundStyle(.secondary.opacity(0.3))

                PointMark(
                    x: .value("Day", selected.dayNumber),
                    y: .value("Elevation", selectedData.displayElevation)
                )
                .foregroundStyle(.blue)
                .symbolSize(100)
            }
        }
        .chartYScale(domain: minElevation...maxElevation)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let day = value.as(Int.self) {
                        Text("D\(day)")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let elevation = value.as(Double.self) {
                        Text("\(Int(elevation))")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { _ in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let xPosition = value.location.x
                                if let dayNumber: Int = proxy.value(atX: xPosition) {
                                    selectedPoint = data.first { $0.dayNumber == dayNumber }
                                }
                            }
                            .onEnded { _ in
                                selectedPoint = nil
                            }
                    )
            }
        }
        .chartBackground { _ in
            Color.clear
        }
        .overlay(alignment: .topLeading) {
            if let selected = selectedPoint {
                pointDetailOverlay(for: selected)
                    .padding(8)
            }
        }
    }

    @ViewBuilder
    private func pointDetailOverlay(for point: ElevationService.ElevationPoint) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Day \(point.dayNumber)")
                .font(.caption)
                .fontWeight(.semibold)

            if let elevation = point.endElevation ?? point.startElevation {
                Text(ElevationService.formatElevation(elevation, unit: unit))
                    .font(.caption)
            }

            Text(point.activityType.rawValue)
                .font(.caption2)
                .foregroundStyle(.secondary)

            if point.risk != .none {
                Label(point.risk.rawValue, systemImage: point.risk.icon)
                    .font(.caption2)
                    .foregroundStyle(point.risk.color)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func activityColor(for type: ActivityType) -> Color {
        Color(type.color)
    }

    private func pointColor(for point: ElevationService.ElevationPoint) -> Color {
        if point.risk == .extreme {
            return .red
        } else if point.risk == .high {
            return .orange
        } else if point.risk == .moderate {
            return .yellow
        } else {
            return activityColor(for: point.activityType)
        }
    }
}

// MARK: - Compact Chart Variant

struct ElevationChartCompactView: View {
    let data: [ElevationService.ElevationPoint]
    let unit: ElevationUnit

    private var displayData: [(dayNumber: Int, elevation: Double)] {
        data.compactMap { point in
            guard let elevation = point.endElevation ?? point.startElevation else {
                return nil
            }
            let display = unit == .feet ? ElevationService.metersToFeet(elevation) : elevation
            return (point.dayNumber, display)
        }
    }

    var body: some View {
        Chart(displayData, id: \.dayNumber) { item in
            LineMark(
                x: .value("Day", item.dayNumber),
                y: .value("Elevation", item.elevation)
            )
            .foregroundStyle(.green)

            AreaMark(
                x: .value("Day", item.dayNumber),
                y: .value("Elevation", item.elevation)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [.green.opacity(0.3), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

#Preview {
    let sampleData: [ElevationService.ElevationPoint] = [
        ElevationService.ElevationPoint(
            dayNumber: 1,
            date: Date(),
            startElevation: 2800,
            endElevation: 3400,
            highPoint: nil,
            lowPoint: nil,
            activityType: .fieldWork,
            risk: .none
        ),
        ElevationService.ElevationPoint(
            dayNumber: 2,
            date: Date().addingTimeInterval(86400),
            startElevation: 3400,
            endElevation: 3800,
            highPoint: nil,
            lowPoint: nil,
            activityType: .fieldWork,
            risk: .none
        ),
        ElevationService.ElevationPoint(
            dayNumber: 3,
            date: Date().addingTimeInterval(86400 * 2),
            startElevation: 3800,
            endElevation: 3800,
            highPoint: nil,
            lowPoint: nil,
            activityType: .restDay,
            risk: .none
        ),
        ElevationService.ElevationPoint(
            dayNumber: 4,
            date: Date().addingTimeInterval(86400 * 3),
            startElevation: 3800,
            endElevation: 4600,
            highPoint: 4630,
            lowPoint: nil,
            activityType: .summit,
            risk: .high
        ),
        ElevationService.ElevationPoint(
            dayNumber: 5,
            date: Date().addingTimeInterval(86400 * 4),
            startElevation: 4600,
            endElevation: 3200,
            highPoint: nil,
            lowPoint: nil,
            activityType: .fieldWork,
            risk: .none
        )
    ]

    return VStack {
        ElevationChartView(data: sampleData, unit: .meters)
            .frame(height: 200)
            .padding()

        ElevationChartCompactView(data: sampleData, unit: .meters)
            .frame(height: 60)
            .padding()
    }
}
