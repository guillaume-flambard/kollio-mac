# 11 — Identité visuelle : vérifier l’encre avant d’ajouter des effets

## Positionnement retenu

**Paper / Ink / Branch** reste une bonne direction de travail pour Kollio. Paper est un fond qui accueille du contenu sans réclamer l’attention. Ink est une hiérarchie typographique durable. Branch est une transformation de relations qui reste compréhensible. Ce n’est ni un thème de post-it, ni une métaphore de bureau réaliste, ni une identité de chatbot.

Le caractère doit venir du rapport entre les masses de texte, de la précision des liens et de la continuité des états. Un logo discret suffit au prototype. Il n’est pas utile de produire une marque animée, une famille d’illustrations et une mascotte avant que le contexte et les deux premières pistes fonctionnent.

Les couleurs définies dans V2 sont conservées comme base. Les remplacements éventuels passent par des tokens, jamais par des corrections locales sans cohérence. Les thèmes clair et sombre ne sont pas de simples inversions de luminance : le contraste d’un texte blanc sur un accent clair peut devenir insuffisant.

## Calculs effectués pour cette recherche

Les rapports ci-dessous ont été calculés sur les valeurs sRGB opaques de V2 avec la formule de luminance relative. Le script et les résultats sont fournis. Les lignes avec transparence sont des simulations de composition sRGB, **pas des captures mesurées du renderer SwiftUI**. Les seuils sont les repères W3C choisis pour le test. [W01, W02]

| Paire | Rapport calculé | Lecture |
|---|---:|---|
| Texte principal clair / fond clair | 14,06:1 | Marge confortable pour le texte |
| Texte secondaire clair / fond clair | 5,39:1 | Passe le repère 4,5:1 à opacité pleine |
| Cobalt clair / fond clair | 5,42:1 | Passe pour un libellé courant |
| Blanc / bouton cobalt clair | 5,82:1 | Association exploitable |
| Relation essentielle claire / fond clair | 3,69:1 | Passe le repère graphique 3:1 |
| Bordure décorative claire / blanc | 1,33:1 | Ne peut pas porter seule un contrôle essentiel |
| Texte secondaire sombre / surface sombre | 7,25:1 | Marge confortable |
| Texte sombre / accent clair du thème sombre | 8,12:1 | Association exploitable |
| Blanc / accent du thème sombre | 2,15:1 | À éviter pour le texte du bouton |
| Bordure décorative sombre / surface sombre | 1,45:1 | Décoration, pas indicateur de focus suffisant |
| Secondaire clair à 50 % / fond clair | ≈2,07:1 | Trop faible pour le texte courant |
| Principal clair à 50 % / fond clair | ≈3,03:1 | Ne respecte pas le repère 4,5:1 |

Deux conséquences immédiates : **ne pas rendre les propositions lisibles à 50 % d’opacité**, et **ne pas employer systématiquement du texte blanc sur tous les accents**. Le trait discontinu et le libellé Proposition peuvent suffire à distinguer un candidat ; il n’a pas à devenir difficile à lire.

Une bordure décorative faible n’est pas un bug en soi. Elle devient un problème si elle est le seul moyen de reconnaître un champ, un contrôle ou la sélection. Le focus doit utiliser un autre contraste et une forme visible. Tester aussi les surfaces adjacentes, pas seulement le fond principal du canvas.

## Hiérarchie typographique opérationnelle

À 100 % sur Mac, conserver les valeurs V2 comme première variante : invitation 28, contexte 22, idée 18, texte 15, action 13, métadonnée 12 points. Ce sont des choix Kollio ; Apple publie ses propres références selon la plateforme, et la lecture dépend du contenu et des préférences. [A06]

Le contexte est plus fort que ses détails, mais il ne doit pas devenir un titre publicitaire occupant la moitié du viewport. Une longue phrase est limitée visuellement à un extrait avec accès au texte complet. Les noms de fichiers peuvent se tronquer au milieu lorsque l’extension reste utile, tandis qu’une décision doit garder assez de mots pour ne pas en inverser le sens.

