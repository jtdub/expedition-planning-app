import Foundation
import SwiftData
import CoreLocation
import OSLog

private let logger = Logger(subsystem: "com.chaki.app", category: "DayFormViewModel")

@Observable
final class DayFormViewModel {
    enum Mode {
        case create(expedition: Expedition)
        case edit(day: ItineraryDay)
    }

    // MARK: - Properties

    let mode: Mode
    private var modelContext: ModelContext

    // Form fields
    var dayNumber: Int = 1
    var date: Date = Date()
    var hasDate: Bool = false
    var location: String = ""
    var startLocation: String = ""
    var endLocation: String = ""
    var activityType: ActivityType = .fieldWork
    var clientDescription: String = ""
    var guideNotes: String = ""

    // Elevation fields (stored in meters internally)
    var startElevationMeters: Double?
    var endElevationMeters: Double?
    var highPointMeters: Double?
    var lowPointMeters: Double?

    // Coordinates
    var startCoordinate: CLLocationCoordinate2D?
    var endCoordinate: CLLocationCoordinate2D?

    // Distance and timing
    var distanceMeters: Double?
    var estimatedHours: Double?

    // Night tracking
    var nightNumber: Int?
    var campName: String = ""

    // MARK: - Computed Properties

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var title: String {
        isEditing ? "Edit Day \(dayNumber)" : "Add Day"
    }

    var canSave: Bool {
        dayNumber > 0 && (!location.isEmpty || !startLocation.isEmpty || !endLocation.isEmpty)
    }

    var elevationGain: Double? {
        guard let start = startElevationMeters, let end = endElevationMeters else { return nil }
        let gain = end - start
        return gain > 0 ? gain : nil
    }

    var elevationLoss: Double? {
        guard let start = startElevationMeters, let end = endElevationMeters else { return nil }
        let loss = start - end
        return loss > 0 ? loss : nil
    }

    var acclimatizationRisk: AcclimatizationRisk {
        ElevationService.assessRisk(
            startElevationMeters: startElevationMeters,
            endElevationMeters: endElevationMeters
        )
    }

    // MARK: - Initialization

    init(mode: Mode, modelContext: ModelContext) {
        self.mode = mode
        self.modelContext = modelContext
        loadExistingData()
    }

    // MARK: - Data Loading

    private func loadExistingData() {
        switch mode {
        case .create(let expedition):
            let existingDays = expedition.itinerary ?? []
            let sortedDays = existingDays.sorted { $0.dayNumber < $1.dayNumber }
            dayNumber = (sortedDays.last?.dayNumber ?? 0) + 1

            if let lastDay = sortedDays.last, let lastDate = lastDay.date {
                date = Calendar.current.date(byAdding: .day, value: 1, to: lastDate) ?? Date()
                hasDate = true
            } else if let startDate = expedition.startDate {
                date = Calendar.current.date(
                    byAdding: .day,
                    value: existingDays.count,
                    to: startDate
                ) ?? Date()
                hasDate = true
            }

            // Copy last day's end elevation as new day's start elevation
            if let lastDay = sortedDays.last {
                startElevationMeters = lastDay.endElevationMeters
                startCoordinate = lastDay.endCoordinate
                startLocation = lastDay.endLocation
            }

        case .edit(let day):
            dayNumber = day.dayNumber
            if let dayDate = day.date {
                date = dayDate
                hasDate = true
            }
            location = day.location
            startLocation = day.startLocation
            endLocation = day.endLocation
            activityType = day.activityType
            clientDescription = day.clientDescription
            guideNotes = day.guideNotes

            startElevationMeters = day.startElevationMeters
            endElevationMeters = day.endElevationMeters
            highPointMeters = day.highPointMeters
            lowPointMeters = day.lowPointMeters

            if let coord = day.startCoordinate {
                startCoordinate = coord
            }
            if let coord = day.endCoordinate {
                endCoordinate = coord
            }

            distanceMeters = day.distanceMeters
            estimatedHours = day.estimatedHours

            nightNumber = day.nightNumber
            campName = day.campName ?? ""
        }
    }

    // MARK: - Save

    func save() {
        switch mode {
        case .create(let expedition):
            createNewDay(for: expedition)
        case .edit(let day):
            updateExistingDay(day)
        }
    }

