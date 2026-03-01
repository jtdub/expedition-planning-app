import XCTest
import CoreLocation
@testable import Chaki

final class RouteServiceTests: XCTestCase {

    // MARK: - Waypoint Type Tests

    func testWaypointTypeIcons() {
        for type in WaypointType.allCases {
            XCTAssertFalse(type.icon.isEmpty, "\(type) should have an icon")
        }
    }

    func testWaypointTypeColors() {
        for type in WaypointType.allCases {
            // Just verify it doesn't crash
            _ = type.color
        }
    }

    func testWaypointTypeSortOrder() {
        // Start should come before end
        XCTAssertLessThan(WaypointType.startPoint.sortOrder, WaypointType.endPoint.sortOrder)
        // End should come before summit
        XCTAssertLessThan(WaypointType.endPoint.sortOrder, WaypointType.summit.sortOrder)
    }

    // MARK: - Route Waypoint Tests

    func testRouteWaypointEquality() {
        let id = UUID()
        let waypoint1 = RouteWaypoint(
            id: id,
            coordinate: CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0),
            name: "Test",
            type: .waypoint,
            sourceId: UUID()
        )
        let waypoint2 = RouteWaypoint(
            id: id,
            coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: -73.0),
            name: "Different",
            type: .campsite,
            sourceId: UUID()
        )

        // Same ID means equal
        XCTAssertEqual(waypoint1, waypoint2)
    }

    func testRouteWaypointHashable() {
        let waypoint1 = RouteWaypoint(
            coordinate: CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0),
            name: "Test1",
            type: .waypoint,
            sourceId: UUID()
        )
        let waypoint2 = RouteWaypoint(
            coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: -73.0),
            name: "Test2",
            type: .campsite,
            sourceId: UUID()
        )

        var set = Set<RouteWaypoint>()
        set.insert(waypoint1)
        set.insert(waypoint2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Waypoint Extraction from Itinerary Tests

    func testExtractWaypointsFromEmptyItinerary() {
        let emptyDays: [ItineraryDay] = []
        let waypoints = RouteService.extractWaypoints(from: emptyDays)
        XCTAssertTrue(waypoints.isEmpty)
    }

    func testExtractWaypointsFromSingleDay() {
        let day = ItineraryDay(dayNumber: 1)
        day.startLocation = "Trailhead"
        day.endLocation = "Camp 1"
        day.startLatitude = 40.0
        day.startLongitude = -74.0
        day.endLatitude = 40.5
        day.endLongitude = -73.5
        day.startElevationMeters = 1000
        day.endElevationMeters = 2000

        let waypoints = RouteService.extractWaypoints(from: [day])

        // Should have start and end points
        XCTAssertEqual(waypoints.count, 2)

        // First should be start point
        XCTAssertEqual(waypoints[0].name, "Trailhead")
        XCTAssertEqual(waypoints[0].type, .startPoint)
        XCTAssertEqual(waypoints[0].elevationMeters, 1000)

        // Last should be end point (since it's the only day)
        XCTAssertEqual(waypoints[1].name, "Camp 1")
        XCTAssertEqual(waypoints[1].type, .endPoint)
        XCTAssertEqual(waypoints[1].elevationMeters, 2000)
    }

    func testExtractWaypointsMultipleDays() {
        let day1 = ItineraryDay(dayNumber: 1)
        day1.startLocation = "Trailhead"
        day1.endLocation = "Camp 1"
        day1.campName = "First Camp"
        day1.startLatitude = 40.0
        day1.startLongitude = -74.0
        day1.endLatitude = 40.5
        day1.endLongitude = -73.5

        let day2 = ItineraryDay(dayNumber: 2)
        day2.endLocation = "Camp 2"
        day2.endLatitude = 41.0
        day2.endLongitude = -73.0
        day2.campName = "Second Camp"

        let day3 = ItineraryDay(dayNumber: 3)
        day3.endLocation = "End"
        day3.endLatitude = 41.5
        day3.endLongitude = -72.5

        let waypoints = RouteService.extractWaypoints(from: [day1, day2, day3])

        // Should have: start (1), camp1 end (1), camp2 end (2), end (3)
        XCTAssertEqual(waypoints.count, 4)

        XCTAssertEqual(waypoints[0].type, .startPoint)
        XCTAssertEqual(waypoints[1].type, .campsite) // Has campName
        XCTAssertEqual(waypoints[2].type, .campsite) // Has campName
        XCTAssertEqual(waypoints[3].type, .endPoint) // Last day
    }

    func testExtractSummitWaypoint() {
        let day = ItineraryDay(dayNumber: 1, activityType: .summit)
        day.endLocation = "Peak"
        day.endLatitude = 40.0
        day.endLongitude = -74.0

        let day2 = ItineraryDay(dayNumber: 2)
        day2.endLocation = "End"
        day2.endLatitude = 41.0
        day2.endLongitude = -73.0

        let waypoints = RouteService.extractWaypoints(from: [day, day2])

        // First end should be summit type
        let summitWaypoint = waypoints.first { $0.name == "Peak" }
        XCTAssertEqual(summitWaypoint?.type, .summit)
    }

    // MARK: - Waypoint Extraction from Resupply Points

    func testExtractWaypointsFromResupplyPoints() {
        let resupply1 = ResupplyPoint(name: "Coldfoot")
        resupply1.latitude = 67.25
        resupply1.longitude = -150.17
        resupply1.elevationMeters = 300
        resupply1.dayNumber = 5
        resupply1.hasPostOffice = true
        resupply1.hasGroceries = true

        let resupply2 = ResupplyPoint(name: "Circle City")
        resupply2.latitude = 65.82
        resupply2.longitude = -144.06

        let waypoints = RouteService.extractWaypoints(from: [resupply1, resupply2])

        XCTAssertEqual(waypoints.count, 2)
        XCTAssertEqual(waypoints[0].type, .resupply)
        XCTAssertEqual(waypoints[0].name, "Coldfoot")
        XCTAssertEqual(waypoints[0].elevationMeters, 300)
        XCTAssertEqual(waypoints[0].dayNumber, 5)
        XCTAssertTrue(waypoints[0].notes?.contains("Post Office") ?? false)
    }

    func testExtractResupplyWithoutCoordinates() {
        let resupply = ResupplyPoint(name: "No Location")
        // No coordinates set

        let waypoints = RouteService.extractWaypoints(from: [resupply])

        // Should be filtered out
        XCTAssertTrue(waypoints.isEmpty)
    }

    // MARK: - Route Building Tests

    func testBuildRouteEmpty() {
        let route = RouteService.buildRoute(from: [])
        XCTAssertTrue(route.isEmpty)
    }

    func testBuildRouteFromDays() {
        let day1 = ItineraryDay(dayNumber: 1)
        day1.startLatitude = 40.0
        day1.startLongitude = -74.0
        day1.endLatitude = 40.5
        day1.endLongitude = -73.5

        let day2 = ItineraryDay(dayNumber: 2)
        day2.endLatitude = 41.0
        day2.endLongitude = -73.0

        let route = RouteService.buildRoute(from: [day1, day2])

        XCTAssertEqual(route.count, 3)
        XCTAssertEqual(route[0].latitude, 40.0)
        XCTAssertEqual(route[1].latitude, 40.5)
        XCTAssertEqual(route[2].latitude, 41.0)
    }

    func testBuildRouteRemovesDuplicates() {
        let day1 = ItineraryDay(dayNumber: 1)
        day1.startLatitude = 40.0
        day1.startLongitude = -74.0
        day1.endLatitude = 40.5
        day1.endLongitude = -73.5

        let day2 = ItineraryDay(dayNumber: 2)
        // Start same as day1 end
        day2.startLatitude = 40.5
        day2.startLongitude = -73.5
        day2.endLatitude = 41.0
        day2.endLongitude = -73.0

        let route = RouteService.buildRoute(from: [day1, day2])

        // Should not duplicate the connection point
        XCTAssertEqual(route.count, 3)
    }

    // MARK: - Statistics Tests

    func testRouteStatistics() {
        let waypoints = [
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0),
                name: "Start",
                type: .startPoint,
                elevationMeters: 1000,
                sourceId: UUID()
            ),
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 40.5, longitude: -73.5),
                name: "Camp",
                type: .campsite,
                elevationMeters: 2000,
                sourceId: UUID()
            ),
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: -73.0),
                name: "Summit",
                type: .summit,
                elevationMeters: 3000,
                sourceId: UUID()
            ),
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 41.5, longitude: -72.5),
                name: "End",
                type: .endPoint,
                elevationMeters: 1500,
                sourceId: UUID()
            )
        ]

        let route = waypoints.map { $0.coordinate }
        let stats = RouteService.statistics(waypoints: waypoints, route: route)

        XCTAssertEqual(stats.waypointCount, 4)
        XCTAssertEqual(stats.campsiteCount, 1)
        XCTAssertEqual(stats.summitCount, 1)
        XCTAssertEqual(stats.highestElevationMeters, 3000)
        XCTAssertEqual(stats.lowestElevationMeters, 1000)
        XCTAssertGreaterThan(stats.totalDistanceMeters, 0)
    }

    // MARK: - Filtering Tests

    func testFilterByType() {
        let waypoints = [
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0),
                name: "Start",
                type: .startPoint,
                sourceId: UUID()
            ),
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 40.5, longitude: -73.5),
                name: "Camp",
                type: .campsite,
                sourceId: UUID()
            ),
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: -73.0),
                name: "Supply",
                type: .resupply,
                sourceId: UUID()
            )
        ]

        let campsitesOnly = RouteService.filter(waypoints: waypoints, by: [.campsite])
        XCTAssertEqual(campsitesOnly.count, 1)
        XCTAssertEqual(campsitesOnly[0].name, "Camp")

        let multipleTypes = RouteService.filter(waypoints: waypoints, by: [.startPoint, .resupply])
        XCTAssertEqual(multipleTypes.count, 2)

        let empty = RouteService.filter(waypoints: waypoints, by: [])
        XCTAssertEqual(empty.count, 3) // Empty set returns all
    }

    func testFilterByDayRange() {
        let waypoints = [
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 40.0, longitude: -74.0),
                name: "Day 1",
                type: .waypoint,
                dayNumber: 1,
                sourceId: UUID()
            ),
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 40.5, longitude: -73.5),
                name: "Day 3",
                type: .waypoint,
                dayNumber: 3,
                sourceId: UUID()
            ),
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: -73.0),
                name: "Day 5",
                type: .waypoint,
                dayNumber: 5,
                sourceId: UUID()
            ),
            RouteWaypoint(
                coordinate: CLLocationCoordinate2D(latitude: 41.5, longitude: -72.5),
                name: "No Day",
                type: .waypoint,
                sourceId: UUID()
            )
        ]

        let days2to4 = RouteService.filter(waypoints: waypoints, fromDay: 2, toDay: 4)
        XCTAssertEqual(days2to4.count, 2) // Day 3 + No Day (included because no day number)

        let fromDay3 = RouteService.filter(waypoints: waypoints, fromDay: 3, toDay: nil)
        XCTAssertEqual(fromDay3.count, 3) // Day 3, Day 5, No Day

        let toDay3 = RouteService.filter(waypoints: waypoints, fromDay: nil, toDay: 3)
        XCTAssertEqual(toDay3.count, 3) // Day 1, Day 3, No Day
    }
}
