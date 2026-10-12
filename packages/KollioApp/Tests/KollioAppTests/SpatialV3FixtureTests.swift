import Foundation
import Testing
@testable import KollioApp

@Suite("Spatial Ink V3 — shared contract")
struct SpatialV3FixtureTests {
    @Test("Every relationship points to two known objects")
    func references() {
        let ids = Set(SpatialV3Fixture.nodes.map(\.id))
        #expect(Set(SpatialV3Fixture.nodes.map(\.id)).count == SpatialV3Fixture.nodes.count)
        for edge in SpatialV3Fixture.edges {
            #expect(ids.contains(edge.source))
            #expect(ids.contains(edge.target))
            #expect(edge.source != edge.target)
        }
    }

    @Test("Exploration is presentation only; it never removes objects")
    func presentationOnly() {
        let initial = SpatialV3Fixture.nodes.filter { $0.depth <= 1 }
        let expanded = SpatialV3Fixture.nodes.filter { $0.depth <= 2 }
        #expect(initial.count == 3)
        #expect(expanded.count == 6)
        #expect(Set(initial.map(\.id)).isSubset(of: Set(expanded.map(\.id))))
        #expect(SpatialV3Fixture.edges.filter { $0.depth <= 1 }.count == 2)
        #expect(SpatialV3Fixture.edges.filter { $0.depth <= 2 }.count == 5)
    }

    @Test("Proposal is provisional and source is not asserted verified")
    func authorityAndProvenance() {
        let proposal = SpatialV3Fixture.nodes.first { $0.kind == "proposal" }
        #expect(proposal?.status == "pending")
        let source = SpatialV3Fixture.nodes.first { $0.kind == "source" }
        #expect(source?.status == "unverified")
    }

    @Test("Normalized coordinates stay inside the spatial surface")
    func coordinates() {
        for node in SpatialV3Fixture.nodes {
            #expect((0...1).contains(node.x))
            #expect((0...1).contains(node.y))
        }
    }
}
