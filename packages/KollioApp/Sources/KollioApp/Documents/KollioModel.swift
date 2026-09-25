import Foundation
import Observation
import KollioCore

/// Where a `.kollio` document lives on this machine.
public struct DocumentFileStore: Sendable {
    public let directory: URL

    public init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let base = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.directory = base.appendingPathComponent("Kollio/Documents", isDirectory: true)
        }
    }

    public var defaultDocumentURL: URL {
        directory.appendingPathComponent("Kollio.\(DocumentCodec.fileExtension)")
    }

    public func url(named name: String) -> URL {
        directory.appendingPathComponent("\(name).\(DocumentCodec.fileExtension)")
    }

    public func load(_ url: URL) throws -> KollioDocument {
        try DocumentCodec.read(from: url)
    }

    public func save(_ document: KollioDocument, to url: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try DocumentCodec.write(document, to: url)
    }
}

/// A proposal being previewed as a ghost branch, before the user keeps it.
public struct ProposalPreview: Identifiable, Equatable {
    public var id: String { proposal.proposalId }
    public var proposal: Proposal
    /// Where each proposed object would appear.
    public var placements: [ObjectID: Position]
    public var objectIDs: [ObjectID]
    public var relationshipIDs: [RelationshipID]
    /// The object the branch grows from.
    public var anchorID: ObjectID
    /// The short, user-facing sentence shown next to the proposal.
    public var rationale: String
    public var summary: String

    public static func == (lhs: ProposalPreview, rhs: ProposalPreview) -> Bool {
        lhs.id == rhs.id && lhs.placements == rhs.placements
    }
}

/// The live editor state: the document, the camera, the selection, and the
/// proposal currently being previewed. Views read it; they never mutate the
/// document behind its back.
@MainActor
@Observable
public final class KollioModel {
    public enum Intent {
        case explore
        case add
        case setAside
    }

    // MARK: State
    public private(set) var session: KollioSession
    public var camera: Camera = .identity
    public var viewport: Size = Size(width: 1200, height: 800)
    public var selection: Set<ObjectID> = []
    public var hoveredObjectID: ObjectID?
    public var frames: [ObjectID: Rect] = [:]
    public var preview: ProposalPreview?
    public var isThinking = false
    public var status: String?
    public var composer: ComposerState?
    public var languageCode: String = KollioModel.systemLanguage
    public var documentURL: URL

    /// The intelligence source. Offline and deterministic by default; the
    /// backend adapter is interchangeable.
    public var service: any SuggestionService

    public let fileStore: DocumentFileStore

    public struct ComposerState: Equatable, Identifiable {
        public var id = UUID()
        /// The object the input is attached to.
        public var anchorID: ObjectID
        public var text: String = ""
        public var intent: Intent = .add
    }

    public static let systemLanguage: String = {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let code = Locale(identifier: preferred).language.languageCode?.identifier ?? "en"
        return ["fr", "en"].contains(code) ? code : "en"
    }()

    // MARK: Life cycle

    public init(
        document: KollioDocument? = nil,
        service: (any SuggestionService)? = nil,
        fileStore: DocumentFileStore = DocumentFileStore(),
        languageCode: String = KollioModel.systemLanguage
    ) {
        self.fileStore = fileStore
        self.languageCode = languageCode
        self.documentURL = fileStore.defaultDocumentURL
        self.service = service ?? KollioModel.makeDemoService(languageCode: languageCode)
        let loaded = document ?? (try? fileStore.load(fileStore.defaultDocumentURL)) ?? SarahFixture.document()
        self.session = KollioSession(document: loaded)
    }

    static func makeDemoService(languageCode: String) -> LocalDemoSuggestionService {
        LocalDemoSuggestionService(context: .init(
            language: languageCode,
            authored: SarahFixture.authoredExpansions
        ))
    }

    // MARK: Document access

    public var document: KollioDocument { session.document }

    public func object(_ id: ObjectID) -> ContentObject? { document.object(id) }

    public func text(of id: ObjectID) -> String {
        guard let object = document.object(id) else { return "" }
        return object.text.resolve(languageCode: languageCode)
    }

