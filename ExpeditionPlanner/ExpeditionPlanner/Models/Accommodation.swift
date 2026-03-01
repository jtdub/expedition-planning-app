import Foundation
import SwiftData

@Model
final class Accommodation {
    var id: UUID = UUID()
    var name: String = ""
    var accommodationType: AccommodationType = AccommodationType.hotel

    // Location
    var address: String = ""
    var city: String = ""
    var country: String = ""
    var latitude: Double?
    var longitude: Double?

    // Contact
    var phone: String = ""
    var email: String = ""
    var website: String = ""

    // Reservation
    var confirmationNumber: String = ""
    var checkInDate: Date?
    var checkOutDate: Date?
    var checkInTime: String = ""
    var checkOutTime: String = ""

    // Cost
    var nightlyRate: Decimal?
    var totalCost: Decimal?
    var currency: String = "USD"
    var groupRate: Bool = false
    var groupRateCode: String = ""
    var isPaid: Bool = false
    var depositAmount: Decimal?
    var depositPaid: Bool = false

    // Amenities stored as comma-separated string for CloudKit compatibility
    var amenitiesString: String = ""

    // Room info
    var roomCount: Int = 1
    var roomType: String = ""
    var roomAssignmentsNotes: String = ""

    // Services
    var hasShuttle: Bool = false
    var shuttleNotes: String = ""
    var hasGearStorage: Bool = false
    var gearStorageNotes: String = ""
    var hasLaundry: Bool = false
    var hasRestaurant: Bool = false
    var hasWifi: Bool = false
    var hasParking: Bool = false

    // Notes
    var nearbyServices: String = ""
    var bookingNotes: String = ""
    var notes: String = ""

    // Status
    var status: AccommodationStatus = AccommodationStatus.reserved

    // Relationships - must be optional for CloudKit
    var expedition: Expedition?

    init(
        name: String = "",
        accommodationType: AccommodationType = .hotel,
        city: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.accommodationType = accommodationType
        self.city = city
    }

    // MARK: - Computed Properties

    var amenities: [String] {
        get {
            amenitiesString.isEmpty ? [] : amenitiesString.components(separatedBy: ",")
        }
        set {
            amenitiesString = newValue.joined(separator: ",")
        }
    }

    var numberOfNights: Int {
        guard let checkIn = checkInDate, let checkOut = checkOutDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: checkIn, to: checkOut).day ?? 0
    }

    var displayAddress: String {
        [address, city, country].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    var dateRange: String {
        guard let checkIn = checkInDate, let checkOut = checkOutDate else { return "Dates TBD" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: checkIn)) - \(formatter.string(from: checkOut))"
    }

    var isUpcoming: Bool {
        guard let checkIn = checkInDate else { return false }
        return checkIn > Date()
    }

    var isCurrent: Bool {
        guard let checkIn = checkInDate, let checkOut = checkOutDate else { return false }
        let now = Date()
        return now >= checkIn && now <= checkOut
    }

    var availableAmenities: [String] {
        var list: [String] = []
        if hasShuttle { list.append("Shuttle") }
        if hasGearStorage { list.append("Gear Storage") }
        if hasLaundry { list.append("Laundry") }
        if hasRestaurant { list.append("Restaurant") }
        if hasWifi { list.append("WiFi") }
        if hasParking { list.append("Parking") }
        return list + amenities
    }

    var calculatedTotalCost: Decimal? {
        guard let rate = nightlyRate else { return totalCost }
        return rate * Decimal(numberOfNights)
    }
}

// MARK: - Accommodation Type

enum AccommodationType: String, Codable, CaseIterable {
    case hotel = "Hotel"
    case motel = "Motel"
    case hostel = "Hostel"
    case lodge = "Lodge"
    case cabin = "Cabin"
    case campground = "Campground"
    case bnb = "B&B"
    case airbnb = "Vacation Rental"
    case backcountry = "Backcountry Camp"
    case hut = "Mountain Hut"
    case other = "Other"

    var icon: String {
        switch self {
        case .hotel, .motel: return "building.2"
        case .hostel: return "bed.double"
        case .lodge: return "house.lodge"
        case .cabin, .hut: return "house"
        case .campground, .backcountry: return "tent"
        case .bnb: return "house.fill"
        case .airbnb: return "key.fill"
        case .other: return "mappin"
        }
    }

    var color: String {
        switch self {
        case .hotel, .motel: return "blue"
        case .hostel: return "purple"
        case .lodge, .cabin, .hut: return "brown"
        case .campground, .backcountry: return "green"
        case .bnb, .airbnb: return "orange"
        case .other: return "gray"
        }
    }
}

// MARK: - Accommodation Status

enum AccommodationStatus: String, Codable, CaseIterable {
    case researching = "Researching"
    case contacted = "Contacted"
    case reserved = "Reserved"
    case confirmed = "Confirmed"
    case checkedIn = "Checked In"
    case checkedOut = "Checked Out"
    case cancelled = "Cancelled"

    var icon: String {
        switch self {
        case .researching: return "magnifyingglass"
        case .contacted: return "phone"
        case .reserved: return "calendar.badge.clock"
        case .confirmed: return "checkmark.circle"
        case .checkedIn: return "door.left.hand.open"
        case .checkedOut: return "door.right.hand.closed"
        case .cancelled: return "xmark.circle"
        }
    }

    var color: String {
        switch self {
        case .researching: return "gray"
        case .contacted: return "yellow"
        case .reserved: return "blue"
        case .confirmed: return "green"
        case .checkedIn: return "orange"
        case .checkedOut: return "gray"
        case .cancelled: return "red"
        }
    }
}
