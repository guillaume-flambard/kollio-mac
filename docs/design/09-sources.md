# 27 — Sources et registre de preuve

Chaque entrée distingue un fait minimal soutenu par la source et ses limites. Les développements de design dans les autres chapitres sont des propositions originales pour Kollio. Les sources ne constituent pas une certification de leur efficacité. Les URL sont fournies pour vérification ; le livre hors ligne ne charge pas de contenus externes automatiquement.

Le corpus est daté du 26 septembre 2026. Pour les HIG rendues dynamiquement, le contenu JSON public du même site Apple a été utilisé lorsque nécessaire. Les transcriptions WWDC ne sont pas des vidéos chronométrées. Les résumés primaires de recherche ne sont pas des reproductions d’expériences. Aucun texte intégral propriétaire n’est redistribué dans le pack.

**Base produit** : `KOLLIO_CAHIER_DES_CHARGES_COMPLET_V2.md`, version 2.0, 25 septembre 2026. Parties relues par retrieval : conventions/personas, surfaces, gestes/design, documents et canvas, registre AI/CAN, équipe, scénarios et recette, index des 71 fonctions. Le registre fourni a été extrait de l’index, pas reconstitué de mémoire. Ce livre ne constitue pas un nouvel audit du dépôt GitHub ou de son exécution.

<a id="source-A01"></a>

## A01 — Apple HIG — Motion

**Nature :** `platform_guidance`. **Consultation :** 2026-09-26.

**Soutient :** Apple recommande un mouvement intentionnel, bref, cohérent avec les interactions et désactivable lorsque nécessaire.

**Limite :** Recommandations de plateforme ; elles ne déterminent pas les durées optimales de Kollio.

Source : https://developer.apple.com/design/human-interface-guidelines/motion

Représentation consultée : https://developer.apple.com/tutorials/data/design/human-interface-guidelines/motion.json

<a id="source-A02"></a>

## A02 — Apple WWDC18 — Designing Fluid Interfaces

**Nature :** `platform_session`. **Consultation :** 2026-09-26. **Publication de référence :** 2018.

**Soutient :** La session insiste sur la réponse immédiate, la continuité spatiale et la possibilité de reprendre la main pendant une transition.

**Limite :** Transcription consultée ; aucune mesure de Kollio ni lecture instrumentée de la vidéo.

Source : https://developer.apple.com/videos/play/wwdc2018/803/

<a id="source-A03"></a>

## A03 — Apple WWDC25 — Meet Liquid Glass

**Nature :** `platform_session`. **Consultation :** 2026-09-26. **Publication de référence :** 2025.

**Soutient :** Le matériau sert une couche fonctionnelle de commandes et de navigation distincte du contenu ; ses variantes répondent à des contextes différents.

**Limite :** N’implique ni zéro barre d’outils ni du verre sur toutes les cartes ; transcription, pas test du rendu.

Source : https://developer.apple.com/videos/play/wwdc2025/219/

<a id="source-A04"></a>

## A04 — Apple HIG — Materials

**Nature :** `platform_guidance`. **Consultation :** 2026-09-26.

**Soutient :** Les matériaux aident à distinguer profondeur, contenu et commandes, avec des recommandations propres aux plateformes.

**Limite :** Ne pas transposer les passages visionOS à une application macOS.

Source : https://developer.apple.com/design/human-interface-guidelines/materials

Représentation consultée : https://developer.apple.com/tutorials/data/design/human-interface-guidelines/materials.json

<a id="source-A05"></a>

## A05 — Apple WWDC23 — Animate with springs

**Nature :** `platform_session`. **Consultation :** 2026-09-26. **Publication de référence :** 2023.

**Soutient :** Les ressorts peuvent préserver la continuité de position et vitesse ; ils ne nécessitent pas un rebond visible.

**Limite :** Le bénéfice dans le canvas doit être testé ; aucun réglage proposé ici n’est imposé par cette session.

Source : https://developer.apple.com/videos/play/wwdc2023/10158/

<a id="source-A06"></a>

## A06 — Apple HIG — Typography

**Nature :** `platform_guidance`. **Consultation :** 2026-09-26.

