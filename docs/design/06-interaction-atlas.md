# 21 — Atlas de 44 micro-interactions

Chaque fiche est une **proposition de design à vérifier**, pas un comportement observé chez un concurrent ni un test exécuté dans Kollio. Les identifiants IX sont stables. Les fonctionnalités citées conservent leurs identifiants V2. Les durées sont des valeurs de départ ; le résultat métier ne dépend jamais de leur fin.

## IX-01 — Arriver dans un document vierge

**Périmètre V2 :** DOC-01, DOC-02.

**Déclenchement et état.** Aucun document restaurable, aucune erreur à masquer. La fenêtre passe de chargement réel à U00, sans injecter Sarah ni demander un compte.

**Contrat visuel.** Invitation, champ multiligne et une action Explorer. Le groupe conserve assez d’espace pour le clavier et les aides. Aucun placeholder n’est pris pour un texte déjà saisi.

**Mouvement.** Entrée immédiate ou fondu ≤140 ms si la transition est déjà disponible. Ne pas attendre une animation de logo ni déplacer continuellement le groupe selon l’état du modèle.

**Interruption et données.** La saisie peut commencer dès que le champ est prêt. Une restauration tardive ne remplace pas des mots déjà entrés. Une erreur de fichier utilise la récupération, pas cet état vide.

**Accessibilité / mouvement réduit.** Focus annoncé sur le champ ; l’invitation est son contexte accessible. En mouvement réduit, aucune translation. Tester le clavier seul et une préférence de texte accrue.

**Recette.** Installation de test vierge : saisir avant 140 ms, coller un paragraphe, changer le focus. Les mots restent intacts et aucune génération involontaire ne part.

## IX-02 — Transformer la saisie en contexte

**Périmètre V2 :** DOC-02, CTX-01.

**Déclenchement et état.** Cmd+Entrée ou bouton après saisie valide. Une commande crée un contexte local ; la requête IA est une opération distincte.

**Contrat visuel.** Le contenant devient un élément de contexte. Un extrait est autorisé si le texte est long, avec ouverture de l’original. La position finale est décidée avant la révélation.

**Mouvement.** Enveloppe en 220 ms maximum de départ ; texte non étiré. Le mouvement peut être remplacé par un fondu croisé court entre deux rendus à taille lisible.

**Interruption et données.** Un double envoi est ignoré ou rattache la même action. Une erreur de stockage garde la saisie. La fin de l’animation ne décide ni la sauvegarde ni le lancement de la génération.

**Accessibilité / mouvement réduit.** Annonce courte « Contexte créé ». Le focus arrive à l’objet ou à son action selon le parcours clavier. Variante réduite : changement immédiat, texte et statut suffisants.

**Recette.** Coller 3 paragraphes puis valider deux fois. Vérifier un document, un contexte, texte original récupérable et absence de deux générations.

## IX-03 — Saisir une précision près d’un objet

**Périmètre V2 :** CTX-01, AI-04, CAN-04.

**Déclenchement et état.** Ajouter ou répondre à une clarification ouvre U03 pour une cible précise. Le mode Ajouter une information ou Demander est explicite.

**Contrat visuel.** Champ ancré, titre de cible court et bouton de validation. Six lignes maximum comme gabarit initial puis défilement intérieur. Le canvas ne suit pas le scroll du texte.

**Mouvement.** Apparition 140 ms ; hauteur adaptée sans faire bouger les objets voisins. Aucun streaming du modèle pendant la frappe.

**Interruption et données.** Échap ferme en gardant un brouillon privé. Reprendre la même cible retrouve ce brouillon. Changer de document ne le publie pas ailleurs.

**Accessibilité / mouvement réduit.** Étiquette de cible et champ accessible ; Enter reste retour à la ligne. Le passage focus ne repose pas sur le survol. Réduction du mouvement : apparition sans déplacement.

**Recette.** Écrire une phrase distinctive, fermer, rouvrir et envoyer. Un service de capture doit recevoir exactement cette phrase et le bon identifiant de cible.

## IX-04 — Sélectionner une pensée

**Périmètre V2 :** CAN-02.

**Déclenchement et état.** Clic simple ou parcours clavier sur une instance active. La sélection est un état local, indépendant de sa validité métier.

**Contrat visuel.** Contour ou fond discret, lisible avec le thème. Actions adaptées proches de l’objet. L’élément focalisé conserve un anneau distinct si plusieurs objets sont sélectionnés.

**Mouvement.** Retour immédiat ; transition de couleur ≤100 ms. Aucun déplacement, zoom ou décalage du texte. La barre apparaît au plus avec reveal 140 ms.

**Interruption et données.** Maj+clic ajuste le groupe. Clic vide ou Échap retire un niveau selon V2. Changer la sélection peut masquer un aperçu, jamais effacer une proposition conservée.

**Accessibilité / mouvement réduit.** Annonce titre et état utile, pas « carte ». La couleur est doublée par un repère de forme. Réduction du mouvement conserve le changement de sélection.

**Recette.** Sélectionner au clavier, puis Maj+clic deux objets. Vérifier absence de génération, visibilité du focus et maintien d’une proposition précédente.

## IX-05 — Survoler sans agir

**Périmètre V2 :** CAN-02.

**Déclenchement et état.** Le pointeur entre dans une cible non sélectionnée. Aucun état métier ou sélection durable n’est modifié.

**Contrat visuel.** Léger fond, contour ou repère de prise. Ne pas révéler un inspecteur complet ni détourner l’attention depuis l’objet sélectionné.

**Mouvement.** Feedback 100 ms, sortie brève. Le composant ne change ni taille ni position. Le tooltip peut attendre environ 500 ms sans retarder le clic.

