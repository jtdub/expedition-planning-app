import XCTest
import SwiftData
@testable import Chaki

@MainActor
final class ItineraryViewModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var expedition: Expedition!

    override func setUp() async throws {
        let schema = Schema([
            Expedition.self,
            ItineraryDay.self,
            GearItem.self,
            Participant.self,
            Contact.self,
            ResupplyPoint.self,
            Permit.self,
            BudgetItem.self,
            RiskAssessment.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = container.mainContext

        expedition = Expedition(name: "Test Expedition", location: "Alaska")
        context.insert(expedition)
        try context.save()
    }

    override func tearDown() async throws {
        container = nil
        context = nil
        expedition = nil
    }

    // MARK: - Initialization Tests

    func testViewModelInitialization() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        XCTAssertEqual(viewModel.totalDays, 0)
        XCTAssertTrue(viewModel.sortedDays.isEmpty)
        XCTAssertNil(viewModel.filterActivityType)
    }

    // MARK: - Add Day Tests

    func testAddDay() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        let day = viewModel.addDay(
            location: "Base Camp",
            activityType: .basecamp
        )

        XCTAssertEqual(viewModel.totalDays, 1)
        XCTAssertEqual(day.dayNumber, 1)
        XCTAssertEqual(day.location, "Base Camp")
        XCTAssertEqual(day.activityType, .basecamp)
        XCTAssertNotNil(day.expedition)
    }

    func testAddMultipleDays() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        _ = viewModel.addDay(location: "Day 1")
        _ = viewModel.addDay(location: "Day 2")
        _ = viewModel.addDay(location: "Day 3")

        XCTAssertEqual(viewModel.totalDays, 3)
        XCTAssertEqual(viewModel.sortedDays[0].dayNumber, 1)
        XCTAssertEqual(viewModel.sortedDays[1].dayNumber, 2)
        XCTAssertEqual(viewModel.sortedDays[2].dayNumber, 3)
    }

    func testNextDayNumber() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        XCTAssertEqual(viewModel.nextDayNumber, 1)

        _ = viewModel.addDay()
        XCTAssertEqual(viewModel.nextDayNumber, 2)

        _ = viewModel.addDay()
        XCTAssertEqual(viewModel.nextDayNumber, 3)
    }

    // MARK: - Delete Day Tests

    func testDeleteDay() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        let day = viewModel.addDay(location: "To Delete")
        XCTAssertEqual(viewModel.totalDays, 1)

        viewModel.deleteDay(day)
        XCTAssertEqual(viewModel.totalDays, 0)
    }

    func testDeleteDaysAtOffsets() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        _ = viewModel.addDay(location: "Day 1")
        _ = viewModel.addDay(location: "Day 2")
        _ = viewModel.addDay(location: "Day 3")

        viewModel.deleteDays(at: IndexSet(integer: 1)) // Delete "Day 2"

        XCTAssertEqual(viewModel.totalDays, 2)
        XCTAssertEqual(viewModel.sortedDays[0].location, "Day 1")
        XCTAssertEqual(viewModel.sortedDays[1].location, "Day 3")
    }

    // MARK: - Reorder Tests

    func testMoveDays() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        _ = viewModel.addDay(location: "First")
        _ = viewModel.addDay(location: "Second")
        _ = viewModel.addDay(location: "Third")

        // Move "Third" to first position
        viewModel.moveDays(from: IndexSet(integer: 2), to: 0)

        XCTAssertEqual(viewModel.sortedDays[0].location, "Third")
        XCTAssertEqual(viewModel.sortedDays[0].dayNumber, 1)
        XCTAssertEqual(viewModel.sortedDays[1].location, "First")
        XCTAssertEqual(viewModel.sortedDays[1].dayNumber, 2)
    }

    func testRenumberDays() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        let day1 = viewModel.addDay(location: "A")
        let day2 = viewModel.addDay(location: "B")
        let day3 = viewModel.addDay(location: "C")

        // Manually mess up the numbers
        day1.dayNumber = 5
        day2.dayNumber = 10
        day3.dayNumber = 15

        viewModel.renumberDays()

        XCTAssertEqual(viewModel.sortedDays[0].dayNumber, 1)
        XCTAssertEqual(viewModel.sortedDays[1].dayNumber, 2)
        XCTAssertEqual(viewModel.sortedDays[2].dayNumber, 3)
    }

    // MARK: - Duplicate Tests

    func testDuplicateDay() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        let original = viewModel.addDay(
            location: "Original",
            startLocation: "Start",
            endLocation: "End",
            activityType: .fieldWork
        )
        original.startElevationMeters = 3000
        original.endElevationMeters = 3500
        original.estimatedHours = 6

        let duplicate = viewModel.duplicateDay(original)

        XCTAssertEqual(viewModel.totalDays, 2)
        XCTAssertEqual(duplicate.dayNumber, 2)
        XCTAssertEqual(duplicate.location, "Original")
        XCTAssertEqual(duplicate.startElevationMeters, 3000)
        XCTAssertEqual(duplicate.endElevationMeters, 3500)
        XCTAssertEqual(duplicate.estimatedHours, 6)
        XCTAssertNotEqual(original.id, duplicate.id)
    }

    // MARK: - Filter Tests

    func testFilterByActivityType() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        _ = viewModel.addDay(activityType: .fieldWork)
        _ = viewModel.addDay(activityType: .restDay)
        _ = viewModel.addDay(activityType: .fieldWork)
        _ = viewModel.addDay(activityType: .summit)

        XCTAssertEqual(viewModel.filteredDays.count, 4)

        viewModel.setFilter(.fieldWork)
        XCTAssertEqual(viewModel.filteredDays.count, 2)

        viewModel.setFilter(.restDay)
        XCTAssertEqual(viewModel.filteredDays.count, 1)

        viewModel.clearFilter()
        XCTAssertEqual(viewModel.filteredDays.count, 4)
    }

    // MARK: - Elevation Data Tests

    func testElevationChartData() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        let day1 = viewModel.addDay(activityType: .fieldWork)
        day1.startElevationMeters = 3000
        day1.endElevationMeters = 3500

        let day2 = viewModel.addDay(activityType: .restDay)
        day2.startElevationMeters = 3500
        day2.endElevationMeters = 3500

        let chartData = viewModel.elevationChartData

        XCTAssertEqual(chartData.count, 2)
        XCTAssertEqual(chartData[0].dayNumber, 1)
        XCTAssertEqual(chartData[0].displayElevation, 3500)
        XCTAssertEqual(chartData[1].dayNumber, 2)
    }

    func testWarningCounts() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        // Safe day
        let day1 = viewModel.addDay()
        day1.startElevationMeters = 3000
        day1.endElevationMeters = 3200

        // Moderate risk day
        let day2 = viewModel.addDay()
        day2.startElevationMeters = 3200
        day2.endElevationMeters = 3600

        // High risk day
        let day3 = viewModel.addDay()
        day3.startElevationMeters = 3600
        day3.endElevationMeters = 4300

        XCTAssertEqual(viewModel.warningCount, 2) // moderate + high
        XCTAssertEqual(viewModel.highRiskCount, 1) // only high
    }

    // MARK: - Statistics Tests

    func testActivityTypeCounts() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        _ = viewModel.addDay(activityType: .fieldWork)
        _ = viewModel.addDay(activityType: .fieldWork)
        _ = viewModel.addDay(activityType: .restDay)
        _ = viewModel.addDay(activityType: .summit)
        _ = viewModel.addDay(activityType: .fieldWork)

        let counts = viewModel.activityTypeCounts

        XCTAssertEqual(counts[.fieldWork], 3)
        XCTAssertEqual(counts[.restDay], 1)
        XCTAssertEqual(counts[.summit], 1)
        XCTAssertNil(counts[.acclimatization])
    }

    func testTotalDistance() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        let day1 = viewModel.addDay()
        day1.distanceMeters = 10000

        let day2 = viewModel.addDay()
        day2.distanceMeters = 15000

        let day3 = viewModel.addDay()
        // No distance set

        let totalDistance = viewModel.totalDistance
        XCTAssertNotNil(totalDistance)
        if let distance = totalDistance {
            XCTAssertEqual(distance.value, 25000, accuracy: 0.1)
        }
    }

    func testTotalEstimatedHours() throws {
        let viewModel = ItineraryViewModel(expedition: expedition, modelContext: context)

        let day1 = viewModel.addDay()
        day1.estimatedHours = 6.5

        let day2 = viewModel.addDay()
        day2.estimatedHours = 8

        let day3 = viewModel.addDay()
        day3.estimatedHours = 4.5

        XCTAssertEqual(viewModel.totalEstimatedHours, 19, accuracy: 0.01)
    }
}