**Soutient :** Apple distingue les hiérarchies et tailles de référence selon la plateforme. La section macOS ne présente pas Dynamic Type comme le mécanisme disponible sur iOS.

**Limite :** Une police système n’assure pas seule une interface accessible ; le zoom du document et la taille de lecture sont différents.

Source : https://developer.apple.com/design/human-interface-guidelines/typography

Représentation consultée : https://developer.apple.com/tutorials/data/design/human-interface-guidelines/typography.json

<a id="source-A07"></a>

## A07 — Apple — UI Design Dos and Don’ts

**Nature :** `platform_guidance`. **Consultation :** 2026-09-26.

**Soutient :** La page propose notamment des cibles tactiles de 44 × 44 points et une proximité entre commandes et contenu concerné.

**Limite :** Recommandation tactile ; pas une obligation de dimensionner toute commande macOS à 44 points.

Source : https://developer.apple.com/design/tips/

<a id="source-A08"></a>

## A08 — Apple Support — Use Multi-Touch gestures on your Mac

**Nature :** `platform_support`. **Consultation :** 2026-09-26.

**Soutient :** Le guide associe le défilement à deux doigts et le pincement à la navigation/au zoom dans les contextes pris en charge.

**Limite :** Les préférences utilisateur et le matériel affectent les gestes ; un double-tap tactile n’est pas un double-clic souris.

Source : https://support.apple.com/en-us/102482

<a id="source-A09"></a>

## A09 — Apple HIG — Menus

**Nature :** `platform_guidance`. **Consultation :** 2026-09-26.

**Soutient :** Les menus donnent accès à des actions nommées clairement et à leurs états ; la ponctuation peut indiquer une étape supplémentaire.

**Limite :** Leur existence n’oblige pas à afficher toutes les actions dans le canvas.

Source : https://developer.apple.com/design/human-interface-guidelines/menus

Représentation consultée : https://developer.apple.com/tutorials/data/design/human-interface-guidelines/menus.json

<a id="source-A10"></a>

## A10 — Apple HIG — Progress indicators

**Nature :** `platform_guidance`. **Consultation :** 2026-09-26.

**Soutient :** Un progrès déterminé correspond à une quantité réellement connue ; l’indication doit rester compréhensible et permettre l’annulation lorsque possible.

**Limite :** Ne donne pas le droit d’inventer un pourcentage de raisonnement LLM.

Source : https://developer.apple.com/design/human-interface-guidelines/progress-indicators

Représentation consultée : https://developer.apple.com/tutorials/data/design/human-interface-guidelines/progress-indicators.json

<a id="source-A11"></a>

## A11 — Apple HIG — Modality

**Nature :** `platform_guidance`. **Consultation :** 2026-09-26.

**Soutient :** Une présentation modale convient à certaines tâches concentrées, avec une sortie claire ; l’empilement gratuit est déconseillé.

**Limite :** Une interdiction universelle de toute modalité n’est pas une règle Apple.

Source : https://developer.apple.com/design/human-interface-guidelines/modality

Représentation consultée : https://developer.apple.com/tutorials/data/design/human-interface-guidelines/modality.json

<a id="source-A12"></a>

## A12 — Apple WWDC25 — Explore prompt design and safety for on-device foundation models

**Nature :** `platform_session`. **Consultation :** 2026-09-26. **Publication de référence :** 2025.

**Soutient :** La session porte sur la formulation des demandes et la conception autour des capacités et limites du modèle embarqué.

**Limite :** Pas une preuve que le modèle comprend tout document ni qu’un rendu structuré est factuellement exact.

Source : https://developer.apple.com/videos/play/wwdc2025/248/

<a id="source-F01"></a>

## F01 — Apple Freeform User Guide — Mac

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** Le guide présente un tableau libre mêlant différentes ressources et des commandes natives visibles.

**Limite :** Capture officielle examinée, pas application manipulée ; le visuel ne prouve pas le ressenti des gestes.

Source : https://support.apple.com/en-euro/guide/freeform/welcome/mac

<a id="source-F02"></a>

