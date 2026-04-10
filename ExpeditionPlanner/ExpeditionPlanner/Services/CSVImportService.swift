import Foundation

// swiftlint:disable file_length

/// Service for importing CSV data into expedition models.
/// Auto-detects the import type by matching headers against known CSVExportService column names.
final class CSVImportService {

    // MARK: - Types

    enum CSVImportType: String, CaseIterable, Identifiable {
        case itinerary = "Itinerary"
        case participants = "Participants"
        case contacts = "Contacts"
        case gear = "Gear"
        case budget = "Budget"
        case permits = "Permits"
        case resupply = "Resupply Points"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .itinerary: return "calendar.day.timeline.left"
            case .participants: return "person.2"
            case .contacts: return "person.crop.rectangle.stack"
            case .gear: return "backpack"
            case .budget: return "dollarsign.circle"
            case .permits: return "doc.text"
            case .resupply: return "shippingbox"
            }
        }

        /// Expected column headers matching CSVExportService output
        var expectedHeaders: Set<String> {
            switch self {
            case .itinerary:
                return [
                    "Day", "Title", "Date", "Start Location", "End Location",
                    "Start Elevation (m)", "End Elevation (m)", "Distance (km)",
                    "Activity", "Description"
                ]
            case .participants:
                return [
                    "Name", "Email", "Phone", "Role", "Group",
                    "Arrival Date", "Departure Date", "Confirmed", "Paid"
                ]
            case .contacts:
                return [
                    "Name", "Role", "Organization", "Category", "Phone",
                    "Cell Phone", "Email", "Location", "Emergency", "Priority"
                ]
            case .gear:
                return [
                    "Name", "Category", "Priority", "Weight (g)", "Quantity",
                    "Total Weight (g)", "Selection", "Packed", "In Hand",
                    "Weighed", "Description"
                ]
            case .budget:
                return [
                    "Name", "Category", "Estimated", "Actual", "Currency",
                    "Vendor", "Paid", "Date Incurred", "Notes"
                ]
            case .permits:
                return [
                    "Name", "Type", "Status", "Issuing Authority", "Deadline",
                    "Cost", "Currency", "Permit Number", "Notes"
                ]
            case .resupply:
                return [
                    "Name", "Day", "Arrival Date", "Latitude", "Longitude",
                    "Post Office", "Groceries", "Fuel", "Lodging",
                    "Restaurant", "Description"
                ]
            }
        }
    }

    struct CSVImportResult {
        let importedCount: Int
        let errorCount: Int
        let errors: [String]
        let duplicateNames: [String]
    }

    // MARK: - Type Detection

    /// Detect the most likely import type by scoring header matches.
    /// Returns nil if no type matches at least 3 headers.
    static func detectType(from headers: [String]) -> CSVImportType? {
        let headerSet = Set(headers)
        var bestType: CSVImportType?
        var bestScore = 0

        for type in CSVImportType.allCases {
            let score = headerSet.intersection(type.expectedHeaders).count
            if score > bestScore {
                bestScore = score
                bestType = type
            }
        }

        return bestScore >= 3 ? bestType : nil
    }

    // MARK: - Import Methods

    static func importGear(from parseResult: CSVParser.ParseResult) -> (items: [GearItem], result: CSVImportResult) {
        var items: [GearItem] = []
        var errors: [String] = []

        for index in parseResult.rows.indices {
            let rowNum = index + 2 // 1-indexed, skip header
            guard let name = parseResult.value(row: index, column: "Name"), !name.isEmpty else {
                errors.append("Row \(rowNum): Missing name")
                continue
            }

            let item = GearItem(name: name)

            if let catStr = parseResult.value(row: index, column: "Category") {
                item.category = parseEnum(catStr, type: GearCategory.self) ?? GearCategory.personalItems
            }

            if let priStr = parseResult.value(row: index, column: "Priority") {
                item.priority = parseEnum(priStr, type: GearPriority.self) ?? GearPriority.suggested
            }

            if let weightStr = parseResult.value(row: index, column: "Weight (g)"),
               let weight = Double(weightStr) {
                item.weightGrams = weight
            }

            if let qtyStr = parseResult.value(row: index, column: "Quantity"),
               let qty = Int(qtyStr) {
                item.quantity = qty
            }

            if let selection = parseResult.value(row: index, column: "Selection") {
                item.selection = selection
            }

            if let packed = parseResult.value(row: index, column: "Packed") {
                item.isPacked = parseBool(packed)
            }

            if let inHand = parseResult.value(row: index, column: "In Hand") {
                item.isInHand = parseBool(inHand)
            }

            if let weighed = parseResult.value(row: index, column: "Weighed") {
                item.isWeighed = parseBool(weighed)
            }

            if let desc = parseResult.value(row: index, column: "Description") {
                item.descriptionOrPurpose = desc
            }

            items.append(item)
        }

        let importResult = CSVImportResult(
            importedCount: items.count,
            errorCount: errors.count,
            errors: errors,
            duplicateNames: []
        )
        return (items, importResult)
    }

    static func importParticipants(
        from parseResult: CSVParser.ParseResult
    ) -> (items: [Participant], result: CSVImportResult) {
        var items: [Participant] = []
        var errors: [String] = []

        for index in parseResult.rows.indices {
            let rowNum = index + 2
            guard let name = parseResult.value(row: index, column: "Name"), !name.isEmpty else {
                errors.append("Row \(rowNum): Missing name")
                continue
            }

            let participant = Participant(name: name)

            if let email = parseResult.value(row: index, column: "Email") {
                participant.email = email
            }

            if let phone = parseResult.value(row: index, column: "Phone") {
                participant.phone = phone
            }

            if let roleStr = parseResult.value(row: index, column: "Role") {
                participant.role = parseEnum(roleStr, type: ParticipantRole.self) ?? ParticipantRole.participant
            }

            if let group = parseResult.value(row: index, column: "Group") {
                participant.groupAssignment = group
            }

            if let arrDate = parseResult.value(row: index, column: "Arrival Date") {
                participant.arrivalDate = parseDate(arrDate)
            }

            if let depDate = parseResult.value(row: index, column: "Departure Date") {
                participant.departureDate = parseDate(depDate)
            }

            if let confirmed = parseResult.value(row: index, column: "Confirmed") {
                participant.isConfirmed = parseBool(confirmed)
            }

            if let paid = parseResult.value(row: index, column: "Paid") {
                participant.hasPaid = parseBool(paid)
            }

            items.append(participant)
        }

        let importResult = CSVImportResult(
            importedCount: items.count,
            errorCount: errors.count,
            errors: errors,
            duplicateNames: []
        )
        return (items, importResult)
    }

    static func importItinerary(
        from parseResult: CSVParser.ParseResult
    ) -> (items: [ItineraryDay], result: CSVImportResult) {
        var items: [ItineraryDay] = []
        var errors: [String] = []

        for index in parseResult.rows.indices {
            let rowNum = index + 2
            guard let dayStr = parseResult.value(row: index, column: "Day"),
                  let dayNumber = Int(dayStr) else {
                errors.append("Row \(rowNum): Missing or invalid day number")
                continue
            }

            let day = ItineraryDay(dayNumber: dayNumber)

            if let title = parseResult.value(row: index, column: "Title") {
                day.location = title
            }

            if let dateStr = parseResult.value(row: index, column: "Date") {
                day.date = parseDate(dateStr)
            }

            if let startLoc = parseResult.value(row: index, column: "Start Location") {
                day.startLocation = startLoc
            }

            if let endLoc = parseResult.value(row: index, column: "End Location") {
                day.endLocation = endLoc
            }

            if let startElev = parseResult.value(row: index, column: "Start Elevation (m)"),
               let elev = Double(startElev) {
                day.startElevationMeters = elev
            }

            if let endElev = parseResult.value(row: index, column: "End Elevation (m)"),
               let elev = Double(endElev) {
                day.endElevationMeters = elev
            }

            if let distStr = parseResult.value(row: index, column: "Distance (km)"),
               let dist = Double(distStr) {
                day.distanceMeters = dist * 1000 // Convert km to meters
            }

            if let actStr = parseResult.value(row: index, column: "Activity") {
                day.activityType = parseEnum(actStr, type: ActivityType.self) ?? ActivityType.fieldWork
            }

            if let desc = parseResult.value(row: index, column: "Description") {
                day.clientDescription = desc
            }

            items.append(day)
        }

        let importResult = CSVImportResult(
            importedCount: items.count,
            errorCount: errors.count,
            errors: errors,
            duplicateNames: []
        )
        return (items, importResult)
    }

    static func importContacts(
        from parseResult: CSVParser.ParseResult
    ) -> (items: [Contact], result: CSVImportResult) {
        var items: [Contact] = []
        var errors: [String] = []

        for index in parseResult.rows.indices {
            let rowNum = index + 2
            guard let name = parseResult.value(row: index, column: "Name"), !name.isEmpty else {
                errors.append("Row \(rowNum): Missing name")
                continue
            }

            let contact = Contact(name: name)

            if let role = parseResult.value(row: index, column: "Role") {
                contact.role = role
            }

            if let org = parseResult.value(row: index, column: "Organization") {
                contact.organization = org
            }

            if let catStr = parseResult.value(row: index, column: "Category") {
                contact.category = parseEnum(catStr, type: ContactCategory.self) ?? ContactCategory.localResource
            }

            if let phone = parseResult.value(row: index, column: "Phone") {
                contact.phone = phone
            }

            if let cell = parseResult.value(row: index, column: "Cell Phone") {
                contact.cellPhone = cell
            }

            if let email = parseResult.value(row: index, column: "Email") {
                contact.email = email
            }

            if let loc = parseResult.value(row: index, column: "Location") {
                contact.location = loc
            }

            if let emergency = parseResult.value(row: index, column: "Emergency") {
                contact.isEmergencyContact = parseBool(emergency)
            }

            if let priorityStr = parseResult.value(row: index, column: "Priority"),
               let priority = Int(priorityStr) {
                contact.emergencyPriority = priority
            }

            items.append(contact)
        }

        let importResult = CSVImportResult(
            importedCount: items.count,
            errorCount: errors.count,
            errors: errors,
            duplicateNames: []
        )
        return (items, importResult)
    }

    static func importBudget(
        from parseResult: CSVParser.ParseResult
    ) -> (items: [BudgetItem], result: CSVImportResult) {
        var items: [BudgetItem] = []
        var errors: [String] = []

        for index in parseResult.rows.indices {
            let rowNum = index + 2
            guard let name = parseResult.value(row: index, column: "Name"), !name.isEmpty else {
                errors.append("Row \(rowNum): Missing name")
                continue
            }

            // Skip the TOTAL summary row
            if name.uppercased() == "TOTAL" {
                continue
            }

            let item = BudgetItem(name: name)

            if let catStr = parseResult.value(row: index, column: "Category") {
                item.category = parseEnum(catStr, type: BudgetCategory.self) ?? BudgetCategory.other
            }

            if let estStr = parseResult.value(row: index, column: "Estimated"),
               let est = Decimal(string: estStr) {
                item.estimatedAmount = est
            }

            if let actStr = parseResult.value(row: index, column: "Actual"),
               !actStr.isEmpty,
               let act = Decimal(string: actStr) {
                item.actualAmount = act
            }

            if let currency = parseResult.value(row: index, column: "Currency"), !currency.isEmpty {
                item.currency = currency
            }

            if let vendor = parseResult.value(row: index, column: "Vendor") {
                item.vendor = vendor.isEmpty ? nil : vendor
            }

            if let paid = parseResult.value(row: index, column: "Paid") {
                item.isPaid = parseBool(paid)
            }

            if let dateStr = parseResult.value(row: index, column: "Date Incurred") {
                item.dateIncurred = parseDate(dateStr)
            }

            if let notes = parseResult.value(row: index, column: "Notes") {
                item.notes = notes
            }

            items.append(item)
        }

        let importResult = CSVImportResult(
            importedCount: items.count,
            errorCount: errors.count,
            errors: errors,
            duplicateNames: []
        )
        return (items, importResult)
    }

    static func importPermits(
        from parseResult: CSVParser.ParseResult
    ) -> (items: [Permit], result: CSVImportResult) {
        var items: [Permit] = []
        var errors: [String] = []

        for index in parseResult.rows.indices {
            let rowNum = index + 2
            guard let name = parseResult.value(row: index, column: "Name"), !name.isEmpty else {
                errors.append("Row \(rowNum): Missing name")
                continue
            }

            let permit = Permit(name: name)

            if let typeStr = parseResult.value(row: index, column: "Type") {
                permit.permitType = parseEnum(typeStr, type: PermitType.self) ?? PermitType.other
            }

            if let statusStr = parseResult.value(row: index, column: "Status") {
                permit.status = parseEnum(statusStr, type: PermitStatus.self) ?? PermitStatus.notStarted
            }

            if let authority = parseResult.value(row: index, column: "Issuing Authority") {
                permit.issuingAuthority = authority
            }

            if let deadlineStr = parseResult.value(row: index, column: "Deadline") {
                permit.applicationDeadline = parseDate(deadlineStr)
            }

            if let costStr = parseResult.value(row: index, column: "Cost"),
               !costStr.isEmpty,
               let cost = Decimal(string: costStr) {
                permit.cost = cost
            }

            if let currency = parseResult.value(row: index, column: "Currency"), !currency.isEmpty {
                permit.currency = currency
            }

            if let number = parseResult.value(row: index, column: "Permit Number") {
                permit.permitNumber = number.isEmpty ? nil : number
            }

            if let notes = parseResult.value(row: index, column: "Notes") {
                permit.notes = notes
            }

            items.append(permit)
        }

        let importResult = CSVImportResult(
            importedCount: items.count,
            errorCount: errors.count,
            errors: errors,
            duplicateNames: []
        )
        return (items, importResult)
    }

    static func importResupply(
        from parseResult: CSVParser.ParseResult
    ) -> (items: [ResupplyPoint], result: CSVImportResult) {
        var items: [ResupplyPoint] = []
        var errors: [String] = []

        for index in parseResult.rows.indices {
            let rowNum = index + 2
            guard let name = parseResult.value(row: index, column: "Name"), !name.isEmpty else {
                errors.append("Row \(rowNum): Missing name")
                continue
            }

            let point = ResupplyPoint(name: name)

            if let dayStr = parseResult.value(row: index, column: "Day"),
               let day = Int(dayStr) {
                point.dayNumber = day
            }

            if let dateStr = parseResult.value(row: index, column: "Arrival Date") {
                point.expectedArrivalDate = parseDate(dateStr)
            }

            if let latStr = parseResult.value(row: index, column: "Latitude"),
               let lat = Double(latStr) {
                point.latitude = lat
            }

            if let lonStr = parseResult.value(row: index, column: "Longitude"),
               let lon = Double(lonStr) {
                point.longitude = lon
            }

            if let po = parseResult.value(row: index, column: "Post Office") {
                point.hasPostOffice = parseBool(po)
            }

            if let groc = parseResult.value(row: index, column: "Groceries") {
                point.hasGroceries = parseBool(groc)
            }

            if let fuel = parseResult.value(row: index, column: "Fuel") {
                point.hasFuel = parseBool(fuel)
            }

            if let lodge = parseResult.value(row: index, column: "Lodging") {
                point.hasLodging = parseBool(lodge)
            }

            if let rest = parseResult.value(row: index, column: "Restaurant") {
                point.hasRestaurant = parseBool(rest)
            }

            if let desc = parseResult.value(row: index, column: "Description") {
                point.resupplyDescription = desc
            }

            items.append(point)
        }

        let importResult = CSVImportResult(
            importedCount: items.count,
            errorCount: errors.count,
            errors: errors,
            duplicateNames: []
        )
        return (items, importResult)
    }

    // MARK: - Duplicate Detection

    static func findDuplicateGearNames(
        in newItems: [GearItem],
        existing: [GearItem]
    ) -> [String] {
        let existingNames = Set(existing.map { $0.name.lowercased() })
        return newItems.filter { existingNames.contains($0.name.lowercased()) }.map { $0.name }
    }

    static func findDuplicateParticipantNames(
        in newItems: [Participant],
        existing: [Participant]
    ) -> [String] {
        let existingNames = Set(existing.map { $0.name.lowercased() })
        return newItems.filter { existingNames.contains($0.name.lowercased()) }.map { $0.name }
    }

    static func findDuplicateContactNames(
        in newItems: [Contact],
        existing: [Contact]
    ) -> [String] {
        let existingNames = Set(existing.map { $0.name.lowercased() })
        return newItems.filter { existingNames.contains($0.name.lowercased()) }.map { $0.name }
    }

    static func findDuplicatePermitNames(
        in newItems: [Permit],
        existing: [Permit]
    ) -> [String] {
        let existingNames = Set(existing.map { $0.name.lowercased() })
        return newItems.filter { existingNames.contains($0.name.lowercased()) }.map { $0.name }
    }

    static func findDuplicateBudgetNames(
        in newItems: [BudgetItem],
        existing: [BudgetItem]
    ) -> [String] {
        let existingNames = Set(existing.map { $0.name.lowercased() })
        return newItems.filter { existingNames.contains($0.name.lowercased()) }.map { $0.name }
    }

    static func findDuplicateResupplyNames(
        in newItems: [ResupplyPoint],
        existing: [ResupplyPoint]
    ) -> [String] {
        let existingNames = Set(existing.map { $0.name.lowercased() })
        return newItems.filter { existingNames.contains($0.name.lowercased()) }.map { $0.name }
    }

    // MARK: - Helpers

    /// Parse a boolean value from common CSV representations
    static func parseBool(_ string: String) -> Bool {
        let lower = string.lowercased().trimmingCharacters(in: .whitespaces)
        return lower == "yes" || lower == "true" || lower == "1"
    }

    /// Parse a date from common CSV date formats
    static func parseDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        for formatter in Self.dateFormatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }

    /// Parse an enum value case-insensitively from its rawValue
    static func parseEnum<T: RawRepresentable & CaseIterable>(
        _ string: String,
        type: T.Type
    ) -> T? where T.RawValue == String {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        // Exact match first
        if let match = T.allCases.first(where: { $0.rawValue == trimmed }) {
            return match
        }
        // Case-insensitive match
        let lower = trimmed.lowercased()
        return T.allCases.first { $0.rawValue.lowercased() == lower }
    }

    // MARK: - Date Formatters (cached)

    private static let dateFormatters: [DateFormatter] = {
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd"
        iso.locale = Locale(identifier: "en_US_POSIX")

        let abbreviated = DateFormatter()
        abbreviated.dateStyle = .medium
        abbreviated.locale = Locale(identifier: "en_US")

        let us = DateFormatter()
        us.dateFormat = "MM/dd/yyyy"
        us.locale = Locale(identifier: "en_US_POSIX")

        let european = DateFormatter()
        european.dateFormat = "dd/MM/yyyy"
        european.locale = Locale(identifier: "en_US_POSIX")

        let abbrevManual = DateFormatter()
        abbrevManual.dateFormat = "MMM d, yyyy"
        abbrevManual.locale = Locale(identifier: "en_US_POSIX")

        return [iso, abbrevManual, abbreviated, us, european]
    }()
}
