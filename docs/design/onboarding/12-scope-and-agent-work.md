# 21 — Raccordement au V2, arbitrages et travail de l’agent

## Une référence ciblée plutôt qu’un nouveau master prompt

Le cahier V2 définit la fonction et sa sémantique. L’atlas V1 définit la grammaire générale du canvas. Ce livre approfondit onboarding, découverte, retour, feedback et interruption. Il ne remplace ni le document partagé ni les schémas du backend. Les identifiants PAT/ONB/MIC/EXP complètent les DOC/CAN/CTX/AI/DEC/TEAM/STU du V2.

L’agent lit le contrat de la fonction active puis seulement les patterns et microcontrats qui s’y rattachent. Charger tous les chapitres pour corriger un tooltip recréerait précisément la surcharge de sessions que le projet cherche à éviter. Le registre des correspondances sert à cette sélection, pas à ouvrir une nouvelle application de gestion.

## Ce qu’on peut préciser sans changer le sens du V2

Maintenir les actions atteignables après sélection ; ne pas faire disparaître une erreur active ; conserver le draft ; rendre le statut provisoire lisible ; respecter les préférences d’aide ; séparer sauvegarde et synchronisation ; ne pas mélanger la fin d’une animation avec une réussite métier ; ne pas voler la caméra ; présenter la version effectivement revue.

Ces changements doivent encore être vérifiés dans le code courant. Une spécification n’est pas la preuve qu’un défaut existe toujours. L’agent utilise `CONTINUE.md` et `known-limitations.md`, compile et observe avant de réimplémenter une correction ancienne.

## Ce qui reste une proposition à valider

Le double-clic Edit à la place de Explore est un amendement expérimental à DR-01, pas une instruction approuvée. Les budgets d’aide — deux apparitions par session, une par conseil — sont des valeurs de départ. Les exemples visibles sur l’écran vide, le seuil de densité au zoom et l’intensité exacte d’un ressort ne deviennent pas des règles universelles.

L’accès aux modalités sans drag précise CAN-03/CAN-06/CAN-10 mais demande une conception locale afin d’éviter des raccourcis concurrents. Ce besoin d’accessibilité ne doit pas être reporté indéfiniment sous prétexte que la fonction drag fonctionne pour le développeur.

## Interfaces frontend minimales proposées

`InteractionContext` fournit les états typing/dragging/pinching/menu/conflict et les cibles visibles. `HelpState` conserve préférences, impressions et événements d’apprentissage. Un `HelpPresentationCoordinator` choisit éventuellement une aide ; il ne modifie jamais le document et n’a pas besoin du backend. N’ajouter ces noms que si les responsabilités n’existent pas déjà sous une autre forme.

Le renderer consomme une sélection d’aide et les états métier existants. Les animations se rattachent à un événement précis avec identifiant stable. Une relecture du body SwiftUI ne relance pas l’apparition et ne compte pas une impression. Les flags transitoires de coaching ne sont pas sérialisés dans `.kollio`.

Pour les fonctions partagées, les retours backend déterminent publié/synchronisé/accepté ; le frontend ne les invente pas. Le serveur n’a pas à recevoir les mouvements de souris ou le texte de toutes les saisies pour que l’aide locale soit contextuelle.

## Livraison minimale cohérente

Commencer par le parcours première saisie → contexte conservé → proposition lisible → choix → reprise. Traiter ensuite la saisie locale, le focus et les erreurs. Puis tester l’entrée invité et le brouillon partagé lorsque TEAM est prêt. Les microanimations arrivent en soutien des comportements, pas comme couche décorative séparée.

Une session de développement produit un résultat observé et un état de reprise précis. Elle n’ajoute pas automatiquement TipKit, une plateforme de tracking et dix plugins si le défaut se corrige par un libellé et une condition de présentation. Une utilisation d’API native se vérifie dans la documentation et le SDK réellement installés.



---

<a id="ch-22"></a>

# 22 — Recette : ce qui est testé ici et ce qui doit l’être sur le Mac

## Les registres sont spécifiés, pas déjà exécutés

Le catalogue d’acceptation fournit des critères reliés aux patterns et aux interactions. Leur statut initial est `notRun`. Les tests automatisés du package livré vérifient la cohérence des références et le comportement d’un simulateur de règles de coaching. Ils ne valident pas la compréhension d’une personne ni le rendu SwiftUI.

Les résultats techniques des artefacts sont consignés séparément dans `research/validation-report.json`. Un test qui vérifie qu’un conseil est supprimé en état typing démontre la règle du simulateur, pas que l’AppKit de Kollio produit correctement cet état. Cette intégration native doit avoir son test et son passage humain.

## Recette native attendue

