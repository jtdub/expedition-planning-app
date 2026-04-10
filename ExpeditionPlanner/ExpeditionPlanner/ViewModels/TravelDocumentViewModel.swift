import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.expedition.planner", category: "TravelDocumentViewModel")

enum TravelDocumentSortOrder: String, CaseIterable {
    case type = "Type"
    case status = "Status"
    case name = "Name"
    case expiry = "Expiry Date"
}

@Observable
final class TravelDocumentViewModel {
    private var modelContext: ModelContext

    var documents: [TravelDocument] = []
    var searchText: String = ""
    var filterDocumentType: DocumentType?
    var filterStatus: ApplicationStatus?
    var sortOrder: TravelDocumentSortOrder = .type
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Load Data

    func loadDocuments(for expedition: Expedition) {
        let allDocs = expedition.travelDocuments ?? []

        var filtered = allDocs

        if !searchText.isEmpty {
            filtered = filtered.filter { doc in
                doc.holderName.localizedCaseInsensitiveContains(searchText) ||
                doc.documentNumber.localizedCaseInsensitiveContains(searchText) ||
                doc.destinationCountry.localizedCaseInsensitiveContains(searchText) ||
                doc.notes.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let docType = filterDocumentType {
            filtered = filtered.filter { $0.documentType == docType }
        }

        if let status = filterStatus {
            filtered = filtered.filter { $0.applicationStatus == status }
        }

        switch sortOrder {
        case .type:
            documents = filtered.sorted { d1, d2 in
                if d1.documentType.rawValue != d2.documentType.rawValue {
                    return d1.documentType.rawValue < d2.documentType.rawValue
                }
                return d1.holderName < d2.holderName
            }
        case .status:
            documents = filtered.sorted { d1, d2 in
                if d1.applicationStatus.rawValue != d2.applicationStatus.rawValue {
                    return d1.applicationStatus.rawValue < d2.applicationStatus.rawValue
                }
                return d1.holderName < d2.holderName
            }
        case .name:
            documents = filtered.sorted { $0.holderName < $1.holderName }
        case .expiry:
            documents = filtered.sorted { d1, d2 in
                let e1 = d1.expiryDate ?? Date.distantFuture
                let e2 = d2.expiryDate ?? Date.distantFuture
                return e1 < e2
            }
        }
    }

    // MARK: - CRUD Operations

    func addDocument(_ document: TravelDocument, to expedition: Expedition) {
        document.expedition = expedition
        if expedition.travelDocuments == nil {
            expedition.travelDocuments = []
        }
        expedition.travelDocuments?.append(document)
        modelContext.insert(document)

        logger.info("Added travel document '\(document.displayTitle)' to expedition")
        saveContext()
        loadDocuments(for: expedition)
    }

    func deleteDocument(_ document: TravelDocument, from expedition: Expedition) {
        let title = document.displayTitle
        expedition.travelDocuments?.removeAll { $0.id == document.id }
        modelContext.delete(document)

        logger.info("Deleted travel document '\(title)' from expedition")
        saveContext()
        loadDocuments(for: expedition)
    }

    func updateDocument(_ document: TravelDocument, in expedition: Expedition) {
        logger.debug("Updated travel document '\(document.displayTitle)'")
        saveContext()
        loadDocuments(for: expedition)
    }

    // MARK: - Computed Properties

    var actionRequiredCount: Int {
        documents.filter { $0.isActionRequired }.count
    }

    var expiredCount: Int {
        documents.filter { $0.isExpired }.count
    }

    var groupedByType: [(documentType: DocumentType, documents: [TravelDocument])] {
        let grouped = Dictionary(grouping: documents) { $0.documentType }
        return DocumentType.allCases.compactMap { type in
            guard let list = grouped[type], !list.isEmpty else { return nil }
            return (documentType: type, documents: list)
        }
    }

    // MARK: - Filtering

    func clearFilters() {
        searchText = ""
        filterDocumentType = nil
        filterStatus = nil
    }

    var hasActiveFilters: Bool {
        filterDocumentType != nil || filterStatus != nil || !searchText.isEmpty
    }

    // MARK: - Private

    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            logger.error("Failed to save travel document changes: \(error.localizedDescription)")
        }
    }
}
