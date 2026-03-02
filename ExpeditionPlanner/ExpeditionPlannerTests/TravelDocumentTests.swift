import XCTest
import SwiftData
@testable import Chaki

final class TravelDocumentTests: XCTestCase {

    // MARK: - Creation Tests

    func testTravelDocumentCreation() throws {
        let doc = TravelDocument(
            documentType: .passport,
            holderName: "John Smith"
        )

        XCTAssertNotNil(doc.id)
        XCTAssertEqual(doc.documentType, .passport)
        XCTAssertEqual(doc.holderName, "John Smith")
    }

    func testTravelDocumentDefaultValues() throws {
        let doc = TravelDocument()

        XCTAssertEqual(doc.documentType, .passport)
        XCTAssertEqual(doc.applicationStatus, .notStarted)
        XCTAssertEqual(doc.costCurrency, "USD")
        XCTAssertTrue(doc.holderName.isEmpty)
        XCTAssertTrue(doc.documentNumber.isEmpty)
        XCTAssertTrue(doc.issuingCountry.isEmpty)
        XCTAssertTrue(doc.visaType.isEmpty)
        XCTAssertTrue(doc.notes.isEmpty)
        XCTAssertNil(doc.issueDate)
        XCTAssertNil(doc.expiryDate)
        XCTAssertNil(doc.cost)
    }

    // MARK: - Expiry Tests

    func testIsExpired() throws {
        let doc = TravelDocument()
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        doc.expiryDate = pastDate

        XCTAssertTrue(doc.isExpired)
    }

    func testIsNotExpired() throws {
        let doc = TravelDocument()
        let futureDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())
        doc.expiryDate = futureDate

        XCTAssertFalse(doc.isExpired)
    }

    func testIsExpiredNilDate() throws {
        let doc = TravelDocument()
        XCTAssertFalse(doc.isExpired)
    }

    func testIsExpiringSoon() throws {
        let doc = TravelDocument()
        let threeMonths = Calendar.current.date(byAdding: .month, value: 3, to: Date())
        doc.expiryDate = threeMonths

        XCTAssertTrue(doc.isExpiringSoon)
    }

    func testIsNotExpiringSoonWhenFarFuture() throws {
        let doc = TravelDocument()
        let twoYears = Calendar.current.date(byAdding: .year, value: 2, to: Date())
        doc.expiryDate = twoYears

        XCTAssertFalse(doc.isExpiringSoon)
    }

    func testIsNotExpiringSoonWhenExpired() throws {
        let doc = TravelDocument()
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        doc.expiryDate = pastDate

        XCTAssertFalse(doc.isExpiringSoon)
    }

    func testDaysUntilExpiry() throws {
        let doc = TravelDocument()
        let tenDays = Calendar.current.date(byAdding: .day, value: 10, to: Date())
        doc.expiryDate = tenDays

        XCTAssertNotNil(doc.daysUntilExpiry)
        // Allow for time-of-day rounding
        XCTAssertTrue((9...10).contains(doc.daysUntilExpiry ?? 0))
    }

    func testDaysUntilExpiryNil() throws {
        let doc = TravelDocument()
        XCTAssertNil(doc.daysUntilExpiry)
    }

    // MARK: - Action Required Tests

    func testIsActionRequiredNotStarted() throws {
        let doc = TravelDocument()
        doc.applicationStatus = .notStarted
        XCTAssertTrue(doc.isActionRequired)
    }

    func testIsActionRequiredInProgress() throws {
        let doc = TravelDocument()
        doc.applicationStatus = .inProgress
        XCTAssertTrue(doc.isActionRequired)
    }

    func testIsActionRequiredDenied() throws {
        let doc = TravelDocument()
        doc.applicationStatus = .denied
        XCTAssertTrue(doc.isActionRequired)
    }

    func testIsActionRequiredApprovedNotExpiring() throws {
        let doc = TravelDocument()
        doc.applicationStatus = .approved
        let farFuture = Calendar.current.date(byAdding: .year, value: 5, to: Date())
        doc.expiryDate = farFuture

        XCTAssertFalse(doc.isActionRequired)
    }

    func testIsActionRequiredApprovedExpiringSoon() throws {
        let doc = TravelDocument()
        doc.applicationStatus = .approved
        let threeMonths = Calendar.current.date(byAdding: .month, value: 3, to: Date())
        doc.expiryDate = threeMonths

        XCTAssertTrue(doc.isActionRequired)
    }

    // MARK: - Display Tests

    func testDisplayTitleWithHolder() throws {
        let doc = TravelDocument(documentType: .visa, holderName: "Jane Doe")
        XCTAssertEqual(doc.displayTitle, "Visa - Jane Doe")
    }

    func testDisplayTitleWithoutHolder() throws {
        let doc = TravelDocument(documentType: .passport)
        XCTAssertEqual(doc.displayTitle, "Passport")
    }

    func testFormattedCost() throws {
        let doc = TravelDocument()
        doc.cost = 150.00
        doc.costCurrency = "USD"

        XCTAssertNotNil(doc.formattedCost)
    }

    func testFormattedCostNil() throws {
        let doc = TravelDocument()
        XCTAssertNil(doc.formattedCost)
    }

    func testDocumentsNeededList() throws {
        let doc = TravelDocument()
        doc.documentsNeeded = "Photo, Application form, Payment receipt"

        let list = doc.documentsNeededList
        XCTAssertEqual(list.count, 3)
        XCTAssertEqual(list[0], "Photo")
        XCTAssertEqual(list[1], "Application form")
        XCTAssertEqual(list[2], "Payment receipt")
    }

    func testDocumentsNeededListEmpty() throws {
        let doc = TravelDocument()
        XCTAssertTrue(doc.documentsNeededList.isEmpty)
    }

    // MARK: - Enum Tests

    func testDocumentTypeProperties() throws {
        for type in DocumentType.allCases {
            XCTAssertFalse(type.icon.isEmpty)
        }
    }

    func testDocumentTypeCaseCount() throws {
        XCTAssertEqual(DocumentType.allCases.count, 7)
    }

    func testApplicationStatusProperties() throws {
        for status in ApplicationStatus.allCases {
            XCTAssertFalse(status.icon.isEmpty)
            XCTAssertFalse(status.color.isEmpty)
        }
    }

    func testApplicationStatusCaseCount() throws {
        XCTAssertEqual(ApplicationStatus.allCases.count, 7)
    }

    // MARK: - Persistence Test

    @MainActor
    func testSwiftDataPersistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Expedition.self, TravelDocument.self,
            configurations: config
        )
        let context = container.mainContext

        let expedition = Expedition(name: "Test Expedition")
        context.insert(expedition)

        let doc = TravelDocument(documentType: .passport, holderName: "John Smith")
        doc.documentNumber = "AB123456"
        doc.issuingCountry = "USA"
        doc.applicationStatus = .approved
        doc.expedition = expedition
        context.insert(doc)

        try context.save()

        let descriptor = FetchDescriptor<TravelDocument>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.holderName, "John Smith")
        XCTAssertEqual(fetched.first?.documentNumber, "AB123456")
        XCTAssertEqual(fetched.first?.applicationStatus, .approved)
    }
}