**Interruption et données.** Le clic prend priorité sur le délai du tooltip. La sortie du pointeur ne ferme pas une action déjà ouverte par sélection.

**Accessibilité / mouvement réduit.** Aucune capacité uniquement disponible au survol. Les aides apparaissent aussi au focus lorsque pertinent. Un utilisateur tactile reçoit les mêmes actions via sélection.

**Recette.** Traverser rapidement dix objets : aucune popup persistante, aucune sélection accidentelle, aucune ligne de texte qui se déplace.

## IX-06 — Atteindre les actions contextuelles

**Périmètre V2 :** CAN-02.

**Déclenchement et état.** Sélection unique disposant d’actions. U02 s’ouvre après le feedback de sélection.

**Contrat visuel.** Maximum trois libellés principaux, menu secondaire clair. Placer à environ 12 points écran de la cible, à l’intérieur du viewport, sans couvrir son titre.

**Mouvement.** Fondu 140 ms et éventuellement translation ≤4 points écran. Le contrôle reste stable pendant le trajet de la souris.

**Interruption et données.** Une nouvelle cible recalcule l’ancre une fois. La barre ne fuit pas à chaque mouvement. Un drag actif masque temporairement les contrôles sans perdre la sélection.

**Accessibilité / mouvement réduit.** Zone traversable entre carte et actions ; focus clavier dans un ordre cohérent. Échap retourne à l’objet. Réduction de mouvement : fondu court ou immédiat.

**Recette.** Tester les quatre coins à 50, 100 et 200 % de zoom, FR/EN et texte agrandi. Tous les boutons restent atteignables sans changer la caméra.

## IX-07 — Modifier le texte existant

**Périmètre V2 :** CAN-04.

**Déclenchement et état.** Modifier ou raccourci convenu cible un contenu existant. L’action ne sollicite pas le modèle.

**Contrat visuel.** Champ de texte dans le même contexte, original intégral disponible. Les actions de génération se retirent de la zone de frappe. La hauteur suit le contenu.

**Mouvement.** Transition de surface ≤140 ms, pas de morphing des caractères. Le caret apparaît immédiatement et la sélection native est conservée.

**Interruption et données.** Cmd+Z annule d’abord la frappe selon le champ. Une fermeture involontaire préserve le brouillon. Un changement distant provoque une comparaison plutôt qu’un écrasement.

**Accessibilité / mouvement réduit.** Libellé « Modifier [titre] », pas un éditeur sans nom. Défilement intérieur indépendant. Variante réduite sans différence de fonctionnalité.

**Recette.** Éditer un texte long, sélectionner une phrase, utiliser copier/coller et undo. Aucun drag de carte ni commande de canvas ne doit intercepter ces gestes.

## IX-08 — Développer un contenu pour le lire

**Périmètre V2 :** CAN-10, CTX-03, DEC-06.

**Déclenchement et état.** Ouvrir un texte, une preuve ou une raison. U05 est une lecture, pas un passage automatique en édition.

**Contrat visuel.** Surface au-dessus de l’ancre, largeur plafonnée adaptée au viewport. Provenance et retour visibles. Pour une ressource longue, lecteur temporaire nommé.

**Mouvement.** Expansion d’enveloppe 220 ms, texte révélé sans étirement. Les voisins restent à leur place. Ne pas animer une énorme hauteur page par page.

**Interruption et données.** Recliquer ou Échap replie depuis l’état courant. Cliquer une autre source change le contenu avec son identité, pas une superposition illisible de lecteurs.

**Accessibilité / mouvement réduit.** Focus envoyé au titre ou à la zone de lecture, restauré à l’ancre à la fermeture. Pas de piège clavier dans une surface non modale.

**Recette.** Ouvrir une raison longue près du bord, sélectionner son texte et revenir. La caméra et le contenu voisin sont inchangés.

## IX-09 — Déplacer une sélection

**Périmètre V2 :** CAN-03.

**Déclenchement et état.** Drag engagé sur une instance ou un groupe sélectionné après le seuil de la plateforme. Le pointeur possède le geste jusqu’au relâchement.

**Contrat visuel.** Objets et liens suivent immédiatement. Élévation discrète sans rotation ni croissance qui fausserait la prise. Positions relatives conservées.

**Mouvement.** Aucune interpolation du mouvement ; ombre ou contour peut changer en 100 ms. À la dépose, pas de lancer inertiel ni de rebond.

**Interruption et données.** Une transaction finale ; Échap avant dépose restaure la position. Perte de focus traite explicitement le geste. Aucun write sémantique à chaque frame.

**Accessibilité / mouvement réduit.** Alternative Déplacer ici et navigation clavier disponible. Réduire les animations ne réduit pas la fidélité au pointeur.

**Recette.** Même drag écran à différents zooms : delta monde correct, lien attaché, une seule annulation restaure tout le groupe.

## IX-10 — Pan au trackpad

**Périmètre V2 :** CAN-01.

**Déclenchement et état.** Scroll sur le canvas ou espace+glisser hors saisie. Les événements d’un lecteur ou champ actif ont priorité.

**Contrat visuel.** La caméra suit l’entrée. Les objets ne changent pas de coordonnées documentaires. Le contexte de sélection reste cohérent.

**Mouvement.** Pas de spring artificiel. Les phases de momentum de navigation prises en charge sont traitées une fois, sans ajouter une deuxième inertie.

**Interruption et données.** Début d’un geste local interrompt une caméra animée ou un suivi volontaire. Fin, annulation et perte de focus remettent les deltas temporaires à zéro.

**Accessibilité / mouvement réduit.** Commandes de navigation sans geste précis disponibles. Le mouvement direct reste autorisé en mode réduit, sans décoration.

