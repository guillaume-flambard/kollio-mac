# Kollio — Direction design et recherche Apple/Canvas

Spécifications de conception extraites du livre de recherche
*KOLLIO — Recherche Design Apple & Canvas V1* (26 septembre 2026). Companion
du cahier des charges fonctionnel V2. Aucun fichier n'a été modifié dans le
code : ces documents décrivent une direction à tester.

## Ordre de lecture

| Document | Contenu | Chapitres source |
|---|---|---|
| [01-direction-and-decisions.md](01-direction-and-decisions.md) | Décisions de conception, matrice de transfert, registre d'amendements DR-01 à DR-12 | 01, 10, 25 |
| [02-platform-and-accessibility.md](02-platform-and-accessibility.md) | Comportements macOS, profils de périphérique, contrat d'accessibilité | 02, 23 |
| [03-benchmark-and-transfer.md](03-benchmark-and-transfer.md) | Freeform, Miro, FigJam, Excalidraw, tldraw, Allume, Heptabase, Obsidian | 04 à 09 |
| [04-visual-language-and-surfaces.md](04-visual-language-and-surfaces.md) | Identité visuelle, contrastes calculés, où chaque chose apparaît, lecture et provenance | 11, 12, 17 |
| [05-journeys-and-behaviour.md](05-journeys-and-behaviour.md) | Mouvement, deux premières minutes, gestes, propositions IA, latence, équipe, studio, grammaire de mouvement | 03, 13 à 16, 18 à 20 |
| [06-interaction-atlas.md](06-interaction-atlas.md) | 44 contrats de micro-interaction IX-01 à IX-44 | 21 |
| [07-storyboards-and-validation.md](07-storyboards-and-validation.md) | 8 storyboards SB-01 à SB-08, plan de recherche UX-01 à UX-12 | 22, 24 |
| [08-feature-mapping.md](08-feature-mapping.md) | Correspondance des 71 fonctionnalités V2 avec chapitres et interactions | 26 |
| [09-sources.md](09-sources.md) | Registre de preuve, 60 sources avec limites explicites | 27 |

## Portée et limites

Le livre est un compagnon de recherche, pas une spécification exécutable. Les
protocoles de recette commencent à `notRun` : les critères humains restent en
attente tant que la séance n'a pas eu lieu. Les durées, tailles et contrasts
sont des valeurs de départ propositions, pas des résultats mesurés.

Les statuts d'information sont distincts : exigence V2, source de plateforme,
observation documentaire, résultat de recherche, proposition Kollio.

## Identifiants stables

- Interfaces : U00 à U13 (cahier des charges V2)
- Fonctions : DOC, CAN, CTX, AI, DEC, TEAM, STU, COM, EXT
- Interactions : IX-01 à IX-44
- Scénarios : SB-01 à SB-08
- Protocoles : UX-01 à UX-12
- Décisions : DR-01 à DR-12

# 00 — Ce livre, ses preuves et ses limites

## Ce que la recherche doit décider

La question n’est pas « comment donner un style Apple à un tableau blanc ? ». Kollio veut faire comprendre une pensée qui se transforme, sans demander d’administrer un graphe. Le design doit permettre de commencer avec une phrase, d’examiner une proposition, de la corriger et de reprendre le travail plus tard. Une interface spectaculaire qui échoue sur ces quatre opérations ne répond pas au produit.

Ce livre est le compagnon de recherche et de conception du **cahier des charges Kollio V2**, et non son remplacement implicite. Il conserve ses ensembles SOLO, TEAM, STUDIO et ECOSYSTEM, ses surfaces U00–U13, ses fonctionnalités DOC/CAN/CTX/AI/DEC/TEAM/STU/COM/EXT et ses scénarios J01–J14. Il approfondit leur apparence, leur découvrabilité, leur mouvement et leurs critères d’évaluation. Les propositions qui contredisent un comportement déjà fixé sont inscrites au registre des amendements : elles ne sont pas discrètement transformées en ordre de développement.

