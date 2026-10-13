import Foundation
import Testing
import KollioCore
@testable import KollioApp

@Suite("Spatial Ink — real document read projection")
struct SpatialDocumentProjectionTests {
    @Test("Projecting Sarah leaves every semantic and presentation field untouched")
    func realDocumentInvariant() throws {
        let document = SarahFixture.document()
        let original = document
        let projection = SpatialDocumentProjection(document: document)
        #expect(projection.documentID == document.documentId)
        #expect(projection.revision == document.revision)
        #expect(projection.semanticRevision == document.semanticRevision)
        #expect(projection.nodes.count == document.content.count)
        #expect(projection.edges.count == document.relationships.count)
        #expect(Set(projection.nodes.map(\.id)).count == projection.nodes.count)
        #expect(Set(projection.edges.map(\.id)).count == projection.edges.count)
        #expect(projection.nodes.map(\.id) == projection.nodes.map(\.id).sorted())
        #expect(projection.edges.map(\.id) == projection.edges.map(\.id).sorted())
        for node in projection.nodes {
            let originalObject = document.content[ObjectID(node.id)]
            #expect(originalObject?.text.text == node.label)
            #expect(originalObject?.kind.rawValue == node.kind)
        }
        #expect(document == original)
    }

    @Test("Real document text respects the active interface language")
    func localizedRead() {
        let document = SarahFixture.document()
        let english = SpatialDocumentProjection(document: document, languageCode: "en")
        let french = SpatialDocumentProjection(document: document, languageCode: "fr")
        for node in english.nodes {
            let source = document.content[ObjectID(node.id)]
            #expect(node.label == source?.text.resolve(languageCode: "en"))
        }
        for node in french.nodes {
            let source = document.content[ObjectID(node.id)]
            #expect(node.label == source?.text.resolve(languageCode: "fr"))
        }
        #expect(english.nodes.map(\.id) == french.nodes.map(\.id))
        #expect(english.edges.map(\.id) == french.edges.map(\.id))
    }

    @Test("Empty document projects without inventing content")
    func emptyDocument() {
        let document = KollioDocument()
        let projection = SpatialDocumentProjection(document: document)
        #expect(projection.nodes.isEmpty)
        #expect(projection.edges.isEmpty)
        #expect(projection.revision == document.revision)
    }
}
