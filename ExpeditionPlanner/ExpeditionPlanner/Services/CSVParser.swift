import Foundation

/// RFC 4180 compliant CSV parser with support for quoted fields,
/// escaped quotes, newlines within fields, and encoding detection.
final class CSVParser {

    // MARK: - Types

    /// Result of parsing a CSV file
    struct ParseResult {
        let headers: [String]
        let rows: [[String]]

        /// Get a value by row index and column name
        func value(row: Int, column: String) -> String? {
            guard let colIndex = headers.firstIndex(of: column),
                  row < rows.count,
                  colIndex < rows[row].count else {
                return nil
            }
            return rows[row][colIndex]
        }

        /// Get a value by row index and column index
        func value(row: Int, columnIndex: Int) -> String? {
            guard row < rows.count, columnIndex < rows[row].count else {
                return nil
            }
            return rows[row][columnIndex]
        }
    }

    enum CSVParseError: Error, LocalizedError {
        case emptyFile
        case noHeaders
        case encodingError
        case invalidFormat(String)

        var errorDescription: String? {
            switch self {
            case .emptyFile:
                return "The file is empty."
            case .noHeaders:
                return "No header row found in the CSV file."
            case .encodingError:
                return "Unable to read the file encoding."
            case .invalidFormat(let detail):
                return "Invalid CSV format: \(detail)"
            }
        }
    }

    // MARK: - Parsing

    /// Parse CSV data from a file URL
    static func parse(url: URL) throws -> ParseResult {
        let data = try Data(contentsOf: url)
        return try parse(data: data)
    }

    /// Parse CSV data from raw bytes with encoding detection
    static func parse(data: Data) throws -> ParseResult {
        guard !data.isEmpty else {
            throw CSVParseError.emptyFile
        }

        // Try UTF-8 first, fall back to Latin-1
        let content: String
        if let utf8 = String(data: data, encoding: .utf8) {
            content = utf8
        } else if let latin1 = String(data: data, encoding: .isoLatin1) {
            content = latin1
        } else {
            throw CSVParseError.encodingError
        }

        return try parse(string: content)
    }

    /// Parse CSV from a string
    static func parse(string: String) throws -> ParseResult {
        let trimmed = string.trimmingCharacters(in: .newlines)
        guard !trimmed.isEmpty else {
            throw CSVParseError.emptyFile
        }

        let allRows = parseRows(from: trimmed)

        guard let headerRow = allRows.first, !headerRow.isEmpty else {
            throw CSVParseError.noHeaders
        }

        let dataRows = Array(allRows.dropFirst()).filter { row in
            // Filter out completely empty rows
            !row.allSatisfy { $0.isEmpty }
        }

        return ParseResult(headers: headerRow, rows: dataRows)
    }

    // MARK: - RFC 4180 Parser

    /// Parse all rows from CSV text, handling quoted fields with embedded newlines
    private static func parseRows(from text: String) -> [[String]] {
        var rows: [[String]] = []
        var currentField = ""
        var currentRow: [String] = []
        var inQuotes = false
        let chars = Array(text.unicodeScalars)
        var index = chars.startIndex

        while index < chars.endIndex {
            let char = chars[index]

            if inQuotes {
                if char == "\"" {
                    // Check for escaped quote ("")
                    let nextIndex = chars.index(after: index)
                    if nextIndex < chars.endIndex && chars[nextIndex] == "\"" {
                        currentField.append("\"")
                        index = chars.index(after: nextIndex)
                    } else {
                        // End of quoted field
                        inQuotes = false
                        index = chars.index(after: index)
                    }
                } else {
                    currentField.unicodeScalars.append(char)
                    index = chars.index(after: index)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                    index = chars.index(after: index)
                } else if char == "," {
                    currentRow.append(currentField)
                    currentField = ""
                    index = chars.index(after: index)
                } else if char == "\r" {
                    // Handle \r\n or bare \r
                    currentRow.append(currentField)
                    currentField = ""
                    rows.append(currentRow)
                    currentRow = []
                    index = chars.index(after: index)
                    if index < chars.endIndex && chars[index] == "\n" {
                        index = chars.index(after: index)
                    }
                } else if char == "\n" {
                    currentRow.append(currentField)
                    currentField = ""
                    rows.append(currentRow)
                    currentRow = []
                    index = chars.index(after: index)
                } else {
                    currentField.unicodeScalars.append(char)
                    index = chars.index(after: index)
                }
            }
        }

        // Don't forget the last field/row
        currentRow.append(currentField)
        if !currentRow.allSatisfy({ $0.isEmpty }) {
            rows.append(currentRow)
        }

        return rows
    }
}
