import Foundation

/// A CSV file, parsed the way the format actually specifies rather than the way a
/// naive split does.
///
/// This exists because a CSV is not a list of lines. A quoted field may contain the
/// delimiter, a newline, and a doubled quote as an escaped one, and a file that
/// looks like this is completely ordinary:
///
/// ```
/// name,note
/// "Rivera, Ana","said ""yes""
/// on Tuesday"
/// ```
///
/// Splitting on commas and newlines turns that into eleven fields and silently
/// attaches half a sentence to the wrong cell. Every downstream claim would then
/// cite a locator that points at the wrong place, which is the one failure this
/// whole capability cannot afford.
public struct CSVTable: Hashable, Sendable {
    public var headers: [String]
    public var rows: [[String]]

    public init(headers: [String], rows: [[String]]) {
        self.headers = headers
        self.rows = rows
    }

    /// A short preview, capped so a huge file cannot fill the interface.
    public func preview(limit: Int = 5) -> CSVTable {
        CSVTable(headers: headers, rows: Array(rows.prefix(limit)))
    }

    /// Reads named fields, so a caller never indexes by position and silently reads
    /// the wrong column after an export changed.
    public func value(row: [String], column: String) -> String? {
        guard let index = headers.firstIndex(of: column), index < row.count else { return nil }
        return row[index]
    }

    /// Parses RFC 4180 style CSV, tolerating CRLF and a UTF-8 BOM.
    ///
    /// Malformed input is repaired where the repair is unambiguous (a missing final
    /// newline) and refused where it is not, rather than guessed at.
    public static func parse(_ text: String) throws -> CSVTable {
        // Line endings are normalised before anything else, and this is not
        // cosmetic. In Swift a CRLF pair is a *single* `Character`, so a file
        // written on Windows walks straight past `case "\r"` and `case "\n"` and
        // lands in the default branch, which turns the whole file into one field.
        // The first version of this parser had exactly that bug and every
        // Windows-authored CSV came back as a single column.
        let normalised = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        var scalars = Array(normalised)
        // A BOM is not data. Leaving it in makes the first header name wrong.
        if scalars.first == "\u{FEFF}" { scalars.removeFirst() }

        var records: [[String]] = []
        var field = ""
        var record: [String] = []
        var inQuotes = false
        var index = 0

        func endField() {
            record.append(field)
            field = ""
        }
        func endRecord() {
            endField()
            // A trailing newline produces one empty record that is not a row.
            if record.count > 1 || record.first?.isEmpty == false {
                records.append(record)
            }
            record = []
        }

        while index < scalars.count {
            let character = scalars[index]
            if inQuotes {
                if character == "\"" {
                    // A doubled quote inside a quoted field is one literal quote.
                    if index + 1 < scalars.count, scalars[index + 1] == "\"" {
                        field.append("\"")
                        index += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(character)
                }
            } else {
                switch character {
                case "\"":
                    inQuotes = true
                case ",":
                    endField()
                case "\n":
                    endRecord()
                default:
                    field.append(character)
                }
            }
            index += 1
        }

        guard inQuotes == false else {
            // An unterminated quote means the rest of the file is unparseable. The
            // honest answer is to refuse, not to return half a table that looks
            // complete.
            throw CSVError.unterminatedQuote
        }
        // Flush a final field and record only when something is actually pending. The
        // first version returned an empty table here whenever the file ended with a
        // newline, which is nearly every CSV, so it silently discarded every row it
        // had already parsed.
        if record.isEmpty == false || field.isEmpty == false {
            endRecord()
        }

        guard let headers = records.first else {
            return CSVTable(headers: [], rows: [])
        }
        return CSVTable(headers: headers, rows: Array(records.dropFirst()))
    }

    public enum CSVError: Error, Equatable {
        case unterminatedQuote
    }
}