    public func detail(of id: ObjectID) -> String? {
        document.object(id)?.detail?.resolve(languageCode: languageCode)
    }

    public func label(of id: RelationshipID) -> String? {
        document.relationship(id)?.label?.resolve(languageCode: languageCode)
    }

    /// Reason of the active decision that set this object aside, if any.
    public func setAsideReason(of id: ObjectID) -> String? {
        guard let decisionID = document.object(id)?.setAsideByDecision,
              let decision = document.decisions[decisionID] else { return nil }
        return decision.rationale?.resolve(languageCode: languageCode)
    }

    /// A direction closed by a durable decision can be reopened.
    public func canReopen(_ id: ObjectID) -> Bool {
        document.object(id)?.isSetAside == true
    }

    /// The roots of the branches that were set aside. They stay on the canvas:
    /// a rejected direction is compact, not deleted.
    public var collapsedRoots: Set<ObjectID> {
        Set(
            document.decisions.values
                .filter { $0.status == .active && $0.kind == .setAside }
                .map(\.targetObjectID)
        )
    }

    /// Objects the canvas actually draws: everything active, plus the root of
    /// each collapsed direction.
    public var visibleInstances: [NodeInstance] {
        let roots = collapsedRoots
        return document.presentation.instances.filter { instance in
            guard let object = document.object(instance.objectID) else { return false }
            if object.isSetAside { return roots.contains(object.id) }
            return !isHiddenByCollapsedAncestor(instance.objectID)
        }
    }

    /// A collapsed direction hides its exclusive descendants, but nothing else.
    func isHiddenByCollapsedAncestor(_ objectID: ObjectID) -> Bool {
        for root in collapsedRoots {
            guard root != objectID,
                  document.exclusiveDescendants(of: root).contains(objectID) else { continue }
            return true
        }
        return false
    }

    public func relationshipsToRender() -> [Relationship] {
        let visibleIDs = Set(visibleInstances.map(\.objectID))
        return document.relationships.values
            .filter { visibleIDs.contains($0.from) && visibleIDs.contains($0.to) }
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }

    public func connectionsToRender(around objectID: ObjectID) -> [Relationship] {
        relationshipsToRender().filter { $0.from == objectID || $0.to == objectID }
    }

    // MARK: Geometry

    /// World rectangle of an object: the measured one when available.
    public func frame(of objectID: ObjectID) -> Rect? {
        if let measured = frames[objectID] { return measured }
        guard let object = document.object(objectID),
              let instance = document.presentation.instance(for: objectID) else { return nil }
        let size = instance.size ?? NodeLayout.estimatedSize(for: object)
        return Rect(origin: instance.position, size: size)
    }

    public func recordFrame(_ rect: Rect, for objectID: ObjectID) {
        guard frames[objectID] != rect else { return }
        frames[objectID] = rect
    }

    public func contentBounds() -> Rect? {
        let rects = visibleInstances.compactMap { document.object($0.objectID) }.compactMap { frame(of: $0.id) }
        guard let first = rects.first else { return nil }
        return rects.dropFirst().reduce(first) { $0.union($1) }
    }

    public func fitContent(animated: Bool = true) {
        guard let bounds = contentBounds() else { return }
        camera = Camera.fitting(content: bounds, viewport: viewport, padding: 120)
        _ = animated
    }

    // MARK: Selection

    public func select(_ id: ObjectID?, extending: Bool = false) {
        if let id {
            if extending {
                if selection.contains(id) { selection.remove(id) } else { selection.insert(id) }
            } else {
                selection = [id]
            }
        } else {
            selection = []
        }
        if selection.count > 1 { preview = nil }
    }

    public var primarySelection: ObjectID? { selection.sorted { $0.rawValue < $1.rawValue }.first }

    public func clearContextualState() {
        selection = []
        preview = nil
        composer = nil
    }

    // MARK: Direct manipulation

    /// Live drag state. The document is not touched while the cursor moves: the
    /// offset is applied visually, and one single transaction is committed on
    /// release.
    public struct DragState: Equatable {
        public var id: ObjectID
        public var worldDelta: Position
    }

    public var dragState: DragState?

