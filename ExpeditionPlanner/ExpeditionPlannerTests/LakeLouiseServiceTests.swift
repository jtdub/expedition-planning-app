import XCTest
import SwiftData
@testable import ExpeditionPlanner

final class LakeLouiseServiceTests: XCTestCase {

    // MARK: - Score Calculation Tests

    func testCalculateTotalZero() {
        let total = LakeLouiseService.calculateTotal(
            headache: 0,
            gastrointestinal: 0,
            fatigue: 0,
            dizziness: 0
        )
        XCTAssertEqual(total, 0)
    }

    func testCalculateTotalMaximum() {
        let total = LakeLouiseService.calculateTotal(
            headache: 3,
            gastrointestinal: 3,
            fatigue: 3,
            dizziness: 3
        )
        XCTAssertEqual(total, 12)
    }

    func testCalculateTotalMixed() {
        let total = LakeLouiseService.calculateTotal(
            headache: 2,
            gastrointestinal: 1,
            fatigue: 1,
            dizziness: 0
        )
        XCTAssertEqual(total, 4)
    }

    // MARK: - Diagnosis Tests

    func testDiagnoseNoAMSWithoutHeadache() {
        // Even with high other symptoms, no headache = no AMS
        let diagnosis = LakeLouiseService.diagnose(
            headache: 0,
            gastrointestinal: 3,
            fatigue: 3,
            dizziness: 3
        )
        XCTAssertEqual(diagnosis, .noAMS)
    }

    func testDiagnoseNoAMSLowScore() {
        let diagnosis = LakeLouiseService.diagnose(
            headache: 1,
            gastrointestinal: 0,
            fatigue: 1,
            dizziness: 0
        )
        XCTAssertEqual(diagnosis, .noAMS)
    }

    func testDiagnoseMildAMS() {
        // Score 3-5 with headache = mild AMS
        let diagnosis = LakeLouiseService.diagnose(
            headache: 2,
            gastrointestinal: 1,
            fatigue: 1,
            dizziness: 0
        )
        XCTAssertEqual(diagnosis, .mildAMS)
    }

    func testDiagnoseMildAMSBoundary() {
        // Score exactly 3 with headache
        let diagnosis = LakeLouiseService.diagnose(
            headache: 1,
            gastrointestinal: 1,
            fatigue: 1,
            dizziness: 0
        )
        XCTAssertEqual(diagnosis, .mildAMS)
    }

    func testDiagnoseSevereAMS() {
        // Score 6+ with headache = severe AMS
        let diagnosis = LakeLouiseService.diagnose(
            headache: 2,
            gastrointestinal: 2,
            fatigue: 1,
            dizziness: 1
        )
        XCTAssertEqual(diagnosis, .severeAMS)
    }

    func testDiagnoseSevereAMSMaximum() {
        let diagnosis = LakeLouiseService.diagnose(
            headache: 3,
            gastrointestinal: 3,
            fatigue: 3,
            dizziness: 3
        )
        XCTAssertEqual(diagnosis, .severeAMS)
    }

    // MARK: - Severity Color Tests

    func testSeverityColorZero() {
        let color = LakeLouiseService.severityColor(for: 0)
        XCTAssertEqual(color, .green)
    }

    func testSeverityColorMild() {
        let color = LakeLouiseService.severityColor(for: 1)
        XCTAssertEqual(color, .yellow)
    }

    func testSeverityColorModerate() {
        let color = LakeLouiseService.severityColor(for: 2)
        XCTAssertEqual(color, .orange)
    }

    func testSeverityColorSevere() {
        let color = LakeLouiseService.severityColor(for: 3)
        XCTAssertEqual(color, .red)
    }

    // MARK: - Symptom Tests

    func testAllSymptomsHaveDescriptions() {
        for symptom in LakeLouiseService.Symptom.allCases {
            for score in 0...3 {
                let description = symptom.scoreDescription(score)
                XCTAssertFalse(description.isEmpty)
                XCTAssertNotEqual(description, "Unknown")
            }
        }
    }

    func testAllSymptomsHaveIcons() {
        for symptom in LakeLouiseService.Symptom.allCases {
            XCTAssertFalse(symptom.icon.isEmpty)
        }
    }

    // MARK: - Recommendation Tests

    func testActionRecommendationsExist() {
        let diagnoses: [LakeLouiseDiagnosis] = [.notRecorded, .noAMS, .mildAMS, .severeAMS]

        for diagnosis in diagnoses {
            let recommendations = LakeLouiseService.actionRecommendation(for: diagnosis)
            XCTAssertFalse(recommendations.isEmpty)
        }
    }

