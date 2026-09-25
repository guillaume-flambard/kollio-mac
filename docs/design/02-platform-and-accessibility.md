# 02 — Être natif Apple : comportements avant apparence

## Ce que les sources disent effectivement

Les HIG typographiques distinguent les plateformes : leurs tailles de référence et leurs mécanismes d’adaptation ne sont pas identiques. La documentation indique notamment que macOS n’utilise pas Dynamic Type comme iOS. La page de conseils tactiles d’Apple recommande des zones d’au moins 44 × 44 points pour les commandes visées au doigt. Ces faits ne rendent pas obligatoire une interface de téléphone sur un Mac. [A06, A07]

Le guide Multi-Touch du Mac documente le défilement à deux doigts et le pincement. La configuration du système et les capacités du périphérique comptent. Un double-tap à deux doigts n’est pas le même événement qu’un double-clic. [A08]

## Trois profils de conception, un même document

| Dimension | Mac, cible actuelle | iPad, étude d’adaptation | iPhone, étude d’adaptation |
|---|---|---|---|
| Entrée dominante | Pointeur précis, clavier, trackpad | Toucher, Pencil éventuel, clavier optionnel | Toucher et clavier logiciel |
| Vue d’ensemble | Plusieurs branches lisibles | Vue libre avec commandes atteignables au doigt | Lecture guidée avant montage spatial dense |
| Commandes locales | Barre près de la sélection, menus natifs | Actions au-dessus de la main ou près d’un bord sûr | Groupe d’actions inférieur contextuel |
| Texte long | Développement local ou lecteur temporaire | Surface lisible sans masquer la cible | Lecture occupant la largeur, retour vers le canvas |
| Annulation | Cmd+Z et menu | Contrôle visible + conventions système | Contrôle disponible sans clavier matériel |
| Survol | Amélioration facultative | Pas un prérequis | N’existe pas comme affordance de base |

Ce tableau est une recommandation de Kollio. Il n’ajoute pas une application mobile au lot actuel. L’objectif est d’éviter un modèle d’interaction que l’on ne pourrait ensuite adapter qu’en cassant le document.

## Taille de texte et zoom : deux commandes différentes

Sur Mac, un utilisateur peut trouver 15 points trop petits même lorsque le canvas est à 100 %. Lui dire de zoomer n’est pas suffisant : les positions s’éloignent, des objets sortent de l’écran et les relations se perdent. Le cahier doit distinguer l’échelle du document et la taille de lecture de l’interface.

Je propose une préférence de lisibilité limitée, basée sur une échelle de texte, sans convertir chaque objet en un style indépendant. Le rendu recalcule les dimensions et conserve les ancrages. Ce recalcul est une opération de présentation, non une modification du sens. Si la vue devient encombrée, l’utilisateur dispose d’Organiser la sélection ; l’application ne redistribue pas silencieusement tout le travail.

Sur iPad et iPhone, l’étude cible doit respecter les mécanismes de taille de texte pris en charge et leurs grands réglages. Les commandes peuvent passer sur plusieurs lignes ou changer de disposition. Un bouton rétréci pour faire entrer trois libellés français n’est pas une adaptation.

## Les conventions macOS à préserver

Le menu Fichier donne Nouveau, Ouvrir, Enregistrer et les documents récents. Modifier contient Annuler/Rétablir. La fenêtre Réglages est distincte du document. Les raccourcis ne disparaissent pas parce qu’aucune barre d’outils n’est affichée.

La saisie conserve sélection de texte, accents, méthodes de saisie, raccourcis et menus contextuels du système. Cmd+Entrée soumet une demande Kollio seulement dans le compositeur concerné. Cmd+Z dans un champ annule sa frappe avant d’annuler une ancienne transaction de graphe. Échap ferme un niveau local en restaurant un focus explicite ; il ne détruit ni brouillon ni document.

Ces comportements sont un contrat de produit et une vérification d’intégration. Utiliser SwiftUI ne les rend pas tous automatiquement corrects. Le canvas peut capturer un événement destiné au champ si les couches et priorités ne sont pas testées.

## Le danger du « verre partout »

La transparence ne doit pas faire varier la lisibilité d’une idée selon le contenu qui passe derrière. Les sources Apple distinguent la couche de contrôle du contenu. Notre application doit garder des textes et documents opaques, même si une barre contextuelle utilise un matériau système. [A03, A04]

Le dessin d’une fenêtre transparente peut être séduisant dans une capture officielle où le fond est choisi. Dans une session réelle, une image saturée, un long tableau ou le mode Contraste renforcé révèle immédiatement ses limites. La recette doit donc contenir un arrière-plan perturbant, pas seulement un canvas ivoire vide.

## Variations matériel et environnement

Vérifier écran intégré et externe, petit viewport et grande fenêtre, souris sans trackpad et clavier non américain. Ne pas promettre des performances à 120 Hz sans matériel compatible. L’interface doit rester fonctionnelle lorsque le mouvement est réduit et lorsque l’inférence locale consomme des ressources.

Une application native n’est pas un ensemble d’effets Apple ; c’est une application qui respecte les attentes et les choix de la personne sur sa machine. Les changements purement esthétiques viennent après le bon fonctionnement de cette base.


---

<a id="ch-03"></a>

# 23 — Accessibilité : le diagramme doit exister autrement qu’en pixels

## Le contrat de lecture

