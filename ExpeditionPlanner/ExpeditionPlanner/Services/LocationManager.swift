import Foundation
import CoreLocation
import Combine

/// Manages location services for expedition tracking
@Observable
final class LocationManager: NSObject {
    // MARK: - Properties

    private let locationManager = CLLocationManager()

    /// Current user location
    private(set) var currentLocation: CLLocation?

    /// Current authorization status
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Whether location is currently being tracked
    private(set) var isTracking = false

    /// Recorded track points during tracking session
    private(set) var trackPoints: [CLLocation] = []

    /// Total distance traveled in current tracking session (meters)
    var distanceTraveled: CLLocationDistance {
        guard trackPoints.count >= 2 else { return 0 }
        var total: CLLocationDistance = 0
        for index in 1..<trackPoints.count {
            total += trackPoints[index].distance(from: trackPoints[index - 1])
        }
        return total
    }

    /// Current speed in meters per second
    var currentSpeed: CLLocationSpeed {
        currentLocation?.speed ?? 0
    }

    /// Current heading in degrees
    var currentHeading: CLLocationDirection {
        currentLocation?.course ?? -1
    }

    /// Whether location services are authorized
    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }

    /// Whether location services are denied
    var isDenied: Bool {
        authorizationStatus == .denied
    }

    /// Human-readable authorization status
    var authorizationStatusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Always"
        case .authorizedWhenInUse:
            return "When In Use"
        @unknown default:
            return "Unknown"
        }
    }

    // MARK: - Initialization

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = true
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Authorization

    /// Request location authorization
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Request always authorization (for background tracking)
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - Location Updates

    /// Start receiving location updates
    func startUpdatingLocation() {
        guard isAuthorized else {
            requestAuthorization()
            return
        }
        locationManager.startUpdatingLocation()
    }

    /// Stop receiving location updates
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    /// Request a single location update
    func requestLocation() {
        guard isAuthorized else {
            requestAuthorization()
            return
        }
        locationManager.requestLocation()
    }

    // MARK: - Tracking

    /// Start tracking expedition progress
    func startTracking() {
        guard isAuthorized else {
            requestAuthorization()
            return
        }

        trackPoints.removeAll()
        isTracking = true
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
    }

    /// Stop tracking and return the recorded track
    func stopTracking() -> [CLLocation] {
        isTracking = false
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.stopUpdatingLocation()
        return trackPoints
    }

    /// Pause tracking temporarily
    func pauseTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
    }

    /// Resume tracking
    func resumeTracking() {
        guard !trackPoints.isEmpty else {
            startTracking()
            return
        }
        isTracking = true
        locationManager.startUpdatingLocation()
    }

    /// Clear recorded track points
    func clearTrack() {
        trackPoints.removeAll()
    }

    // MARK: - Utilities

    /// Calculate distance from current location to a coordinate
    func distanceTo(_ coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        let destination = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: destination)
    }

    /// Calculate bearing from current location to a coordinate
    func bearingTo(_ coordinate: CLLocationCoordinate2D) -> Double? {
        guard let current = currentLocation else { return nil }
        return DistanceService.bearing(from: current.coordinate, to: coordinate)
    }

    /// Get track points as coordinates for map display
    var trackCoordinates: [CLLocationCoordinate2D] {
        trackPoints.map { $0.coordinate }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Filter out inaccurate locations
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 100 else { return }

        currentLocation = location

        if isTracking {
            // Only add point if it's significantly different from the last one
            if let lastPoint = trackPoints.last {
                let distance = location.distance(from: lastPoint)
                if distance >= 5 { // Minimum 5 meters between track points
                    trackPoints.append(location)
                }
            } else {
                trackPoints.append(location)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle location errors silently for now
        // In production, you might want to notify the user
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                authorizationStatus = .denied
            default:
                break
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        // Automatically start updates if authorized and tracking was requested
        if isAuthorized && isTracking {
            locationManager.startUpdatingLocation()
        }
    }
}