    public func dragOffset(for objectID: ObjectID) -> Position {
        guard let dragState, dragState.id == objectID else { return .zero }
        return dragState.worldDelta
    }

    public func beginDrag(_ id: ObjectID, screenTranslation: CGSize) {
        // A gesture reports the cumulative translation from its start, so an
        // update for the same object replaces the delta instead of being ignored.
        if let dragState, dragState.id != id { return }
        dragState = DragState(
            id: id,
            worldDelta: camera.worldDelta(forScreenDelta: Position(x: screenTranslation.width, y: screenTranslation.height))
        )
    }

    /// One transaction, one undo entry, whatever the path the object took.
    public func endDrag() {
        guard let dragState else { return }
        self.dragState = nil
        let delta = dragState.worldDelta
        guard abs(delta.x) > 0.5 || abs(delta.y) > 0.5 else { return }
        moveObject(dragState.id, by: delta)
    }

    public func moveObject(_ id: ObjectID, by delta: Position) {
        guard let instance = document.presentation.instance(for: id) else { return }
        let destination = instance.position.offset(dx: delta.x, dy: delta.y)
        let move = MoveNodeInstance(instanceID: instance.id, position: destination)
        session.apply(
            [.moveNodeInstances(MoveNodeInstances(moves: [move]))],
            label: L10n.undoMove
        )
    }

    // MARK: Intelligence

    /// Asks the current source for a proposal and previews it as a ghost branch.
    public func explore(_ id: ObjectID, intent: Intent = .explore) async {
        guard !isThinking else { return }
        isThinking = true
        defer { isThinking = false }
        status = nil

        let request = ProposalRequest(
            requestId: UUID().uuidString,
            documentId: document.documentId,
            baseSemanticRevision: session.semanticRevision,
            intent: intent == .explore ? .explore : .add,
            targetIds: [id],
            contentLocale: languageCode
        )
        do {
            let response = try await service.respond(to: request, document: document)
            handle(response, anchor: id)
        } catch {
            status = L10n.errorGeneric
        }
    }

    /// The offline engine can be driven directly, with no request round-trip.
    public func handle(_ response: ProposalResponse, anchor: ObjectID) {
        switch response.status {
        case .noChange:
            preview = nil
            status = L10n.statusNoChange
        case .needsInput:
            composer = ComposerState(anchorID: anchor, intent: .add)
            status = response.questions.first?.resolve(languageCode: languageCode)
        case .proposed:
            guard let proposal = response.proposal else {
                status = L10n.statusNoChange
                return
            }
            preview = makePreview(proposal: proposal, anchor: anchor)
        }
    }

    /// Turns a proposal into a preview: where each proposed object would sit.
    ///
    /// Placement is intent, never pixels chosen by the generator, and it never
    /// lands on top of what is already on the canvas: a proposed object that
    /// would overlap an existing one is pushed down until the document stays
    /// readable.
    func makePreview(proposal: Proposal, anchor: ObjectID) -> ProposalPreview {
        var objectIDs: [ObjectID] = []
        var relationshipIDs: [RelationshipID] = []
        for operation in proposal.operations {
            switch operation {
            case .createObject(let create):
                objectIDs.append(create.id)
            case .addRelationship(let add):
                relationshipIDs.append(add.id)
            default:
                break
            }
        }

        let occupancy = occupiedRects(excluding: objectIDs)
        var placements: [ObjectID: Position] = [:]
        var taken: [Rect] = []

        for hint in proposal.placementHints {
            guard objectIDs.contains(hint.objectID) else { continue }
            let anchorCentre = hint.relativeTo.flatMap { frame(of: $0)?.center }
                ?? frame(of: anchor)?.center
                ?? .zero
            let size = estimatedSize(of: hint.objectID, in: proposal)
            var candidate = Position(
                x: anchorCentre.x + hint.offsetX,
                y: anchorCentre.y + hint.offsetY
            )
            candidate = separate(
                candidate,
                size: size,
                from: occupancy + taken
            )
            placements[hint.objectID] = candidate
            taken.append(Rect(origin: candidate, size: size))
        }

        // Anything created without a placement hint still gets a readable slot.
        for (index, id) in objectIDs.enumerated() where placements[id] == nil {
            let base = frame(of: anchor)?.center ?? .zero
            let size = estimatedSize(of: id, in: proposal)
            let candidate = separate(
                Position(x: base.x, y: base.y + Double(index + 1) * 170),
                size: size,
                from: occupancy + taken
            )
            placements[id] = candidate
            taken.append(Rect(origin: candidate, size: size))
        }

        let reason = proposal.rationale?.resolve(languageCode: languageCode) ?? ""
        return ProposalPreview(
            proposal: proposal,
            placements: placements,
            objectIDs: objectIDs,
            relationshipIDs: relationshipIDs,
            anchorID: anchor,
            rationale: reason,
            summary: proposal.summary.resolve(languageCode: languageCode)
        )
    }

