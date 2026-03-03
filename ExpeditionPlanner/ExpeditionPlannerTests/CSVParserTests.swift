import XCTest
@testable import Chaki

final class CSVParserTests: XCTestCase {

    // MARK: - Basic Parsing

    func testParseSimpleCSV() throws {
        let csv = "Name,Age,City\nAlice,30,Denver\nBob,25,Fairbanks"
        let result = try CSVParser.parse(string: csv)

        XCTAssertEqual(result.headers, ["Name", "Age", "City"])
        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0], ["Alice", "30", "Denver"])
        XCTAssertEqual(result.rows[1], ["Bob", "25", "Fairbanks"])
    }

    func testParseHeadersOnly() throws {
        let csv = "Name,Age,City"
        let result = try CSVParser.parse(string: csv)

        XCTAssertEqual(result.headers, ["Name", "Age", "City"])
        XCTAssertTrue(result.rows.isEmpty)
    }

    func testParseEmptyFields() throws {
        let csv = "A,B,C\n1,,3\n,2,"
        let result = try CSVParser.parse(string: csv)

        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0], ["1", "", "3"])
        XCTAssertEqual(result.rows[1], ["", "2", ""])
    }

    // MARK: - Quoted Fields

    func testParseQuotedFieldWithComma() throws {
        let csv = "Name,Location\nAlice,\"Denver, CO\""
        let result = try CSVParser.parse(string: csv)

        XCTAssertEqual(result.rows[0][1], "Denver, CO")
    }

    func testParseQuotedFieldWithEscapedQuotes() throws {
        let csv = "Name,Desc\nItem,\"He said \"\"hello\"\"\""
        let result = try CSVParser.parse(string: csv)

        XCTAssertEqual(result.rows[0][1], "He said \"hello\"")
    }

    func testParseQuotedFieldWithNewline() throws {
        let csv = "Name,Notes\nAlice,\"Line 1\nLine 2\""
        let result = try CSVParser.parse(string: csv)

        XCTAssertEqual(result.rows.count, 1)
        XCTAssertEqual(result.rows[0][1], "Line 1\nLine 2")
    }

    func testParseQuotedFieldWithAllSpecialChars() throws {
        let csv = "Name,Notes\nItem,\"commas, \"\"quotes\"\", and\nnewlines\""
        let result = try CSVParser.parse(string: csv)

        XCTAssertEqual(result.rows.count, 1)
        XCTAssertEqual(result.rows[0][1], "commas, \"quotes\", and\nnewlines")
    }

    // MARK: - Line Endings

    func testParseWindowsLineEndings() throws {
        let csv = "A,B\r\n1,2\r\n3,4"
        let result = try CSVParser.parse(string: csv)

        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0], ["1", "2"])
        XCTAssertEqual(result.rows[1], ["3", "4"])
    }

    func testParseUnixLineEndings() throws {
        let csv = "A,B\n1,2\n3,4"
        let result = try CSVParser.parse(string: csv)

        XCTAssertEqual(result.rows.count, 2)
    }

    func testParseTrailingNewline() throws {
        let csv = "A,B\n1,2\n"
        let result = try CSVParser.parse(string: csv)

        XCTAssertEqual(result.rows.count, 1)
        XCTAssertEqual(result.rows[0], ["1", "2"])
    }

    // MARK: - Value Access

    func testValueByColumnName() throws {
        let csv = "Name,Age\nAlice,30"
        let result = try CSVParser.parse(string: csv)

        XCTAssertEqual(result.value(row: 0, column: "Name"), "Alice")
        XCTAssertEqual(result.value(row: 0, column: "Age"), "30")
        XCTAssertNil(result.value(row: 0, column: "Missing"))
        XCTAssertNil(result.value(row: 1, column: "Name"))
    }

    func testValueByColumnIndex() throws {
        let csv = "A,B,C\n1,2,3"
        let result = try CSVParser.parse(string: csv)

        XCTAssertEqual(result.value(row: 0, columnIndex: 0), "1")
        XCTAssertEqual(result.value(row: 0, columnIndex: 2), "3")
        XCTAssertNil(result.value(row: 0, columnIndex: 5))
    }

    // MARK: - Error Cases

    func testParseEmptyString() {
        XCTAssertThrowsError(try CSVParser.parse(string: "")) { error in
            XCTAssertTrue(error is CSVParser.CSVParseError)
        }
    }

    func testParseEmptyData() {
        XCTAssertThrowsError(try CSVParser.parse(data: Data())) { error in
            XCTAssertTrue(error is CSVParser.CSVParseError)
        }
    }

    // MARK: - Data Encoding

    func testParseUTF8Data() throws {
        let csv = "Name,City\nAna,Zürich"
        let data = csv.data(using: .utf8)!
        let result = try CSVParser.parse(data: data)

        XCTAssertEqual(result.rows[0][1], "Zürich")
    }

    func testParseLatin1Fallback() throws {
        // Create data with Latin-1 encoding that's invalid UTF-8
        let csv = "Name,City\nAna,Z\u{FC}rich"
        let data = csv.data(using: .isoLatin1)!
        let result = try CSVParser.parse(data: data)

        XCTAssertEqual(result.rows[0][1], "Zürich")
    }

    // MARK: - Edge Cases

    func testParseSingleColumn() throws {
        let csv = "Name\nAlice\nBob"
        let result = try CSVParser.parse(string: csv)

        XCTAssertEqual(result.headers, ["Name"])
        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0], ["Alice"])
    }

    func testParseFilterEmptyRows() throws {
        let csv = "A,B\n1,2\n\n3,4"
        let result = try CSVParser.parse(string: csv)

        XCTAssertEqual(result.rows.count, 2)
        XCTAssertEqual(result.rows[0], ["1", "2"])
        XCTAssertEqual(result.rows[1], ["3", "4"])
    }
}
