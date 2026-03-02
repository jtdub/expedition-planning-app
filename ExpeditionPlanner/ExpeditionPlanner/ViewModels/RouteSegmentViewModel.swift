import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.chaki.app", category: "RouteSegmentViewModel")

enum RouteSegmentSortOrder: String, CaseIterable {
    case terrain = "Terrain"
    case dayNumber = "Day Number"
    case name = "Name"
    case distance = "Distance"
    case difficulty = "Difficulty"
}

@Observable
final class RouteSegmentViewModel {
    private var modelContext: ModelContext

    var segments: [RouteSegment] = []
    var searchText: String = ""
    var filterTerrainType: TerrainType?
    var filterDifficulty: DifficultyRating?
    var sortOrder: RouteSegmentSortOrder = .dayNumber
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadSegments(for expedition: Expedition) {
        let allSegments = expedition.routeSegments ?? []

        var filtered = allSegments

        if !searchText.isEmpty {
            filtered = filtered.filter { segment in
                segment.name.localizedCaseInsensitiveContains(searchText) ||
                segment.terrainDescription.localizedCaseInsensitiveContains(searchText) ||
                segment.navigationNotes.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let terrain = filterTerrainType {
            filtered = filtered.filter { $0.terrainType == terrain }
        }

        if let difficulty = filterDifficulty {
            filtered = filtered.filter { $0.difficultyRating == difficulty }
        }

        switch sortOrder {
        case .terrain:
            segments = filtered.sorted { s1, s2 in
                if s1.terrainType.rawValue != s2.terrainType.rawValue {
                    return s1.terrainType.rawValue < s2.terrainType.rawValue
                }
                return s1.name < s2.name
            }
        case .dayNumber:
            segments = filtered.sorted { s1, s2 in
                let d1 = s1.startDayNumber ?? Int.max
                let d2 = s2.startDayNumber ?? Int.max
                if d1 != d2 { return d1 < d2 }
                return s1.name < s2.name
            }
        case .name:
            segments = filtered.sorted { $0.name < $1.name }
        case .distance:
            segments = filtered.sorted { s1, s2 in
                let d1 = s1.distanceMeters ?? Double.infinity
                let d2 = s2.distanceMeters ?? Double.infinity
                return d1 < d2
            }
        case .difficulty:
            segments = filtered.sorted { s1, s2 in
                if s1.difficultyRating.rawValue != s2.difficultyRating.rawValue {
                    return s1.difficultyRating.rawValue < s2.difficultyRating.rawValue
                }
                return s1.name < s2.name
            }
        }
    }

    // MARK: - CRUD Operations

    func addSegment(_ segment: RouteSegment, to expedition: Expedition) {
        segment.expedition = expedition
        if expedition.routeSegments == nil {
            expedition.routeSegments = []
        }
        expedition.routeSegments?.append(segment)
        modelContext.insert(segment)

        logger.info("Added route segment '\(segment.name)' to expedition")
        saveContext()
        loadSegments(for: expedition)
    }

    func deleteSegment(_ segment: RouteSegment, from expedition: Expedition) {
        let name = segment.name
        expedition.routeSegments?.removeAll { $0.id == segment.id }
        modelContext.delete(segment)

        logger.info("Deleted route segment '\(name)' from expedition")
        saveContext()
        loadSegments(for: expedition)
    }

    func updateSegment(_ segment: RouteSegment, in expedition: Expedition) {
        logger.debug("Updated route segment '\(segment.name)'")
        saveContext()
        loadSegments(for: expedition)
    }

    // MARK: - Computed Properties

    var totalDistance: Double {
        segments.compactMap { $0.distanceMeters }.reduce(0, +)
    }

    var totalElevationGain: Double {
        segments.compactMap { $0.elevationGainMeters }.reduce(0, +)
    }

    var groupedByTerrain: [(terrainType: TerrainType, segments: [RouteSegment])] {
        let grouped = Dictionary(grouping: segments) { $0.terrainType }
        return TerrainType.allCases.compactMap { terrain in
            guard let list = grouped[terrain], !list.isEmpty else { return nil }
            return (terrainType: terrain, segments: list)
        }
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
        filterTerrainType = nil
        filterDifficulty = nil
    }

    var hasActiveFilters: Bool {
        filterTerrainType != nil || filterDifficulty != nil || !searchText.isEmpty
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save route segment changes: \(error.localizedDescription)")
        }
    }
}
