import Foundation
import Testing
@testable import KollioCore

/// Shared fixture: a tiny Sarah-like graph. Deliberately small: a context, two
/// alternative directions, one blocking constraint and one open question.
enum Fixture {
    static func sarah() -> KollioDocument {
        var builder = DocumentBuilder()
        let context = builder.object(
            "sarah-context", kind: .context,
            "Récupérer la liste des prospects sans dépendre du CRM",
            en: "Recover the prospect list without depending on the CRM",
            at: Position(x: 0, y: 0)
        )!
        let crm = builder.object(
            "sarah-crm", kind: .hypothesis,
            "Connexion directe au CRM",
            en: "Direct CRM connection",
            detail: "Lecture de la liste des prospects depuis l’API du CRM",
            detailEN: "Reading the prospect list straight from the CRM API",
            at: Position(x: -240, y: 200)
        )!
        let csv = builder.object(
            "sarah-csv", kind: .hypothesis,
            "Export CSV depuis l’outil source",
            en: "CSV export from the source tool",
            detail: "L’export est déjà disponible dans l’outil source",
            detailEN: "The export is already available in the source tool",
            at: Position(x: 240, y: 200)
        )!
        let blocked = builder.object(
            "sarah-blocked", kind: .constraint,
            "Identifiants API indisponibles",
            en: "API credentials unavailable",
            at: Position(x: -240, y: 380)
        )!
        let viable = builder.object(
            "sarah-viable", kind: .evidence,
            "Export disponible",
            en: "Export available",
            at: Position(x: 240, y: 380)
        )!
        let question = builder.object(
            "sarah-question", kind: .question,
            "Peut-on récupérer aussi les tags ?",
            en: "Can we recover the tags too?",
            at: Position(x: 240, y: 540)
        )!

        // One instance carries an explicit size, to prove size serializes too.
        var document = builder.document
        if let index = document.presentation.instances.firstIndex(where: { $0.objectID == csv }) {
            document.presentation.instances[index].size = Size(width: 260, height: 92)
        }
        builder = DocumentBuilder(document: document)

        builder.link("sarah-l1", from: context, to: crm, .alternativeTo)
        builder.link("sarah-l2", from: context, to: csv, .alternativeTo)
        builder.link("sarah-l3", from: crm, to: blocked, .constrains)
        builder.link("sarah-l4", from: csv, to: viable, .supports)
        builder.link("sarah-l5", from: csv, to: question, .addresses)
        return builder.document
    }
}
