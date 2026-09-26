# 01 — La décision centrale : apprendre en conservant le contrôle

## Le problème n’est pas le nombre d’écrans d’accueil

Une personne peut fermer cinq écrans de bienvenue et ne pas comprendre pourquoi un trait est discontinu. Elle peut aussi ne voir aucun écran d’accueil et croire que la première réponse du modèle est déjà une décision du projet. Le premier problème est une charge inutile ; le second est une ambiguïté dangereuse pour un outil de travail. Supprimer les tutoriels ne résout pas automatiquement le second.

Notre objectif proposé est une **première valeur maîtrisée**. La personne a produit ou récupéré un contenu qui lui sert, sait si ce contenu est une suggestion ou un élément retenu, et connaît une façon de le modifier ou de revenir en arrière. Le produit peut y arriver avec une IA, manuellement ou en lecture d’un document invité. Il n’existe pas un seul bouton dont le clic prouverait cette compréhension.

## Les quatre apprentissages à rendre possibles

**Expression.** Je peux apporter ma situation avec mes mots. Je ne dois pas transformer ma phrase en prompt sophistiqué ni choisir entre huit types de nœuds. Le texte original existe toujours après la réponse.

**Interprétation.** Je reconnais la différence entre mon apport, une ressource, une proposition et une décision. Cela se comprend par les libellés, les relations et les actions, pas uniquement par une couleur.

**Contrôle.** Je peux éditer, refuser, masquer et rouvrir. L’existence de ces voies doit être perceptible avant que je regrette une action. Une fois une branche conservée, son identité et sa place ne changent pas arbitrairement.

**Continuité.** Je retrouve mon travail, y compris lorsqu’une génération échoue ou qu’un collègue modifie le document. Le retour dans Kollio ne me demande pas de recommencer l’apprentissage depuis zéro.

Ces dimensions ne constituent pas un score d’intelligence de l’utilisateur. Le logiciel observe seulement quelques actions utiles pour ne pas répéter une aide manifestement inutile. Il ne déduit pas qu’une personne est débutante, anxieuse ou compétente à partir de sa vitesse de lecture.

## Le minimum d’interface n’est pas le minimum de signaux

Notre recommandation est de supprimer le chrome permanent sans supprimer les points d’appui. L’écran vide contient une entrée identifiable. Une sélection révèle des actions nommées. Une branche repliée possède une voie de retour. Un problème actif reste visible jusqu’à résolution. Les menus macOS gardent les commandes de documents et les réglages nécessaires.

Nous ne mesurons donc pas le design au nombre de pixels blancs. Nous cherchons le plus petit ensemble de signaux qui permette d’agir sans deviner. Un petit bouton visible peut économiser un long conseil. Un titre précis peut rendre une icône secondaire superflue. Inversement, un conseil ajouté pour compenser une commande introuvable doit faire suspecter la commande, pas déclencher une nouvelle couche de tutoriels.

## Ce que nous ne voulons pas optimiser

Ne pas viser mécaniquement le taux d’acceptation des propositions. Refuser une mauvaise piste avec compréhension est une réussite. Ne pas mesurer l’apprentissage par le nombre de bulles fermées. Ne pas pousser des invitations pour compléter une checklist si le travail est individuel. Ne pas gonfler la durée d’usage, les séries quotidiennes ou le nombre de générations.

La valeur professionnelle peut être d’arriver plus vite à une décision et de fermer l’application. Aucun confetti n’est nécessaire pour accepter un bloc de texte. Une invitation bien placée à essayer une action peut être utile ; un mécanisme qui culpabilise la personne parce qu’elle ignore cette invitation ne l’est pas.

## Arbitrages retenus pour le premier essai

L’arrivée individuelle reste un champ libre et une action. Un exemple synthétique est accessible mais secondaire. Aucun compte ou choix de fournisseur n’interrompt la saisie locale. La première proposition enseigne surtout son statut et la possibilité d’agir dessus. Le rappel d’un geste n’apparaît que lorsque la tâche le rend pertinent. Le collègue invité arrive près du travail demandé, pas sur la visite guidée d’un créateur. La personne qui revient retrouve son contexte avant une éventuelle nouveauté produit.

Ces choix sont cohérents avec l’orientation du V2. Leur dosage — un exemple visible ou un lien, un conseil ou aucun — reste à départager par les protocoles du chapitre de recherche. Ils ne justifient pas une nouvelle refonte du moteur.



---

<a id="ch-02"></a>

# 02 — Ce que les meilleures sources soutiennent — et ce qu’elles ne prouvent pas

## Lire les résultats avant de copier le pattern