Ne pas utiliser cinq graisses. Regular pour lire, medium pour distinguer, un accent supplémentaire exceptionnel pour une erreur ou un titre. Les capitales techniques et l’espacement excessif entre lettres peuvent servir un petit repère, pas tous les titres de nœuds. Le texte du document reste sélectionnable dans son mode de lecture développé.

## Les dimensions servent le contenu

Les plages de largeur V2 restent des gabarits, pas des dimensions rigides : pensée 200–300 points, référence compacte 200–280, résultat 300–420. La hauteur dépend de la langue et des préférences de lecture. Un label qui se coupe est un signal pour adapter le composant, pas pour réduire sa police automatiquement.

Les actions proches d’un objet utilisent des points écran constants. Elles ne deviennent pas minuscules au dézoom. L’interface peut réduire les détails du document, mais elle conserve une zone d’action atteignable et une manière de développer le texte.

## Accent et vérité

Le cobalt indique l’attention, la sélection ou la proposition. Il ne signifie pas « correct ». L’ambre indique quelque chose à examiner, pas un danger certain. Le rouge reste réservé à une erreur ou une action destructive significative. Une direction écartée reste neutre et explicable : la présenter en rouge peut donner l’impression d’une faute plutôt que d’un choix situé.

Les sources n’obtiennent pas un sceau de confiance parce qu’elles sont importées. Préférer une icône de document, un nom et un état concret : importé, extrait partiellement, inaccessible. La validation d’une interprétation apparaît dans une décision distincte.

## Signature graphique proposée

L’élément distinctif est un embranchement net dont l’épaisseur et les points d’attache restent cohérents. Le langage de forme repose sur quelques rayons et des relations propres, pas des variations aléatoires. À petite taille, la marque pourrait être un K ramifié, mais sa création n’est pas nécessaire à l’expérience.

La recette visuelle comprend un document long, des sources colorées derrière les contrôles, du français, une fenêtre étroite et le mode sombre. Une capture de six titres courts ne suffit pas à valider le système.


---

<a id="ch-12"></a>

# 12 — L’interface épurée : où chaque chose doit apparaître

## Une carte des niveaux, pas une collection de panneaux

Le V2 définit U00 à U13. Nous les conservons en répartissant l’expérience en quatre niveaux : document au repos, actions de proximité, lecture concentrée, opérations de portée globale. Cette répartition est un schéma de conception ; elle n’ajoute pas quatre onglets.

| Niveau | Question de l’utilisateur | Surface | Sortie attendue |
|---|---|---|---|
| Document | Où en sommes-nous ? | U01, idées et relations | Sélection ou navigation |
| Proximité | Que puis-je faire ici ? | U02/U03/U04 | Commande ou proposition |
| Lecture | Que signifie exactement cet élément ? | U05/U09/U11 | Retour à l’ancre |
| Portée globale | Que vais-je enregistrer, partager ou configurer ? | U06/U07/U08/U10/U13 | Retour au document sans perte |

Une interface peut être visuellement petite et conceptuellement lourde. Une puce qui cache dix sous-menus et trois états invisibles n’est pas forcément plus simple qu’un dialogue clair. Les recommandations de divulgation progressive et de modalité soutiennent une hiérarchie compréhensible, pas le dogme du zéro fenêtre. [R05, A11]

## U00 : donner une première prise

L’invitation doit répondre à trois questions : où écrire, quelle information suffit, ce qui se produira après validation. Une courte phrase de contexte suffit. Le champ conserve les retours à la ligne. Le bouton Explorer agit après avoir créé le contexte local, même si l’IA devient indisponible.

« Ouvrir un document » reste une voie secondaire lisible. Une démo n’est pas le chemin par défaut. Aucun choix de fournisseur ne s’impose avant la première phrase. Si le modèle manque, la personne peut continuer manuellement ou choisir explicitement la démo.

## U01 : le calme n’est pas l’absence d’état

Le titre du document et l’accès au menu suffisent en haut. Le canvas montre le contexte et les branches. Les contrôles de navigation restent discrets mais retrouvables au clavier et par un accès visible. Une erreur de sauvegarde persiste assez longtemps pour être comprise ; elle ne disparaît pas pour conserver une capture jolie.

