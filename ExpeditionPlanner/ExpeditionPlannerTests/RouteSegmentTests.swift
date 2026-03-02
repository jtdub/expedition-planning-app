import XCTest
import SwiftData
@testable import Chaki

final class RouteSegmentTests: XCTestCase {

    // MARK: - Creation Tests

    func testRouteSegmentCreation() throws {
        let segment = RouteSegment(
            name: "Anaktuvuk Ridge",
            terrainType: .ridgeline,
            difficultyRating: .strenuous
        )

        XCTAssertNotNil(segment.id)
        XCTAssertEqual(segment.name, "Anaktuvuk Ridge")
        XCTAssertEqual(segment.terrainType, .ridgeline)
        XCTAssertEqual(segment.difficultyRating, .strenuous)
    }

    func testRouteSegmentDefaultValues() throws {
        let segment = RouteSegment(name: "Test Segment")

        XCTAssertEqual(segment.terrainType, .tundra)
        XCTAssertEqual(segment.difficultyRating, .moderate)
        XCTAssertTrue(segment.terrainDescription.isEmpty)
        XCTAssertTrue(segment.hazards.isEmpty)
        XCTAssertTrue(segment.navigationNotes.isEmpty)
        XCTAssertTrue(segment.notes.isEmpty)
        XCTAssertNil(segment.distanceMeters)
        XCTAssertNil(segment.estimatedHours)
        XCTAssertNil(segment.startDayNumber)
        XCTAssertNil(segment.endDayNumber)
        XCTAssertNil(segment.elevationGainMeters)
        XCTAssertNil(segment.elevationLossMeters)
    }

    // MARK: - Computed Property Tests

    func testDistanceComputed() throws {
        let segment = RouteSegment(name: "Test")
        segment.distanceMeters = 12000

        let distance = segment.distance
        XCTAssertNotNil(distance)
        XCTAssertEqual(distance?.value, 12000)
        XCTAssertEqual(distance?.unit, .meters)
    }

    func testDistanceNilWhenNotSet() throws {
        let segment = RouteSegment(name: "Test")
        XCTAssertNil(segment.distance)
    }

    func testElevationGainComputed() throws {
        let segment = RouteSegment(name: "Test")
        segment.elevationGainMeters = 800

        let gain = segment.elevationGain
        XCTAssertNotNil(gain)
        XCTAssertEqual(gain?.value, 800)
        XCTAssertEqual(gain?.unit, .meters)
    }

    func testElevationLossComputed() throws {
        let segment = RouteSegment(name: "Test")
        segment.elevationLossMeters = 500

        let loss = segment.elevationLoss
        XCTAssertNotNil(loss)
        XCTAssertEqual(loss?.value, 500)
        XCTAssertEqual(loss?.unit, .meters)
    }

    func testFormattedEstimatedTimeHoursAndMinutes() throws {
        let segment = RouteSegment(name: "Test")
        segment.estimatedHours = 7.5

        XCTAssertEqual(segment.formattedEstimatedTime, "7h 30m")
    }

    func testFormattedEstimatedTimeWholeHours() throws {
        let segment = RouteSegment(name: "Test")
        segment.estimatedHours = 4.0

        XCTAssertEqual(segment.formattedEstimatedTime, "4h")
    }

    func testFormattedEstimatedTimeMinutesOnly() throws {
        let segment = RouteSegment(name: "Test")
        segment.estimatedHours = 0.5

        XCTAssertEqual(segment.formattedEstimatedTime, "30m")
    }

    func testFormattedEstimatedTimeNil() throws {
        let segment = RouteSegment(name: "Test")
        XCTAssertNil(segment.formattedEstimatedTime)
    }

    func testDayRangeDescriptionRange() throws {
        let segment = RouteSegment(name: "Test")
        segment.startDayNumber = 2
        segment.endDayNumber = 4

        XCTAssertEqual(segment.dayRangeDescription, "Days 2-4")
    }

    func testDayRangeDescriptionSingleDay() throws {
        let segment = RouteSegment(name: "Test")
        segment.startDayNumber = 5
        segment.endDayNumber = 5

        XCTAssertEqual(segment.dayRangeDescription, "Day 5")
    }

    func testDayRangeDescriptionStartOnly() throws {
        let segment = RouteSegment(name: "Test")
        segment.startDayNumber = 3

        XCTAssertEqual(segment.dayRangeDescription, "Day 3")
    }

    func testDayRangeDescriptionNil() throws {
        let segment = RouteSegment(name: "Test")
        XCTAssertNil(segment.dayRangeDescription)
    }

    // MARK: - Enum Tests

    func testTerrainTypeProperties() throws {
        for terrain in TerrainType.allCases {
            XCTAssertFalse(terrain.icon.isEmpty)
            XCTAssertFalse(terrain.color.isEmpty)
        }
    }

    func testTerrainTypeCaseCount() throws {
        XCTAssertEqual(TerrainType.allCases.count, 11)
    }

    func testDifficultyRatingReuse() throws {
        // Verify DifficultyRating is shared with EscapeRoute
        for rating in DifficultyRating.allCases {
            XCTAssertFalse(rating.icon.isEmpty)
            XCTAssertFalse(rating.color.isEmpty)
        }
    }

    // MARK: - Persistence Test

    @MainActor
    func testSwiftDataPersistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Expedition.self, RouteSegment.self,
            configurations: config
        )
        let context = container.mainContext

        let expedition = Expedition(name: "Test Expedition")
        context.insert(expedition)

        let segment = RouteSegment(name: "Tundra Traverse", terrainType: .tundra)
        segment.distanceMeters = 15000
        segment.estimatedHours = 8.5
        segment.elevationGainMeters = 600
        segment.expedition = expedition
        context.insert(segment)

        try context.save()

        let descriptor = FetchDescriptor<RouteSegment>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Tundra Traverse")
        XCTAssertEqual(fetched.first?.distanceMeters, 15000)
        XCTAssertEqual(fetched.first?.terrainType, .tundra)
    }
}
