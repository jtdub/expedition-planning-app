import XCTest
import SwiftData
@testable import Chaki

final class ExpeditionTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([Expedition.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    // MARK: - Creation Tests

    func testExpeditionCreation() throws {
        let expedition = Expedition(
            name: "Alaska 2026",
            expeditionDescription: "Brooks Range traverse",
            startDate: Date(),
            endDate: Date().adding(days: 14),
            status: .planning,
            location: "Brooks Range, AK"
        )

        XCTAssertNotNil(expedition.id)
        XCTAssertEqual(expedition.name, "Alaska 2026")
        XCTAssertEqual(expedition.status, .planning)
        XCTAssertEqual(expedition.location, "Brooks Range, AK")
        XCTAssertNotNil(expedition.createdAt)
    }

    func testExpeditionDefaultValues() throws {
        let expedition = Expedition(name: "Test")

        XCTAssertEqual(expedition.status, .planning)
        XCTAssertTrue(expedition.expeditionDescription.isEmpty)
        XCTAssertTrue(expedition.location.isEmpty)
        XCTAssertNil(expedition.startDate)
        XCTAssertNil(expedition.endDate)
        XCTAssertTrue(expedition.itinerary?.isEmpty ?? true)
        XCTAssertTrue(expedition.gearItems?.isEmpty ?? true)
        XCTAssertTrue(expedition.participants?.isEmpty ?? true)
    }

    // MARK: - Computed Properties Tests

    func testTotalDays() throws {
        let startDate = Date()
        let endDate = startDate.adding(days: 10)

        let expedition = Expedition(
            name: "Test",
            startDate: startDate,
            endDate: endDate
        )

        XCTAssertEqual(expedition.totalDays, 10)
    }

    func testTotalDaysWithoutDates() throws {
        let expedition = Expedition(name: "Test")
        XCTAssertEqual(expedition.totalDays, 0)
    }

    func testTotalBudget() throws {
        let expedition = Expedition(name: "Test")
        modelContext.insert(expedition)

        let item1 = BudgetItem(name: "Flights", estimatedAmount: 1000)
        item1.expedition = expedition

        let item2 = BudgetItem(name: "Gear", estimatedAmount: 500)
        item2.expedition = expedition

        expedition.budgetItems = [item1, item2]

        XCTAssertEqual(expedition.totalBudget, 1500)
    }

    // MARK: - Status Tests

    func testExpeditionStatusValues() throws {
        XCTAssertEqual(ExpeditionStatus.planning.rawValue, "Planning")
        XCTAssertEqual(ExpeditionStatus.active.rawValue, "Active")
        XCTAssertEqual(ExpeditionStatus.completed.rawValue, "Completed")

        XCTAssertEqual(ExpeditionStatus.planning.icon, "pencil.circle")
        XCTAssertEqual(ExpeditionStatus.active.icon, "figure.hiking")
    }

    // MARK: - Persistence Tests

    func testExpeditionPersistence() throws {
        let expedition = Expedition(name: "Persistence Test", location: "Test Location")
        modelContext.insert(expedition)
        try modelContext.save()

        let descriptor = FetchDescriptor<Expedition>()
        let expeditions = try modelContext.fetch(descriptor)

        XCTAssertEqual(expeditions.count, 1)
        XCTAssertEqual(expeditions.first?.name, "Persistence Test")
    }

    func testExpeditionDeletion() throws {
        let expedition = Expedition(name: "Delete Test")
        modelContext.insert(expedition)
        try modelContext.save()

        modelContext.delete(expedition)
        try modelContext.save()

        let descriptor = FetchDescriptor<Expedition>()
        let expeditions = try modelContext.fetch(descriptor)

        XCTAssertEqual(expeditions.count, 0)
    }
}
