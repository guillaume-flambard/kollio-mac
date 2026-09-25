import Foundation

/// Local editing history (Cmd+Z).
///
/// This is *not* project memory. A decision recorded in the document survives
/// closing the app; an undone edit does not. `UndoHistory` therefore holds
/// document snapshots, and each entry carries a label for the menu.
public struct UndoHistory: Sendable {
    public struct Entry: Sendable {
        public var label: String
        public var documentBefore: KollioDocument
        public var documentAfter: KollioDocument
    }

    public private(set) var entries: [Entry] = []
    public private(set) var cursor: Int = 0
    public var limit: Int

    public init(limit: Int = 100) {
        self.limit = limit
    }

    public var canUndo: Bool { cursor > 0 }
    public var canRedo: Bool { cursor < entries.count }

    public var undoLabel: String? { canUndo ? entries[cursor - 1].label : nil }
    public var redoLabel: String? { canRedo ? entries[cursor].label : nil }

    public mutating func record(label: String, before: KollioDocument, after: KollioDocument) {
        // A new action after an undo discards the redo tail.
        if cursor < entries.count {
            entries.removeSubrange(cursor..<entries.count)
        }
        guard before != after else { return }
        entries.append(Entry(label: label, documentBefore: before, documentAfter: after))
        if entries.count > limit {
            entries.removeFirst(entries.count - limit)
        }
        cursor = entries.count
    }

    public mutating func undo(current: KollioDocument) -> KollioDocument? {
        guard canUndo else { return nil }
        cursor -= 1
        return entries[cursor].documentBefore
    }

    public mutating func redo(current: KollioDocument) -> KollioDocument? {
        guard canRedo else { return nil }
        let document = entries[cursor].documentAfter
        cursor += 1
        return document
    }

    public mutating func reset() {
        entries.removeAll()
        cursor = 0
    }
}

/// Applies commands, records undo entries, and keeps the document consistent.
///
/// This is the seam the app binds to. Views never mutate the document directly.
public struct KollioSession: Sendable {
    public private(set) var store: DocumentStore
    public private(set) var history: UndoHistory
    public private(set) var lastError: DocumentError?

    public init(document: KollioDocument = KollioDocument()) {
        self.store = DocumentStore(document: document)
        self.history = UndoHistory()
    }

    public var document: KollioDocument { store.document }
    public var semanticRevision: Int { store.semanticRevision }

    @discardableResult
    public mutating func apply(_ commands: [Command], label: String, at date: Date = Date()) -> Bool {
        let before = store.document
        do {
            try store.apply(commands, at: date)
            history.record(label: label, before: before, after: store.document)
            lastError = nil
            return true
        } catch let error as DocumentError {
            lastError = error
            return false
        } catch {
            lastError = .forbiddenOperation(String(describing: error))
            return false
        }
    }

    @discardableResult
    public mutating func undo() -> Bool {
        guard let document = history.undo(current: store.document) else { return false }
        store.replace(with: document)
        return true
    }

    @discardableResult
    public mutating func redo() -> Bool {
        guard let document = history.redo(current: store.document) else { return false }
        store.replace(with: document)
        return true
    }
}
