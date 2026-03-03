import XCTest
@testable import Chaki

final class CSVImportServiceTests: XCTestCase {

    // MARK: - Type Detection

    func testDetectGearType() {
        let headers = ["Name", "Category", "Priority", "Weight (g)", "Quantity"]
        XCTAssertEqual(CSVImportService.detectType(from: headers), .gear)
    }

    func testDetectParticipantsType() {
        let headers = ["Name", "Email", "Phone", "Role", "Group", "Confirmed"]
        XCTAssertEqual(CSVImportService.detectType(from: headers), .participants)
    }

    func testDetectContactsType() {
        let headers = ["Name", "Role", "Organization", "Category", "Cell Phone", "Emergency"]
        XCTAssertEqual(CSVImportService.detectType(from: headers), .contacts)
    }

    func testDetectItineraryType() {
        let headers = ["Day", "Title", "Date", "Start Location", "End Location", "Activity"]
        XCTAssertEqual(CSVImportService.detectType(from: headers), .itinerary)
    }

    func testDetectBudgetType() {
        let headers = ["Name", "Category", "Estimated", "Actual", "Currency", "Vendor"]
        XCTAssertEqual(CSVImportService.detectType(from: headers), .budget)
    }

    func testDetectPermitsType() {
        let headers = ["Name", "Type", "Status", "Issuing Authority", "Deadline"]
        XCTAssertEqual(CSVImportService.detectType(from: headers), .permits)
    }

    func testDetectResupplyType() {
        let headers = ["Name", "Day", "Arrival Date", "Latitude", "Longitude", "Post Office"]
        XCTAssertEqual(CSVImportService.detectType(from: headers), .resupply)
    }

    func testDetectTypeReturnsNilForUnknownHeaders() {
        let headers = ["Foo", "Bar", "Baz"]
        XCTAssertNil(CSVImportService.detectType(from: headers))
    }

    func testDetectTypeRequiresMinimumThreeMatches() {
        let headers = ["Name", "Category"]
        XCTAssertNil(CSVImportService.detectType(from: headers))
    }

    // MARK: - Gear Import

    func testImportGear() throws {
        // swiftlint:disable:next line_length
        let csv = "Name,Category,Priority,Weight (g),Quantity,Total Weight (g),Selection,Packed,In Hand,Weighed,Description\n"
            + "Trail Runners,Footwear,critical,340,1,340,,Yes,Yes,Yes,Running shoes\n"
            + "Rain Jacket,Element Protection,suggested,280,1,280,Primary,No,Yes,No,Waterproof shell"
        let parseResult = try CSVParser.parse(string: csv)
        let (items, result) = CSVImportService.importGear(from: parseResult)

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(result.importedCount, 2)
        XCTAssertEqual(result.errorCount, 0)

        XCTAssertEqual(items[0].name, "Trail Runners")
        XCTAssertEqual(items[0].category, .footwear)
        XCTAssertEqual(items[0].priority, .critical)
        XCTAssertEqual(items[0].weightGrams, 340)
        XCTAssertTrue(items[0].isPacked)
        XCTAssertTrue(items[0].isInHand)
        XCTAssertTrue(items[0].isWeighed)
        XCTAssertEqual(items[0].descriptionOrPurpose, "Running shoes")

        XCTAssertEqual(items[1].name, "Rain Jacket")
        XCTAssertEqual(items[1].category, .elementProtection)
        XCTAssertEqual(items[1].selection, "Primary")
    }

    func testImportGearSkipsEmptyNames() throws {
        // swiftlint:disable:next line_length
        let csv = "Name,Category,Priority,Weight (g),Quantity,Total Weight (g),Selection,Packed,In Hand,Weighed,Description\n"
            + ",Footwear,critical,340,1,340,,Yes,Yes,Yes,No name"
        let parseResult = try CSVParser.parse(string: csv)
        let (items, result) = CSVImportService.importGear(from: parseResult)

        XCTAssertEqual(items.count, 0)
        XCTAssertEqual(result.errorCount, 1)
    }

    // MARK: - Participant Import

    func testImportParticipants() throws {
        let csv = "Name,Email,Phone,Role,Group,Arrival Date,Departure Date,Confirmed,Paid\n"
            + "Alice Smith,alice@test.com,555-1234,guide,Alpha,2026-06-15,2026-07-01,Yes,Yes\n"
            + "Bob Jones,bob@test.com,555-5678,participant,Beta,,2026-07-01,No,No"
        let parseResult = try CSVParser.parse(string: csv)
        let (items, result) = CSVImportService.importParticipants(from: parseResult)

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(result.errorCount, 0)

        XCTAssertEqual(items[0].name, "Alice Smith")
        XCTAssertEqual(items[0].email, "alice@test.com")
        XCTAssertEqual(items[0].role, .guide)
        XCTAssertEqual(items[0].groupAssignment, "Alpha")
        XCTAssertTrue(items[0].isConfirmed)
        XCTAssertTrue(items[0].hasPaid)
        XCTAssertNotNil(items[0].arrivalDate)

        XCTAssertEqual(items[1].role, .participant)
        XCTAssertFalse(items[1].isConfirmed)
    }