**Recette.** Deux doigts sur canvas puis sur texte long : le premier déplace la vue, le second le texte. Aucun double delta ni objet déplacé.

## IX-11 — Pincer pour zoomer

**Périmètre V2 :** CAN-01.

**Déclenchement et état.** Magnification dans le canvas. Capturer le point monde sous l’ancre et le zoom de début de geste.

**Contrat visuel.** La cible sous l’ancre reste stable ; contrôles locaux à taille écran. La hiérarchie de détail peut changer seulement avec des seuils stables.

**Mouvement.** Manipulation directe, bornes 20–250 % issues de V2. Ne pas additionner plusieurs fois le facteur cumulatif.

**Interruption et données.** Un nouveau geste reprend l’état courant. Une limite ne produit pas de vibration graphique ou d’oscillation. Cmd+1 est une action séparée.

**Accessibilité / mouvement réduit.** Boutons/menus de zoom disponibles au clavier. La lecture ne dépend pas exclusivement du pinch. Le mode réduit garde le zoom contrôlé directement.

**Recette.** Pincer au centre puis près d’un bord avec une sélection : dérive d’ancre mesurée, contrôles lisibles et aucune nouvelle génération.

## IX-12 — Recentrer volontairement

**Périmètre V2 :** CAN-01, CAN-09.

**Déclenchement et état.** Cmd+0 ou Voir la proposition. L’utilisateur demande explicitement une cible de caméra.

**Contrat visuel.** Le résultat final inclut une marge lisible. Ne pas introduire un fit global après une décision locale. Une navigation de retour garde son sens.

**Mouvement.** Transition de caméra environ 260 ms ; trajectoire simple. Pour un trajet très long, privilégier un changement sobre plutôt qu’un vol touristique.

**Interruption et données.** Pan, pinch ou nouvelle demande de navigation interrompt immédiatement et repart de l’état affiché. Aucun verrou d’entrée jusqu’à la fin.

**Accessibilité / mouvement réduit.** Mode réduit : saut contrôlé avec cible annoncée. Le focus suit le résultat demandé, pas un objet voisin choisi au hasard.

**Recette.** Interrompre le recadrage à mi-course, puis déplacer une carte. Aucun retour automatique vers l’ancienne cible.

## IX-13 — Créer manuellement un voisin

**Périmètre V2 :** CAN-05, CTX-01.

**Déclenchement et état.** Ajouter ici ou double-clic vide selon V2, sans clic accidentel de simple désélection.

**Contrat visuel.** Un champ indique l’emplacement d’ajout et éventuellement la cible d’association. Le texte validé devient une pensée, sans sélection obligatoire d’un type technique.

**Mouvement.** Apparition 140 ms ; objet final au même emplacement que la saisie. Aucune cascade de contenu généré.

**Interruption et données.** Échap conserve le brouillon prévu par V2 ou annule explicitement la création vide. Une commande finale est annulable.

**Accessibilité / mouvement réduit.** Menu Ajouter et raccourci équivalent ; création au point connu lorsque sans pointeur. Focus dans le texte puis sur l’objet créé.

**Recette.** Créer trois voisins puis relier le dernier ailleurs. Vérifier qu’aucune dépendance causale n’a été inventée par leur proximité.

## IX-14 — Créer une relation

**Périmètre V2 :** CAN-06.

**Déclenchement et état.** Relier depuis une source puis choisir une cible, ou utiliser une poignée si le mode le permet.

**Contrat visuel.** Prévisualisation de ligne et sens proposé ; extrémités stables. Le libellé distingue association, dépendance et soutien lorsqu’applicable.

**Mouvement.** Ligne provisoire suit directement le pointeur. Confirmation : trait stable en ≤140 ms, pas de lumière qui parcourt le câble.

**Interruption et données.** Échap annule sans relation orpheline. Type incompatible refusé près de la cible. Ne pas changer une relation existante par simple chevauchement.

**Accessibilité / mouvement réduit.** Alternative source puis cible au clic, et choix par liste temporaire au clavier. Zone de clic élargie sans rendre le trait lui-même énorme.

**Recette.** Créer, annuler, recréer à 200 % puis supprimer la relation. Les objets restent inchangés et la direction du label est comprise.

## IX-15 — Sélectionner une relation

**Périmètre V2 :** CAN-06.

**Déclenchement et état.** Clic sur le trait, son label ou son équivalent accessible. L’instance sélectionnée référence une relation métier connue.

**Contrat visuel.** Trait accentué, extrémités identifiables, actions Expliquer / Modifier / Retirer. L’étiquette ne change pas de sens avec la sélection.

**Mouvement.** Contour ou teinte ≤100 ms. La zone de capture initiale est 10–12 points écran ; l’épaisseur visible reste environ 1,5–2 points.

**Interruption et données.** Une autre sélection ferme le contrôle sans modifier le lien. À une intersection, permettre de distinguer les candidats plutôt que choisir au hasard.

**Accessibilité / mouvement réduit.** Annonce « [source] bloque [cible] » ou libellé équivalent. Le menu peut être invoqué sans viser la courbe. Mode réduit identique hors fade.

**Recette.** Sélectionner deux liens croisés à plusieurs zooms. Confirmer que chaque action vise la bonne relation et pas son voisin.

## IX-16 — Replier un groupe de lecture

**Périmètre V2 :** CAN-07, CAN-10.

**Déclenchement et état.** Chevron de groupe ou action Replier. Il s’agit d’une présentation locale, pas d’un rejet métier.

**Contrat visuel.** Une enveloppe compacte garde titre, nombre utile et repère d’ouverture. Les autres occurrences de contenus partagés restent visibles ailleurs.

