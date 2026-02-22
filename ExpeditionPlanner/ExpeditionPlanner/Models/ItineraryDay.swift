import Foundation
import SwiftData
import CoreLocation

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

    var color: String {
        switch self {
        case .internationalTravel: return "purple"
        case .domesticTravel: return "blue"
        case .acclimatization: return "orange"
        case .fieldWork: return "green"
        case .restDay: return "teal"
        case .resupply: return "brown"
        case .summit: return "red"
        case .basecamp: return "indigo"
        }
    }
}