    // MARK: - Itinerary Import

    func testImportItinerary() throws {
        // swiftlint:disable:next line_length
        let csv = "Day,Title,Date,Start Location,End Location,Start Elevation (m),End Elevation (m),Distance (km),Activity,Description\n"
            + "1,Trailhead,2026-06-15,Fairbanks,Dalton Mile 235,150,450,12.5,Domestic Travel,Drive to trailhead"
        let parseResult = try CSVParser.parse(string: csv)
        let (items, result) = CSVImportService.importItinerary(from: parseResult)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(result.errorCount, 0)

        XCTAssertEqual(items[0].dayNumber, 1)
        XCTAssertEqual(items[0].location, "Trailhead")
        XCTAssertEqual(items[0].startLocation, "Fairbanks")
        XCTAssertEqual(items[0].endLocation, "Dalton Mile 235")
        XCTAssertEqual(items[0].startElevationMeters, 150)
        XCTAssertEqual(items[0].endElevationMeters, 450)
        XCTAssertEqual(items[0].distanceMeters, 12500) // km * 1000
        XCTAssertEqual(items[0].activityType, .domesticTravel)
        XCTAssertEqual(items[0].clientDescription, "Drive to trailhead")
    }

    // MARK: - Contact Import

    func testImportContacts() throws {
        let csv = "Name,Role,Organization,Category,Phone,Cell Phone,Email,Location,Emergency,Priority\n"
            + "Air Taxi,Pilot,Coyote Air,transport,907-555-1234,,coyote@test.com,Coldfoot,No,\n"
            + "Ranger Station,Ranger,NPS,emergency,907-555-5678,,nps@test.com,Bettles,Yes,1"
        let parseResult = try CSVParser.parse(string: csv)
        let (items, result) = CSVImportService.importContacts(from: parseResult)

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(result.errorCount, 0)

        XCTAssertEqual(items[0].name, "Air Taxi")
        XCTAssertEqual(items[0].category, .transport)
        XCTAssertFalse(items[0].isEmergencyContact)

        XCTAssertEqual(items[1].name, "Ranger Station")
        XCTAssertEqual(items[1].category, .emergency)
        XCTAssertTrue(items[1].isEmergencyContact)
        XCTAssertEqual(items[1].emergencyPriority, 1)
    }

    // MARK: - Budget Import

    func testImportBudget() throws {
        let csv = "Name,Category,Estimated,Actual,Currency,Vendor,Paid,Date Incurred,Notes\n"
            + "Flights,flights,1200,1150.50,USD,Alaska Air,Yes,2026-03-01,Round trip\n"
            + "Permits,permits,50,,USD,,No,,Park entry"
        let parseResult = try CSVParser.parse(string: csv)
        let (items, result) = CSVImportService.importBudget(from: parseResult)

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(result.errorCount, 0)

        XCTAssertEqual(items[0].name, "Flights")
        XCTAssertEqual(items[0].category, .flights)
        XCTAssertEqual(items[0].estimatedAmount, Decimal(1200))
        XCTAssertEqual(items[0].actualAmount, Decimal(string: "1150.50"))
        XCTAssertTrue(items[0].isPaid)
        XCTAssertNotNil(items[0].dateIncurred)

        XCTAssertEqual(items[1].name, "Permits")
        XCTAssertNil(items[1].actualAmount)
        XCTAssertFalse(items[1].isPaid)
    }

