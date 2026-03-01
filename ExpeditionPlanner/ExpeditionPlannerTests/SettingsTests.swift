import XCTest
@testable import Chaki

final class SettingsTests: XCTestCase {

    // MARK: - Unit Enum Tests

    func testElevationUnitValues() {
        XCTAssertEqual(ElevationUnit.meters.rawValue, "Meters (m)")
        XCTAssertEqual(ElevationUnit.feet.rawValue, "Feet (ft)")
        XCTAssertEqual(ElevationUnit.allCases.count, 2)
    }

    func testWeightUnitValues() {
        XCTAssertEqual(WeightUnit.kilograms.rawValue, "Kilograms (kg)")
        XCTAssertEqual(WeightUnit.pounds.rawValue, "Pounds (lb)")
        XCTAssertEqual(WeightUnit.ounces.rawValue, "Ounces (oz)")
        XCTAssertEqual(WeightUnit.allCases.count, 3)
    }

    func testDistanceUnitValues() {
        XCTAssertEqual(DistanceUnit.kilometers.rawValue, "Kilometers (km)")
        XCTAssertEqual(DistanceUnit.miles.rawValue, "Miles (mi)")
        XCTAssertEqual(DistanceUnit.allCases.count, 2)
    }

    func testTemperatureUnitValues() {
        XCTAssertEqual(TemperatureUnit.celsius.rawValue, "Celsius (°C)")
        XCTAssertEqual(TemperatureUnit.fahrenheit.rawValue, "Fahrenheit (°F)")
        XCTAssertEqual(TemperatureUnit.allCases.count, 2)
    }

    // MARK: - Appearance Tests

    func testAppColorSchemeValues() {
        XCTAssertEqual(AppColorScheme.system.rawValue, "System")
        XCTAssertEqual(AppColorScheme.light.rawValue, "Light")
        XCTAssertEqual(AppColorScheme.dark.rawValue, "Dark")
        XCTAssertEqual(AppColorScheme.allCases.count, 3)
    }

    // MARK: - Export Format Tests

    func testExportFormatValues() {
        XCTAssertEqual(ExportFormat.pdf.rawValue, "PDF")
        XCTAssertEqual(ExportFormat.csv.rawValue, "CSV")
        XCTAssertEqual(ExportFormat.json.rawValue, "JSON")
        XCTAssertEqual(ExportFormat.allCases.count, 3)
    }

    func testExportFormatIcons() {
        XCTAssertEqual(ExportFormat.pdf.icon, "doc.richtext")
        XCTAssertEqual(ExportFormat.csv.icon, "tablecells")
        XCTAssertEqual(ExportFormat.json.icon, "curlybraces")
    }

    // MARK: - Gear Template Tests

    func testGearTemplateValues() {
        XCTAssertEqual(GearTemplate.backpacking.rawValue, "Backpacking")
        XCTAssertEqual(GearTemplate.mountaineering.rawValue, "Mountaineering")
        XCTAssertEqual(GearTemplate.kayaking.rawValue, "Kayaking/Packrafting")
        XCTAssertEqual(GearTemplate.skiing.rawValue, "Ski Touring")
        XCTAssertEqual(GearTemplate.ultralight.rawValue, "Ultralight")
        XCTAssertEqual(GearTemplate.expeditionHeavy.rawValue, "Expedition (Heavy)")
        XCTAssertEqual(GearTemplate.custom.rawValue, "Custom")
        XCTAssertEqual(GearTemplate.allCases.count, 7)
    }

    // MARK: - Currency Tests

    func testCurrencyValues() {
        let usd = Currency.allCases.first { $0.code == "USD" }
        XCTAssertNotNil(usd)
        XCTAssertEqual(usd?.name, "US Dollar")

        let eur = Currency.allCases.first { $0.code == "EUR" }
        XCTAssertNotNil(eur)
        XCTAssertEqual(eur?.name, "Euro")

        let pen = Currency.allCases.first { $0.code == "PEN" }
        XCTAssertNotNil(pen)
        XCTAssertEqual(pen?.name, "Peruvian Sol")
    }

    func testCurrencyCount() {
        XCTAssertEqual(Currency.allCases.count, 14)
    }

    func testCurrencyHashable() {
        let usd1 = Currency(code: "USD", name: "US Dollar")
        let usd2 = Currency(code: "USD", name: "US Dollar")
        XCTAssertEqual(usd1, usd2)

        var set = Set<Currency>()
        set.insert(usd1)
        set.insert(usd2)
        XCTAssertEqual(set.count, 1)
    }
}
