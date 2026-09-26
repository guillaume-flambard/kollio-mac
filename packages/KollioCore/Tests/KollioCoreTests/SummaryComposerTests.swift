import Foundation
import Testing
@testable import KollioCore

/// The composer that fills a synthesis without a model.
///
/// The tests are about what it refuses to do, because that is the whole of it: a
/// deterministic reader that writes only what it can point at, declares absence
/// where absence is a fact, and leaves alone the one thing it cannot know.
@Suite("Summary composer")
struct SummaryComposerTests {
    private var ctx: ObjectID { ObjectID("object:ctx") }
    private var method: ObjectID { ObjectID("object:method") }

    private func objective() -> SummaryArtifact.SummaryLine {
        SummaryArtifact.SummaryLine(
            id: SummaryLineID("objective"),
            text: LocalizedText("Decide what to change before the review"),
            provenance: .human(ActorID("actor:guillaume"))
        )
    }

    private func compose(
        _ document: KollioDocument,
        title: String = "Sign-up funnel"
    ) -> SummaryComposer.Outcome {
        SummaryComposer.compose(
            id: SummaryID("s1"), title: title, objective: objective(), in: document, languageCode: "en"
        )
    }

    @Test("Every line it writes rests on something")
    func everyLineIsReferenced() {
        var builder = DocumentBuilder()
        builder.object("ctx", kind: .context, "Reduce the sign-up flow to three steps")
        builder.object("method", kind: .method, "Instrument each step")
        let recorded = builder.setAside("reject-1", target: method, rationale: "No budget this year")
        #expect(recorded)
        let outcome = compose(builder.document)

        let lines = outcome.summary.allLines
        #expect(lines.count > 1)
        for line in lines {
            // The composer writes engine lines, so an unreferenced one would be
            // refused by the command layer. Composing something the store would
            // reject would be a composer that cannot be used.
            #expect(
                !line.isUnsupportedAssertion,
                "\(line.id) rests on nothing and the store would refuse it"
            )
        }
    }

    @Test("It never offers a rejected direction as a direction")
    func neverOffersARejectedDirection() {
        var builder = DocumentBuilder()
        builder.object("ctx", kind: .context, "Reduce the sign-up flow to three steps")
        builder.object("method", kind: .method, "Instrument each step")
        let recorded = builder.setAside("reject-1", target: method, rationale: "No budget this year")
        #expect(recorded)
        let outcome = compose(builder.document)

        // The set-aside object is reported as set aside, in the reasons, with the
        // person's own reason. It is never presented as a current direction.
        let reasons = outcome.summary.reasons.flatMap(\.lines)
        #expect(reasons.count == 1)
        #expect(reasons[0].text.text.contains("set aside"))
        #expect(reasons[0].text.text.contains("No budget this year"))

        let state = outcome.summary.currentState.flatMap(\.lines)
        #expect(state.allSatisfy { $0.text.text.contains("set aside") == false })
        let stateTexts = state.map(\.text.text)
        #expect(stateTexts.contains { $0.contains("Instrument each step") } == false)
    }

    @Test("A rejection with no reason becomes an uncertainty, not a reason")
    func unreasonedRejectionIsAnUncertainty() {
        var builder = DocumentBuilder()
        builder.object("ctx", kind: .context, "Reduce the sign-up flow to three steps")
        builder.object("method", kind: .method, "Instrument each step")
        let recorded = builder.setAside("reject-1", target: method, rationale: "   ")
        #expect(recorded)
        let outcome = compose(builder.document)

        // The document records that something stopped and not why. That is an
        // uncertainty about the document, and it is the only honest place for it.
        // Not an empty array: a declared absence, which is a different claim.
        let reasons = outcome.summary.reasons
        #expect(reasons.count == 1)
        #expect(reasons[0].isNothingRecorded)
        #expect(reasons[0].lines.isEmpty)
        let uncertainties = outcome.summary.uncertainties.flatMap(\.lines)
        #expect(uncertainties.count == 1)
        #expect(uncertainties[0].text.text.contains("no reason recorded"))
    }

    @Test("It leaves uncertainties absent rather than declaring there are none")
    func itCannotDeclareNothingUncertain() {
        var builder = DocumentBuilder()
        builder.object("ctx", kind: .context, "Reduce the sign-up flow to three steps")
        let outcome = compose(builder.document)

        // This is the asymmetry the whole design rests on. A deterministic reader
        // knows what the document says. It has no way of knowing what the document
        // failed to say, so "nothing was recorded here" would be a claim about the
        // world wearing the costume of a fact about a file.
        #expect(outcome.summary.uncertainties.isEmpty)

        // The state has something in it, because the document has one active
        // object, so it is written rather than declared.
        let state = outcome.summary.currentState
        #expect(state.count == 1)
        #expect(state[0].lines.count == 1)
        #expect(state[0].isNothingRecorded == false)

        // These two have nothing behind them, and the composer can tell the
        // difference: no rejection exists, and no hypothesis lacks a claim.
        for section in [SummaryArtifact.Section.reasons, .nextVerifications] {
            let value = outcome.summary.sections(section)
            #expect(value.count == 1)
            #expect(value[0].lines.isEmpty)
            #expect(value[0].isNothingRecorded)
        }
    }

    @Test("A hypothesis no claim touches is named as unexamined")
    func unexaminedHypothesisIsNamed() {
        var builder = DocumentBuilder()
        builder.object("ctx", kind: .context, "Reduce the sign-up flow to three steps")
        builder.object("hyp", kind: .hypothesis, "The network is the bottleneck")
        let outcome = compose(builder.document)

        let verifications = outcome.summary.nextVerifications.flatMap(\.lines)
        #expect(verifications.count == 1)
        // Stated as a fact about the document: no claim rests on it. Not as a
        // prediction that it is wrong, and not as a recommendation. Citations hang
        // off claims rather than off objects, so the composer says the one thing
        // the document can actually answer.
        #expect(verifications[0].text.text.contains("no claim rests on it yet"))
        #expect(verifications[0].references.contains { $0.id == "object:hyp" })
    }

    @Test("A selection too wide is refused, and the narrower scope is kept")
    func tooWideIsRefused() {
        var builder = DocumentBuilder()
        for index in 0..<(SummaryComposer.objectLimit + 5) {
            builder.object("o\(index)", kind: .context, "Object number \(index)")
        }
        let outcome = compose(builder.document)

        #expect(outcome.summary.proposedNarrowerScope != nil)
        #expect(outcome.summary.proposedNarrowerScope?.objectIDs.count == SummaryComposer.objectLimit)
        #expect(outcome.summary.proposedNarrowerScope?.reason.contains("\(SummaryComposer.objectLimit + 5) objects") == true)
        #expect(outcome.summary.readSet.objectIDs.count == SummaryComposer.objectLimit)
    }

    @Test("The read set is sorted, so two runs give the same synthesis")
    func readSetIsDeterministic() {
        var builder = DocumentBuilder()
        for index in 0..<8 {
            builder.object("o\(index)", kind: .context, "Object number \(index)")
        }
        let a = compose(builder.document).summary.readSet
        let b = compose(builder.document).summary.readSet
        #expect(a == b)
        #expect(a.sorted() == a)
    }

    @Test("It composes a draft, always")
    func alwaysADraft() {
        var builder = DocumentBuilder()
        builder.object("ctx", kind: .context, "Reduce the sign-up flow to three steps")
        #expect(compose(builder.document).summary.isDraft)
    }

    @Test("What it composes is accepted by the store")
    func whatItComposesIsAccepted() throws {
        var builder = DocumentBuilder()
        builder.object("ctx", kind: .context, "Reduce the sign-up flow to three steps")
        builder.object("method", kind: .method, "Instrument each step")
        builder.object("hyp", kind: .hypothesis, "The network is the bottleneck")
        let recorded = builder.setAside("reject-1", target: method, rationale: "No budget")
        #expect(recorded)

        var store = DocumentStore(document: builder.document)
        let outcome = compose(store.document)
        // A composer whose output the store refuses is not a composer, it is a
        // suggestion that has to be rewritten by hand.
        try store.apply([.startSummary(.init(
            summary: outcome.summary, provenance: .human(ActorID("actor:guillaume"))
        ))])
        #expect(store.document.summaries.summary(SummaryID("s1")) != nil)
    }

    @Test("A long line is shortened with a real ellipsis")
    func longLinesAreShortened() {
        var builder = DocumentBuilder()
        builder.object("ctx", kind: .context, String(repeating: "word ", count: 80))
        let outcome = compose(builder.document)
        let line = outcome.summary.currentState.flatMap(\.lines).first
        #expect(line?.text.text.hasSuffix("…") == true)
        #expect(line?.text.text.count ?? 0 < 130)
    }

    @Test("An empty document composes to almost nothing, and says so")
    func emptyDocument() {
        let outcome = compose(KollioDocument())
        #expect(outcome.summary.currentState[0].isNothingRecorded)
        #expect(outcome.summary.uncertainties.isEmpty)
        #expect(outcome.summary.readSet.objectIDs.isEmpty)
    }
}
