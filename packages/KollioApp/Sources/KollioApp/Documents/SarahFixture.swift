import Foundation
import KollioCore

/// The demo scenario. Kept out of the domain engine: Sarah is a fixture that
/// demonstrates Kollio, not a rule inside it.
public enum SarahFixture {
    public static func document() -> KollioDocument {
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
            at: Position(x: -270, y: 210)
        )!
        let csv = builder.object(
            "sarah-csv", kind: .hypothesis,
            "Export CSV depuis l’outil source",
            en: "CSV export from the source tool",
            detail: "L’export est déjà disponible dans l’outil source",
            detailEN: "The export is already available in the source tool",
            at: Position(x: 270, y: 210)
        )!
        let blocked = builder.object(
            "sarah-blocked", kind: .constraint,
            "Identifiants API indisponibles",
            en: "API credentials unavailable",
            at: Position(x: -270, y: 400)
        )!
        let viable = builder.object(
            "sarah-viable", kind: .evidence,
            "Export disponible",
            en: "Export available",
            at: Position(x: 270, y: 400)
        )!
        let question = builder.object(
            "sarah-question", kind: .question,
            "Peut-on récupérer aussi les tags ?",
            en: "Can we recover the tags too?",
            at: Position(x: 600, y: 520)
        )!

        builder.link("sarah-l1", from: context, to: crm, .alternativeTo)
        builder.link("sarah-l2", from: context, to: csv, .alternativeTo)
        builder.link("sarah-l3", from: crm, to: blocked, .constrains,
                     label: "bloque", labelEN: "blocks")
        builder.link("sarah-l4", from: csv, to: viable, .supports,
                     label: "ouvre", labelEN: "enables")
        builder.link("sarah-l5", from: csv, to: question, .addresses)
        return builder.document
    }

    /// Authored expansions for the demo engine, keyed on what an object says.
    /// This is fixture content, not a Kollio rule.
    public static var authoredExpansions: [String: LocalDemoSuggestionService.Expansion] {
        let crmSignature = textSignature("Connexion directe au CRM", "Direct CRM connection")
        let csvSignature = textSignature("Export CSV depuis l’outil source", "CSV export from the source tool")
        return [
            crmSignature: LocalDemoSuggestionService.Expansion(
                summary: LocalizedText("Ce que l’accès direct exige", variants: ["en": "What direct access requires"]),
                rationale: LocalizedText(
                    "Sans identifiants API, cette direction dépend d’un accès que nous n’avons pas.",
                    variants: ["en": "Without API credentials, this direction depends on access we do not have."]
                ),
                steps: [
                    .init(
                        kind: .question,
                        text: LocalizedText("Qui peut demander les accès API ?", variants: ["en": "Who can request the API access?"]),
                        relation: .addresses,
                        offsetX: 0,
                        offsetY: 170
                    ),
                    .init(
                        kind: .constraint,
                        text: LocalizedText("Identifiants API indisponibles", variants: ["en": "API credentials unavailable"]),
                        relation: .constrains,
                        offsetX: 0,
                        offsetY: 320
                    )
                ]
            ),
            csvSignature: LocalDemoSuggestionService.Expansion(
                summary: LocalizedText("Ce que l’export permet déjà", variants: ["en": "What the export already allows"]),
                rationale: LocalizedText(
                    "L’export disponible permet d’éviter la dépendance au CRM.",
                    variants: ["en": "The available export removes the CRM dependency."]
                ),
                steps: [
                    .init(
                        kind: .evidence,
                        text: LocalizedText("L’export CSV est disponible aujourd’hui", variants: ["en": "The CSV export is available today"]),
                        relation: .supports,
                        offsetX: -180,
                        offsetY: 170
                    ),
                    .init(
                        kind: .method,
                        text: LocalizedText("Reconstruire la liste depuis le CSV", variants: ["en": "Rebuild the list from the CSV"]),
                        relation: .uses,
                        offsetX: 180,
                        offsetY: 170
                    ),
                    .init(
                        kind: .question,
                        text: LocalizedText("Et les tags dans ce cas ?", variants: ["en": "What about the tags in that case?"]),
                        relation: .addresses,
                        offsetX: 0,
                        offsetY: 340
                    )
                ]
            )
        ]
    }

    /// Authored content is keyed on what the object says, in both languages.
    static func textSignature(_ fr: String, _ en: String) -> String {
        DemoContent.textSignature(
            for: ContentObject(
                id: ObjectID("authored-probe"),
                kind: .hypothesis,
                text: LocalizedText(fr, variants: ["en": en]),
                provenance: .human("fixture")
            )
        )
    }
}
