import SwiftUI
import MapKit

struct WaypointDetailSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    let waypoint: RouteWaypoint
    let elevationUnit: ElevationUnit

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    headerSection

                    // Info Card
                    infoCard

                    // Map Preview
                    mapPreview

                    // Coordinates Card
                    coordinatesCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Waypoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(waypoint.type.color.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: waypoint.type.icon)
                    .font(.title)
                    .foregroundStyle(waypoint.type.color)
            }

            Text(waypoint.name)
                .font(.title2)
                .fontWeight(.semibold)

            Text(waypoint.type.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .background(waypoint.type.color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Info Card

    private var infoCard: some View {
        GroupBox("Details") {
            VStack(spacing: 12) {
                if let dayNumber = waypoint.dayNumber {
                    LabeledContent("Day", value: "Day \(dayNumber)")
                }

                if let date = waypoint.date {
                    LabeledContent("Date") {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                    }
                }

                if let elevation = waypoint.elevationMeters {
                    LabeledContent("Elevation") {
                        Text(ElevationService.formatElevation(elevation, unit: elevationUnit))
                    }
                }

                if let notes = waypoint.notes, !notes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(notes)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Map Preview

    private var mapPreview: some View {
        GroupBox("Location") {
            Map {
                Marker(waypoint.name, coordinate: waypoint.coordinate)
                    .tint(waypoint.type.color)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Coordinates Card

    private var coordinatesCard: some View {
        GroupBox("Coordinates") {
            VStack(spacing: 8) {
                LabeledContent("Latitude") {
                    Text(formatCoordinate(waypoint.coordinate.latitude, isLatitude: true))
                        .font(.system(.body, design: .monospaced))
                }

                LabeledContent("Longitude") {
                    Text(formatCoordinate(waypoint.coordinate.longitude, isLatitude: false))
                        .font(.system(.body, design: .monospaced))
                }

                Divider()

                Button {
                    openInMaps()
                } label: {
                    Label("Open in Maps", systemImage: "map")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Helpers

    private func formatCoordinate(_ value: Double, isLatitude: Bool) -> String {
        let direction: String
        if isLatitude {
            direction = value >= 0 ? "N" : "S"
        } else {
            direction = value >= 0 ? "E" : "W"
        }

        let absValue = abs(value)
        let degrees = Int(absValue)
        let minutes = Int((absValue - Double(degrees)) * 60)
        let seconds = ((absValue - Double(degrees)) * 60 - Double(minutes)) * 60

        return String(format: "%d° %d' %.1f\" %@", degrees, minutes, seconds, direction)
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: waypoint.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = waypoint.name
        mapItem.openInMaps(launchOptions: nil)
    }
}

#Preview {
    WaypointDetailSheet(
        waypoint: RouteWaypoint(
            coordinate: CLLocationCoordinate2D(latitude: 68.1234, longitude: -149.5678),
            name: "Arctic Camp",
            type: .campsite,
            elevationMeters: 1250,
            dayNumber: 5,
            date: Date(),
            notes: "Good water source nearby. Protected from wind.",
            sourceId: UUID()
        ),
        elevationUnit: .meters
    )
}
