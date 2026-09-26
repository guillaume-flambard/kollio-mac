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

    /// The document a launch should open.
    ///
    /// The default file when it exists, and otherwise the most recently written
    /// document in the directory. This is what makes "a new document gets its
    /// own file" work across launches: the previous document stays on disk and
    /// is not overwritten, and the newest one is the one that was being worked
    /// on.
    public var mostRecentDocumentURL: URL? {
        if FileManager.default.fileExists(atPath: defaultDocumentURL.path) {
            return defaultDocumentURL
        }
        let candidates = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ))?.filter { $0.pathExtension == DocumentCodec.fileExtension } ?? []
        return candidates.max { lhs, rhs in
            let left = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            let right = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            return left < right
        }
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
        case edit
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
    /// How far a streaming answer has got. It is display only: a progress carries
    /// no identifier and cannot be kept, so it is never a preview and never
    /// reaches the command system. It is cleared the moment the request ends,
    /// whatever the outcome.
    public var progress: ProposalProgress?
    public var status: String?
    public var composer: ComposerState?
    public var languageCode: String = KollioModel.systemLanguage
    public var documentURL: URL
    /// Set when a stored document existed but could not be read. The canvas shows
    /// the problem instead of quietly loading something else, and the unreadable
    /// file is never written over.
    public private(set) var loadFailure: (any Error)?

    /// The intelligence source. Offline and deterministic by default; the
    /// backend adapter is interchangeable.
    public var service: any SuggestionService

    /// What the app is really talking to, so the status line can say so without
    /// a control panel.
    public private(set) var serviceMode: ServiceConfiguration = .demo

    public let fileStore: DocumentFileStore

    public struct ComposerState: Equatable, Identifiable {
        public var id = UUID()
        /// The object the input is attached to.
        public var anchorID: ObjectID
        public var text: String = ""
        public var intent: Intent = .add
        /// The object's version when this draft was opened, for an edit.
        ///
        /// CAN-04: a conflict "shows my version and the current one, and never
        /// closes the input without recovery". Remembering what the person was
        /// looking at is what lets the interface say so instead of overwriting.
        public var baseVersion: Int?
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
        languageCode: String = KollioModel.systemLanguage,
        mode: ServiceConfiguration? = nil
    ) {
        self.fileStore = fileStore
        self.languageCode = languageCode
        // A launch opens the default file when there is one, and otherwise the
        // document that was written most recently.
        let url = fileStore.mostRecentDocumentURL ?? fileStore.defaultDocumentURL
        self.documentURL = url
        if let service {
            // An explicit service, as the tests use.
            self.service = service
            self.serviceMode = mode ?? .demo
        } else {
            // The source the environment actually configured, resolved once.
            let resolved = KollioModel.makeConfiguredService(languageCode: languageCode)
            self.service = resolved.service
            self.serviceMode = resolved.mode
        }
        if let document {
            // Explicit document, as the tests and the demo use.
            self.session = KollioSession(document: document)
            self.loadFailure = nil
        } else if FileManager.default.fileExists(atPath: url.path) {
            // A document exists. If it cannot be read, that is reported and the
            // file is left alone: overwriting it with a demo would destroy work
            // the user could still recover by hand.
            do {
                self.session = KollioSession(document: try fileStore.load(url))
                self.loadFailure = nil
            } catch {
                self.session = KollioSession(document: KollioDocument())
                self.loadFailure = error
            }
        } else {
            // Nothing stored: the first experience, and no fixture.
            self.session = KollioSession(document: KollioDocument())
            self.loadFailure = nil
        }
    }

    static func makeDemoService(languageCode: String) -> LocalDemoSuggestionService {
        LocalDemoSuggestionService(context: .init(
            language: languageCode,
            authored: SarahFixture.authoredExpansions
        ))
    }

    /// The model a normal launch gets. Separate from `init` so the default
    /// arguments used by tests stay deterministic.
    public static func makeAppModel() -> KollioModel {
        KollioModel()
    }

    /// A model pinned to the deterministic engine, for tests and previews.
    ///
    /// The deterministic suite must never depend on whether the Mac it runs on
    /// has a usable on-device model, and must never make a real generation. Every
    /// test that needs a service asks for this one explicitly rather than
    /// inheriting the launch default.
    public static func deterministicModel(
        document: KollioDocument? = nil,
        fileStore: DocumentFileStore = DocumentFileStore(directory: URL(fileURLWithPath: NSTemporaryDirectory()))
    ) -> KollioModel {
        KollioModel(
            document: document,
            service: makeDemoService(languageCode: "fr"),
            fileStore: fileStore,
            mode: .demo
        )
    }

    /// What the app says about on-device intelligence right now, and nothing
    /// more. The status line uses this; no panel is added to the canvas.
    public var appleAvailability: AppleModelAvailability? {
        (service as? AppleLocalSuggestionService)?.availability
    }

    /// Builds the service the environment asks for, and records what was really
    /// chosen. A server that cannot be reached is reported as an error, never
    /// quietly replaced by the demo engine, and an unavailable on-device model is
    /// reported as a refusal, never quietly replaced either.
    public static func makeConfiguredService(
        languageCode: String,
        configuration: ServiceConfiguration = ServiceConfiguration.fromEnvironment().configuration,
        token: String? = nil
    ) -> (service: any SuggestionService, mode: ServiceConfiguration) {
        switch configuration {
        case .apple:
            return (AppleLocalSuggestionService(), .apple)
        case .demo:
            return (makeDemoService(languageCode: languageCode), .demo)
        case .server(let baseURL):
            guard let token, token.isEmpty == false else {
                return (makeDemoService(languageCode: languageCode), .demo)
            }
            return (RemoteSuggestionService(baseURL: baseURL, token: token), configuration)
        }
    }

    // MARK: Document access

    public var document: KollioDocument { session.document }

    /// How a chosen file is read. Injectable so a test can hand over a file it made
    /// itself rather than reaching for the user's disk.
    public var sourceReader = SourceReader()

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

    /// Drops from the selection any object that is no longer in the document.
    ///
    /// CAN-02: an object removed elsewhere "clears the selection and explains if
    /// an edit was active, and never selects something else." Pruning is the only
    /// place that rule lives, so undo, redo and a remote change all obey it.
    public func pruneSelection() {
        selection = selection.filter { document.object($0) != nil }
    }

    /// The transient surfaces that Escape can close, in the order a person leaves
    /// them: the deepest open thing first, the selection last.
    ///
    /// CAN-02 AC03: "Escape closes one level, then the selection." Closing
    /// everything at once is a different behaviour, and a worse one — a person who
    /// meant to dismiss a draft loses the selection they had built up.
    public enum TransientLevel: Equatable {
        case composer
        case claimDraft
        case stanceDraft
        case citation
        case readingSource
        case preview
        case selection

        /// The level Escape would close right now, or nil when there is nothing
        /// transient left. A drag owns the pointer, so it is not dismissible here.
        @MainActor
        public static func topmost(in model: KollioModel) -> TransientLevel? {
            if model.composer != nil { return .composer }
            if model.claimDraft != nil { return .claimDraft }
            if model.stanceDraft != nil { return .stanceDraft }
            if model.openCitationClaim != nil { return .citation }
            if model.readingSourceID != nil { return .readingSource }
            if model.preview != nil { return .preview }
            if !model.selection.isEmpty { return .selection }
            return nil
        }
    }

    /// Closes exactly one level. Returns the level it closed, so a caller can
    /// report it and a test can assert it.
    @discardableResult
    public func dismissOneLevel() -> TransientLevel? {
        switch TransientLevel.topmost(in: self) {
        case .composer:
            // A closed composer keeps its draft; the draft belongs to the target,
            // not to the surface.
            composer = nil
            return .composer
        case .claimDraft:
            claimDraft = nil
            return .claimDraft
        case .stanceDraft:
            stanceDraft = nil
            return .stanceDraft
        case .citation:
            openCitationClaim = nil
            return .citation
        case .readingSource:
            readingSourceID = nil
            return .readingSource
        case .preview:
            // Closing a proposal hides it. It is not a rejection and not a
            // deletion: nothing was applied and nothing is forgotten.
            preview = nil
            return .preview
        case .selection:
            selection = []
            return .selection
        case .none:
            return nil
        }
    }

    /// Used when a document is closed or reset, where there is no level to
    /// preserve.
    public func clearContextualState() {
        selection = []
        preview = nil
        composer = nil
    }

    /// The actions offered for a selected object: at most three shown, the rest
    /// behind one named control.
    ///
    /// The set is a model fact so that `ContextualActionSet.maximumPrimary` can be
    /// checked by a test rather than trusted to a `HStack`.
    public func contextualActions(for id: ObjectID) -> ContextualActionSet {
        let object = document.object(id)
        return ContextualActionSet.forObject(
            id: id,
            kind: object?.kind ?? .need,
            canReopen: canReopen(id),
            canAttachSource: object != nil,
            canAssertClaim: object != nil
        )
    }

    // MARK: Direct manipulation

    /// Live drag state. The document is not touched while the pointer moves: the
    /// offset is applied visually, and one single transaction is committed on
    /// release.
    ///
    /// `ids` is a set, not one id, because CAN-03 moves a *group*: the chosen
    /// instances keep their relative positions and undo restores them together.
    public struct DragState: Equatable {
        /// The instance under the pointer. It is the anchor of the gesture and the
        /// one that decides whether an update belongs to this drag.
        public var anchor: InstanceID
        /// Every instance that follows the pointer. Order is not significant; the
        /// relative positions are preserved by applying the same delta to each.
        public var ids: Set<InstanceID>
        public var worldDelta: Position
    }

    public var dragState: DragState?

    /// The live offset for one instance. Addressing an instance rather than an
    /// object is what lets two occurrences of the same object move independently.
    public func dragOffset(forInstance instanceID: InstanceID) -> Position {
        guard let dragState, dragState.ids.contains(instanceID) else { return .zero }
        return dragState.worldDelta
    }

    /// The live offset of the first instance of an object, which is what a canvas
    /// that has not resolved instances yet needs.
    public func dragOffset(for objectID: ObjectID) -> Position {
        guard let instance = document.presentation.instance(for: objectID) else { return .zero }
        return dragOffset(forInstance: instance.id)
    }

    public func isDragging(_ instanceID: InstanceID) -> Bool {
        dragState?.ids.contains(instanceID) ?? false
    }

    public func beginDrag(_ id: ObjectID, screenTranslation: CGSize) {
        guard let instance = document.presentation.instance(for: id) else { return }
        beginDrag([instance.id], screenTranslation: screenTranslation)
    }

    /// Starts a group drag.
    ///
    /// The caller passes the instances that should follow the pointer. The canvas
    /// resolves the selection to instances before calling, because a selection is
    /// a set of *objects* and a move is a set of *places*.
    public func beginDrag(_ instanceIDs: [InstanceID], screenTranslation: CGSize) {
        guard let anchor = instanceIDs.first else { return }

        // A gesture reports the cumulative translation from its start, so an
        // update for the same anchor replaces the delta instead of being ignored.
        // A different anchor is a different gesture and is refused rather than
        // merging two gestures into one delta.
        if let dragState, dragState.anchor != anchor { return }

        dragState = DragState(
            anchor: anchor,
            ids: Set(instanceIDs),
            worldDelta: camera.worldDelta(forScreenDelta: Position(x: screenTranslation.width, y: screenTranslation.height))
        )
    }

    /// The instances a drag on this object should move: its own, plus the other
    /// selected objects' first instance when the object is part of a multi-selection.
    ///
    /// An unselected object dragged while something else is selected moves alone.
    /// That is the difference between "move what I picked" and "move what I
    /// happened to touch", and only the first is what a person means.
    public func draggableInstances(for id: ObjectID) -> [InstanceID] {
        guard let instance = document.presentation.instance(for: id) else { return [] }
        guard selection.contains(id), selection.count > 1 else { return [instance.id] }
        return selection
            .compactMap { document.presentation.instance(for: $0)?.id }
    }

    /// One transaction, one undo entry, whatever the path the objects took.
    public func endDrag() {
        guard let dragState else { return }
        self.dragState = nil
        let delta = dragState.worldDelta
        guard abs(delta.x) > 0.5 || abs(delta.y) > 0.5 else { return }
        moveInstances(dragState.ids, by: delta)
    }

    /// Cancels the gesture without writing. CAN-03: "cancelling mid-gesture
    /// restores all positions."
    public func cancelDrag() {
        dragState = nil
    }

    /// Moves several instances in one transaction, so one undo restores the group.
    ///
    /// CAN-03 AC02. The domain already accepts a list of moves; this is where a
    /// group drag stops being a set of single drags. Addressing by instance is
    /// what keeps two occurrences of one object independent.
    public func moveInstances(_ instanceIDs: Set<InstanceID>, by delta: Position) {
        let moves = instanceIDs.compactMap { id -> MoveNodeInstance? in
            guard let instance = document.presentation.instance(id: id) else { return nil }
            return MoveNodeInstance(
                instanceID: instance.id,
                position: instance.position.offset(dx: delta.x, dy: delta.y)
            )
        }
        guard moves.isEmpty == false else { return }
        session.apply(
            [.moveNodeInstances(MoveNodeInstances(moves: moves))],
            label: L10n.undoMove
        )
    }

    /// Convenience for a whole object, used by the tests and by any call site that
    /// genuinely means "everywhere this object is drawn".
    public func moveObject(_ id: ObjectID, by delta: Position) {
        moveInstances(
            Set(document.presentation.instances(of: id).map(\.id)),
            by: delta
        )
    }


    // MARK: Commands

    /// The one way anything changes the document from outside.
    ///
    /// Views call this rather than mutating anything: the transaction, the undo
    /// entry and the error handling all live here, so there is one path to get right
    /// rather than one per call site. A refused command changes nothing and says
    /// so, because a command that half-applied would be a corrupted document.
    @discardableResult
    public func perform(_ commands: [Command], label: String) -> Bool {
        guard commands.isEmpty == false else { return true }
        guard session.apply(commands, label: label) else {
            status = L10n.errorGeneric
            return false
        }
        return true
    }

    // MARK: Create, duplicate, remove

    /// Writes an idea down, without asking what kind of idea it is.
    ///
    /// CAN-05: "Create an idea without choosing a category, then clarify its
    /// meaning." This is local and immediate. It does not call a model, because a
    /// person who already knows what they want to say should never wait on a network
    /// to say it, and a model cannot be assumed to be there (invariant 7). The
    /// object is created as `.unclear` and its meaning is settled later, by editing
    /// it or by exploring from it.
    @discardableResult
    public func createIdea(
        _ text: String,
        near anchor: ObjectID?,
        at position: Position? = nil
    ) -> ObjectID? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let id = ObjectID("object:" + UUID().uuidString)
        // The creation point is previewed at the anchor when there is one, and
        // offset from it so the new idea does not land exactly on the thing it was
        // written next to.
        let place = position
            ?? anchor.flatMap { document.presentation.instance(for: $0)?.position.offset(dx: 0, dy: 180) }
            ?? .zero
        let create = CreateObject(
            id: id,
            kind: .unclear,
            text: LocalizedText(trimmed),
            position: place,
            provenance: .human("local-user")
        )
        guard perform([.createObject(create)], label: L10n.undoCreate) else { return nil }
        select(id)
        return id
    }

    /// A second drawing of the same idea, in another place.
    ///
    /// This is the operation people mean most of the time by "duplicate", and it is
    /// the one that must not touch meaning: no new object, no new author, no second
    /// share. Offsets by a visible step so the copy is not hidden under the
    /// original.
    @discardableResult
    public func duplicateOccurrence(of instanceID: InstanceID) -> InstanceID? {
        guard document.presentation.instance(id: instanceID) != nil else { return nil }
        let newID = InstanceID("instance:" + UUID().uuidString)
        let source = document.presentation.instance(id: instanceID)
        let command = Command.duplicateNodeInstance(
            DuplicateNodeInstance(
                instanceID: instanceID,
                id: newID,
                position: source?.position.offset(dx: 40, dy: 40)
            )
        )
        guard perform([command], label: L10n.undoDuplicateOccurrence) else { return nil }
        return newID
    }

    /// The same thought said again as a new idea, related to the original.
    ///
    /// A variant can be changed without changing what it came from, which is the
    /// reason it is a new object and not a second occurrence. The link is
    /// `derivedFrom`, so the document can still answer "why is this here".
    @discardableResult
    public func duplicateAsVariant(of id: ObjectID) -> ObjectID? {
        guard document.object(id) != nil else { return nil }
        let newObject = ObjectID("object:" + UUID().uuidString)
        let command = Command.duplicateObject(
            DuplicateObject(
                sourceID: id,
                id: newObject,
                instanceID: InstanceID("instance:" + UUID().uuidString),
                relationshipID: RelationshipID("relationship:" + UUID().uuidString),
                position: document.presentation.instance(for: id)?.position.offset(dx: 40, dy: 40),
                provenance: .human("local-user")
            )
        )
        guard perform([command], label: L10n.undoDuplicateVariant) else { return nil }
        select(newObject)
        return newObject
    }

    /// Takes one drawing off the canvas and keeps the idea.
    @discardableResult
    public func removeOccurrence(_ instanceID: InstanceID) -> Bool {
        perform(
            [.removeNodeInstance(RemoveNodeInstance(instanceID: instanceID))],
            label: L10n.undoRemoveOccurrence
        )
    }

    /// Removes the idea from the document.
    ///
    /// Deliberately a separate call from `removeOccurrence`, with its own label, so
    /// the two are never the same gesture. The interface asks for a confirmation
    /// here and not there, because this one loses the thinking and that one does
    /// not.
    @discardableResult
    public func removeFromDocument(_ id: ObjectID) -> Bool {
        perform([.removeObject(RemoveObject(id: id))], label: L10n.undoRemoveObject)
    }

    /// An object waiting for the person to answer the one question the two removals
    /// share: does this keep the idea or remove it.
    ///
    /// The two are never the same gesture and never the same button, but they are
    /// also never both applied on a first click. This is that moment, held in the
    /// model so the view does not have to hold a destructive intent of its own.
    public var pendingRemoval: ObjectID?

    public func requestRemoveFromDocument(_ id: ObjectID) {
        guard document.object(id) != nil else { return }
        pendingRemoval = id
    }

    /// Answers the pending question, either way. Cancelling is a first-class answer
    /// and leaves the document untouched.
    public func resolvePendingRemoval(keepingIdea: Bool) {
        guard let id = pendingRemoval else { return }
        pendingRemoval = nil
        if keepingIdea {
            if let instance = document.presentation.instance(for: id) {
                _ = removeOccurrence(instance.id)
            }
        } else {
            _ = removeFromDocument(id)
        }
    }

    // MARK: Adding information at a precise place

    /// Writes the sentence down, linked to the thing it is about.
    ///
    /// CTX-01: "The sentence becomes an authored note linked to the target" and
    /// "`CreateObject` plus `associatedWith` in one transaction." The whole point is
    /// that this is *local*. What the person typed is already theirs and already
    /// true, so it is stored before anything is asked of a model, and asking is a
    /// separate later action. If that later action fails, this is still here.
    ///
    /// A note rather than a hypothesis on purpose: the person has not decided what
    /// this sentence *is*, only that it belongs next to that object. "No ontology
    /// knowledge required" is the requirement, and requiring a kind here would put
    /// the burden back on the person.
    @discardableResult
    public func addNote(_ sentence: String, to anchor: ObjectID) -> ObjectID? {
        guard document.object(anchor) != nil else { return nil }
        // What is stored is what was typed, minus the whitespace at the ends and
        // nothing else. The folded form exists only to compare two submissions, and
        // storing it would quietly rewrite the person's sentence, which is the one
        // thing this project never does.
        let authored = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let folded = normalise(authored) else { return nil }

        // A double submission is deduplicated. Pressing the key twice is a fact
        // about the person, not two pieces of information, and two identical notes
        // would read as corroboration that nobody provided.
        if let existing = existingNote(matching: folded, at: anchor) {
            select(existing)
            return existing
        }

        let noteID = ObjectID("object:" + UUID().uuidString)
        let commands: [Command] = [
            .createObject(CreateObject(
                id: noteID,
                kind: .note,
                text: LocalizedText(authored),
                position: document.presentation.instance(for: anchor)?.position
                    .offset(dx: 0, dy: 180),
                provenance: .human("local-user")
            )),
            .addRelationship(AddRelationship(
                id: RelationshipID("relationship:" + UUID().uuidString),
                from: noteID,
                to: anchor,
                kind: .associatedWith,
                provenance: .human("local-user")
            ))
        ]
        // One transaction: a note with no link, or a link to a note that was never
        // written, are both states nobody asked for.
        guard perform(commands, label: L10n.undoAddNote) else { return nil }
        select(noteID)
        return noteID
    }

    /// The note already at this anchor with these words, if there is one.
    private func existingNote(matching sentence: String, at anchor: ObjectID) -> ObjectID? {
        let linked = document.relationships.values
            .filter { $0.kind == .associatedWith && $0.to == anchor }
            .map(\.from)
        return linked.first { id in
            guard let object = document.object(id), object.kind == .note else { return false }
            return normalise(object.text.text) == sentence
        }
    }

    /// Trims, and folds runs of whitespace, so that the same sentence typed with a
    /// stray line break is recognised as the same sentence.
    private func normalise(_ sentence: String) -> String? {
        let folded = sentence
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        return folded.isEmpty ? nil : folded
    }

    /// Asks what this note would change, which is a different question from having
    /// written it down.
    ///
    /// Kept apart from `addNote` so the two failures are separate: this one can time
    /// out, be refused, or find no intelligence, and none of that is a reason the
    /// sentence stops existing.
    public func revealConsequences(of note: ObjectID) async {
        await explore(note, intent: .explore)
    }

    /// The kinds intelligence may not choose on its own.
    ///
    /// CTX-01: "A type proposed by intelligence asks for confirmation when it
    /// changes the reasoning." A note states something; a hypothesis, a constraint or
    /// a piece of evidence each *argue* something, and the difference is the whole
    /// content of the document. So a proposal that would create anything other than a
    /// note is held until a person says yes.
    public static func kindNeedsConfirmation(_ kind: ContentObject.Kind) -> Bool {
        switch kind {
        case .note, .unclear:
            return false
        case .context, .need, .method, .technicalBlock, .product, .hypothesis,
             .constraint, .question, .evidence, .scenario, .decision, .contribution:
            return true
        }
    }

    /// A proposal waiting for a person to agree with the kind intelligence chose.
    public var pendingKindConfirmation: Proposal?

    /// Whether a proposal would change the reasoning rather than add a note, and so
    /// has to be confirmed before it is applied.
    public func kindConfirmation(for proposal: Proposal) -> [ObjectID] {
        proposal.operations.compactMap { operation in
            guard case .createObject(let create) = operation,
                  Self.kindNeedsConfirmation(create.kind) else { return nil }
            return create.id
        }
    }

    // MARK: Sources
    // MARK: Claims

    /// A claim being written, before it is stated.
    ///
    /// The scope is not typed: it is what the person has selected, or the object
    /// they are working on. A scope is the part people get wrong, and deriving it
    /// from a selection makes the narrow case the easy one and the sweeping case the
    /// deliberate one.
    public struct ClaimDraft: Equatable, Identifiable {
        public var id = UUID()
        public var anchor: ObjectID
        public var role: Claim.Role
        public var scopeObjects: Set<ObjectID>
        public var criterion: String = ""

        public init(anchor: ObjectID, role: Claim.Role, scopeObjects: Set<ObjectID>) {
            self.anchor = anchor
            self.role = role
            self.scopeObjects = scopeObjects
        }
    }

    public var claimDraft: ClaimDraft?

    /// Opens the claim composer for an object.
    ///
    /// With several objects selected, the claim is about all of them: a person
    /// selecting two branches and stating a constraint means "this applies to
    /// these", which is the scoped case and should not be the fiddly one.
    public func startClaim(role: Claim.Role, anchor: ObjectID) {
        let scope = selection.isEmpty ? [anchor] : Array(selection)
        claimDraft = ClaimDraft(anchor: anchor, role: role, scopeObjects: Set(scope))
    }

    /// States the drafted claim.
    ///
    /// Refused with a reason rather than stated loosely: a claim whose scope is
    /// empty would be a law of the universe, and the command layer refuses it too.
    @discardableResult
    public func submitClaim() -> Bool {
        guard let draft = claimDraft else { return false }
        guard draft.scopeObjects.isEmpty == false else {
            status = L10n.claimScopeEmpty
            return false
        }
        let claim = Claim(
            id: ClaimID("claim:" + UUID().uuidString),
            objectID: draft.anchor,
            role: draft.role,
            scope: ClaimScope(
                id: ScopeID("scope:" + UUID().uuidString),
                title: L10n.claimScopeTitle(default: object(draft.anchor)?.text.text ?? draft.anchor.rawValue),
                objectIDs: draft.scopeObjects
            ),
            criterion: draft.criterion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : draft.criterion
        )
        guard perform([.assertClaim(.init(
            claim: claim, provenance: .human("local-user")
        ))], label: L10n.undoAssertClaim) else { return false }
        claimDraft = nil
        return true
    }

    /// The claim made on an object, if there is one.
    public func claim(on objectID: ObjectID) -> Claim? {
        document.claims.allClaims().first { $0.objectID == objectID }
    }

    /// The two stances in one place, so a claim can be read at a glance.
    public func claimSummary(for objectID: ObjectID) -> ClaimSummary? {
        guard let claim = claim(on: objectID) else { return nil }
        return ClaimSummary(
            id: claim.id,
            role: claim.role,
            scopeCount: claim.scope.objectIDs.count,
            isAsserted: claim.isAsserted,
            hypothesis: claim.role == .hypothesis ? claim.assessment : nil,
            constraint: claim.role == .constraint ? claim.resolution : nil,
            criterion: claim.criterion
        )
    }

    /// Records a stance. Both cases need an observation, and neither one is
    /// reachable without one.
    @discardableResult
    public func recordStance(_ draft: StanceDraft) -> Bool {
        let trimmed = draft.observation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, let claim = claim(on: draft.anchor) else { return false }
        // The two evidence types are separate on purpose, so a hypothesis and a
        // constraint cannot end up sharing a verdict by accident.
        let by = ActorID("local-user")
        let now = Date()
        let command: Command
        switch claim.role {
        case .hypothesis:
            let assessment: HypothesisAssessment = switch draft.stance {
            case .supported: .supported(.init(observation: trimmed, by: by, at: now))
            case .contradicted: .contradicted(.init(observation: trimmed, by: by, at: now))
            case .refuted: .refuted(.init(observation: trimmed, by: by, at: now))
            case .satisfied, .notApplicable, .open: .open
            }
            command = .assessHypothesis(.init(
                claimID: claim.id, assessment: assessment, provenance: .human(by)
            ))
        case .constraint:
            let resolution: ConstraintResolution = switch draft.stance {
            case .satisfied: .satisfied(.init(observation: trimmed, by: by, at: now))
            case .notApplicable: .notApplicable(.init(observation: trimmed, by: by, at: now))
            case .supported, .contradicted, .refuted, .open: .open
            }
            command = .resolveConstraint(.init(
                claimID: claim.id, resolution: resolution, provenance: .human(by)
            ))
        }
        guard perform([command], label: L10n.undoRecordStance) else { return false }
        stanceDraft = nil
        return true
    }

    public struct StanceDraft: Equatable, Identifiable {
        public var id = UUID()
        public var anchor: ObjectID
        public var stance: Stance
        public var observation: String = ""

        public init(anchor: ObjectID, stance: Stance) {
            self.anchor = anchor
            self.stance = stance
        }
    }

    /// The stances a person can take, as one vocabulary for the interface.
    ///
    /// Which of them apply depends on the role, and the interface only offers the
    /// ones that do. A constraint cannot be "refuted" and a hypothesis cannot be
    /// "satisfied": those are the two mistakes this split exists to prevent.
    public enum Stance: String, CaseIterable, Identifiable {
        case supported
        case contradicted
        case refuted
        case satisfied
        case notApplicable
        case open

        public var id: String { rawValue }

        public static func applicable(to role: Claim.Role) -> [Stance] {
            switch role {
            case .hypothesis: [.open, .supported, .contradicted, .refuted]
            case .constraint: [.open, .satisfied, .notApplicable]
            }
        }
    }

    public var stanceDraft: StanceDraft?

    // MARK: Citations

    /// The system's reader, for a file too long to read as text on the canvas.
    ///
    /// Held by the model rather than by a view so that opening and closing it is
    /// one decision in one place, and so the same file cannot be opened twice from
    /// two different cards.
    @MainActor public let sourcePreview = SourcePreviewPanel()

    /// Opens the person's own file in the system reader, beside the canvas.
    public func openInReader(_ sourceID: SourceID) {
        guard let locator = document.sources.source(sourceID)?.locator,
              let url = URL(string: locator)
        else { return }
        sourcePreview.present(url)
    }

    /// A source open for reading, so a passage can be chosen from it.
    ///
    /// The text comes from the revision on record, never re-read from disk: what a
    /// person cites has to be the text the document believes it read.
    public var readingSourceID: SourceID?

    /// The lines of a source, addressable so a citation can point at one.
    public func lines(of sourceID: SourceID) -> [String] {
        guard let text = document.sources.source(sourceID)?.latest?.extraction.text else { return [] }
        return text.components(separatedBy: .newlines)
    }

    /// The source as a table, parsed from the text on record.
    ///
    /// Parsed from the revision rather than from the file on disk, for the same
    /// reason the lines are: what is shown has to be what the document believes it
    /// read. A file that changed underneath must not silently change a preview.
    public func table(for sourceID: SourceID) -> CSVTable? {
        guard let source = document.sources.source(sourceID),
              source.kind == .csv,
              let text = source.latest?.extraction.text,
              let parsed = try? CSVTable.parse(text)
        else { return nil }
        return parsed
    }

    /// Cites a passage of a source, from the revision currently on record.
    ///
    /// The quote is taken from the chosen lines rather than typed, because a quote
    /// that differs from the source is not a quote. The locator is the range that
    /// was actually chosen, so opening the citation later lands on the same lines.
    @discardableResult
    public func citePassage(
        of sourceID: SourceID,
        lines range: Range<Int>,
        to claim: ObjectID
    ) -> Bool {
        let all = lines(of: sourceID)
        guard range.lowerBound >= 0, range.upperBound <= all.count, range.lowerBound < range.upperBound,
              let revision = document.sources.source(sourceID)?.latest
        else { return false }
        let quote = all[range].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard quote.isEmpty == false else { return false }

        let citation = Citation(
            id: CitationID("citation:" + UUID().uuidString),
            claimID: claim,
            sourceID: sourceID,
            revisionID: revision.id,
            locator: SourceLocator(lineRange: range),
            quote: quote
        )
        guard perform([.addCitation(.init(
            citation: citation, claimID: claim, provenance: .human("local-user")
        ))], label: L10n.undoAddCitation) else { return false }
        readingSourceID = nil
        return true
    }

    /// The claim whose citations are open, and the one being checked.
    ///
    /// Transient, like the composer and the decision card: it appears where the
    /// person is working and goes away when they move on. There is no citations
    /// panel anywhere in the application, because a permanent home for evidence
    /// would be a permanent home for reading rather than for thinking.
    public var openCitationClaim: ObjectID?
    public var verifyingCitationID: CitationID?
    /// What the person is writing into the verification input. It lives on the model
    /// so a refused check does not lose the sentence.
    public var verificationDraft: String = ""

    /// The citations of a claim, in a stable order.
    public func citations(of objectID: ObjectID) -> [CitationDetail] {
        document.sources.citations(supporting: objectID).map { citation in
            let source = document.sources.source(citation.sourceID)
            let revision = source?.revision(citation.revisionID)
            return CitationDetail(
                citation: citation,
                sourceTitle: source?.title ?? citation.sourceID.rawValue,
                /// The text of the exact revision the citation was read against. Not
                /// the current one: a claim has to be re-checkable against what it
                /// was actually based on, which is the whole point of keeping the
                /// history.
                passage: Self.passage(in: revision?.extraction.text, at: citation.locator),
                state: SourceChipState(revision?.extraction ?? .notAttempted),
                isCurrentRevision: source?.latest?.id == citation.revisionID
            )
        }
    }

    /// The lines a locator points at, when the text is line-addressable.
    ///
    /// A page locator in a PDF has no line numbers, so the passage is nil and the
    /// interface shows the locator and the quote instead of pretending it opened
    /// something. Returning nil is the honest answer; a wrong slice would be worse.
    static func passage(in text: String?, at locator: SourceLocator) -> String? {
        guard let text, let range = locator.lineRange else { return nil }
        let lines = text.components(separatedBy: .newlines)
        guard range.lowerBound >= 0, range.upperBound <= lines.count, range.lowerBound < range.upperBound
        else { return nil }
        return lines[range].joined(separator: "\n")
    }

    public func toggleCitations(of objectID: ObjectID) {
        openCitationClaim = openCitationClaim == objectID ? nil : objectID
        verifyingCitationID = nil
    }

    /// Records that a person checked a citation, with what they saw.
    ///
    /// Refused when the observation is empty, because a check that says nothing is
    /// not a check. The draft is only cleared once the command has been accepted,
    /// so a refused verification keeps what was typed.
    @discardableResult
    public func recordVerification(
        _ citationID: CitationID,
        observation: String
    ) -> Bool {
        let trimmed = observation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return false }
        let command = Command.recordVerification(.init(
            citationID: citationID,
            observation: trimmed,
            author: ActorID("local-user")
        ))
        guard perform([command], label: L10n.undoRecordVerification) else { return false }
        verifyingCitationID = nil
        return true
    }


    /// Reads a file the person chose and attaches it, as one transaction.
    ///
    /// The read happens first and the two commands are applied together, so a file
    /// that cannot be read leaves nothing behind: no half-attached source, and no
    /// source pointing at a revision that was never recorded. What comes back is
    /// what was read, so a caller can say "no text in this file" instead of
    /// reporting a success.
    @discardableResult
    public func attachSource(
        at url: URL,
        to objectID: ObjectID
    ) -> SourceReader.Read? {
        guard object(objectID) != nil else {
            status = L10n.errorGeneric
            return nil
        }
        let read: SourceReader.Read
        do {
            read = try sourceReader.read(url: url)
        } catch {
            status = L10n.sourceReadFailed
            return nil
        }

        // A stable id from the content, so attaching the same file twice is a
        // recognisable duplicate rather than a second copy of the same source.
        let sourceID = SourceID("source:" + String(read.digest.prefix(16)))
        let revision = SourceRevision(
            id: SourceRevisionID("revision:" + String(read.digest.prefix(16))),
            sequence: (document.sources.source(sourceID)?.attempts.count ?? 0) + 1,
            extraction: read.extraction,
            digest: read.digest
        )
        let reference = SourceReference(
            id: sourceID,
            kind: read.kind,
            title: read.title,
            locator: read.locator,
            revisions: document.sources.source(sourceID)?.revisions ?? []
        )
        let provenance = Provenance.human(ActorID("local-user"))
        let commands: [Command] = document.sources.source(sourceID) == nil
            ? [.attachSource(.init(source: reference, attachedTo: objectID, provenance: provenance))]
            : []
        guard perform(commands + [.importSourceRevision(.init(
            sourceID: sourceID, revision: revision, provenance: provenance
        ))], label: L10n.undoAttachSource) else {
            return nil
        }
        return read
    }


    /// What a source chip says about one resource cited by an object.
    ///
    /// Read straight from the ledger and never cached: the chip is the document's
    /// own state, and a cached copy of it would be a second truth free to disagree.
    public func sourceChips(for objectID: ObjectID) -> [SourceChip] {
        let citations = document.sources.citations(supporting: objectID)
        guard citations.isEmpty == false else { return [] }

        // One chip per source, however many passages of it are cited.
        var order: [SourceID] = []
        var counts: [SourceID: Int] = [:]
        for citation in citations {
            if counts[citation.sourceID] == nil { order.append(citation.sourceID) }
            counts[citation.sourceID, default: 0] += 1
        }
        return order.compactMap { id in
            guard let source = document.sources.source(id) else { return nil }
            return SourceChip(
                id: id,
                title: source.title,
                state: SourceChipState(source.extraction),
                citations: counts[id] ?? 0
            )
        }
    }

    // MARK: Intelligence

    /// What a request about this target actually reads.
    ///
    /// AI-03: "Use the useful global context, the target, applicable constraints and
    /// directions already rejected." Those four are not the same list, and the last
    /// one is the one that is easy to leave out and the most expensive to leave out:
    /// without it, intelligence re-proposes what the person already turned down, and
    /// the rejection looks like it never happened.
    ///
    /// A rejected direction travels with the reason it was rejected for. "No budget
    /// for it" and "we tried this in March and it did not hold" are different
    /// instructions, and a bare list of dead ends reads to a generator as a ban
    /// rather than as reasoning.
    ///
    /// Reachable objects only: a constraint three branches away is not applicable to
    /// this target, and sending it would spend the context budget on noise.
    public func readSet(for target: ObjectID) -> [ProposalRequest.ContextItem] {
        // Keyed by id and emitted in a stable order, because an object can be reached
        // by more than one route: a constraint that is both a neighbour and a rejected
        // direction must arrive *once*, carrying the reason it was rejected for.
        // Collecting "first writer wins" lost that reason whenever the object happened
        // to be mentioned before the rejections were walked, which made the same
        // document produce two different read sets depending on iteration order.
        var items: [ObjectID: ProposalRequest.ContextItem] = [:]

        func mention(_ object: ContentObject) {
            guard items[object.id] == nil else { return }
            items[object.id] = ProposalRequest.ContextItem(
                objectID: object.id,
                kind: object.kind,
                text: object.text.text,
                lifecycle: object.lifecycle,
                reason: nil
            )
        }

        if let target = object(target) { mention(target) }

        // Everything within reach: what it links to directly, and one step beyond.
        // A constraint three branches away is not applicable to this target, and
        // sending it would spend the context budget on noise.
        let neighbours = directNeighbours(of: target)
        for id in neighbours { if let object = object(id) { mention(object) } }
        for id in neighbours.flatMap({ secondDegreeNeighbours(of: $0) }) where !neighbours.contains(id) {
            if let object = object(id) { mention(object) }
        }

        // The rejected directions, and the reason each was rejected for. This runs
        // last on purpose: it *upgrades* what is already there rather than skipping
        // it, because "this was refused, and here is why" is strictly more than
        // "this is nearby".
        for decision in activeSetAsideDecisions() {
            let reason = decision.rationale?.text
            for id in decision.branchObjectIDs + [decision.targetObjectID] {
                guard let object = object(id), object.isSetAside else { continue }
                items[id] = ProposalRequest.ContextItem(
                    objectID: object.id,
                    kind: object.kind,
                    text: object.text.text,
                    lifecycle: object.lifecycle,
                    reason: reason
                )
            }
        }

        // Sorted so the fingerprint, and anything else reading the set, does not
        // depend on how a dictionary happened to iterate.
        return items.keys.sorted { $0.rawValue < $1.rawValue }.compactMap { items[$0] }
    }

    private func directNeighbours(of id: ObjectID) -> [ObjectID] {
        var found: Set<ObjectID> = []
        for relationship in document.relationships.values {
            if relationship.from == id { found.insert(relationship.to) }
            if relationship.to == id { found.insert(relationship.from) }
        }
        return found.filter { $0 != id }
    }

    private func secondDegreeNeighbours(of id: ObjectID) -> [ObjectID] {
        directNeighbours(of: id).filter { $0 != id }
    }

    /// The set-aside decisions that still stand.
    ///
    /// A reopened direction is not a rejected one any more, and consulting it as
    /// though it were would be the model quietly undoing a decision the person made.
    private func activeSetAsideDecisions() -> [Decision] {
        document.decisions.values
            .filter { $0.kind == .setAside && $0.status == .active }
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }

    /// The stable signature of what a request read, sent as its precondition.
    public func readSetFingerprint(for target: ObjectID) -> String {
        ProposalRequest.fingerprint(of: readSet(for: target))
    }


    /// Asks the current source for a proposal and previews it as a ghost branch.
    ///
    /// `instruction` carries what the person actually typed. It is optional
    /// because a plain Explore has nothing to carry, and it is part of the
    /// request because a sentence that never leaves the composer is a sentence
    /// the application silently threw away.
    @discardableResult
    public func explore(
        _ id: ObjectID,
        intent: Intent = .explore,
        instruction: String? = nil
    ) async -> Bool {
        guard !isThinking else { return false }
        isThinking = true
        defer { isThinking = false }
        status = nil

        let trimmed = instruction?.trimmingCharacters(in: .whitespacesAndNewlines)
        // The exact sentence travels, not a paraphrase of it. AI-03 AC01 is about
        // transmission, and the words a person chose are the part that cannot be
        // reconstructed from the target alone.
        let context = readSet(for: id)
        let request = ProposalRequest(
            requestId: UUID().uuidString,
            documentId: document.documentId,
            baseSemanticRevision: session.semanticRevision,
            intent: intent == .explore ? .explore : .add,
            targetIds: [id],
            instruction: (trimmed?.isEmpty == false) ? trimmed : nil,
            contentLocale: languageCode,
            context: context,
            // The signature of what was just read, so a source can tell whether it is
            // answering against the same document it was given rather than a stale
            // understanding of it.
            preconditions: ProposalRequest.Preconditions(
                semanticRevision: session.semanticRevision,
                readSetFingerprint: ProposalRequest.fingerprint(of: context)
            )
        )
        do {
            let response: ProposalResponse
            if let streaming = service as? any StreamingSuggestionService {
                // A source that can stream is asked to stream. The answer is
                // identical; the only difference is that the person sees it
                // arriving instead of waiting on a spinner for seconds.
                response = try await streaming.stream(to: request, document: document) { [weak self] update in
                    Task { @MainActor in self?.progress = update }
                }
            } else {
                response = try await service.respond(to: request, document: document)
            }
            progress = nil
            handle(response, anchor: id)
            return true
        } catch is CancellationError {
            // A cancelled request publishes nothing. The draft and the context
            // stay exactly as they were, and no half-received answer is left on
            // screen pretending to be progress towards something.
            progress = nil
            return false
        } catch let error as AppleModelError {
            // The real reason, in the user's language, and no substitution: the
            // context is untouched and the demo engine is not quietly used.
            progress = nil
            status = error.errorDescription
            return false
        } catch {
            progress = nil
            status = L10n.errorGeneric
            return false
        }
    }

    /// The offline engine can be driven directly, with no request round-trip.
    public func handle(_ response: ProposalResponse, anchor: ObjectID) {
        switch response.status {
        case .noChange:
            // AI-03 AC03: "a new request offers to keep or hide the previous one
            // rather than erasing it." Nothing arrived, so nothing is taken away:
            // the proposal already on screen is still somebody's thinking and stays
            // there. Clearing it here used to destroy a pending branch because a
            // later question produced no answer.
            status = L10n.statusNoChange
        case .needsInput:
            composer = ComposerState(anchorID: anchor, intent: .add)
            status = response.questions.first?.resolve(languageCode: languageCode)
        case .proposed:
            guard let proposal = response.proposal else {
                status = L10n.statusNoChange
                return
            }
            // One working group per window, so the new one takes the stage, and the
            // previous one is *offered* rather than dropped. Whether the person
            // wants it is their answer to give, not a default.
            if let previous = preview {
                supersededProposal = previous
                keptProposals.append(previous)
            }
            preview = makePreview(proposal: proposal, anchor: anchor)
        }
    }

    /// Proposals that were on the canvas and are not any more, still readable.
    public private(set) var keptProposals: [ProposalPreview] = []

    /// The proposal a new request displaced, waiting for an answer about its fate.
    public var supersededProposal: ProposalPreview?

    /// Keeps the proposal a new request displaced. It stays readable rather than
    /// being restored to the canvas, because two branches from one target at once is
    /// not what the canvas is for.
    public func keepPreviousProposal() {
        supersededProposal = nil
    }

    /// Hides the proposal a new request displaced, and forgets it.
    ///
    /// Hiding is not deleting: the objects it would have created were never created,
    /// so nothing that anybody wrote is lost, and the history of what was proposed
    /// stays in the document's revision.
    public func hidePreviousProposal() {
        if let previous = supersededProposal {
            keptProposals.removeAll { $0.id == previous.id }
        }
        supersededProposal = nil
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
        // The camera is deliberately left alone. Collapsing a branch is a local
        // decision, and Cmd+0 stays the explicit way to reframe the view.
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
        // Reopening restores what was already there. It does not rearrange it,
        // and it does not move the view either.
    }

    // MARK: Inline input

    public func startComposer(anchor: ObjectID, intent: Intent = .add) {
        composer = ComposerState(anchorID: anchor, intent: intent)
    }

    /// Opens the composer pre-filled with the object's own text, so an edit
    /// starts from what is actually there rather than from nothing.
    public func startEditing(anchor: ObjectID) {
        guard let object = object(anchor) else { return }
        composer = ComposerState(
            anchorID: anchor,
            text: object.text.text,
            intent: .edit,
            baseVersion: object.objectVersion
        )
    }

    public func submitComposer() async {
        guard let composer else { return }
        let text = composer.text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch composer.intent {
        case .add:
            guard !text.isEmpty else { return }
            // CTX-01: Add is not a call that spends the sentence. It writes the note,
            // linked to the target, in one local transaction. Nothing is asked of a
            // model here, so there is nothing that can fail here, and the note is
            // already findable before the person asks to see the consequences.
            if addNote(text, to: composer.anchorID) != nil { self.composer = nil }
        case .setAside:
            self.composer = nil
            setAside(composer.anchorID, reason: text.isEmpty ? nil : text)
        case .explore:
            // AI-03: "A local instruction may be added." It used to be discarded
            // here, which meant a person who typed a steer and pressed the key had
            // it silently ignored. The draft is only closed once the request has
            // actually been made, so a refused send leaves the words in place.
            let sent = await explore(composer.anchorID, intent: .explore, instruction: text)
            if sent { self.composer = nil }
        case .edit:
            // An edit is a user's own contribution, not a request to a model,
            // so it goes through the command system and never asks anything.
            // The composer is *not* cleared before the write: a refusal has to
            // leave the person their text, and clearing first would throw it away
            // on the way to finding out it failed.
            let applied = applyEdit(
                to: composer.anchorID,
                text: text,
                expectedVersion: composer.baseVersion
            )
            if applied { self.composer = nil }
        }
    }

    /// Replaces the text of one object, keeping its identity.
    ///
    /// The full authored text is preserved: no summary replaces what was typed,
    /// no other object moves, and the object stays the same object. It is one
    /// transaction, so it undoes as one action.
    @discardableResult
    public func applyEdit(to id: ObjectID, text: String, expectedVersion: Int? = nil) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let object = object(id) else { return false }
        guard object.text.text != trimmed else { return true }
        let command = Command.updateObjectText(UpdateObjectText(
            id: id,
            text: LocalizedText(trimmed),
            provenance: .human("local-user"),
            expectedVersion: expectedVersion
        ))
        guard session.apply([command], label: L10n.undoEdit) else {
            // The refusal is about the text, not about the application, so it is
            // reported as such. The draft is still in the composer.
            status = L10n.errorEditConflict
            return false
        }
        return true
    }

    /// Whether the object moved on while this draft was open, so the interface can
    /// say so *before* the person presses the key rather than after.
    public func hasEditConflict(_ composer: ComposerState) -> Bool {
        guard composer.intent == .edit, let base = composer.baseVersion else { return false }
        guard let object = object(composer.anchorID) else { return true }
        return object.objectVersion != base
    }

    // MARK: First experience

    /// The first experience: the person's own words become the document's
    /// context object.
    ///
    /// There is no longer a pair of canned hypotheses behind it. The authored
    /// text is preserved exactly as written, the object is created through the
    /// command system so it has a stable identity and an undo entry, and the
    /// canvas shows it immediately. Asking for intelligence is a separate step
    /// that can fail without touching any of this.
    @discardableResult
    public func start(with statement: String) -> ObjectID? {
        let text = statement.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        // A fresh document, and a save target of its own: a new document must
        // never overwrite the previous one.
        var builder = DocumentBuilder(document: KollioDocument())
        guard let context = builder.object(
            "context", kind: .context, text, en: text, at: Position(x: 0, y: 0)
        ) else { return nil }
        session = KollioSession(document: builder.document)
        adoptNewSaveTarget()
        selection = [context]
        frames = [:]
        camera = Camera(zoom: 1, translation: Position(x: 40, y: 120))
        // Persisted before anything else can fail, so the words are safe even
        // if the intelligence source is unreachable.
        save()
        return context
    }

    /// Explores the authored context. Separate from `start(with:)` on purpose:
    /// a failure here must not cost the user their sentence.
    public func exploreInitialContext(_ id: ObjectID) async {
        await explore(id, intent: .explore)
    }

    /// A new document gets its own file, so saving it can never overwrite the
    /// document that was open before.
    private func adoptNewSaveTarget() {
        let name = "Kollio-\(Self.shortStamp())"
        documentURL = fileStore.url(named: name)
    }

    private static func shortStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // The short suffix keeps two documents created in the same second
        // distinct, which a bare timestamp would not.
        return "\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(4))"
    }

    public var isEmpty: Bool { document.content.isEmpty }

    /// A stored document could not be read. The user is told, and the file is
    /// left exactly as it is.
    public var hasUnreadableDocument: Bool { loadFailure != nil }

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
            pruneSelection()
        }
    }

    public func redo() {
        if session.redo() {
            pruneSelection()
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

    /// A new, empty document with its own save target. Reusing the previous
    /// document's file would destroy it on the first save.
    public func newDocument() {
        session = KollioSession(document: KollioDocument())
        frames = [:]
        selection = []
        preview = nil
        composer = nil
        loadFailure = nil
        camera = .identity
        adoptNewSaveTarget()
    }

    /// The Sarah scenario, always through an explicit action. It is never what a
    /// launch falls back to.
    public func loadDemo() {
        session = KollioSession(document: SarahFixture.document())
        frames = [:]
        selection = []
        preview = nil
        composer = nil
        loadFailure = nil
        adoptNewSaveTarget()
        fitContent()
    }
}


/// The state a source chip shows, taken from what the import actually achieved.
///
/// There is no "imported" state that flatters the app: a file with no text layer
/// says so, and a source nobody has read yet says that too.
public enum SourceChipState: Hashable, Sendable {
    case notRead
    case importing
    case ready
    case partial(String)
    case noText
    case unsupported
    case missing
    /// Cited, but the source has moved or gone: the claim stands, the check does not.
    case unverifiable

    public init(_ extraction: SourceReference.Extraction) {
        switch extraction {
        case .notAttempted: self = .notRead
        case .pending: self = .importing
        case .ready: self = .ready
        case .partial(_, let reason): self = .partial(reason)
        case .noText: self = .noText
        case .unsupported: self = .unsupported
        case .missing: self = .missing
        }
    }

    /// Spoken rather than shown, because a coloured dot tells a screen reader
    /// nothing at all.
    public var accessibilityDescription: String {
        switch self {
        case .notRead: return L10n.sourceStateNotRead
        case .importing: return L10n.sourceStateImporting
        case .ready: return L10n.sourceStateReady
        case .partial: return L10n.sourceStatePartial
        case .noText: return L10n.sourceStateNoText
        case .unsupported: return L10n.sourceStateUnsupported
        case .missing: return L10n.sourceStateMissing
        case .unverifiable: return L10n.sourceStateUnverifiable
        }
    }

    /// A chip is calm when nothing needs a person's attention.
    public var needsAttention: Bool {
        switch self {
        case .ready, .notRead, .importing: return false
        case .partial, .noText, .unsupported, .missing, .unverifiable: return true
        }
    }
}

public struct SourceChip: Hashable, Sendable, Identifiable {
    public var id: SourceID
    public var title: String
    public var state: SourceChipState
    public var citations: Int

    public init(id: SourceID, title: String, state: SourceChipState, citations: Int) {
        self.id = id
        self.title = title
        self.state = state
        self.citations = citations
    }
}


/// A citation, with everything the interface needs to show it honestly.
public struct CitationDetail: Identifiable, Hashable, Sendable {
    public var citation: Citation
    public var sourceTitle: String
    /// The lines the locator points at, or nil when it points at a page or the
    /// text is unavailable.
    public var passage: String?
    public var state: SourceChipState
    /// False when the source has moved on since this was cited, which is the case
    /// where re-reading matters most.
    public var isCurrentRevision: Bool

    public var id: CitationID { citation.id }

    public init(
        citation: Citation,
        sourceTitle: String,
        passage: String?,
        state: SourceChipState,
        isCurrentRevision: Bool
    ) {
        self.citation = citation
        self.sourceTitle = sourceTitle
        self.passage = passage
        self.state = state
        self.isCurrentRevision = isCurrentRevision
    }
}


/// A claim as the interface reads it: role, how much it covers, and how it stands.
public struct ClaimSummary: Identifiable, Hashable, Sendable {
    public var id: ClaimID
    public var role: Claim.Role
    public var scopeCount: Int
    public var isAsserted: Bool
    public var hypothesis: HypothesisAssessment?
    public var constraint: ConstraintResolution?
    public var criterion: String?

    public init(
        id: ClaimID,
        role: Claim.Role,
        scopeCount: Int,
        isAsserted: Bool,
        hypothesis: HypothesisAssessment?,
        constraint: ConstraintResolution?,
        criterion: String?
    ) {
        self.id = id
        self.role = role
        self.scopeCount = scopeCount
        self.isAsserted = isAsserted
        self.hypothesis = hypothesis
        self.constraint = constraint
        self.criterion = criterion
    }
}
