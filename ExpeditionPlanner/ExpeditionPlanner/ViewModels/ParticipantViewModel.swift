import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.chaki.app", category: "ParticipantViewModel")

enum ParticipantSortOrder: String, CaseIterable {
    case name = "Name"
    case role = "Role"
    case group = "Group"
    case status = "Status"
}

@Observable
final class ParticipantViewModel {
    private var modelContext: ModelContext

    var participants: [Participant] = []
    var searchText: String = ""
    var filterRole: ParticipantRole?
    var filterGroup: String?
    var sortOrder: ParticipantSortOrder = .name
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadParticipants(for expedition: Expedition) {
        let allParticipants = expedition.participants ?? []

        var filtered = allParticipants

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { participant in
                participant.name.localizedCaseInsensitiveContains(searchText) ||
                participant.email.localizedCaseInsensitiveContains(searchText) ||
                participant.groupAssignment.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply role filter
        if let role = filterRole {
            filtered = filtered.filter { $0.role == role }
        }

        // Apply group filter
        if let group = filterGroup, !group.isEmpty {
            filtered = filtered.filter { $0.groupAssignment == group }
        }

        // Sort
        switch sortOrder {
        case .name:
            participants = filtered.sorted { $0.name < $1.name }
        case .role:
            participants = filtered.sorted { p1, p2 in
                if p1.role != p2.role {
                    return p1.role.rawValue < p2.role.rawValue
                }
                return p1.name < p2.name
            }
        case .group:
            participants = filtered.sorted { p1, p2 in
                if p1.groupAssignment != p2.groupAssignment {
                    return p1.groupAssignment < p2.groupAssignment
                }
                return p1.name < p2.name
            }
        case .status:
            participants = filtered.sorted { p1, p2 in
                if p1.isConfirmed != p2.isConfirmed {
                    return p1.isConfirmed
                }
                return p1.name < p2.name
            }
        }
    }

    // MARK: - CRUD Operations

    func addParticipant(_ participant: Participant, to expedition: Expedition) {
        participant.expedition = expedition
        if expedition.participants == nil {
            expedition.participants = []
        }
        expedition.participants?.append(participant)
        modelContext.insert(participant)

        logger.info("Added participant '\(participant.name)' to expedition")
        saveContext()
        loadParticipants(for: expedition)
    }

    func deleteParticipant(_ participant: Participant, from expedition: Expedition) {
        let name = participant.name
        expedition.participants?.removeAll { $0.id == participant.id }
        modelContext.delete(participant)

        logger.info("Deleted participant '\(name)' from expedition")
        saveContext()
        loadParticipants(for: expedition)
    }

    func updateParticipant(_ participant: Participant, in expedition: Expedition) {
        logger.debug("Updated participant '\(participant.name)'")
        saveContext()
        loadParticipants(for: expedition)
    }

    // MARK: - Computed Properties

    var confirmedCount: Int {
        participants.filter { $0.isConfirmed }.count
    }

    var paidCount: Int {
        participants.filter { $0.hasPaid }.count
    }

    var staffCount: Int {
        participants.filter { $0.role.isStaff }.count
    }

    var uniqueGroups: [String] {
        let groups = Set(participants.map { $0.groupAssignment }).filter { !$0.isEmpty }
        return groups.sorted()
    }

    var groupedByRole: [(role: ParticipantRole, participants: [Participant])] {
        let grouped = Dictionary(grouping: participants) { $0.role }
        return ParticipantRole.allCases.compactMap { role in
            guard let list = grouped[role], !list.isEmpty else { return nil }
            return (role: role, participants: list)
        }
    }

    var groupedByGroup: [(group: String, participants: [Participant])] {
        let grouped = Dictionary(grouping: participants) { $0.groupAssignment }
        return grouped.keys.sorted().compactMap { group in
            guard let list = grouped[group], !list.isEmpty else { return nil }
            let displayGroup = group.isEmpty ? "Unassigned" : group
            return (group: displayGroup, participants: list)
        }
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
        filterRole = nil
        filterGroup = nil
    }

    var hasActiveFilters: Bool {
        filterRole != nil || filterGroup != nil || !searchText.isEmpty
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save participant changes: \(error.localizedDescription)")
        }
    }
}
