import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.chaki.app", category: "CSVImport")

/// View model managing the CSV import workflow: file parsing, type detection,
/// preview, duplicate checking, and import execution.
@Observable
final class CSVImportViewModel {

    // MARK: - State

    var parseResult: CSVParser.ParseResult?
    var detectedType: CSVImportService.CSVImportType?
    var selectedType: CSVImportService.CSVImportType?
    var importResult: CSVImportService.CSVImportResult?
    var errorMessage: String?
    var isImporting = false
    var previewRows: [[String]] = []
    var duplicateNames: [String] = []

    /// The effective import type (user override or auto-detected)
    var effectiveType: CSVImportService.CSVImportType? {
        selectedType ?? detectedType
    }

    // MARK: - File Parsing

    func parseFile(url: URL) {
        do {
            let result = try CSVParser.parse(url: url)
            parseResult = result
            detectedType = CSVImportService.detectType(from: result.headers)
            selectedType = nil
            importResult = nil
            errorMessage = nil
            duplicateNames = []

            // Preview first 20 rows
            previewRows = Array(result.rows.prefix(20))

            logger.info("Parsed CSV: \(result.headers.count) columns, \(result.rows.count) rows")
            if let detected = detectedType {
                logger.info("Detected type: \(detected.rawValue)")
            }
        } catch {
            errorMessage = error.localizedDescription
            parseResult = nil
            detectedType = nil
            logger.error("CSV parse error: \(error.localizedDescription)")
        }
    }

    // MARK: - Duplicate Checking

    func checkDuplicates(in expedition: Expedition) {
        guard let result = parseResult, let type = effectiveType else {
            duplicateNames = []
            return
        }

        switch type {
        case .gear:
            let (items, _) = CSVImportService.importGear(from: result)
            duplicateNames = CSVImportService.findDuplicateGearNames(
                in: items, existing: expedition.gearItems ?? []
            )
        case .participants:
            let (items, _) = CSVImportService.importParticipants(from: result)
            duplicateNames = CSVImportService.findDuplicateParticipantNames(
                in: items, existing: expedition.participants ?? []
            )
        case .contacts:
            let (items, _) = CSVImportService.importContacts(from: result)
            duplicateNames = CSVImportService.findDuplicateContactNames(
                in: items, existing: expedition.contacts ?? []
            )
        case .budget:
            let (items, _) = CSVImportService.importBudget(from: result)
            duplicateNames = CSVImportService.findDuplicateBudgetNames(
                in: items, existing: expedition.budgetItems ?? []
            )
        case .permits:
            let (items, _) = CSVImportService.importPermits(from: result)
            duplicateNames = CSVImportService.findDuplicatePermitNames(
                in: items, existing: expedition.permits ?? []
            )
        case .resupply:
            let (items, _) = CSVImportService.importResupply(from: result)
            duplicateNames = CSVImportService.findDuplicateResupplyNames(
                in: items, existing: expedition.resupplyPoints ?? []
            )
        case .itinerary:
            duplicateNames = [] // Itinerary days don't duplicate by name
        }
    }

    // MARK: - Import Execution

    func performImport(to expedition: Expedition) {
        guard let result = parseResult, let type = effectiveType else {
            errorMessage = "No data to import"
            return
        }

        isImporting = true

        switch type {
        case .gear:
            let (items, csvResult) = CSVImportService.importGear(from: result)
            var existing = expedition.gearItems ?? []
            for item in items {
                item.expedition = expedition
                existing.append(item)
            }
            expedition.gearItems = existing
            importResult = csvResult
            logger.info("Imported \(items.count) gear items")

        case .participants:
            let (items, csvResult) = CSVImportService.importParticipants(from: result)
            var existing = expedition.participants ?? []
            for item in items {
                item.expedition = expedition
                existing.append(item)
            }
            expedition.participants = existing
            importResult = csvResult
            logger.info("Imported \(items.count) participants")

        case .contacts:
            let (items, csvResult) = CSVImportService.importContacts(from: result)
            var existing = expedition.contacts ?? []
            for item in items {
                item.expedition = expedition
                existing.append(item)
            }
            expedition.contacts = existing
            importResult = csvResult
            logger.info("Imported \(items.count) contacts")

        case .itinerary:
            let (items, csvResult) = CSVImportService.importItinerary(from: result)
            var existing = expedition.itinerary ?? []
            for item in items {
                item.expedition = expedition
                existing.append(item)
            }
            expedition.itinerary = existing
            importResult = csvResult
            logger.info("Imported \(items.count) itinerary days")

        case .budget:
            let (items, csvResult) = CSVImportService.importBudget(from: result)
            var existing = expedition.budgetItems ?? []
            for item in items {
                item.expedition = expedition
                existing.append(item)
            }
            expedition.budgetItems = existing
            importResult = csvResult
            logger.info("Imported \(items.count) budget items")

        case .permits:
            let (items, csvResult) = CSVImportService.importPermits(from: result)
            var existing = expedition.permits ?? []
            for item in items {
                item.expedition = expedition
                existing.append(item)
            }
            expedition.permits = existing
            importResult = csvResult
            logger.info("Imported \(items.count) permits")

        case .resupply:
            let (items, csvResult) = CSVImportService.importResupply(from: result)
            var existing = expedition.resupplyPoints ?? []
            for item in items {
                item.expedition = expedition
                existing.append(item)
            }
            expedition.resupplyPoints = existing
            importResult = csvResult
            logger.info("Imported \(items.count) resupply points")
        }

        isImporting = false
    }

    // MARK: - Reset

    func reset() {
        parseResult = nil
        detectedType = nil
        selectedType = nil
        importResult = nil
        errorMessage = nil
        isImporting = false
        previewRows = []
        duplicateNames = []
    }
}
