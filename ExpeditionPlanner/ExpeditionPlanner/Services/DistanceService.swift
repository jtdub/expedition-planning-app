import Foundation
import CoreLocation

struct DistanceService {
    // MARK: - Constants

    static let metersPerKilometer: Double = 1000.0
    static let metersPerMile: Double = 1609.344
    static let feetPerMeter: Double = 3.28084

    // MARK: - Distance Calculations

    /// Calculate geodesic distance between two coordinates
    static func distance(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation)
    }

    /// Calculate total distance along a route of coordinates
    static func totalDistance(along coordinates: [CLLocationCoordinate2D]) -> CLLocationDistance {
        guard coordinates.count >= 2 else { return 0 }

        var total: CLLocationDistance = 0
        for index in 0..<(coordinates.count - 1) {
            total += distance(from: coordinates[index], to: coordinates[index + 1])
        }
        return total
    }

    /// Calculate distance from a point to the nearest point on a line segment
    static func distanceToSegment(
        point: CLLocationCoordinate2D,
        segmentStart: CLLocationCoordinate2D,
        segmentEnd: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        let pointLoc = CLLocation(latitude: point.latitude, longitude: point.longitude)
        let startLoc = CLLocation(latitude: segmentStart.latitude, longitude: segmentStart.longitude)
        let endLoc = CLLocation(latitude: segmentEnd.latitude, longitude: segmentEnd.longitude)

        let segmentLength = startLoc.distance(from: endLoc)
        guard segmentLength > 0 else {
            return pointLoc.distance(from: startLoc)
        }

        // Project point onto segment
        let param = max(0, min(1, projection(point: point, onto: (segmentStart, segmentEnd))))
        let projectedLat = segmentStart.latitude + param * (segmentEnd.latitude - segmentStart.latitude)
        let projectedLon = segmentStart.longitude + param * (segmentEnd.longitude - segmentStart.longitude)
        let projectedLoc = CLLocation(latitude: projectedLat, longitude: projectedLon)

        return pointLoc.distance(from: projectedLoc)
    }

    /// Calculate the projection parameter t for a point onto a line segment
    private static func projection(
        point: CLLocationCoordinate2D,
        onto segment: (CLLocationCoordinate2D, CLLocationCoordinate2D)
    ) -> Double {
        let (start, end) = segment
        let dx = end.longitude - start.longitude
        let dy = end.latitude - start.latitude

        guard dx != 0 || dy != 0 else { return 0 }

        let param = ((point.longitude - start.longitude) * dx + (point.latitude - start.latitude) * dy)
            / (dx * dx + dy * dy)

        return param
    }

    // MARK: - Bearing Calculations

    /// Calculate initial bearing from start to end coordinate
    static func bearing(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let dLon = (end.longitude - start.longitude) * .pi / 180

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

        var bearing = atan2(y, x) * 180 / .pi
        bearing = (bearing + 360).truncatingRemainder(dividingBy: 360)

        return bearing
    }

    /// Convert bearing to cardinal direction
    static func cardinalDirection(from bearing: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                          "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((bearing + 11.25) / 22.5) % 16
        return directions[index]
    }

    // MARK: - Unit Conversion

    static func metersToKilometers(_ meters: Double) -> Double {
        meters / metersPerKilometer
    }

    static func metersToMiles(_ meters: Double) -> Double {
        meters / metersPerMile
    }

    static func kilometersToMeters(_ km: Double) -> Double {
        km * metersPerKilometer
    }

    static func milesToMeters(_ miles: Double) -> Double {
        miles * metersPerMile
    }

    // MARK: - Formatting

    static func formatDistance(_ meters: Double, useMetric: Bool = true) -> String {
        if useMetric {
            if meters >= 1000 {
                return String(format: "%.1f km", metersToKilometers(meters))
            } else {
                return String(format: "%.0f m", meters)
            }
        } else {
            let miles = metersToMiles(meters)
            if miles >= 0.1 {
                return String(format: "%.1f mi", miles)
            } else {
                let feet = meters * feetPerMeter
                return String(format: "%.0f ft", feet)
            }
        }
    }

    static func formatBearing(_ bearing: Double) -> String {
        let cardinal = cardinalDirection(from: bearing)
        return String(format: "%.0f° %@", bearing, cardinal)
    }

    // MARK: - Bounding Box

    struct BoundingBox {
        let minLatitude: Double
        let maxLatitude: Double
        let minLongitude: Double
        let maxLongitude: Double

        var center: CLLocationCoordinate2D {
            CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            )
        }

        var latitudeSpan: Double {
            maxLatitude - minLatitude
        }

        var longitudeSpan: Double {
            maxLongitude - minLongitude
        }
    }

    /// Calculate bounding box for a set of coordinates
    static func boundingBox(for coordinates: [CLLocationCoordinate2D]) -> BoundingBox? {
        guard !coordinates.isEmpty else { return nil }

        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }

        return BoundingBox(
            minLatitude: minLat,
            maxLatitude: maxLat,
            minLongitude: minLon,
            maxLongitude: maxLon
        )
    }
}
