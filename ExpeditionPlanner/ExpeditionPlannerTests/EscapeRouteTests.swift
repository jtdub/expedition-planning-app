import XCTest
import SwiftData
@testable import Chaki

final class EscapeRouteTests: XCTestCase {

    // MARK: - Creation Tests

    func testEscapeRouteCreation() throws {
        let route = EscapeRoute(
            name: "River Crossing Bailout",
            routeType: .primary,
            segmentName: "Day 3-5 Ridge"
        )

        XCTAssertNotNil(route.id)
        XCTAssertEqual(route.name, "River Crossing Bailout")
        XCTAssertEqual(route.routeType, .primary)
        XCTAssertEqual(route.segmentName, "Day 3-5 Ridge")
    }

    func testEscapeRouteDefaultValues() throws {
        let route = EscapeRoute(name: "Test Route")

        XCTAssertEqual(route.routeType, .primary)
        XCTAssertEqual(route.difficultyRating, .moderate)
        XCTAssertEqual(route.destinationType, .trailhead)
        XCTAssertFalse(route.isVerified)
        XCTAssertTrue(route.routeDescription.isEmpty)
        XCTAssertTrue(route.hazards.isEmpty)
        XCTAssertNil(route.distanceMeters)
        XCTAssertNil(route.estimatedHours)
        XCTAssertNil(route.startDayNumber)
        XCTAssertNil(route.endDayNumber)
    }

    // MARK: - Computed Property Tests

    func testDistanceComputed() throws {
        let route = EscapeRoute(name: "Test")
        route.distanceMeters = 5000

        let distance = route.distance
        XCTAssertNotNil(distance)
        XCTAssertEqual(distance?.value, 5000)
        XCTAssertEqual(distance?.unit, .meters)
    }

    func testDistanceNilWhenNotSet() throws {
        let route = EscapeRoute(name: "Test")

        XCTAssertNil(route.distance)
    }

    func testFormattedEstimatedTimeHoursAndMinutes() throws {
        let route = EscapeRoute(name: "Test")
        route.estimatedHours = 6.5

        XCTAssertEqual(route.formattedEstimatedTime, "6h 30m")
    }

    func testFormattedEstimatedTimeWholeHours() throws {
        let route = EscapeRoute(name: "Test")
        route.estimatedHours = 3.0

        XCTAssertEqual(route.formattedEstimatedTime, "3h")
    }

    func testFormattedEstimatedTimeMinutesOnly() throws {
        let route = EscapeRoute(name: "Test")
        route.estimatedHours = 0.75

        XCTAssertEqual(route.formattedEstimatedTime, "45m")
    }

    func testFormattedEstimatedTimeNil() throws {
        let route = EscapeRoute(name: "Test")

        XCTAssertNil(route.formattedEstimatedTime)
    }

    func testDestinationCoordinate() throws {
        let route = EscapeRoute(name: "Test")
        route.destinationLatitude = 65.5
        route.destinationLongitude = -150.2

        let coord = route.destinationCoordinate
        XCTAssertNotNil(coord)
        XCTAssertEqual(coord?.latitude, 65.5)
        XCTAssertEqual(coord?.longitude, -150.2)
    }

    func testDayRangeDescriptionRange() throws {
        let route = EscapeRoute(name: "Test")
        route.startDayNumber = 3
        route.endDayNumber = 5

        XCTAssertEqual(route.dayRangeDescription, "Days 3-5")
    }

    func testDayRangeDescriptionSingleDay() throws {
        let route = EscapeRoute(name: "Test")
        route.startDayNumber = 7
        route.endDayNumber = 7

        XCTAssertEqual(route.dayRangeDescription, "Day 7")
    }

    func testDayRangeDescriptionStartOnly() throws {
        let route = EscapeRoute(name: "Test")
        route.startDayNumber = 4

        XCTAssertEqual(route.dayRangeDescription, "Day 4")
    }

    func testDayRangeDescriptionNil() throws {
        let route = EscapeRoute(name: "Test")

        XCTAssertNil(route.dayRangeDescription)
    }