Un canvas dessiné comme une image unique peut être visuellement parfait et inutilisable pour une personne qui n’en perçoit pas la composition. Kollio doit exposer des éléments, des relations et des actions structurées. Le titre, l’état utile et la provenance ne sont pas seulement des dessins.

La navigation logique peut parcourir le contexte, les branches et les relations pertinentes. Une relation de causalité ou de contrainte ne doit pas être supprimée du parcours pour réduire la verbosité si elle porte justement le sens du projet. Les éléments décoratifs, eux, n’ont pas besoin d’être annoncés comme contenu.

Le graphe peut contenir des cycles et des contributions partagées. Une liste naïve qui suit toutes les relations risque de répéter sans fin les mêmes objets. Il faut définir une projection accessible avec références explicites : « déjà présent dans cette branche », « utilisé également ici ». Cette projection ne change pas le modèle.

## Navigation et focus

Le focus reste visible, et idéalement entièrement visible. Le critère W3C minimum AA consulté porte sur le fait qu’il ne soit pas entièrement masqué ; notre objectif complet est donc plus exigeant que ce minimum. [W03]

Ouvrir un menu local place le focus dans ce menu. Le fermer revient à l’objet qui l’a ouvert. Supprimer cet objet revient à un parent ou voisin déterminé, avec une annonce. Un résultat de recherche mène à sa cible et conserve un retour ; il ne change pas silencieusement l’état d’une décision.

Une proposition arrivante ne vole pas le focus d’un champ ou d’un lecteur. Une annonce courte indique sa disponibilité. La personne peut choisir quand l’examiner. Les mises à jour de présence ne doivent pas interrompre continuellement la lecture.

## Pointeur simple, toucher et clavier

Trois contrôles sont nécessaires à vérifier : les cibles au pointeur, les cibles tactiles et les accès clavier. Les références ne donnent pas un nombre universel valable partout. Apple propose 44 points pour les cibles tactiles ; W3C AA définit 24 pixels CSS avec exceptions pour son périmètre web. [A07, W04]

Pour les petites commandes macOS personnalisées, un gabarit de 32–36 points écran constitue une proposition d’essai, pas une règle Apple. Les cibles réelles peuvent dépasser la taille de l’icône. Elles ne doivent pas se chevaucher au point de rendre le clic ambigu.

Une action au clavier ne dispense pas de l’alternative au pointeur simple sans glisser discutée dans W3C. [W05] Relier par deux clics et déplacer via une commande sont donc des pistes de conception pertinentes. Elles partagent les mêmes mutations que le drag.

## Survol, durée et erreurs

Une commande ne disparaît pas pendant que la personne essaie de l’atteindre. Les contenus additionnels concernés doivent pouvoir être survolés, fermés et conservés pendant leur utilisation ; cette lecture vient du critère W3C dédié. [W06]

Les tooltips ne contiennent pas l’unique explication d’une action critique. Les erreurs persistantes ne sont pas des toasts trop courts. Les confirmations de partage décrivent les données et destinataires avec assez d’espace pour les lire.

Ne pas remplacer un label par une animation ou une vibration. Le son reste facultatif, et le sens ne dépend pas du matériel haptique. Les utilisateurs ne doivent pas deviner qu’un shake signifie « cette proposition a été refusée par le serveur ».

## Texte et contrastes

Les résultats du chapitre 11 montrent que les tokens opaques sont souvent exploitables mais que leur transparence peut perdre la lisibilité. Cela justifie de garder l’encre lisible dans les fantômes. La bordure décorative n’est pas le focus.

Tester chaque thème sur les surfaces réelles, y compris lorsqu’un matériau translucide est au-dessus d’une image. Une vérification de paires hexadécimales ne remplace pas une capture rendue, mais elle permet de détecter des erreurs évidentes avant la recette.

L’agrandissement du texte doit donner priorité au contenu. Les boutons peuvent changer de disposition, les métadonnées se replier, les textes se développer. Réduire la police pour garder le rectangle d’origine est le contraire de l’adaptation recherchée.

## Mouvement réduit

Le mode réduit retire zooms automatiques décoratifs, translations d’apparition et rebonds. Les couleurs, contours, labels et changements d’état suffisent. Une réponse instantanée ne doit pas rendre l’interface incompréhensible parce que toute la causalité était exprimée par une trajectoire.

Le critère W3C sur les animations déclenchées par interaction est AAA, non AA. [W07] Kollio peut volontairement viser ce confort sans déclarer une conformité web ou native complète. Les mouvements directement commandés restent nécessaires à la manipulation ; ils ne sont pas assimilés à une animation de célébration.

## Matrice de recette proposée

Croiser clair/sombre, mouvement normal/réduit, texte standard/agrandi, clavier/pointeur, document local/partagé. Il n’est pas nécessaire d’exécuter toutes les combinaisons à chaque commit. En revanche, les parcours fondamentaux doivent être couverts avant une validation d’ensemble.

Le test humain cherche des obstacles réels : cible introuvable, ordre de lecture incohérent, contrôle masqué, annonce répétitive, impossibilité de revenir, sens perdu en mode réduit. Le rapport donne des exemples précis plutôt qu’un score global d’accessibilité non justifié.

La présence de fonctions d’accessibilité dans un framework ne dispense pas du travail d’intégration. Les vues personnalisées du canvas constituent précisément la zone où ces contrats risquent d’être oubliés.


---

<a id="ch-24"></a>