La recherche a été effectuée le **26 septembre 2026**. Une page officielle consultée ce jour peut décrire une interface plus ancienne, une fonctionnalité en déploiement ou une cible différente. La date d’accès n’est pas la date de création d’un principe. Les études de 2007 et 2008 restent présentées comme historiques. Les notes de Muse/Allume ne deviennent pas des descriptions certifiées de la version actuelle.

## Cinq statuts d’information

**Exigence V2.** Décision déjà posée par le cahier des charges : texte original conservé, décisions réversibles, génération Apple locale prioritaire, proposition avant modification, langue française et anglaise. Le fichier V2 est une spécification, pas un rapport de test.

**Source de plateforme.** Recommandation Apple ou documentation d’une interface. Elle explique un comportement ou un usage attendu ; elle ne prouve pas qu’une taille, une couleur ou une durée particulière augmente la productivité dans Kollio.

**Observation documentaire.** Mécanisme décrit par un éditeur, ou élément visible dans une illustration officielle effectivement examinée. Ce statut ne signifie pas que j’ai installé le produit, utilisé ses gestes ou testé son accessibilité avec un lecteur d’écran.

**Résultat de recherche.** Conclusion limitée au contexte de l’étude consultée. Les sources empiriques retenues ici sont des pages et résumés primaires. Il n’y a pas eu réanalyse des données, reproduction des expériences ni lecture instrumentée de toutes leurs annexes.

**Proposition Kollio.** Choix original, argumenté, mais qui doit être testé : une barre de trois actions, un texte à 15 points, un aperçu à trois branches, un mouvement de 220 millisecondes. Les valeurs apparaissent dans les fichiers de tokens pour faciliter l’essai ; elles ne sont pas des résultats mesurés.

## Matériaux réellement consultés

Le corpus rassemble des HIG Apple, des transcriptions WWDC, de l’aide Freeform, Miro et FigJam, des pages produits et notes de conception d’Allume, MindNode, Heptabase, Scrintal, ainsi que la documentation d’Excalidraw, tldraw et JSON Canvas. Des recommandations W3C, NN/g et Microsoft HAX complètent les sources de produits. Les références détaillées sont dans le registre, avec un résumé limité à ce qu’elles soutiennent.

Quatre visuels officiels ont été examinés : une illustration générale Freeform, un extrait de barre d’outils Miro, une composition Allume sur iPad et une vue Heptabase mêlant tableau et lecture. Ce sont des **images d’éditeur**, non des captures produites par un essai de leurs applications. Les transcriptions vidéo ont été lues ; aucune mesure de chronologie n’a été extraite d’une vidéo concurrente. Le livre n’invente donc pas « le ressort exact de Miro » ou « la courbe de Freeform ».

Les images propriétaires ne sont pas redistribuées en collection dans le pack. Le registre visuel donne leur origine et explique l’observation. Les tableaux de gestes, chronologies et règles proposés pour Kollio sont des créations de spécification, pas des copies de ces interfaces.

## Référence non identifiée : « M26 »

La recherche n’a pas permis d’identifier de manière fiable un produit de canvas correspondant à ce nom dans le contexte demandé. Il peut s’agir d’une autre orthographe ou d’une transcription, mais cette possibilité ne permet pas de choisir à la place de l’utilisateur. **M26 n’est ni remplacé par N26, ni assimilé à macOS 26.** Son audit reste ouvert jusqu’à réception d’un lien exact. Cette incertitude ne bloque pas le reste du corpus.

## Comment utiliser le livre

Pour choisir la direction, lire les chapitres 01, 10, 11 et 25. Pour travailler une fonctionnalité, retrouver son identifiant V2 dans la matrice, puis ouvrir le contrat d’interaction et le protocole de recette concernés. Pour coder une transition, lire sa fiche de l’atlas avec sa règle d’interruption : une durée seule n’est pas une animation spécifiée.

Le résultat de cette recherche n’est pas « le meilleur design prouvé ». C’est **une direction cohérente, une justification inspectable et un moyen de départager les variantes**. Aucun changement n’a été appliqué au dépôt dans le cadre de cette livraison. Le nombre de sources, de fiches ou de mots n’est pas un score de qualité du logiciel.


---

<a id="ch-01"></a>