    func testSortedWaypoints() throws {
        let route = EscapeRoute(name: "Test")
        let wp1 = EscapeWaypoint(name: "Second", orderIndex: 1)
        let wp2 = EscapeWaypoint(name: "First", orderIndex: 0)
        let wp3 = EscapeWaypoint(name: "Third", orderIndex: 2)
        route.waypoints = [wp1, wp2, wp3]

        let sorted = route.sortedWaypoints
        XCTAssertEqual(sorted[0].name, "First")
        XCTAssertEqual(sorted[1].name, "Second")
        XCTAssertEqual(sorted[2].name, "Third")
    }

    // MARK: - EscapeWaypoint Tests

    func testEscapeWaypointCreation() throws {
        let waypoint = EscapeWaypoint(name: "River Ford", orderIndex: 2)

        XCTAssertNotNil(waypoint.id)
        XCTAssertEqual(waypoint.name, "River Ford")
        XCTAssertEqual(waypoint.orderIndex, 2)
    }

    func testEscapeWaypointCoordinate() throws {
        let waypoint = EscapeWaypoint(name: "Test")
        waypoint.latitude = 64.8
        waypoint.longitude = -148.3

        let coord = waypoint.coordinate
        XCTAssertNotNil(coord)
        XCTAssertEqual(coord?.latitude, 64.8)
        XCTAssertEqual(coord?.longitude, -148.3)
    }

    func testEscapeWaypointElevation() throws {
        let waypoint = EscapeWaypoint(name: "Test")
        waypoint.elevationMeters = 1500

        let elevation = waypoint.elevation
        XCTAssertNotNil(elevation)
        XCTAssertEqual(elevation?.value, 1500)
        XCTAssertEqual(elevation?.unit, .meters)
    }

    // MARK: - Enum Tests

    func testEscapeRouteTypeProperties() throws {
        for type in EscapeRouteType.allCases {
            XCTAssertFalse(type.icon.isEmpty)
            XCTAssertFalse(type.color.isEmpty)
        }
    }

    func testEscapeRouteTypeSortOrder() throws {
        XCTAssertEqual(EscapeRouteType.primary.sortOrder, 0)
        XCTAssertEqual(EscapeRouteType.alternate.sortOrder, 1)
        XCTAssertEqual(EscapeRouteType.emergencyOnly.sortOrder, 2)
    }

    func testEscapeDestinationTypeProperties() throws {
        for type in EscapeDestinationType.allCases {
            XCTAssertFalse(type.icon.isEmpty)
        }
    }

    func testDifficultyRatingProperties() throws {
        for rating in DifficultyRating.allCases {
            XCTAssertFalse(rating.icon.isEmpty)
            XCTAssertFalse(rating.color.isEmpty)
        }
    }

    func testEscapeRouteTypeCaseCount() throws {
        XCTAssertEqual(EscapeRouteType.allCases.count, 3)
    }

    func testDestinationTypeCaseCount() throws {
        XCTAssertEqual(EscapeDestinationType.allCases.count, 8)
    }

    func testDifficultyRatingCaseCount() throws {
        XCTAssertEqual(DifficultyRating.allCases.count, 5)
    }

    // MARK: - Persistence Test

    @MainActor
    func testSwiftDataPersistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Expedition.self, EscapeRoute.self, EscapeWaypoint.self,
            configurations: config
        )
        let context = container.mainContext

        let expedition = Expedition(name: "Test Expedition")
        context.insert(expedition)

        let route = EscapeRoute(name: "Ridge Bailout", routeType: .primary)
        route.distanceMeters = 8000
        route.estimatedHours = 4.5
        route.destinationName = "Anaktuvuk Pass"
        route.expedition = expedition
        context.insert(route)

        let waypoint = EscapeWaypoint(name: "Saddle Pass", orderIndex: 0)
        waypoint.latitude = 68.1
        waypoint.longitude = -151.7
        waypoint.escapeRoute = route
        context.insert(waypoint)

        try context.save()

        let descriptor = FetchDescriptor<EscapeRoute>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Ridge Bailout")
        XCTAssertEqual(fetched.first?.distanceMeters, 8000)
        XCTAssertEqual(fetched.first?.waypoints?.count, 1)
        XCTAssertEqual(fetched.first?.waypoints?.first?.name, "Saddle Pass")
    }
}
