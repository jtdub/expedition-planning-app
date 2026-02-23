import Foundation
import SwiftUI

/// Service for Lake Louise Acute Mountain Sickness (AMS) Score calculations
/// The Lake Louise Score is the standard diagnostic tool for AMS
struct LakeLouiseService {

    // MARK: - Symptom Definitions

    enum Symptom: String, CaseIterable, Identifiable {
        case headache = "Headache"
        case gastrointestinal = "GI Symptoms"
        case fatigue = "Fatigue/Weakness"
        case dizziness = "Dizziness"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .headache: return "brain.head.profile"
            case .gastrointestinal: return "stomach"
            case .fatigue: return "figure.walk"
            case .dizziness: return "tornado"
            }
        }

        func scoreDescription(_ score: Int) -> String {
            switch self {
            case .headache:
                return headacheDescription(score)
            case .gastrointestinal:
                return gastrointestinalDescription(score)
            case .fatigue:
                return fatigueDescription(score)
            case .dizziness:
                return dizzinessDescription(score)
            }
        }

        private func headacheDescription(_ score: Int) -> String {
            switch score {
            case 0: return "No headache"
            case 1: return "Mild headache"
            case 2: return "Moderate headache"
            case 3: return "Severe headache, incapacitating"
            default: return "Unknown"
            }
        }

        private func gastrointestinalDescription(_ score: Int) -> String {
            switch score {
            case 0: return "Good appetite"
            case 1: return "Poor appetite or nausea"
            case 2: return "Moderate nausea or vomiting"
            case 3: return "Severe nausea/vomiting, incapacitating"
            default: return "Unknown"
            }
        }

        private func fatigueDescription(_ score: Int) -> String {
            switch score {
            case 0: return "Not tired or weak"
            case 1: return "Mild fatigue/weakness"
            case 2: return "Moderate fatigue/weakness"
            case 3: return "Severe fatigue/weakness, incapacitating"
            default: return "Unknown"
            }
        }

        private func dizzinessDescription(_ score: Int) -> String {
            switch score {
            case 0: return "No dizziness"
            case 1: return "Mild dizziness"
            case 2: return "Moderate dizziness"
            case 3: return "Severe dizziness, incapacitating"
            default: return "Unknown"
            }
        }
    }

    // MARK: - Score Calculation

    static func calculateTotal(
        headache: Int,
        gastrointestinal: Int,
        fatigue: Int,
        dizziness: Int
    ) -> Int {
        headache + gastrointestinal + fatigue + dizziness
    }

    static func diagnose(
        headache: Int,
        gastrointestinal: Int,
        fatigue: Int,
        dizziness: Int
    ) -> LakeLouiseDiagnosis {
        let total = calculateTotal(
            headache: headache,
            gastrointestinal: gastrointestinal,
            fatigue: fatigue,
            dizziness: dizziness
        )

        // Headache is required for AMS diagnosis
        if headache == 0 {
            return .noAMS
        }

        if total >= 6 {
            return .severeAMS
        } else if total >= 3 {
            return .mildAMS
        } else {
            return .noAMS
        }
    }

    // MARK: - Severity Color

    static func severityColor(for score: Int) -> Color {
        switch score {
        case 0: return .green
        case 1: return .yellow
        case 2: return .orange
        case 3: return .red
        default: return .secondary
        }
    }

    // MARK: - Total Score Interpretation

    static func totalScoreInterpretation(_ total: Int, hasHeadache: Bool) -> String {
        if !hasHeadache {
            return "Score: \(total) - No AMS (headache required for diagnosis)"
        }

        switch total {
        case 0...2:
            return "Score: \(total) - No significant symptoms"
        case 3...5:
            return "Score: \(total) - Mild AMS"
        case 6...9:
            return "Score: \(total) - Moderate to Severe AMS"
        case 10...12:
            return "Score: \(total) - Severe AMS"
        default:
            return "Score: \(total)"
        }
    }

    // MARK: - Action Recommendations

    static func actionRecommendation(for diagnosis: LakeLouiseDiagnosis) -> [String] {
        switch diagnosis {
        case .notRecorded:
            return [
                "Record symptoms daily above 2500m",
                "Monitor all team members",
                "Establish baseline before ascent"
            ]
        case .noAMS:
            return [
                "Continue planned ascent",
                "Stay hydrated",
                "Monitor for symptom onset"
            ]
        case .mildAMS:
            return [
                "Do NOT ascend further",
                "Rest at current altitude",
                "Consider acetazolamide (Diamox)",
                "Use analgesics for headache",
                "Descend if symptoms worsen"
            ]
        case .severeAMS:
            return [
                "DESCEND IMMEDIATELY (minimum 500m)",
                "Administer oxygen if available",
                "Consider dexamethasone",
                "Do NOT leave person alone",
                "Evacuate to medical care"
            ]
        }
    }
}
