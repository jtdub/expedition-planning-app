import SwiftUI
import SwiftData

enum WaterSourceFormMode {
    case create
    case edit(WaterSource)
}

struct WaterSourceFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: WaterSourceFormMode
    let expedition: Expedition
    var viewModel: WaterSourceViewModel

    // Form fields
    @State private var name: String = ""
    @State private var sourceType: WaterSourceType = .stream
    @State private var reliability: ReliabilityRating = .seasonal
    @State private var treatmentRequired: TreatmentMethod = .filter

    @State private var latitudeText: String = ""
    @State private var longitudeText: String = ""
    @State private var elevationText: String = ""
    @State private var distanceFromTrail: String = ""

    @State private var contaminationRisks: String = ""
    @State private var flowRate: String = ""

    @State private var seasonalNotes: String = ""
    @State private var notes: String = ""
    @State private var isVerified: Bool = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var existingSource: WaterSource? {
        if case .edit(let source) = mode {
            return source
        }
        return nil
    }

    var body: some View {
        Form {
            sourceInfoSection
            locationSection
            qualitySection
            seasonalNotesSection
            notesSection
            statusSection
        }
        .navigationTitle(isEditing ? "Edit Water Source" : "New Water Source")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveSource()
                }
                .disabled(name.isEmpty)
            }
        }
        .onAppear {
            loadExistingData()
        }
    }

    // MARK: - Sections

    private var sourceInfoSection: some View {
        Section {
            TextField("Source Name", text: $name)

            Picker("Source Type", selection: $sourceType) {
                ForEach(WaterSourceType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }

            Picker("Reliability", selection: $reliability) {
                ForEach(ReliabilityRating.allCases, id: \.self) { rating in
                    Label(rating.rawValue, systemImage: rating.icon)
                        .tag(rating)
                }
            }

            Picker("Treatment Required", selection: $treatmentRequired) {
                ForEach(TreatmentMethod.allCases, id: \.self) { method in
                    Label(method.rawValue, systemImage: method.icon)
                        .tag(method)
                }
            }
        } header: {
            Text("Source Info")
        }
    }

    private var locationSection: some View {
        Section {
            TextField("Latitude", text: $latitudeText)
                .keyboardType(.decimalPad)

            TextField("Longitude", text: $longitudeText)
                .keyboardType(.decimalPad)

            TextField("Elevation (meters)", text: $elevationText)
                .keyboardType(.decimalPad)

            TextField("Distance from Trail", text: $distanceFromTrail)
        } header: {
            Text("Location")
        }
    }

    private var qualitySection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Contamination Risks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $contaminationRisks)
                    .frame(minHeight: 60)
            }

            TextField("Flow Rate", text: $flowRate)
        } header: {
            Text("Water Quality")
        }
    }

    private var seasonalNotesSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Seasonal Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $seasonalNotes)
                    .frame(minHeight: 60)
            }
        } header: {
            Text("Seasonal Notes")
        }
    }

    private var notesSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $notes)
                    .frame(minHeight: 60)
            }
        } header: {
            Text("Notes")
        }
    }

    private var statusSection: some View {
        Section {
            Toggle("Verified", isOn: $isVerified)
        } header: {
            Text("Status")
        } footer: {
            Text("Mark as verified once the water source has been confirmed.")
        }
    }

    // MARK: - Data Loading

    private func loadExistingData() {
        guard let source = existingSource else { return }

        name = source.name
        sourceType = source.sourceType
        reliability = source.reliability
        treatmentRequired = source.treatmentRequired

        if let lat = source.latitude { latitudeText = String(lat) }
        if let lon = source.longitude { longitudeText = String(lon) }
        if let elev = source.elevationMeters { elevationText = String(elev) }
        distanceFromTrail = source.distanceFromTrail

        contaminationRisks = source.contaminationRisks
        flowRate = source.flowRate

        seasonalNotes = source.seasonalNotes
        notes = source.notes
        isVerified = source.isVerified
    }

    // MARK: - Save

    private func saveSource() {
        if let existing = existingSource {
            existing.name = name
            existing.sourceType = sourceType
            existing.reliability = reliability
            existing.treatmentRequired = treatmentRequired
            existing.latitude = Double(latitudeText)
            existing.longitude = Double(longitudeText)
            existing.elevationMeters = Double(elevationText)
            existing.distanceFromTrail = distanceFromTrail
            existing.contaminationRisks = contaminationRisks
            existing.flowRate = flowRate
            existing.seasonalNotes = seasonalNotes
            existing.notes = notes
            existing.isVerified = isVerified
            if isVerified { existing.lastVerified = Date() }

            viewModel.updateSource(existing, in: expedition)
        } else {
            let source = WaterSource(name: name, sourceType: sourceType, reliability: reliability)
            source.treatmentRequired = treatmentRequired
            source.latitude = Double(latitudeText)
            source.longitude = Double(longitudeText)
            source.elevationMeters = Double(elevationText)
            source.distanceFromTrail = distanceFromTrail
            source.contaminationRisks = contaminationRisks
            source.flowRate = flowRate
            source.seasonalNotes = seasonalNotes
            source.notes = notes
            source.isVerified = isVerified
            if isVerified { source.lastVerified = Date() }

            viewModel.addSource(source, to: expedition)
        }

        dismiss()
    }
}
