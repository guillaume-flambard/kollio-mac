# 19 — Dix protocoles pour choisir les patterns sans intuition seule

## Question avant instrument

On ne peut pas conclure « meilleur onboarding » parce qu’une variante a une animation plus plaisante. Définir une tâche, un état d’entrée, une erreur possible et une observation attendue. Séparer réussite, temps, compréhension, préférence et confiance. La qualité perçue ne remplace pas la capacité à conserver son travail.

Pour une première recherche formative, viser par exemple six à huit personnes ayant des habitudes variées du Mac et des canvas. Ce nombre est une proposition logistique, pas une taille garantissant saturation ou significativité. Inclure des personnes non développeuses pertinentes pour le produit. Les besoins d’accessibilité nécessitent des participants et méthodes adaptés, pas uniquement des développeurs testant sans souris.

Une comparaison quantitative exige un calcul de puissance selon la métrique, la variance attendue et l’effet utile recherché. Ne pas attribuer un pourcentage d’amélioration à un test de cinq amis. En petit effectif, documenter les incidents, séquences, verbatims autorisés et divergences plutôt qu’une moyenne surinterprétée.

## Méthode proposée

Utiliser des tâches équivalentes et contrebalancer l’ordre des variantes. Le même participant ne découvre pas deux fois une interface comme débutant ; cette contamination doit être considérée. Pour les tâches de timing, la verbalisation simultanée peut changer le temps : préférer une courte rétrospective, ou présenter la mesure comme issue d’un protocole think-aloud.

Ne pas intervenir au premier silence. Préparer une gradation d’aide et marquer chaque intervention du facilitateur. Une réussite accompagnée ne devient pas autonome dans le tableau de résultats. Demander une prédiction avant un clic lorsqu’on teste le sens d’un bouton, puis demander l’explication de l’état après l’action.

Limiter les données à des situations synthétiques. Informer sur l’enregistrement, recueillir l’accord, permettre d’arrêter et fixer la rétention. Aucune session n’est nécessairement enregistrée si des notes suffisent. Les profils ne servent pas à inférer des traits personnels sensibles.

Les protocoles ci-dessous sont préparés, **non exécutés** dans cette livraison. Chaque seuil de recette native doit être associé à une preuve réelle, pas à une réussite du simulateur HTML.

### EXP-01 — Champ seul ou exemple facultatif

**Hypothèse.** Un exemple secondaire peut réduire la page blanche sans imposer un contexte.

**Variantes :** Invitation + champ / Même invitation + lien vers un exemple synthétique.

**Tâche.** Démarrer un document sur une situation choisie par le participant, puis retrouver ses mots.

**Mesures :** temps jusqu’au premier contexte personnel, abandons observés et raison, utilité déclarée de l’exemple.

**Garde-fous.** Pas de différences de modèle ni de couleurs entre variantes ; ne pas remplacer une saisie en cours.

**Règle de décision.** Retenir l’exemple seulement s’il aide au démarrage sans favoriser la confusion avec son propre travail. Petit échantillon : résultat qualitatif, pas uplift garanti.

**V2 :** DOC-02.

### EXP-02 — Statut de proposition avec ou sans conseil

**Hypothèse.** Un label permanent clair peut suffire à enseigner le provisoire.

**Variantes :** Proposition + actions nommées / Même surface + conseil ONB-01 unique.

**Tâche.** Lire un candidat correct et un candidat contenant une erreur synthétique, puis expliquer ce qui appartient au document.

**Mesures :** bonne identification pending/canonique, erreur détectée, interruption perçue, action choisie.

**Garde-fous.** Ne pas récompenser la vitesse d’acceptation ; débriefer la présence volontaire d’une erreur.

**Règle de décision.** Supprimer le conseil s’il n’apporte pas de compréhension. S’il aide seulement certains entrants, adapter au rôle explicite et non à un profil inféré.

**V2 :** AI-07, AI-08.

### EXP-03 — Double-clic : convention actuelle ou édition

**Hypothèse.** Un double-clic sur un texte peut créer une attente d’édition.

**Variantes :** V2 : double-clic Explore / Prototype isolé : double-clic Edit avec Explore visible.

**Tâche.** Corriger une faute puis explorer une alternative, ordre contrebalancé.

**Mesures :** explorations involontaires, temps et erreurs de saisie, prédiction avant action.

**Garde-fous.** Ne pas modifier le comportement production pendant l’étude ; même visibilité du bouton Explorer.

**Règle de décision.** Décision explicite DR-01 seulement après observation. Ne pas départager sur goût esthétique seul.

**V2 :** CAN-04, AI-03.

### EXP-04 — Commande nommée ou icône

**Hypothèse.** Les verbes peuvent réduire les erreurs de sens malgré une surface légèrement plus grande.