## F02 — Freeform — Keyboard shortcuts and gestures

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** Le guide documente des accès clavier et gestes pour la navigation et les objets.

**Limite :** Ne pas importer des raccourcis sans tenir compte du contexte de saisie et des claviers FR/EN.

Source : https://support.apple.com/en-euro/guide/freeform/frfm46c25187e/mac

<a id="source-F03"></a>

## F03 — Freeform — Work with scenes

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** Les scènes mémorisent des vues du tableau pour parcourir ou présenter son contenu.

**Limite :** Une vue mémorisée n’est ni une hypothèse ni un groupe métier.

Source : https://support.apple.com/en-euro/guide/freeform/frfm7cc55b64/mac

<a id="source-F04"></a>

## F04 — Freeform — Collaborate on a board

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** La documentation distingue rejoindre une position et suivre un collaborateur ; une interaction locale peut arrêter ce suivi.

**Limite :** Comportement documentaire ; disponibilité et vécu non testés avec deux comptes.

Source : https://support.apple.com/en-euro/guide/freeform/frfm4e6e2c9a6/mac

<a id="source-M01"></a>

## M01 — Miro — New simplified user interface

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** La simplification regroupe les outils par fonctions tout en conservant des zones de création, de navigation et de collaboration.

**Limite :** La page décrit un déploiement progressif ; la capture de barre de création examinée est un extrait, pas tout le produit.

Source : https://help.miro.com/hc/en-us/articles/20967864443410-Miro-s-new-simplified-user-interface

<a id="source-M02"></a>

## M02 — Miro — Mouse, trackpad or touchscreen

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** Miro documente des modes de navigation adaptés aux périphériques, dont le pan tactile et le pincement au trackpad.

**Limite :** La configuration exacte peut différer ; ne pas exporter le comportement de molette d’un produit web comme loi macOS.

Source : https://help.miro.com/hc/en-us/articles/360017731053-Using-Miro-with-a-mouse-trackpad-or-touchscreen

<a id="source-M03"></a>

## M03 — Miro — Attention management

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** Des fonctions de suivi et de rassemblement des participants pilotent l’attention dans un tableau collaboratif.

**Limite :** Le présent document recommande une variante volontaire ; ce choix Kollio n’est pas présenté comme celui de Miro.

Source : https://help.miro.com/hc/en-us/articles/360013358479-Attention-management

<a id="source-M04"></a>

## M04 — Miro — Catch up

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** La fonctionnalité documentée vise la reprise de ce qui s’est passé sur un tableau.

**Limite :** N’établit ni réduction mesurée du temps de reprise ni disponibilité sur chaque compte.

Source : https://help.miro.com/hc/en-us/articles/24002895569298-Catch-up

<a id="source-M05"></a>

## M05 — Miro — Command palette

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** Une palette fournit un accès à des commandes sans conserver tous leurs boutons à l’écran.

**Limite :** Les raccourcis de Kollio restent son propre contrat de plateforme.

Source : https://help.miro.com/hc/en-us/articles/10389262146706-Command-palette

<a id="source-J01"></a>

## J01 — FigJam — Explore files

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** Le guide décrit la surface de travail, ses outils et la structuration du contenu.

**Limite :** Documentation de fonctionnement ; pas une preuve expérimentale de supériorité.

Source : https://help.figma.com/hc/en-us/articles/15300412458647-Explore-FigJam-files

<a id="source-J02"></a>

## J02 — FigJam — Quick create

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** La création près d’un objet réduit le retour à la barre d’outils ; certains gestes créent aussi une liaison.

**Limite :** Les variantes diffèrent selon le type d’objet ; ne pas assimiler toute création à une relation sémantique.

Source : https://help.figma.com/hc/en-us/articles/1500004291601-Build-faster-with-quick-create-in-FigJam

<a id="source-J03"></a>

## J03 — FigJam for iPad — transition and interaction guide

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** La page annonce le retrait de l’app FigJam autonome le 8 janvier 2026 et l’usage via Figma, puis décrit des gestes tactiles.

**Limite :** La même page conserve des instructions historiques : analyser les principes, pas recommander l’installation de l’ancienne application.

