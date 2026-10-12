import Foundation
import Testing
@testable import KollioApp

@Suite("Spatial V3 stress contract")
struct SpatialV3StressTests {
    @Test("Native fixture contains 100 objects and 200 routed relations")
    func counts() {
        #expect(SpatialV3StressFixture.nodes.count == 100)
        #expect(SpatialV3StressFixture.edges.count == 200)
        for edge in SpatialV3StressFixture.edges {
            #expect(edge.points.count >= 2)
            #expect(!edge.blocked)
        }
    }
}
