# 04 — Sept portes d’entrée, pas un tunnel universel

## L’entrée est une intention, pas une date de création de compte

Le statut « nouvel utilisateur » est trop grossier. Une personne peut être nouvelle dans Kollio mais experte d’un autre canvas ; ancienne dans le produit mais invitée pour la première fois comme lectrice ; propriétaire d’un fichier local mais nouvelle face à la synchronisation. Un champ `hasCompletedOnboarding` ne couvre pas ces situations.

Nous proposons de choisir le parcours à partir de l’action d’entrée et des droits connus. Les préférences ou événements observés servent seulement à ajuster les aides, jamais à autoriser une opération.

| Entrée | Premier contenu utile | Action principale | Ce qu’on ne demande pas |
|---|---|---|---|
| Nouvelle idée locale | Champ de contexte | Explorer ou conserver manuellement | Compte, métier, entreprise, modèle préféré. |
| Document local existant | Vue restaurée | Reprendre le point de travail | Nouvelle présentation des principes. |
| Invitation d’équipe | But, rôle et ancre du document | Lire puis contribuer selon droits | Créer son propre espace avant d’ouvrir celui reçu. |
| Fichier importé | Aperçu et état de compatibilité | Ouvrir sans altérer l’original | Génération automatique sur toutes les sources. |
| Démo volontaire | Petite scène Sarah isolée | Essayer une action | Fournir ses données réelles. |
| Document récupéré après incident | Version récupérable identifiée | Comparer/restaurer | Rejouer l’onboarding marketing. |
| Première capacité avancée | Résultat actuel et prochaine capacité | Essayer sur son travail | Remplir toutes les préférences de fonctions futures. |

## Routage proposé et garde-fous

Si une invitation est ouverte, elle prime sur la restauration d’un autre document dans cette même demande d’ouverture, sans écraser sa session. Le lien est vérifié ; le rôle présenté vient de l’état autorisé. Si le bon compte manque, l’authentification conserve la destination. Après annulation, le travail local reste disponible. Une nouvelle session ne doit pas perdre le lien et demander à l’utilisateur de le retrouver dans son e-mail.

Si le fichier est incompatible, l’application explique ce qui peut être lu sans perte. Un écran vide « commencez un projet » n’est pas une récupération. Si une sauvegarde antérieure existe, le choix de restauration cite sa date et sa provenance, sans présenter une génération de remplacement comme une réparation de fichier.

Pour une démo, chaque essai a sa propre copie. Un bouton « Réinitialiser l’exemple » ne touche jamais les documents privés. Quitter la démo n’efface ni les préférences ni une première saisie conservée ailleurs. L’historique d’apprentissage du parcours démo ne doit pas être compté comme preuve que la personne a publié ou accepté quelque chose en équipe réelle.

## Compétence locale et rôle restent indépendants

Le propriétaire peut ne pas connaître le produit ; un viewer peut très bien le connaître. Les actions présentées suivent les permissions, alors que les aides suivent l’expérience pertinente. Un contributeur ne doit pas apprendre à « retenir dans le document commun » s’il ne possède pas ce droit. Il apprend à publier une proposition et à comprendre qui peut l’accepter.

La phrase d’arrivée d’un invité doit répondre à trois questions : **pourquoi suis-je ici, que puis-je faire, où commencer ?** Le rôle technique `contributor` peut être expliqué par « Vous pouvez commenter et proposer des changements ». Ce n’est pas une permission augmentée par une formulation sympathique.

## Revenir après une pause

Le retour restaure d’abord l’endroit et le travail. Une nouveauté produit ne doit pas masquer un brouillon ou un conflit. Un résumé « depuis votre dernière visite » se consulte volontairement et utilise de vrais changements connus. Il ne présente pas une modification de position comme une nouvelle décision.

Un conseil ignoré lors de la première session ne se réaffiche pas simplement parce que la personne s’est reconnectée. L’absence d’activité pendant plusieurs jours ne signifie pas qu’elle a tout oublié. Une commande « Revoir les repères » rend l’aide disponible sans déduire automatiquement un besoin de remise à niveau.



---

<a id="ch-05"></a>

# 05 — Le premier parcours : de sa phrase à une valeur maîtrisée

## Scène de recette, pas contenu à injecter dans toutes les demandes

Texte synthétique : « Nous voulons organiser une journée découverte. Nous disposons d’une salle de 30 places, de deux intervenants et d’aucun budget publicitaire. » Il sert à essayer le parcours ; Sarah reste un autre exemple. Dans l’app réelle, le modèle ou le mode manuel part du texte effectivement fourni.