Source : https://help.figma.com/hc/en-us/articles/4502073572247-FigJam-for-iPad

<a id="source-J04"></a>

## J04 — FigJam — Screen reader

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** Le guide expose régions, parcours hiérarchique et lecture/édition d’objets. Il indique une activation spécifique de l’accessibilité du tableau.

**Limite :** Kollio doit rendre son contenu accessible sans découverte préalable d’un réglage caché ; ce choix est une différence assumée.

Source : https://help.figma.com/hc/en-us/articles/14477051168791-Use-FigJam-with-a-screen-reader

<a id="source-E01"></a>

## E01 — Excalidraw — Official project README

**Nature :** `product_repository`. **Consultation :** 2026-09-26.

**Soutient :** Le projet expose un tableau graphique au style dessiné et un format de scène réutilisable.

**Limite :** README consulté, pas usage de l’application ni audit de tout son code.

Source : https://github.com/excalidraw/excalidraw

Représentation consultée : https://raw.githubusercontent.com/excalidraw/excalidraw/master/README.md

<a id="source-T01"></a>

## T01 — tldraw — Accessibility

**Nature :** `sdk_documentation`. **Consultation :** 2026-09-26.

**Soutient :** Le SDK documente des descriptions accessibles des formes, l’adaptation au mouvement réduit et le contrôle des raccourcis.

**Limite :** API web ; transposer les capacités, pas importer ses composants dans SwiftUI.

Source : https://tldraw.dev/sdk-features/accessibility

<a id="source-O01"></a>

## O01 — Obsidian — Canvas

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** Canvas associe notes, fichiers et relations sur une surface spatiale.

**Limite :** Carte, fichier source et contenu indexé ne sont pas interchangeables ; fonctionnement natif Kollio à concevoir.

Source : https://obsidian.md/help/plugins/canvas

<a id="source-O02"></a>

## O02 — JSON Canvas — Open format

**Nature :** `format_specification`. **Consultation :** 2026-09-26.

**Soutient :** JSON Canvas décrit un format ouvert pour des données de canvas.

**Limite :** Ne fournit pas à lui seul les décisions, permissions et transactions spécifiques de Kollio.

Source : https://jsoncanvas.org/

<a id="source-L01"></a>

## L01 — Allume — Product overview, formerly Muse

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** Allume présente un espace de pensée mêlant documents et médias, avec une composition spatiale et des choix de simplicité.

**Limite :** Image officielle examinée ; slogans de productivité non traités comme des résultats de recherche.

Source : https://allume.com/

<a id="source-L02"></a>

## L02 — Muse/Allume memo — Linked cards

**Nature :** `historical_design_memo`. **Consultation :** 2026-09-26. **Publication de référence :** 2022.

**Soutient :** La note explique le partage d’un même contenu entre plusieurs emplacements visuels.

**Limite :** Note de conception de 2022 ; pas assurance que chaque détail correspond à la version actuelle.

Source : https://allume.com/memos/2022-09-linked-cards/

<a id="source-L03"></a>

## L03 — Muse/Allume memo — Infinite canvas

**Nature :** `historical_design_memo`. **Consultation :** 2026-09-26. **Publication de référence :** 2020.

**Soutient :** Les auteurs discutent la tension entre espace extensible et orientation dans une surface de travail.

**Limite :** Retour des concepteurs en 2020, pas essai contrôlé ni comportement actuel certifié.

Source : https://allume.com/memos/2020-12-infinite-canvas/

<a id="source-L04"></a>

## L04 — Muse/Allume memo — Pointing

**Nature :** `historical_design_memo`. **Consultation :** 2026-09-26. **Publication de référence :** 2021.

**Soutient :** La note examine comment le pointage exprime attention et communication dans un espace partagé.

**Limite :** Observation de conception historique ; pas mesure d’un gain sur Kollio.

Source : https://allume.com/memos/2021-04-pointing/

<a id="source-H01"></a>

## H01 — Heptabase — Product overview

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** Le produit présente des cartes et tableaux reliés à des ressources de connaissance ; une capture montre une vue d’ensemble avec une zone de lecture.