**Variantes :** Icônes seules avec tooltips / Verbes courts et icônes secondaires.

**Tâche.** Ajouter une information, modifier une phrase et rejeter un candidat.

**Mesures :** prédiction correcte, mauvais clics, lectures de tooltips, retours arrière.

**Garde-fous.** Tester français et anglais avec largeur adaptée ; ne pas avantager artificiellement une variante tronquée.

**Règle de décision.** Préférer les libellés si la précision s’améliore, même si la composition occupe quelques pixels de plus.

**V2 :** CAN-02, CTX-01.

### EXP-05 — Animation d’ajout versus modification stable

**Hypothèse.** Une animation locale peut aider à suivre l’origine ; le diff statique peut aider à comparer des mots.

**Variantes :** Branche ajoutée avec transition locale / Même ajout sans transition / Texte modifié avec avant/après stable / Texte modifié avec simple fondu expérimental.

**Tâche.** Identifier l’origine d’un nouvel élément puis repérer une négation changée dans un texte.

**Mesures :** précision des réponses, temps de lecture, préférence distincte, inconfort déclaré.

**Garde-fous.** Tâches comparables, ordre contrebalancé ; personnes sensibles au mouvement peuvent refuser sans justification.

**Règle de décision.** Choisir par type de transformation et non un vainqueur universel. Un effet apprécié mais moins compréhensible n’est pas retenu pour la lecture critique.

**V2 :** CAN-08, AI-07.

### EXP-06 — Attente et possibilité d’agir

**Hypothèse.** Un feedback local exact peut préserver le contrôle pendant une latence variable.

**Variantes :** Indicateur local + annuler / Même indicateur avec libellé contextuel minimal.

**Tâche.** Lancer une demande simulée de durée connue pour le banc, travailler ailleurs puis annuler une seconde.

**Mesures :** clics répétés, compréhension traitement/enregistré, réussite d’annulation, perte de focus.

**Garde-fous.** Latences simulées identiques entre variantes ; aucun pourcentage mensonger ; aucune durée présentée comme benchmark Apple.

**Règle de décision.** Conserver le minimum qui informe sans annonces redondantes. Aucun résultat tardif ne doit devenir actif après annulation.

**V2 :** AI-09.

### EXP-07 — Invité : vue générale ou ancre demandée

**Hypothèse.** Une ancre d’arrivée peut faciliter l’orientation si le contexte reste accessible.

**Variantes :** Fit de tout le document / Vue liée avec motif et accès au contexte.

**Tâche.** Retrouver une décision, sa justification et indiquer ce que le rôle autorise.

**Mesures :** temps pour identifier la tâche, mauvaise branche lue, compréhension du rôle, retour au contexte.

**Garde-fous.** Même document et droits ; ne pas ouvrir une région non autorisée pour rendre la démo plus utile.

**Règle de décision.** Retenir l’ancre si elle aide la tâche et ne cache pas les informations nécessaires à sa compréhension.

**V2 :** TEAM-03, CAN-09.

### EXP-08 — Comprendre privé, publié et retenu

**Hypothèse.** Des labels d’état associés aux actions peuvent limiter les erreurs de partage.

**Variantes :** États actuels / Libellés explicites et prévisualisation de publication.

**Tâche.** Équipe de deux personnes fictives : préparer, publier, réviser puis accepter une proposition.

**Mesures :** anticipation de ce que voit l’autre, tentatives de mauvais rôle, acceptation de version périmée, confiance déclarée.

**Garde-fous.** Aucune donnée réelle ; serveur de test pour les effets réseau ; présence non simulée en douce.

**Règle de décision.** Un seul écrasement silencieux ou accès illégitime est un défaut bloquant, pas une moyenne compensée par les bons cas.

**V2 :** TEAM-07, TEAM-08, TEAM-09.

### EXP-09 — Navigation sans drag et sans clavier

**Hypothèse.** Une alternative par clics peut permettre des tâches impossibles avec un drag continu.

**Variantes :** Contrôles actuels / Relier puis cible et Déplacer ici explicites.

**Tâche.** Créer un lien et déplacer une idée avec le pointeur, sans maintien du bouton ni raccourci clavier.

**Mesures :** réussite, nombre de reprises, erreurs de cible, fatigue ou gêne rapportée.

**Garde-fous.** Ne pas demander d’imiter un handicap ; recruter si possible des utilisateurs des modalités pertinentes. Clavier et VoiceOver ont leurs propres sessions.

**Règle de décision.** La variante doit rester utilisable indépendamment du clavier. Une alternative difficile à découvrir ne satisfait pas le besoin fonctionnel.

**V2 :** CAN-03, CAN-06, CAN-10.

### EXP-10 — Rappel utile ou interruption en trop

**Hypothèse.** Limiter les conseils devrait réduire les interruptions sans supprimer l’aide volontaire.