    func testImportBudgetSkipsTotalRow() throws {
        let csv = "Name,Category,Estimated,Actual,Currency,Vendor,Paid,Date Incurred,Notes\n"
            + "Item,other,100,,USD,,No,,\n"
            + "\n"
            + "TOTAL,,100,,USD,,,,"
        let parseResult = try CSVParser.parse(string: csv)
        let (items, _) = CSVImportService.importBudget(from: parseResult)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].name, "Item")
    }

    // MARK: - Permit Import

    func testImportPermits() throws {
        // swiftlint:disable:next line_length
        let csv = "Name,Type,Status,Issuing Authority,Deadline,Cost,Currency,Permit Number,Notes\n"
            + "Wilderness Permit,Wilderness Permit,obtained,NPS,2026-05-01,0,USD,WP-2026-001,Approved"
        let parseResult = try CSVParser.parse(string: csv)
        let (items, result) = CSVImportService.importPermits(from: parseResult)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(result.errorCount, 0)

        XCTAssertEqual(items[0].name, "Wilderness Permit")
        XCTAssertEqual(items[0].permitType, .wilderness)
        XCTAssertEqual(items[0].status, .obtained)
        XCTAssertEqual(items[0].issuingAuthority, "NPS")
        XCTAssertEqual(items[0].permitNumber, "WP-2026-001")
    }

    // MARK: - Resupply Import

    func testImportResupply() throws {
        // swiftlint:disable:next line_length
        let csv = "Name,Day,Arrival Date,Latitude,Longitude,Post Office,Groceries,Fuel,Lodging,Restaurant,Description\n"
            + "Wiseman,8,2026-06-22,67.410000,-150.110000,No,Yes,No,Yes,No,Small community"
        let parseResult = try CSVParser.parse(string: csv)
        let (items, result) = CSVImportService.importResupply(from: parseResult)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(result.errorCount, 0)

        XCTAssertEqual(items[0].name, "Wiseman")
        XCTAssertEqual(items[0].dayNumber, 8)
        XCTAssertEqual(items[0].latitude!, 67.41, accuracy: 0.001)
        XCTAssertEqual(items[0].longitude!, -150.11, accuracy: 0.001)
        XCTAssertFalse(items[0].hasPostOffice)
        XCTAssertTrue(items[0].hasGroceries)
        XCTAssertTrue(items[0].hasLodging)
    }

    // MARK: - Helper Tests

    func testParseBool() {
        XCTAssertTrue(CSVImportService.parseBool("Yes"))
        XCTAssertTrue(CSVImportService.parseBool("yes"))
        XCTAssertTrue(CSVImportService.parseBool("true"))
        XCTAssertTrue(CSVImportService.parseBool("1"))
        XCTAssertFalse(CSVImportService.parseBool("No"))
        XCTAssertFalse(CSVImportService.parseBool("false"))
        XCTAssertFalse(CSVImportService.parseBool("0"))
        XCTAssertFalse(CSVImportService.parseBool(""))
    }

    func testParseDateISO() {
        let date = CSVImportService.parseDate("2026-06-15")
        XCTAssertNotNil(date)
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.year, from: date!), 2026)
        XCTAssertEqual(calendar.component(.month, from: date!), 6)
        XCTAssertEqual(calendar.component(.day, from: date!), 15)
    }

    func testParseDateAbbreviated() {
        let date = CSVImportService.parseDate("Jun 15, 2026")
        XCTAssertNotNil(date)
    }

    func testParseDateUS() {
        let date = CSVImportService.parseDate("06/15/2026")
        XCTAssertNotNil(date)
    }

    func testParseDateEmpty() {
        XCTAssertNil(CSVImportService.parseDate(""))
        XCTAssertNil(CSVImportService.parseDate("  "))
    }

    func testParseEnumCaseInsensitive() {
        let result = CSVImportService.parseEnum("CRITICAL", type: GearPriority.self)
        XCTAssertEqual(result, .critical)
    }

    func testParseEnumExactMatch() {
        let result = CSVImportService.parseEnum("Footwear", type: GearCategory.self)
        XCTAssertEqual(result, .footwear)
    }

    func testParseEnumReturnsNilForUnknown() {
        let result = CSVImportService.parseEnum("nonexistent", type: GearCategory.self)
        XCTAssertNil(result)
    }

    // MARK: - Duplicate Detection

    func testFindDuplicateGearNames() {
        let existing = [GearItem(name: "Trail Runners"), GearItem(name: "Rain Jacket")]
        let newItems = [GearItem(name: "trail runners"), GearItem(name: "Tent")]

        let duplicates = CSVImportService.findDuplicateGearNames(in: newItems, existing: existing)
        XCTAssertEqual(duplicates.count, 1)
        XCTAssertEqual(duplicates[0], "trail runners")
    }

    func testFindDuplicateParticipantNames() {
        let existing = [Participant(name: "Alice Smith")]
        let newItems = [Participant(name: "Alice Smith"), Participant(name: "Bob Jones")]

        let duplicates = CSVImportService.findDuplicateParticipantNames(in: newItems, existing: existing)
        XCTAssertEqual(duplicates.count, 1)
    }

    // MARK: - Round-Trip Tests

    func testRoundTripGear() throws {
        // Create a gear item, export it, parse it back, and verify
        let expedition = Expedition(name: "Test")
        let item = GearItem(name: "Test Pack")
        item.category = .packing
        item.priority = .critical
        item.weightGrams = 1500
        item.quantity = 1
        item.isPacked = true
        item.isInHand = true
        item.isWeighed = true
        item.descriptionOrPurpose = "Main backpack"
        expedition.gearItems = [item]

        let csv = CSVExportService.exportGear(for: expedition)
        let parseResult = try CSVParser.parse(string: csv)
        let (items, result) = CSVImportService.importGear(from: parseResult)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(result.errorCount, 0)
        XCTAssertEqual(items[0].name, "Test Pack")
        XCTAssertEqual(items[0].category, .packing)
        XCTAssertEqual(items[0].priority, .critical)
        XCTAssertEqual(items[0].weightGrams, 1500)
        XCTAssertTrue(items[0].isPacked)
        XCTAssertTrue(items[0].isInHand)
        XCTAssertTrue(items[0].isWeighed)
        XCTAssertEqual(items[0].descriptionOrPurpose, "Main backpack")
    }

    func testRoundTripParticipants() throws {
        let expedition = Expedition(name: "Test")
        let participant = Participant(name: "Test User")
        participant.email = "test@example.com"
        participant.phone = "555-1234"
        participant.role = .guide
        participant.groupAssignment = "Alpha"
        participant.isConfirmed = true
        participant.hasPaid = true
        expedition.participants = [participant]

        let csv = CSVExportService.exportParticipants(for: expedition)
        let parseResult = try CSVParser.parse(string: csv)
        let (items, result) = CSVImportService.importParticipants(from: parseResult)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(result.errorCount, 0)
        XCTAssertEqual(items[0].name, "Test User")
        XCTAssertEqual(items[0].email, "test@example.com")
        XCTAssertEqual(items[0].role, .guide)
        XCTAssertTrue(items[0].isConfirmed)
        XCTAssertTrue(items[0].hasPaid)
    }

    func testRoundTripContacts() throws {
        let expedition = Expedition(name: "Test")
        let contact = Contact(name: "Park Ranger")
        contact.role = "Ranger"
        contact.organization = "NPS"
        contact.category = .emergency
        contact.phone = "907-555-1234"
        contact.email = "ranger@nps.gov"
        contact.location = "Bettles"
        contact.isEmergencyContact = true
        contact.emergencyPriority = 1
        expedition.contacts = [contact]

        let csv = CSVExportService.exportContacts(for: expedition)
        let parseResult = try CSVParser.parse(string: csv)
        let (items, result) = CSVImportService.importContacts(from: parseResult)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(result.errorCount, 0)
        XCTAssertEqual(items[0].name, "Park Ranger")
        XCTAssertEqual(items[0].category, .emergency)
        XCTAssertTrue(items[0].isEmergencyContact)
        XCTAssertEqual(items[0].emergencyPriority, 1)
    }

    func testRoundTripPermits() throws {
        let expedition = Expedition(name: "Test")
        let permit = Permit(name: "Backcountry Permit")
        permit.permitType = .wilderness
        permit.status = .obtained
        permit.issuingAuthority = "NPS"
        permit.cost = 25
        permit.currency = "USD"
        permit.permitNumber = "BC-2026-001"
        permit.notes = "Group camping"
        expedition.permits = [permit]

        let csv = CSVExportService.exportPermits(for: expedition)
        let parseResult = try CSVParser.parse(string: csv)
        let (items, result) = CSVImportService.importPermits(from: parseResult)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(result.errorCount, 0)
        XCTAssertEqual(items[0].name, "Backcountry Permit")
        XCTAssertEqual(items[0].permitType, .wilderness)
        XCTAssertEqual(items[0].status, .obtained)
        XCTAssertEqual(items[0].permitNumber, "BC-2026-001")
    }

    func testRoundTripResupply() throws {
        let expedition = Expedition(name: "Test")
        let point = ResupplyPoint(name: "Wiseman")
        point.dayNumber = 8
        point.latitude = 67.41
        point.longitude = -150.11
        point.hasPostOffice = false
        point.hasGroceries = true
        point.hasFuel = false
        point.hasLodging = true
        point.hasRestaurant = false
        point.resupplyDescription = "Small community on Dalton Highway"
        expedition.resupplyPoints = [point]

        let csv = CSVExportService.exportResupplyPoints(for: expedition)
        let parseResult = try CSVParser.parse(string: csv)
        let (items, result) = CSVImportService.importResupply(from: parseResult)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(result.errorCount, 0)
        XCTAssertEqual(items[0].name, "Wiseman")
        XCTAssertEqual(items[0].dayNumber, 8)
        XCTAssertTrue(items[0].hasGroceries)
        XCTAssertTrue(items[0].hasLodging)
        XCTAssertFalse(items[0].hasPostOffice)
    }
}
