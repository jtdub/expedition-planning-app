import SwiftUI
import SwiftData

struct EscapeRouteDetailView: View {
    @Environment(\.dismiss)
    private var dismiss

    let route: EscapeRoute
    let expedition: Expedition
    var viewModel: EscapeRouteViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // Header
            Section {
                headerView
            }

            // Route Metrics
            Section {
                metricsSection
            } header: {
                Text("Route Metrics")
            }

            // Terrain & Conditions
            if hasTerrainInfo {
                Section {
                    terrainSection
                } header: {
                    Label("Terrain & Conditions", systemImage: "mountain.2")
                }
            }

            // Destination
            Section {
                destinationSection
            } header: {
                Label("Destination", systemImage: route.destinationType.icon)
            }

            // Waypoints
            if route.waypointCount > 0 {
                Section {
                    waypointsSection
                } header: {
                    Text("Waypoints (\(route.waypointCount))")
                }
            }

            // Medical & Communication
            if hasMedicalInfo {
                Section {
                    medicalSection
                } header: {
                    Label("Medical & Communication", systemImage: "cross.case")
                }
            }

            // Seasonal Notes
            if !route.seasonalNotes.isEmpty {
                Section {
                    Text(route.seasonalNotes)
                } header: {
                    Text("Seasonal Notes")
                }
            }

            // Description
            if !route.routeDescription.isEmpty {
                Section {
                    Text(route.routeDescription)
                } header: {
                    Text("Description")
                }
            }

            // Notes
            if !route.notes.isEmpty {
                Section {
                    Text(route.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Status
            Section {
                statusSection
            } header: {
                Text("Status")
            }

            // Actions
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Escape Route", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Route Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                EscapeRouteFormView(
                    mode: .edit(route),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete Escape Route?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteRoute(route, from: expedition)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 16) {
            VStack {
                Image(systemName: route.routeType.icon)
                    .font(.title)
                    .foregroundStyle(colorForType)
            }
            .frame(width: 60, height: 60)
            .background(colorForType.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(route.name)
                    .font(.title2)
                    .fontWeight(.bold)

                if let dayRange = route.dayRangeDescription {
                    Text(dayRange)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(route.routeType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(colorForType.opacity(0.2))
                    .foregroundStyle(colorForType)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Metrics

    private var metricsSection: some View {
        VStack(spacing: 8) {
            if let distance = route.distance {
                LabeledContent("Distance") {
                    Text(formatDistance(distance))
                }
            }

            if let time = route.formattedEstimatedTime {
                LabeledContent("Estimated Time", value: time)
            }

            if let gain = route.elevationGain {
                LabeledContent("Elevation Gain") {
                    Text(formatElevation(gain))
                }
            }

            if let loss = route.elevationLoss {
                LabeledContent("Elevation Loss") {
                    Text(formatElevation(loss))
                }
            }

            LabeledContent("Difficulty") {
                HStack(spacing: 4) {
                    Image(systemName: route.difficultyRating.icon)
                        .foregroundStyle(colorForDifficulty)
                    Text(route.difficultyRating.rawValue)
                }
            }
        }
    }

    // MARK: - Terrain

    private var hasTerrainInfo: Bool {
        !route.terrainDescription.isEmpty || !route.hazards.isEmpty || !route.requiredGear.isEmpty
    }

    private var terrainSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !route.terrainDescription.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Terrain")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(route.terrainDescription)
                }
            }

            if !route.hazards.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hazards")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(route.hazards)
                        .foregroundStyle(.orange)
                }
            }

            if !route.requiredGear.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Required Gear")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(route.requiredGear)
                }
            }
        }
    }

    // MARK: - Destination

    private var destinationSection: some View {
        VStack(spacing: 8) {
            LabeledContent("Type") {
                Label(route.destinationType.rawValue, systemImage: route.destinationType.icon)
            }

            if !route.destinationName.isEmpty {
                LabeledContent("Name", value: route.destinationName)
            }

            if route.hasCoordinates {
                LabeledContent("Coordinates") {
                    if let lat = route.destinationLatitude, let lon = route.destinationLongitude {
                        Text(String(format: "%.4f, %.4f", lat, lon))
                            .font(.caption)
                    }
                }
            }
        }
    }

    // MARK: - Waypoints

    private var waypointsSection: some View {
        ForEach(route.sortedWaypoints) { waypoint in
            HStack(spacing: 12) {
                Text("\(waypoint.orderIndex + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 24, height: 24)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(waypoint.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if !waypoint.waypointDescription.isEmpty {
                        Text(waypoint.waypointDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                if let elevation = waypoint.elevation {
                    Text(formatElevation(elevation))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Medical

    private var hasMedicalInfo: Bool {
        !route.nearestMedicalFacility.isEmpty ||
        !route.medicalFacilityDistance.isEmpty ||
        !route.communicationNotes.isEmpty
    }

    private var medicalSection: some View {
        VStack(spacing: 8) {
            if !route.nearestMedicalFacility.isEmpty {
                LabeledContent("Nearest Facility", value: route.nearestMedicalFacility)
            }

            if !route.medicalFacilityDistance.isEmpty {
                LabeledContent("Distance", value: route.medicalFacilityDistance)
            }

            if !route.communicationNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Communication")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(route.communicationNotes)
                }
            }
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(spacing: 12) {
            Toggle("Verified", isOn: Binding(
                get: { route.isVerified },
                set: { newValue in
                    route.isVerified = newValue
                    if newValue { route.lastVerifiedDate = Date() }
                    viewModel.updateRoute(route, in: expedition)
                }
            ))

            if let verifiedDate = route.lastVerifiedDate {
                LabeledContent("Last Verified") {
                    Text(verifiedDate.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
    }

    // MARK: - Helpers

    private var colorForType: Color {
        switch route.routeType.color {
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .secondary
        }
    }

    private var colorForDifficulty: Color {
        switch route.difficultyRating.color {
        case "green": return .green
        case "blue": return .blue
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

    private func formatElevation(_ elevation: Measurement<UnitLength>) -> String {
        let meters = elevation.converted(to: .meters)
        return String(format: "%.0f m", meters.value)
    }
}