**Limite :** Image marketing examinée, pas mesure de la charge cognitive ni manipulation du produit.

Source : https://heptabase.com/

<a id="source-S01"></a>

## S01 — Scrintal — Product overview

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** Le site présente un travail de notes et ressources sur canvas, avec liens entre contenus.

**Limite :** Description éditeur ; aucun chiffre de performance ou de satisfaction utilisé.

Source : https://scrintal.com/

<a id="source-N01"></a>

## N01 — MindNode — Features

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** MindNode combine carte, plan, repli, notes et focalisation ; sa page présente aussi l’expansion de contenu par IA.

**Limite :** Ne démontre pas la qualité de l’IA ; pas une raison de prétendre Kollio premier canvas intelligent.

Source : https://www.mindnode.com/features

<a id="source-N02"></a>

## N02 — MindNode — Accessibility

**Nature :** `product_documentation`. **Consultation :** 2026-09-26.

**Soutient :** La page précise les plateformes pour VoiceOver, Dynamic Type, thèmes et focalisation ; toutes les fonctions ne sont pas annoncées partout.

**Limite :** Les listes de plateformes importent ; ne pas attribuer les fonctionnalités iPad au Mac par défaut.

Source : https://www.mindnode.com/accessibility

<a id="source-R01"></a>

## R01 — Amershi et al. — Guidelines for Human-AI Interaction

**Nature :** `research_primary_summary`. **Consultation :** 2026-09-26. **Publication de référence :** 2019.

**Soutient :** Le travail de 2019 propose 18 recommandations et une évaluation par des praticiens sur plusieurs produits IA.

**Limite :** Résumé primaire consulté ; pas un essai de Kollio, ni une validation spécifique des LLM actuels.

Source : https://www.microsoft.com/en-us/research/publication/guidelines-for-human-ai-interaction/

<a id="source-R02"></a>

## R02 — Microsoft HAX — Design Library

**Nature :** `research_toolkit`. **Consultation :** 2026-09-26.

**Soutient :** La bibliothèque organise des recommandations autour du démarrage, de l’usage, des erreurs et de l’évolution des systèmes IA.

**Limite :** Cadre d’analyse, pas assurance automatique de confiance ou d’efficacité.

Source : https://www.microsoft.com/en-us/haxtoolkit/library/

<a id="source-R03"></a>

## R03 — Heer & Robertson — Animated Transitions in Statistical Data Graphics

**Nature :** `research_primary_summary`. **Consultation :** 2026-09-26. **Publication de référence :** 2007.

**Soutient :** Deux expériences rapportées examinent l’apport de transitions animées pour lire des transformations de graphiques.

**Limite :** Résumé primaire de 2007 consulté ; ne prouve pas que toutes les animations de graphes aident la décision.

Source : https://idl.uw.edu/papers/animated-transitions

<a id="source-R04"></a>

## R04 — Robertson et al. — Effectiveness of Animation in Trend Visualization

**Nature :** `research_primary_summary`. **Consultation :** 2026-09-26. **Publication de référence :** 2008.

**Soutient :** Le résumé rapporte que des vues statiques peuvent mieux servir certaines analyses de tendances que l’animation, malgré l’attrait de cette dernière.

**Limite :** Contexte expérimental de 2008, pas canvas de LLM ; effet non généralisé à toutes tâches.

Source : https://www.microsoft.com/en-us/research/publication/effectiveness-of-animation-in-trend-visualization/

<a id="source-R05"></a>

## R05 — NN/g — Progressive Disclosure

**Nature :** `expert_guidance`. **Consultation :** 2026-09-26. **Publication de référence :** 2006.

**Soutient :** La divulgation progressive exige de choisir les actions principales et de rendre l’accès au secondaire évident.

**Limite :** Recommandation experte de 2006 ; ne fixe pas universellement trois actions ni zéro panneau.

Source : https://www.nngroup.com/articles/progressive-disclosure/

<a id="source-R06"></a>

## R06 — NN/g — Response Times: The 3 Important Limits

**Nature :** `expert_guidance`. **Consultation :** 2026-09-26.