Un article de recommandations, une expérience contrôlée, un guide d’utilisation et une présentation de développeur ne répondent pas à la même question. Le guide peut prouver qu’une fonction existe ; il ne prouve pas qu’elle augmente la réussite d’une tâche. Une étude sur quatre apps simples ne permet pas de trancher tout l’onboarding d’un espace de raisonnement collectif.

Le registre R01–R33 rassemble les résumés courts, dates et limites. Les conclusions ci-dessous séparent l’enseignement documenté et notre transfert au produit. Elles ne constituent pas une méta-analyse exhaustive.

## A. Le tutoriel d’ouverture ne bénéficie pas automatiquement aux tâches simples

L’étude NN/g de 2020 compare tutoriel en cartes et absence de tutoriel sur quatre apps iPhone auprès de 70 personnes. Elle ne trouve pas de différence significative de réussite ou de temps de tâche ; les personnes ayant lu le tutoriel évaluent les tâches comme plus difficiles. Les utilisateurs connaissaient déjà iOS, les tâches étaient relativement simples et le temps du tutoriel n’entre pas dans la durée de tâche rapportée. [R09](#source-r09)

**Transfert proposé :** ne pas construire une visite générale obligatoire pour enseigner des gestes déjà familiers. **Conclusion interdite :** tous les tutoriels sont inutiles. Pour Kollio, le caractère provisoire d’une proposition et la publication d’un brouillon sont des notions nouvelles : elles peuvent exiger une explication, mais au moment où elles sont visibles.

## B. L’aide contextuelle n’autorise pas les interruptions permanentes

Les recommandations Apple distinguent l’apprentissage intégré à l’usage, l’aide contextuelle et un parcours préalable lorsque nécessaire. TipKit fournit des moyens de conditionner et de limiter les conseils. Il ne choisit pas ce qu’une personne doit apprendre pour son travail. [R01](#source-r01) · [R03](#source-r03) · [R04](#source-r04)

**Transfert proposé :** une politique déterministe décide si un conseil peut apparaître. Les événements de travail ont priorité. **Conclusion interdite :** utiliser TipKit rend automatiquement l’onboarding efficace. Le même framework peut produire un excellent petit rappel ou une avalanche d’interruptions.

## C. Certaines étapes séquentielles sont légitimes

Le cas des objets connectés décrit par NN/g demande des prérequis matériels et des étapes explicites. [R13](#source-r13) Cela ne contredit pas l’entrée directe d’un éditeur : une activation de matériel et une première phrase sont des tâches différentes.

**Transfert proposé :** la connexion à un espace et le consentement à un traitement distant peuvent nécessiter une surface temporaire ordonnée. **Conclusion interdite :** « canvas-first » interdirait tous les dialogues. Ce principe refuse une administration dominante, pas les choix dont la personne doit réellement comprendre la portée.

## D. Donner une explication ne garantit pas une confiance calibrée

L’étude de Buçinca et collègues (2021, N=199) décrit des interventions réduisant la surconfiance dans une tâche d’aide à la décision, avec un coût de satisfaction et des effets variables selon la motivation cognitive. Le résumé primaire est la matière lue ici. [R17](#source-r17)

**Transfert proposé :** garder les sources, changements et moyens de correction inspectables ; introduire une revue proportionnée aux conséquences. **Conclusion interdite :** forcer une justification ou un délai pour chaque action. Une faute de frappe locale et une décision d’équipe ont des risques différents.

## E. Mouvement utile et lecture stable sont compatibles

Heer et Robertson étudient en 2007 des transitions entre graphiques statistiques ; certaines transitions améliorent la perception dans leurs expériences. [R18](#source-r18) Cela ne signifie pas qu’un texte doit toujours se transformer sous les yeux de son lecteur.

**Transfert proposé :** utiliser le mouvement pour conserver l’identité et l’origine d’un changement ; utiliser une comparaison stable pour juger une différence. **Conclusion interdite :** toute animation augmente la compréhension, ou tout résultat statique est préférable. Le test doit porter sur ce que la personne doit identifier.

## F. Des limites de réponse ne sont pas des délais à imposer

Les repères historiques autour de 0,1 s, 1 s et 10 s aident à raisonner sur feedback et attente. [R14](#source-r14) Ils ne sont pas une consigne « afficher un tip après dix secondes » ni « ralentir une réponse trop rapide ».

**Transfert proposé :** accusé de réception immédiat, attente locale honnête, récupération accessible. Mesurer séparément recherche d’une commande, temps de calcul, temps de lecture et temps de réparation. Les confondre empêche de savoir quoi améliorer.

## G. Les règles d’accessibilité peuvent révéler des défauts de tout le parcours

W3C explicite, pour le web, la persistance du contenu temporaire, les alternatives au drag, le focus et les annonces d’état. [R25–R29, R31–R33] Une application native utilise d’autres API, mais les situations d’échec sont pertinentes : commande qui disparaît pendant le trajet, résultat annoncé en volant le focus, action uniquement possible avec un mouvement précis.

**Transfert proposé :** transformer ces situations en recette native. **Conclusion interdite :** un contraste calculé ou un label accessible rend l’ensemble conforme. Le parcours complet, les modalités d’entrée et les réglages système doivent être essayés.



---

<a id="ch-03"></a>

# 03 — Comparer des mécanismes, pas collectionner des captures

## Matrice de transfert ciblée

Ce chapitre ne recommence pas le panorama esthétique de l’atlas V1. Il examine quelques mécanismes documentés qui répondent à l’arrivée, à la découverte et à la reprise. Aucun classement « meilleure app sur 100 » n’est inventé.

| Référence | Mécanisme documenté | Transfert Kollio proposé | Ce que l’on refuse de copier |
|---|---|---|---|
| Apple, Discoverable design | Gestes accompagnés de voies et signaux compréhensibles. [R02](#source-r02) | Explorer reste visible à la sélection ; le double-clic est un accélérateur, pas l’unique entrée. | Ajouter une tab bar simplement parce que l’exemple Apple en utilise une. |
| TipKit | Éligibilité et séquencement de conseils. [R03](#source-r03) · [R04](#source-r04) | Rappels rares fondés sur action utile et contexte actif. | Une séquence de conseils imposée à tous. |
| Miro, Start view | Zone d’arrivée des nouveaux invités. [R20](#source-r20) | L’invitation porte un point de départ compréhensible. | Recentrer continuellement le collègue ou traiter la zone comme une ACL. |
| Freeform, scènes | Zones nommées pour retrouver et présenter. [R21](#source-r21) | Point d’entrée et chemin de lecture facultatif. | Générer une table des matières énorme avant tout usage. |
| tldraw SDK | Navigation et description des formes accessibles. [R23](#source-r23) | Objet compréhensible sans savoir viser son contour exact. | Copier des raccourcis web qui entrent en conflit avec macOS. |
| Obsidian, sandbox | Espace d’essai séparé du travail courant. [R24](#source-r24) | Sarah ouvre une copie isolée, explicitement fictive. | Remplacer une idée personnelle par une démo obligatoire. |

## Pourquoi un bon pattern peut être mauvais au mauvais endroit

Une zone de départ préconfigurée aide un invité dans un grand graphe. Elle devient nuisible si chaque ouverture ignore l’endroit où la personne avait laissé son travail. Un exemple prérempli réduit l’angoisse de la page blanche. Il devient trompeur si son contenu est présenté comme une analyse de la phrase réellement saisie. Un conseil rend un geste visible. Il devient un obstacle si sa bulle couvre la cible ou oblige à arrêter de taper.

Le transfert doit donc documenter **la condition**, pas uniquement la forme. Dans nos fiches, « pour un nouveau collaborateur sans vue restaurée » est une condition. « Toujours zoomer sur le contexte » ne l’est pas. « Après une action réussie, si la personne n’a jamais utilisé le raccourci » est une condition. « Au bout de trois secondes, afficher comment utiliser le clavier » est un délai arbitraire.

## Une bibliothèque de captures ne montre pas les états absents

Un écran présenté par un éditeur montre rarement l’annulation au mauvais moment, le mauvais compte dans une invitation, la disparition d’une source ou le retour d’une réponse devenue périmée. Ces états font pourtant partie de l’expérience. Le travail de recherche doit les reconstruire comme hypothèses de recette, sans prétendre qu’ils ont été observés chez le concurrent.

La même prudence s’applique au mouvement : une animation vue sur une vidéo ne donne pas directement sa durée réelle, le ressort sous-jacent ou la politique d’interruption. Ici, les paramètres de Kollio sont originaux et testables. Nous ne prétendons pas avoir trouvé « la courbe de Miro ».

## Ce que l’agent peut utiliser immédiatement

Il peut reprendre les exigences de découvertes déjà présentes dans le V2 : actions locales nommées, voies clavier, conservation du texte, retour aux branches et indication honnête de traitement. Il peut ajouter des contrôles de recette pour les bords du viewport, le trajet du pointeur ou la reprise d’une invitation. Il ne doit pas installer les SDK des concurrents pour rendre ces patterns disponibles dans SwiftUI.

Les changements de conventions — double-clic, nombre d’exemples visibles, publication implicite — restent séparés. La première expérience recommandée porte sur un exemple repliable et un conseil au premier résultat, parce qu’ils ont un périmètre limité. Si l’observation montre une bonne compréhension sans conseil, conserver la variante sans conseil est une vraie issue de recherche, pas un échec du projet d’onboarding.



---

<a id="ch-04"></a>
