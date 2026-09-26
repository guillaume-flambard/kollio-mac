# 08 — Patterns UI : choisir la bonne surface pour chaque information

## Quatre questions avant d’ajouter un composant

L’information est-elle nécessaire pour agir maintenant ? Demande-t-elle une décision ? Peut-elle être consultée sans interrompre ? Où se situe son objet d’origine ? Ces questions donnent souvent une meilleure réponse que « faisons une popup plus jolie ».

Un bouton effectue une action. Un label décrit un état. Une info-bulle explique brièvement sans interaction complexe. Une surface de détail peut contenir des liens et contrôles. Une confirmation rassemble un choix dont la portée justifie une interruption. Un toast est une information transitoire, pas un lieu fiable pour une erreur qui risque de faire perdre le travail.

L’APG W3C distingue notamment le tooltip, qui ne reçoit pas le focus, d’un contenu comprenant des éléments focalisables. [R33](#source-r33) Dans Kollio natif, cela conduit à nommer honnêtement la barre d’actions ou le popover utilisé, au lieu de cacher des boutons de décision dans une « simple tooltip ».

## Tableau de décision proposé

| Besoin de la personne | Surface | Durée de présence | Retour normal |
|---|---|---|---|
| Savoir ce que fait une icône | Label ou courte explication | Tant que consultée | Reste sur la même commande. |
| Agir sur une idée | Actions locales | Tant que la sélection est active | Même ancre après action. |
| Lire une source longue | Détail ou lecteur temporaire | Jusqu’à fermeture explicite | Même objet et caméra. |
| Comprendre une proposition | Ghost group et résumé d’impact | Tant qu’en attente | Acceptation, refus ou masquage distinct. |
| Choisir entre versions en conflit | Comparaison locale stable | Jusqu’à décision | Travail non choisi récupérable. |
| Réparer une sauvegarde | État durable avec action | Jusqu’à résolution | Statut réellement mis à jour. |
| Apprendre un raccourci | Conseil facultatif | Consultation/fermeture/action | Pas de changement métier. |
| Partager hors du Mac | Dialogue de portée | Jusqu’à validation ou annulation | Aucune sortie avant confirmation. |

## Affordance avant commentaire

Si une source ressemble à une phrase ordinaire mais ouvre un fichier, son icône, son titre et son état doivent suggérer cette possibilité. Si une branche est repliée, un contrôle d’ouverture distingue repli visuel et décision écartée. Si une proposition contient un changement sur un objet existant, montrer la différence avant de mettre en avant Retenir.

Le texte d’aide ne compense pas un statut trompeur. Écrire « vous pouvez annuler » ne suffit pas si l’annulation perd le texte original. Écrire « local » ne suffit pas si le proxy contacte un service externe. Chaque libellé engage le comportement décrit dans le V2.

## Actions principales et secondaires

Le maximum de trois actions locales est une limite de composition de départ. Il ne faut pas remplacer trois libellés clairs par trois icônes ambiguës pour gagner de la place. Si une action fondamentale est toujours reléguée au sous-menu puis cherchée par les utilisateurs, revoir sa priorité plutôt que lui ajouter un conseil permanent.

Les actions fréquentes restent à position stable pour un même type d’état. L’arrivée d’une suggestion ne doit pas déplacer sous le pointeur le bouton qui allait être pressé. Les droits et l’état de la cible peuvent modifier les actions, mais cette modification doit laisser une explication lorsqu’elle surprendrait la personne.

## Les confirmations sont proportionnées

L’édition d’un titre local ne demande pas un dialogue de confirmation ; elle conserve l’annulation. Accepter une proposition passe déjà par un aperçu explicite : ne pas ajouter systématiquement « Êtes-vous sûr ? ». En revanche, une publication ou une suppression irréversible nécessite une portée et un engagement identifiables.

Une confirmation n’est pas un écran de droit que l’utilisateur doit mémoriser. Elle cite l’objet, l’action et les conséquences présentes. Elle n’ajoute pas une formule vague « cette action peut avoir des conséquences ». Le choix sûr doit préserver les données, pas seulement fermer la fenêtre.



---

<a id="ch-09"></a>

# 09 — Interactivité directe : les gestes et les commandes ne doivent pas se combattre

## Un arbitre d’événements explicite

L’interaction commence par la priorité de la cible. Dans une saisie, le drag peut sélectionner du texte. Sur un bouton, le geste appartient au contrôle. Sur un objet, il déplace une instance. Sur un connecteur, il sélectionne la relation ou utilise une poignée active. Sur le fond, il navigue ou trace une sélection selon le mode défini.

Cette priorité doit être écrite et testée plutôt que dépendre accidentellement de l’ordre de modificateurs SwiftUI. L’agent vérifie le comportement réel du framework et n’ajoute pas un moniteur AppKit global capturant tous les événements pour contourner un bug local.

## Le clic n’est pas encore un drag

La pression signale immédiatement une cible possible. Le début d’un déplacement suit un seuil adapté au système. Tant qu’il n’est pas dépassé, la personne peut cliquer, déplacer légèrement involontairement le pointeur ou relâcher sans créer une transaction de mouvement. À l’inverse, quand le drag est engagé, le contenu suit directement le pointeur : pas de ressort « élégant » qui le fait traîner.

Le commit du mouvement arrive à la fin du geste. Échap ou une annulation système restaure l’état transitoire selon le contrat ; la sauvegarde ne capture pas des dizaines de coordonnées intermédiaires. Déplacer à 80 %, 100 % ou 180 % utilise le même repère et les connecteurs suivent la géométrie affichée.

## La commande reste possible sans trajectoire précise

Le V2 prévoit des actions visibles et le clavier. Nous ajoutons une recette spécifique de pointeur sans glisser : sélectionner puis choisir une destination ou utiliser des déplacements nommés. Ce n’est pas un panneau obligatoire affiché à tous ; c’est une alternative atteignable dans les commandes pertinentes. Le critère W3C sur le drag sépare expressément cette capacité de l’alternative au clavier. [R26](#source-r26)

Pour relier, une méthode « source puis destination » réduit la dépendance à une poignée minuscule. L’utilisateur voit la source sélectionnée et peut annuler avant de choisir la cible. Un état de validation donne la nature possible du lien ; le logiciel ne déclare pas un lien causal simplement parce que deux points ont été cliqués.

## Le trajet vers les actions doit être praticable

Les commandes apparaissent près de l’objet mais ne disparaissent pas dans l’espace entre celui-ci et la barre. Survol et sélection ne sont pas le même état : une sélection persiste après sortie du pointeur. La surface temporaire reste fermable, son focus visible et sa position bornée à la fenêtre. Le test n’est pas « le bouton apparaît », mais « je peux l’atteindre sans devoir accélérer ou suivre un couloir invisible ». [R25](#source-r25)

Lorsqu’un texte agrandit l’objet ou que le viewport rétrécit, recalculer l’ancrage sans déplacement continu de tous les contrôles. Mesurer la surface effective, pas une largeur constante incompatible avec le français. Garder le contrôle focalisé lisible ; la version native du test n’est pas validée uniquement par un attribut d’accessibilité.

## Texte, clavier et variantes de gestes

Les touches à lettre seule n’agissent pas dans un champ. Cmd+Z annule la saisie active avant une ancienne transaction du graphe. La touche de soumission, le retour à la ligne et la fermeture doivent être vérifiés avec clavier français et méthodes de saisie en composition. Une séquence de composition ne déclenche pas prématurément une exploration.

Le double-clic Explore reste la convention V2 jusqu’à décision contraire. La recherche proposée compare sa compréhension à celle d’un double-clic Éditer, sans basculer l’application en douce. Quelle que soit la variante retenue, l’action principale doit rester disponible autrement.

## Rentrer et sortir d’une interaction

Pour chaque geste, spécifier ce qui se passe si la fenêtre perd le focus, la cible disparaît, les droits changent ou une autre personne modifie le texte. Une erreur ne laisse pas un mode main actif à l’insu de l’utilisateur. Une commande qui ne peut plus s’appliquer abandonne avec explication et laisse le brouillon récupérable. Le retour au calme est aussi important que l’animation d’entrée.



---

<a id="ch-10"></a>
