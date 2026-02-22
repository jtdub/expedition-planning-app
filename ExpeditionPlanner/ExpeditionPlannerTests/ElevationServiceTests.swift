import XCTest
@testable import ExpeditionPlanner

final class ElevationServiceTests: XCTestCase {

    // MARK: - Risk Assessment Tests

    func testNoRiskBelowThreshold() {
        // Below 3000m, no risk regardless of gain
        let risk = ElevationService.assessRisk(
            startElevationMeters: 1000,
            endElevationMeters: 2000
        )
        XCTAssertEqual(risk, .none)
    }

    func testNoRiskWhenDescending() {
        // Descending at altitude should have no risk
        let risk = ElevationService.assessRisk(
            startElevationMeters: 4000,
            endElevationMeters: 3500
        )
        XCTAssertEqual(risk, .none)
    }

    func testNoRiskForSmallGain() {
        // Small gain (<300m) above 3000m should be safe
        let risk = ElevationService.assessRisk(
            startElevationMeters: 3500,
            endElevationMeters: 3700
        )
        XCTAssertEqual(risk, .none)
    }

    func testModerateRiskForMediumGain() {
        // 300-500m gain above 3000m is moderate risk
        let risk = ElevationService.assessRisk(
            startElevationMeters: 3500,
            endElevationMeters: 3900
        )
        XCTAssertEqual(risk, .moderate)
    }

    func testHighRiskForLargeGain() {
        // 500-750m gain above 3000m is high risk
        let risk = ElevationService.assessRisk(
            startElevationMeters: 3500,
            endElevationMeters: 4100
        )
        XCTAssertEqual(risk, .high)
    }

    func testExtremeRiskForVeryLargeGain() {
        // >750m gain above 3000m is extreme risk
        let risk = ElevationService.assessRisk(
            startElevationMeters: 3500,
            endElevationMeters: 4500
        )
        XCTAssertEqual(risk, .extreme)
    }

    func testNilElevationsReturnNoRisk() {
        let risk1 = ElevationService.assessRisk(startElevationMeters: nil, endElevationMeters: 3500)
        XCTAssertEqual(risk1, .none)

        let risk2 = ElevationService.assessRisk(startElevationMeters: 3000, endElevationMeters: nil)
        XCTAssertEqual(risk2, .none)

        let risk3 = ElevationService.assessRisk(startElevationMeters: nil, endElevationMeters: nil)
        XCTAssertEqual(risk3, .none)
    }

    // MARK: - Unit Conversion Tests

    func testMetersToFeet() {
        let feet = ElevationService.metersToFeet(1000)
        XCTAssertEqual(feet, 3280.84, accuracy: 0.01)
    }

    func testFeetToMeters() {
        let meters = ElevationService.feetToMeters(3280.84)
        XCTAssertEqual(meters, 1000, accuracy: 0.01)
    }

    func testConvertSameUnit() {
        let value = ElevationService.convert(1000, from: .meters, to: .meters)
        XCTAssertEqual(value, 1000)

        let value2 = ElevationService.convert(3000, from: .feet, to: .feet)
        XCTAssertEqual(value2, 3000)
    }

    func testConvertMetersToFeet() {
        let feet = ElevationService.convert(1000, from: .meters, to: .feet)
        XCTAssertEqual(feet, 3280.84, accuracy: 0.01)
    }

    func testConvertFeetToMeters() {
        let meters = ElevationService.convert(3280.84, from: .feet, to: .meters)
        XCTAssertEqual(meters, 1000, accuracy: 0.01)
    }

    // MARK: - Formatting Tests

    func testFormatElevationMeters() {
        let formatted = ElevationService.formatElevation(3500, unit: .meters)
        XCTAssertEqual(formatted, "3500 m")
    }

    func testFormatElevationFeet() {
        let formatted = ElevationService.formatElevation(1000, unit: .feet)
        XCTAssertEqual(formatted, "3281 ft")
    }

    func testFormatNilElevation() {
        let formatted = ElevationService.formatElevation(nil, unit: .meters)
        XCTAssertEqual(formatted, "--")
    }

