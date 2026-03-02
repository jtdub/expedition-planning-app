import SwiftUI

enum EscapeWaypointFormMode {
    case create
    case edit(EscapeWaypoint)
}

struct EscapeWaypointFormView: View {
    @Environment(\.dismiss)
    private var dismiss

    let mode: EscapeWaypointFormMode
    let onSave: (EscapeWaypoint) -> Void

    @State private var name: String = ""
    @State private var latitudeText: String = ""
    @State private var longitudeText: String = ""
    @State private var elevationText: String = ""
    @State private var waypointDescription: String = ""
    @State private var hazards: String = ""
    @State private var notes: String = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var existingWaypoint: EscapeWaypoint? {
        if case .edit(let waypoint) = mode {
            return waypoint
        }
        return nil
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)

                TextField("Latitude", text: $latitudeText)
                    .keyboardType(.decimalPad)

                TextField("Longitude", text: $longitudeText)
                    .keyboardType(.decimalPad)

                TextField("Elevation (meters)", text: $elevationText)
                    .keyboardType(.decimalPad)
            } header: {
                Text("Waypoint Info")
            }

            Section {
                VStack(alignment: .leading) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $waypointDescription)
                        .frame(minHeight: 60)
                }

                VStack(alignment: .leading) {
                    Text("Hazards")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $hazards)
                        .frame(minHeight: 60)
                }
            } header: {
                Text("Details")
            }

            Section {
                VStack(alignment: .leading) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $notes)
                        .frame(minHeight: 40)
                }
            } header: {
                Text("Notes")
            }
        }
        .navigationTitle(isEditing ? "Edit Waypoint" : "New Waypoint")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") {
                    saveWaypoint()
                }
                .disabled(name.isEmpty)
            }
        }
        .onAppear {
            loadExistingData()
        }
    }

    private func loadExistingData() {
        guard let waypoint = existingWaypoint else { return }

        name = waypoint.name
        if let lat = waypoint.latitude {
            latitudeText = String(lat)
        }
        if let lon = waypoint.longitude {
            longitudeText = String(lon)
        }
        if let elev = waypoint.elevationMeters {
            elevationText = String(elev)
        }
        waypointDescription = waypoint.waypointDescription
        hazards = waypoint.hazards
        notes = waypoint.notes
    }

    private func saveWaypoint() {
        if let existing = existingWaypoint {
            existing.name = name
            existing.latitude = Double(latitudeText)
            existing.longitude = Double(longitudeText)
            existing.elevationMeters = Double(elevationText)
            existing.waypointDescription = waypointDescription
            existing.hazards = hazards
            existing.notes = notes
            onSave(existing)
        } else {
            let waypoint = EscapeWaypoint(name: name)
            waypoint.latitude = Double(latitudeText)
            waypoint.longitude = Double(longitudeText)
            waypoint.elevationMeters = Double(elevationText)
            waypoint.waypointDescription = waypointDescription
            waypoint.hazards = hazards
            waypoint.notes = notes
            onSave(waypoint)
        }

        dismiss()
    }
}