**Soutient :** L’article fournit des repères historiques de perception du délai et de continuité de l’action.

**Limite :** Heuristiques, pas SLA pour inférence locale ni lois exactes applicables à toutes populations.

Source : https://www.nngroup.com/articles/response-times-3-important-limits/

<a id="source-W01"></a>

## W01 — WCAG 2.2 — Contrast minimum

**Nature :** `accessibility_standard`. **Consultation :** 2026-09-26.

**Soutient :** Le critère AA distingue notamment un contraste minimal de 4,5:1 pour le texte courant.

**Limite :** Standard web utilisé comme repère mesurable ; unités CSS et points natifs ne doivent pas être confondus.

Source : https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html

<a id="source-W02"></a>

## W02 — WCAG 2.2 — Non-text contrast

**Nature :** `accessibility_standard`. **Consultation :** 2026-09-26.

**Soutient :** Les informations graphiques et composants essentiels concernés doivent avoir un contraste de 3:1 avec les couleurs adjacentes.

**Limite :** Les éléments purement décoratifs ne portent pas la même obligation ; ce document ne certifie pas l’application.

Source : https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html

<a id="source-W03"></a>

## W03 — WCAG 2.2 — Focus not obscured minimum

**Nature :** `accessibility_standard`. **Consultation :** 2026-09-26.

**Soutient :** Le critère AA minimum interdit que le composant focalisé soit entièrement masqué par du contenu créé par l’auteur.

**Limite :** Kollio propose un focus entièrement visible : objectif plus strict, pas citation littérale du minimum AA.

Source : https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html

<a id="source-W04"></a>

## W04 — WCAG 2.2 — Target size minimum

**Nature :** `accessibility_standard`. **Consultation :** 2026-09-26.

**Soutient :** Le minimum AA vise 24 × 24 pixels CSS avec des exceptions, notamment liées à l’espacement.

**Limite :** Ce n’est ni la cible tactile Apple de 44 points ni une recommandation de rendre les commandes macOS minuscules.

Source : https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html

<a id="source-W05"></a>

## W05 — WCAG 2.2 — Dragging movements

**Nature :** `accessibility_standard`. **Consultation :** 2026-09-26.

**Soutient :** Les fonctions utilisant un glisser doivent offrir une alternative au pointeur simple sans glisser, sauf exceptions prévues.

**Limite :** Une alternative clavier seule ne répond pas à ce critère web précis ; transposition qualitative pour le natif.

Source : https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements.html

<a id="source-W06"></a>

## W06 — WCAG 2.2 — Content on hover or focus

**Nature :** `accessibility_standard`. **Consultation :** 2026-09-26.

**Soutient :** Les contenus additionnels concernés doivent pouvoir être fermés, survolés et conservés pendant leur utilisation.

**Limite :** Critère applicable selon le composant ; pas permission de rendre la commande principale invisible jusqu’au survol.

Source : https://www.w3.org/WAI/WCAG22/Understanding/content-on-hover-or-focus.html

<a id="source-W07"></a>

## W07 — WCAG 2.2 — Animation from interactions

**Nature :** `accessibility_standard`. **Consultation :** 2026-09-26.

**Soutient :** Le critère AAA permet de désactiver le mouvement déclenché par interaction lorsqu’il n’est pas essentiel.

**Limite :** Ne pas le présenter comme un critère AA ; un mouvement contrôlé directement et une décoration ne sont pas identiques.

Source : https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html

## Référence en attente — M26

Les recherches du nom dans le contexte canvas/whiteboard/interface n’ont pas permis d’identifier un produit fiable. Statut : non identifié. Aucun score, capture ou comportement n’est attribué à ce nom. Un lien exact est nécessaire pour ajouter son analyse.

## Illustrations effectivement examinées

Les quatre références visuelles listées dans `research/visual-observations.json` sont des images officielles vues durant la recherche. Elles ne sont pas des captures de sessions exécutées par le chercheur. Les images ne sont pas embarquées dans le livre pour éviter une redistribution non nécessaire ; leurs liens et observations sont conservés. Les schémas du chapitre 22 sont des scénarios originaux de conception, pas des captures du logiciel.
