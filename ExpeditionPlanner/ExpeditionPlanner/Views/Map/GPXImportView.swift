import SwiftUI
import UniformTypeIdentifiers
import CoreLocation

struct GPXImportView: View {
    @Environment(\.dismiss)
    private var dismiss

    let onImport: ([RouteWaypoint]) -> Void

    @State private var showingFilePicker = false
    @State private var parseResult: GPXService.GPXParseResult?
    @State private var errorMessage: String?
    @State private var selectedWaypoints: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Group {
                if let result = parseResult {
                    resultView(result: result)
                } else {
                    pickFileView
                }
            }
            .navigationTitle("Import GPX")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if parseResult != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import") {
                            importSelected()
                        }
                        .disabled(selectedWaypoints.isEmpty)
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType(filenameExtension: "gpx") ?? .xml],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
        }
    }

    // MARK: - Pick File View

    private var pickFileView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.badge.arrow.up")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Import GPX File")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Select a GPX file to import waypoints and track data into your expedition.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showingFilePicker = true
            } label: {
                Label("Choose File", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 48)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding()
    }

    // MARK: - Result View

    @ViewBuilder
    private func resultView(result: GPXService.GPXParseResult) -> some View {
        List {
            // Summary Section
            Section("File Summary") {
                if let name = result.name {
                    LabeledContent("Name", value: name)
                }

                LabeledContent("Waypoints", value: "\(result.waypoints.count)")
                LabeledContent("Track Points", value: "\(result.trackPoints.count)")
            }

            // Waypoints Section
            if !result.waypoints.isEmpty {
                Section {
                    ForEach(result.waypoints) { waypoint in
                        waypointRow(waypoint: waypoint)
                    }
                } header: {
                    HStack {
                        Text("Waypoints")
                        Spacer()
                        Button(selectedWaypoints.count == result.waypoints.count ? "Deselect All" : "Select All") {
                            if selectedWaypoints.count == result.waypoints.count {
                                selectedWaypoints.removeAll()
                            } else {
                                selectedWaypoints = Set(result.waypoints.map { $0.id })
                            }
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .onAppear {
            // Select all waypoints by default
            selectedWaypoints = Set(result.waypoints.map { $0.id })
        }
    }

    private func waypointRow(waypoint: RouteWaypoint) -> some View {
        Button {
            toggleSelection(waypoint.id)
        } label: {
            HStack {
                // Selection indicator
                Image(systemName: selectedWaypoints.contains(waypoint.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedWaypoints.contains(waypoint.id) ? .blue : .secondary)

                // Type icon
                Image(systemName: waypoint.type.icon)
                    .foregroundStyle(waypoint.type.color)
                    .frame(width: 24)

                // Name and coordinates
                VStack(alignment: .leading, spacing: 2) {
                    Text(waypoint.name)
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text(formatCoordinate(waypoint.coordinate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Elevation if available
                if let elevation = waypoint.elevationMeters {
                    Text("\(Int(elevation))m")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                errorMessage = "No file selected"
                return
            }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access file"
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            if let parsed = GPXService.parse(url: url) {
                parseResult = parsed
                errorMessage = nil
            } else {
                errorMessage = "Failed to parse GPX file. Please check the file format."
            }

        case .failure(let error):
            errorMessage = "Error selecting file: \(error.localizedDescription)"
        }
    }

    private func toggleSelection(_ id: UUID) {
        if selectedWaypoints.contains(id) {
            selectedWaypoints.remove(id)
        } else {
            selectedWaypoints.insert(id)
        }
    }

    private func importSelected() {
        guard let result = parseResult else { return }

        let waypointsToImport = result.waypoints.filter { selectedWaypoints.contains($0.id) }
        onImport(waypointsToImport)
        dismiss()
    }

    // MARK: - Helpers

    private func formatCoordinate(_ coord: CLLocationCoordinate2D) -> String {
        String(format: "%.4f, %.4f", coord.latitude, coord.longitude)
    }
}

#Preview {
    GPXImportView { _ in
        // Preview action
    }
}
