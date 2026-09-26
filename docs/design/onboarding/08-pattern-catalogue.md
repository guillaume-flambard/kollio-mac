# 15 — Catalogue de 36 patterns applicables à Kollio

## Comment utiliser les fiches

Ces **36 patterns** sont des décisions ou hypothèses de conception Kollio, non un classement universel. Leurs références justifient l’attention portée au problème ; les séquences proposées restent à implémenter et tester. Les identifiants V2 ancrent chaque fiche dans une fonction existante. Ne pas fabriquer 36 composants nouveaux si les vues et commandes actuelles suffisent.

Chaque fiche décrit un besoin, une séquence concrète, un anti-pattern, une récupération et une preuve attendue. La preuve attendue n’est jamais réputée acquise par la présence de la fiche dans le registre.

### PAT-01 — Commencer par un travail personnel, pas par un profil

**Famille :** Arrivée · **V2 :** DOC-01, DOC-02, AI-01.

**Problème.** L’utilisateur vient avec une situation, pas avec le désir de configurer son identité dans un nouveau logiciel.

**Séquence proposée.** Une invitation explicite, un champ multiligne et Explorer. Au clic, créer le contexte local avant la génération. Les exemples et l’ouverture d’un fichier restent secondaires. Le compte intervient seulement au partage.

**À éviter.** Profession, taille d’équipe, préférences IA et invitation de collègues obligatoires avant de pouvoir saisir une phrase.

**Récupération.** Un modèle indisponible laisse le texte éditable. Une panne de stockage distingue mémoire conservée et sauvegarde non réussie.

**Preuve attendue.** La personne apporte son propre problème, retrouve ses mots et peut expliquer où ils sont conservés.