    private func createNewDay(for expedition: Expedition) {
        let day = ItineraryDay(
            dayNumber: dayNumber,
            date: hasDate ? date : nil,
            location: location,
            startLocation: startLocation,
            endLocation: endLocation,
            activityType: activityType,
            clientDescription: clientDescription,
            guideNotes: guideNotes
        )

        day.startElevationMeters = startElevationMeters
        day.endElevationMeters = endElevationMeters
        day.highPointMeters = highPointMeters
        day.lowPointMeters = lowPointMeters

        if let coord = startCoordinate {
            day.startLatitude = coord.latitude
            day.startLongitude = coord.longitude
        }
        if let coord = endCoordinate {
            day.endLatitude = coord.latitude
            day.endLongitude = coord.longitude
        }

        day.distanceMeters = distanceMeters
        day.estimatedHours = estimatedHours
        day.nightNumber = nightNumber
        day.campName = campName.isEmpty ? nil : campName

        day.expedition = expedition
        if expedition.itinerary == nil {
            expedition.itinerary = []
        }
        expedition.itinerary?.append(day)
        modelContext.insert(day)

        logger.info("Created day \(day.dayNumber) for expedition \(expedition.name)")
        saveContext()
    }

    private func updateExistingDay(_ day: ItineraryDay) {
        day.dayNumber = dayNumber
        day.date = hasDate ? date : nil
        day.location = location
        day.startLocation = startLocation
        day.endLocation = endLocation
        day.activityType = activityType
        day.clientDescription = clientDescription
        day.guideNotes = guideNotes

        day.startElevationMeters = startElevationMeters
        day.endElevationMeters = endElevationMeters
        day.highPointMeters = highPointMeters
        day.lowPointMeters = lowPointMeters

        if let coord = startCoordinate {
            day.startLatitude = coord.latitude
            day.startLongitude = coord.longitude
        } else {
            day.startLatitude = nil
            day.startLongitude = nil
        }
        if let coord = endCoordinate {
            day.endLatitude = coord.latitude
            day.endLongitude = coord.longitude
        } else {
            day.endLatitude = nil
            day.endLongitude = nil
        }

        day.distanceMeters = distanceMeters
        day.estimatedHours = estimatedHours
        day.nightNumber = nightNumber
        day.campName = campName.isEmpty ? nil : campName

        day.expedition?.updatedAt = Date()

        logger.info("Updated day \(day.dayNumber)")
        saveContext()
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save day: \(error.localizedDescription)")
        }
    }

    // MARK: - Elevation Input Helpers

    func setStartElevation(_ value: Double?, unit: ElevationUnit) {
        if let value {
            startElevationMeters = ElevationService.convert(value, from: unit, to: .meters)
        } else {
            startElevationMeters = nil
        }
    }

    func setEndElevation(_ value: Double?, unit: ElevationUnit) {
        if let value {
            endElevationMeters = ElevationService.convert(value, from: unit, to: .meters)
        } else {
            endElevationMeters = nil
        }
    }

    func setHighPoint(_ value: Double?, unit: ElevationUnit) {
        if let value {
            highPointMeters = ElevationService.convert(value, from: unit, to: .meters)
        } else {
            highPointMeters = nil
        }
    }

    func setLowPoint(_ value: Double?, unit: ElevationUnit) {
        if let value {
            lowPointMeters = ElevationService.convert(value, from: unit, to: .meters)
        } else {
            lowPointMeters = nil
        }
    }

    func startElevation(in unit: ElevationUnit) -> Double? {
        guard let meters = startElevationMeters else { return nil }
        return ElevationService.convert(meters, from: .meters, to: unit)
    }

    func endElevation(in unit: ElevationUnit) -> Double? {
        guard let meters = endElevationMeters else { return nil }
        return ElevationService.convert(meters, from: .meters, to: unit)
    }

    func highPoint(in unit: ElevationUnit) -> Double? {
        guard let meters = highPointMeters else { return nil }
        return ElevationService.convert(meters, from: .meters, to: unit)
    }

    func lowPoint(in unit: ElevationUnit) -> Double? {
        guard let meters = lowPointMeters else { return nil }
        return ElevationService.convert(meters, from: .meters, to: unit)
    }
}
