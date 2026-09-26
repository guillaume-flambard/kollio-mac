# 10 — Crosswalk : les 71 fonctions V2, openspec et le design

Ce document relie trois sources qui ne se parlent pas encore :

- `docs/specs/SPECIFICATIONS.md` — la spécification normative, 71 fonctions,
  169 critères d'acceptation ;
- `openspec/specs/*.md` — les capacités en présent, 41 exigences et 30
  scénarios ;
- `docs/design/*` — la direction design, 44 interactions IX, 8 storyboards SB,
  12 protocoles UX.

Il ne crée aucune exigence nouvelle. Il montre où la couverture existe, où elle
est mince, et quelles fonctions n'ont pas encore de contrat d'interface.

## Ce que la comparaison révèle

| Capacité | Fonctions | AC | Exigences | Scénarios | Interactions IX | Sans IX |
|---|---:|---:|---:|---:|---:|---:|
| canvas | 10 | 23 | 4 | 6 | 20 | 0 |
| collaboration | 13 | 34 | 5 | 2 | 18 | 0 |
| commerce | 3 | 6 | 3 | 0 | 3 | 0 |
| context | 7 | 16 | 4 | 4 | 10 | 0 |
| decisions | 6 | 14 | 4 | 2 | 9 | 0 |
| documents | 8 | 18 | 5 | 7 | 12 | 0 |
| ecosystem | 3 | 7 | 3 | 0 | 3 | 0 |
| intelligence | 12 | 29 | 7 | 7 | 22 | 0 |
| studio | 9 | 22 | 3 | 2 | 9 | 0 |

Trois constats, dans l'ordre de gravité.

**1. Le design n'est écrit nulle part comme exigence.** Les 44 contrats IX
décrivent le comportement observable d'une interaction, avec déclenchement,
mouvement, interruption et recette. Aucun n'existe dans `openspec/specs/`, qui ne
contient ni exigence de mouvement, ni contraste, ni annonce, ni cible tactile.
Une interaction peut donc être conforme au design et ne violer aucune exigence
openspec, et l'inverse est vrai aussi.

**2. Les capacités à Interaction reduced ont le moins de scénarios.**
`commerce` et `ecosystem` ont zéro scénario, alors qu'elles vendent et
transfèrent. `collaboration` a 13 fonctions, 34 critères et 2 scénarios. Les
critères d'acceptation existent dans la spécification, mais le scénario
scénarisé — la plus petite chose qu'un test puisse prouver — manque.

**3. Le sort de la vérification est uniforme.** 15 fonctions
`automatedVerified`, 1 `humanVerified`, 55 `specified`. Les 8 protocoles UX et
les 8 storyboards SB ne changent rien à ce compte : ils ne sont pas exécutés. Le
livre de recherche le dit lui-même, un statut humain ne s'obtient pas en écrivant
une fonction.

## Ce qui manque comme exigence, par famille

| Famille | Contrat de design non écrit en openspec | Fichiers design |
|---|---|---|
| CAN | Trois actions principales, barre de proximité, alternative au glisser, zone de capture d'une relation | `02`, `04`, `06` |
| CTX | États d'une source (importé, extrait partiellement, inaccessible), retour à l'ancre, citation liée à une version | `04` |
| AI | Trois familles de proposition (ajout, remplacement, portée), avant/après stable, statut obsolète, destination réelle affichée | `05` |
| DEC | Écarter et fermer distincts, réouverture sans modèle, mémoire de la raison | `05` |
| DOC | Enregistré localement distinct de synchronisé, erreur de sauvegarde persistante, mot de passe par commande secondaire | `04`, `05` |
| TEAM | Suivi volontaire, version effectivement lue avant acceptation, portée du partage avant envoi | `05` |
| STU, COM, EXT | Provenance et réutilisation, périmètre d'export, statut de simulation | `05` |

## Tableau des 71 fonctions

`AC` est le nombre de critères d'acceptation. `Statut` vient de
`openspec/specs/feature-catalog.json`, une vue générée. `Chap.` et `IX` viennent
de `docs/design/`.

