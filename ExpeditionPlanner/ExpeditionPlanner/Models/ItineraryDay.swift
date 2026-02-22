import Foundation
import SwiftData
import CoreLocation
import SwiftUI

@Model
final class ItineraryDay {
    var id: UUID = UUID()
    var dayNumber: Int = 0
    var date: Date?
    var location: String = ""
    var startLocation: String = ""
    var endLocation: String = ""

    // Elevation tracking
    var startElevationMeters: Double?
    var endElevationMeters: Double?
    var highPointMeters: Double?
    var lowPointMeters: Double?

    // Activity and description
    var activityType: ActivityType = ActivityType.fieldWork
    var clientDescription: String = ""
    var guideNotes: String = ""

    // Coordinates
    var startLatitude: Double?
    var startLongitude: Double?
    var endLatitude: Double?
    var endLongitude: Double?

    // Distance and timing
    var distanceMeters: Double?
    var estimatedHours: Double?

    // Night tracking
    var nightNumber: Int?
    var campName: String?

    // Visual
    var colorCode: String?

    // Lake Louise Score (AMS tracking)
    // Each symptom scored 0-3, total 0-12
    var llsHeadache: Int?
    var llsGastrointestinal: Int?
    var llsFatigue: Int?
    var llsDizziness: Int?
    var llsRecordedAt: Date?

    // Relationship - must be optional for CloudKit
    var expedition: Expedition?

    init(
        dayNumber: Int = 0,
        date: Date? = nil,
        location: String = "",
        startLocation: String = "",
        endLocation: String = "",
        activityType: ActivityType = .fieldWork,
        clientDescription: String = "",
        guideNotes: String = ""
    ) {
        self.id = UUID()
        self.dayNumber = dayNumber
        self.date = date
        self.location = location
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.activityType = activityType
        self.clientDescription = clientDescription
        self.guideNotes = guideNotes
    }

    // MARK: - Computed Properties

    var startElevation: Measurement<UnitLength>? {
        guard let meters = startElevationMeters else { return nil }
        return Measurement(value: meters, unit: .meters)
    }

    var endElevation: Measurement<UnitLength>? {
        guard let meters = endElevationMeters else { return nil }
        return Measurement(value: meters, unit: .meters)
    }

    var elevationGain: Measurement<UnitLength>? {
        guard let start = startElevationMeters, let end = endElevationMeters else { return nil }
        let gain = max(0, end - start)
        return Measurement(value: gain, unit: .meters)
    }

    var elevationLoss: Measurement<UnitLength>? {
        guard let start = startElevationMeters, let end = endElevationMeters else { return nil }
        let loss = max(0, start - end)
        return Measurement(value: loss, unit: .meters)
    }

    var distance: Measurement<UnitLength>? {
        guard let meters = distanceMeters else { return nil }
        return Measurement(value: meters, unit: .meters)
    }

    var startCoordinate: CLLocationCoordinate2D? {
        guard let lat = startLatitude, let lon = startLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var endCoordinate: CLLocationCoordinate2D? {
        guard let lat = endLatitude, let lon = endLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    // Acclimatization check: >500m gain above 3000m is concerning
    var hasAcclimatizationRisk: Bool {
        guard let endMeters = endElevationMeters,
              let startMeters = startElevationMeters,
              endMeters > 3000 else { return false }
        return (endMeters - startMeters) > 500
    }

    // MARK: - Lake Louise Score

    var hasLakeLouiseScore: Bool {
        llsHeadache != nil || llsGastrointestinal != nil ||
        llsFatigue != nil || llsDizziness != nil
    }

    var lakeLouiseTotal: Int? {
        guard hasLakeLouiseScore else { return nil }
        return (llsHeadache ?? 0) + (llsGastrointestinal ?? 0) +
               (llsFatigue ?? 0) + (llsDizziness ?? 0)
    }

    var lakeLouiseDiagnosis: LakeLouiseDiagnosis {
        guard let total = lakeLouiseTotal else { return .notRecorded }
        let hasHeadache = (llsHeadache ?? 0) > 0

        if !hasHeadache {
            return .noAMS
        } else if total >= 6 {
            return .severeAMS
        } else if total >= 3 {
            return .mildAMS
        } else {
            return .noAMS
        }
    }
}

// MARK: - Lake Louise Diagnosis

enum LakeLouiseDiagnosis: String, Codable {
    case notRecorded = "Not Recorded"
    case noAMS = "No AMS"
    case mildAMS = "Mild AMS"
    case severeAMS = "Severe AMS"

    var icon: String {
        switch self {
        case .notRecorded: return "pencil.slash"
        case .noAMS: return "checkmark.circle.fill"
        case .mildAMS: return "exclamationmark.triangle.fill"
        case .severeAMS: return "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .notRecorded: return .secondary
        case .noAMS: return .green
        case .mildAMS: return .orange
        case .severeAMS: return .red
        }
    }

    var recommendation: String {
        switch self {
        case .notRecorded:
            return "Record symptoms to assess altitude sickness risk."
        case .noAMS:
            return "No signs of acute mountain sickness. Continue as planned."
        case .mildAMS:
            return "Rest at current altitude. Do not ascend until symptoms resolve. " +
                   "Consider descent if symptoms worsen."
        case .severeAMS:
            return "DESCEND IMMEDIATELY. Do not wait for improvement. " +
                   "Seek medical attention. Consider oxygen and medications."
        }
    }
}

// MARK: - Activity Type

enum ActivityType: String, Codable, CaseIterable {
    case internationalTravel = "International Travel"
    case domesticTravel = "Domestic Travel"
    case acclimatization = "Acclimatization"
    case fieldWork = "Field Work"
    case restDay = "Rest Day"
    case resupply = "Resupply"
    case summit = "Summit"
    case basecamp = "Base Camp"

    var icon: String {
        switch self {
        case .internationalTravel: return "airplane"
        case .domesticTravel: return "car"
        case .acclimatization: return "lungs"
        case .fieldWork: return "figure.hiking"
        case .restDay: return "bed.double"
        case .resupply: return "shippingbox"
        case .summit: return "mountain.2"
        case .basecamp: return "tent"
        }
    }

    var color: Color {
        switch self {
        case .internationalTravel: return .purple
        case .domesticTravel: return .blue
        case .acclimatization: return .orange
        case .fieldWork: return .green
        case .restDay: return .teal
        case .resupply: return .brown
        case .summit: return .red
        case .basecamp: return .indigo
        }
    }
}