Vérifier l’app réellement exécutée avec clavier, souris et trackpad. Tester la saisie longue, les retours à la ligne, les changements rapides de cible, une barre locale proche des quatre bords, un zoom éloigné, une demande pendant un drag et une erreur pendant une aide. Ajouter VoiceOver, mouvement réduit, contraste accru et texte français long.

Rejouer les scénarios de perte réseau et version concurrente avec deux sessions clientes indépendantes. Ne pas injecter un état mémoire commun à deux faux utilisateurs puis présenter cela comme preuve de collaboration distante. Une présence fictive doit être explicitement marquée dans les démonstrations de recherche.

## Validation de la politique de conseils

Au minimum : aucune aide pendant frappe, drag, pinch ou menu ; aucune aide dans une fenêtre inactive ; pas de deuxième conseil lorsqu’un autre est présenté ; ancre réelle visible ; rôle autorisé ; limites d’apparition respectées ; conseil refusé non réactivé ; succès observé ne détruit pas l’accès volontaire à l’aide.

Les sessions où aucune aide n’apparaît peuvent être correctes. Ne pas forcer une bulle pour rendre une capture plus attractive. L’état d’apprentissage est local et ne doit pas être copié dans un export partagé. Tester aussi le passage entre deux comptes sans réutiliser les préférences identifiables du compte précédent.

## Captures et mesures honnêtes

Une capture montre un état visuel, pas une animation. Une vidéo montre un comportement observable, pas nécessairement sa cause. Un test de géométrie prouve un calcul, pas l’agrément du geste. Les preuves doivent préciser appareil, OS, version app, mode de modèle et scénario.

Le document présent, ses pages HTML et son laboratoire éventuel ne doivent jamais être présentés comme des captures de Kollio native. Ils n’utilisent ni modèle Apple ni backend. Toute étape impossible dans l’environnement reste notée `blocked` ou `notRun`, jamais transformée en réussite implicite.



---

<a id="ch-23"></a>

# 23 — Matrice fonctionnelle et ordre d’application

## Correspondance ciblée

La matrice ne prétend pas réécrire les 71 fonctions du V2. Elle indique où ce complément apporte un contrat utile. Les autres fonctions conservent leur définition et l’atlas de design précédent. Les identifiants nouveaux ne remplacent pas ceux du produit.

| Fonction V2 | Patterns | Interactions | Conseils | Expériences |
|---|---|---|---|---|
| AI-01 | PAT-01, PAT-07 | MIC-14 | — | — |
| AI-02 | — | MIC-01 | — | — |
| AI-03 | PAT-11, PAT-14, PAT-15 | MIC-06 | — | EXP-03 |
| AI-04 | PAT-24 | — | — | — |
| AI-07 | PAT-05, PAT-21, PAT-22, PAT-29, PAT-35 | MIC-08, MIC-10 | ONB-01 | EXP-02, EXP-05 |
| AI-08 | PAT-05, PAT-17, PAT-21, PAT-26, PAT-33, PAT-34 | MIC-09, MIC-11 | ONB-01 | EXP-02 |
| AI-09 | PAT-03, PAT-07, PAT-19, PAT-25, PAT-33, PAT-36 | MIC-07, MIC-14 | — | EXP-06 |
| AI-10 | PAT-06, PAT-23 | — | — | — |
| AI-11 | PAT-21, PAT-23 | — | ONB-05 | — |
| CAN-01 | PAT-25, PAT-34 | MIC-05 | ONB-04 | — |
| CAN-02 | PAT-05, PAT-10, PAT-11, PAT-12, PAT-13, PAT-20 | MIC-02, MIC-03, MIC-13 | — | EXP-04 |
| CAN-03 | PAT-16 | MIC-04 | — | EXP-09 |
| CAN-04 | PAT-15 | — | ONB-02 | EXP-03 |
| CAN-05 | PAT-17 | — | — | — |
| CAN-06 | PAT-16 | — | — | EXP-09 |
| CAN-08 | PAT-12, PAT-34 | MIC-08 | — | EXP-05 |
| CAN-09 | PAT-09, PAT-18, PAT-36 | MIC-12, MIC-20 | — | EXP-07 |
| CAN-10 | PAT-35, PAT-36 | — | — | EXP-09 |
| CTX-01 | PAT-11, PAT-14, PAT-24 | MIC-06 | ONB-02 | EXP-04 |
| CTX-02 | PAT-06 | — | ONB-06 | — |
| CTX-03 | PAT-23 | — | ONB-06 | — |
| CTX-05 | PAT-22 | — | — | — |
| CTX-06 | PAT-23 | — | ONB-05 | — |
| DEC-02 | PAT-18, PAT-26 | MIC-11, MIC-12 | ONB-03 | — |
| DEC-03 | PAT-04, PAT-17 | MIC-09 | — | — |
| DEC-06 | PAT-18, PAT-26 | — | — | — |
| DOC-01 | PAT-01, PAT-08 | — | — | — |
| DOC-02 | PAT-01, PAT-02, PAT-03, PAT-07 | MIC-01 | — | EXP-01 |
| DOC-03 | PAT-02, PAT-04, PAT-14 | — | — | — |
| DOC-04 | PAT-03, PAT-08, PAT-19, PAT-30, PAT-33 | MIC-15 | ONB-09 | — |
| DOC-05 | PAT-04 | — | — | — |
| DOC-08 | PAT-10, PAT-13, PAT-35 | MIC-13 | — | EXP-10 |
| STU-03 | PAT-20 | — | — | — |
| TEAM-01 | PAT-06 | — | — | — |
| TEAM-02 | PAT-06 | — | — | — |
| TEAM-03 | PAT-09, PAT-27 | MIC-16 | — | EXP-07 |
| TEAM-04 | PAT-09, PAT-20, PAT-27, PAT-31 | MIC-16 | — | — |
| TEAM-05 | PAT-32 | MIC-19 | — | — |
| TEAM-07 | PAT-27, PAT-28 | MIC-17 | ONB-07 | EXP-08 |
| TEAM-08 | PAT-22, PAT-29 | MIC-10, MIC-18 | ONB-08 | EXP-08 |
| TEAM-09 | PAT-28 | MIC-18 | — | EXP-08 |
| TEAM-10 | PAT-30 | — | ONB-09 | — |
| TEAM-11 | PAT-08 | — | ONB-10 | EXP-10 |
| TEAM-12 | PAT-31 | — | — | — |
| TEAM-13 | PAT-32 | MIC-19 | — | — |