**Mouvement.** Transition environ 180–220 ms sur le groupe concerné. Ne pas faire voler tous les descendants vers le centre du document.

**Interruption et données.** Réouverture restitue les positions conservées. L’annulation de navigation n’écrit aucune décision. Une cible en cours d’édition garde son brouillon.

**Accessibilité / mouvement réduit.** État développé/replié annoncé et action nommée. En mode réduit, changement direct avec conservation du focus au groupe.

**Recette.** Replier, chercher un enfant, le lire sans rouvrir la décision et revenir. Les états métier et autres occurrences sont intacts.

## IX-17 — Montrer une inférence en cours

**Périmètre V2 :** AI-01, AI-02, AI-03, AI-09.

**Déclenchement et état.** Requête explicite admise par le coordinateur. La cible et la destination effective sont connues.

**Contrat visuel.** Indication locale près de l’ancre avec Annuler. Texte « Exploration en cours » et destination réelle, sans pourcentage inventé.

**Mouvement.** Le feedback débute immédiatement ; le résultat rapide n’attend pas un minimum esthétique. Un indicateur système peut fonctionner sans déplacer la branche.

**Interruption et données.** Annuler met fin au cycle visible ; les autres éditions restent actives. Une limite de concurrence donne une réponse locale, pas une file invisible illimitée.

**Accessibilité / mouvement réduit.** Annonce du début une seule fois, puis de l’issue. Pas de répétition à chaque frame. Variante réduite conforme au composant système ou libellé statique.

**Recette.** Réponse instantanée, réponse lente, annulation : aucune durée artificielle, double demande ni blocage du pan.

## IX-18 — Faire apparaître une branche fantôme

**Périmètre V2 :** AI-02, AI-03, AI-07, CAN-08.

**Déclenchement et état.** Un candidat complet et valide est disponible ; il n’est pas encore canonique.

**Contrat visuel.** Relations discontinues et objets à leur future position. Le texte reste opaque. Une indication de proposition et l’auteur/destination distinguent le statut.

**Mouvement.** Branche 280 ms de départ ; décalage 4–8 points écran et léger stagger plafonné à 120 ms. Le sens prime sur un ordre décoratif complexe.

**Interruption et données.** Objets interactifs dès leur présentation valide. Une annulation ou un changement de document retire le candidat sans muter le canonique. Aucun recadrage imposé.

**Accessibilité / mouvement réduit.** Annonce du nombre de changements et accès à la revue. Mode réduit : apparition stable immédiate ou fondu court ; même contenu lisible.

**Recette.** Comparer les positions du preview aux positions après Keep. Tester une réponse hors écran et son action Voir, sans caméra volée.

## IX-19 — Corriger une proposition avant décision

**Périmètre V2 :** AI-07, TEAM-07.

**Déclenchement et état.** Modifier un titre ou contenu de candidat. En équipe, la correction vise une version du brouillon ou de la proposition publiée.

**Contrat visuel.** Même enveloppe de proposition, champ local et état Modifié utile. Ancien contenu conservé pour une revue si cela affecte une version déjà publiée.

**Mouvement.** Entrée en édition ≤140 ms. Pas d’inférence par caractère ; pas d’animation du texte qui bouge sous le caret.

**Interruption et données.** Valider relance les contrôles déterministes. Une erreur laisse la saisie. Publier une révision est distinct de l’édition privée.

**Accessibilité / mouvement réduit.** Focus natif ; lien vers la version examinée. Reduce Motion n’altère ni les informations de version ni la possibilité de corriger.

**Recette.** Modifier puis publier une version 2 pendant qu’un autre client lit la version 1. L’acceptation ancienne ne s’applique pas silencieusement.

## IX-20 — Retenir un candidat

**Périmètre V2 :** AI-08, DEC-01, TEAM-08.

**Déclenchement et état.** Utilisateur autorisé, candidat précis, préconditions encore valides. Un groupe cohérent est accepté en une transaction.

**Contrat visuel.** Le trait devient continu, le label de proposition laisse place au statut ordinaire. Conserver exactement les objets et leur placement montrés.

**Mouvement.** Stabilisation ≤180 ms de départ, sans déplacement ni confetti. Les états ne dépendent pas de la fin de l’effet.

**Interruption et données.** Double clic ne double pas le commit. Un rejet de préconditions garde la proposition à revoir. Cmd+Z utilise l’inverse ou la compensation définie par V2.

**Accessibilité / mouvement réduit.** Annonce « Proposition retenue » après l’état confirmé approprié. En partagé, distinguer envoi en attente et acceptation confirmée. Réduit : changement immédiat.

**Recette.** Keep, double Keep, Undo puis Redo : IDs, relations et géométrie cohérents ; aucun objet fantôme orphelin.

## IX-21 — Fermer un aperçu sans le rejeter

**Périmètre V2 :** AI-08, CAN-02.

**Déclenchement et état.** Action Fermer/Masquer sur un aperçu non accepté, ou changement de sélection qui le masque temporairement.

**Contrat visuel.** Les fantômes se retirent ; une voie de retour vers la proposition existe selon V2. Aucun mot Écarté n’est ajouté sans décision.

**Mouvement.** Fade de sortie ≤160 ms ; pas de rangement visible dans une corbeille qui suggérerait une suppression.

**Interruption et données.** La proposition conserve son identité et ses préconditions. À la reprise, elle peut être stale et doit le signaler. Rien n’est accepté automatiquement.

**Accessibilité / mouvement réduit.** Libellé explicite « Fermer l’aperçu », pas une croix sans nom. Focus rendu à l’ancre. Variante réduite immédiate.

**Recette.** Fermer puis retrouver le candidat après une autre sélection. Vérifier absence de décision de rejet durable et contrôle de fraîcheur conservé.

