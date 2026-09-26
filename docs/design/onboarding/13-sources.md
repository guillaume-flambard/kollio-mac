# 24 — Registre des sources et limites de la recherche

## Sources et nature des preuves

Chaque entrée indique ce qui a été consulté et ce qu’elle ne permet pas d’affirmer. Les documents Apple sont des recommandations ou des descriptions d’API ; les aides produits décrivent des fonctions ; les études ne sont pas des benchmarks Kollio. Tous les résumés sont reformulés. Les originaux ne sont pas reproduits dans le pack.

Les renvois internes au V2 et à l’atlas désignent les fichiers fournis dans la conversation, relus par sections pertinentes. Aucun état du dépôt courant n’a été vérifié pour cette recherche : ce n’est pas un audit de code.

<a id="source-r01"></a>

### R01 — Onboarding — Human Interface Guidelines

**Éditeur/auteurs :** Apple · **Nature :** `platform_guidance`.

**Date/version :** Mise à jour indiquée : 2024-06-10 · **Consultation :** 2026-09-26.

**Matériau lu :** Texte officiel via endpoint documentaire JSON.

**Apport limité de la source.** Apprentissage par action, aide près de la tâche, tutoriel facultatif lorsqu’il est approprié et configuration non essentielle différée. Une permission intervient au besoin de la fonction, sauf prérequis réellement indispensable.

**Limites.** Recommandation de plateforme, pas mesure du taux d’activation de Kollio. Le caractère facultatif ne supprime pas les consentements ou prérequis obligatoires.