## Ordre d’application conseillé

**Premier passage :** PAT-01/03/11/14/21, MIC-01/02/06/08/09. Rendre le contexte durable, les actions claires et le candidat lisible avant de construire des conseils.

**Deuxième passage :** PAT-05/10/12/13/19 et ONB-01/02/03. Installer uniquement les aides dont l’utilité apparaît dans la première observation, avec le droit de se taire.

**Troisième passage :** PAT-16/35/36 et les tests d’accessibilité ; puis les parcours invités/équipe lorsque leurs effets existent réellement.

Ce découpage ne dispense pas de gérer les erreurs dès le départ. Il empêche seulement de créer le système complet de coaching avant de savoir si trois labels corrects suffisent.



---

<a id="ch-24"></a>

# 25 — Décision finale : moins de formation imposée, plus de contrôle visible

## Le meilleur prochain design n’est pas un nouvel onboarding complet

Kollio dispose déjà d’une direction visuelle et d’un cahier fonctionnel. L’amélioration proposée est d’abord une séquence plus intelligible : où écrire, ce qui a été conservé, ce qui est encore proposé, ce que change un clic et comment revenir en arrière. Ce sont les cinq questions à résoudre avant d’ajouter une visite guidée.

Les patterns retenus gardent des portes visibles dans une interface calme. Ils ne demandent pas de replacer un inspecteur permanent autour du canvas. Ils ne transforment pas non plus l’absence de chrome en interdiction d’un libellé utile, d’un dialogue de sécurité ou d’une erreur persistante.

## La signature d’interaction

Une branche naît à son point d’origine. Le texte reste lisible. Une proposition ne se confond pas avec une décision. Une modification peut se comparer immobile. Le document garde les traces que la personne a choisi de conserver. Les commandes sont à portée de clic et de clavier. Le temps d’attente n’est pas maquillé. L’équipe ne voit pas des brouillons qui n’ont pas été publiés.

Le mouvement relie ces états, mais ne les remplace pas. Un effet qui plaît sans faire comprendre reste un effet, pas une preuve de design réussi. Les personnes doivent pouvoir travailler sans mouvement décoratif et sans répéter une formation qu’elles ont refusée.

## Un système qui sait se taire

Une aide bien conçue a une règle de disparition autant qu’une règle d’apparition. Elle respecte les erreurs, la frappe, le focus, le geste et la préférence de la personne. Elle ne revient pas parce que l’équipe veut augmenter son nombre d’impressions. L’aide volontaire reste accessible, même lorsque le coaching automatique est désactivé.

Ce livre livre des hypothèses, des contrats et une recette. L’étape suivante n’est pas d’ajouter toutes ses fiches comme des composants indépendants ; c’est d’observer une boucle complète avec un contexte personnel, de corriger les ambiguïtés prouvées puis de sélectionner les aides réellement nécessaires.

Le critère décisif est simple à formuler : **après un changement, la personne sait encore où elle est, ce qu’elle regarde et ce qu’elle peut faire.**
