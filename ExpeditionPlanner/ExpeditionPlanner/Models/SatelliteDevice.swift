import Foundation
import SwiftData

@Model
final class SatelliteDevice {
    var id: UUID = UUID()
    var name: String = ""
    var deviceType: SatelliteDeviceType = SatelliteDeviceType.inReach

    // Device identification
    var deviceId: String = ""
    var imeiNumber: String = ""
    var serialNumber: String = ""

    // Subscription/Plan
    var subscriptionPlan: String = ""
    var subscriptionExpiry: Date?
    var monthlyFee: Decimal?
    var currency: String = "USD"

    // Rental info (if rented)
    var isRented: Bool = false
    var rentalCompany: String = ""
    var rentalContact: String = ""
    var rentalPhone: String = ""
    var pickupLocation: String = ""
    var pickupDate: Date?
    var pickupInstructions: String = ""
    var returnLocation: String = ""
    var returnDate: Date?
    var returnInstructions: String = ""
    var rentalCost: Decimal?

    // Check-in configuration
    var checkInSchedule: String = ""
    var checkInRecipients: String = ""
    var okMessageText: String = "All OK - checking in as scheduled"
    var customMessage1: String = ""
    var customMessage2: String = ""
    var sosContacts: String = ""

    // Technical info
    var batteryType: String = ""
    var batteryLife: String = ""
    var chargingNotes: String = ""
    var frequencyBand: String = ""

    // VHF/Radio specific
    var radioFrequencies: String = ""
    var callSign: String = ""

    // Assignment
    var assignedToParticipant: String = ""

    // Status
    var status: DeviceStatus = DeviceStatus.available
    var lastCheckIn: Date?
    var notes: String = ""

    // Relationships - must be optional for CloudKit
    var expedition: Expedition?

    init(
        name: String = "",
        deviceType: SatelliteDeviceType = .inReach
    ) {
        self.id = UUID()
        self.name = name
        self.deviceType = deviceType
    }

    // MARK: - Computed Properties

    var isSubscriptionActive: Bool {
        guard let expiry = subscriptionExpiry else { return true }
        return expiry > Date()
    }

    var displayName: String {
        if name.isEmpty {
            return "\(deviceType.rawValue) - \(deviceId.isEmpty ? "Unassigned" : deviceId)"
        }
        return name
    }

    var needsPickup: Bool {
        guard isRented, let pickup = pickupDate else { return false }
        return pickup > Date()
    }

    var needsReturn: Bool {
        guard isRented, let returnD = returnDate else { return false }
        return returnD > Date()
    }

    var checkInRecipientsArray: [String] {
        checkInRecipients.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var radioFrequenciesArray: [String] {
        radioFrequencies.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

// MARK: - Satellite Device Type

enum SatelliteDeviceType: String, Codable, CaseIterable {
    case inReach = "Garmin inReach"
    case inReachMini = "Garmin inReach Mini"
    case inReachMessenger = "Garmin inReach Messenger"
    case zoleo = "ZOLEO"
    case spot = "SPOT"
    case spotX = "SPOT X"
    case satPhone = "Satellite Phone"
    case iridiumGo = "Iridium GO!"
    case plb = "PLB (Personal Locator Beacon)"
    case vhfRadio = "VHF Radio"
    case hfRadio = "HF Radio"
    case other = "Other"

    var icon: String {
        switch self {
        case .inReach, .inReachMini, .inReachMessenger:
            return "antenna.radiowaves.left.and.right"
        case .zoleo, .spot, .spotX:
            return "dot.radiowaves.left.and.right"
        case .satPhone:
            return "phone.fill"
        case .iridiumGo:
            return "wifi"
        case .plb:
            return "sos"
        case .vhfRadio, .hfRadio:
            return "radio"
        case .other:
            return "wave.3.right"
        }
    }

    var color: String {
        switch self {
        case .inReach, .inReachMini, .inReachMessenger: return "orange"
        case .zoleo: return "blue"
        case .spot, .spotX: return "yellow"
        case .satPhone, .iridiumGo: return "purple"
        case .plb: return "red"
        case .vhfRadio, .hfRadio: return "green"
        case .other: return "gray"
        }
    }

    var hasTwoWayMessaging: Bool {
        switch self {
        case .inReach, .inReachMini, .inReachMessenger, .zoleo, .spotX, .satPhone, .iridiumGo:
            return true
        case .spot, .plb, .vhfRadio, .hfRadio, .other:
            return false
        }
    }

    var hasTracking: Bool {
        switch self {
        case .inReach, .inReachMini, .inReachMessenger, .zoleo, .spot, .spotX:
            return true
        case .satPhone, .iridiumGo, .plb, .vhfRadio, .hfRadio, .other:
            return false
        }
    }
}

// MARK: - Device Status

enum DeviceStatus: String, Codable, CaseIterable {
    case available = "Available"
    case assigned = "Assigned"
    case inUse = "In Use"
    case charging = "Charging"
    case needsRepair = "Needs Repair"
    case rented = "Rented"
    case returned = "Returned"

    var icon: String {
        switch self {
        case .available: return "checkmark.circle"
        case .assigned: return "person.badge.clock"
        case .inUse: return "antenna.radiowaves.left.and.right"
        case .charging: return "battery.100.bolt"
        case .needsRepair: return "wrench"
        case .rented: return "tag"
        case .returned: return "arrow.uturn.left"
        }
    }

    var color: String {
        switch self {
        case .available: return "green"
        case .assigned: return "blue"
        case .inUse: return "orange"
        case .charging: return "yellow"
        case .needsRepair: return "red"
        case .rented: return "purple"
        case .returned: return "gray"
        }
    }
}