[Consulter la source R01](https://developer.apple.com/design/human-interface-guidelines/onboarding)

<a id="source-r02"></a>

### R02 — Discoverable design — WWDC21

**Éditeur/auteurs :** Apple · **Nature :** `platform_guidance`.

**Date/version :** 2021 · **Consultation :** 2026-09-26.

**Matériau lu :** Transcription officielle.

**Apport limité de la source.** Hiérarchiser les fonctions visibles, désambiguïser avec des mots, suggérer les gestes et fournir une voie visible équivalente. La recherche de minimalisme peut rendre une interface moins découvrable.

**Limites.** Les exemples portent notamment sur une app iOS illustrative. Aucun essai de Kollio ni preuve que toute app doit posséder une tab bar.

[Consulter la source R02](https://developer.apple.com/videos/play/wwdc2021/10126/)

<a id="source-r03"></a>

### R03 — Make features discoverable with TipKit — WWDC23

**Éditeur/auteurs :** Apple · **Nature :** `implementation_documentation`.

**Date/version :** 2023 · **Consultation :** 2026-09-26.

**Matériau lu :** Transcription et exemples officiels.

**Apport limité de la source.** TipKit associe des conseils à des règles et événements, contrôle leur fréquence et permet leur invalidation. La présentation peut être testée sans attendre les conditions d’usage.

**Limites.** Les noms d’API d’une session ancienne peuvent différer du SDK installé. Le framework ne décide pas à lui seul de la politique d’attention de Kollio.

[Consulter la source R03](https://developer.apple.com/videos/play/wwdc2023/10229/)

<a id="source-r04"></a>

### R04 — Customize feature discovery with TipKit — WWDC24

**Éditeur/auteurs :** Apple · **Nature :** `implementation_documentation`.

**Date/version :** 2024 · **Consultation :** 2026-09-26.

**Matériau lu :** Transcription et exemples officiels.

**Apport limité de la source.** La session décrit notamment des groupes de conseils ordonnés et leur invalidation quand l’action correspondante est réalisée.

**Limites.** Les groupes ne justifient pas de transformer toutes les fonctions en parcours imposé. Vérifier disponibilité et comportement dans le SDK cible.

[Consulter la source R04](https://developer.apple.com/videos/play/wwdc2024/10070/)

<a id="source-r05"></a>

### R05 — Motion — Human Interface Guidelines

**Éditeur/auteurs :** Apple · **Nature :** `platform_guidance`.

**Date/version :** Mise à jour indiquée : 2025-09-09 · **Consultation :** 2026-09-26.

**Matériau lu :** Texte officiel via JSON.

**Apport limité de la source.** Mouvement intentionnel, bref et précis ; information non portée uniquement par l’animation ; possibilité de l’interrompre. Les réponses des composants système varient selon le mode d’entrée.

**Limites.** Ne pas transformer les exemples de jeu ou visionOS en seuils universels macOS. Les durées Kollio sont des décisions à tester.

[Consulter la source R05](https://developer.apple.com/design/human-interface-guidelines/motion)

<a id="source-r06"></a>

### R06 — Designing Fluid Interfaces — WWDC18

**Éditeur/auteurs :** Apple · **Nature :** `platform_guidance`.

**Date/version :** 2018 · **Consultation :** 2026-09-26.

**Matériau lu :** Transcription officielle, passages interaction continue.

**Apport limité de la source.** Les interfaces fluides conservent la continuité et permettent de reprendre la main pendant les transitions. La réponse à l’interaction ne devrait pas être suspendue jusqu’à la fin d’une chorégraphie.

**Limites.** Présentation de conception, pas benchmark de performances ni prescription d’un moteur de canvas particulier.

[Consulter la source R06](https://developer.apple.com/videos/play/wwdc2018/803/)

<a id="source-r07"></a>

### R07 — Animate with springs — WWDC23

**Éditeur/auteurs :** Apple · **Nature :** `implementation_documentation`.

**Date/version :** 2023 · **Consultation :** 2026-09-26.

**Matériau lu :** Transcription officielle.

**Apport limité de la source.** Les ressorts permettent de représenter continuité et vitesse lors d’un changement de cible. La durée perceptuelle diffère du temps de stabilisation mathématique. Un ressort n’implique pas nécessairement un rebond visible.

**Limites.** Ne pas utiliser une fin d’animation comme validation de sauvegarde. Les coefficients doivent être testés, pas copiés d’un autre composant.

[Consulter la source R07](https://developer.apple.com/videos/play/wwdc2023/10158/)

<a id="source-r08"></a>

### R08 — Progress indicators — Human Interface Guidelines

**Éditeur/auteurs :** Apple · **Nature :** `platform_guidance`.

**Date/version :** Mise à jour indiquée : 2023-09-12 · **Consultation :** 2026-09-26.

**Matériau lu :** Texte officiel via JSON.

**Apport limité de la source.** Distinguer une progression mesurable d’une activité indéterminée, rester exact, maintenir un emplacement cohérent et permettre l’arrêt lorsque pertinent. Les descriptions sont utiles si elles ajoutent un contexte réel.

**Limites.** La recommandation macOS évite les libellés redondants de spinners. Un pourcentage arbitraire de génération n’est pas une mesure.

[Consulter la source R08](https://developer.apple.com/design/human-interface-guidelines/progress-indicators)

<a id="source-r09"></a>

### R09 — Mobile Tutorials: Wasted Effort or Efficiency Boost?

**Éditeur/auteurs :** Nielsen Norman Group · **Nature :** `empirical_study`.

**Date/version :** 2020-03-08 · **Consultation :** 2026-09-26.

**Matériau lu :** Article original : méthode, résultats et limites.

**Apport limité de la source.** Étude distante entre groupes : 70 participants, quatre applications iPhone relativement simples. Réussite 91 % avec tutoriel contre 94 % sans, différence non significative. Facilité perçue moindre avec tutoriel (4,92 contre 5,49 sur 7 ; p=0,047). Pas de différence significative de temps de tâche ; le temps de lecture du tutoriel est exclu de cette mesure.

**Limites.** Participants déjà utilisateurs iOS ; tâches simples ; tutoriel en cartes. Ne démontre ni l’inutilité de toute formation ni la supériorité d’une variante Kollio.

[Consulter la source R09](https://www.nngroup.com/articles/mobile-tutorials/)

<a id="source-r10"></a>

### R10 — Onboarding Tutorials vs. Contextual Help

**Éditeur/auteurs :** Nielsen Norman Group · **Nature :** `practice_synthesis`.

**Date/version :** 2023-02-12 · **Consultation :** 2026-09-26.

**Matériau lu :** Article.

**Apport limité de la source.** L’article distingue aide poussée et aide contextuelle, les coûts d’interruption et de mémorisation, et les situations où un tutoriel séparé peut rester utile.

**Limites.** Conseils professionnels et exemples ; pas une estimation causale de rétention pour Kollio.

[Consulter la source R10](https://www.nngroup.com/articles/onboarding-tutorials/)

<a id="source-r11"></a>

### R11 — Progressive Disclosure

**Éditeur/auteurs :** Nielsen Norman Group · **Nature :** `practice_synthesis`.

**Date/version :** 2006-12-03 · **Consultation :** 2026-09-26.

**Matériau lu :** Article.

**Apport limité de la source.** La divulgation progressive réserve les options rares ou avancées à une seconde couche tout en gardant les principales accessibles.

**Limites.** Principe ancien utile, non seuil scientifique du nombre de boutons. Cacher une action fréquente dans un menu sans indice ne l’applique pas correctement.

[Consulter la source R11](https://www.nngroup.com/articles/progressive-disclosure/)

<a id="source-r12"></a>

### R12 — 8 Design Guidelines for Complex Applications

**Éditeur/auteurs :** Nielsen Norman Group · **Nature :** `practice_synthesis`.

**Date/version :** 2020-11-08 · **Consultation :** 2026-09-26.

**Matériau lu :** Article.

**Apport limité de la source.** Apprendre en faisant sans dommages, faciliter les parcours non linéaires, garder les traces de travail et réduire le bruit sans retirer la capacité.

**Limites.** La cible inclut des outils spécialisés complexes. Kollio doit adapter ces conseils à des utilisateurs métier non experts du canvas.

[Consulter la source R12](https://www.nngroup.com/articles/complex-application-design/)

<a id="source-r13"></a>

### R13 — Onboarding and Connecting Smart Devices

**Éditeur/auteurs :** Nielsen Norman Group · **Nature :** `practice_synthesis`.

**Date/version :** 2025-09-12 · **Consultation :** 2026-09-26.

**Matériau lu :** Article.

**Apport limité de la source.** Les connexions d’objets physiques peuvent demander des étapes visuelles explicites ; reconnexion et erreurs doivent être conçues comme de vrais parcours.

**Limites.** Contre-exemple à « aucun wizard ». Il ne prouve pas qu’un éditeur de documents doive imposer un onboarding en étapes.

[Consulter la source R13](https://www.nngroup.com/articles/smart-device-onboarding/)

<a id="source-r14"></a>

### R14 — Response Times: The 3 Important Limits

**Éditeur/auteurs :** Nielsen Norman Group · **Nature :** `historical_heuristic`.

**Date/version :** 1993, page consultée actuelle · **Consultation :** 2026-09-26.

**Matériau lu :** Article.

**Apport limité de la source.** Repères historiques de perception de la réponse et d’attente autour de 0,1 s, 1 s et 10 s.

**Limites.** Heuristiques, non garanties pour toute tâche ou population. Ne pas ajouter de délai artificiel ni un tutoriel automatiquement après dix secondes.

[Consulter la source R14](https://www.nngroup.com/articles/response-times-3-important-limits/)

<a id="source-r15"></a>

### R15 — Guidelines for Human-AI Interaction

**Éditeur/auteurs :** Microsoft Research / CHI · **Nature :** `research_framework`.

**Date/version :** 2019 · **Consultation :** 2026-09-26.

**Matériau lu :** Résumé primaire de publication.

**Apport limité de la source.** 18 recommandations évaluées en plusieurs étapes, dont une étude avec 49 praticiens sur 20 produits enrichis par l’IA.

**Limites.** Pertinence d’un cadre, pas preuve que tous les principes améliorent chaque métrique de chaque LLM actuel. Article complet non réanalysé ici.

[Consulter la source R15](https://www.microsoft.com/en-us/research/publication/guidelines-for-human-ai-interaction/)

<a id="source-r16"></a>

### R16 — Guidelines for Human-AI Interaction — HAX Toolkit

**Éditeur/auteurs :** Microsoft · **Nature :** `practice_framework`.

**Date/version :** Page non datée, consultée le 2026-09-26 · **Consultation :** 2026-09-26.

**Matériau lu :** Page officielle et structure de la bibliothèque.

**Apport limité de la source.** Les situations sont organisées au premier contact, pendant l’usage, lors des erreurs et dans la durée.

**Limites.** Cadre d’analyse, pas SDK de Kollio ni machine déterminant automatiquement la confiance à afficher.

[Consulter la source R16](https://www.microsoft.com/en-us/haxtoolkit/ai-guidelines/)

<a id="source-r17"></a>

### R17 — To Trust or to Think: Cognitive Forcing Functions Can Reduce Overreliance on AI

**Éditeur/auteurs :** Buçinca, Malaya, Gajos · **Nature :** `empirical_study`.

**Date/version :** 2021-02-19 · **Consultation :** 2026-09-26.

**Matériau lu :** Résumé primaire des auteurs sur arXiv.

**Apport limité de la source.** Dans une expérience N=199, les interventions étudiées réduisent la surconfiance par rapport à des approches explicatives simples, avec un coût de satisfaction et des bénéfices variables selon la motivation cognitive.

**Limites.** Contexte expérimental spécifique ; pas permission de mettre de la friction partout. Résumé consulté, pas reproduction ni relecture exhaustive des données.

[Consulter la source R17](https://arxiv.org/abs/2102.09692)

<a id="source-r18"></a>

### R18 — Animated Transitions in Statistical Data Graphics

**Éditeur/auteurs :** Heer, Robertson / UW IDL · **Nature :** `empirical_study`.

**Date/version :** 2007 · **Consultation :** 2026-09-26.

**Matériau lu :** Page primaire, résumé et légende.

**Apport limité de la source.** Deux expériences contrôlées sur des graphiques statistiques rapportent des bénéfices perceptifs de certaines transitions ; la page illustre un changement en étapes.

**Limites.** Graphiques statistiques, pas toutes les transformations de texte ou tous les canvas. Pas de timings concurrents déduits de cette étude.

[Consulter la source R18](https://idl.uw.edu/papers/animated-transitions)

<a id="source-r19"></a>

### R19 — Measuring the User Experience on a Large Scale

**Éditeur/auteurs :** Rodden, Hutchinson, Fu / Google Research · **Nature :** `measurement_framework`.

**Date/version :** CHI 2010 · **Consultation :** 2026-09-26.

**Matériau lu :** Résumé primaire.

**Apport limité de la source.** Le cadre HEART relie objectifs utilisateurs, signaux et métriques plutôt que de choisir uniquement les mesures faciles à collecter.

**Limites.** Cadre méthodologique, pas référence universelle de taux d’activation ou de rétention ; résumé consulté.

[Consulter la source R19](https://research.google/pubs/measuring-the-user-experience-on-a-large-scale-user-centered-metrics-for-web-applications/)

<a id="source-r20"></a>

### R20 — Sharing boards and inviting collaborators — Start view

**Éditeur/auteurs :** Miro · **Nature :** `product_documentation`.

**Date/version :** Version web consultée le 2026-09-26 · **Consultation :** 2026-09-26.

**Matériau lu :** Section Start view de l’aide officielle.

**Apport limité de la source.** Un éditeur autorisé à partager peut définir la zone d’arrivée des nouveaux invités ; sans ce réglage, le tableau complet est montré.

**Limites.** Fonction documentée, pas expérience d’onboarding testée ici. Une zone d’arrivée n’est pas une restriction d’accès aux autres objets.

[Consulter la source R20](https://help.miro.com/hc/en-us/articles/360017730813-Sharing-boards-and-inviting-collaborators)

<a id="source-r21"></a>

### R21 — Get started with Freeform on Mac

**Éditeur/auteurs :** Apple Support · **Nature :** `product_documentation`.

**Date/version :** Guide courant consulté le 2026-09-26 · **Consultation :** 2026-09-26.

**Matériau lu :** Guide officiel.

**Apport limité de la source.** Création et ajout passent par des commandes visibles ; des scènes permettent de retrouver et présenter des zones du tableau.

**Limites.** Documentation et non manipulation de l’application. Ne pas copier la barre complète dans Kollio par simple analogie.

[Consulter la source R21](https://support.apple.com/guide/freeform/get-started-frfm85d6f7b58/mac)

<a id="source-r22"></a>

### R22 — Move items on a Freeform board on Mac

**Éditeur/auteurs :** Apple Support · **Nature :** `product_documentation`.

**Date/version :** Guide courant consulté le 2026-09-26 · **Consultation :** 2026-09-26.

**Matériau lu :** Guide officiel.

**Apport limité de la source.** La documentation décrit déplacement d’éléments, ajustement de vue et espace-glisser pour déplacer le canvas.

**Limites.** Un geste documenté n’exclut pas la nécessité d’une autre entrée accessible. Pas de mesure du comportement physique sur le Mac du porteur.

[Consulter la source R22](https://support.apple.com/guide/freeform/move-items-frfm220e044a/mac)

<a id="source-r23"></a>

### R23 — Accessibility — tldraw SDK

**Éditeur/auteurs :** tldraw · **Nature :** `implementation_documentation`.

**Date/version :** Page non datée, consultée le 2026-09-26 · **Consultation :** 2026-09-26.

**Matériau lu :** Documentation SDK.

**Apport limité de la source.** Annonce des sélections, navigation clavier des formes, descriptions personnalisables et réglages de mouvement sont documentés.

**Limites.** Capacités du SDK web ; elles ne deviennent pas automatiquement les comportements de Kollio SwiftUI. Pas de benchmark ni de test utilisateur ici.

[Consulter la source R23](https://tldraw.dev/sdk-features/accessibility)

<a id="source-r24"></a>

### R24 — Sandbox vault

**Éditeur/auteurs :** Obsidian · **Nature :** `product_documentation`.

**Date/version :** Page non datée, consultée le 2026-09-26 · **Consultation :** 2026-09-26.

**Matériau lu :** Aide officielle.

**Apport limité de la source.** Un coffre séparé permet l’exploration et le diagnostic sans altérer le coffre habituel ; le guide précise une différence de disponibilité mobile.

**Limites.** Un bac à sable n’est pas une preuve de valeur sur le travail réel. Ne pas rendre une démo obligatoire à la place du contexte utilisateur.

[Consulter la source R24](https://help.obsidian.md/sandbox)

<a id="source-r25"></a>

### R25 — Understanding SC 1.4.13: Content on Hover or Focus

**Éditeur/auteurs :** W3C WAI · **Nature :** `accessibility_explanation`.

**Date/version :** WCAG 2.2, page courante · **Consultation :** 2026-09-26.

**Matériau lu :** Explication du critère AA.

**Apport limité de la source.** Le contenu additionnel au survol/focus doit notamment pouvoir rester atteignable, persister pendant son usage et être écarté dans les conditions du critère.

**Limites.** Page Understanding informative ; application normative au web. Sert de protocole de test analogue sur Mac, pas de certification native automatique.

[Consulter la source R25](https://www.w3.org/WAI/WCAG22/Understanding/content-on-hover-or-focus.html)

<a id="source-r26"></a>

### R26 — Understanding SC 2.5.7: Dragging Movements

**Éditeur/auteurs :** W3C WAI · **Nature :** `accessibility_explanation`.

**Date/version :** WCAG 2.2, page courante · **Consultation :** 2026-09-26.

**Matériau lu :** Explication du critère AA.

**Apport limité de la source.** Une alternative à pointeur unique sans drag est requise dans le champ du critère. Une alternative au clavier ne suffit pas à elle seule.

**Limites.** Web, exceptions propres au critère ; les équivalents proposés pour Kollio sont à tester au pointeur et au clavier séparément.

[Consulter la source R26](https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements.html)

<a id="source-r27"></a>

### R27 — Understanding SC 2.3.3: Animation from Interactions

**Éditeur/auteurs :** W3C WAI · **Nature :** `accessibility_explanation`.

**Date/version :** WCAG 2.2, page courante · **Consultation :** 2026-09-26.

**Matériau lu :** Explication du critère AAA.

**Apport limité de la source.** Les animations de mouvement déclenchées par interaction doivent pouvoir être désactivées sauf lorsqu’essentielles dans le champ du critère.

**Limites.** Ce critère est AAA, pas une obligation AA générale. Ne pas confondre animation facultative et suppression du feedback ou du suivi direct.

[Consulter la source R27](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html)

<a id="source-r28"></a>

### R28 — Understanding SC 4.1.3: Status Messages

**Éditeur/auteurs :** W3C WAI · **Nature :** `accessibility_explanation`.

**Date/version :** WCAG 2.2, page courante · **Consultation :** 2026-09-26.

**Matériau lu :** Explication du critère AA.

**Apport limité de la source.** Les messages d’état doivent pouvoir être déterminés programmatiquement sans nécessairement recevoir le focus.

**Limites.** La transposition macOS utilise les API natives appropriées ; un rôle ARIA n’est pas une API SwiftUI.

[Consulter la source R28](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html)

<a id="source-r29"></a>

### R29 — Understanding SC 2.5.2: Pointer Cancellation

**Éditeur/auteurs :** W3C WAI · **Nature :** `accessibility_explanation`.

**Date/version :** WCAG 2.2, page courante · **Consultation :** 2026-09-26.

**Matériau lu :** Explication du critère AA.

**Apport limité de la source.** Le critère vise la prévention et la récupération des activations accidentelles au pointeur, avec conditions sur les événements et possibilité d’abandon ou retour.

**Limites.** Pas une interdiction des gestes continus. La décision de commit de Kollio reste décrite par action.

[Consulter la source R29](https://www.w3.org/WAI/WCAG22/Understanding/pointer-cancellation.html)

<a id="source-r30"></a>

### R30 — Add personality to your app through UX writing — WWDC24

**Éditeur/auteurs :** Apple · **Nature :** `platform_guidance`.

**Date/version :** 2024 · **Consultation :** 2026-09-26.

**Matériau lu :** Transcription officielle.

**Apport limité de la source.** Distinguer une voix cohérente d’un ton ajusté à la situation. Une erreur demande davantage de clarté et d’aide qu’un message de célébration.

**Limites.** Les textes FR/EN de ce pack sont originaux. Une session de writing n’établit pas leurs taux de compréhension.

[Consulter la source R30](https://developer.apple.com/videos/play/wwdc2024/10140/)

<a id="source-r31"></a>

### R31 — Understanding SC 2.4.11: Focus Not Obscured (Minimum)

**Éditeur/auteurs :** W3C WAI · **Nature :** `accessibility_explanation`.

**Date/version :** WCAG 2.2, page courante · **Consultation :** 2026-09-26.

**Matériau lu :** Explication du critère AA.

**Apport limité de la source.** Le composant focalisé ne doit pas être entièrement masqué par du contenu créé par l’auteur dans le champ du critère.

**Limites.** Le pack vise une lisibilité plus forte du contrôle actif quand possible ; ne pas attribuer cette préférence complète au minimum normatif.

[Consulter la source R31](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html)

<a id="source-r32"></a>

### R32 — Understanding SC 1.4.3: Contrast (Minimum)

**Éditeur/auteurs :** W3C WAI · **Nature :** `accessibility_explanation`.

**Date/version :** WCAG 2.2, page courante · **Consultation :** 2026-09-26.

**Matériau lu :** Explication du critère AA.

**Apport limité de la source.** Référence 4,5:1 pour texte courant et exceptions du critère ; considérer le contraste du résultat affiché, pas uniquement un token avant composition.

**Limites.** Mesure couleur seule insuffisante pour certifier toute l’application ; fonds translucides et rendu réel doivent être examinés.

[Consulter la source R32](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)

<a id="source-r33"></a>

### R33 — Tooltip Pattern — ARIA Authoring Practices

**Éditeur/auteurs :** W3C WAI · **Nature :** `implementation_guidance`.

**Date/version :** Page courante, statut de pattern à vérifier · **Consultation :** 2026-09-26.

**Matériau lu :** Page APG.

**Apport limité de la source.** Le tooltip décrit une information additionnelle ; il ne reçoit pas le focus. Un contenu comportant des éléments focalisables demande un autre pattern, par exemple une surface non modale adaptée.

**Limites.** Pattern APG web, indiqué en cours de travail sur la page ; ne pas l’utiliser comme justification d’un menu interactif caché dans un tooltip natif.

[Consulter la source R33](https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/)

## Références volontairement non utilisées comme preuve

Une page ACM inaccessible et une aide Raycast inaccessible ne servent pas de base à des résultats chiffrés ou à une description de parcours. Les galeries de marketing et résumés secondaires ne sont pas utilisés pour annoncer un effet causal. Les interfaces Figma/Miro/Freeform déjà étudiées dans l’atlas ne sont pas réputées toutes réinstallées dans cette recherche.

« M26 » reste sans identification fiable. Il faut son lien exact pour l’ajouter au corpus. Cela ne bloque ni les contrats d’onboarding ni les tests de reprise et de contrôle.

## Limites générales

Pas de recrutement, pas de test natif, pas d’évaluation du modèle Apple, pas de modification du backend et pas de mesure des timings concurrents. Les captures des fichiers HTML, si présentes, documentent uniquement le rendu du livre ou du banc. L’état exact des API devra être recontrôlé au moment de l’implémentation. Les essais préparés ne deviennent pas des résultats parce qu’ils sont décrits dans le registre.



---

<a id="ch-25"></a>