## IX-22 — Écarter une direction avec mémoire

**Périmètre V2 :** DEC-02, AI-08.

**Déclenchement et état.** Action Écarter appliquée à une direction ou proposition selon son contrat. Motif demandé de manière légère, non inventé par le modèle.

**Contrat visuel.** Trace compacte portant titre et motif condensé. Les descendants exclusifs se replient ; les contributions utilisées ailleurs demeurent présentes.

**Mouvement.** Transition locale ≈180 ms. Réduire l’enveloppe, pas l’opacité du texte jusqu’à le rendre illisible. Caméra inchangée.

**Interruption et données.** Une erreur de commande laisse le graphe intact. Rouvrir restaure le contenu connu. Fermer le champ du motif ne doit pas valider silencieusement la décision.

**Accessibilité / mouvement réduit.** Statut et action Rouvrir nommés. Une raison longue se développe. En mode réduit, repli immédiat sans perte d’information.

**Recette.** Écarter A qui partage X avec B : A compact, B et X actifs, motif après relance, caméra strictement conservée.

## IX-23 — Rouvrir une direction

**Périmètre V2 :** DEC-02.

**Déclenchement et état.** Clic sur Rouvrir, raccourci ou action accessible d’une branche écartée.

**Contrat visuel.** Retour des objets, relations et emplacements connus. L’ancienne raison reste consultable, la nouvelle décision explique la réouverture.

**Mouvement.** Révélation locale ≤220 ms, sans impression de génération neuve. Pas d’appel IA ni de placement recalculé arbitrairement.

**Interruption et données.** Nouveau geste peut interrompre l’effet, pas la cohérence du domaine. Si un élément référencé manque, afficher la limite au lieu d’en inventer un.

**Accessibilité / mouvement réduit.** Focus retourne à la branche rouverte ou à sa cible choisie. Mode réduit identique sémantiquement.

**Recette.** Rouvrir après save/quit/reload et non seulement dans la même session. Les IDs et positions attendus sont retrouvés.

## IX-24 — Montrer un impact à examiner

**Périmètre V2 :** CTX-05, DEC-01, AI-07.

**Déclenchement et état.** Une nouvelle information ou version de source affecte explicitement certaines hypothèses ou décisions.

**Contrat visuel.** Accentuer localement source, liens et cibles. Texte « 2 éléments à revoir » fondé sur le résultat réel. Ouvrir montre les raisons et la portée.

**Mouvement.** Un seul pulse de contour doux ≤220 ms facultatif, puis état stable. Aucun clignotement ni cascade automatique de suppressions.

**Interruption et données.** L’utilisateur peut lire ailleurs ; les changements restent en attente. La disparition de la preuve ne choisit pas automatiquement une autre direction.

**Accessibilité / mouvement réduit.** Résumé lisible sans animation ; ordre de lecture source puis conséquences. Réduit : contour et message statiques.

**Recette.** Une preuve de A ne bloque ni B ni une contribution partagée sans dépendance requise. Le participant doit pouvoir expliquer cette portée.

## IX-25 — Signaler un candidat obsolète

**Périmètre V2 :** AI-07, AI-09, TEAM-08.

**Déclenchement et état.** Le contexte lu ou la version du candidat change avant acceptation. Le statut stale est établi par validation, pas par une simple navigation.

**Contrat visuel.** Aperçu conservé mais Retenir désactivé avec raison et actions Revoir/Actualiser. Montrer les références qui ont changé lorsque disponibles.

**Mouvement.** Transition de statut ≤100 ms. Pas de shake ou de disparition totale du candidat. Un avant/après reste stable à lire.

**Interruption et données.** Une nouvelle génération est explicite et n’efface pas le brouillon. Un pan ou un zoom seul ne déclenche pas ce statut.

**Accessibilité / mouvement réduit.** Annonce concise et non répétée. Le contrôle désactivé explique sa condition. Réduction de mouvement sans différence de compréhension.

**Recette.** Modifier le texte pendant l’inférence, puis essayer Keep. Comparer au même test avec un simple pan : seul le premier exige une revalidation métier.

## IX-26 — Annuler une requête

**Périmètre V2 :** AI-09.

**Déclenchement et état.** Annuler pendant une exploration active, fermer sa fenêtre ou changer de cible/session selon le contrat.

**Contrat visuel.** L’indicateur quitte l’attente ; retour local « Exploration annulée » lorsqu’utile. Le contexte et le brouillon restent disponibles.

**Mouvement.** Sortie 100–160 ms, sans attendre la fin du calcul fournisseur. Aucun résultat partiel animé dans le document canonique.

**Interruption et données.** Une réponse tardive est ignorée. La nouvelle demande reçoit une nouvelle identité. L’effet visuel n’est pas l’implémentation de l’annulation.

**Accessibilité / mouvement réduit.** Bouton clavier/lecteur accessible. Annonce finale une fois. Aucun avertissement sonore obligatoire.

**Recette.** Simuler une réponse reçue après cancel et après ouverture d’un autre document : aucun objet ajouté dans l’un ou l’autre.

## IX-27 — Afficher une erreur récupérable

**Périmètre V2 :** AI-09, DOC-04.

**Déclenchement et état.** Échec de génération ou de sauvegarde classifié. Le message correspond à ce qui a réellement échoué.

**Contrat visuel.** Erreur près de l’opération, avec texte conservé et action adaptée. Une erreur de sauvegarde persistante reste retrouvable au niveau du document.

**Mouvement.** Apparition brève ≤140 ms. Pas de secousse générale, pas de confetti rouge. Ne pas faire disparaître automatiquement l’unique voie de récupération.

