import SwiftUI
import UIKit
import MapKit

// MARK: - GPX Export View

struct GPXExportView: View {
    @Environment(\.dismiss)
    private var dismiss

    let waypoints: [RouteWaypoint]
    let routeCoordinates: [CLLocationCoordinate2D]
    let expeditionName: String

    @State private var includeTrack = true
    @State private var includeWaypoints = true
    @State private var isExporting = false
    @State private var exportedURL: URL?
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Export Options") {
                    Toggle("Include Waypoints", isOn: $includeWaypoints)
                    Toggle("Include Track", isOn: $includeTrack)
                }

                Section("Summary") {
                    LabeledContent("Waypoints", value: "\(waypoints.count)")
                    LabeledContent("Track Points", value: "\(routeCoordinates.count)")
                }

                Section {
                    Button {
                        exportGPX()
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                            } else {
                                Label("Export GPX File", systemImage: "square.and.arrow.up")
                            }
                            Spacer()
                        }
                    }
                    .disabled(!includeWaypoints && !includeTrack)
                }
            }
            .navigationTitle("Export GPX")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func exportGPX() {
        isExporting = true

        let waypointsToExport = includeWaypoints ? waypoints : []
        let trackToExport = includeTrack ? routeCoordinates : []

        let gpxString = GPXService.export(
            waypoints: waypointsToExport,
            trackCoordinates: trackToExport,
            name: expeditionName
        )

        // Save to temp file
        let fileName = "\(expeditionName.replacingOccurrences(of: " ", with: "_")).gpx"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try gpxString.write(to: tempURL, atomically: true, encoding: .utf8)
            exportedURL = tempURL
            showingShareSheet = true
        } catch {
            // Handle error silently for now
        }

        isExporting = false
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Tracking Control Sheet

struct TrackingControlSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    @Bindable var viewModel: RouteMapViewModel

    var body: some View {
        NavigationStack {
            Form {
                // Status Section
                Section("Location Status") {
                    LabeledContent("Authorization") {
                        Text(viewModel.locationManager.authorizationStatusDescription)
                            .foregroundStyle(viewModel.locationManager.isAuthorized ? .green : .secondary)
                    }

                    if viewModel.locationManager.isDenied {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }

                // Current Location Section
                if let location = viewModel.locationManager.currentLocation {
                    Section("Current Location") {
                        LabeledContent("Latitude") {
                            Text(String(format: "%.6f", location.coordinate.latitude))
                                .font(.system(.body, design: .monospaced))
                        }

                        LabeledContent("Longitude") {
                            Text(String(format: "%.6f", location.coordinate.longitude))
                                .font(.system(.body, design: .monospaced))
                        }

                        LabeledContent("Altitude") {
                            Text(String(format: "%.0f m", location.altitude))
                        }

                        LabeledContent("Accuracy") {
                            Text(String(format: "%.0f m", location.horizontalAccuracy))
                        }

                        if let nextWaypoint = viewModel.distanceToNextWaypoint() {
                            LabeledContent("Next Waypoint") {
                                Text(nextWaypoint)
                            }
                        }
                    }
                }

                // Tracking Section
                Section("Expedition Tracking") {
                    if viewModel.isTrackingExpedition {
                        LabeledContent("Track Points") {
                            Text("\(viewModel.userTrackCoordinates.count)")
                        }

                        LabeledContent("Distance Traveled") {
                            Text(viewModel.formattedDistanceTraveled)
                        }

                        Button(role: .destructive) {
                            viewModel.stopTracking()
                            dismiss()
                        } label: {
                            Label("Stop Tracking", systemImage: "stop.fill")
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        Text("Track your expedition progress and record your route as you travel.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            viewModel.startTracking()
                            dismiss()
                        } label: {
                            Label("Start Tracking", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(!viewModel.locationManager.isAuthorized)
                    }
                }

                // Follow Location Toggle
                Section {
                    Toggle("Follow My Location", isOn: $viewModel.followUserLocation)
                }
            }
            .navigationTitle("Location Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Offline Download Sheet

struct OfflineDownloadSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    @Bindable var viewModel: RouteMapViewModel
    let expeditionName: String

    @StateObject private var mapCache = MapCacheService.shared
    @State private var selectedZoomLevel = 13
    @State private var downloadError: String?

    private let zoomLevels = [
        (level: 10, description: "Overview (fastest)"),
        (level: 12, description: "Regional"),
        (level: 13, description: "Detailed (recommended)"),
        (level: 15, description: "High Detail (large)")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Region") {
                    if let bbox = viewModel.boundingBox {
                        LabeledContent("Area") {
                            Text(String(format: "%.2f° × %.2f°", bbox.latitudeSpan, bbox.longitudeSpan))
                        }

                        LabeledContent("Center") {
                            Text(String(format: "%.4f, %.4f", bbox.center.latitude, bbox.center.longitude))
                                .font(.system(.body, design: .monospaced))
                        }
                    }

                    LabeledContent("Waypoints") {
                        Text("\(viewModel.waypoints.count)")
                    }
                }

                Section("Download Options") {
                    Picker("Detail Level", selection: $selectedZoomLevel) {
                        ForEach(zoomLevels, id: \.level) { zoom in
                            Text(zoom.description).tag(zoom.level)
                        }
                    }
                }

                Section {
                    if let bbox = viewModel.boundingBox {
                        let tileEstimate = estimateTileCount(bbox: bbox, maxZoom: selectedZoomLevel)
                        LabeledContent("Estimated Tiles") {
                            Text("\(tileEstimate)")
                        }

                        LabeledContent("Estimated Size") {
                            Text(estimateSize(tileCount: tileEstimate))
                        }
                    }
                } header: {
                    Text("Estimate")
                } footer: {
                    Text("Actual size may vary. Tiles are sourced from OpenStreetMap.")
                }

                if let error = downloadError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        startDownload()
                    } label: {
                        HStack {
                            Spacer()
                            if mapCache.isDownloading {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Downloading \(Int(mapCache.downloadProgress * 100))%")
                            } else {
                                Label("Download Map Region", systemImage: "arrow.down.circle.fill")
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.boundingBox == nil || mapCache.isDownloading)
                }
            }
            .navigationTitle("Download Offline Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func estimateTileCount(bbox: DistanceService.BoundingBox, maxZoom: Int) -> Int {
        var count = 0
        let minZoom = 10

        for zoom in minZoom...maxZoom {
            let tilesPerDegree = pow(2.0, Double(zoom)) / 360.0
            let tilesX = Int(ceil(bbox.longitudeSpan * tilesPerDegree))
            let tilesY = Int(ceil(bbox.latitudeSpan * tilesPerDegree))
            count += tilesX * tilesY
        }

        return count
    }

    private func estimateSize(tileCount: Int) -> String {
        // Average tile size is ~15KB
        let bytes = Int64(tileCount * 15_000)
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func startDownload() {
        guard let bbox = viewModel.boundingBox else { return }

        downloadError = nil

        Task {
            do {
                try await mapCache.downloadRegion(
                    name: expeditionName,
                    region: MKCoordinateRegion(
                        center: bbox.center,
                        span: MKCoordinateSpan(
                            latitudeDelta: bbox.latitudeSpan * 1.2,
                            longitudeDelta: bbox.longitudeSpan * 1.2
                        )
                    ),
                    minZoom: 10,
                    maxZoom: selectedZoomLevel
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    downloadError = error.localizedDescription
                }
            }
        }
    }
}
