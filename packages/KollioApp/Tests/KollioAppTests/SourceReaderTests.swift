import Foundation
import PDFKit
import CoreText
import Testing
import KollioCore
@testable import KollioApp

/// Reading a file the person chose.
///
/// The two acceptance criteria that matter most are here by name: a CSV with
/// quotes and newlines parses correctly, and an image-only PDF is marked as having
/// no text. Both are cases where a plausible-looking reader would produce something
/// wrong rather than something absent.
@Suite("Reading a source")
struct SourceReaderTests {
    /// One directory per test instance. A computed property would mint a new UUID on
    /// every access, so the file written and the file read would be in different
    /// places, which is exactly the kind of quiet wrongness these tests exist to
    /// catch.
    private let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("kollio-reader-\(UUID().uuidString)")

    private func write(_ text: String, extension pathExtension: String, named name: String = "source") throws -> URL {
        let url = directory.appendingPathComponent("\(name).\(pathExtension)")
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        try Data(text.utf8).write(to: url)
        return url
    }

    private func write(_ data: Data, extension pathExtension: String, named name: String = "source") throws -> URL {
        let url = directory.appendingPathComponent("\(name).\(pathExtension)")
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        try data.write(to: url)
        return url
    }

    // MARK: CSV

    @Test("AC01: a CSV with quotes, commas and newlines parses correctly")
    func csvWithQuotedFields() throws {
        // The whole point: this row contains the delimiter, a doubled quote, and a
        // newline inside one field.
        let csv = """
        name,note
        "Rivera, Ana","said ""yes""
        on Tuesday"
        Okafor,"plain, simple"
        """
        let url = try write(csv, extension: "csv")
        let read = try SourceReader().read(url: url)

        #expect(read.kind == .csv)
        #expect(read.table?.headers == ["name", "note"])
        #expect(read.table?.rows.count == 2)

        let first = try #require(read.table?.rows.first)
        #expect(first.count == 2)
        // A comma inside quotes is data, not a separator.
        #expect(first[0] == "Rivera, Ana")
        // A doubled quote is one literal quote, and the newline stayed in the field.
        #expect(first[1] == "said \"yes\"\non Tuesday")
        #expect(read.table?.value(row: first, column: "note") == "said \"yes\"\non Tuesday")
        #expect(read.table?.value(row: read.table!.rows[1], column: "name") == "Okafor")
    }

    @Test("A CSV ending without a newline still yields its last row")
    func csvWithoutTrailingNewline() throws {
        let url = try write("a,b\n1,2", extension: "csv")
        let read = try SourceReader().read(url: url)
        #expect(read.table?.rows == [["1", "2"]])
    }

    @Test("A CSV with CRLF line endings parses the same as one with LF")
    func csvWithWindowsLineEndings() throws {
        let url = try write("a,b\r\n1,2\r\n3,4\r\n", extension: "csv")
        let read = try SourceReader().read(url: url)
        #expect(read.table?.headers == ["a", "b"])
        #expect(read.table?.rows == [["1", "2"], ["3", "4"]])
    }

    @Test("A CSV whose quote is never closed is partial, and says why")
    func unterminatedQuoteIsPartial() throws {
        let url = try write("a,b\n1,\"never closed\n2,3\n", extension: "csv")
        let read = try SourceReader().read(url: url)
        // The bytes are kept, because a person may still want to look at the file,
        // but it is not presented as a successfully parsed table.
        #expect(read.table == nil)
        if case .partial(_, let reason) = read.extraction {
            #expect(reason.contains("never closed"))
        } else {
            Issue.record("an unterminated quote must be reported as partial, not ready")
        }
    }

    @Test("A CSV with only a header has rows, not nothing")
    func headerOnlyCSV() throws {
        let url = try write("a,b\n", extension: "csv")
        let read = try SourceReader().read(url: url)
        #expect(read.table?.headers == ["a", "b"])
        #expect(read.table?.rows.isEmpty == true)
    }

    @Test("A preview is capped and says nothing about the rest")
    func previewIsCapped() throws {
        var rows = (0..<50).map { ["\($0)", "b\($0)"] }
        rows.insert(["id", "name"], at: 0)
        let csv = rows.map { "\($0[0]),\($0[1])" }.joined(separator: "\n")
        let table = try CSVTable.parse(csv)
        #expect(table.rows.count == 50)
        #expect(table.preview().rows.count == 5)
    }

    // MARK: PDF

