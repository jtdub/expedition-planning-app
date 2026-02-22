import XCTest
import SwiftData
@testable import ExpeditionPlanner

final class RiskAssessmentTests: XCTestCase {

    // MARK: - Creation Tests

    func testRiskAssessmentCreation() throws {
        let risk = RiskAssessment(
            title: "Bear Encounter",
            hazardType: .wildlife,
            likelihood: .medium,
            severity: .high
        )

        XCTAssertNotNil(risk.id)
        XCTAssertEqual(risk.title, "Bear Encounter")
        XCTAssertEqual(risk.hazardType, .wildlife)
        XCTAssertEqual(risk.likelihood, .medium)
        XCTAssertEqual(risk.severity, .high)
    }

    func testRiskAssessmentDefaultValues() throws {
        let risk = RiskAssessment(title: "Test Risk")

        XCTAssertEqual(risk.hazardType, .terrain)
        XCTAssertEqual(risk.likelihood, .medium)
        XCTAssertEqual(risk.severity, .medium)
        XCTAssertFalse(risk.isAddressed)
        XCTAssertTrue(risk.mitigationStrategy.isEmpty)
    }

    // MARK: - Risk Score Tests

    func testRiskScoreCalculation() throws {
        let risk = RiskAssessment(title: "Test")

        risk.likelihood = .low
        risk.severity = .low
        XCTAssertEqual(risk.riskScore, 4) // 2 * 2

        risk.likelihood = .medium
        risk.severity = .medium
        XCTAssertEqual(risk.riskScore, 9) // 3 * 3

        risk.likelihood = .high
        risk.severity = .high
        XCTAssertEqual(risk.riskScore, 16) // 4 * 4

        risk.likelihood = .veryHigh
        risk.severity = .veryHigh
        XCTAssertEqual(risk.riskScore, 25) // 5 * 5
    }

    func testRiskRatingFromScore() throws {
        let risk = RiskAssessment(title: "Test")

        // Low risk (1-3)
        risk.likelihood = .veryLow
        risk.severity = .veryLow
        XCTAssertEqual(risk.riskRating, .low)

        // Medium risk (4-6)
        risk.likelihood = .low
        risk.severity = .low
        XCTAssertEqual(risk.riskRating, .medium)

        // High risk (7-12)
        risk.likelihood = .medium
        risk.severity = .high
        XCTAssertEqual(risk.riskRating, .high)

        // Critical risk (>12)
        risk.likelihood = .high
        risk.severity = .high
        XCTAssertEqual(risk.riskRating, .critical)
    }

    // MARK: - Needs Attention Tests

    func testNeedsAttentionForHighUnaddressedRisk() throws {
        let risk = RiskAssessment(title: "Test", likelihood: .high, severity: .high)
        risk.isAddressed = false

        XCTAssertTrue(risk.needsAttention)
    }

    func testNoAttentionNeededWhenAddressed() throws {
        let risk = RiskAssessment(title: "Test", likelihood: .high, severity: .high)
        risk.isAddressed = true

        XCTAssertFalse(risk.needsAttention)
    }

    func testNoAttentionNeededForLowRisk() throws {
        let risk = RiskAssessment(title: "Test", likelihood: .veryLow, severity: .low)
        risk.isAddressed = false

        XCTAssertFalse(risk.needsAttention)
    }

    // MARK: - Hazard Type Tests

    func testAllHazardTypesCovered() throws {
        let allTypes = HazardType.allCases
        XCTAssertEqual(allTypes.count, 10)

        for type in allTypes {
            XCTAssertFalse(type.icon.isEmpty)
        }
    }

    func testHazardTypeIcons() throws {
        XCTAssertEqual(HazardType.wildlife.icon, "pawprint")
        XCTAssertEqual(HazardType.weather.icon, "cloud.bolt")
        XCTAssertEqual(HazardType.altitude.icon, "arrow.up.to.line")
        XCTAssertEqual(HazardType.avalanche.icon, "snow")
    }

    // MARK: - Risk Level Tests

    func testRiskLevelValues() throws {
        XCTAssertEqual(RiskLevel.veryLow.value, 1)
        XCTAssertEqual(RiskLevel.low.value, 2)
        XCTAssertEqual(RiskLevel.medium.value, 3)
        XCTAssertEqual(RiskLevel.high.value, 4)
        XCTAssertEqual(RiskLevel.veryHigh.value, 5)
    }

    // MARK: - Risk Rating Tests

    func testRiskRatingProperties() throws {
        XCTAssertEqual(RiskRating.low.color, "green")
        XCTAssertEqual(RiskRating.medium.color, "yellow")
        XCTAssertEqual(RiskRating.high.color, "orange")
        XCTAssertEqual(RiskRating.critical.color, "red")

        XCTAssertEqual(RiskRating.critical.icon, "exclamationmark.triangle.fill")
    }
}
