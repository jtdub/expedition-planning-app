import Foundation
import SwiftData
import CoreLocation

@Model
final class ResupplyPoint {
    var id: UUID = UUID()
    var name: String = ""
    var resupplyDescription: String = ""

    // Post office info
    var postOfficeAddress: String?
    var postOfficeHours: String?
    var postOfficePhone: String?
    var mailingInstructions: String?

    // Location
    var latitude: Double?
    var longitude: Double?
    var elevationMeters: Double?

    // Services available
    var hasPostOffice: Bool = false
    var hasGroceries: Bool = false
    var hasFuel: Bool = false
    var hasLodging: Bool = false
    var hasRestaurant: Bool = false
    var hasShowers: Bool = false
    var hasLaundry: Bool = false
    var servicesNotes: String = ""

    // Timing
    var expectedArrivalDate: Date?
    var dayNumber: Int?

    var notes: String = ""

    // Relationship - must be optional for CloudKit
    var expedition: Expedition?

    init(
        name: String = "",
        resupplyDescription: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.resupplyDescription = resupplyDescription
    }

    // MARK: - Computed Properties

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var elevation: Measurement<UnitLength>? {
        guard let meters = elevationMeters else { return nil }
        return Measurement(value: meters, unit: .meters)
    }

    var availableServices: [String] {
        var services: [String] = []
        if hasPostOffice { services.append("Post Office") }
        if hasGroceries { services.append("Groceries") }
        if hasFuel { services.append("Fuel") }
        if hasLodging { services.append("Lodging") }
        if hasRestaurant { services.append("Restaurant") }
        if hasShowers { services.append("Showers") }
        if hasLaundry { services.append("Laundry") }
        return services
    }

    var servicesString: String {
        availableServices.joined(separator: ", ")
    }

    var mailingAddress: String? {
        guard hasPostOffice else { return nil }
        return mailingInstructions ?? postOfficeAddress
    }
}
