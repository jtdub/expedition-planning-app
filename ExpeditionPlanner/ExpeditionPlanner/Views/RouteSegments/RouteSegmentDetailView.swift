import SwiftUI
import SwiftData

struct RouteSegmentDetailView: View {
    @Environment(\.dismiss)
    private var dismiss

    let segment: RouteSegment
    let expedition: Expedition
    var viewModel: RouteSegmentViewModel

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

            // Terrain & Navigation
            if hasTerrainInfo {
                Section {
                    terrainSection
                } header: {
                    Label("Terrain & Navigation", systemImage: "mountain.2")
                }
            }

            // Water & Camping
            if hasWaterCampingInfo {
                Section {
                    waterCampingSection
                } header: {
                    Label("Water & Camping", systemImage: "drop")
                }
            }

            // Seasonal Notes
            if !segment.seasonalNotes.isEmpty {
                Section {
                    Text(segment.seasonalNotes)
                } header: {
                    Text("Seasonal Notes")
                }
            }

            // Notes
            if !segment.notes.isEmpty {
                Section {
                    Text(segment.notes)
                } header: {
                    Text("Notes")
                }
            }

            // Actions
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Route Segment", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Segment Details")
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
                RouteSegmentFormView(
                    mode: .edit(segment),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete Route Segment?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteSegment(segment, from: expedition)
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
                Image(systemName: segment.terrainType.icon)
                    .font(.title)
                    .foregroundStyle(colorForTerrain)
            }
            .frame(width: 60, height: 60)
            .background(colorForTerrain.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(segment.name)
                    .font(.title2)
                    .fontWeight(.bold)

                if let dayRange = segment.dayRangeDescription {
                    Text(dayRange)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(segment.terrainType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(colorForTerrain.opacity(0.2))
                    .foregroundStyle(colorForTerrain)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Metrics

    private var metricsSection: some View {
        VStack(spacing: 8) {
            if let distance = segment.distance {
                LabeledContent("Distance") {
                    Text(formatDistance(distance))
                }
            }

            if let time = segment.formattedEstimatedTime {
                LabeledContent("Estimated Time", value: time)
            }

            if let gain = segment.elevationGain {
                LabeledContent("Elevation Gain") {
                    Text(formatElevation(gain))
                }
            }

            if let loss = segment.elevationLoss {
                LabeledContent("Elevation Loss") {
                    Text(formatElevation(loss))
                }
            }

            LabeledContent("Difficulty") {
                HStack(spacing: 4) {
                    Image(systemName: segment.difficultyRating.icon)
                        .foregroundStyle(colorForDifficulty)
                    Text(segment.difficultyRating.rawValue)
                }
            }
        }
    }

    // MARK: - Terrain & Navigation

    private var hasTerrainInfo: Bool {
        !segment.terrainDescription.isEmpty || !segment.hazards.isEmpty || !segment.navigationNotes.isEmpty
    }

    private var terrainSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !segment.terrainDescription.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Terrain")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(segment.terrainDescription)
                }
            }

            if !segment.hazards.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hazards")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(segment.hazards)
                        .foregroundStyle(.orange)
                }
            }

            if !segment.navigationNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Navigation Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(segment.navigationNotes)
                }
            }
        }
    }

    // MARK: - Water & Camping

    private var hasWaterCampingInfo: Bool {
        !segment.waterNotes.isEmpty || !segment.campingNotes.isEmpty
    }

    private var waterCampingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !segment.waterNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Water Sources")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(segment.waterNotes)
                }
            }

            if !segment.campingNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Camping")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(segment.campingNotes)
                }
            }
        }
    }

    // MARK: - Helpers

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

    private var colorForDifficulty: Color {
        switch segment.difficultyRating.color {
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