| ID | Titre | Capacité | Lot | AC | Statut | Chap. | IX |
|---|---|---|---|---:|---|---|---|
| CAN-01 | Navigate with trackpad and mouse | canvas | L1 | 2 | automatedVerified | 11, 14, 20, 21, 23 | IX-10, IX-11, IX-12 |
| CAN-02 | Select and reach the actions | canvas | L1 | 2 | specified | 11, 14, 20, 21, 23 | IX-04, IX-05, IX-06, IX-21 |
| CAN-03 | Move one or several instances | canvas | L1 | 2 | specified | 11, 14, 20, 21, 23 | IX-09 |
| CAN-04 | Edit content in place | canvas | L1 | 2 | specified | 11, 14, 20, 21, 23 | IX-03, IX-07 |
| CAN-05 | Create, duplicate, remove | canvas | L1 | 2 | specified | 11, 14, 20, 21, 23 | IX-13 |
| CTX-01 | Add information at a precise place | context | L1 | 3 | specified | 15, 17, 22 | IX-02, IX-03, IX-13 |
| DOC-01 | First launch and restoration | documents | L1 | 2 | automatedVerified | 12, 13, 17 | IX-01 |
| DOC-02 | Enter a context and begin | documents | L1 | 2 | automatedVerified | 12, 13, 17 | IX-01, IX-02 |
| DOC-03 | New, open, multiple | documents | L1 | 2 | automatedVerified | 12, 13, 17 | IX-31 |
| DOC-04 | Save, recovery, close | documents | L1 | 2 | automatedVerified | 12, 13, 17 | IX-27, IX-32 |
| AI-01 | Availability and choice of intelligence | intelligence | L2 | 3 | automatedVerified | 13, 15, 16, 20 | IX-17 |
| AI-02 | First exploration of your own context | intelligence | L2 | 2 | humanVerified | 13, 15, 16, 20 | IX-17, IX-18 |
| AI-03 | Explore a branch | intelligence | L2 | 2 | specified | 13, 15, 16, 20 | IX-17, IX-18 |
| AI-04 | Answer a clarification | intelligence | L2 | 2 | specified | 13, 15, 16, 20 | IX-03 |
| AI-07 | Examine and correct a proposal | intelligence | L2 | 3 | automatedVerified | 13, 15, 16, 20 | IX-18, IX-19, IX-24, IX-25 |
| AI-08 | Keep, set aside, or dismiss | intelligence | L2 | 3 | automatedVerified | 13, 15, 16, 20 | IX-20, IX-21, IX-22 |
| AI-09 | Cancel, retry, understand errors | intelligence | L2 | 3 | specified | 13, 15, 16, 20 | IX-17, IX-25, IX-26, IX-27 |
| CAN-08 | Place proposals and organise locally | canvas | L2 | 3 | specified | 11, 14, 20, 21, 23 | IX-18 |
| DEC-01 | Take an explicit decision | decisions | L2 | 3 | automatedVerified | 15, 18, 22 | IX-20, IX-24 |
| DEC-02 | Set aside and reopen a path | decisions | L2 | 2 | automatedVerified | 15, 18, 22 | IX-22, IX-23 |
| DEC-03 | Undo and redo without harming anyone | decisions | L2 | 3 | automatedVerified | 15, 18, 22 | Principes transversaux |
| AI-05 | Compare directions without inventing scores | intelligence | L3 | 2 | specified | 13, 15, 16, 20 | Principes transversaux |
| AI-06 | Synthesise and prepare a deliverable | intelligence | L3 | 3 | specified | 13, 15, 16, 20 | Principes transversaux |
| AI-11 | See a proposal's reasons and destination | intelligence | L3 | 2 | specified | 13, 15, 16, 20 | Principes transversaux |
| AI-12 | Manage a large context | intelligence | L3 | 2 | specified | 13, 15, 16, 20 | Principes transversaux |
| CAN-06 | Link, select and edit a relation | canvas | L3 | 2 | specified | 11, 14, 20, 21, 23 | IX-14, IX-15 |
| CAN-07 | Group and fold visually | canvas | L3 | 2 | specified | 11, 14, 20, 21, 23 | IX-16 |
| CAN-09 | Search and navigate | canvas | L3 | 3 | specified | 11, 14, 20, 21, 23 | IX-12, IX-30 |
| CAN-10 | Presentation and accessible reading | canvas | L3 | 3 | specified | 11, 14, 20, 21, 23 | IX-08, IX-16, IX-44 |
| CTX-02 | Drop resources and read them | context | L3 | 2 | automatedVerified | 15, 17, 22 | IX-28 |
| CTX-03 | Cite and verify provenance | context | L3 | 3 | automatedVerified | 15, 17, 22 | IX-08 |
| CTX-04 | Define a hypothesis or a constraint | context | L3 | 2 | specified | 15, 17, 22 | Principes transversaux |
| CTX-05 | Understand the impact of new information | context | L3 | 2 | specified | 15, 17, 22 | IX-24, IX-29 |
| CTX-06 | See and limit what intelligence will use | context | L3 | 2 | automatedVerified | 15, 17, 22 | Principes transversaux |
| CTX-07 | Update a resource without erasing history | context | L3 | 2 | automatedVerified | 15, 17, 22 | IX-29 |
| DEC-04 | Build a validation experiment | decisions | L4 | 2 | specified | 15, 18, 22 | Principes transversaux |
| DEC-05 | Record a result and learn | decisions | L4 | 2 | specified | 15, 18, 22 | Principes transversaux |
| DEC-06 | Understand how you got here | decisions | L4 | 2 | specified | 15, 18, 22 | IX-08, IX-41 |
| DOC-05 | Rename, duplicate, export | documents | L4 | 3 | specified | 12, 13, 17 | IX-33, IX-43 |
| DOC-06 | Find your documents | documents | L4 | 3 | specified | 12, 13, 17 | IX-30, IX-31 |
| DOC-07 | Archive, trash, delete | documents | L4 | 2 | specified | 12, 13, 17 | Principes transversaux |
| DOC-08 | Preferences and diagnostics | documents | L4 | 2 | specified | 12, 13, 17 | IX-44 |
| TEAM-01 | Sign in and create a workspace | collaboration | L5 | 2 | specified | 18, 22, 23 | Principes transversaux |
| TEAM-02 | Share a private document | collaboration | L5 | 3 | specified | 18, 22, 23 | IX-33 |
| TEAM-03 | Invite and join | collaboration | L5 | 3 | specified | 18, 22, 23 | IX-34 |
| TEAM-04 | Apply rights and manage members | collaboration | L5 | 2 | specified | 18, 22, 23 | IX-34, IX-40 |
| TEAM-05 | Real presence and voluntary follow | collaboration | L5 | 3 | specified | 18, 22, 23 | IX-38 |
| TEAM-06 | Discuss and mention in the right place | collaboration | L5 | 3 | specified | 18, 22, 23 | IX-36 |
| TEAM-07 | Contribute without overwriting the common document | collaboration | L5 | 3 | specified | 18, 22, 23 | IX-19, IX-35 |
| TEAM-08 | Review, request changes, accept | collaboration | L5 | 3 | specified | 18, 22, 23 | IX-20, IX-25, IX-36 |
| TEAM-09 | Edit in parallel and resolve a conflict | collaboration | L5 | 2 | specified | 18, 22, 23 | IX-37 |
| TEAM-10 | Work offline then synchronise | collaboration | L5 | 2 | specified | 18, 22, 23 | IX-32, IX-39 |
| TEAM-11 | Resume a session and see what changed | collaboration | L5 | 2 | specified | 18, 22, 23 | IX-41 |
| TEAM-12 | Leave, revoke, keep an authorised copy | collaboration | L5 | 3 | specified | 18, 22, 23 | IX-40 |
| TEAM-13 | Present together without piloting others | collaboration | L5 | 3 | specified | 18, 22, 23 | IX-38 |
| STU-01 | Turn know-how into a reusable method | studio | L7 | 2 | specified | 08, 19, 22 | Principes transversaux |
| STU-02 | Record a technical capability | studio | L7 | 3 | specified | 08, 19, 22 | Principes transversaux |
| STU-03 | Find relevant contributions | studio | L7 | 3 | specified | 08, 19, 22 | Principes transversaux |
| STU-04 | Assemble a small product | studio | L7 | 2 | specified | 08, 19, 22 | IX-42 |
| STU-05 | Test a tool with demonstration data | studio | L7 | 2 | specified | 08, 19, 22 | IX-42 |
| STU-06 | Reuse and update a contribution | studio | L7 | 3 | specified | 08, 19, 22 | Principes transversaux |
| STU-07 | See authors and negotiate shares | studio | L7 | 3 | specified | 08, 19, 22 | Principes transversaux |
| STU-08 | Prepare a private or public release | studio | L7 | 2 | specified | 08, 19, 22 | Principes transversaux |
| STU-09 | Consult a product as an end user | studio | L7 | 2 | specified | 08, 19, 22 | IX-42 |
| AI-10 | Choose a cloud destination explicitly | intelligence | L8 | 2 | specified | 13, 15, 16, 20 | Principes transversaux |
| COM-01 | Buy access to a product | commerce | L9 | 2 | specified | 19, 22 | Principes transversaux |
| COM-02 | Compute and consult revenue | commerce | L9 | 2 | specified | 19, 22 | Principes transversaux |
| COM-03 | Support, reporting, refunds | commerce | L9 | 2 | specified | 19, 22 | Principes transversaux |
| EXT-01 | Export a living document and read it on the web | ecosystem | L9 | 3 | specified | 07, 17, 19 | IX-43 |
| EXT-02 | Receive a proposal from another assistant | ecosystem | L9 | 2 | specified | 07, 17, 19 | Principes transversaux |
| EXT-03 | Native commands and system sharing | ecosystem | L9 | 2 | specified | 07, 17, 19 | Principes transversaux |
