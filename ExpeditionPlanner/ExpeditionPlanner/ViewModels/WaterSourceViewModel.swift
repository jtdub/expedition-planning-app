import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.chaki.app", category: "WaterSourceViewModel")

enum WaterSourceSortOrder: String, CaseIterable {
    case type = "Type"
    case reliability = "Reliability"
    case name = "Name"
}

@Observable
final class WaterSourceViewModel {
    private var modelContext: ModelContext

    var sources: [WaterSource] = []
    var searchText: String = ""
    var filterSourceType: WaterSourceType?
    var filterReliability: ReliabilityRating?
    var sortOrder: WaterSourceSortOrder = .name
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadSources(for expedition: Expedition) {
        let allSources = expedition.waterSources ?? []

        var filtered = allSources

        if !searchText.isEmpty {
            filtered = filtered.filter { source in
                source.name.localizedCaseInsensitiveContains(searchText) ||
                source.seasonalNotes.localizedCaseInsensitiveContains(searchText) ||
                source.notes.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let sourceType = filterSourceType {
            filtered = filtered.filter { $0.sourceType == sourceType }
        }

        if let reliability = filterReliability {
            filtered = filtered.filter { $0.reliability == reliability }
        }

        switch sortOrder {
        case .type:
            sources = filtered.sorted { s1, s2 in
                if s1.sourceType.rawValue != s2.sourceType.rawValue {
                    return s1.sourceType.rawValue < s2.sourceType.rawValue
                }
                return s1.name < s2.name
            }
        case .reliability:
            sources = filtered.sorted { s1, s2 in
                if s1.reliability.rawValue != s2.reliability.rawValue {
                    return s1.reliability.rawValue < s2.reliability.rawValue
                }
                return s1.name < s2.name
            }
        case .name:
            sources = filtered.sorted { $0.name < $1.name }
        }
    }

    // MARK: - CRUD Operations

    func addSource(_ source: WaterSource, to expedition: Expedition) {
        source.expedition = expedition
        if expedition.waterSources == nil {
            expedition.waterSources = []
        }
        expedition.waterSources?.append(source)
        modelContext.insert(source)

        logger.info("Added water source '\(source.name)' to expedition")
        saveContext()
        loadSources(for: expedition)
    }

    func deleteSource(_ source: WaterSource, from expedition: Expedition) {
        let name = source.name
        expedition.waterSources?.removeAll { $0.id == source.id }
        modelContext.delete(source)

        logger.info("Deleted water source '\(name)' from expedition")
        saveContext()
        loadSources(for: expedition)
    }

    func updateSource(_ source: WaterSource, in expedition: Expedition) {
        logger.debug("Updated water source '\(source.name)'")
        saveContext()
        loadSources(for: expedition)
    }

    // MARK: - Computed Properties

    var verifiedCount: Int {
        sources.filter { $0.isVerified }.count
    }

    var needsTreatmentCount: Int {
        sources.filter { $0.needsTreatment }.count
    }

    var groupedByType: [(sourceType: WaterSourceType, sources: [WaterSource])] {
        let grouped = Dictionary(grouping: sources) { $0.sourceType }
        return WaterSourceType.allCases.compactMap { type in
            guard let list = grouped[type], !list.isEmpty else { return nil }
            return (sourceType: type, sources: list)
        }
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
        filterSourceType = nil
        filterReliability = nil
    }

    var hasActiveFilters: Bool {
        filterSourceType != nil || filterReliability != nil || !searchText.isEmpty
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save water source changes: \(error.localizedDescription)")
        }
    }
}