Le statut de partage n’est pas répété sur chaque objet. Il apparaît au niveau du document et lorsqu’une action transmet des informations. Le brouillon d’une proposition garde son propre statut. L’IA locale n’efface pas le fait qu’un document est partagé.

## U02 : trois actions seulement quand elles sont pertinentes

Une idée ordinaire expose Explorer, Ajouter et Écarter selon V2. Un contexte expose Explorer, Modifier et Ajouter une source. Une source expose Ouvrir, Utiliser ici et Voir l’origine. Cette variation évite de faire apprendre une barre identique dont deux boutons seraient souvent désactivés.

La barre ne surgit pas uniquement au survol. Elle suit la sélection et reste atteignable pendant le trajet du pointeur. Ses limites sont calculées dans le viewport, sans couvrir le titre. La variation de largeur entre français et anglais est mesurée. Si aucun emplacement ne fonctionne, une disposition compacte à côté de l’ancre vaut mieux qu’un contrôle en dehors de la fenêtre.

Un menu Plus explicite garde les actions moins fréquentes. Les labels annoncent l’effet : « Retirer du tableau » ne promet pas une suppression définitive. Les ellipses peuvent annoncer une information encore requise, conformément aux conventions de menu, sans être appliquées arbitrairement à chaque bouton. [A09]

## U05 : lire long sans construire un inspecteur

Un paragraphe peut se développer localement. Une ressource plus longue peut ouvrir un lecteur temporaire avec sa provenance et une commande Retour au canvas. Le point de retour conserve l’ancre et sa sélection. Fermer le lecteur ne change pas le statut de la source.

Le lecteur ne devient pas le lieu de toutes les propriétés. On y lit le contenu et les informations nécessaires à sa fiabilité. La méthode complète, les erreurs d’extraction ou le choix de pages ont leur place lorsqu’ils servent la tâche présente.

## U07 et U10 : les exceptions nécessaires

Partager un document exige de comprendre quels objets, sources et branches quittent le Mac. Un dialogue centré et lisible est préférable à une minuscule popover débordant sur le diagramme. La personne voit le destinataire, le rôle et le périmètre avant l’envoi. Fermer n’envoie rien.

Un conflit sur une phrase peut être traité près de cette phrase. Plusieurs modifications longues peuvent nécessiter une surface de comparaison temporaire. Elle montre version commune et variante locale, conserve le brouillon et permet de revenir. Ce n’est pas un prétexte pour ouvrir une application de merge dans l’application, mais ce n’est pas non plus interdit par une règle de minimalisme.

## Mesure de la sobriété

Pour chaque état, identifier l’action principale, le contenu essentiel et le moyen de retour. Noter les contrôles qui ne servent aucune tâche disponible. Retirer ces derniers avant d’ajouter une animation.

Tester également l’accès au secondaire : retrouver une source, une décision passée ou un export. Si la personne ne sait pas que ces fonctions existent, l’interface n’est pas encore simple ; elle est opaque.


---

<a id="ch-13"></a>

# 17 — Lire, citer, retrouver : le canvas n’est pas une carte miniature de tout

## Une ressource possède plusieurs états visibles

Une ressource peut être déposée, extraite, partiellement lue, utilisée dans une proposition, remplacée ou inaccessible. Ces états ne se résument pas à une icône de trombone. Le V2 distingue explicitement source, preuve et décision ; la présentation doit conserver cette distinction.

Au repos, un `ReferenceChip` montre titre, format et état utile. Son ouverture révèle le contenu effectivement disponible, la version et le lien avec la question concernée. Une extraction partielle est annoncée près de l’aperçu. Le titre seul ne donne pas le droit d’affirmer qu’un document a été analysé.

## Déposer sans surprendre

Pendant le drag d’un fichier, mettre en évidence une cible valide. Si le dépôt se fait sur une branche, l’aperçu annonce « Ajouter comme source à cette branche ». Si le dépôt se fait dans le vide, il crée une référence indépendante. Le système ne choisit pas silencieusement de l’envoyer au modèle.