**Variantes :** Aucun conseil automatique, aide disponible / Coordinateur limité proposé.

**Tâche.** Plusieurs petites sessions espacées, avec reprise, demande d’aide volontaire et désactivation des conseils.

**Mesures :** aides répétées indésirables, tâches bloquées, rappel compris, réussite après retour.

**Garde-fous.** Pas de réactivation après refus ; pas de collecte du texte privé ni de suivi individuel opaque.

**Règle de décision.** Ne pas généraliser une étude de première session à la rétention. Conserver la version la plus sobre compatible avec la réussite observée.

**V2 :** DOC-08, TEAM-11.



---

<a id="ch-20"></a>

# 20 — Mesurer une première valeur, pas une série de clics

## Un signal d’action n’est pas une preuve de compréhension

Le framework HEART et la démarche objectifs → signaux → métriques fournissent un cadre utile pour décider ce qu’on mesure. Nous l’appliquons ici au produit sans revendiquer un seuil universel d’activation. Les catégories servent à structurer une question, pas à justifier une collecte illimitée. [R19](#source-r19)

Kollio vise une première valeur maîtrisée : un résultat utile que la personne comprend et sait reprendre. La télémétrie peut mesurer qu’un objet a été créé, une proposition traitée et un document rouvert. Elle ne peut pas conclure à elle seule que la personne a compris la différence entre hypothèse et preuve. Cette compréhension exige une recherche utilisateur ou un retour explicite.

## Trois horloges indépendantes

| Horloge | Début / fin | Utilité | Confusion à éviter |
|---|---|---|---|
| Feedback | Action → premier retour local | Repérer une interface qui paraît ne pas répondre | Ne pas l’appeler temps de résultat IA |
| Résultat | Demande → candidat exploitable ou réponse claire | Quantifier attente et récupération | Ne pas inclure un résultat invalide comme succès |
| Valeur | Entrée dans la tâche → résultat utile compris | Observer l’apprentissage et le travail | Ne pas déduire la compréhension d’un clic Retenir |

Le temps de restauration et de lecture compte selon la tâche. Indiquer si l’on inclut les écrans d’aide dans la mesure. Un protocole qui exclut les quinze minutes de formation ne peut pas conclure sur le temps total jusqu’à la première valeur.

## Événements minimaux proposés

`context_created`, `context_edited`, `proposal_shown`, `proposal_reviewed`, `proposal_kept`, `proposal_set_aside`, `branch_reopened`, `document_saved`, `document_restored`, `tip_presented`, `tip_dismissed`, `tip_action_performed`, `request_failed`, `request_cancelled`.

Les noms sont des exemples de contrats d’observation. L’application doit réutiliser ses événements existants et ne pas confondre un événement UI avec la preuve d’un commit serveur. Les champs sont limités à la version produit, mode, durée disponible et statut nécessaire. Le titre privé d’un document et le contenu des prompts ne sont pas requis pour savoir qu’une annulation a échoué.

L’état local de coaching peut fonctionner sans analytics externe. Exporter volontairement un rapport de test est distinct de téléverser automatiquement l’usage. Les identifiants de session doivent être limités au périmètre nécessaire ; aucun enrichissement publicitaire ne fait partie de cette recherche.

## Mesures de contrôle et garde-fous

Une baisse du taux d’acceptation peut être positive si les utilisateurs détectent davantage d’erreurs IA. Compter séparément la qualité du candidat, la compréhension de son statut et le choix final. Une hausse du temps de session peut signifier une exploration profonde, une interface confuse ou une génération trop lente ; elle n’a pas une interprétation automatique.

Les garde-fous bloquants sont des événements tels qu’une perte de texte, une publication privée non voulue, une acceptation de mauvaise version ou une proposition tardive appliquée au mauvais document. Ne pas les diluer dans une note moyenne d’esthétique. Documenter la gravité, la reproductibilité et la récupération.

Pour les conseils, mesurer aussi les suppressions : non montré parce qu’une erreur était active, ancre hors écran, préférence de refus, budget atteint. Ces résultats prouvent que la politique sait se taire ; ils ne sont pas des opportunités perdues de rétention.

## Interdictions d’interprétation

Ne pas annoncer que « 91 % des gens n’ont pas besoin d’onboarding » à partir d’une étude particulière. Ne pas prétendre qu’un temps de deux minutes est une norme Apple. Ne pas présenter un score d’engagement comme un signe de bien-être ou de compétence. Ne pas attribuer un changement de chiffre à un design lorsque modèle, population et fonctionnalité ont changé simultanément.

Le rapport final d’une expérience doit montrer les conditions, les exclusions, les incertitudes et les cas négatifs, pas seulement la capture de la variante gagnante.



---

<a id="ch-21"></a>
