import SwiftUI
import SwiftData

enum EscapeRouteFormMode {
    case create
    case edit(EscapeRoute)
}

struct EscapeRouteFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: EscapeRouteFormMode
    let expedition: Expedition
    var viewModel: EscapeRouteViewModel

    // Form fields
    @State private var name: String = ""
    @State private var routeType: EscapeRouteType = .primary
    @State private var routeDescription: String = ""

    @State private var startDayText: String = ""
    @State private var endDayText: String = ""
    @State private var segmentName: String = ""

    @State private var distanceText: String = ""
    @State private var estimatedHoursText: String = ""
    @State private var elevationGainText: String = ""
    @State private var elevationLossText: String = ""
    @State private var difficultyRating: DifficultyRating = .moderate

    @State private var terrainDescription: String = ""
    @State private var hazards: String = ""
    @State private var requiredGear: String = ""
    @State private var seasonalNotes: String = ""

    @State private var destinationType: EscapeDestinationType = .trailhead
    @State private var destinationName: String = ""
    @State private var destLatText: String = ""
    @State private var destLonText: String = ""

    @State private var nearestMedicalFacility: String = ""
    @State private var medicalFacilityDistance: String = ""
    @State private var communicationNotes: String = ""

    @State private var isVerified: Bool = false
    @State private var notes: String = ""

    @State private var showingWaypointSheet = false
    @State private var editingWaypoint: EscapeWaypoint?

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var existingRoute: EscapeRoute? {
        if case .edit(let route) = mode {
            return route
        }
        return nil
    }

    var body: some View {
        Form {
            routeInfoSection
            segmentSection
            metricsSection
            terrainSection
            destinationSection
            medicalSection

            if isEditing, let route = existingRoute {
                waypointsSection(route: route)
            }

            statusSection
            notesSection
        }
        .navigationTitle(isEditing ? "Edit Escape Route" : "New Escape Route")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveRoute()
                }
                .disabled(name.isEmpty)
            }
        }
        .sheet(isPresented: $showingWaypointSheet) {
            NavigationStack {
                EscapeWaypointFormView(
                    mode: editingWaypoint.map { .edit($0) } ?? .create,
                    onSave: { waypoint in
                        if let route = existingRoute, editingWaypoint == nil {
                            waypoint.orderIndex = route.waypointCount
                            viewModel.addWaypoint(waypoint, to: route)
                        }
                        editingWaypoint = nil
                    }
                )
            }
        }
        .onAppear {
            loadExistingData()
        }
    }

    // MARK: - Sections

    private var routeInfoSection: some View {
        Section {
            TextField("Route Name", text: $name)

            Picker("Route Type", selection: $routeType) {
                ForEach(EscapeRouteType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }

            VStack(alignment: .leading) {
                Text("Description")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $routeDescription)
                    .frame(minHeight: 60)
            }
        } header: {
            Text("Route Info")
        }
    }

    private var segmentSection: some View {
        Section {
            TextField("Start Day", text: $startDayText)
                .keyboardType(.numberPad)

            TextField("End Day", text: $endDayText)
                .keyboardType(.numberPad)

            TextField("Segment Name", text: $segmentName)
        } header: {
            Text("Itinerary Segment")
        } footer: {
            Text("Link this escape route to specific days in your itinerary.")
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

            Picker("Difficulty", selection: $difficultyRating) {
                ForEach(DifficultyRating.allCases, id: \.self) { rating in
                    Text(rating.rawValue).tag(rating)
                }
            }
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
                Text("Required Gear")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $requiredGear)
                    .frame(minHeight: 60)
            }

            VStack(alignment: .leading) {
                Text("Seasonal Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $seasonalNotes)
                    .frame(minHeight: 40)
            }
        } header: {
            Text("Terrain & Conditions")
        }
    }

    private var destinationSection: some View {
        Section {
            Picker("Destination Type", selection: $destinationType) {
                ForEach(EscapeDestinationType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }

            TextField("Destination Name", text: $destinationName)

            TextField("Latitude", text: $destLatText)
                .keyboardType(.decimalPad)

            TextField("Longitude", text: $destLonText)
                .keyboardType(.decimalPad)
        } header: {
            Text("Destination")
        }
    }

    private var medicalSection: some View {
        Section {
            TextField("Nearest Medical Facility", text: $nearestMedicalFacility)
            TextField("Distance to Medical", text: $medicalFacilityDistance)

            VStack(alignment: .leading) {
                Text("Communication Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $communicationNotes)
                    .frame(minHeight: 60)
            }
        } header: {
            Text("Medical & Communication")
        }
    }

    private func waypointsSection(route: EscapeRoute) -> some View {
        Section {
            ForEach(route.sortedWaypoints) { waypoint in
                HStack {
                    Text("\(waypoint.orderIndex + 1).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    Text(waypoint.name)
                    Spacer()
                    if waypoint.hasCoordinates {
                        Image(systemName: "mappin.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    editingWaypoint = waypoint
                    showingWaypointSheet = true
                }
            }
            .onDelete { indexSet in
                deleteWaypoints(at: indexSet, from: route)
            }

            Button {
                editingWaypoint = nil
                showingWaypointSheet = true
            } label: {
                Label("Add Waypoint", systemImage: "plus.circle")
            }
        } header: {
            Text("Waypoints (\(route.waypointCount))")
        }
    }

    private var statusSection: some View {
        Section {
            Toggle("Verified", isOn: $isVerified)
        } header: {
            Text("Status")
        } footer: {
            Text("Mark as verified once the route has been confirmed.")
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
        guard let route = existingRoute else { return }

        name = route.name
        routeType = route.routeType
        routeDescription = route.routeDescription

        if let start = route.startDayNumber { startDayText = String(start) }
        if let end = route.endDayNumber { endDayText = String(end) }
        segmentName = route.segmentName

        if let dist = route.distanceMeters { distanceText = String(dist) }
        if let hours = route.estimatedHours { estimatedHoursText = String(hours) }
        if let gain = route.elevationGainMeters { elevationGainText = String(gain) }
        if let loss = route.elevationLossMeters { elevationLossText = String(loss) }
        difficultyRating = route.difficultyRating

        terrainDescription = route.terrainDescription
        hazards = route.hazards
        requiredGear = route.requiredGear
        seasonalNotes = route.seasonalNotes

        destinationType = route.destinationType
        destinationName = route.destinationName
        if let lat = route.destinationLatitude { destLatText = String(lat) }
        if let lon = route.destinationLongitude { destLonText = String(lon) }

        nearestMedicalFacility = route.nearestMedicalFacility
        medicalFacilityDistance = route.medicalFacilityDistance
        communicationNotes = route.communicationNotes

        isVerified = route.isVerified
        notes = route.notes
    }

    // MARK: - Save

    private func saveRoute() {
        if let existing = existingRoute {
            existing.name = name
            existing.routeType = routeType
            existing.routeDescription = routeDescription
            existing.startDayNumber = Int(startDayText)
            existing.endDayNumber = Int(endDayText)
            existing.segmentName = segmentName
            existing.distanceMeters = Double(distanceText)
            existing.estimatedHours = Double(estimatedHoursText)
            existing.elevationGainMeters = Double(elevationGainText)
            existing.elevationLossMeters = Double(elevationLossText)
            existing.difficultyRating = difficultyRating
            existing.terrainDescription = terrainDescription
            existing.hazards = hazards
            existing.requiredGear = requiredGear
            existing.seasonalNotes = seasonalNotes
            existing.destinationType = destinationType
            existing.destinationName = destinationName
            existing.destinationLatitude = Double(destLatText)
            existing.destinationLongitude = Double(destLonText)
            existing.nearestMedicalFacility = nearestMedicalFacility
            existing.medicalFacilityDistance = medicalFacilityDistance
            existing.communicationNotes = communicationNotes
            existing.isVerified = isVerified
            if isVerified { existing.lastVerifiedDate = Date() }
            existing.notes = notes

            viewModel.updateRoute(existing, in: expedition)
        } else {
            let route = EscapeRoute(name: name, routeType: routeType, segmentName: segmentName)
            route.routeDescription = routeDescription
            route.startDayNumber = Int(startDayText)
            route.endDayNumber = Int(endDayText)
            route.distanceMeters = Double(distanceText)
            route.estimatedHours = Double(estimatedHoursText)
            route.elevationGainMeters = Double(elevationGainText)
            route.elevationLossMeters = Double(elevationLossText)
            route.difficultyRating = difficultyRating
            route.terrainDescription = terrainDescription
            route.hazards = hazards
            route.requiredGear = requiredGear
            route.seasonalNotes = seasonalNotes
            route.destinationType = destinationType
            route.destinationName = destinationName
            route.destinationLatitude = Double(destLatText)
            route.destinationLongitude = Double(destLonText)
            route.nearestMedicalFacility = nearestMedicalFacility
            route.medicalFacilityDistance = medicalFacilityDistance
            route.communicationNotes = communicationNotes
            route.isVerified = isVerified
            if isVerified { route.lastVerifiedDate = Date() }
            route.notes = notes

            viewModel.addRoute(route, to: expedition)
        }

        dismiss()
    }

    // MARK: - Helpers

    private func deleteWaypoints(at indexSet: IndexSet, from route: EscapeRoute) {
        let sorted = route.sortedWaypoints
        for index in indexSet {
            viewModel.deleteWaypoint(sorted[index], from: route)
        }
    }
}
