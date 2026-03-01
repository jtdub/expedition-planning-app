import XCTest
import SwiftData
import CoreLocation
@testable import Chaki

final class ItineraryDayTests: XCTestCase {

    // MARK: - Creation Tests

    func testItineraryDayCreation() throws {
        let day = ItineraryDay(
            dayNumber: 1,
            date: Date(),
            location: "Kotzebue",
            startLocation: "Kotzebue Airport",
            endLocation: "Kotzebue Lodge",
            activityType: .domesticTravel,
            clientDescription: "Arrive in Kotzebue, check into lodge",
            guideNotes: "Pick up clients at 3pm, confirm gear transfer"
        )

        XCTAssertNotNil(day.id)
        XCTAssertEqual(day.dayNumber, 1)
        XCTAssertEqual(day.activityType, .domesticTravel)
        XCTAssertEqual(day.location, "Kotzebue")
    }

    func testItineraryDayDefaultValues() throws {
        let day = ItineraryDay(dayNumber: 5)

        XCTAssertEqual(day.dayNumber, 5)
        XCTAssertEqual(day.activityType, .fieldWork)
        XCTAssertTrue(day.location.isEmpty)
        XCTAssertNil(day.startElevationMeters)
        XCTAssertNil(day.endElevationMeters)
    }

    // MARK: - Elevation Tests

    func testElevationConversion() throws {
        let day = ItineraryDay(dayNumber: 1)
        day.startElevationMeters = 3000
        day.endElevationMeters = 3500

        XCTAssertEqual(day.startElevation?.value, 3000)
        XCTAssertEqual(day.startElevation?.unit, .meters)
        XCTAssertEqual(day.endElevation?.value, 3500)
    }

    func testElevationGain() throws {
        let day = ItineraryDay(dayNumber: 1)
        day.startElevationMeters = 3000
        day.endElevationMeters = 3500

        let gain = day.elevationGain
        XCTAssertNotNil(gain)
        XCTAssertEqual(gain?.value, 500)
    }

    func testElevationLoss() throws {
        let day = ItineraryDay(dayNumber: 1)
        day.startElevationMeters = 3500
        day.endElevationMeters = 3000

        let loss = day.elevationLoss
        XCTAssertNotNil(loss)
        XCTAssertEqual(loss?.value, 500)
    }

    func testNoElevationLossOnGain() throws {
        let day = ItineraryDay(dayNumber: 1)
        day.startElevationMeters = 3000
        day.endElevationMeters = 3500

        let loss = day.elevationLoss
        XCTAssertEqual(loss?.value, 0)
    }

    // MARK: - Acclimatization Tests

    func testAcclimatizationRiskDetection() throws {
        let day = ItineraryDay(dayNumber: 1)

        // Below threshold, should be false
        day.startElevationMeters = 2500
        day.endElevationMeters = 3000
        XCTAssertFalse(day.hasAcclimatizationRisk)

        // Above threshold but safe gain
        day.startElevationMeters = 3000
        day.endElevationMeters = 3400
        XCTAssertFalse(day.hasAcclimatizationRisk)

        // Above threshold with risky gain (>500m)
        day.startElevationMeters = 3000
        day.endElevationMeters = 3600
        XCTAssertTrue(day.hasAcclimatizationRisk)
    }

    func testAcclimatizationSafeAtLowAltitude() throws {
        let day = ItineraryDay(dayNumber: 1)
        day.startElevationMeters = 1000
        day.endElevationMeters = 2000

        // Even with 1000m gain, no risk below 3000m
        XCTAssertFalse(day.hasAcclimatizationRisk)
    }

    // MARK: - Coordinate Tests

    func testCoordinateConversion() throws {
        let day = ItineraryDay(dayNumber: 1)
        day.startLatitude = 67.5
        day.startLongitude = -162.5
        day.endLatitude = 67.6
        day.endLongitude = -162.4

        XCTAssertNotNil(day.startCoordinate)
        XCTAssertEqual(day.startCoordinate?.latitude, 67.5)
        XCTAssertEqual(day.startCoordinate?.longitude, -162.5)

        XCTAssertNotNil(day.endCoordinate)
    }

    func testNilCoordinatesWhenMissing() throws {
        let day = ItineraryDay(dayNumber: 1)

        XCTAssertNil(day.startCoordinate)
        XCTAssertNil(day.endCoordinate)
    }

    // MARK: - Activity Type Tests

    func testActivityTypeProperties() throws {
        XCTAssertEqual(ActivityType.internationalTravel.icon, "airplane")
        XCTAssertEqual(ActivityType.fieldWork.icon, "figure.hiking")
        XCTAssertEqual(ActivityType.restDay.icon, "bed.double")
        XCTAssertEqual(ActivityType.summit.icon, "mountain.2")

        XCTAssertEqual(ActivityType.acclimatization.color, .orange)
        XCTAssertEqual(ActivityType.fieldWork.color, .green)
    }

    func testAllActivityTypesCovered() throws {
        let allTypes = ActivityType.allCases
        XCTAssertEqual(allTypes.count, 8)

        for type in allTypes {
            XCTAssertFalse(type.icon.isEmpty)
            // Each activity type has a color (Color type, always non-nil)
            XCTAssertNotNil(type.color)
        }
    }
}