    func testFormatElevationChangePositive() {
        let formatted = ElevationService.formatElevationChange(500, unit: .meters, showSign: true)
        XCTAssertEqual(formatted, "+500 m")
    }

    func testFormatElevationChangeNoSign() {
        let formatted = ElevationService.formatElevationChange(500, unit: .meters, showSign: false)
        XCTAssertEqual(formatted, "500 m")
    }

    // MARK: - Summary Tests

    func testElevationSummaryEmpty() {
        let summary = ElevationService.summary(from: [])

        XCTAssertEqual(summary.totalGain, 0)
        XCTAssertEqual(summary.totalLoss, 0)
        XCTAssertNil(summary.highestPoint)
        XCTAssertNil(summary.lowestPoint)
        XCTAssertEqual(summary.daysWithRisk, 0)
        XCTAssertEqual(summary.highRiskDays, 0)
    }

    func testElevationSummaryWithDays() {
        let day1 = ItineraryDay(dayNumber: 1)
        day1.startElevationMeters = 3000
        day1.endElevationMeters = 3500

        let day2 = ItineraryDay(dayNumber: 2)
        day2.startElevationMeters = 3500
        day2.endElevationMeters = 4200
        day2.highPointMeters = 4300

        let day3 = ItineraryDay(dayNumber: 3)
        day3.startElevationMeters = 4200
        day3.endElevationMeters = 3800

        let summary = ElevationService.summary(from: [day1, day2, day3])

        XCTAssertEqual(summary.totalGain, 1200) // 500 + 700
        XCTAssertEqual(summary.totalLoss, 400) // 400
        XCTAssertEqual(summary.highestPoint, 4300)
        XCTAssertEqual(summary.lowestPoint, 3000)
        XCTAssertEqual(summary.startingElevation, 3000)
        XCTAssertEqual(summary.endingElevation, 3800)
        XCTAssertEqual(summary.daysWithRisk, 2) // day1 moderate, day2 high
        XCTAssertEqual(summary.highRiskDays, 1) // day2 only
    }

    // MARK: - Chart Data Tests

    func testChartDataGeneration() {
        let day1 = ItineraryDay(dayNumber: 1, activityType: .fieldWork)
        day1.startElevationMeters = 3000
        day1.endElevationMeters = 3400

        let day2 = ItineraryDay(dayNumber: 2, activityType: .restDay)
        day2.startElevationMeters = 3400
        day2.endElevationMeters = 3400

        let chartData = ElevationService.chartData(from: [day1, day2])

        XCTAssertEqual(chartData.count, 2)
        XCTAssertEqual(chartData[0].dayNumber, 1)
        XCTAssertEqual(chartData[0].activityType, .fieldWork)
        XCTAssertEqual(chartData[0].risk, .moderate)
        XCTAssertEqual(chartData[1].activityType, .restDay)
        XCTAssertEqual(chartData[1].risk, .none)
    }

    // MARK: - Risk Enum Tests

    func testAcclimatizationRiskProperties() {
        XCTAssertFalse(AcclimatizationRisk.none.description.isEmpty)
        XCTAssertFalse(AcclimatizationRisk.moderate.icon.isEmpty)
        XCTAssertNotNil(AcclimatizationRisk.high.color)
        XCTAssertFalse(AcclimatizationRisk.extreme.description.isEmpty)
    }

    func testRecommendations() {
        let noneRec = ElevationService.recommendation(for: .none)
        XCTAssertTrue(noneRec.contains("Continue"))

        let moderateRec = ElevationService.recommendation(for: .moderate)
        XCTAssertTrue(moderateRec.contains("hydrated") || moderateRec.contains("watch"))

        let highRec = ElevationService.recommendation(for: .high)
        XCTAssertTrue(highRec.contains("split") || highRec.contains("acclimatization"))

        let extremeRec = ElevationService.recommendation(for: .extreme)
        XCTAssertTrue(extremeRec.contains("recommend") || extremeRec.contains("revising"))
    }
}
