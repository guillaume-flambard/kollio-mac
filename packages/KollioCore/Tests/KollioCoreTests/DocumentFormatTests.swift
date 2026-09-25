import Foundation
import Testing
@testable import KollioCore

@Suite("Document format")
struct DocumentFormatTests {
    @Test("Round-trips through the portable JSON format")
    func roundTrip() throws {
        let document = Fixture.sarah()
        let data = try DocumentCodec.encode(document)
        let decoded = try DocumentCodec.decode(data)
        #expect(decoded == document)
    }

    @Test("Stores no renderer type and no platform type")
    func portability() throws {
        let data = try DocumentCodec.encode(Fixture.sarah())
        let json = String(decoding: data, as: UTF8.self)
        #expect(!json.contains("CGPoint"))
        #expect(!json.contains("Color"))
        #expect(!json.contains("SwiftUI"))
        // Geometry is stored as plain {x,y} / {width,height} values.
        #expect(json.contains("\"x\""))
        #expect(json.contains("\"width\""))
    }

    @Test("Rejects a newer schema version instead of guessing")
    func futureSchema() throws {
        var document = Fixture.sarah()
        document.schemaVersion = KollioDocument.currentSchemaVersion + 1
        let data = try DocumentCodec.encode(document)
        #expect(throws: DocumentCodec.CodecError.self) {
            try DocumentCodec.decode(data)
        }
    }

    @Test("Keeps object identity stable across serialization")
    func stableIDs() throws {
        let document = Fixture.sarah()
        let decoded = try DocumentCodec.decode(try DocumentCodec.encode(document))
        #expect(Set(document.content.keys) == Set(decoded.content.keys))
        #expect(Set(document.relationships.keys) == Set(decoded.relationships.keys))
        #expect(Set(document.presentation.instances.map(\.objectID)) == Set(decoded.presentation.instances.map(\.objectID)))
    }

    @Test("Derives three visual forms from the semantic kinds")
    func visualForms() {
        let object = ContentObject(id: "a", kind: .hypothesis, text: LocalizedText("x"), provenance: .human("me"))
        #expect(object.form == .thought)
        let product = ContentObject(id: "b", kind: .product, text: LocalizedText("x"), provenance: .human("me"))
        #expect(product.form == .richResult)
        let evidence = ContentObject(id: "c", kind: .evidence, text: LocalizedText("x"), provenance: .human("me"))
        #expect(evidence.form == .reference)
    }
}
