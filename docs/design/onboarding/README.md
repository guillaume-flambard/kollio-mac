# Kollio — Patterns UX, onboarding et interactivité

Spécifications de conception extraites du livre de recherche
*KOLLIO — Patterns UX/UI, onboarding & interactivité V1* (26 septembre 2026).
Compagnon du cahier des charges V2 et de l'atlas design Apple & Canvas V1. Aucun
fichier de code n'a été modifié : ces documents décrivent une direction à tester.

Ce livre est le complément de [`../`](../README.md). Il traite ce que le premier
ne traitait pas : l'arrivée, la découverte, l'aide au bon moment, l'erreur et la
reprise. Il ne redéfinit ni le domaine ni la grammaire visuelle.

## Ordre de lecture

| Document | Contenu | Chapitres source |
|---|---|---|
| [01-direction-and-evidence.md](01-direction-and-evidence.md) | La décision centrale, ce que les sources soutiennent, matrice de transfert | 01, 02, 03 |
| [02-entry-and-first-value.md](02-entry-and-first-value.md) | Sept portes d'entrée, le premier parcours | 04, 05 |
| [03-learning-and-cues.md](03-learning-and-cues.md) | État d'apprentissage, aides contextuelles et règles d'éligibilité | 06, 07 |
| [04-ui-patterns-and-gestures.md](04-ui-patterns-and-gestures.md) | Choix de surface, interactivité directe | 08, 09 |
| [05-motion-and-ai-ux.md](05-motion-and-ai-ux.md) | Microanimations, UX de l'IA | 10, 11 |
| [06-errors-and-team-onboarding.md](06-errors-and-team-onboarding.md) | Erreurs et récupération, onboarding d'équipe | 12, 13 |
| [07-accessibility-and-language.md](07-accessibility-and-language.md) | Clavier, accessibilité, français, adaptation tactile | 14 |
| [08-pattern-catalogue.md](08-pattern-catalogue.md) | 36 fiches PAT et 10 conseils ONB avec leur texte FR/EN | 15, 16 |
| [09-interaction-contracts.md](09-interaction-contracts.md) | 20 contrats MIC | 17 |
| [10-journeys.md](10-journeys.md) | 8 parcours ONJ-01 à ONJ-08 | 18 |
| [11-protocols-and-measures.md](11-protocols-and-measures.md) | 10 protocoles EXP, trois horloges,，première valeur | 19, 20 |
| [12-scope-and-agent-work.md](12-scope-and-agent-work.md) | Raccordement V2, recette, matrice, décision finale | 21, 22, 23, 25 |
| [13-sources.md](13-sources.md) | Registre de preuve, 33 sources avec limites | 24 |
| [14-overlap-with-existing-requirements.md](14-overlap-with-existing-requirements.md) | Ce que ce livre ajoute, ce qu'il ne fait que reformuler | synthèse |

## Identifiants stables

- Patterns : PAT-01 à PAT-36
- Conseils : ONB-01 à ONB-10
- Contrats d'interaction : MIC-01 à MIC-20
- Parcours : ONJ-01 à ONJ-08
- Protocoles : EXP-01 à EXP-10

## Portée et limites

Aucun test utilisateur, aucune mesure de ressenti au trackpad, aucune évaluation
du modèle Apple, aucune modification du backend. Les protocoles commencent à
`notRun`. Les valeurs — deux apparitions de conseil par session, une impression
par conseil, 80–120 ms de retour — sont des hypothèses à tester, pas des
propriétés de TipKit ou d'un produit concurrent.

Le double-clic reste celui du V2 tant que `DR-01` n'est pas tranché. Ce livre ne
propose pas de le changer et ne le changera pas par un usage de l'agent.

# 00 — Mission, périmètre et statut des preuves

## Un approfondissement, pas un troisième redémarrage

