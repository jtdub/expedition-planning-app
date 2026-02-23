import SwiftUI
import SwiftData
import MapKit

enum MapStyleOption: String, CaseIterable {
    case standard = "Standard"
    case satellite = "Satellite"
    case hybrid = "Hybrid"
}

struct RouteMapView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Bindable var expedition: Expedition

    @AppStorage("elevationUnit")
    private var elevationUnit: ElevationUnit = .meters

    @State private var viewModel: RouteMapViewModel?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showingWaypointDetail = false
    @State private var showingGPXImport = false
    @State private var showingGPXExport = false
    @State private var selectedMapStyle: MapStyleOption = .standard
    @State private var showingTrackingSheet = false
    @State private var mapSelection: MapFeature?
    @State private var showingOfflineDownload = false
    @StateObject private var mapCache = MapCacheService.shared

    private var mapStyle: MapStyle {
        switch selectedMapStyle {
        case .standard:
            return .standard
        case .satellite:
            return .imagery
        case .hybrid:
            return .hybrid
        }
    }

    var body: some View {
        Group {
            if let viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Route Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                if let viewModel {
                    trackingButton(viewModel: viewModel)
                }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                mapStyleMenu
                gpxMenu
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = RouteMapViewModel(expedition: expedition, modelContext: modelContext)
                if let vm = viewModel {
                    cameraPosition = vm.mapCameraPosition
                }
            }
        }
        .sheet(isPresented: $showingWaypointDetail) {
            if let viewModel, let waypoint = viewModel.selectedWaypoint {
                WaypointDetailSheet(
                    waypoint: waypoint,
                    elevationUnit: elevationUnit
                )
            }
        }
        .sheet(isPresented: $showingGPXImport) {
            GPXImportView { waypoints in
                viewModel?.importWaypoints(waypoints)
            }
        }
        .sheet(isPresented: $showingGPXExport) {
            if let viewModel {
                GPXExportView(
                    waypoints: viewModel.waypoints,
                    routeCoordinates: viewModel.routeCoordinates,
                    expeditionName: expedition.name
                )
            }
        }
        .sheet(isPresented: $showingTrackingSheet) {
            if let viewModel {
                TrackingControlSheet(viewModel: viewModel)
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showingOfflineDownload) {
            if let viewModel {
                OfflineDownloadSheet(
                    viewModel: viewModel,
                    expeditionName: expedition.name
                )
            }
        }
    }

    @ViewBuilder
    private func contentView(viewModel: RouteMapViewModel) -> some View {
        if viewModel.hasRouteData {
            ZStack(alignment: .bottom) {
                mapContent(viewModel: viewModel)

                RouteMapOverlayView(
                    viewModel: viewModel,
                    elevationUnit: elevationUnit
                )
            }
        } else {
            emptyState
        }
    }

    @ViewBuilder
    private func mapContent(viewModel: RouteMapViewModel) -> some View {
        Map(position: $cameraPosition) {
            // Route polyline
            if viewModel.routeCoordinates.count >= 2 {
                MapPolyline(coordinates: viewModel.routeCoordinates)
                    .stroke(.blue, lineWidth: 3)
            }

            // User's recorded track (shown in green)
            if viewModel.userTrackCoordinates.count >= 2 {
                MapPolyline(coordinates: viewModel.userTrackCoordinates)
                    .stroke(.green, lineWidth: 4)
            }

            // Waypoint markers
            ForEach(viewModel.filteredWaypoints) { waypoint in
                Annotation(
                    waypoint.name,
                    coordinate: waypoint.coordinate,
                    anchor: .bottom
                ) {
                    WaypointAnnotation(
                        waypoint: waypoint,
                        isSelected: viewModel.selectedWaypoint?.id == waypoint.id,
                        onTap: {
                            viewModel.selectWaypoint(waypoint)
                            showingWaypointDetail = true
                        }
                    )
                }
            }

            // User location
            UserAnnotation()
        }
        .mapStyle(mapStyle)
        .mapControls {
            MapCompass()
            MapScaleView()
            MapUserLocationButton()
        }
        .onAppear {
            // Request location updates when map appears
            viewModel.locationManager.startUpdatingLocation()
        }
        .onChange(of: viewModel.followUserLocation) { _, follow in
            if follow, let location = viewModel.locationManager.currentLocation {
                cameraPosition = .camera(MapCamera(
                    centerCoordinate: location.coordinate,
                    distance: 1000
                ))
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Route Data", systemImage: "map")
        } description: {
            Text("Add coordinates to your itinerary days to see your route on the map.")
        } actions: {
            Button {
                showingGPXImport = true
            } label: {
                Label("Import GPX", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var mapStyleMenu: some View {
        Menu {
            Button {
                selectedMapStyle = .standard
            } label: {
                Label("Standard", systemImage: selectedMapStyle == .standard ? "checkmark" : "")
            }

            Button {
                selectedMapStyle = .satellite
            } label: {
                Label("Satellite", systemImage: selectedMapStyle == .satellite ? "checkmark" : "")
            }

            Button {
                selectedMapStyle = .hybrid
            } label: {
                Label("Hybrid", systemImage: selectedMapStyle == .hybrid ? "checkmark" : "")
            }
        } label: {
            Image(systemName: "map")
        }
    }

    @ViewBuilder
    private func trackingButton(viewModel: RouteMapViewModel) -> some View {
        Button {
            if viewModel.isTrackingExpedition {
                showingTrackingSheet = true
            } else {
                if viewModel.locationManager.isAuthorized {
                    showingTrackingSheet = true
                } else {
                    viewModel.locationManager.requestAuthorization()
                }
            }
        } label: {
            Image(systemName: viewModel.isTrackingExpedition
                ? "location.fill"
                : "location")
            .foregroundStyle(viewModel.isTrackingExpedition ? .green : .primary)
        }
    }

    private var gpxMenu: some View {
        Menu {
            Button {
                showingGPXImport = true
            } label: {
                Label("Import GPX", systemImage: "square.and.arrow.down")
            }

            Button {
                showingGPXExport = true
            } label: {
                Label("Export GPX", systemImage: "square.and.arrow.up")
            }
            .disabled(viewModel?.waypoints.isEmpty ?? true)

            Divider()

            Button {
                showingOfflineDownload = true
            } label: {
                if mapCache.isDownloading {
                    Label("Downloading...", systemImage: "arrow.down.circle")
                } else {
                    Label("Download for Offline", systemImage: "arrow.down.circle")
                }
            }
            .disabled(viewModel?.boundingBox == nil || mapCache.isDownloading)
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

#Preview {
    NavigationStack {
        RouteMapView(expedition: Expedition(name: "Test Expedition"))
    }
    .modelContainer(for: Expedition.self, inMemory: true)
}
