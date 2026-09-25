import Foundation
import PDFKit
import CryptoKit
import KollioCore

/// Reads a file the person chose, and says honestly what came out of it.
///
/// Three rules run through the whole thing:
///
/// - **A link is never fetched.** A URL typed by a person stays a pointer.
/// - **An image is not understood.** Reading a picture is an explicit action, not
///   something that happens quietly while a file is being opened.
/// - **"No text" is a real answer.** An image-only PDF says so, rather than
///   importing an empty document that looks like a successful read.
///
/// Nothing is copied into the document. What comes back is a locator, the text if
/// there was any, and a digest, which is exactly what a citation needs to be
/// re-checkable later.
public struct SourceReader: Sendable {
    public init() {}

    /// What reading a file produced.
    public struct Read: Sendable {
        public var kind: SourceReference.Kind
        public var title: String
        public var locator: String
        public var extraction: SourceReference.Extraction
        public var digest: String
        /// Present when the file is a table, so a preview can be shown without
        /// loading the whole thing.
        public var table: CSVTable?

        public init(
            kind: SourceReference.Kind,
            title: String,
            locator: String,
            extraction: SourceReference.Extraction,
            digest: String,
            table: CSVTable? = nil
        ) {
            self.kind = kind
            self.title = title
            self.locator = locator
            self.extraction = extraction
            self.digest = digest
            self.table = table
        }
    }

    /// Reads a file from disk. The caller has already obtained the URL, which means
    /// the person chose it.
    public func read(url: URL) throws -> Read {
        // Checked before the file is touched. Reading first meant an https URL
        // failed with "the file could not be opened", which tells a person nothing
        // about the rule that actually refused it.
        if Self.kind(for: url) == .link { throw SourceReadError.refusingToFetchLink }

        let data = try Data(contentsOf: url)
        let digest = Self.digest(of: data)
        let title = url.lastPathComponent
        let locator = url.absoluteString

        switch Self.kind(for: url) {
        case .link:
            // Never reached through this path, and refused if it somehow is: this
            // function reads a file that exists.
            throw SourceReadError.refusingToFetchLink
        case .image:
            // The bytes are digested so the file can be recognised later, and
            // nothing else happens. No OCR, no description, no guess.
            return Read(
                kind: .image, title: title, locator: locator,
                extraction: .notAttempted, digest: digest
            )
        case .csv:
            return try readCSV(data: data, title: title, locator: locator, digest: digest)
        case .pdf:
            return readPDF(data: data, title: title, locator: locator, digest: digest)
        case .text, .markdown:
            return try readText(data: data, title: title, locator: locator, digest: digest)
        case .other:
            return Read(
                kind: .other, title: title, locator: locator,
                extraction: .unsupported(reason: "no reader for this kind of file"),
                digest: digest
            )
        }
    }

    // MARK: Kinds

    /// The kind is decided by the extension, with the content type as a second
    /// opinion for the ambiguous cases. A file whose extension lies is still read as
    /// text, which is the forgiving and correct behaviour for a text format.
    public static func kind(for url: URL) -> SourceReference.Kind {
        // A pasted link has no useful extension, so the scheme decides. Getting this
        // wrong would file a web address as an unknown file kind, and the person
        // would be told a format is unsupported rather than that it is a link.
        if let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" {
            return .link
        }
        switch url.pathExtension.lowercased() {
        case "md", "markdown": return .markdown
        case "txt", "text": return .text
        case "csv", "tsv": return .csv
        case "pdf": return .pdf
        case "png", "jpg", "jpeg", "heic", "gif", "webp", "tiff": return .image
        case "url", "webloc", "link": return .link
        default: return .other
        }
    }

    // MARK: Readers

    private func readText(
        data: Data, title: String, locator: String, digest: String
    ) throws -> Read {
        guard let text = String(data: data, encoding: .utf8) else {
            // Not "imported with no text", which would be a different and wrong
            // claim: the file may well have text, in an encoding we cannot read.
            return Read(
                kind: .text, title: title, locator: locator,
                extraction: .unsupported(reason: "the file is not UTF-8 text"),
                digest: digest
            )
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return Read(
                kind: .text, title: title, locator: locator,
                extraction: .noText(reason: "the file is empty"),
                digest: digest
            )
        }
        return Read(
            kind: .text, title: title, locator: locator,
            extraction: .ready(text: text), digest: digest
        )
    }

    private func readCSV(
        data: Data, title: String, locator: String, digest: String
    ) throws -> Read {
        guard let text = String(data: data, encoding: .utf8) else {
            return Read(
                kind: .csv, title: title, locator: locator,
                extraction: .unsupported(reason: "the file is not UTF-8 text"),
                digest: digest
            )
        }
        do {
            let table = try CSVTable.parse(text)
            guard table.headers.isEmpty == false else {
                return Read(
                    kind: .csv, title: title, locator: locator,
                    extraction: .noText(reason: "the file has no header row"),
                    digest: digest
                )
            }
            // A CSV is quoted as text so a citation can point at a row, and the
            // parsed table travels with it so the row can be shown as a table
            // rather than as a wall of commas.
            return Read(
                kind: .csv, title: title, locator: locator,
                extraction: .ready(text: text),
                digest: digest,
                table: table
            )
        } catch {
            return Read(
                kind: .csv, title: title, locator: locator,
                extraction: .partial(
                    text: text,
                    reason: "the file is not valid CSV: a quoted field is never closed"
                ),
                digest: digest
            )
        }
    }

    private func readPDF(
        data: Data, title: String, locator: String, digest: String
    ) -> Read {
        guard let document = PDFDocument(data: data) else {
            return Read(
                kind: .pdf, title: title, locator: locator,
                extraction: .unsupported(reason: "the file could not be opened as a PDF"),
                digest: digest
            )
        }
        var pages: [String] = []
        for index in 0..<document.pageCount {
            guard let text = document.page(at: index)?.string else { continue }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty == false { pages.append(trimmed) }
        }
        guard pages.isEmpty == false else {
            // The common real case: a scan. There is no text layer, and pretending
            // otherwise would produce an empty document that looks imported.
            return Read(
                kind: .pdf, title: title, locator: locator,
                extraction: .noText(reason: "the PDF has no text layer, it may be a scan"),
                digest: digest
            )
        }
        return Read(
            kind: .pdf, title: title, locator: locator,
            extraction: .ready(text: pages.joined(separator: "\n\n")),
            digest: digest
        )
    }

    // MARK: Digest

    /// A digest of the bytes that were actually read.
    ///
    /// This is what lets a person be told "this is not the file your claim was based
    /// on" without the app claiming to understand the document's content.
    public static func digest(of data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

public enum SourceReadError: Error, Equatable {
    /// Reading a file never turns into fetching a URL. The two are different acts
    /// and only one of them was asked for.
    case refusingToFetchLink
}
