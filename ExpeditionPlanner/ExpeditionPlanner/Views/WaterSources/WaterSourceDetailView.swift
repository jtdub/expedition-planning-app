import SwiftUI
import SwiftData

struct WaterSourceDetailView: View {
    @Environment(\.dismiss)
    private var dismiss

    let source: WaterSource
    let expedition: Expedition
    var viewModel: WaterSourceViewModel

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // Header
            Section {
                headerView
            }

            // Source Info
            Section {
                sourceInfoSection
            } header: {
                Text("Source Info")
            }

            // Location
            if hasLocationInfo {
                Section {
                    locationSection
                } header: {
                    Label("Location", systemImage: "mappin.and.ellipse")
                }
            }

            // Water Quality
            if hasQualityInfo {
                Section {
                    qualitySection
                } header: {
                    Label("Water Quality", systemImage: "drop.triangle")
                }
            }

            // Seasonal Notes
            if !source.seasonalNotes.isEmpty {
                Section {
                    Text(source.seasonalNotes)
                } header: {
                    Text("Seasonal Notes")
                }
            }

            // Notes
            if !source.notes.isEmpty {
                Section {
                    Text(source.notes)
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
                    Label("Delete Water Source", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Source Details")
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
                WaterSourceFormView(
                    mode: .edit(source),
                    expedition: expedition,
                    viewModel: viewModel
                )
            }
        }
        .alert("Delete Water Source?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteSource(source, from: expedition)
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
                Image(systemName: source.sourceType.icon)
                    .font(.title)
                    .foregroundStyle(colorForReliability)
            }
            .frame(width: 60, height: 60)
            .background(colorForReliability.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(source.sourceType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(colorForReliability.opacity(0.2))
                    .foregroundStyle(colorForReliability)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Source Info

    private var sourceInfoSection: some View {
        VStack(spacing: 8) {
            LabeledContent("Type") {
                Label(source.sourceType.rawValue, systemImage: source.sourceType.icon)
            }

            LabeledContent("Reliability") {
                HStack(spacing: 4) {
                    Image(systemName: source.reliability.icon)
                        .foregroundStyle(colorForReliability)
                    Text(source.reliability.rawValue)
                }
            }

            LabeledContent("Treatment Required") {
                Label(source.treatmentRequired.rawValue, systemImage: source.treatmentRequired.icon)
            }
        }
    }

    // MARK: - Location

    private var hasLocationInfo: Bool {
        source.hasCoordinates || source.elevation != nil || !source.distanceFromTrail.isEmpty
    }

    private var locationSection: some View {
        VStack(spacing: 8) {
            if source.hasCoordinates {
                LabeledContent("Coordinates") {
                    if let lat = source.latitude, let lon = source.longitude {
                        Text(String(format: "%.4f, %.4f", lat, lon))
                            .font(.caption)
                    }
                }
            }

            if let elevation = source.elevation {
                LabeledContent("Elevation") {
                    Text(formatElevation(elevation))
                }
            }

            if !source.distanceFromTrail.isEmpty {
                LabeledContent("Distance from Trail", value: source.distanceFromTrail)
            }
        }
    }

    // MARK: - Water Quality

    private var hasQualityInfo: Bool {
        !source.contaminationRisks.isEmpty || !source.flowRate.isEmpty
    }

    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !source.contaminationRisks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Contamination Risks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(source.contaminationRisks)
                        .foregroundStyle(.orange)
                }
            }

            if !source.flowRate.isEmpty {
                LabeledContent("Flow Rate", value: source.flowRate)
            }
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(spacing: 12) {
            Toggle("Verified", isOn: Binding(
                get: { source.isVerified },
                set: { newValue in
                    source.isVerified = newValue
                    if newValue { source.lastVerified = Date() }
                    viewModel.updateSource(source, in: expedition)
                }
            ))

            if let verifiedDate = source.lastVerified {
                LabeledContent("Last Verified") {
                    Text(verifiedDate.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
    }

    // MARK: - Helpers

    private var colorForReliability: Color {
        switch source.reliability.color {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        default: return .secondary
        }
    }

    private func formatElevation(_ elevation: Measurement<UnitLength>) -> String {
        let meters = elevation.converted(to: .meters)
        return String(format: "%.0f m", meters.value)
    }
}
