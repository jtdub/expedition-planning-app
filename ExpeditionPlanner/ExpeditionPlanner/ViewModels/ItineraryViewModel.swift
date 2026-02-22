import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.expedition.planner", category: "ItineraryViewModel")

@Observable
final class ItineraryViewModel {
    // MARK: - Properties

    private(set) var expedition: Expedition
    private var modelContext: ModelContext

    var filterActivityType: ActivityType?
    var showChartSection: Bool = true

    // MARK: - Initialization

    init(expedition: Expedition, modelContext: ModelContext) {
        self.expedition = expedition
        self.modelContext = modelContext
    }

    // MARK: - Computed Properties

    var sortedDays: [ItineraryDay] {
        let days = expedition.itinerary ?? []
        return days.sorted { $0.dayNumber < $1.dayNumber }
    }

    var filteredDays: [ItineraryDay] {
        guard let filter = filterActivityType else {
            return sortedDays
        }
        return sortedDays.filter { $0.activityType == filter }
    }

    var elevationChartData: [ElevationService.ElevationPoint] {
        ElevationService.chartData(from: sortedDays)
    }

    var elevationSummary: ElevationService.ElevationSummary {
        ElevationService.summary(from: sortedDays)
    }

    var daysWithWarnings: [ItineraryDay] {
        sortedDays.filter { ElevationService.assessRisk(for: $0) != .none }
    }

    var warningCount: Int {
        daysWithWarnings.count
    }

    var highRiskCount: Int {
        sortedDays.filter {
            let risk = ElevationService.assessRisk(for: $0)
            return risk == .high || risk == .extreme
        }.count
    }

    var totalDays: Int {
        sortedDays.count
    }

    var nextDayNumber: Int {
        (sortedDays.last?.dayNumber ?? 0) + 1
    }

    var nextDate: Date? {
        if let lastDay = sortedDays.last, let lastDate = lastDay.date {
            return Calendar.current.date(byAdding: .day, value: 1, to: lastDate)
        }
        return expedition.startDate
    }

    // MARK: - CRUD Operations

    func addDay(
        dayNumber: Int? = nil,
        date: Date? = nil,
        location: String = "",
        startLocation: String = "",
        endLocation: String = "",
        activityType: ActivityType = .fieldWork,
        clientDescription: String = "",
        guideNotes: String = ""
    ) -> ItineraryDay {
        let day = ItineraryDay(
            dayNumber: dayNumber ?? nextDayNumber,
            date: date ?? nextDate,
            location: location,
            startLocation: startLocation,
            endLocation: endLocation,
            activityType: activityType,
            clientDescription: clientDescription,
            guideNotes: guideNotes
        )

        day.expedition = expedition
        if expedition.itinerary == nil {
            expedition.itinerary = []
        }
        expedition.itinerary?.append(day)
        modelContext.insert(day)

        logger.info("Added day \(day.dayNumber) to expedition \(self.expedition.name)")
        save()

        return day
    }

    func deleteDay(_ day: ItineraryDay) {
        let dayNumber = day.dayNumber
        expedition.itinerary?.removeAll { $0.id == day.id }
        modelContext.delete(day)

        logger.info("Deleted day \(dayNumber) from expedition \(self.expedition.name)")
        save()
    }

    func deleteDays(at offsets: IndexSet) {
        let daysToDelete = offsets.map { filteredDays[$0] }
        for day in daysToDelete {
            deleteDay(day)
        }
    }

    func moveDays(from source: IndexSet, to destination: Int) {
        var days = sortedDays
        days.move(fromOffsets: source, toOffset: destination)
        renumberDays(days)
    }

    func renumberDays(_ days: [ItineraryDay]? = nil) {
        let daysToRenumber = days ?? sortedDays

        for (index, day) in daysToRenumber.enumerated() {
            day.dayNumber = index + 1
        }

        logger.info("Renumbered \(daysToRenumber.count) days")
        save()
    }

    func duplicateDay(_ day: ItineraryDay) -> ItineraryDay {
        let newDay = ItineraryDay(
            dayNumber: nextDayNumber,
            date: nextDate,
            location: day.location,
            startLocation: day.startLocation,
            endLocation: day.endLocation,
            activityType: day.activityType,
            clientDescription: day.clientDescription,
            guideNotes: day.guideNotes
        )

        // Copy elevation data
        newDay.startElevationMeters = day.startElevationMeters
        newDay.endElevationMeters = day.endElevationMeters
        newDay.highPointMeters = day.highPointMeters
        newDay.lowPointMeters = day.lowPointMeters

        // Copy coordinates
        newDay.startLatitude = day.startLatitude
        newDay.startLongitude = day.startLongitude
        newDay.endLatitude = day.endLatitude
        newDay.endLongitude = day.endLongitude

        // Copy distance/timing
        newDay.distanceMeters = day.distanceMeters
        newDay.estimatedHours = day.estimatedHours

        newDay.expedition = expedition
        expedition.itinerary?.append(newDay)
        modelContext.insert(newDay)

        logger.info("Duplicated day \(day.dayNumber) as day \(newDay.dayNumber)")
        save()

        return newDay
    }

    // MARK: - Filtering

    func setFilter(_ activityType: ActivityType?) {
        filterActivityType = activityType
    }

    func clearFilter() {
        filterActivityType = nil
    }

    // MARK: - Persistence

    private func save() {
        do {
            try modelContext.save()
            expedition.updatedAt = Date()
        } catch {
            logger.error("Failed to save itinerary changes: \(error.localizedDescription)")
        }
    }

    // MARK: - Statistics

    var activityTypeCounts: [ActivityType: Int] {
        var counts: [ActivityType: Int] = [:]
        for day in sortedDays {
            counts[day.activityType, default: 0] += 1
        }
        return counts
    }

    var totalDistance: Measurement<UnitLength>? {
        let totalMeters = sortedDays.compactMap { $0.distanceMeters }.reduce(0, +)
        guard totalMeters > 0 else { return nil }
        return Measurement(value: totalMeters, unit: .meters)
    }

    var totalEstimatedHours: Double {
        sortedDays.compactMap { $0.estimatedHours }.reduce(0, +)
    }
}
