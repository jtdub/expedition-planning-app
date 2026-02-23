import Foundation
import SwiftData
import SwiftUI

enum AcclimatizationRisk: String, CaseIterable {
    case none = "None"
    case moderate = "Moderate"
    case high = "High"
    case extreme = "Extreme"

    var description: String {
        switch self {
        case .none:
            return "Safe altitude gain for the day"
        case .moderate:
            return "Slightly rapid ascent. Monitor for symptoms."
        case .high:
            return "Rapid ascent above 3000m. Consider adding rest day."
        case .extreme:
            return "Very rapid ascent. High risk of altitude sickness."
        }
    }

    var icon: String {
        switch self {
        case .none:
            return "checkmark.circle.fill"
        case .moderate:
            return "exclamationmark.triangle"
        case .high:
            return "exclamationmark.triangle.fill"
        case .extreme:
            return "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .none:
            return .green
        case .moderate:
            return .yellow
        case .high:
            return .orange
        case .extreme:
            return .red
        }
    }
}

struct ElevationService {
    // MARK: - Constants

    static let altitudeThreshold: Double = 3000 // meters
    static let safeGainPerDay: Double = 300 // meters
    static let moderateGainPerDay: Double = 500 // meters
    static let highGainPerDay: Double = 750 // meters
    static let metersPerFoot: Double = 0.3048
    static let feetPerMeter: Double = 3.28084

    // MARK: - Risk Assessment

    static func assessRisk(
        startElevationMeters: Double?,
        endElevationMeters: Double?
    ) -> AcclimatizationRisk {
        guard let start = startElevationMeters,
              let end = endElevationMeters else {
            return .none
        }

        let gain = end - start

        // Below threshold, no risk regardless of gain
        if end < altitudeThreshold {
            return .none
        }

        // Descending or flat, no risk
        if gain <= 0 {
            return .none
        }

        // Assess based on gain amount
        if gain <= safeGainPerDay {
            return .none
        } else if gain <= moderateGainPerDay {
            return .moderate
        } else if gain <= highGainPerDay {
            return .high
        } else {
            return .extreme
        }
    }

    static func assessRisk(for day: ItineraryDay) -> AcclimatizationRisk {
        assessRisk(
            startElevationMeters: day.startElevationMeters,
            endElevationMeters: day.endElevationMeters
        )
    }

    // MARK: - Unit Conversion

    static func metersToFeet(_ meters: Double) -> Double {
        meters * feetPerMeter
    }

    static func feetToMeters(_ feet: Double) -> Double {
        feet * metersPerFoot
    }

    static func convert(_ value: Double, from: ElevationUnit, to: ElevationUnit) -> Double {
        if from == to { return value }

        switch (from, to) {
        case (.meters, .feet):
            return metersToFeet(value)
        case (.feet, .meters):
            return feetToMeters(value)
        default:
            return value
        }
    }

    // MARK: - Display Helpers

    static func formatElevation(
        _ meters: Double?,
        unit: ElevationUnit
    ) -> String {
        guard let meters else { return "--" }

        let value: Double
        let unitSuffix: String

        switch unit {
        case .meters:
            value = meters
            unitSuffix = "m"
        case .feet:
            value = metersToFeet(meters)
            unitSuffix = "ft"
        }

        return String(format: "%.0f %@", value, unitSuffix)
    }

    static func formatElevationChange(
        _ meters: Double?,
        unit: ElevationUnit,
        showSign: Bool = true
    ) -> String {
        guard let meters else { return "--" }

        let value: Double
        let unitSuffix: String

        switch unit {
        case .meters:
            value = meters
            unitSuffix = "m"
        case .feet:
            value = metersToFeet(meters)
            unitSuffix = "ft"
        }

        if showSign && value > 0 {
            return String(format: "+%.0f %@", value, unitSuffix)
        } else {
            return String(format: "%.0f %@", value, unitSuffix)
        }
    }

    // MARK: - Recommendations

    static func recommendation(for risk: AcclimatizationRisk) -> String {
        switch risk {
        case .none:
            return "Continue as planned."
        case .moderate:
            return "Stay hydrated, watch for headache or nausea."
        case .high:
            return "Consider splitting into two days or adding acclimatization day."
        case .extreme:
            return "Strongly recommend revising itinerary. Add rest days or lower sleeping elevation."
        }
    }

    // MARK: - Chart Data

    struct ElevationPoint: Identifiable {
        let id = UUID()
        let dayNumber: Int
        let date: Date?
        let startElevation: Double?
        let endElevation: Double?
        let highPoint: Double?
        let lowPoint: Double?
        let activityType: ActivityType
        let risk: AcclimatizationRisk

        var displayElevation: Double {
            endElevation ?? startElevation ?? 0
        }
    }

    static func chartData(from days: [ItineraryDay]) -> [ElevationPoint] {
        days.map { day in
            ElevationPoint(
                dayNumber: day.dayNumber,
                date: day.date,
                startElevation: day.startElevationMeters,
                endElevation: day.endElevationMeters,
                highPoint: day.highPointMeters,
                lowPoint: day.lowPointMeters,
                activityType: day.activityType,
                risk: assessRisk(for: day)
            )
        }
    }

    // MARK: - Summary Statistics

    struct ElevationSummary {
        let totalGain: Double
        let totalLoss: Double
        let highestPoint: Double?
        let lowestPoint: Double?
        let startingElevation: Double?
        let endingElevation: Double?
        let daysWithRisk: Int
        let highRiskDays: Int
    }

    static func summary(from days: [ItineraryDay]) -> ElevationSummary {
        var totalGain: Double = 0
        var totalLoss: Double = 0
        var highestPoint: Double?
        var lowestPoint: Double?
        var daysWithRisk = 0
        var highRiskDays = 0

        let sortedDays = days.sorted { $0.dayNumber < $1.dayNumber }

        for day in sortedDays {
            // Calculate gain/loss
            if let start = day.startElevationMeters, let end = day.endElevationMeters {
                if end > start {
                    totalGain += (end - start)
                } else {
                    totalLoss += (start - end)
                }
            }

            // Track high/low points
            if let high = day.highPointMeters {
                if let current = highestPoint {
                    highestPoint = max(current, high)
                } else {
                    highestPoint = high
                }
            }
            if let end = day.endElevationMeters {
                if let current = highestPoint {
                    highestPoint = max(current, end)
                } else {
                    highestPoint = end
                }
            }

            if let low = day.lowPointMeters {
                if let current = lowestPoint {
                    lowestPoint = min(current, low)
                } else {
                    lowestPoint = low
                }
            }
            if let start = day.startElevationMeters {
                if let current = lowestPoint {
                    lowestPoint = min(current, start)
                } else {
                    lowestPoint = start
                }
            }

            // Count risk days
            let risk = assessRisk(for: day)
            if risk != .none {
                daysWithRisk += 1
            }
            if risk == .high || risk == .extreme {
                highRiskDays += 1
            }
        }

        return ElevationSummary(
            totalGain: totalGain,
            totalLoss: totalLoss,
            highestPoint: highestPoint,
            lowestPoint: lowestPoint,
            startingElevation: sortedDays.first?.startElevationMeters,
            endingElevation: sortedDays.last?.endElevationMeters,
            daysWithRisk: daysWithRisk,
            highRiskDays: highRiskDays
        )
    }
}