Ce livre répond à une question précise : **comment faire apprendre et manipuler Kollio sans transformer le produit en tutoriel permanent ?** Il complète le cahier des charges fonctionnel V2 et l’atlas design Apple & Canvas V1. Le premier décrit les capacités ; le second pose la grammaire visuelle ; celui-ci décrit les mécanismes de découverte, d’apprentissage, de feedback, de récupération et d’interaction. Les fichiers d’origine restent conservés.

La cible principale reste le Mac, avec clavier, trackpad et souris. Les adaptations iPad/iPhone sont des décisions à éprouver ultérieurement, pas des fonctionnalités natives livrées avec cette recherche. Les futures capacités TEAM, STUDIO et ECOSYSTEM reçoivent une logique d’entrée, mais ne sont pas imposées au premier lancement individuel.

La recherche web a été menée le **26 septembre 2026**. Elle porte sur des sources Apple, W3C, des documents d’éditeurs et des publications originales. Certaines recommandations datent de plusieurs années ; la date de consultation n’est pas leur date de publication. Les résumés de recherche lus sont explicitement identifiés comme tels. Aucune étude utilisateur ni mesure de ressenti au trackpad n’a été conduite pour cette livraison.

## Ce qui change par rapport aux documents précédents

Le chapitre des « deux premières minutes » de l’atlas V1 décrivait déjà l’arrivée du contexte. Nous allons plus loin : entrées alternatives, rôle de l’utilisateur, conditions des conseils, interruption et reprise, valeur sans modèle, collaborateurs invités, état d’apprentissage non linéaire, instruments de mesure et contrats exploitables par l’agent.

La palette Paper / Ink / Branch est conservée. Ce livre ne propose pas une nouvelle marque, un autre backend ou un changement silencieux du double-clic. Il précise comment les affordances existantes deviennent compréhensibles. Les propositions qui changeraient une convention du V2 passent dans le registre d’amendements, avec une expérience à réaliser avant d’en faire une prescription.

## Cinq niveaux de preuve

| Marque | Nature | Ce qu’on peut en conclure |
|---|---|---|
| Exigence V2 | Règle déjà spécifiée | Comportement cible, pas réalisation constatée. |
| Recommandation de plateforme | HIG, WWDC, documentation | Cadre d’usage Apple ; vérifier plateforme et disponibilité. |
| Observation documentaire | Aide d’un produit | Mécanisme décrit par l’éditeur, non essai effectué ici. |
| Résultat empirique | Étude originale ou résumé primaire | Résultat limité aux tâches, personnes et conditions étudiées. |
| Hypothèse Kollio | Design proposé dans ce livre | Décision argumentée à implémenter/tester, non meilleure pratique prouvée. |

Les fiches `PAT`, `ONB`, `MIC` et `EXP` sont des **propositions Kollio**. Leurs sources éclairent le problème, mais ne prouvent pas les valeurs proposées. Les minutages, limites de conseils et distances sont des valeurs de départ, pas les paramètres internes de Miro, d’Apple ou d’un autre logiciel.

## Matériaux réellement utilisés et limites

Le V2 et les chapitres pertinents de l’atlas V1 ont été relus. Les sources web sont résumées dans un registre avec leur périmètre. Les produits concurrents n’ont pas tous été installés ; leurs parcours sont étudiés au travers de leurs aides officielles. Les transcriptions WWDC ne sont pas des captures instrumentées de leurs animations. Aucun fonds d’images propriétaires n’est redistribué.

La référence précédente « M26 » reste non identifiée sans lien précis. Nous ne la remplaçons pas par une marque au nom proche. Les pages non accessibles, les extraits tiers insuffisants et les classements promotionnels ne sont pas utilisés comme preuves. Une source paywallée ne devient pas « lue » parce que son titre a été trouvé.

Le livrable est un livre, un catalogue structuré et des règles testables. Les vérifications effectuées sur ces artefacts sont séparées de la recette de Kollio. Le code natif, le modèle Apple et le backend de l’application ne sont pas modifiés ni certifiés par cette livraison.



---

<a id="ch-01"></a>
