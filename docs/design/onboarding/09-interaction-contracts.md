# 17 — Vingt contrats de micro-animation et d’interactivité

## Lecture d’un contrat

Ces vingt contrats complètent l’atlas précédent en précisant particulièrement le lien entre apprentissage, feedback et état métier. Ils ne remplacent pas les identifiants fonctionnels. Une opération ne devient pas complète parce que son animation est réussie. Les paramètres décrits sont des hypothèses de rendu ; leurs critères sont à tester dans l’application native.

La séparation importante est : **déclencheur → état avant → changement métier → projection visuelle → état final → interruption**. Le même état final doit être accessible au clavier et sans mouvement décoratif.

### MIC-01 — Le contexte devient un objet

**Déclencheur :** Validation de la saisie initiale.

**Avant.** Champ avec brouillon et focus ; aucun objet enregistré si la validation a échoué.

**Chorégraphie et ordre.** Création métier d’abord. L’enveloppe devient une surface de contexte, sans réduire le texte à une poussière. Une transition d’environ 220 ms peut accompagner la continuité, sans déplacement caméra imposé.

**Après.** Texte entier conservé ; état de sauvegarde exact ; activité IA séparée si déclenchée.

**Interruption et échec.** Nouvelle saisie ou modèle indisponible ne détruit pas le contexte. Fermeture préserve les données récupérables.

**Accès et mouvement réduit.** Réduire les animations : mise à jour immédiate, même contenu. Focus dans le contexte ou commande accessible, pas arraché vers une astuce.

