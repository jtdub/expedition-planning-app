import XCTest
import SwiftData
@testable import Chaki

final class WaterSourceTests: XCTestCase {

    // MARK: - Creation Tests

    func testWaterSourceCreation() throws {
        let source = WaterSource(
            name: "Glacier Creek",
            sourceType: .stream,
            reliability: .perennial
        )

        XCTAssertNotNil(source.id)
        XCTAssertEqual(source.name, "Glacier Creek")
        XCTAssertEqual(source.sourceType, .stream)
        XCTAssertEqual(source.reliability, .perennial)
    }

    func testWaterSourceDefaultValues() throws {
        let source = WaterSource(name: "Test Source")

        XCTAssertEqual(source.sourceType, .stream)
        XCTAssertEqual(source.reliability, .seasonal)
        XCTAssertEqual(source.treatmentRequired, .filter)
        XCTAssertFalse(source.isVerified)
        XCTAssertTrue(source.seasonalNotes.isEmpty)
        XCTAssertTrue(source.contaminationRisks.isEmpty)
        XCTAssertTrue(source.flowRate.isEmpty)
        XCTAssertTrue(source.notes.isEmpty)
        XCTAssertNil(source.latitude)
        XCTAssertNil(source.longitude)
        XCTAssertNil(source.elevationMeters)
        XCTAssertNil(source.lastVerified)
    }

    // MARK: - Computed Property Tests

    func testCoordinate() throws {
        let source = WaterSource(name: "Test")
        source.latitude = 67.5
        source.longitude = -152.3

        let coord = source.coordinate
        XCTAssertNotNil(coord)
        XCTAssertEqual(coord?.latitude, 67.5)
        XCTAssertEqual(coord?.longitude, -152.3)
    }

    func testCoordinateNilWhenPartial() throws {
        let source = WaterSource(name: "Test")
        source.latitude = 67.5

        XCTAssertNil(source.coordinate)
    }

    func testHasCoordinates() throws {
        let source = WaterSource(name: "Test")
        XCTAssertFalse(source.hasCoordinates)

        source.latitude = 67.5
        source.longitude = -152.3
        XCTAssertTrue(source.hasCoordinates)
    }

    func testElevation() throws {
        let source = WaterSource(name: "Test")
        source.elevationMeters = 2100

        let elevation = source.elevation
        XCTAssertNotNil(elevation)
        XCTAssertEqual(elevation?.value, 2100)
        XCTAssertEqual(elevation?.unit, .meters)
    }

    func testElevationNilWhenNotSet() throws {
        let source = WaterSource(name: "Test")
        XCTAssertNil(source.elevation)
    }

    func testNeedsTreatment() throws {
        let source = WaterSource(name: "Test")
        source.treatmentRequired = .filter
        XCTAssertTrue(source.needsTreatment)

        source.treatmentRequired = .none
        XCTAssertFalse(source.needsTreatment)
    }

    func testNeedsTreatmentAllMethods() throws {
        let source = WaterSource(name: "Test")

        source.treatmentRequired = .uv
        XCTAssertTrue(source.needsTreatment)

        source.treatmentRequired = .boil
        XCTAssertTrue(source.needsTreatment)

        source.treatmentRequired = .chemical
        XCTAssertTrue(source.needsTreatment)
    }

    // MARK: - Enum Tests

    func testWaterSourceTypeProperties() throws {
        for type in WaterSourceType.allCases {
            XCTAssertFalse(type.icon.isEmpty)
        }
    }

    func testWaterSourceTypeCaseCount() throws {
        XCTAssertEqual(WaterSourceType.allCases.count, 8)
    }

    func testReliabilityRatingProperties() throws {
        for rating in ReliabilityRating.allCases {
            XCTAssertFalse(rating.icon.isEmpty)
            XCTAssertFalse(rating.color.isEmpty)
        }
    }

    func testReliabilityRatingCaseCount() throws {
        XCTAssertEqual(ReliabilityRating.allCases.count, 4)
    }

    func testTreatmentMethodProperties() throws {
        for method in TreatmentMethod.allCases {
            XCTAssertFalse(method.icon.isEmpty)
        }
    }

    func testTreatmentMethodCaseCount() throws {
        XCTAssertEqual(TreatmentMethod.allCases.count, 5)
    }

    // MARK: - Persistence Test

    @MainActor
    func testSwiftDataPersistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Expedition.self, WaterSource.self,
            configurations: config
        )
        let context = container.mainContext

        let expedition = Expedition(name: "Test Expedition")
        context.insert(expedition)

        let source = WaterSource(name: "Alpine Spring", sourceType: .spring, reliability: .perennial)
        source.latitude = 68.2
        source.longitude = -150.5
        source.elevationMeters = 1800
        source.treatmentRequired = .filter
        source.expedition = expedition
        context.insert(source)

        try context.save()

        let descriptor = FetchDescriptor<WaterSource>()
        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Alpine Spring")
        XCTAssertEqual(fetched.first?.sourceType, .spring)
        XCTAssertEqual(fetched.first?.reliability, .perennial)
        XCTAssertTrue(fetched.first?.hasCoordinates ?? false)
    }
}