    func testSevereAMSHasDescentRecommendation() {
        let recommendations = LakeLouiseService.actionRecommendation(for: .severeAMS)
        let hasDescentAdvice = recommendations.contains { $0.uppercased().contains("DESCEND") }
        XCTAssertTrue(hasDescentAdvice)
    }

    // MARK: - Interpretation Tests

    func testTotalScoreInterpretationNoHeadache() {
        let interpretation = LakeLouiseService.totalScoreInterpretation(9, hasHeadache: false)
        XCTAssertTrue(interpretation.contains("No AMS"))
        XCTAssertTrue(interpretation.contains("headache required"))
    }

    func testTotalScoreInterpretationMild() {
        let interpretation = LakeLouiseService.totalScoreInterpretation(4, hasHeadache: true)
        XCTAssertTrue(interpretation.contains("Mild AMS"))
    }

    func testTotalScoreInterpretationSevere() {
        let interpretation = LakeLouiseService.totalScoreInterpretation(8, hasHeadache: true)
        XCTAssertTrue(interpretation.contains("Severe AMS"))
    }
}

// MARK: - ItineraryDay Lake Louise Extension Tests

final class ItineraryDayLakeLouiseTests: XCTestCase {

    func testHasLakeLouiseScoreFalseWhenEmpty() {
        let day = ItineraryDay(dayNumber: 1)
        XCTAssertFalse(day.hasLakeLouiseScore)
    }

    func testHasLakeLouiseScoreTrueWhenAnyValueSet() {
        let day = ItineraryDay(dayNumber: 1)
        day.llsHeadache = 1
        XCTAssertTrue(day.hasLakeLouiseScore)
    }

    func testLakeLouiseTotalNilWhenNoScore() {
        let day = ItineraryDay(dayNumber: 1)
        XCTAssertNil(day.lakeLouiseTotal)
    }

    func testLakeLouiseTotalCalculation() {
        let day = ItineraryDay(dayNumber: 1)
        day.llsHeadache = 2
        day.llsGastrointestinal = 1
        day.llsFatigue = 1
        day.llsDizziness = 0
        XCTAssertEqual(day.lakeLouiseTotal, 4)
    }

    func testLakeLouiseDiagnosisNotRecordedWhenEmpty() {
        let day = ItineraryDay(dayNumber: 1)
        XCTAssertEqual(day.lakeLouiseDiagnosis, .notRecorded)
    }

    func testLakeLouiseDiagnosisMildAMS() {
        let day = ItineraryDay(dayNumber: 1)
        day.llsHeadache = 2
        day.llsGastrointestinal = 1
        day.llsFatigue = 1
        day.llsDizziness = 0
        XCTAssertEqual(day.lakeLouiseDiagnosis, .mildAMS)
    }

    func testLakeLouiseDiagnosisSevereAMS() {
        let day = ItineraryDay(dayNumber: 1)
        day.llsHeadache = 3
        day.llsGastrointestinal = 2
        day.llsFatigue = 2
        day.llsDizziness = 1
        XCTAssertEqual(day.lakeLouiseDiagnosis, .severeAMS)
    }

    func testLakeLouiseDiagnosisNoAMSWithoutHeadache() {
        let day = ItineraryDay(dayNumber: 1)
        day.llsHeadache = 0
        day.llsGastrointestinal = 2
        day.llsFatigue = 2
        day.llsDizziness = 2
        XCTAssertEqual(day.lakeLouiseDiagnosis, .noAMS)
    }
}

// MARK: - LakeLouiseDiagnosis Tests

final class LakeLouiseDiagnosisTests: XCTestCase {

    func testAllDiagnosesHaveIcons() {
        let diagnoses: [LakeLouiseDiagnosis] = [.notRecorded, .noAMS, .mildAMS, .severeAMS]
        for diagnosis in diagnoses {
            XCTAssertFalse(diagnosis.icon.isEmpty)
        }
    }

    func testAllDiagnosesHaveColors() {
        let diagnoses: [LakeLouiseDiagnosis] = [.notRecorded, .noAMS, .mildAMS, .severeAMS]
        for diagnosis in diagnoses {
            XCTAssertNotNil(diagnosis.color)
        }
    }

    func testAllDiagnosesHaveRecommendations() {
        let diagnoses: [LakeLouiseDiagnosis] = [.notRecorded, .noAMS, .mildAMS, .severeAMS]
        for diagnosis in diagnoses {
            XCTAssertFalse(diagnosis.recommendation.isEmpty)
        }
    }

    func testSevereAMSRecommendationContainsDescent() {
        let recommendation = LakeLouiseDiagnosis.severeAMS.recommendation
        XCTAssertTrue(recommendation.uppercased().contains("DESCEND"))
    }
}
