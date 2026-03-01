import Foundation
import SwiftData

@Model
final class TransportLeg {
    var id: UUID = UUID()
    var transportType: TransportType = TransportType.flight
    var carrier: String = ""
    var bookingReference: String = ""

    // Departure
    var departureLocation: String = ""
    var departureCode: String = ""
    var departureTime: Date?
    var departureTimezone: String = ""

    // Arrival
    var arrivalLocation: String = ""
    var arrivalCode: String = ""
    var arrivalTime: Date?
    var arrivalTimezone: String = ""

    // Flight-specific
    var flightNumber: String = ""
    var airline: String = ""
    var aircraft: String?
    var seatAssignment: String?

    // Ground transport specific
    var vehicleInfo: String?
    var driverContact: String?
    var pickupInstructions: String?

    // Cost
    var cost: Decimal?
    var currency: String = "USD"
    var isPaid: Bool = false

    // Status
    var status: TransportStatus = TransportStatus.booked
    var notes: String = ""

    // Relationships - must be optional for CloudKit
    var expedition: Expedition?
    var participant: Participant?

    // For multi-leg journeys, link to next segment
    var legOrder: Int = 0

    init(
        transportType: TransportType = .flight,
        carrier: String = "",
        departureLocation: String = "",
        arrivalLocation: String = ""
    ) {
        self.id = UUID()
        self.transportType = transportType
        self.carrier = carrier
        self.departureLocation = departureLocation
        self.arrivalLocation = arrivalLocation
    }

    // MARK: - Computed Properties

    var duration: TimeInterval? {
        guard let departure = departureTime, let arrival = arrivalTime else { return nil }
        return arrival.timeIntervalSince(departure)
    }

    var formattedDuration: String {
        guard let duration = duration else { return "N/A" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var displayTitle: String {
        if transportType == .flight && !flightNumber.isEmpty {
            return "\(airline) \(flightNumber)"
        }
        return "\(transportType.rawValue): \(carrier)"
    }

    var routeSummary: String {
        let from = departureCode.isEmpty ? departureLocation : departureCode
        let to = arrivalCode.isEmpty ? arrivalLocation : arrivalCode
        return "\(from) → \(to)"
    }

    var isUpcoming: Bool {
        guard let departure = departureTime else { return false }
        return departure > Date()
    }

    var isInProgress: Bool {
        guard let departure = departureTime, let arrival = arrivalTime else { return false }
        let now = Date()
        return now >= departure && now <= arrival
    }
}

// MARK: - Transport Type

enum TransportType: String, Codable, CaseIterable {
    case flight = "Flight"
    case bushPlane = "Bush Plane"
    case charter = "Charter Flight"
    case helicopter = "Helicopter"
    case shuttle = "Shuttle"
    case bus = "Bus"
    case train = "Train"
    case boat = "Boat"
    case ferry = "Ferry"
    case taxi = "Taxi"
    case rental = "Rental Car"
    case other = "Other"

    var icon: String {
        switch self {
        case .flight, .charter: return "airplane"
        case .bushPlane: return "airplane.circle"
        case .helicopter: return "helicopter.circle"
        case .shuttle, .bus: return "bus"
        case .train: return "tram"
        case .boat, .ferry: return "ferry"
        case .taxi: return "car"
        case .rental: return "car.fill"
        case .other: return "figure.walk"
        }
    }

    var color: String {
        switch self {
        case .flight, .charter, .bushPlane, .helicopter: return "blue"
        case .shuttle, .bus, .train: return "green"
        case .boat, .ferry: return "cyan"
        case .taxi, .rental: return "orange"
        case .other: return "gray"
        }
    }
}

// MARK: - Transport Status

enum TransportStatus: String, Codable, CaseIterable {
    case planned = "Planned"
    case booked = "Booked"
    case confirmed = "Confirmed"
    case checkedIn = "Checked In"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case delayed = "Delayed"

    var icon: String {
        switch self {
        case .planned: return "calendar"
        case .booked: return "ticket"
        case .confirmed: return "checkmark.circle"
        case .checkedIn: return "person.badge.clock"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        case .delayed: return "clock.badge.exclamationmark"
        }
    }

    var color: String {
        switch self {
        case .planned: return "gray"
        case .booked: return "blue"
        case .confirmed: return "green"
        case .checkedIn: return "orange"
        case .completed: return "gray"
        case .cancelled: return "red"
        case .delayed: return "yellow"
        }
    }
}
