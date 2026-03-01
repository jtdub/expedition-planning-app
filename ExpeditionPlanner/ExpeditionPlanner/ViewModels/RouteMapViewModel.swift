import Foundation
import SwiftData
import SwiftUI
import MapKit
import OSLog

private let logger = Logger(subsystem: "com.chaki.app", category: "RouteMapViewModel")

@Observable
final class RouteMapViewModel {
    // MARK: - Properties

    private(set) var expedition: Expedition
    private var modelContext: ModelContext

    var selectedWaypoint: RouteWaypoint?
    var showElevationOverlay: Bool = false
    var selectedWaypointTypes: Set<WaypointType> = Set(WaypointType.allCases)
    var showNearbyShelters: Bool = true

    /// Location manager for tracking
    let locationManager = LocationManager()

    /// Whether to follow user location on map
    var followUserLocation: Bool = false

    /// Whether tracking mode is active
    var isTrackingExpedition: Bool {
        locationManager.isTracking
    }

    // MARK: - Initialization

    init(expedition: Expedition, modelContext: ModelContext) {
        self.expedition = expedition
        self.modelContext = modelContext
    }

    // MARK: - Computed Properties

    var waypoints: [RouteWaypoint] {
        var allWaypoints = RouteService.extractWaypoints(from: expedition)

        // Add nearby shelter cabins if enabled
        if showNearbyShelters && !routeCoordinates.isEmpty {
            let shelterWaypoints = fetchShelterWaypoints()
            allWaypoints.append(contentsOf: shelterWaypoints)
        }

        return allWaypoints
    }

    /// Fetch shelters from SwiftData and convert to waypoints
    private func fetchShelterWaypoints() -> [RouteWaypoint] {
        let descriptor = FetchDescriptor<Shelter>()
        do {
            let shelters = try modelContext.fetch(descriptor)
            // Filter to shelters near the route
            let nearShelters = filterSheltersNearRoute(shelters, withinMeters: 15000)
            return ShelterService.toWaypoints(nearShelters)
        } catch {
            logger.error("Failed to fetch shelters: \(error.localizedDescription)")
            return []
        }
    }

    /// Filter shelters that are within distance of any route coordinate
    private func filterSheltersNearRoute(_ shelters: [Shelter], withinMeters distance: Double) -> [Shelter] {
        guard !routeCoordinates.isEmpty else { return [] }

        return shelters.filter { shelter in
            guard let lat = shelter.latitude, let lon = shelter.longitude else { return false }
            let shelterLocation = CLLocation(latitude: lat, longitude: lon)

            return routeCoordinates.contains { coord in
                let routeLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                return shelterLocation.distance(from: routeLocation) <= distance
            }
        }
    }

    var filteredWaypoints: [RouteWaypoint] {
        RouteService.filter(waypoints: waypoints, by: selectedWaypointTypes)
    }

    var routeCoordinates: [CLLocationCoordinate2D] {
        let days = expedition.itinerary ?? []
        return RouteService.buildRoute(from: days)
    }

    var statistics: RouteService.RouteStatistics {
        RouteService.statistics(waypoints: waypoints, route: routeCoordinates)
    }

    var hasRouteData: Bool {
        !routeCoordinates.isEmpty || !waypoints.isEmpty
    }

    var boundingBox: DistanceService.BoundingBox? {
        let coords = waypoints.map { $0.coordinate } + routeCoordinates
        return DistanceService.boundingBox(for: coords)
    }