    private func estimatedSize(of objectID: ObjectID, in proposal: Proposal) -> Size {
        guard let create = proposal.operations.compactMap({ operation -> CreateObject? in
            if case .createObject(let create) = operation, create.id == objectID { return create }
            return nil
        }).first else { return Size(width: NodeLayout.minimumWidth, height: NodeLayout.thoughtHeight) }
        return NodeLayout.estimatedSize(
            for: ContentObject(id: objectID, kind: create.kind, text: create.text, provenance: .human("ghost"))
        )
    }

    /// Every rectangle a proposed object must not cover.
    private func occupiedRects(excluding proposed: [ObjectID]) -> [Rect] {
        visibleInstances
            .filter { !proposed.contains($0.objectID) }
            .compactMap { frame(of: $0.objectID) }
    }

    /// Pushes a candidate down, then sideways, until it is clear of everything
    /// already on the canvas. Deterministic, and it never moves existing work.
    private func separate(_ position: Position, size: Size, from others: [Rect]) -> Position {
        let step = 34.0
        let gap = Space.m
        var candidate = position
        for _ in 0..<24 {
            let rect = Rect(origin: candidate, size: size)
            let blocker = others.first { rect.insetBy(dx: -gap, dy: -gap).intersects($0) }
            guard let blocker else { return candidate }
            candidate = Position(x: candidate.x, y: blocker.maxY + gap + size.height / 2)
        }
        // Still colliding after pushing down: step to the right of everything.
        let right = others.map(\.maxX).max() ?? candidate.x
        return Position(x: right + Space.xl + size.width / 2, y: candidate.y)
    }

    /// Keep: the proposed objects become normal document objects, in one
    /// transaction that undo restores as a whole.
    public func keepPreview() {
        guard let preview else { return }
        session.apply(
            [.applyProposal(ApplyProposal(
                proposal: preview.proposal,
                placements: preview.placements,
                provenance: .human("local-user")
            ))],
            label: L10n.undoKeepProposal
        )
        self.preview = nil
        status = L10n.statusKept
    }

    /// Setting a proposal aside discards it. Nothing was added to the document,
    /// so there is nothing to remember: a *direction* is set aside from its own
    /// contextual action, which does record a durable reason.
    public func discardPreview() {
        preview = nil
        status = L10n.statusDiscarded
    }

    /// Asks for the reason before setting a direction aside, so the memory of
    /// the decision belongs to the user and not to the machine.
    public func requestSetAsideReason(for id: ObjectID) {
        composer = ComposerState(anchorID: id, intent: .setAside)
    }

    /// Set aside on a real direction: a durable decision, not a deletion.
    public func setAside(_ id: ObjectID, reason: String?) {
        let command = Command.recordDecision(RecordDecision(
            id: KollioID.decision(UUID().uuidString),
            kind: .setAside,
            targetObjectID: id,
            rationale: reason.map { LocalizedText($0) },
            provenance: .human("local-user")
        ))
        guard session.apply([command], label: L10n.undoSetAside) else {
            status = L10n.errorGeneric
            return
        }
        if selection.contains(id) { selection.remove(id) }
        fitContent()
    }