### Étape 1 — Une invitation, une entrée, une promesse limitée

Le champ porte un titre permanent : « Sur quoi travaille-t-on ? ». Une phrase explique l’effet : « Décrivez la situation ; votre texte deviendra le point de départ du document. » Le placeholder contient un exemple court, mais ne remplace pas le label. La saisie conserve Enter pour les paragraphes et Cmd+Enter pour soumettre.

L’écran n’affiche pas encore les instructions de drag, les invitations d’équipe, un choix de modèle et un tableau de prix. Un lien discret « Voir un exemple » peut ouvrir un exemple remplaçable seulement si le champ est vide. Si du texte existe, le choix d’exemple crée une autre démo ou demande explicitement quoi conserver ; il ne remplit pas silencieusement le champ par-dessus.

### Étape 2 — Création locale visible

La validation crée un document et un objet de contexte. L’écriture locale est réelle, avec état d’échec traité. Le contenant de saisie peut se transformer vers la surface de contexte ; le texte ne s’envole pas vers un coin à une taille illisible. Le contenu original n’est ni résumé ni changé de langue par cette transition.

La personne doit voir que sa phrase est maintenant un élément du travail. « Sur ce Mac » désigne le lieu effectif de l’inférence lorsqu’elle commence, pas une promesse absolue sur toutes les fonctions réseau futures.

### Étape 3 — Une attente qui n’occupe pas tout le produit

Si le modèle fonctionne, une activité locale est attachée au contexte, avec Annuler. Si les ressources ne sont pas disponibles, un état honnête donne l’option manuelle et, séparément, l’exemple de démonstration. Ce ne sont pas deux façons de maquiller une panne en succès.

Le contexte reste éditable. Si cette édition rend la requête caduque, le coordinateur invalide son résultat tardif. La personne n’a pas à comprendre l’identifiant de requête pour savoir qu’une proposition correspond à une ancienne phrase.

### Étape 4 — Apprendre le caractère provisoire

Un petit ensemble de candidats apparaît près du contexte, avec relations discontinues et textes lisibles. Le groupe porte « Proposition ». Un court conseil, seulement si nécessaire, explique : « Rien n’est ajouté tant que vous ne retenez pas cette proposition. Vous pouvez aussi la modifier. » Il n’exige pas de cliquer sur Suivant et ne recouvre pas les candidats.

Il ne faut pas forcer trois pistes si une clarification est plus utile. Par exemple, demander le public attendu est légitime ; inventer que les intervenants sont disponibles à une date donnée ne l’est pas. La découverte de Kollio doit permettre d’apprendre son contrôle sans confondre la fluidité de génération avec la fiabilité de tous les contenus.

### Étape 5 — Un acte délibéré, pas un clic d’activation

La personne peut retenir une proposition utile, corriger un intitulé, demander une clarification ou écarter une mauvaise direction. Chacun peut constituer un progrès. « Première valeur » n’est pas synonyme de « accepte le premier résultat ». Si elle corrige un fait et refuse deux pistes non pertinentes, le produit peut avoir bien rendu le contrôle même si la qualité du modèle doit encore être améliorée.

L’acceptation conserve positions et identités, applique une transaction et indique son résultat. La possibilité d’annulation est visible dans le menu et peut être rappelée une fois. Pas besoin de faire annuler le travail réel pour prouver que la personne sait le faire ; un essai guidé séparé peut le proposer volontairement.

### Étape 6 — Reprendre sans re-onboarding

La personne ferme et rouvre le document. Elle retrouve son texte, ce qu’elle a gardé et les décisions explicites. L’app ne rejoue pas l’apparition initiale comme si tout venait d’être produit. L’aide à la reprise porte sur les changements réels depuis son départ, pas sur un carrousel de fonctions.

## Ce que l’observateur demande

Avant de faire cliquer, demander : « Qu’est-ce qui appartient déjà au document ? », « Que ferait ce bouton ? », puis « Comment retrouveriez-vous le texte initial ? ». Une réponse verbale n’est pas suffisante : vérifier le geste correspondant. Mais une tâche réussie au hasard sans compréhension n’est pas suffisante non plus.

Séparer temps de saisie, calcul, lecture et manipulation. Si l’utilisateur hésite sur le sens de Retenir, réduire la latence du modèle ne résout pas ce problème. Si l’entrée est claire et que l’attente dure trop longtemps, ajouter un tutoriel ne rend pas le résultat plus rapide.



---

<a id="ch-06"></a>