**Interruption et données.** Réessai manuel valide les conditions actuelles. Le message n’efface pas un succès indépendant. Un échec réseau ne bascule pas vers un autre fournisseur.

**Accessibilité / mouvement réduit.** Rôle d’annonce approprié sans monopoliser le lecteur d’écran. Message FR/EN compréhensible, pas code HTTP brut. Réduit : aucune translation.

**Recette.** Déclencher modèle indisponible puis disque plein simulé : actions et textes distincts, données conservées, aucune fausse mention Enregistré.

## IX-28 — Importer une source

**Périmètre V2 :** CTX-02.

**Déclenchement et état.** Dépôt explicite d’un fichier ou dialogue d’ouverture vers une branche ou le vide.

**Contrat visuel.** Cible de dépôt surlignée et effet annoncé. ReferenceChip avec nom, format et état import/extraction réel ; aucun sceau de validation prématuré.

**Mouvement.** Retour de dépôt immédiat ; apparition 140 ms. La progression mesurable d’une extraction peut être indiquée séparément de l’IA.

**Interruption et données.** Annuler l’import ne supprime pas le fichier source. Échec laisse une référence en erreur récupérable ou annule proprement selon V2. Pas d’envoi cloud au dépôt.

**Accessibilité / mouvement réduit.** Alternative Ajouter une source via menu. Le label annonce état et nom ; progression annoncée avec parcimonie. Mode réduit identique.

**Recette.** Importer un CSV valide puis un fichier trop gros : bon état, aperçu fidèle, nombre analysé explicite, original conservé.

## IX-29 — Remplacer une version de source

**Périmètre V2 :** CTX-07, CTX-05.

**Déclenchement et état.** L’utilisateur choisit un nouveau fichier pour une source connue ; identité du contenu et nouvelle version sont distinguées.

**Contrat visuel.** ReferenceChip affiche la version actuelle. Les affirmations liées à l’ancienne peuvent porter À revoir, avec accès à leur ancienne référence.

**Mouvement.** Changement de statut ≤140 ms. Aucun remplacement animé qui efface les différences entre les fichiers avant lecture.

**Interruption et données.** Annuler préserve l’ancienne version. Une extraction incomplète de la nouvelle n’est pas annoncée comme une validation complète.

**Accessibilité / mouvement réduit.** Version et état accessibles, lecteur avant/après disponible. Mode réduit conserve les différences textuelles.

**Recette.** CSV avec tags puis sans tags : seule la preuve concernée demande révision, l’ancien historique reste consultable.

## IX-30 — Chercher et rejoindre un objet

**Périmètre V2 :** CAN-09, DOC-06.

**Déclenchement et état.** Cmd+F dans le document ou Cmd+K pour commandes/documents, selon le contrat existant.

**Contrat visuel.** Palette temporaire, titre et extrait, distinction local/partagé et état écarté. Sélectionner un résultat révèle son chemin sans changer sa décision.

**Mouvement.** Ouverture 140 ms ; navigation vers résultat environ 260 ms si autorisée. Pas de repli/reouverture métier automatique.

**Interruption et données.** Échap retourne au point et focus précédents. Un résultat devenu inaccessible est nommé comme tel et ne vise pas un homonyme.

**Accessibilité / mouvement réduit.** Liste navigable clavier, résultats annoncés sans lire chaque frappe. Mouvement réduit : cible immédiate et focus visible.

**Recette.** Trouver une raison dans une branche écartée, la lire et revenir : décision toujours écartée et aucun appel modèle.

## IX-31 — Changer de document

**Périmètre V2 :** DOC-03, DOC-06.

**Déclenchement et état.** Ouvrir un autre document ou activer une autre fenêtre. Chaque session garde ses brouillons et sa caméra.

**Contrat visuel.** Titre et contenu corrects, sans mélange de propositions. Restaurer une vue existante, pas rejouer l’onboarding.

**Mouvement.** Pas de morphing entre graphes sans parenté. Changement immédiat ou fondu très court si nécessaire pour éviter un flash.

**Interruption et données.** Les résultats du document précédent ne sont pas publiés dans le nouveau. Retour restaure son contexte de travail lorsque conservé.

**Accessibilité / mouvement réduit.** Annonce du nouveau document, pas lecture de tout le graphe. Focus initial déterminé ; aucun clavier piégé dans une ancienne palette.

**Recette.** Deux fenêtres dont une génère : basculer puis recevoir la réponse. Chaque élément reste associé à sa propre session.

## IX-32 — Enregistrer et informer

**Périmètre V2 :** DOC-04, TEAM-10.

**Déclenchement et état.** Transaction validée, flush explicite ou autosave. Synchronisation réseau éventuelle indépendante.

**Contrat visuel.** État discret dans le menu/titre du document. Enregistré sur ce Mac n’est pas Synchronisé. Erreur persistante accessible.

**Mouvement.** Aucune animation de contenu. Petit changement d’état ≤100 ms ; pas de badge de succès répété à chaque caractère.

**Interruption et données.** Une nouvelle écriture ne masque pas une erreur non résolue. Fermer doit conserver une récupération ou permettre un choix adapté.

**Accessibilité / mouvement réduit.** Annonce uniquement les événements utiles, pas tous les autosaves. Le contraste du statut est lisible. Variante réduite identique.

**Recette.** Sauvegarder hors ligne puis relancer : contenu présent, sync encore en attente, aucune affirmation que le serveur a confirmé.

## IX-33 — Prévisualiser un partage

**Périmètre V2 :** TEAM-02, DOC-05.

**Déclenchement et état.** Owner ouvre Partager depuis le document. Aucune donnée n’est envoyée par la simple ouverture du dialogue.

