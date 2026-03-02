import Foundation
import SwiftData

@Model
final class Expedition {
    var id: UUID = UUID()
    var name: String = ""
    var expeditionDescription: String = ""
    var startDate: Date?
    var endDate: Date?
    var status: ExpeditionStatus = ExpeditionStatus.planning
    var location: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Relationships - must be optional for CloudKit
    @Relationship(deleteRule: .cascade, inverse: \ItineraryDay.expedition)
    var itinerary: [ItineraryDay]?

    @Relationship(deleteRule: .cascade, inverse: \GearItem.expedition)
    var gearItems: [GearItem]?

    @Relationship(deleteRule: .cascade, inverse: \Participant.expedition)
    var participants: [Participant]?

    @Relationship(deleteRule: .cascade, inverse: \Contact.expedition)
    var contacts: [Contact]?

    @Relationship(deleteRule: .cascade, inverse: \ResupplyPoint.expedition)
    var resupplyPoints: [ResupplyPoint]?

    @Relationship(deleteRule: .cascade, inverse: \Permit.expedition)
    var permits: [Permit]?

    @Relationship(deleteRule: .cascade, inverse: \BudgetItem.expedition)
    var budgetItems: [BudgetItem]?

    @Relationship(deleteRule: .cascade, inverse: \RiskAssessment.expedition)
    var riskAssessments: [RiskAssessment]?

    @Relationship(deleteRule: .cascade, inverse: \InsurancePolicy.expedition)
    var insurancePolicies: [InsurancePolicy]?

    @Relationship(deleteRule: .cascade, inverse: \TransportLeg.expedition)
    var transportLegs: [TransportLeg]?

    @Relationship(deleteRule: .cascade, inverse: \Accommodation.expedition)
    var accommodations: [Accommodation]?

    @Relationship(deleteRule: .cascade, inverse: \SatelliteDevice.expedition)
    var satelliteDevices: [SatelliteDevice]?

    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.expedition)
    var checklistItems: [ChecklistItem]?

    @Relationship(deleteRule: .cascade, inverse: \EscapeRoute.expedition)
    var escapeRoutes: [EscapeRoute]?

    @Relationship(deleteRule: .cascade, inverse: \RouteSegment.expedition)
    var routeSegments: [RouteSegment]?

    @Relationship(deleteRule: .cascade, inverse: \WaterSource.expedition)
    var waterSources: [WaterSource]?

    @Relationship(deleteRule: .cascade, inverse: \TravelDocument.expedition)
    var travelDocuments: [TravelDocument]?

    @Relationship(deleteRule: .cascade, inverse: \MealPlan.expedition)
    var mealPlans: [MealPlan]?

    init(
        name: String = "",
        expeditionDescription: String = "",
        startDate: Date? = nil,
        endDate: Date? = nil,
        status: ExpeditionStatus = .planning,
        location: String = "",
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.expeditionDescription = expeditionDescription
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.location = location
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    var totalDays: Int {
        guard let start = startDate, let end = endDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }

    var sortedItinerary: [ItineraryDay] {
        (itinerary ?? []).sorted { $0.dayNumber < $1.dayNumber }
    }

    var totalBudget: Decimal {
        (budgetItems ?? []).reduce(0) { $0 + $1.estimatedAmount }
    }

    var actualSpend: Decimal {
        (budgetItems ?? []).compactMap { $0.actualAmount }.reduce(0, +)
    }

    var participantCount: Int {
        (participants ?? []).count
    }

    var gearWeight: Measurement<UnitMass> {
        let totalGrams = (gearItems ?? []).compactMap { $0.weight }.reduce(0.0) {
            $0 + $1.converted(to: .grams).value
        }
        return Measurement(value: totalGrams, unit: .grams)
    }
}

// MARK: - Expedition Status

enum ExpeditionStatus: String, Codable, CaseIterable {
    case planning = "Planning"
    case prepared = "Prepared"
    case active = "Active"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var icon: String {
        switch self {
        case .planning: return "pencil.circle"
        case .prepared: return "checkmark.circle"
        case .active: return "figure.hiking"
        case .completed: return "flag.checkered"
        case .cancelled: return "xmark.circle"
        }
    }

    var color: String {
        switch self {
        case .planning: return "blue"
        case .prepared: return "orange"
        case .active: return "green"
        case .completed: return "gray"
        case .cancelled: return "red"
        }
    }
}