    @Test("AC02: a PDF with no text layer is marked as having no text")
    func pdfWithoutTextLayerHasNoText() throws {
        // Built with a real PDF context rather than as a checked-in binary, so the
        // test states exactly what it means: a valid PDF whose content stream draws
        // a shape and never a glyph. That is what a scan looks like to a reader.
        let url = directory.appendingPathComponent("scan.pdf")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        #expect(Self.makePDF(at: url, drawText: false) != nil)

        let read = try SourceReader().read(url: url)
        #expect(read.kind == .pdf)
        #expect(read.extraction.isUsable == false)
        if case .noText(let reason) = read.extraction {
            #expect(reason.contains("scan"))
        } else {
            Issue.record("a PDF with no text layer must say so, not import as empty")
        }
    }

    @Test("A PDF with a text layer is read")
    func textPDFIsRead() throws {
        let url = directory.appendingPathComponent("text.pdf")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        #expect(Self.makePDF(at: url, drawText: true) != nil)

        let read = try SourceReader().read(url: url)
        #expect(read.extraction.isUsable)
        #expect(read.extraction.text?.contains("nine steps") == true)
    }

    // MARK: Text, image, link

    @Test("An image is digested and nothing else")
    func imageIsNotUnderstood() throws {
        let url = try write(Self.blankImage().tiffRepresentation ?? Data(), extension: "png")
        let read = try SourceReader().read(url: url)
        #expect(read.kind == .image)
        // No description, no guessed content, no OCR. The digest exists so the file
        // can be recognised later.
        #expect(read.extraction == .notAttempted)
        #expect(read.extraction.text == nil)
        #expect(read.digest.isEmpty == false)
    }

    @Test("A link is never fetched by the reader")
    func linkIsNeverFetched() throws {
        let url = URL(string: "https://example.invalid/page")!
        #expect(SourceReader.kind(for: url) == .link)
        #expect(throws: SourceReadError.refusingToFetchLink) {
            try SourceReader().read(url: url)
        }
    }

    @Test("An empty text file says it has no text")
    func emptyTextFileHasNoText() throws {
        let url = try write("   \n  \n", extension: "txt")
        let read = try SourceReader().read(url: url)
        if case .noText = read.extraction {} else {
            Issue.record("an empty file must not import as a ready source")
        }
    }

    @Test("A file of an unknown kind is refused honestly")
    func unknownKindIsRefused() throws {
        let url = try write(Data([0x00, 0x01, 0x02]), extension: "xyz")
        let read = try SourceReader().read(url: url)
        #expect(read.kind == .other)
        if case .unsupported = read.extraction {} else {
            Issue.record("an unreadable kind must be unsupported, not an empty success")
        }
    }

    @Test("Two files with the same bytes have the same digest, and different ones do not")
    func digestTracksContent() throws {
        // Distinct file names: writing two different contents to one path would
        // leave only the last one, and the test would compare a file with itself.
        let a = try write("same", extension: "txt", named: "a")
        let b = try write("same", extension: "md", named: "b")
        let c = try write("different", extension: "txt", named: "c")
        let reader = SourceReader()
        #expect(try reader.read(url: a).digest == reader.read(url: b).digest)
        #expect(try reader.read(url: a).digest != reader.read(url: c).digest)
    }

    // MARK: Fixtures built in-process

    private static func blankImage() -> NSImage {
        NSImage(size: NSSize(width: 8, height: 8))
    }

    /// Writes a real PDF whose content stream either draws glyphs or does not.
    ///
    /// A `PDFPage` built with a text *annotation* was tried first and does not work:
    /// annotations are not page content, so `page.string` finds nothing, which is a
    /// faithful reflection of how annotations behave and not a way to make a fixture.
    /// Drawing through a PDF context is what actually produces a text layer.
    private static func makePDF(at url: URL, drawText: Bool) -> Bool {
        var mediaBox = CGRect(x: 0, y: 0, width: 300, height: 300)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return false
        }
        context.beginPDFPage(nil)
        if drawText {
            let attributed = NSAttributedString(
                string: "Signup takes nine steps today.",
                attributes: [.font: NSFont.systemFont(ofSize: 14)]
            )
            let line = CTLineCreateWithAttributedString(attributed)
            context.textPosition = CGPoint(x: 24, y: 240)
            CTLineDraw(line, context)
        } else {
            // A filled rectangle: a real page with no glyphs on it at all.
            context.setFillColor(NSColor.black.cgColor)
            context.fill(CGRect(x: 20, y: 20, width: 120, height: 120))
        }
        context.endPDFPage()
        context.closePDF()
        return true
    }
}
