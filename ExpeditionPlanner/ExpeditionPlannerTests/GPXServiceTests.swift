import XCTest
import CoreLocation
@testable import ExpeditionPlanner

final class GPXServiceTests: XCTestCase {

    // MARK: - Export Tests

    func testExportEmptyData() {
        let gpx = GPXService.export(
            waypoints: [],
            trackCoordinates: [],
            name: nil,
            description: nil
        )

        XCTAssertTrue(gpx.contains("<?xml"))
        XCTAssertTrue(gpx.contains("<gpx"))
        XCTAssertTrue(gpx.contains("</gpx>"))
        XCTAssertFalse(gpx.contains("<wpt"))
        XCTAssertFalse(gpx.contains("<trk"))
    }

    func testExportWithMetadata() {
        let gpx = GPXService.export(
            waypoints: [],
            trackCoordinates: [],
            name: "Test Expedition",
            description: "A test expedition"
        )

        XCTAssertTrue(gpx.contains("<metadata>"))
        XCTAssertTrue(gpx.contains("<name>Test Expedition</name>"))
        XCTAssertTrue(gpx.contains("<desc>A test expedition</desc>"))
        XCTAssertTrue(gpx.contains("<time>"))
    }

    func testExportWithWaypoints() {
        let waypoints = [
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0),
                name: "Start Point",
                type: .startPoint,
                elevationMeters: 1000,
                sourceId: UUID()
            ),
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: -73.0),
                name: "Camp 1",
                type: .campsite,
                elevationMeters: 2000,
                notes: "Good water source",
                sourceId: UUID()
            )
        ]

        let gpx = GPXService.export(
            waypoints: waypoints,
            trackCoordinates: [],
            name: "Test"
        )

        XCTAssertTrue(gpx.contains("<wpt lat=\"40.0\" lon=\"-74.0\">"))
        XCTAssertTrue(gpx.contains("<name>Start Point</name>"))
        XCTAssertTrue(gpx.contains("<ele>1000.0</ele>"))
        XCTAssertTrue(gpx.contains("<type>Start Point</type>"))

        XCTAssertTrue(gpx.contains("<wpt lat=\"41.0\" lon=\"-73.0\">"))
        XCTAssertTrue(gpx.contains("<name>Camp 1</name>"))
        XCTAssertTrue(gpx.contains("<desc>Good water source</desc>"))
    }

    func testExportWithTrack() {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0),
            CLLocationCoordinate2D(latitude: 40.5, longitude: -73.5),
            CLLocationCoordinate2D(latitude: 41.0, longitude: -73.0)
        ]

        let gpx = GPXService.export(
            waypoints: [],
            trackCoordinates: coordinates,
            name: "Test Route"
        )

        XCTAssertTrue(gpx.contains("<trk>"))
        XCTAssertTrue(gpx.contains("<name>Test Route Track</name>"))
        XCTAssertTrue(gpx.contains("<trkseg>"))
        XCTAssertTrue(gpx.contains("<trkpt lat=\"40.0\" lon=\"-74.0\"/>"))
        XCTAssertTrue(gpx.contains("<trkpt lat=\"40.5\" lon=\"-73.5\"/>"))
        XCTAssertTrue(gpx.contains("<trkpt lat=\"41.0\" lon=\"-73.0\"/>"))
        XCTAssertTrue(gpx.contains("</trkseg>"))
        XCTAssertTrue(gpx.contains("</trk>"))
    }

    func testExportEscapesXMLCharacters() {
        let waypoints = [
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0),
                name: "Camp <Test> & \"Special\"",
                type: .campsite,
                notes: "Use caution 'here'",
                sourceId: UUID()
            )
        ]

        let gpx = GPXService.export(
            waypoints: waypoints,
            trackCoordinates: [],
            name: nil
        )

        XCTAssertTrue(gpx.contains("&lt;Test&gt;"))
        XCTAssertTrue(gpx.contains("&amp;"))
        XCTAssertTrue(gpx.contains("&quot;Special&quot;"))
        XCTAssertTrue(gpx.contains("&apos;here&apos;"))
    }

    // MARK: - Parse Tests

    func testParseValidGPX() {
        let gpxData = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Test">
            <metadata>
                <name>Test Route</name>
                <desc>A test route</desc>
            </metadata>
            <wpt lat="40.0" lon="-74.0">
                <ele>1000</ele>
                <name>Start</name>
                <type>Start Point</type>
            </wpt>
            <wpt lat="41.0" lon="-73.0">
                <ele>2000</ele>
                <name>End</name>
                <type>End Point</type>
            </wpt>
            <trk>
                <name>Track</name>
                <trkseg>
                    <trkpt lat="40.0" lon="-74.0"/>
                    <trkpt lat="40.5" lon="-73.5"/>
                    <trkpt lat="41.0" lon="-73.0"/>
                </trkseg>
            </trk>
        </gpx>
        """.data(using: .utf8)!

        let result = GPXService.parse(data: gpxData)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Test Route")
        XCTAssertEqual(result?.description, "A test route")
        XCTAssertEqual(result?.waypoints.count, 2)
        XCTAssertEqual(result?.trackPoints.count, 3)

        let startWaypoint = result?.waypoints.first
        XCTAssertEqual(startWaypoint?.name, "Start")
        XCTAssertEqual(startWaypoint?.coordinate.latitude, 40.0)
        XCTAssertEqual(startWaypoint?.coordinate.longitude, -74.0)
        XCTAssertEqual(startWaypoint?.elevationMeters, 1000)
        XCTAssertEqual(startWaypoint?.type, .startPoint)
    }

    func testParseMinimalGPX() {
        let gpxData = """
        <?xml version="1.0"?>
        <gpx version="1.1">
            <wpt lat="45.5" lon="-122.5">
                <name>Portland</name>
            </wpt>
        </gpx>
        """.data(using: .utf8)!

        let result = GPXService.parse(data: gpxData)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.waypoints.count, 1)
        XCTAssertEqual(result?.waypoints.first?.name, "Portland")
        XCTAssertEqual(result?.waypoints.first?.type, .waypoint)
        XCTAssertNil(result?.waypoints.first?.elevationMeters)
    }

    func testParseWaypointTypes() {
        let gpxData = """
        <?xml version="1.0"?>
        <gpx version="1.1">
            <wpt lat="1.0" lon="1.0">
                <name>Camp</name>
                <type>campsite</type>
            </wpt>
            <wpt lat="2.0" lon="2.0">
                <name>Supply</name>
                <type>resupply</type>
            </wpt>
            <wpt lat="3.0" lon="3.0">
                <name>Peak</name>
                <type>summit</type>
            </wpt>
            <wpt lat="4.0" lon="4.0">
                <name>Danger</name>
                <type>hazard</type>
            </wpt>
        </gpx>
        """.data(using: .utf8)!

        let result = GPXService.parse(data: gpxData)

        XCTAssertEqual(result?.waypoints.count, 4)
        XCTAssertEqual(result?.waypoints[0].type, .campsite)
        XCTAssertEqual(result?.waypoints[1].type, .resupply)
        XCTAssertEqual(result?.waypoints[2].type, .summit)
        XCTAssertEqual(result?.waypoints[3].type, .hazard)
    }

    func testParseInvalidXML() {
        let invalidData = "This is not XML".data(using: .utf8)!
        let result = GPXService.parse(data: invalidData)

        // Should return nil for invalid XML
        XCTAssertNil(result)
    }

    func testParseEmptyGPX() {
        let gpxData = """
        <?xml version="1.0"?>
        <gpx version="1.1">
        </gpx>
        """.data(using: .utf8)!

        let result = GPXService.parse(data: gpxData)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.waypoints.count, 0)
        XCTAssertEqual(result?.trackPoints.count, 0)
    }

    // MARK: - Round Trip Tests

    func testExportThenParse() {
        let originalWaypoints = [
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0),
                name: "Start",
                type: .startPoint,
                elevationMeters: 1000,
                sourceId: UUID()
            ),
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: -73.0),
                name: "End",
                type: .endPoint,
                elevationMeters: 2000,
                sourceId: UUID()
            )
        ]

        let originalTrack = [
            CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0),
            CLLocationCoordinate2D(latitude: 41.0, longitude: -73.0)
        ]

        // Export
        let gpxString = GPXService.export(
            waypoints: originalWaypoints,
            trackCoordinates: originalTrack,
            name: "Round Trip Test"
        )

        // Parse back
        let gpxData = gpxString.data(using: .utf8)!
        let result = GPXService.parse(data: gpxData)

        // Verify
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Round Trip Test")
        XCTAssertEqual(result?.waypoints.count, 2)
        XCTAssertEqual(result?.trackPoints.count, 2)

        // Check waypoint data preserved
        XCTAssertEqual(result?.waypoints[0].name, "Start")
        XCTAssertEqual(result?.waypoints[0].type, .startPoint)
        XCTAssertEqual(result?.waypoints[0].elevationMeters, 1000)

        XCTAssertEqual(result?.waypoints[1].name, "End")
        XCTAssertEqual(result?.waypoints[1].type, .endPoint)
        XCTAssertEqual(result?.waypoints[1].elevationMeters, 2000)

        // Check coordinates
        XCTAssertEqual(result?.trackPoints[0].latitude, 40.0)
        XCTAssertEqual(result?.trackPoints[0].longitude, -74.0)
    }
}