**V2 :** DOC-02, AI-02 · **Sources d’éclairage :** [R01](#source-r01) · [R05](#source-r05).

### MIC-02 — Sélection et actions locales

**Déclencheur :** Clic ou sélection clavier.

**Avant.** Objet au repos, texte lisible, aucune action obligatoire au survol.

**Chorégraphie et ordre.** Contour immédiatement perceptible ; commandes en fondu bref autour de 140 ms. Leur zone interactive n’attend pas une grande chorégraphie.

**Après.** Sélection persistante ; actions nommées à taille écran et dans le viewport.

**Interruption et échec.** Autre sélection retarget la surface sans confondre l’action déjà engagée ; Échap remonte une couche.

**Accès et mouvement réduit.** Focus clairement différencié de sélection ; commandes accessibles au clavier.

**V2 :** CAN-02 · **Sources d’éclairage :** [R02](#source-r02) · [R25](#source-r25) · [R31](#source-r31).

### MIC-03 — Trajet vers une commande

**Déclencheur :** Le pointeur quitte l’objet vers sa barre.

**Avant.** La barre est ouverte car l’objet est sélectionné.

**Chorégraphie et ordre.** Aucune animation de fuite ou changement de côté. La surface reste en place pendant la traversée.

**Après.** La cible reste cliquable même si la souris avance lentement.

**Interruption et échec.** Clic ailleurs désélectionne selon la règle du canvas, pas simple sortie de l’objet.

**Accès et mouvement réduit.** Hover et focus partagent la même possibilité de lire et fermer ; pas de minuterie agressive.

**V2 :** CAN-02 · **Sources d’éclairage :** [R25](#source-r25) · [R33](#source-r33).

### MIC-04 — Le drag n’attend pas son ressort

**Déclencheur :** Glisser une instance.

**Avant.** Position canonique et offsets transitoires séparés.

**Chorégraphie et ordre.** L’offset suit directement le delta écran converti en monde. Aucune interpolation ajoutée. Les connecteurs utilisent exactement la même géométrie.

**Après.** Une transaction au relâchement ; position finale égale à la prévisualisation.

**Interruption et échec.** Échap ou perte de focus annule proprement l’offset non commité ; aucun drag collé.

**Accès et mouvement réduit.** Alternative par clics et clavier ; mode réduit ne ralentit pas une manipulation essentielle.

**V2 :** CAN-03 · **Sources d’éclairage :** [R06](#source-r06) · [R26](#source-r26) · [R29](#source-r29).

### MIC-05 — Vue et objet ne se déplacent pas ensemble

**Déclencheur :** Pan ou pinch de navigation.

**Avant.** Caméra locale, contenu inchangé.

**Chorégraphie et ordre.** Application directe des événements ; ancre de zoom stable ; ne pas doubler l’inertie système par une animation concurrente.

**Après.** Les positions métier ne changent pas ; les commandes écran restent utilisables.

**Interruption et échec.** Une saisie interne possède son scroll. Perte de focus termine la phase ; événement suivant ne reprend pas un delta ancien.

**Accès et mouvement réduit.** Boutons/menu de zoom et recentrage ; alternative de navigation clavier, focus lisible.

**V2 :** CAN-01 · **Sources d’éclairage :** [R06](#source-r06) · [R22](#source-r22).

### MIC-06 — Saisie attachée sans mouvement parasite

**Déclencheur :** Ajouter ou demander depuis une sélection.

**Avant.** Objet ciblé et commande explicite.

**Chorégraphie et ordre.** Le champ s’ouvre depuis l’ancre sur 140–220 ms ; le texte n’est pas étiré. Le reste du diagramme reste immobile.

**Après.** Cible visible, champ actif, bouton et Cmd+Entrée cohérents.

**Interruption et échec.** Échap conserve le brouillon ; une autre sélection ne change pas sa cible ; aucune soumission pendant composition IME.

**Accès et mouvement réduit.** Entrée ajoute une ligne ; focus à l’intérieur de la saisie ; les gestes du canvas n’interceptent pas le texte.

**V2 :** CTX-01, AI-03 · **Sources d’éclairage :** [R12](#source-r12) · [R30](#source-r30).

### MIC-07 — Accusé de réception d’exploration

**Déclencheur :** Demande réellement acceptée par le coordinateur.

**Avant.** Action disponible, aucun appel en double.

**Chorégraphie et ordre.** Retour visuel local immédiat ; activité indéterminée seulement tant que le traitement court. Aucune pause minimale pour montrer un spinner.

**Après.** Annuler accessible ; le document reste manipulable.

**Interruption et échec.** Annuler marque la demande puis ignore une réponse tardive. Le draft n’est pas effacé par un timeout.

**Accès et mouvement réduit.** Message de statut sans focus forcé ; pas d’annonce de chaque token.

**V2 :** AI-09 · **Sources d’éclairage :** [R08](#source-r08) · [R14](#source-r14) · [R28](#source-r28).

### MIC-08 — Apparition d’une branche proposée

**Déclencheur :** Réponse complète et validée.

**Avant.** Aucun objet canonique nouveau ; placements prévus localement.

**Chorégraphie et ordre.** Connecteur et éléments se révèlent près de leur emplacement final, fondu et éventuel décalage 4–8 pt, autour de 180–280 ms. Pas de texte à scale zéro.

**Après.** Groupe identifié comme Proposition ; contenu lisible ; Keep/Set aside accessibles.

**Interruption et échec.** Un drag ou une autre action peut interrompre la décoration sans changer le candidat ; pas d’autolayout global.

**Accès et mouvement réduit.** Mode réduit : nouveau groupe statique avec label ; annonce agrégée, pas une annonce par nœud.

**V2 :** CAN-08, AI-07 · **Sources d’éclairage :** [R05](#source-r05) · [R18](#source-r18) · [R28](#source-r28).

### MIC-09 — Candidat retenu au même endroit

**Déclencheur :** Keep avec préconditions valides.

**Avant.** Groupe fantôme avec même géométrie que sa forme finale.

**Chorégraphie et ordre.** Appliquer la transaction une fois ; traits discontinus deviennent continus avec fondu bref si pertinent. Ne pas déplacer ni faire grossir les cartes.

**Après.** Objets canoniques, provenance conservée ; undo disponible selon le modèle.

**Interruption et échec.** Erreur de validation : garder le candidat et expliquer ; une interruption d’animation ne fait pas un demi-commit.

**Accès et mouvement réduit.** État accepté lisible sans couleur seule ; focus conservé sur le groupe ou la commande logique suivante.

**V2 :** AI-08, DEC-03 · **Sources d’éclairage :** [R05](#source-r05) · [R06](#source-r06).

### MIC-10 — Lire une modification avant de l’accepter

**Déclencheur :** Proposition de modifier un texte existant.

**Avant.** Texte original et candidateRevision identifiés.

**Chorégraphie et ordre.** Ouvrir une comparaison stable ; pas de morphing permanent entre des formulations. Surligner avec libellés, sans obliger à percevoir un mouvement.

**Après.** La personne peut corriger le candidat ou refuser avant le commit.

**Interruption et échec.** Version changée pendant la lecture : signaler le décalage ; ne pas substituer silencieusement une autre version.

**Accès et mouvement réduit.** Ordre de lecture ancien puis proposé ; différences exprimées en mots, pas seulement barré/couleur.

**V2 :** AI-07, TEAM-08 · **Sources d’éclairage :** [R17](#source-r17) · [R27](#source-r27).

### MIC-11 — Écarter garde une trace

**Déclencheur :** Décision explicite avec raison facultative.

**Avant.** Branche active ou proposition à traiter selon le contrat métier.

**Chorégraphie et ordre.** Replier seulement les descendants exclusifs ; environ 180 ms si mouvement autorisé. Les objets partagés restent accessibles ailleurs.

**Après.** Trace compacte avec raison et Rouvrir ; camera inchangée.

**Interruption et échec.** Annulation rétablit l’action selon les règles ; l’animation ne détruit pas l’historique.

**Accès et mouvement réduit.** Motif lisible et action nommée ; pas rouge d’erreur ni texte trop transparent.

**V2 :** DEC-02, AI-08 · **Sources d’éclairage :** [R05](#source-r05) · [R15](#source-r15).

### MIC-12 — Rouvrir n’est pas régénérer

**Déclencheur :** Action Rouvrir.

**Avant.** Direction écartée avec identité et placements conservés.

**Chorégraphie et ordre.** Révéler les éléments mémorisés ; courte transition de présence, pas de nouvel appel IA.

**Après.** Positions et versions restituées ; raison historique consultable.

**Interruption et échec.** La fermeture du détail n’écarte pas de nouveau la branche. Une preuve manquante reste indiquée comme telle.

**Accès et mouvement réduit.** Action présente au clavier et clic ; annonce de réouverture, sans annoncer tous les descendants.

**V2 :** DEC-02, CAN-09 · **Sources d’éclairage :** [R05](#source-r05) · [R23](#source-r23).

### MIC-13 — Conseil contextuel non bloquant

**Déclencheur :** Éligibilité et arbitrage validés.

**Avant.** Ancre stable visible, aucune saisie/geste/erreur prioritaire.

**Chorégraphie et ordre.** Petit fondu autour de 140 ms ; aucun assombrissement du canvas ; aucune translation de la cible.

**Après.** Une aide maximum ; action principale non couverte ; fermeture disponible.

**Interruption et échec.** Si le geste commence, suspendre le conseil sans annuler ce geste. Impression enregistrée une seule fois.

**Accès et mouvement réduit.** Présentation ne vole pas le focus ; aide interactive distincte du tooltip ; “ne plus montrer” respecté.

**V2 :** DOC-08, CAN-02 · **Sources d’éclairage :** [R03](#source-r03) · [R04](#source-r04) · [R25](#source-r25).

### MIC-14 — Modèle indisponible, document disponible

**Déclencheur :** Échec de disponibilité au moment de l’action.

**Avant.** Contexte local déjà créé.

**Chorégraphie et ordre.** Message factuel apparaît près de la demande, sans écran de connexion ou animation trompeuse.

**Après.** Continuer manuellement et options autorisées ; aucune donnée envoyée au cloud par défaut.

**Interruption et échec.** Disponibilité revenue : le choix de réessayer reste explicite ; aucun rejeu silencieux de toutes les demandes.

**Accès et mouvement réduit.** Motif dans la langue UI, statut annoncé sans popup automatique au centre de la tâche.

**V2 :** AI-01, AI-09 · **Sources d’éclairage :** [R15](#source-r15) · [R28](#source-r28).

### MIC-15 — Échec de sauvegarde visible jusqu’à résolution

**Déclencheur :** Écriture locale refusée.

**Avant.** Modifications actives qui ne sont pas toutes sur disque.

**Chorégraphie et ordre.** Retirer tout succès faux ; exposer une action de récupération ancrée au document. Pas de disparition automatique.

**Après.** Choix de destination ou retry, contenu en mémoire conservé tant que possible.

**Interruption et échec.** Fermer demande de gérer les changements non sauvés ; animation et compte à rebours n’autorisent pas une perte.

**Accès et mouvement réduit.** Annonce mesurée mais durable, focus non arraché pendant frappe sauf action de fermeture explicite.

**V2 :** DOC-04 · **Sources d’éclairage :** [R28](#source-r28) · [R30](#source-r30).

### MIC-16 — Invitation comprise sans tour de créateur

**Déclencheur :** Accès autorisé après acceptation.

**Avant.** Rôle, document et ancre connus ou manque indiqué.

**Chorégraphie et ordre.** Ouvrir la vue liée, cadrage initial lisible et explication courte de l’intention.

**Après.** Actions adaptées au rôle ; accès au contexte, pas de checklist de création imposée.

**Interruption et échec.** Ancre supprimée : explication et point sûr ; aucun accès à des données non autorisées.

**Accès et mouvement réduit.** Lecture logique de tâche puis rôle ; clavier vers l’objet ciblé, pas vers un tip marketing.

**V2 :** TEAM-03, TEAM-04 · **Sources d’éclairage :** [R20](#source-r20) · [R02](#source-r02).

### MIC-17 — Brouillon devient proposition publiée

**Déclencheur :** Publier avec droits valides.

**Avant.** Essai privé et candidateRevision locale.

**Chorégraphie et ordre.** État publication en cours puis confirmation serveur ; ne pas prétendre que l’équipe le voit avant succès.

**Après.** Candidat attribué visible aux destinataires autorisés ; canonique inchangé.

**Interruption et échec.** Réseau coupé : rester En attente avec requête identifiable ; réessai sans double publication.

**Accès et mouvement réduit.** Libellés privés/publiés distincts ; retour d’état sans fanfare ni déplacement du canvas des collègues.

**V2 :** TEAM-07 · **Sources d’éclairage :** [R15](#source-r15) · [R28](#source-r28).

### MIC-18 — Conflit ciblé plutôt que succès silencieux

**Déclencheur :** Serveur refuse une version périmée.

**Avant.** Brouillon local, version examinée et nouvel état commun conservés.

**Chorégraphie et ordre.** Afficher les variantes statiques près de la cible ; suspendre les aides facultatives.

**Après.** Choisir version commune, garder variante ou modifier avant nouveau commit.

**Interruption et échec.** Fermer garde un conflit non résolu et le brouillon ; ne pas compter fermeture comme acceptation.

**Accès et mouvement réduit.** Ordre de lecture explicite des versions, aucune différence seulement portée par animation.

**V2 :** TEAM-08, TEAM-09 · **Sources d’éclairage :** [R12](#source-r12) · [R17](#source-r17).

### MIC-19 — Suivi interrompu par intention locale

**Déclencheur :** Pan/pinch/clic Quitter pendant suivi.

**Avant.** Suivi volontaire identifié.

**Chorégraphie et ordre.** Arrêter immédiatement les cibles caméra reçues ; le geste local reprend sans ressort de rappel.

**Après.** Vue indépendante, documents et droits inchangés.

**Interruption et échec.** Nouveau message de présence ne réactive pas le suivi ; il faut une nouvelle action volontaire.

**Accès et mouvement réduit.** Quitter accessible sans geste ; conservation d’un repère vers le parcours si utile.

**V2 :** TEAM-05, TEAM-13 · **Sources d’éclairage :** [R06](#source-r06) · [R21](#source-r21).

### MIC-20 — Revenir à une cible cherchée

**Déclencheur :** Choix d’un résultat de recherche.

**Avant.** Caméra de départ et raison d’ouverture conservées.

**Chorégraphie et ordre.** Navigation volontaire brève vers la cible ; annuler au premier geste local. Une branche écartée s’ouvre en lecture temporaire.

**Après.** Cible lisible et état métier inchangé ; commande de retour disponible.

**Interruption et échec.** Recherche suivante remplace la navigation, pas l’objet. Réduction de mouvement effectue le déplacement sans zoom animé.

**Accès et mouvement réduit.** Focus cible avec titre et statut ; pas seulement un halo fugitif.

**V2 :** CAN-09 · **Sources d’éclairage :** [R05](#source-r05) · [R23](#source-r23).



---

<a id="ch-18"></a>
