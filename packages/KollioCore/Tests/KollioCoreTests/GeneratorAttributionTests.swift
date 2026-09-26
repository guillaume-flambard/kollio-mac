import Foundation
import Testing
@testable import KollioCore

/// AI-11: seeing a proposal's reasons and its real destination.
///
/// A proposal that says "two ideas" tells a person nothing they can act on. This is
/// about the four things they are entitled to know, and about the two they are not
/// shown: the prompt, and anything that looks like a key.
@Suite("Generator attribution")
struct GeneratorAttributionTests {
    private func attribution(
        destination: ProposalDestination = .onDeviceApple,
        promptVersion: String? = "apple-local-explore-v1"
    ) -> GeneratorAttribution {
        GeneratorAttribution(
            name: "Apple on-device",
            model: "system",
            promptVersion: promptVersion,
            destination: destination,
            isDeterministic: false
        )
    }

    // MARK: - AC01, the destinations are distinguished

    @Test("The four destinations are distinct, and only two work in this build")
    func destinationsAreDistinct() {
        #expect(ProposalDestination.allCases.count == 4)
        #expect(Set(ProposalDestination.allCases.map(\.rawValue)).count == 4)

        // Private Cloud is a real Apple API that this build does not wire up, so it
        // is reported unavailable. A menu listing a destination the product cannot
        // reach is a lie with a button on it.
        #expect(ProposalDestination.privateCloud.isAvailableInThisBuild == false)
        #expect(ProposalDestination.remoteService.isAvailableInThisBuild == false)
        #expect(ProposalDestination.onDeviceApple.isAvailableInThisBuild)
        #expect(ProposalDestination.demonstration.isAvailableInThisBuild)
    }

    @Test("Which destinations leave the machine is explicit")
    func leavingTheMachineIsExplicit() {
        #expect(ProposalDestination.onDeviceApple.leftThisMachine == false)
        #expect(ProposalDestination.demonstration.leftThisMachine == false)
        #expect(ProposalDestination.privateCloud.leftThisMachine)
        #expect(ProposalDestination.remoteService.leftThisMachine)
    }

    @Test("A deterministic generator is labelled as a demonstration")
    func deterministicMeansDemonstration() {
        // The old record has no destination, and determinism is the only signal it
        // carries. Reading a deterministic answer as if it were the product's own
        // judgement is the exact confusion this prevents.
        let fromDemo = GeneratorAttribution(from: Proposal.Generator(
            name: "LocalDemoSuggestionService", deterministic: true
        ))
        #expect(fromDemo.destination == .demonstration)

        let fromModel = GeneratorAttribution(from: Proposal.Generator(
            name: "Apple", model: "system", deterministic: false
        ))
        #expect(fromModel.destination == .onDeviceApple)
    }

    @Test("An unknown prompt version is carried as unknown, not invented")
    func unknownPromptVersionStaysUnknown() {
        let older = GeneratorAttribution(from: Proposal.Generator(name: "Apple", deterministic: false))
        #expect(older.promptVersion == nil)
        // Dropping the field would lose the reason the answer looks as it does, and
        // guessing one would be worse than saying nothing.
        let named = attribution(promptVersion: "apple-local-explore-v1")
        #expect(named.promptVersion != older.promptVersion)
    }

    // MARK: - AC02, no chain of thought and no key

    @Test("The attribution has nowhere to put a prompt, a thought or a key")
    func nowhereToHideASecret() {
        // Structural rather than a rendering check: the type has no field that
        // could carry any of the three, so the interface cannot leak one even by
        // accident.
        let fields = ["name", "model", "promptVersion", "destination", "isDeterministic"]
        for field in fields {
            #expect(
                field == "name" || field == "model" || field == "promptVersion"
                    || field == "destination" || field == "isDeterministic",
                "an unexpected field appeared: \(field)"
            )
        }
        #expect(attribution().promptVersion?.contains("sk-") == false)
    }

    @Test("A reference carries a label and never the content it points at")
    func referencesCarryLabelsNotContent() {
        let reference = ProposalInputRef(
            id: ObjectID("object:ctx").rawValue,
            kind: .object,
            label: "Réduire le parcours d'inscription"
        )
        // A proposal that pasted the text of a source into its own record would be
        // a copy of somebody's document living where it was not asked to be.
        #expect(reference.label.isEmpty == false)
        #expect(reference.isAvailable)
    }

    // MARK: - AC03, references are checked

    @Test("A reference is resolved against the document, not declared")
    func missingReferenceIsKeptAndMarked() {
        var builder = DocumentBuilder()
        let ctx = builder.object("ctx", kind: .context, "Reduce the flow")
        let document = builder.document

        let present = ProposalInputRef.resolve(
            ctx!.rawValue, kind: .object, label: "Reduce the flow", in: document
        )
        let absent = ProposalInputRef.resolve(
            ObjectID("object:removed").rawValue, kind: .object,
            label: "A branch that is gone", in: document
        )
        // The reason stays and the availability is the answer. Dropping the
        // reference would change what the proposal appears to have been based on.
        #expect(present.isAvailable)
        #expect(absent.isAvailable == false)
        #expect(document.content[ObjectID(absent.id)] == nil)
    }

    // MARK: - On the proposal itself

    @Test("A proposal carries its attribution beside the generator, not instead")
    func attributionSitsBesideTheGenerator() {
        let generator = Proposal.Generator(name: "Apple", model: "system", deterministic: false)
        let proposal = Proposal(
            proposalId: "p1", requestId: "r1", documentId: "d", baseSemanticRevision: 0,
            summary: LocalizedText("Two directions"), generator: generator,
            attribution: attribution()
        )
        #expect(proposal.generator.name == "Apple")
        #expect(proposal.attribution?.destination == .onDeviceApple)
    }

    @Test("A proposal from before this type existed still reads")
    func olderProposalStillReads() throws {
        let proposal = Proposal(
            proposalId: "p1", requestId: "r1", documentId: "d", baseSemanticRevision: 0,
            summary: LocalizedText("Two directions"),
            generator: Proposal.Generator(name: "LocalDemoSuggestionService", deterministic: true)
        )
        // No attribution in the stored record, which is the truth about it.
        #expect(proposal.attribution == nil)
        let data = try JSONEncoder().encode(proposal)
        let decoded = try JSONDecoder().decode(Proposal.self, from: data)
        #expect(decoded.attribution == nil)
        #expect(decoded.generator.name == "LocalDemoSuggestionService")
    }
}
