import SwiftUI
import SwiftData

enum RouteSegmentFormMode {
    case create
    case edit(RouteSegment)
}

struct RouteSegmentFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: RouteSegmentFormMode
    let expedition: Expedition
    var viewModel: RouteSegmentViewModel

    // Form fields
    @State private var name: String = ""
    @State private var terrainType: TerrainType = .tundra
    @State private var difficultyRating: DifficultyRating = .moderate

    @State private var startDayText: String = ""
    @State private var endDayText: String = ""

    @State private var distanceText: String = ""
    @State private var estimatedHoursText: String = ""
    @State private var elevationGainText: String = ""
    @State private var elevationLossText: String = ""

    @State private var terrainDescription: String = ""
    @State private var hazards: String = ""
    @State private var navigationNotes: String = ""

    @State private var waterNotes: String = ""
    @State private var campingNotes: String = ""

    @State private var seasonalNotes: String = ""
    @State private var notes: String = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var existingSegment: RouteSegment? {
        if case .edit(let segment) = mode {
            return segment
        }
        return nil
    }

    var body: some View {
        Form {
            segmentInfoSection
            dayRangeSection
            metricsSection
            terrainSection
            waterCampingSection
            seasonalNotesSection
            notesSection
        }
        .navigationTitle(isEditing ? "Edit Route Segment" : "New Route Segment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveSegment()
                }
                .disabled(name.isEmpty)
            }
        }
        .onAppear {
            loadExistingData()
        }
    }

    // MARK: - Sections

    private var segmentInfoSection: some View {
        Section {
            TextField("Segment Name", text: $name)

            Picker("Terrain Type", selection: $terrainType) {
                ForEach(TerrainType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }

            Picker("Difficulty", selection: $difficultyRating) {
                ForEach(DifficultyRating.allCases, id: \.self) { rating in
                    Text(rating.rawValue).tag(rating)
                }
            }
        } header: {
            Text("Segment Info")
        }
    }

    private var dayRangeSection: some View {
        Section {
            TextField("Start Day", text: $startDayText)
                .keyboardType(.numberPad)

            TextField("End Day", text: $endDayText)
                .keyboardType(.numberPad)
        } header: {
            Text("Day Range")
        } footer: {
            Text("Link this segment to specific days in your itinerary.")
        }
    }

    private var metricsSection: some View {
        Section {
            TextField("Distance (meters)", text: $distanceText)
                .keyboardType(.decimalPad)

            TextField("Estimated Hours", text: $estimatedHoursText)
                .keyboardType(.decimalPad)

            TextField("Elevation Gain (meters)", text: $elevationGainText)
                .keyboardType(.decimalPad)

            TextField("Elevation Loss (meters)", text: $elevationLossText)
                .keyboardType(.decimalPad)
        } header: {
            Text("Route Metrics")
        }
    }

    private var terrainSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Terrain Description")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $terrainDescription)
                    .frame(minHeight: 60)
            }

            VStack(alignment: .leading) {
                Text("Hazards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $hazards)
                    .frame(minHeight: 60)
            }

            VStack(alignment: .leading) {
                Text("Navigation Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $navigationNotes)
                    .frame(minHeight: 60)
            }
        } header: {
            Text("Terrain & Navigation")
        }
    }

    private var waterCampingSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Water Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $waterNotes)
                    .frame(minHeight: 60)
            }

            VStack(alignment: .leading) {
                Text("Camping Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $campingNotes)
                    .frame(minHeight: 60)
            }
        } header: {
            Text("Water & Camping")
        }
    }

    private var seasonalNotesSection: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Seasonal Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $seasonalNotes)
                    .frame(minHeight: 40)
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

    // MARK: - Data Loading

    private func loadExistingData() {
        guard let segment = existingSegment else { return }

        name = segment.name
        terrainType = segment.terrainType
        difficultyRating = segment.difficultyRating

        if let start = segment.startDayNumber { startDayText = String(start) }
        if let end = segment.endDayNumber { endDayText = String(end) }

        if let dist = segment.distanceMeters { distanceText = String(dist) }
        if let hours = segment.estimatedHours { estimatedHoursText = String(hours) }
        if let gain = segment.elevationGainMeters { elevationGainText = String(gain) }
        if let loss = segment.elevationLossMeters { elevationLossText = String(loss) }

        terrainDescription = segment.terrainDescription
        hazards = segment.hazards
        navigationNotes = segment.navigationNotes

        waterNotes = segment.waterNotes
        campingNotes = segment.campingNotes

        seasonalNotes = segment.seasonalNotes
        notes = segment.notes
    }

    // MARK: - Save

    private func saveSegment() {
        if let existing = existingSegment {
            existing.name = name
            existing.terrainType = terrainType
            existing.difficultyRating = difficultyRating
            existing.startDayNumber = Int(startDayText)
            existing.endDayNumber = Int(endDayText)
            existing.distanceMeters = Double(distanceText)
            existing.estimatedHours = Double(estimatedHoursText)
            existing.elevationGainMeters = Double(elevationGainText)
            existing.elevationLossMeters = Double(elevationLossText)
            existing.terrainDescription = terrainDescription
            existing.hazards = hazards
            existing.navigationNotes = navigationNotes
            existing.waterNotes = waterNotes
            existing.campingNotes = campingNotes
            existing.seasonalNotes = seasonalNotes
            existing.notes = notes

            viewModel.updateSegment(existing, in: expedition)
        } else {
            let segment = RouteSegment(name: name, terrainType: terrainType, difficultyRating: difficultyRating)
            segment.startDayNumber = Int(startDayText)
            segment.endDayNumber = Int(endDayText)
            segment.distanceMeters = Double(distanceText)
            segment.estimatedHours = Double(estimatedHoursText)
            segment.elevationGainMeters = Double(elevationGainText)
            segment.elevationLossMeters = Double(elevationLossText)
            segment.terrainDescription = terrainDescription
            segment.hazards = hazards
            segment.navigationNotes = navigationNotes
            segment.waterNotes = waterNotes
            segment.campingNotes = campingNotes
            segment.seasonalNotes = seasonalNotes
            segment.notes = notes

            viewModel.addSegment(segment, to: expedition)
        }

        dismiss()
    }
}