Au relâchement, la source apparaît avec un état d’import réel. Si l’application copie le fichier, cela doit être clair ; si elle conserve une référence externe, le risque de fichier déplacé doit être géré. Les gestes ne remplacent pas un contrat de stockage.

Un aperçu de tableau montre d’abord les en-têtes et quelques lignes. Le nombre affiché ne doit pas laisser croire qu’il s’agit de toutes les lignes analysées. La largeur du tableau et la lecture horizontale se gèrent dans sa surface, pas en faisant défiler toute la carte avec les colonnes.

## Citer un fait exact

Dans Sarah, constater la présence de la colonne `tags` est différent d’affirmer que les tags sont corrects, exhaustifs ou utilisables dans tout produit. La preuve doit pointer vers la version de la source et la partie concernée. Le libellé proposé est « Colonne tags présente dans cette version », pas « Tags validés ».

Une citation près d’une affirmation peut être compacte. En l’ouvrant, l’utilisateur retrouve l’extrait et sa source, puis revient à l’affirmation. Le chemin n’est pas une fenêtre générique de propriétés. Si la source n’est plus accessible, l’affirmation reste visible avec une limite explicite et les contrôles nécessaires à sa révision.

## Lecture longue et mode concentré

Le V2 permet un lecteur temporaire lorsqu’un contenu dépasse le développement local. Nous gardons cette possibilité. Un PDF de plusieurs pages, une méthode détaillée ou un historique de décision n’a pas à tenir dans une carte de 250 points.

Le lecteur indique sa cible, sa source et sa place dans le document. Une commande de retour ramène au canvas en conservant caméra et sélection si elles sont encore valides. Fermer le lecteur n’annule pas un commentaire déjà publié et ne détruit pas un brouillon privé.

Dans le futur iPad, cette lecture peut occuper une grande partie de l’écran. Dans le futur iPhone, elle peut devenir la surface principale temporaire. Ce n’est pas un changement de modèle : le contenu et ses références restent identiques.

## Retrouver sans réécrire

Cmd+F cherche dans le document. Les résultats peuvent inclure une décision écartée si le filtre le prévoit. Ouvrir un résultat masqué révèle temporairement son emplacement ; cela ne rouvre pas la décision. Le résultat indique titre, extrait et contexte d’appartenance.

Cmd+K propose des commandes et documents récents selon V2. Le nom et une indication de stockage évitent de confondre deux documents au même titre. Le passage entre fenêtres ne transporte pas une proposition de A vers B. Les brouillons et tâches appartiennent à une session explicite.

Un état vide de recherche dit « Aucun résultat dans ce document » plutôt que « Rien n’existe ». Si l’index n’inclut pas encore une source, sa portée est indiquée. Un modèle ne doit pas inventer un résultat pour éviter une liste vide.

## Exporter est aussi une expérience de lecture

L’utilisateur voit le périmètre : contenu actif, branches écartées, discussions, sources et données manquantes. Une exportation d’image représente une vue, tandis qu’un `.kollio` porte le document vivant. Les deux ne doivent pas être vendus comme équivalents.

Une synthèse peut indiquer la révision du document sur laquelle elle repose. Elle ne remplace pas le contexte original. Le lecteur externe peut avoir besoin du résultat sans les discussions privées ; il faut une prévisualisation honnête, pas une case minuscule cochée par défaut pour tout inclure.

## Langue et fidélité

Les libellés d’interface sont localisés. Le contenu de l’utilisateur ne change pas de langue lors d’un réglage. Une source anglaise peut coexister avec une idée française. Une éventuelle traduction est une version explicitement générée et liée à l’original.

Tester les titres longs, les accents, les nombres, les dates et les extensions de fichiers. Une interface française dans laquelle les labels natifs sont traduits mais les exemples forcés restent anglais n’est pas un parcours complet de localisation.

Features concernées : DOC-03/05/06/08, CTX-02/03/06/07, AI-06/11/12, CAN-09, EXT-01.


---

<a id="ch-18"></a>