    /// Reopen: restores the objects, the relationships and the positions.
    public func reopen(_ id: ObjectID) {
        let command = Command.recordDecision(RecordDecision(
            id: KollioID.decision(UUID().uuidString),
            kind: .reopened,
            targetObjectID: id,
            provenance: .human("local-user")
        ))
        guard session.apply([command], label: L10n.undoReopen) else {
            status = L10n.errorGeneric
            return
        }
        selection = [id]
        fitContent()
    }

    // MARK: Inline input

    public func startComposer(anchor: ObjectID, intent: Intent = .add) {
        composer = ComposerState(anchorID: anchor, intent: intent)
    }

    public func submitComposer() async {
        guard let composer else { return }
        let text = composer.text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch composer.intent {
        case .add:
            guard !text.isEmpty else { return }
            self.composer = nil
            await explore(composer.anchorID, intent: .add)
        case .setAside:
            self.composer = nil
            setAside(composer.anchorID, reason: text.isEmpty ? nil : text)
        case .explore:
            self.composer = nil
            await explore(composer.anchorID, intent: .explore)
        }
    }

    // MARK: First experience

    /// The initial text becomes part of the document, with a small structure
    /// around it. It is not a chat message.
    public func start(with statement: String) {
        let text = statement.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        var builder = DocumentBuilder(document: KollioDocument())
        let context = builder.object("context", kind: .context, text, en: text, at: Position(x: 0, y: 0))!
        let a = builder.object("direction-a", kind: .hypothesis, L10n.seedDirectionA, en: L10n.seedDirectionAEN, at: Position(x: -250, y: 210))!
        let b = builder.object("direction-b", kind: .hypothesis, L10n.seedDirectionB, en: L10n.seedDirectionBEN, at: Position(x: 250, y: 210))!
        builder.link("seed-a", from: context, to: a, .alternativeTo)
        builder.link("seed-b", from: context, to: b, .alternativeTo)
        session = KollioSession(document: builder.document)
        selection = [context]
        fitContent()
    }

    public var isEmpty: Bool { document.content.isEmpty }

    /// Development aid for visual review: `KOLLIO_REVIEW=explore` opens the app
    /// with a proposal already on the canvas, so the ghost branch can be
    /// captured in a screenshot. Never used in a normal launch.
    public func prepareVisualStateForReview() async {
        let review = ProcessInfo.processInfo.environment["KOLLIO_REVIEW"]
        guard let review, !review.isEmpty else { return }
        let csv = KollioID.object("sarah-csv")
        switch review {
        case "explore", "kept":
            selection = [KollioID.object("sarah-crm")]
            await explore(KollioID.object("sarah-crm"))
            if review == "kept" { keepPreview() }
        case "setaside":
            setAside(csv, reason: reviewReason)
            selection = [csv]
        case "reopened":
            setAside(csv, reason: reviewReason)
            reopen(csv)
        default:
            break
        }
    }

    private var reviewReason: String {
        languageCode == "fr"
            ? "On garde cette direction pour plus tard, les accès API ne sont pas disponibles."
            : "Keeping this direction for later, the API access is not available."
    }

    // MARK: History and persistence

    public var canUndo: Bool { session.history.canUndo }
    public var canRedo: Bool { session.history.canRedo }

    public func undo() {
        if session.undo() {
            selection = selection.filter { document.object($0) != nil }
        }
    }

    public func redo() {
        if session.redo() {
            selection = selection.filter { document.object($0) != nil }
        }
    }

    @discardableResult
    public func save() -> Bool {
        do {
            try fileStore.save(document, to: documentURL)
            status = L10n.statusSaved
            return true
        } catch {
            status = L10n.errorSaveFailed
            return false
        }
    }

    /// Simulates the full cycle: save, close, reopen.
    public func reloadFromDisk() {
        guard let reloaded = try? fileStore.load(documentURL) else { return }
        session = KollioSession(document: reloaded)
        frames = [:]
        selection = []
        preview = nil
    }

    public func newDocument() {
        session = KollioSession(document: KollioDocument())
        frames = [:]
        selection = []
        preview = nil
        camera = .identity
    }

    public func loadDemo() {
        session = KollioSession(document: SarahFixture.document())
        frames = [:]
        selection = []
        preview = nil
        fitContent()
    }
}