**Contrat visuel.** Surface temporaire montrant destination, rôle et périmètre exact : sources, branches écartées, commentaires. Actions Partager et Annuler.

**Mouvement.** Présentation native concentrée. Ne pas déplacer tous les objets vers une animation de nuage ou de serveur.

**Interruption et données.** Fermer conserve le document privé. Une erreur d’upload laisse une reprise claire et ne produit pas un lien prétendument utilisable.

**Accessibilité / mouvement réduit.** Focus géré comme dialogue, titre et sortie accessibles. Ordre de lecture révèle le périmètre avant confirmation.

**Recette.** Ouvrir puis annuler, ensuite partager sans une source : vérifier absence de premier envoi et exclusion conservée dans le second.

## IX-34 — Accepter une invitation

**Périmètre V2 :** TEAM-03, TEAM-04.

**Déclenchement et état.** Destinataire authentifié ouvre une invitation encore valide. Rôle et document sont présentés avant acceptation.

**Contrat visuel.** Vue courte, précise, sans accès anticipé au contenu non autorisé. Le mauvais compte propose un changement de session sans effacer les documents privés.

**Mouvement.** Transition native sobre ; pas d’avatars fictifs célébrant l’arrivée. Après succès, ouvrir le document à un point cohérent.

**Interruption et données.** Lien expiré ou révoqué conserve une erreur explicite. Rejouer l’acceptation ne crée pas un second participant.

**Accessibilité / mouvement réduit.** Rôle nommé en français/anglais, bouton d’acceptation sans ambiguïté. Retour clavier standard.

**Recette.** Viewer accepté reste viewer. Invitation rejouée, expirée et mauvais compte ont des sorties distinctes.

## IX-35 — Publier un brouillon de contribution

**Périmètre V2 :** TEAM-07.

**Déclenchement et état.** Contributor ou editor choisit de publier un candidat privé. Le texte en cours de frappe n’a pas été diffusé.

**Contrat visuel.** La proposition passe de Privé à Publication en cours puis Publiée, avec auteur et version. Les autres voient un candidat, pas un changement déjà accepté.

**Mouvement.** Stabilisation locale ≤180 ms. La présence distante n’entraîne pas une caméra forcée. Aucun mouvement lié aux frappes privées.

**Interruption et données.** Échec réseau garde le brouillon. Nouvelle édition crée une nouvelle version selon V2 ; elle ne conserve pas une ancienne approbation comme si rien n’avait changé.

**Accessibilité / mouvement réduit.** Annonce de publication réelle et droit du rôle. Mode réduit conserve ces états. Une icône cloud seule ne suffit pas.

**Recette.** Deux sessions : écrire sans publier n’apparaît pas chez le collègue ; publier produit une seule proposition attribuée.

## IX-36 — Demander une modification

**Périmètre V2 :** TEAM-08, TEAM-06.

**Déclenchement et état.** Reviewer sélectionne une version publiée et choisit Demander une modification.

**Contrat visuel.** Champ attaché à la proposition, motif, version concernée. La proposition reste ouverte ; l’auteur reçoit un événement utile.

**Mouvement.** Champ révélé en 140 ms. Aucun rejet rouge ni disparition du candidat. Message envoyé devient une discussion lisible.

**Interruption et données.** Annuler préserve le brouillon ; une autre version arrivée pendant la rédaction exige de préciser laquelle est visée.

**Accessibilité / mouvement réduit.** Titre de cible et rôle de la demande explicités. Le champ et son envoi sont accessibles sans pointer une branche fine.

**Recette.** Envoyer une demande puis réviser le candidat : discussion et version restent cohérentes, aucun canonique modifié.

## IX-37 — Résoudre un conflit ciblé

**Périmètre V2 :** TEAM-09.

**Déclenchement et état.** Deux transactions ne peuvent être conciliées automatiquement selon le contrat. La version commune et le brouillon local sont conservés.

**Contrat visuel.** Comparaison stable près de l’objet ou lecteur temporaire si long. Actions conserver commune, variante ou édition. Montrer les références affectées.

**Mouvement.** Apparition ≤140 ms ; pas de morphing entre phrases pendant la lecture. Le canvas reste stable.

**Interruption et données.** Fermer ne choisit pas arbitrairement une version. Les opérations indépendantes peuvent continuer ; celles qui dépendent du conflit attendent.

**Accessibilité / mouvement réduit.** Versions étiquetées en texte, pas seulement vert/rouge. Lecture séquentielle disponible. Réduit : comparaison identique.

**Recette.** Deux titres concurrents : aucune perte de mots. Résoudre en variante garde les deux apports et leurs auteurs.

## IX-38 — Suivre puis reprendre sa caméra

**Périmètre V2 :** TEAM-05, TEAM-13.

**Déclenchement et état.** Invitation de présentation ou commande Suivre un participant acceptée volontairement.

**Contrat visuel.** Petit état Vous suivez [nom] avec Quitter. Les mouvements distants concernent la caméra, pas les décisions.

**Mouvement.** Navigation distante bornée et sobre ; pas de grands voyages permanents. Premier pan/pinch local sort immédiatement du suivi.

**Interruption et données.** Déconnexion du présentateur stoppe le suivi et conserve la vue actuelle. Aucun réabonnement silencieux à son retour.

**Accessibilité / mouvement réduit.** Commande Quitter accessible au clavier. Mode réduit : changement de vue discret sans vol animé, annonces d’étapes plutôt que coordonnées.

**Recette.** Nora zoome pendant la présentation d’Alex : Nora libre, Alex inchangé, les autres participants non affectés.

## IX-39 — Perdre puis retrouver le réseau

**Périmètre V2 :** TEAM-10.

