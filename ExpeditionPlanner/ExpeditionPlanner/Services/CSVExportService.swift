import Foundation

/// Service for exporting expedition data to CSV format
final class CSVExportService {

    // MARK: - Export Methods

    /// Export itinerary to CSV
    static func exportItinerary(for expedition: Expedition) -> String {
        // swiftlint:disable:next line_length
        var csv = "Day,Title,Date,Start Location,End Location,Start Elevation (m),End Elevation (m),Distance (km),Activity,Description\n"

        for day in expedition.sortedItinerary {
            let dateString = day.date?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let startElev = day.startElevationMeters.map { String(format: "%.0f", $0) } ?? ""
            let endElev = day.endElevationMeters.map { String(format: "%.0f", $0) } ?? ""
            let distanceKm = day.distanceMeters.map { String(format: "%.1f", $0 / 1000) } ?? ""

            let row = [
                String(day.dayNumber),
                escapeCSV(day.location),
                escapeCSV(dateString),
                escapeCSV(day.startLocation),
                escapeCSV(day.endLocation),
                startElev,
                endElev,
                distanceKm,
                escapeCSV(day.activityType.rawValue),
                escapeCSV(day.clientDescription)
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    /// Export participants to CSV
    static func exportParticipants(for expedition: Expedition) -> String {
        var csv = "Name,Email,Phone,Role,Group,Arrival Date,Departure Date,Confirmed,Paid\n"

        for participant in expedition.participants ?? [] {
            let arrivalDate = participant.arrivalDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let departureDate = participant.departureDate?.formatted(date: .abbreviated, time: .omitted) ?? ""

            let row = [
                escapeCSV(participant.name),
                escapeCSV(participant.email),
                escapeCSV(participant.phone),
                escapeCSV(participant.role.rawValue),
                escapeCSV(participant.groupAssignment),
                escapeCSV(arrivalDate),
                escapeCSV(departureDate),
                participant.isConfirmed ? "Yes" : "No",
                participant.hasPaid ? "Yes" : "No"
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    /// Export contacts to CSV
    static func exportContacts(for expedition: Expedition) -> String {
        var csv = "Name,Role,Organization,Category,Phone,Cell Phone,Email,Location,Emergency,Priority\n"

        for contact in expedition.contacts ?? [] {
            let row = [
                escapeCSV(contact.name),
                escapeCSV(contact.role),
                escapeCSV(contact.organization ?? ""),
                escapeCSV(contact.category.rawValue),
                escapeCSV(contact.phone ?? ""),
                escapeCSV(contact.cellPhone ?? ""),
                escapeCSV(contact.email ?? ""),
                escapeCSV(contact.location),
                contact.isEmergencyContact ? "Yes" : "No",
                contact.emergencyPriority.map { String($0) } ?? ""
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    /// Export gear list to CSV
    static func exportGear(for expedition: Expedition) -> String {
        // swiftlint:disable:next line_length
        var csv = "Name,Category,Priority,Weight (g),Quantity,Total Weight (g),Selection,Packed,In Hand,Weighed,Description\n"

        for item in expedition.gearItems ?? [] {
            let weight = item.weightGrams.map { String(format: "%.1f", $0) } ?? ""
            let totalWeightValue = item.totalWeight?.value ?? 0
            let totalWeight = item.totalWeight != nil ? String(format: "%.1f", totalWeightValue) : ""

            let row = [
                escapeCSV(item.name),
                escapeCSV(item.category.rawValue),
                escapeCSV(item.priority.rawValue),
                weight,
                String(item.quantity),
                totalWeight,
                escapeCSV(item.selection),
                item.isPacked ? "Yes" : "No",
                item.isInHand ? "Yes" : "No",
                item.isWeighed ? "Yes" : "No",
                escapeCSV(item.descriptionOrPurpose)
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    /// Export budget to CSV
    static func exportBudget(for expedition: Expedition) -> String {
        var csv = "Name,Category,Estimated,Actual,Currency,Vendor,Paid,Date Incurred,Notes\n"

        for item in expedition.budgetItems ?? [] {
            let estimated = NSDecimalNumber(decimal: item.estimatedAmount).stringValue
            let actual = item.actualAmount.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
            let dateIncurred = item.dateIncurred?.formatted(date: .abbreviated, time: .omitted) ?? ""

            let row = [
                escapeCSV(item.name),
                escapeCSV(item.category.rawValue),
                estimated,
                actual,
                item.currency,
                escapeCSV(item.vendor ?? ""),
                item.isPaid ? "Yes" : "No",
                escapeCSV(dateIncurred),
                escapeCSV(item.notes)
            ].joined(separator: ",")

            csv += row + "\n"
        }

        // Add totals row
        let totalEstimated = (expedition.budgetItems ?? []).reduce(Decimal(0)) { $0 + $1.estimatedAmount }
        let totalActual = (expedition.budgetItems ?? []).compactMap { $0.actualAmount }.reduce(Decimal(0), +)

        csv += "\n"
        let estStr = NSDecimalNumber(decimal: totalEstimated).stringValue
        let actStr = NSDecimalNumber(decimal: totalActual).stringValue
        csv += "TOTAL,,\(estStr),\(actStr),USD,,,,"

        return csv
    }

    /// Export permits to CSV
    static func exportPermits(for expedition: Expedition) -> String {
        var csv = "Name,Type,Status,Issuing Authority,Deadline,Cost,Currency,Permit Number,Notes\n"

        for permit in expedition.permits ?? [] {
            let deadline = permit.applicationDeadline?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let cost = permit.cost.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""

            let row = [
                escapeCSV(permit.name),
                escapeCSV(permit.permitType.rawValue),
                escapeCSV(permit.status.rawValue),
                escapeCSV(permit.issuingAuthority),
                escapeCSV(deadline),
                cost,
                permit.currency,
                escapeCSV(permit.permitNumber ?? ""),
                escapeCSV(permit.notes)
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    /// Export resupply points to CSV
    static func exportResupplyPoints(for expedition: Expedition) -> String {
        var csv = "Name,Day,Arrival Date,Latitude,Longitude,Post Office,Groceries,Fuel,Lodging,Restaurant,Description\n"

        for point in expedition.resupplyPoints ?? [] {
            let dayNum = point.dayNumber.map { String($0) } ?? ""
            let arrivalDate = point.expectedArrivalDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let lat = point.latitude.map { String(format: "%.6f", $0) } ?? ""
            let lon = point.longitude.map { String(format: "%.6f", $0) } ?? ""

            let row = [
                escapeCSV(point.name),
                dayNum,
                escapeCSV(arrivalDate),
                lat,
                lon,
                point.hasPostOffice ? "Yes" : "No",
                point.hasGroceries ? "Yes" : "No",
                point.hasFuel ? "Yes" : "No",
                point.hasLodging ? "Yes" : "No",
                point.hasRestaurant ? "Yes" : "No",
                escapeCSV(point.resupplyDescription)
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    // MARK: - Helper Methods

    /// Escape a string for CSV (handle commas, quotes, and newlines)
    private static func escapeCSV(_ string: String) -> String {
        var escaped = string

        // If the string contains comma, quote, or newline, wrap in quotes
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            // Double any existing quotes
            escaped = escaped.replacingOccurrences(of: "\"", with: "\"\"")
            // Wrap in quotes
            escaped = "\"\(escaped)\""
        }

        return escaped
    }
}
