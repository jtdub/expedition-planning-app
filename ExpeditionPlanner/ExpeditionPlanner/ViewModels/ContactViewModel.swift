import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.expedition.planner", category: "ContactViewModel")

enum ContactSortOrder: String, CaseIterable {
    case name = "Name"
    case category = "Category"
    case location = "Location"
    case priority = "Priority"
}

@Observable
final class ContactViewModel {
    private var modelContext: ModelContext

    var contacts: [Contact] = []
    var searchText: String = ""
    var filterCategory: ContactCategory?
    var showEmergencyOnly: Bool = false
    var sortOrder: ContactSortOrder = .category
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadContacts(for expedition: Expedition) {
        let allContacts = expedition.contacts ?? []

        var filtered = allContacts

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchText) ||
                contact.role.localizedCaseInsensitiveContains(searchText) ||
                (contact.organization ?? "").localizedCaseInsensitiveContains(searchText) ||
                contact.location.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply category filter
        if let category = filterCategory {
            filtered = filtered.filter { $0.category == category }
        }

        // Apply emergency filter
        if showEmergencyOnly {
            filtered = filtered.filter { $0.isEmergencyContact }
        }

        // Sort
        switch sortOrder {
        case .name:
            contacts = filtered.sorted { $0.name < $1.name }
        case .category:
            contacts = filtered.sorted { c1, c2 in
                if c1.category != c2.category {
                    return c1.category.rawValue < c2.category.rawValue
                }
                return c1.name < c2.name
            }
        case .location:
            contacts = filtered.sorted { c1, c2 in
                if c1.location != c2.location {
                    return c1.location < c2.location
                }
                return c1.name < c2.name
            }
        case .priority:
            contacts = filtered.sorted { c1, c2 in
                // Emergency contacts first, then by priority
                if c1.isEmergencyContact != c2.isEmergencyContact {
                    return c1.isEmergencyContact
                }
                let p1 = c1.emergencyPriority ?? 999
                let p2 = c2.emergencyPriority ?? 999
                if p1 != p2 {
                    return p1 < p2
                }
                return c1.name < c2.name
            }
        }
    }

    // MARK: - CRUD Operations

    func addContact(_ contact: Contact, to expedition: Expedition) {
        contact.expedition = expedition
        if expedition.contacts == nil {
            expedition.contacts = []
        }
        expedition.contacts?.append(contact)
        modelContext.insert(contact)

        logger.info("Added contact '\(contact.name)' to expedition")
        saveContext()
        loadContacts(for: expedition)
    }

    func deleteContact(_ contact: Contact, from expedition: Expedition) {
        let name = contact.name
        expedition.contacts?.removeAll { $0.id == contact.id }
        modelContext.delete(contact)

        logger.info("Deleted contact '\(name)' from expedition")
        saveContext()
        loadContacts(for: expedition)
    }

    func updateContact(_ contact: Contact, in expedition: Expedition) {
        logger.debug("Updated contact '\(contact.name)'")
        saveContext()
        loadContacts(for: expedition)
    }

    // MARK: - Computed Properties

    var emergencyContacts: [Contact] {
        contacts.filter { $0.isEmergencyContact }
            .sorted { ($0.emergencyPriority ?? 999) < ($1.emergencyPriority ?? 999) }
    }

    var categoryCounts: [ContactCategory: Int] {
        var counts: [ContactCategory: Int] = [:]
        for contact in contacts {
            counts[contact.category, default: 0] += 1
        }
        return counts
    }

    var groupedByCategory: [(category: ContactCategory, contacts: [Contact])] {
        let grouped = Dictionary(grouping: contacts) { $0.category }
        return ContactCategory.allCases.compactMap { category in
            guard let list = grouped[category], !list.isEmpty else { return nil }
            return (category: category, contacts: list)
        }
    }

    var groupedByLocation: [(location: String, contacts: [Contact])] {
        let grouped = Dictionary(grouping: contacts) { $0.location }
        return grouped.keys.sorted().compactMap { location in
            guard let list = grouped[location], !list.isEmpty else { return nil }
            let displayLocation = location.isEmpty ? "Unspecified" : location
            return (location: displayLocation, contacts: list)
        }
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
        filterCategory = nil
        showEmergencyOnly = false
    }

    var hasActiveFilters: Bool {
        filterCategory != nil || showEmergencyOnly || !searchText.isEmpty
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save contact changes: \(error.localizedDescription)")
        }
    }
}
