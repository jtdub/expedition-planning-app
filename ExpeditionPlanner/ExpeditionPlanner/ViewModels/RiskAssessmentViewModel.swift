import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.expedition.planner", category: "RiskAssessmentViewModel")

enum RiskSortOrder: String, CaseIterable {
    case riskScore = "Risk Score"
    case hazardType = "Hazard Type"
    case title = "Title"
    case status = "Status"
}

@Observable
final class RiskAssessmentViewModel {
    private var modelContext: ModelContext

    var assessments: [RiskAssessment] = []
    var searchText: String = ""
    var filterHazardType: HazardType?
    var filterRiskRating: RiskRating?
    var showUnaddressedOnly: Bool = false
    var sortOrder: RiskSortOrder = .riskScore
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadAssessments(for expedition: Expedition) {
        let allAssessments = expedition.riskAssessments ?? []

        var filtered = allAssessments

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { assessment in
                assessment.title.localizedCaseInsensitiveContains(searchText) ||
                assessment.riskDescription.localizedCaseInsensitiveContains(searchText) ||
                assessment.mitigationStrategy.localizedCaseInsensitiveContains(searchText) ||
                (assessment.location ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply hazard type filter
        if let hazardType = filterHazardType {
            filtered = filtered.filter { $0.hazardType == hazardType }
        }

        // Apply risk rating filter
        if let riskRating = filterRiskRating {
            filtered = filtered.filter { $0.riskRating == riskRating }
        }

        // Apply unaddressed filter
        if showUnaddressedOnly {
            filtered = filtered.filter { !$0.isAddressed }
        }

        // Sort
        switch sortOrder {
        case .riskScore:
            assessments = filtered.sorted { $0.riskScore > $1.riskScore }
        case .hazardType:
            assessments = filtered.sorted { a1, a2 in
                if a1.hazardType != a2.hazardType {
                    return a1.hazardType.rawValue < a2.hazardType.rawValue
                }
                return a1.riskScore > a2.riskScore
            }
        case .title:
            assessments = filtered.sorted { $0.title < $1.title }
        case .status:
            assessments = filtered.sorted { a1, a2 in
                if a1.isAddressed != a2.isAddressed {
                    return !a1.isAddressed
                }
                return a1.riskScore > a2.riskScore
            }
        }
    }

    // MARK: - CRUD Operations

    func addAssessment(_ assessment: RiskAssessment, to expedition: Expedition) {
        assessment.expedition = expedition
        if expedition.riskAssessments == nil {
            expedition.riskAssessments = []
        }
        expedition.riskAssessments?.append(assessment)
        modelContext.insert(assessment)

        logger.info("Added risk assessment '\(assessment.title)' to expedition")
        saveContext()
        loadAssessments(for: expedition)
    }

    func deleteAssessment(_ assessment: RiskAssessment, from expedition: Expedition) {
        let title = assessment.title
        expedition.riskAssessments?.removeAll { $0.id == assessment.id }
        modelContext.delete(assessment)

        logger.info("Deleted risk assessment '\(title)' from expedition")
        saveContext()
        loadAssessments(for: expedition)
    }

    func updateAssessment(_ assessment: RiskAssessment, in expedition: Expedition) {
        logger.debug("Updated risk assessment '\(assessment.title)'")
        saveContext()
        loadAssessments(for: expedition)
    }

    // MARK: - Computed Properties

    var criticalRisks: [RiskAssessment] {
        assessments.filter { $0.riskRating == .critical && !$0.isAddressed }
            .sorted { $0.riskScore > $1.riskScore }
    }

    var highRisks: [RiskAssessment] {
        assessments.filter { $0.riskRating == .high && !$0.isAddressed }
            .sorted { $0.riskScore > $1.riskScore }
    }

    var needsAttentionCount: Int {
        assessments.filter { $0.needsAttention }.count
    }

    var addressedCount: Int {
        assessments.filter { $0.isAddressed }.count
    }

    var hazardTypeCounts: [HazardType: Int] {
        var counts: [HazardType: Int] = [:]
        for assessment in assessments {
            counts[assessment.hazardType, default: 0] += 1
        }
        return counts
    }

    var riskRatingCounts: [RiskRating: Int] {
        var counts: [RiskRating: Int] = [:]
        for assessment in assessments {
            counts[assessment.riskRating, default: 0] += 1
        }
        return counts
    }

    var groupedByHazardType: [(hazardType: HazardType, assessments: [RiskAssessment])] {
        let grouped = Dictionary(grouping: assessments) { $0.hazardType }
        return HazardType.allCases.compactMap { hazardType in
            guard let list = grouped[hazardType], !list.isEmpty else { return nil }
            return (hazardType: hazardType, assessments: list.sorted { $0.riskScore > $1.riskScore })
        }
    }

    var groupedByRiskRating: [(rating: RiskRating, assessments: [RiskAssessment])] {
        let grouped = Dictionary(grouping: assessments) { $0.riskRating }
        // Sort by rating severity (critical first)
        let sortedRatings: [RiskRating] = [.critical, .high, .medium, .low]
        return sortedRatings.compactMap { rating in
            guard let list = grouped[rating], !list.isEmpty else { return nil }
            return (rating: rating, assessments: list.sorted { $0.riskScore > $1.riskScore })
        }
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
        filterHazardType = nil
        filterRiskRating = nil
        showUnaddressedOnly = false
    }

    var hasActiveFilters: Bool {
        filterHazardType != nil || filterRiskRating != nil || showUnaddressedOnly || !searchText.isEmpty
    }

    // MARK: - Risk Matrix

    func assessmentsForMatrix(likelihood: RiskLevel, severity: RiskLevel) -> [RiskAssessment] {
        assessments.filter { $0.likelihood == likelihood && $0.severity == severity }
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save risk assessment changes: \(error.localizedDescription)")
        }
    }
}