**Éclairage documentaire :** [R01](#source-r01) · [R02](#source-r02) · [R09](#source-r09).

### PAT-02 — Exemple facultatif, entièrement réversible

**Famille :** Arrivée · **V2 :** DOC-02, DOC-03.

**Problème.** Le champ vide peut laisser une personne hésitante sans que cela justifie un tutoriel forcé.

**Séquence proposée.** Un lien Voir un exemple insère un contexte synthétique clairement annoncé. L’utilisateur peut le modifier, l’effacer ou ouvrir une copie de démonstration. Sa saisie déjà présente n’est jamais remplacée sans choix.

**À éviter.** Texte de Sarah injecté dans tous les documents ou placeholder si long qu’il ressemble à un résultat déjà produit.

**Récupération.** Annuler l’exemple restitue le brouillon antérieur. Fermer la démo ne supprime pas le document personnel.

**Preuve attendue.** Mesurer les départs autonomes et le temps jusqu’à un contexte personnel, séparément des essais de démonstration.

**Éclairage documentaire :** [R02](#source-r02) · [R24](#source-r24).

### PAT-03 — Conservation avant génération

**Famille :** Arrivée · **V2 :** DOC-02, DOC-04, AI-09.

**Problème.** Un échec du modèle ne doit pas effacer le premier effort consenti par la personne.

**Séquence proposée.** Valider le texte, créer document et objet, déclencher la sauvegarde contrôlée, afficher le contexte, puis demander une proposition. La réponse ne remplace jamais les mots originaux.

**À éviter.** Vider le champ avant que la création ait été prise en charge, ou annoncer Enregistré simplement parce qu’une animation est finie.

**Récupération.** En cas de disque plein, garder la saisie en mémoire, exposer la panne et permettre une autre destination. Ne pas promettre sa survie à un crash si aucune récupération n’a été écrite.

**Preuve attendue.** Test après panne de génération et relance ; vérification séparée de la réussite disque et de la réponse IA.

**Éclairage documentaire :** [R08](#source-r08) · [R12](#source-r12).

### PAT-04 — Bac à sable qui ne touche pas le travail réel

**Famille :** Arrivée · **V2 :** DOC-03, DOC-05, DEC-03.

**Problème.** Essayer un geste risqué dans un document important peut empêcher l’apprentissage.

**Séquence proposée.** Ouvrir une copie synthétique par une action volontaire. Y montrer une décision, une annulation et une réouverture, avec retour clair au document d’origine. Le nom et le stockage distinguent cet essai.

**À éviter.** Demander une véritable suppression, un partage public ou une vente pour terminer une visite guidée.

**Récupération.** Abandonner l’essai revient à la session précédente. Réinitialiser la démo ne réinitialise ni les fichiers ni l’aide désactivée.

**Preuve attendue.** La personne essaie librement et sait ensuite distinguer la copie d’exercice de son document.

**Éclairage documentaire :** [R12](#source-r12) · [R24](#source-r24).

### PAT-05 — Aide juste au premier besoin

**Famille :** Arrivée · **V2 :** AI-07, AI-08, CAN-02.

**Problème.** Une longue explication est oubliée si elle précède de loin le geste concerné.

**Séquence proposée.** Quand une proposition est présente et que la personne n’en a encore traité aucune, envisager un seul conseil près de ses actions. Le supprimer après action observée ou refus explicite. Aucun appel IA pour choisir ce conseil.

**À éviter.** Chaîne automatique de bulles couvrant toutes les fonctions ou déclenchement pendant une saisie.

**Récupération.** Si l’ancre sort du viewport, suspendre le conseil. Conserver son éligibilité sans le compter comme vu avant présentation réelle.

**Preuve attendue.** Compréhension du statut d’une proposition avec moins d’interruptions, pas simple hausse des clics de fermeture.

**Éclairage documentaire :** [R03](#source-r03) · [R04](#source-r04) · [R10](#source-r10).

### PAT-06 — Préparation reportée à sa cause

**Famille :** Arrivée · **V2 :** CTX-02, AI-10, TEAM-01, TEAM-02.

**Problème.** L’application n’a pas besoin de toutes les permissions possibles pour produire sa première valeur.

**Séquence proposée.** Demander l’accès au fichier lors de sa sélection ; expliquer la destination avant un cloud autorisé ; connecter un compte au premier partage. Les prérequis techniques réellement indispensables restent honnêtes.

**À éviter.** Permission globale sur tous les documents ou connexion de services proposée comme étape obligatoire du canvas.

**Récupération.** Un refus laisse l’action non autorisée indisponible, mais conserve navigation et contenu déjà légitimement accessibles.

**Preuve attendue.** Associer chaque demande à un geste compréhensible et vérifier l’absence de transmission avant accord.

**Éclairage documentaire :** [R01](#source-r01) · [R13](#source-r13).

### PAT-07 — Mode manuel sans modèle disponible

**Famille :** Arrivée · **V2 :** AI-01, AI-09, DOC-02.

**Problème.** L’indisponibilité Apple ne doit pas rendre l’utilisateur incapable de commencer son document.

**Séquence proposée.** Conserver le contexte et proposer de créer, relier ou préciser manuellement. Une démo est explicitement une démo. Montrer seulement le motif réel d’indisponibilité exposé par la plateforme.

**À éviter.** Réponse Sarah présentée comme analyse du contexte personnel ou basculement automatique vers un fournisseur distant.

**Récupération.** Réessayer vérifie l’état courant. Le travail manuel n’est pas régénéré ou supprimé lorsque le modèle revient.

**Preuve attendue.** Parcours productif sans inférence, puis reprise sans perte lorsque l’adaptateur est disponible.

**Éclairage documentaire :** [R15](#source-r15) · [R16](#source-r16).

### PAT-08 — Reprise avant nouveautés

**Famille :** Arrivée · **V2 :** DOC-01, DOC-04, TEAM-11.

**Problème.** Une personne qui revient cherche sa place dans le travail, pas une nouvelle tournée du produit.

**Séquence proposée.** Restaurer document, position de lecture et brouillons selon le V2. Les changements de l’équipe se consultent à la demande. Une nouveauté fonctionnelle n’interrompt pas le retour au contexte.

**À éviter.** Rejouer l’accueil après chaque mise à jour ou masquer un document restauré derrière une annonce.

**Récupération.** Une restauration incomplète indique ses limites et propose la récupération. Ne pas la remplacer par un projet vide.

**Preuve attendue.** Temps pour reprendre une intention déjà connue et capacité à retrouver une décision antérieure.

**Éclairage documentaire :** [R12](#source-r12) · [R16](#source-r16).

### PAT-09 — Invité dirigé vers la tâche, pas perdu dans le plan

**Famille :** Arrivée · **V2 :** TEAM-03, TEAM-04, CAN-09.

**Problème.** Un grand canvas peut être très clair pour son auteur et incompréhensible pour un collègue invité.

**Séquence proposée.** Après contrôle d’accès, afficher le rôle et le point demandé dans l’invitation. Offrir Voir le contexte puis revenir à l’ancre. Le viewport d’accueil est une vue, pas une permission supplémentaire.

**À éviter.** Accueil de créateur imposé au lecteur ou zoom initial si large que tous les titres sont illisibles.

**Récupération.** Si l’ancre a disparu, l’indiquer et revenir à un contexte sûr du même document autorisé, sans inventer sa nouvelle cible.

**Preuve attendue.** L’invité sait pourquoi il est là, ce qu’il peut faire et comment comprendre le contexte environnant.

**Éclairage documentaire :** [R20](#source-r20) · [R21](#source-r21).

### PAT-10 — Apprentissage non linéaire et révocable

**Famille :** Arrivée · **V2 :** DOC-08, CAN-02.

**Problème.** Les gens découvrent les capacités dans des ordres différents ; un parcours unique devient vite faux.

**Séquence proposée.** Mémoriser localement quelques actions accomplies et choix de masquer l’aide. Un utilisateur peut ouvrir une rubrique d’aide sans réinitialiser ses connaissances. Ne pas changer les identifiants de conseils pour contourner un refus.

**À éviter.** Checklist 100 % obligatoire, badge de progression métier fondé sur le nombre de tips fermés ou classement de compétence.

**Récupération.** Une remise à zéro de l’aide nécessite une action explicite et ne touche pas les décisions du document.

**Preuve attendue.** Conseils utiles lorsqu’ils sont demandés, absence de répétitions après maîtrise observée ou refus.

**Éclairage documentaire :** [R03](#source-r03) · [R04](#source-r04).

### PAT-11 — Libellé d’action plutôt qu’icône énigmatique

**Famille :** Commandes · **V2 :** CAN-02, CTX-01, AI-03.

**Problème.** Une icône nouvelle ne permet pas de deviner la différence entre modifier et demander au modèle.

**Séquence proposée.** Afficher un verbe court près de la sélection. Réserver les icônes seules aux commandes familières et leur fournir un label accessible. Tester les textes FR avant de décider une largeur.

**À éviter.** Étoile magique signifiant tour à tour explorer, publier et synthétiser.

**Récupération.** Si les commandes ne tiennent pas, placer les rares dans un accès secondaire nommé ; ne pas tronquer une action dangereuse.

**Preuve attendue.** La personne prédit le résultat avant de cliquer, sans devoir découvrir l’explication par erreur.

**Éclairage documentaire :** [R02](#source-r02) · [R11](#source-r11) · [R30](#source-r30).

### PAT-12 — Barre locale stable et atteignable

**Famille :** Commandes · **V2 :** CAN-02, CAN-08.

**Problème.** Une barre qui disparaît pendant le trajet du pointeur rend la fonction inaccessible.

**Séquence proposée.** Lier l’affichage à la sélection, pas uniquement au hover. Maintenir une zone de transition et une position écran stable. Clamper aux bords, en évitant de couvrir le texte visé.

**À éviter.** Délai minuscule qui ferme la barre dès que la souris quitte l’objet ou changement incessant de côté.

**Récupération.** Si le viewport devient trop étroit, utiliser une surface locale compacte ou un menu natif, en conservant le focus.

**Preuve attendue.** Accès au bouton avec mouvement lent, gros pointeur, zoom éloigné et clavier.

**Éclairage documentaire :** [R25](#source-r25) · [R31](#source-r31).

### PAT-13 — Tooltip informatif, popover interactif

**Famille :** Commandes · **V2 :** CAN-02, DOC-08.

**Problème.** Un conseil contenant des actions focalisables n’est pas une simple légende de survol.

**Séquence proposée.** Le tooltip explique brièvement un contrôle et ne reçoit pas des boutons métier. Pour une aide interactive, utiliser une surface adaptée avec focus, fermeture et retour de focus définis.

**À éviter.** Bouton Rouvrir enfermé dans une bulle qui disparaît au clavier ou dont le pointeur ne peut franchir le bord.

**Récupération.** Échap ferme la couche d’aide pertinente sans effacer une saisie ni annuler une proposition indépendante.

**Preuve attendue.** Lecture et utilisation possibles par chaque modalité, sans trajet précis imposé.

**Éclairage documentaire :** [R25](#source-r25) · [R33](#source-r33).

### PAT-14 — Saisir à l’endroit concerné avec sa cible visible

**Famille :** Commandes · **V2 :** CTX-01, AI-03, DOC-03.

**Problème.** Une phrase libre perd son sens si on ne sait plus à quel objet elle s’applique.

**Séquence proposée.** Le compositeur montre une cible courte puis le champ. Le brouillon suit cette ancre. Changer de sélection ne requalifie pas silencieusement la demande. Cmd+Entrée et bouton soumettent la même opération.

**À éviter.** Champ global dont le contexte change quand l’utilisateur clique ailleurs pendant qu’il écrit.

**Récupération.** Si la cible disparaît, conserver le brouillon et demander où l’associer. Ne pas le rattacher au prochain élément sélectionné.

**Preuve attendue.** Test avec deux fenêtres, deux sélections et une réponse tardive ; aucun mélange de texte ou d’identité.

**Éclairage documentaire :** [R12](#source-r12) · [R15](#source-r15).

### PAT-15 — Modifier et demander : deux conséquences distinctes

**Famille :** Commandes · **V2 :** CAN-04, AI-03.

**Problème.** Retoucher une phrase personnelle ne devrait pas provoquer une génération surprise.

**Séquence proposée.** Modifier entre dans l’édition locale ; Explorer appelle une proposition. Les chemins sont nommés. Le double-clic actuel reste celui du V2 tant qu’une décision de produit n’a pas tranché une autre convention.

**À éviter.** Adopter un nouveau double-clic dans cette recherche et laisser l’agent changer aussi les tests métier sans accord.

**Récupération.** Une génération involontaire peut être annulée ; le texte original n’est pas remplacé. La suppression du brouillon demande une intention explicite.

**Preuve attendue.** Expérience contrôlée edit/explore mesurant erreurs et compréhension, pas seulement préférence déclarée.

**Éclairage documentaire :** [R02](#source-r02) · [R12](#source-r12).

### PAT-16 — Alternative au glisser par clics

**Famille :** Commandes · **V2 :** CAN-03, CAN-06.

**Problème.** Un dispositif de pointage adapté peut permettre des clics mais rendre un drag continu difficile.

**Séquence proposée.** Pour relier : choisir Relier, puis une cible par clic ou recherche. Pour déplacer : une action contextuelle Déplacer ici peut choisir une destination sans maintenir la pression. Le clavier reste un autre chemin, non l’unique compensation.

**À éviter.** Conclure que les raccourcis de clavier suffisent à toutes les personnes qui ne peuvent pas glisser.

**Récupération.** Échap annule le mode de placement ; clic hors cible ne crée pas de relation arbitraire. Les changements acceptés restent undoables.

**Preuve attendue.** Compléter déplacement et liaison avec un pointeur uniquement, sans drag et sans clavier.

**Éclairage documentaire :** [R26](#source-r26) · [R29](#source-r29).

### PAT-17 — Confirmation proportionnée et annulation réelle

**Famille :** Commandes · **V2 :** CAN-05, DEC-03, AI-08.

**Problème.** Confirmer chaque mouvement fatigue ; supprimer silencieusement des données prive de contrôle.

**Séquence proposée.** Actions locales réversibles avec undo, sans dialogue systématique. Opérations destructrices ou externes : nommer l’objet, la portée et l’effet. L’acceptation d’un candidat montre ce qui changerait avant de le commettre.

**À éviter.** Êtes-vous sûr générique pour tout, ou confirmation prétendant annuler ensuite un envoi déjà effectué.

**Récupération.** L’erreur de commit laisse l’aperçu intact. Les références affectées sont expliquées avant une suppression sémantique.

**Preuve attendue.** Réduction des confirmations inutiles sans hausse de pertes ni ambiguïté des actions irréversibles.

**Éclairage documentaire :** [R12](#source-r12) · [R15](#source-r15) · [R29](#source-r29).

### PAT-18 — Retrouver sans rouvrir une décision

**Famille :** Commandes · **V2 :** CAN-09, DEC-02, DEC-06.

**Problème.** La recherche d’une branche rejetée doit permettre de la lire sans la remettre en activité.

**Séquence proposée.** Un résultat mène au chemin temporairement révélé, avec marque Lecture d’une direction écartée. Revenir restaure la vue précédente. Rouvrir est une autre action explicite.

**À éviter.** Réactiver automatiquement la stratégie simplement parce que la recherche doit la rendre visible.

**Récupération.** Une source manquante reste identifiable ; aucune citation n’est présentée comme nouvellement consultée.

**Preuve attendue.** Après la recherche, le statut et l’historique métier sont identiques avant toute décision nouvelle.

**Éclairage documentaire :** [R12](#source-r12) · [R21](#source-r21).

### PAT-19 — Erreur persistante, aide secondaire

**Famille :** Commandes · **V2 :** DOC-04, AI-09.

**Problème.** Un toast effacé peut laisser croire que le travail est conservé alors que la sauvegarde a échoué.

**Séquence proposée.** Associer l’erreur à sa cible avec cause utile, état du travail et voie de récupération. Donner la priorité à cette information sur les conseils d’apprentissage.

**À éviter.** Faire disparaître une erreur de sauvegarde après trois secondes ou la recouvrir d’une nouveauté produit.

**Récupération.** Conserver le brouillon ; réessayer l’opération avec le contexte actuel ; ne pas rejouer toutes les générations passées.

**Preuve attendue.** L’utilisateur peut retrouver la panne et savoir ce qui reste seulement en mémoire.

**Éclairage documentaire :** [R08](#source-r08) · [R28](#source-r28) · [R30](#source-r30).

### PAT-20 — Révélation progressive sans écran vide de possibilités

**Famille :** Commandes · **V2 :** CAN-02, STU-03, TEAM-04.

**Problème.** Tout cacher évite le bruit mais retire aussi les moyens de découverte.

**Séquence proposée.** Montrer les quelques actions fréquentes et un accès secondaire explicite. Les fonctions avancées deviennent pertinentes au bon objet : source, sélection multiple, proposition ou résultat.

**À éviter.** Menu de trente commandes identiques pour tous les objets ou fonctions essentielles accessibles seulement par raccourci secret.

**Récupération.** Un rôle qui n’a pas le droit d’agir voit la raison quand cette compréhension est utile, pas une fausse commande active.

**Preuve attendue.** Trouver une fonction courante sans aide puis une fonction rare avec son menu, sans apprendre tout le système.

**Éclairage documentaire :** [R02](#source-r02) · [R11](#source-r11).

### PAT-21 — Suggestion lisible, statut provisoire explicite

**Famille :** Intelligence · **V2 :** AI-07, AI-08, AI-11.

**Problème.** La personne doit comprendre une proposition avant de décider de la retenir.

**Séquence proposée.** Texte opaque, traits discontinus et libellé Proposition. Le destinataire de l’inférence est consultable et visible pendant la demande. Les actions s’appliquent à un groupe défini.

**À éviter.** Opacité de 30 % pour tout le groupe ou ressemblance parfaite avec le contenu déjà accepté.

**Récupération.** Une proposition invalide ne rejoint jamais le canonique. Son erreur est locale et récupérable sans toucher au contexte.

**Preuve attendue.** Demander quels éléments font déjà partie du document et lesquels attendent une décision.

**Éclairage documentaire :** [R15](#source-r15) · [R16](#source-r16) · [R32](#source-r32).

### PAT-22 — Avant/après stable quand le texte change

**Famille :** Intelligence · **V2 :** AI-07, CTX-05, TEAM-08.

**Problème.** Une morphose de phrase est jolie mais ne permet pas forcément de comparer le sens.

**Séquence proposée.** Montrer l’ancien et le candidat à proximité, avec les différences lisibles. L’utilisateur peut relire sans que les mots continuent à changer. La transition finale conserve l’identité.

**À éviter.** Remplacement animé répétitif et acceptation implicite au dernier frame.

**Récupération.** Si le contenu change à distance, marquer la version examinée obsolète et proposer de revoir le nouvel état.

**Preuve attendue.** Repérer une négation retirée ou une contrainte modifiée dans une tâche de compréhension.

**Éclairage documentaire :** [R17](#source-r17) · [R18](#source-r18).

### PAT-23 — Expliquer la base et la destination, pas une assurance

**Famille :** Intelligence · **V2 :** CTX-03, CTX-06, AI-10, AI-11.

**Problème.** Un ton confiant peut être pris pour une validation et le mot local peut cacher un relais cloud.

**Séquence proposée.** Based on montre références, portée et omissions. La destination réelle est Sur ce Mac, Cloud autorisé ou Démo selon le chemin. Une source reste vérifiable au point concerné.

**À éviter.** Score de confiance inventé, chaîne de pensée fabriquée ou marque Apple sur une réponse de démonstration.

**Récupération.** Source inaccessible : état explicite. Changement de destination : aucun envoi avant consentement/politique applicable.

**Preuve attendue.** L’utilisateur sait pourquoi la proposition existe et où ses données ont été traitées.

**Éclairage documentaire :** [R15](#source-r15) · [R16](#source-r16).

### PAT-24 — Clarifier sans forcer une réponse inventée

**Famille :** Intelligence · **V2 :** AI-04, CTX-01.

**Problème.** Certaines demandes ne peuvent être développées utilement sans information supplémentaire.

**Séquence proposée.** Une question attachée à la bonne cible laisse répondre, indiquer Je ne sais pas, ou continuer manuellement. La réponse devient un apport conservé avec sa portée.

**À éviter.** Formulaire obligatoire de vingt variables ou impossibilité de poursuivre tant qu’un chiffre hypothétique n’est pas fourni.

**Récupération.** L’inconnu reste unknown. Une panne après réponse ne l’efface pas ni ne transforme l’absence d’information en contrainte levée.

**Preuve attendue.** Le résultat respecte une réponse inconnue et ne cite pas un budget jamais donné.

**Éclairage documentaire :** [R15](#source-r15) · [R16](#source-r16).

### PAT-25 — Attente honnête et activité indépendante

**Famille :** Intelligence · **V2 :** AI-09, CAN-01.

**Problème.** La génération prend du temps mais ne doit pas immobiliser l’éditeur.

**Séquence proposée.** Accuser réception immédiatement, afficher une activité près de la cible et permettre d’annuler. Progression chiffrée seulement si mesurée ; ailleurs, libellé factuel et absence de fausse estimation.

**À éviter.** Pause artificielle pour rendre le modèle impressionnant ou pourcentage qui monte toujours jusqu’à 99 %.

**Récupération.** Un timeout conserve le contexte et autorise un réessai explicite. Une réponse tardive ne s’affiche pas comme encore active.

**Preuve attendue.** La personne peut déplacer une autre idée pendant la demande et sait si celle-ci est terminée.

**Éclairage documentaire :** [R08](#source-r08) · [R14](#source-r14).

### PAT-26 — Refus utile avec mémoire

**Famille :** Intelligence · **V2 :** AI-08, DEC-02, DEC-06.

**Problème.** Reproposer la même piste ignorée transforme l’exploration en répétition frustrante.

**Séquence proposée.** Écarter conserve le candidat, la raison et la portée. La prochaine demande inclut les rejets pertinents. Masquer temporairement reste une action différente, sans préférence permanente inventée.

**À éviter.** Traiter une mauvaise suggestion rejetée comme un échec utilisateur ou imposer de l’accepter pour finir le tutoriel.

**Récupération.** Réexaminer est explicite et montre l’ancien contexte de rejet. Un changement pertinent peut justifier une autre proposition, pas un oubli silencieux.

**Preuve attendue.** Deux demandes successives ne répètent pas une direction identique sans expliquer le changement.

**Éclairage documentaire :** [R15](#source-r15) · [R16](#source-r16).

### PAT-27 — Rôle compris à l’entrée d’équipe

**Famille :** Équipe · **V2 :** TEAM-03, TEAM-04, TEAM-07.

**Problème.** Contributeur et éditeur voient parfois le même canvas mais ne disposent pas des mêmes effets.

**Séquence proposée.** L’invitation annonce la tâche et le rôle. Un contributeur voit Publier la proposition, l’éditeur Retenir dans le commun. Les contrôles suivent les droits réels sans exposer la matrice complète.

**À éviter.** Bouton Retenir qui produit en fait un simple brouillon chez un utilisateur et un commit chez un autre sans explication.

**Récupération.** Droits changés : préserver brouillon, arrêter l’action non autorisée, expliquer la nouvelle situation.

**Preuve attendue.** La personne décrit ce que son clic partagera et ce qui ne sera pas modifié.

**Éclairage documentaire :** [R15](#source-r15) · [R20](#source-r20).

### PAT-28 — Brouillon privé puis publication volontaire

**Famille :** Équipe · **V2 :** TEAM-07, TEAM-09.

**Problème.** Les essais et la frappe ne doivent pas être confondus avec les changements que l’équipe adopte.

**Séquence proposée.** L’exploration reste locale jusqu’à Publier. Le candidat publié reçoit auteur et version. La présence d’un collègue n’autorise pas la diffusion de tous les brouillons.

**À éviter.** Partager chaque phrase pendant sa rédaction ou appeler privé un état déjà envoyé au serveur pour la revue.

**Récupération.** Erreur de publication : conserver le brouillon et son état non publié ; pas de double envoi au réessai.

**Preuve attendue.** Deux sessions indépendantes prouvent que la seconde ne voit pas la frappe et reçoit seulement la proposition publiée.

**Éclairage documentaire :** [R15](#source-r15) · [R16](#source-r16).

### PAT-29 — Revue d’une version exacte

**Famille :** Équipe · **V2 :** TEAM-08, AI-07.

**Problème.** Accepter une proposition qu’un collègue vient de modifier peut valider quelque chose de non lu.

**Séquence proposée.** La surface affiche la version examinée ; Retenir transmet cette version et les préconditions. Une réponse de conflit conserve la lecture et demande d’examiner les différences actualisées.

**À éviter.** Appliquer automatiquement la dernière version sous couvert d’une approbation plus ancienne.

**Récupération.** Deux acceptations concurrentes donnent une seule transaction. La seconde session reçoit la décision actuelle.

**Preuve attendue.** Test candidate v1 affichée puis v2 publiée avant clic : aucune v2 acceptée sans revue.

**Éclairage documentaire :** [R15](#source-r15) · [R17](#source-r17).

### PAT-30 — Sauvegardé ici n’est pas synchronisé

**Famille :** Équipe · **V2 :** DOC-04, TEAM-10.

**Problème.** Le disque local peut être à jour alors que le serveur n’a rien reçu.

**Séquence proposée.** États distincts dans le menu document et indicateur local en cas d’attente importante. Un guide de partage les explique à ce moment, sans ajouter un dashboard de synchronisation.

**À éviter.** Coche verte unique couvrant stockage, réseau, validation et autorisation.

**Récupération.** Reconnexion rejoue les demandes identifiées après contrôle de droits. Un conflit reste en attente avec brouillon conservé.

**Preuve attendue.** Quitter hors ligne puis relancer conserve l’outbox et l’utilisateur ne croit pas que l’équipe a reçu les changements.

**Éclairage documentaire :** [R12](#source-r12) · [R28](#source-r28).

### PAT-31 — Accès perdu sans effacer l’intention

**Famille :** Équipe · **V2 :** TEAM-04, TEAM-12.

**Problème.** Un changement de droits est un événement de travail, pas un simple toast réseau.

**Séquence proposée.** Arrêter les commits non autorisés, présenter l’état d’accès, le compte utilisé et les options réellement permises. La gestion des copies suit la politique du produit, sans promettre un effacement rétroactif.

**À éviter.** Continuer à montrer Synchronisé ou offrir un export non autorisé comme solution universelle.

**Récupération.** Une demande de réaccès ne publie rien. Les travaux locaux en attente sont gérés selon la politique explicite.

**Preuve attendue.** Aucun commit après révocation ; message clair sur ce qui peut être conservé ou envoyé.

**Éclairage documentaire :** [R13](#source-r13) · [R15](#source-r15).

### PAT-32 — Suivre volontairement et sortir immédiatement

**Famille :** Équipe · **V2 :** TEAM-05, TEAM-13.

**Problème.** La navigation d’un présentateur ne devrait pas déplacer les autres sans accord.

**Séquence proposée.** Une invitation de suivi explique son effet sur la caméra. Une fois accepté, afficher Vous suivez… et Quitter. Un geste local sort du suivi sans modifier la caméra du présentateur.

**À éviter.** Rappeler sans cesse la personne au viewport du présentateur ou partager sa caméra pendant une simple lecture.

**Récupération.** Présentateur déconnecté : garder la vue locale et arrêter le suivi. Aucun repli ou décision métier n’est annulé.

**Preuve attendue.** Deux clients, sortie au pinch/pan et aucune caméra distante impactée.

**Éclairage documentaire :** [R20](#source-r20) · [R21](#source-r21).

### PAT-33 — Retour immédiat, travail fini seulement quand il l’est

**Famille :** Mouvement · **V2 :** DOC-04, AI-09, AI-08.

**Problème.** Le clic doit être reconnu avant la fin de l’opération sans annoncer un faux succès.

**Séquence proposée.** État pressé puis activité réelle. L’affichage de réussite attend le résultat métier approprié. La transition visuelle n’est qu’une projection de cet état.

**À éviter.** Coche de succès optimiste pour une permission, un paiement ou une sauvegarde encore refusables.

**Récupération.** Échec fait revenir à une action utile avec le contexte conservé, pas à un écran vide.

**Preuve attendue.** Mesurer temps de premier feedback séparément du temps de résultat et de compréhension.

**Éclairage documentaire :** [R06](#source-r06) · [R08](#source-r08) · [R14](#source-r14).

### PAT-34 — Transition interruptible et identité stable

**Famille :** Mouvement · **V2 :** CAN-01, CAN-08, AI-08.

**Problème.** Un utilisateur ne doit pas attendre la fin d’un effet pour agir à nouveau.

**Séquence proposée.** Animer uniquement les éléments modifiés ; garder l’ancre, le focus et les IDs. Un mouvement de caméra demandé est interrompu au prochain geste ; un drag suit directement le pointeur.

**À éviter.** Spring appliqué au canvas entier ou système bloquant les actions durant le fondu.

**Récupération.** Interruption décide explicitement la projection visuelle à conserver sans annuler un commit déjà validé.

**Preuve attendue.** Appuis rapides, ouverture puis fermeture, zoom pendant arrivée : aucun doublon ni saut de canonique.

**Éclairage documentaire :** [R05](#source-r05) · [R06](#source-r06) · [R07](#source-r07).

### PAT-35 — Mouvement réduit, information entière

**Famille :** Mouvement · **V2 :** CAN-10, AI-07, DOC-08.

**Problème.** Retirer une animation ne doit pas enlever le seul indice de modification.

**Séquence proposée.** Conserver labels, focus, avant/après et statut ; remplacer la décoration par une mise à jour ou fondu court. Tester les deux modes jusqu’au même état final.

**À éviter.** Uniquement désactiver le CSS/SwiftUI et laisser disparaître sans explication la moitié du graphe.

**Récupération.** Changer le réglage pendant une transition mène à un état stable ; aucun timer ne porte la logique métier.

**Preuve attendue.** Même tâche réussie sans mouvement décoratif et aucune différence dans les données finales.

**Éclairage documentaire :** [R05](#source-r05) · [R27](#source-r27).

### PAT-36 — Focus rendu à une place explicable

**Famille :** Mouvement · **V2 :** CAN-09, CAN-10, AI-09.

**Problème.** Une interaction peut paraître fluide à la souris et perdre totalement un utilisateur clavier.

**Séquence proposée.** Ouvrir un détail place le focus selon son usage. Fermer le rend à l’objet d’origine ; supprimer cet objet le reporte sur une cible logique. Les messages d’état n’arrachent pas le focus.

**À éviter.** Focus renvoyé au premier bouton de fenêtre à chaque changement ou élément focalisé totalement couvert par une aide.

**Récupération.** Si l’ancre n’existe plus, annoncer l’événement et choisir un parent ou commande stable ; jamais une cible arbitraire.

**Preuve attendue.** Tester avec navigation clavier et VoiceOver, en plus des captures visuelles.

**Éclairage documentaire :** [R23](#source-r23) · [R28](#source-r28) · [R31](#source-r31).



---

<a id="ch-16"></a>

# 16 — Règles de coaching et contrat de présentation

## Dix conseils possibles ne signifient pas dix conseils affichés

Le registre `onboarding-cues.json` fournit dix candidats de découverte. Ils sont éligibles seulement dans un contexte utile. Ils sont déclenchés par un contexte de travail, pas par une attente mesurée arbitrairement. Les mêmes explications restent accessibles volontairement depuis le menu Aide, en dehors des budgets du coaching automatique. Le nombre de candidats n’est pas le nombre d’étapes d’un onboarding.

Les valeurs retenues pour le premier essai sont une seule aide automatique visible globalement, au plus deux apparitions automatiques par session et une impression automatique par conseil. Ces chiffres sont des **hypothèses conservatrices à tester**. Une aide demandée explicitement n’est pas interdite après désactivation des aides proactives. Une erreur active n’est pas une astuce et ne peut être masquée par ce réglage.

## Algorithme proposé

Le coordinateur reçoit uniquement des signaux minimaux : fenêtre active, phase d’interaction, ancre visible, rôle courant, capacité autorisée et événements d’action. Il ne lit pas le texte privé pour profiler la personne. Il applique d’abord les suppressions, puis l’éligibilité, puis une priorité stable. La règle de décision renvoie **un candidat**, jamais une mutation du document.

Une écriture native est prioritaire sur le coaching. Un geste en cours, une interaction avec menu, une erreur bloquante ou un conflit suspendent l’apparition. Un conseil non montré n’est pas compté comme impression. Lorsqu’il apparaît, le compteur est mis à jour une fois par identifiant de présentation pour ne pas compter chaque rendu SwiftUI comme une nouvelle exposition.

Une ancre devenue invisible ferme ou suspend la présentation sans faire paniquer la caméra pour la rejoindre. L’absence d’ancre ne devient pas un conseil flottant au milieu d’un autre document. Un changement de compte ou de fenêtre détruit la présentation courante et réévalue sa portée avant toute autre apparition.

## Préférence et mémoire

`dismissed` signifie que la personne ne souhaite plus ce conseil automatique. `completed` signifie qu’un événement utile a été observé, pas que la personne a réussi un examen. `shown` est une mesure d’exposition réelle. Ces notions restent indépendantes des statuts de proposition et des droits sur le document.

La préférence appartient à l’utilisateur local, pas au fichier partagé. Dans cette première version, aucune synchronisation cloud des conseils n’est nécessaire. Le même document peut être ouvert par un débutant et une personne expérimentée sans enregistrer leur progression dans le graphe.

## TipKit comme moteur, pas comme multiplication des outils

Apple fournit déjà des règles, événements et mécanismes de présentation dans TipKit. Les exemples de WWDC24 montrent aussi des groupes ordonnés. Notre proposition est d’utiliser l’outil natif disponible et une petite couche d’arbitrage pour les états propres au canvas, pas de reconstruire une plateforme d’onboarding. [R03](#source-r03) · [R04](#source-r04)

Vérifier le SDK, la disponibilité macOS et les signatures avant d’écrire les appels. Les exemples de conférence de différentes années ne doivent pas être assemblés sans compilation. Une éventuelle synchronisation de TipKit n’est pas activée sans choix produit de partage de cet état.

Le simulateur Python livré formalise l’éligibilité à des fins de test. Ce n’est ni un remplacement de TipKit, ni une règle qui doit s’exécuter dans l’application Python. Il peut servir de cas de référence pour le coordinateur Swift.

## Fonctionnement après erreur et reprise

Un retour de réseau ne doit pas déclencher à la fois une proposition, une nouvelle fonction, un rappel de raccourci et un résumé d’activité. L’utilisateur finit d’abord l’action engagée. Une fois l’état stable, le coordinateur peut réexaminer les aides éligibles sans rattraper tout ce qu’il n’a pas affiché pendant l’interruption.

Le bouton Aide offre un accès intentionnel aux explications de base : saisir, modifier, explorer, comprendre un candidat, écarter, rouvrir et partager. Il ne relance pas un tour imposé depuis le premier écran. La personne choisit le sujet qui lui manque.


## Registre des conseils

### ONB-01 — Comprendre une proposition

**Déclencheur :** `proposalVisible` · **Ancre :** `proposalActions`.

**FR :** Ces éléments sont proposés. Vous pouvez les examiner avant de les retenir.

**EN :** These changes are proposed. Review them before keeping them.

**Fin de l’aide :** `proposalReviewed`, fermeture explicite ou inéligibilité. **Fonctions :** AI-07, AI-08. La règle respecte toutes les suppressions transversales décrites plus haut.

### ONB-02 — Modifier ses mots

**Déclencheur :** `contextSelected` · **Ancre :** `contextEdit`.

**FR :** Votre texte reste ici. Modifier change vos mots ; Explorer demande des pistes.

**EN :** Your text stays here. Edit changes your words; Explore requests ideas.

**Fin de l’aide :** `contextEdited`, fermeture explicite ou inéligibilité. **Fonctions :** CAN-04, CTX-01. La règle respecte toutes les suppressions transversales décrites plus haut.

### ONB-03 — Retrouver une direction

**Déclencheur :** `branchSetAside` · **Ancre :** `branchReopen`.

**FR :** Cette direction reste conservée. Rouvrir la rend accessible sans la recréer.

**EN :** This direction is preserved. Reopen restores it without regenerating it.

**Fin de l’aide :** `branchReopened`, fermeture explicite ou inéligibilité. **Fonctions :** DEC-02. La règle respecte toutes les suppressions transversales décrites plus haut.

### ONB-04 — Se déplacer sans toucher au contenu

**Déclencheur :** `navigationControlsOpened` · **Ancre :** `navigationControls`.

**FR :** Déplacez la vue avec deux doigts. Les idées gardent leur place dans le document.

**EN :** Pan the view with two fingers. Ideas keep their positions in the document.

**Fin de l’aide :** `cameraPanned`, fermeture explicite ou inéligibilité. **Fonctions :** CAN-01. La règle respecte toutes les suppressions transversales décrites plus haut.

### ONB-05 — Vérifier la portée utilisée

**Déclencheur :** `contextScopeOpened` · **Ancre :** `contextScope`.

**FR :** Cette liste indique les éléments utilisés pour cette demande, pas tout ce que contient votre Mac.

**EN :** This list shows the items used for this request, not everything on your Mac.

**Fin de l’aide :** `contextScopeReviewed`, fermeture explicite ou inéligibilité. **Fonctions :** CTX-06, AI-11. La règle respecte toutes les suppressions transversales décrites plus haut.

### ONB-06 — Comprendre une source

**Déclencheur :** `sourceSelected` · **Ancre :** `sourceStatus`.

**FR :** Une ressource ajoutée peut être partiellement lue. Consultez son état avant d’en tirer une conclusion.

**EN :** An added source may be only partly read. Check its status before drawing a conclusion.

**Fin de l’aide :** `sourceInspected`, fermeture explicite ou inéligibilité. **Fonctions :** CTX-02, CTX-03. La règle respecte toutes les suppressions transversales décrites plus haut.

### ONB-07 — Publication volontaire du brouillon

**Déclencheur :** `sharedDraftReady` · **Ancre :** `publishProposal`.

**FR :** Ce brouillon est privé. Publier le propose à l’équipe sans modifier le document commun.

**EN :** This draft is private. Publish shares the proposal without changing the common document.

**Fin de l’aide :** `proposalPublished`, fermeture explicite ou inéligibilité. **Fonctions :** TEAM-07. La règle respecte toutes les suppressions transversales décrites plus haut.

### ONB-08 — Vérifier la version examinée

**Déclencheur :** `sharedProposalSelected` · **Ancre :** `proposalRevision`.

**FR :** Votre décision porte sur cette version. Si elle change, vous pourrez revoir les différences.

**EN :** Your decision applies to this version. If it changes, you can review the differences.

**Fin de l’aide :** `sharedProposalReviewed`, fermeture explicite ou inéligibilité. **Fonctions :** TEAM-08. La règle respecte toutes les suppressions transversales décrites plus haut.

### ONB-09 — Distinguer disque et équipe

**Déclencheur :** `sharedDocumentReady` · **Ancre :** `storageStatus`.

**FR :** Enregistré sur ce Mac et synchronisé avec l’équipe sont deux états distincts.

**EN :** Saved on this Mac and synced with the team are different states.

**Fin de l’aide :** `syncStatesReviewed`, fermeture explicite ou inéligibilité. **Fonctions :** DOC-04, TEAM-10. La règle respecte toutes les suppressions transversales décrites plus haut.

### ONB-10 — Revenir aux changements utiles

**Déclencheur :** `returnSummaryAvailable` · **Ancre :** `activitySummary`.

**FR :** Vous pouvez lire les décisions et propositions depuis votre dernière visite sans rejouer tous les déplacements.

**EN :** Review decisions and proposals since your last visit without replaying every movement.

**Fin de l’aide :** `returnSummaryOpened`, fermeture explicite ou inéligibilité. **Fonctions :** TEAM-11. La règle respecte toutes les suppressions transversales décrites plus haut.



---

<a id="ch-17"></a>
