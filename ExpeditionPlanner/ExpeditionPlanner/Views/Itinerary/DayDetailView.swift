import SwiftUI
import SwiftData
import MapKit

struct DayDetailView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    let day: ItineraryDay
    let elevationUnit: ElevationUnit

    @State private var showingEditSheet = false

    private var risk: AcclimatizationRisk {
        ElevationService.assessRisk(for: day)
    }

    private var activityColor: Color {
        day.activityType.color
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with activity type
                    headerSection

                    // Content sections
                    VStack(spacing: 16) {
                        // Location Card
                        locationCard

                        // Elevation Card
                        if day.startElevationMeters != nil || day.endElevationMeters != nil {
                            elevationCard
                        }

                        // Map Card
                        if day.startCoordinate != nil || day.endCoordinate != nil {
                            mapCard
                        }

                        // Details Card
                        if day.estimatedHours != nil || day.distanceMeters != nil {
                            detailsCard
                        }

                        // Description Card
                        if !day.clientDescription.isEmpty {
                            descriptionCard(
                                title: "Client Description",
                                text: day.clientDescription
                            )
                        }

                        // Guide Notes Card
                        if !day.guideNotes.isEmpty {
                            descriptionCard(
                                title: "Guide Notes",
                                text: day.guideNotes,
                                isPrivate: true
                            )
                        }

                        // Camp Card
                        if day.nightNumber != nil || day.campName != nil {
                            campCard
                        }

                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Day \(day.dayNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                DayFormView(mode: .edit(day: day), modelContext: modelContext)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            // Activity type icon
            ZStack {
                Circle()
                    .fill(activityColor.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: day.activityType.icon)
                    .font(.title)
                    .foregroundStyle(activityColor)
            }

            Text(day.activityType.rawValue)
                .font(.headline)
                .foregroundStyle(activityColor)

            if let date = day.date {
                Text(date.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Warning badge if needed
            if risk != .none {
                HStack {
                    Image(systemName: risk.icon)
                    Text(risk.rawValue)
                }
                .font(.caption)
                .foregroundStyle(risk.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(risk.color.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(activityColor.opacity(0.05))
    }

    // MARK: - Location Card

    private var locationCard: some View {
        GroupBox("Location") {
            VStack(alignment: .leading, spacing: 8) {
                if !day.startLocation.isEmpty || !day.endLocation.isEmpty {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text("From")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(day.startLocation.isEmpty ? "--" : day.startLocation)
                                .font(.body)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .foregroundStyle(.secondary)

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("To")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(day.endLocation.isEmpty ? "--" : day.endLocation)
                                .font(.body)
                        }
                    }
                }

                if !day.location.isEmpty {
                    Divider()
                    LabeledContent("General Area", value: day.location)
                }
            }
        }
    }

    // MARK: - Elevation Card

    private var elevationCard: some View {
        GroupBox("Elevation") {
            VStack(spacing: 12) {
                HStack {
                    elevationValue(
                        label: "Start",
                        value: day.startElevationMeters,
                        icon: "arrow.up.right"
                    )

                    Spacer()

                    if let gain = day.elevationGain, gain.value > 0 {
                        VStack {
                            Image(systemName: "arrow.up")
                                .foregroundStyle(.green)
                            let formatted = ElevationService.formatElevationChange(
                                gain.value,
                                unit: elevationUnit,
                                showSign: true
                            )
                            Text(formatted)
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    } else if let loss = day.elevationLoss, loss.value > 0 {
                        VStack {
                            Image(systemName: "arrow.down")
                                .foregroundStyle(.red)
                            let formatted = ElevationService.formatElevationChange(
                                -loss.value,
                                unit: elevationUnit,
                                showSign: true
                            )
                            Text(formatted)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    Spacer()

                    elevationValue(
                        label: "End",
                        value: day.endElevationMeters,
                        icon: "mappin.circle"
                    )
                }

                if day.highPointMeters != nil || day.lowPointMeters != nil {
                    Divider()

                    HStack {
                        if let high = day.highPointMeters {
                            Label {
                                Text(ElevationService.formatElevation(high, unit: elevationUnit))
                            } icon: {
                                Image(systemName: "arrow.up.to.line")
                                    .foregroundStyle(.orange)
                            }
                            .font(.caption)
                        }

                        Spacer()

                        if let low = day.lowPointMeters {
                            Label {
                                Text(ElevationService.formatElevation(low, unit: elevationUnit))
                            } icon: {
                                Image(systemName: "arrow.down.to.line")
                                    .foregroundStyle(.blue)
                            }
                            .font(.caption)
                        }
                    }
                }

                // Risk recommendation if needed
                if risk != .none {
                    Divider()
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundStyle(.yellow)
                        Text(ElevationService.recommendation(for: risk))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func elevationValue(label: String, value: Double?, icon: String) -> some View {
        VStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(ElevationService.formatElevation(value, unit: elevationUnit))
                .font(.headline)
        }
    }

    // MARK: - Map Card

    private var mapCard: some View {
        GroupBox("Map") {
            Map {
                if let start = day.startCoordinate {
                    Marker(day.startLocation.isEmpty ? "Start" : day.startLocation, coordinate: start)
                        .tint(.green)
                }

                if let end = day.endCoordinate {
                    Marker(day.endLocation.isEmpty ? "End" : day.endLocation, coordinate: end)
                        .tint(.red)
                }

                if let start = day.startCoordinate, let end = day.endCoordinate {
                    MapPolyline(coordinates: [start, end])
                        .stroke(.blue, lineWidth: 2)
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        GroupBox("Details") {
            VStack(spacing: 8) {
                if let distance = day.distanceMeters {
                    LabeledContent("Distance") {
                        Text(formatDistance(distance))
                    }
                }

                if let hours = day.estimatedHours {
                    LabeledContent("Estimated Time") {
                        Text(formatHours(hours))
                    }
                }
            }
        }
    }

    // MARK: - Description Card

    private func descriptionCard(title: String, text: String, isPrivate: Bool = false) -> some View {
        GroupBox {
            Text(text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            HStack {
                Text(title)
                if isPrivate {
                    Image(systemName: "lock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Camp Card

    private var campCard: some View {
        GroupBox("Camp") {
            VStack(spacing: 8) {
                if let night = day.nightNumber {
                    LabeledContent("Night Number", value: "\(night)")
                }

                if let camp = day.campName, !camp.isEmpty {
                    LabeledContent("Camp Name", value: camp)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000
        return String(format: "%.1f km", km)
    }

    private func formatHours(_ hours: Double) -> String {
        let wholeHours = Int(hours)
        let minutes = Int((hours - Double(wholeHours)) * 60)

        if minutes > 0 {
            return "\(wholeHours)h \(minutes)m"
        } else {
            return "\(wholeHours) hours"
        }
    }
}

#Preview {
    let day = ItineraryDay(
        dayNumber: 5,
        date: Date(),
        startLocation: "Soraypampa",
        endLocation: "Salkantay Pass",
        activityType: .summit,
        clientDescription: "Summit day! Early start at 4am. Reach the pass by 10am.",
        guideNotes: "Check weather forecast. Have emergency shelter ready."
    )
    day.startElevationMeters = 3900
    day.endElevationMeters = 4630
    day.highPointMeters = 4630
    day.estimatedHours = 8
    day.distanceMeters = 12000
    day.startLatitude = -13.3695
    day.startLongitude = -72.5574
    day.endLatitude = -13.3347
    day.endLongitude = -72.5419

    return DayDetailView(day: day, elevationUnit: .meters)
        .modelContainer(for: Expedition.self, inMemory: true)
}
