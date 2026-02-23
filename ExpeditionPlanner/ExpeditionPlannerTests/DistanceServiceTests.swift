import XCTest
import CoreLocation
@testable import ExpeditionPlanner

final class DistanceServiceTests: XCTestCase {

    // MARK: - Distance Calculation Tests

    func testDistanceBetweenSamePoint() {
        let coord = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        let distance = DistanceService.distance(from: coord, to: coord)
        XCTAssertEqual(distance, 0, accuracy: 0.001)
    }

    func testDistanceNYCToLA() {
        // New York City
        let nyc = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        // Los Angeles
        let la = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)

        let distance = DistanceService.distance(from: nyc, to: la)

        // Expected ~3940 km
        let expectedKm = 3940.0
        let actualKm = distance / 1000.0
        XCTAssertEqual(actualKm, expectedKm, accuracy: 50) // Within 50km
    }

    func testDistanceShortRange() {
        // Two points ~1km apart
        let point1 = CLLocationCoordinate2D(latitude: 40.0000, longitude: -74.0000)
        let point2 = CLLocationCoordinate2D(latitude: 40.0090, longitude: -74.0000)

        let distance = DistanceService.distance(from: point1, to: point2)

        // ~1000 meters
        XCTAssertEqual(distance, 1000, accuracy: 10)
    }

    // MARK: - Total Distance Tests

    func testTotalDistanceEmptyArray() {
        let total = DistanceService.totalDistance(along: [])
        XCTAssertEqual(total, 0)
    }

    func testTotalDistanceSinglePoint() {
        let coords = [CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0)]
        let total = DistanceService.totalDistance(along: coords)
        XCTAssertEqual(total, 0)
    }

    func testTotalDistanceMultiplePoints() {
        let coords = [
            CLLocationCoordinate2D(latitude: 40.0000, longitude: -74.0000),
            CLLocationCoordinate2D(latitude: 40.0090, longitude: -74.0000), // ~1km
            CLLocationCoordinate2D(latitude: 40.0180, longitude: -74.0000)  // ~1km more
        ]

        let total = DistanceService.totalDistance(along: coords)

        // Should be ~2000m
        XCTAssertEqual(total, 2000, accuracy: 20)
    }

    // MARK: - Bearing Tests

    func testBearingNorth() {
        let start = CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0)
        let end = CLLocationCoordinate2D(latitude: 41.0, longitude: -74.0)

        let bearing = DistanceService.bearing(from: start, to: end)

        // Should be approximately 0 (north)
        XCTAssertEqual(bearing, 0, accuracy: 1)
    }

    func testBearingEast() {
        let start = CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0)
        let end = CLLocationCoordinate2D(latitude: 40.0, longitude: -73.0)

        let bearing = DistanceService.bearing(from: start, to: end)

        // Should be approximately 90 (east)
        XCTAssertEqual(bearing, 90, accuracy: 2)
    }

    func testBearingSouth() {
        let start = CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0)
        let end = CLLocationCoordinate2D(latitude: 39.0, longitude: -74.0)

        let bearing = DistanceService.bearing(from: start, to: end)

        // Should be approximately 180 (south)
        XCTAssertEqual(bearing, 180, accuracy: 1)
    }

    func testBearingWest() {
        let start = CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0)
        let end = CLLocationCoordinate2D(latitude: 40.0, longitude: -75.0)

        let bearing = DistanceService.bearing(from: start, to: end)

        // Should be approximately 270 (west)
        XCTAssertEqual(bearing, 270, accuracy: 2)
    }

    // MARK: - Cardinal Direction Tests

    func testCardinalDirectionNorth() {
        let direction = DistanceService.cardinalDirection(from: 0)
        XCTAssertEqual(direction, "N")
    }

    func testCardinalDirectionEast() {
        let direction = DistanceService.cardinalDirection(from: 90)
        XCTAssertEqual(direction, "E")
    }

    func testCardinalDirectionSouth() {
        let direction = DistanceService.cardinalDirection(from: 180)
        XCTAssertEqual(direction, "S")
    }

    func testCardinalDirectionWest() {
        let direction = DistanceService.cardinalDirection(from: 270)
        XCTAssertEqual(direction, "W")
    }

    func testCardinalDirectionNortheast() {
        let direction = DistanceService.cardinalDirection(from: 45)
        XCTAssertEqual(direction, "NE")
    }

    // MARK: - Unit Conversion Tests

    func testMetersToKilometers() {
        let km = DistanceService.metersToKilometers(5000)
        XCTAssertEqual(km, 5.0)
    }

    func testMetersToMiles() {
        let miles = DistanceService.metersToMiles(1609.344)
        XCTAssertEqual(miles, 1.0, accuracy: 0.001)
    }

    func testKilometersToMeters() {
        let meters = DistanceService.kilometersToMeters(5)
        XCTAssertEqual(meters, 5000)
    }

    func testMilesToMeters() {
        let meters = DistanceService.milesToMeters(1)
        XCTAssertEqual(meters, 1609.344, accuracy: 0.001)
    }

    // MARK: - Formatting Tests

    func testFormatDistanceMetric() {
        let short = DistanceService.formatDistance(500)
        XCTAssertEqual(short, "500 m")

        let long = DistanceService.formatDistance(5000)
        XCTAssertEqual(long, "5.0 km")
    }

    func testFormatDistanceImperial() {
        let short = DistanceService.formatDistance(100, useMetric: false)
        XCTAssertTrue(short.contains("ft"))

        let long = DistanceService.formatDistance(5000, useMetric: false)
        XCTAssertTrue(long.contains("mi"))
    }

    func testFormatBearing() {
        let formatted = DistanceService.formatBearing(45)
        XCTAssertEqual(formatted, "45° NE")
    }

    // MARK: - Bounding Box Tests

    func testBoundingBoxEmpty() {
        let bbox = DistanceService.boundingBox(for: [])
        XCTAssertNil(bbox)
    }

    func testBoundingBoxSinglePoint() {
        let coords = [CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0)]
        let bbox = DistanceService.boundingBox(for: coords)

        XCTAssertNotNil(bbox)
        XCTAssertEqual(bbox?.minLatitude, 40.0)
        XCTAssertEqual(bbox?.maxLatitude, 40.0)
        XCTAssertEqual(bbox?.minLongitude, -74.0)
        XCTAssertEqual(bbox?.maxLongitude, -74.0)
    }

    func testBoundingBoxMultiplePoints() {
        let coords = [
            CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0),
            CLLocationCoordinate2D(latitude: 41.0, longitude: -73.0),
            CLLocationCoordinate2D(latitude: 39.0, longitude: -75.0)
        ]
        let bbox = DistanceService.boundingBox(for: coords)

        XCTAssertNotNil(bbox)
        XCTAssertEqual(bbox?.minLatitude, 39.0)
        XCTAssertEqual(bbox?.maxLatitude, 41.0)
        XCTAssertEqual(bbox?.minLongitude, -75.0)
        XCTAssertEqual(bbox?.maxLongitude, -73.0)
    }

    func testBoundingBoxCenter() {
        let coords = [
            CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0),
            CLLocationCoordinate2D(latitude: 42.0, longitude: -72.0)
        ]
        let bbox = DistanceService.boundingBox(for: coords)

        XCTAssertEqual(bbox?.center.latitude, 41.0)
        XCTAssertEqual(bbox?.center.longitude, -73.0)
    }

    func testBoundingBoxSpan() {
        let coords = [
            CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0),
            CLLocationCoordinate2D(latitude: 42.0, longitude: -72.0)
        ]
        let bbox = DistanceService.boundingBox(for: coords)

        XCTAssertEqual(bbox?.latitudeSpan, 2.0)
        XCTAssertEqual(bbox?.longitudeSpan, 2.0)
    }

    // MARK: - Distance to Segment Tests

    func testDistanceToSegmentOnLine() {
        let point = CLLocationCoordinate2D(latitude: 40.5, longitude: -74.0)
        let start = CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0)
        let end = CLLocationCoordinate2D(latitude: 41.0, longitude: -74.0)

        let distance = DistanceService.distanceToSegment(
            point: point,
            segmentStart: start,
            segmentEnd: end
        )

        // Point is on the line, distance should be very small
        XCTAssertEqual(distance, 0, accuracy: 1)
    }

    func testDistanceToSegmentOffLine() {
        let point = CLLocationCoordinate2D(latitude: 40.5, longitude: -73.0)
        let start = CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0)
        let end = CLLocationCoordinate2D(latitude: 41.0, longitude: -74.0)

        let distance = DistanceService.distanceToSegment(
            point: point,
            segmentStart: start,
            segmentEnd: end
        )

        // Point is 1 degree longitude away
        XCTAssertGreaterThan(distance, 50000) // Should be > 50km
    }
}