**Déclenchement et état.** Document partagé ouvert, connexion perdue. Les données locales autorisées restent disponibles.

**Contrat visuel.** Enregistré localement / En attente de synchronisation. L’outbox reste inspectable en résumé, sans barre animée permanente.

**Mouvement.** Changement de statut bref. À reconnexion, ne pas rejouer toutes les animations des opérations mises en file.

**Interruption et données.** Revalidation des droits et conflits avant envoi. Fermer et relancer conserve les modifications en attente selon V2.

**Accessibilité / mouvement réduit.** État compréhensible sans couleur, non répété par VoiceOver à chaque retry. Réduit : aucun mouvement réseau décoratif.

**Recette.** Couper le réseau, modifier, quitter, rouvrir et reconnecter. Aucun doublon, aucun succès partagé annoncé avant confirmation.

## IX-40 — Perdre un accès partagé

**Périmètre V2 :** TEAM-04, TEAM-12.

**Déclenchement et état.** Le serveur ou une reconnexion confirme une révocation ou un changement de rôle.

**Contrat visuel.** Action d’écriture suspendue, message local durable et options réellement autorisées. Le brouillon ne disparaît pas derrière un écran générique.

**Mouvement.** Aucune animation punitive. Contrôles mis à jour immédiatement, focus déplacé seulement si son ancienne cible n’est plus utilisable.

**Interruption et données.** Aucun commit tardif. Export/copie uniquement si le contrat le permet. Ne pas promettre une purge de fichiers déjà exportés.

**Accessibilité / mouvement réduit.** Annonce du changement de droit et de la prochaine action. Pas de commande grisée sans raison.

**Recette.** Révoquer Nora hors ligne puis reconnecter : travail en attente reconnu, envoi interdit, message non assimilé à fichier supprimé.

## IX-41 — Comprendre ce qui a changé

**Périmètre V2 :** TEAM-11, DEC-06.

**Déclenchement et état.** L’utilisateur choisit Depuis ma dernière visite ou ouvre une nouveauté ciblée.

**Contrat visuel.** Résumé temporaire des décisions, sources et propositions ; pas le replay de tous les déplacements. Chaque item possède une ancre et un état.

**Mouvement.** Apparition 140 ms. Navigation vers un item sur demande seulement. Pas de défilement automatique de caméra en ouvrant le résumé.

**Interruption et données.** Marquer lu reste personnel. Un élément supprimé est signalé, pas rattaché à un homonyme. Fermer ramène à la vue initiale.

**Accessibilité / mouvement réduit.** Liste structurée navigable, nombre exact. Réduit : lecture identique et navigation non animée.

**Recette.** Trois événements utiles et cent drags : le résumé reste compréhensible et ne marque pas les événements du collègue comme lus.

## IX-42 — Essayer un petit outil

**Périmètre V2 :** STU-04, STU-05, STU-09.

**Déclenchement et état.** Ouvrir un ResultBlock et lancer un essai autorisé sur des données de démonstration.

**Contrat visuel.** Entrées, limites et sortie sont claires. Un résultat déterministe diffère d’une interprétation IA. Les erreurs de colonnes apparaissent près de l’entrée.

**Mouvement.** Retour immédiat puis progrès réel si disponible. Résultat révélé en 180 ms environ, pas de séquence de faux terminal.

**Interruption et données.** Changer les entrées invalide la sortie précédente comme résultat actuel. Annuler ne modifie pas le document source. Pas de script tiers arbitraire.

**Accessibilité / mouvement réduit.** Lecture de formulaire native, résultat structuré accessible et export. Réduit : aucune perte d’état.

**Recette.** CSV valide puis colonne manquante : sortie réelle différente, erreur exacte, aucune capture figée présentée comme calcul.

## IX-43 — Exporter une vue ou un document

**Périmètre V2 :** DOC-05, EXT-01.

**Déclenchement et état.** Menu Exporter, sélection du format et du périmètre.

**Contrat visuel.** Prévisualisation du contenu inclus, avertissement d’actifs manquants et distinction image/document vivant. Destination via dialogue système.

**Mouvement.** Présentation native ; aucune animation de succès avant création effective. Un progrès déterminé n’apparaît que si la quantité est connue.

**Interruption et données.** Annuler laisse l’original intact. Échec d’écriture conserve la configuration de l’export et propose une autre destination.

**Accessibilité / mouvement réduit.** Champs et périmètre lisibles au clavier. Mode réduit suit le dialogue système. Le document exporté n’hérite pas de secrets.

**Recette.** Exporter sans discussions privées puis rouvrir le fichier : contenu conforme à la preview, pas seulement extension correcte.

## IX-44 — Changer la lisibilité et la langue

**Périmètre V2 :** DOC-08, CAN-10.

**Déclenchement et état.** Préférence de langue, thème ou taille de lecture, ou changement système pris en charge.

**Contrat visuel.** Libellés s’adaptent, contenu authored conservé. Le contraste est recalculé par tokens ; le texte agrandi n’est pas coupé pour garder une taille fixe.

**Mouvement.** Éviter l’animation de toute la géométrie pendant une adaptation typographique importante. Conserver l’ancre de lecture et le focus.

**Interruption et données.** Une saisie en cours ne se réinitialise pas. Une langue de contenu différente de l’UI reste possible et n’est pas traduite silencieusement.

**Accessibilité / mouvement réduit.** Sur Mac, ne pas prétendre que Dynamic Type iOS s’applique partout. Vérifier contrôles et document à chaque taille retenue. Réduit : immédiat.

**Recette.** FR→EN→FR pendant édition d’une phrase française : phrase identique, clés absentes, boutons entiers et focus utile conservé.



---

<a id="ch-22"></a>