    var mapCameraPosition: MapCameraPosition {
        guard let bbox = boundingBox else {
            return .automatic
        }

        let center = bbox.center
        let latSpan = max(bbox.latitudeSpan * 1.2, 0.01)
        let lonSpan = max(bbox.longitudeSpan * 1.2, 0.01)

        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: lonSpan)
        )

        return .region(region)
    }

    // MARK: - Elevation Chart Data

    var elevationChartData: [ElevationService.ElevationPoint] {
        let days = expedition.sortedItinerary
        return ElevationService.chartData(from: days)
    }

    // MARK: - Formatting

    var formattedTotalDistance: String {
        DistanceService.formatDistance(statistics.totalDistanceMeters)
    }

    func formattedElevation(_ meters: Double?, unit: ElevationUnit) -> String {
        ElevationService.formatElevation(meters, unit: unit)
    }

    // MARK: - Actions

    func selectWaypoint(_ waypoint: RouteWaypoint) {
        selectedWaypoint = waypoint
        logger.info("Selected waypoint: \(waypoint.name)")
    }

    func clearSelection() {
        selectedWaypoint = nil
    }

    func toggleWaypointTypeFilter(_ type: WaypointType) {
        if selectedWaypointTypes.contains(type) {
            selectedWaypointTypes.remove(type)
        } else {
            selectedWaypointTypes.insert(type)
        }
    }

    func showAllWaypointTypes() {
        selectedWaypointTypes = Set(WaypointType.allCases)
    }

    func toggleElevationOverlay() {
        showElevationOverlay.toggle()
    }

    // MARK: - GPX Import

    func importWaypoints(_ importedWaypoints: [RouteWaypoint]) {
        guard let days = expedition.itinerary else {
            logger.warning("No itinerary to import waypoints into")
            return
        }

        // For now, log the imported waypoints
        // Full implementation would match imported waypoints to days
        logger.info("Imported \(importedWaypoints.count) waypoints")

        // Update coordinates on matching days by name
        for waypoint in importedWaypoints {
            for day in days {
                if day.startLocation.lowercased() == waypoint.name.lowercased() {
                    day.startLatitude = waypoint.coordinate.latitude
                    day.startLongitude = waypoint.coordinate.longitude
                    if let elevation = waypoint.elevationMeters {
                        day.startElevationMeters = elevation
                    }
                }

                if day.endLocation.lowercased() == waypoint.name.lowercased() {
                    day.endLatitude = waypoint.coordinate.latitude
                    day.endLongitude = waypoint.coordinate.longitude
                    if let elevation = waypoint.elevationMeters {
                        day.endElevationMeters = elevation
                    }
                }
            }
        }

        save()
    }

    // MARK: - Location Tracking

    /// Start tracking expedition progress
    func startTracking() {
        locationManager.startTracking()
        followUserLocation = true
        logger.info("Started expedition tracking")
    }

    /// Stop tracking and optionally save track
    func stopTracking(saveTrack: Bool = true) {
        let track = locationManager.stopTracking()
        followUserLocation = false

        if saveTrack && !track.isEmpty {
            logger.info("Stopped tracking with \(track.count) points")
            // Track can be exported or saved as needed
        }
    }

    /// Get user's recorded track as coordinates
    var userTrackCoordinates: [CLLocationCoordinate2D] {
        locationManager.trackCoordinates
    }

    /// Distance traveled in current tracking session
    var formattedDistanceTraveled: String {
        DistanceService.formatDistance(locationManager.distanceTraveled)
    }

    /// Distance to next waypoint from current location
    func distanceToNextWaypoint() -> String? {
        guard let location = locationManager.currentLocation else { return nil }

        // Find the next waypoint (closest one ahead)
        // For now, just use all waypoints - a more sophisticated implementation
        // would track which waypoints have been passed
        let remainingWaypoints = waypoints

        guard let nearest = remainingWaypoints.min(by: {
            location.distance(from: CLLocation(
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude
            )) < location.distance(from: CLLocation(
                latitude: $1.coordinate.latitude,
                longitude: $1.coordinate.longitude
            ))
        }) else { return nil }

        let distance = location.distance(from: CLLocation(
            latitude: nearest.coordinate.latitude,
            longitude: nearest.coordinate.longitude
        ))

        return "\(DistanceService.formatDistance(distance)) to \(nearest.name)"
    }

    // MARK: - Persistence

    private func save() {
        do {
            try modelContext.save()
            expedition.updatedAt = Date()
        } catch {
            logger.error("Failed to save route changes: \(error.localizedDescription)")
        }
    }
}
