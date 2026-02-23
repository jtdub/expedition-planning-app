import Foundation
import SwiftData
import CoreLocation

@Model
final class Shelter {
    var id: UUID = UUID()
    var name: String = ""
    var shelterType: ShelterType = ShelterType.publicCabin
    var latitude: Double?
    var longitude: Double?
    var elevationMeters: Double?
    var region: String = ""
    var capacity: Int?
    var reservationRequired: Bool = false
    var feePerNight: Decimal?
    var feeCurrency: String = "USD"
    var seasonOpen: String?
    var emergencyUseAllowed: Bool = true

    // Amenity booleans
    var hasWoodStove: Bool = false
    var hasSleepingPlatform: Bool = false
    var hasFirewood: Bool = false
    var hasOuthouse: Bool = false
    var hasWater: Bool = false
    var hasFirstAid: Bool = false
    var hasEmergencySupplies: Bool = false
    var hasHelipad: Bool = false

    // Metadata
    var isUserAdded: Bool = false
    var notes: String = ""
    var lastVerified: Date?
    var managingAgency: String?
    var contactPhone: String?
    var websiteURL: String?

    init(
        name: String = "",
        shelterType: ShelterType = .publicCabin,
        latitude: Double? = nil,
        longitude: Double? = nil,
        elevationMeters: Double? = nil,
        region: String = "",
        capacity: Int? = nil,
        reservationRequired: Bool = false,
        notes: String = "",
        isUserAdded: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.shelterType = shelterType
        self.latitude = latitude
        self.longitude = longitude
        self.elevationMeters = elevationMeters
        self.region = region
        self.capacity = capacity
        self.reservationRequired = reservationRequired
        self.notes = notes
        self.isUserAdded = isUserAdded
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

    var amenities: [ShelterAmenity] {
        var result: [ShelterAmenity] = []
        if hasWoodStove { result.append(.woodStove) }
        if hasSleepingPlatform { result.append(.sleepingPlatform) }
        if hasFirewood { result.append(.firewood) }
        if hasOuthouse { result.append(.outhouse) }
        if hasWater { result.append(.water) }
        if hasFirstAid { result.append(.firstAid) }
        if hasEmergencySupplies { result.append(.emergencySupplies) }
        if hasHelipad { result.append(.helipad) }
        return result
    }

    var amenitySummary: String {
        amenities.map { $0.rawValue }.joined(separator: ", ")
    }

    var capacityText: String {
        guard let cap = capacity else { return "Unknown" }
        return "\(cap) people"
    }

    var feeText: String? {
        guard let fee = feePerNight else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = feeCurrency
        return formatter.string(from: fee as NSDecimalNumber)
    }
}

// MARK: - Shelter Type

enum ShelterType: String, Codable, CaseIterable {
    case publicCabin = "Public Cabin"
    case emergencyShelter = "Emergency Shelter"
    case hut = "Mountain Hut"
    case lodge = "Lodge"
    case yurt = "Yurt"
    case tentPlatform = "Tent Platform"
    case leanTo = "Lean-to"
    case bivyShelter = "Bivy Shelter"

    var icon: String {
        switch self {
        case .publicCabin: return "house.fill"
        case .emergencyShelter: return "exclamationmark.triangle.fill"
        case .hut: return "house.lodge.fill"
        case .lodge: return "building.2.fill"
        case .yurt: return "tent.fill"
        case .tentPlatform: return "tent"
        case .leanTo: return "triangle.fill"
        case .bivyShelter: return "tent.2.fill"
        }
    }

    var color: String {
        switch self {
        case .publicCabin: return "brown"
        case .emergencyShelter: return "red"
        case .hut: return "orange"
        case .lodge: return "blue"
        case .yurt: return "purple"
        case .tentPlatform: return "green"
        case .leanTo: return "gray"
        case .bivyShelter: return "teal"
        }
    }

    var typeDescription: String {
        switch self {
        case .publicCabin:
            return "Government-maintained public use cabin, often requires reservation"
        case .emergencyShelter:
            return "Emergency-only shelter for survival situations"
        case .hut:
            return "Mountain hut, may be staffed or unstaffed"
        case .lodge:
            return "Commercial lodge with services and amenities"
        case .yurt:
            return "Semi-permanent circular tent structure"
        case .tentPlatform:
            return "Designated flat platform for tent camping"
        case .leanTo:
            return "Three-sided open shelter"
        case .bivyShelter:
            return "Small emergency bivy shelter"
        }
    }
}

// MARK: - Shelter Amenity

enum ShelterAmenity: String, Codable, CaseIterable {
    case woodStove = "Wood Stove"
    case sleepingPlatform = "Sleeping Platform"
    case firewood = "Firewood"
    case outhouse = "Outhouse"
    case water = "Water Source"
    case firstAid = "First Aid Kit"
    case emergencySupplies = "Emergency Supplies"
    case helipad = "Helipad"

    var icon: String {
        switch self {
        case .woodStove: return "flame.fill"
        case .sleepingPlatform: return "bed.double.fill"
        case .firewood: return "tree.fill"
        case .outhouse: return "toilet.fill"
        case .water: return "drop.fill"
        case .firstAid: return "cross.case.fill"
        case .emergencySupplies: return "bag.fill"
        case .helipad: return "airplane"
        }
    }
}

// MARK: - Shelter Region

enum ShelterRegion: String, Codable, CaseIterable {
    case alaska = "Alaska"
    case yukon = "Yukon"
    case brooksRange = "Brooks Range"
    case denali = "Denali Area"
    case other = "Other"

    var description: String {
        switch self {
        case .alaska: return "General Alaska"
        case .yukon: return "Yukon Territory"
        case .brooksRange: return "Brooks Range, Alaska"
        case .denali: return "Denali National Park Area"
        case .other: return "Other Region"
        }
    }
}
