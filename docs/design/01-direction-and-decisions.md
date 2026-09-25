# 01 — La direction : un document calme, des changements explicables

## La décision de conception centrale

Kollio ne doit pas ressembler à une réponse d’IA posée sur un grand écran. Il doit ressembler à un espace de travail dans lequel une idée possède une place et une histoire. La différence doit se voir dès une scène de six éléments : on reconnaît le contexte, les possibilités, ce qui manque, ce qui est proposé et ce qui a été décidé.

La cible proposée est **un document typographique spatialisé**, avec des ressources compactes et quelques résultats plus riches. Le texte est le contenu principal, les relations le rendent compréhensible, les commandes apparaissent au point de travail. Une image ou un aperçu de fichier n’est pas forcé dans le même rectangle qu’une question de sept mots.

Ce choix provient du besoin Kollio, non d’une interdiction Apple des barres d’outils. Les interfaces étudiées conservent souvent des commandes visibles. Le point commun utile n’est pas leur disparition, mais une distinction entre travail et navigation. Le corpus Apple sur les matériaux donne un appui à cette séparation ; le dosage exact reste notre décision. [A03, A04]

## Huit décisions à adopter sans ajouter de modules

**1. Le sens avant la silhouette.** À niveau de zoom courant, une personne doit comprendre « cette condition bloque cette direction » sans connaître le type `Constraint`. Le rôle technique reste accessible, mais le titre et la relation suffisent au premier regard.

**2. Une stabilité spatiale forte.** Une suggestion ne recalcule pas tout le tableau. Le résultat arrive près de sa cible. La conservation des positions n’est pas seulement une propriété de données : la caméra ne doit pas changer à l’acceptation ou au rejet.

**3. Le brouillon n’est pas le document partagé.** Une différence visible indique ce qui attend une décision. La couleur ne suffit pas : utiliser aussi le trait discontinu, le nom de l’auteur, le mot Proposition et des actions adaptées.

**4. La richesse est locale, pas cachée.** L’interface au repos peut être calme tout en montrant qu’un objet s’ouvre, qu’une source existe ou qu’un problème demande attention. Effacer toute indication jusqu’au survol pénalise les personnes qui ne savent pas où chercher.

**5. Une action de base ne dépend pas du modèle.** Déplacer, modifier son texte, ouvrir une source, relier deux objets, rouvrir une décision et annuler doivent répondre même si l’inférence est indisponible. Le design ne devrait jamais confondre « assistant occupé » avec « application inutilisable ».

**6. Le résultat difficile doit pouvoir être lu sans mouvement.** Un ajout simple peut être montré comme une branche. Une modification de contenu existant nécessite un avant/après stable. Une suppression ou une invalidation exige l’énoncé de sa portée. Le même effet d’apparition ne peut pas expliquer les trois.

**7. L’accès aux commandes doit être redondant sans être bruyant.** Souris, clavier et technologies d’assistance disposent de chemins. Une action principale est nommée, un accès secondaire est évident. Cela évite une interface minimaliste qui fonctionne uniquement après un tutoriel de gestes.

**8. La sauvegarde et le partage disent la vérité.** Un document peut être enregistré localement et non synchronisé. Un résultat peut être généré sur le Mac et appartenir à un document partagé. Ce sont des dimensions indépendantes, donc des libellés indépendants.

## Ce qu’il faut cesser d’optimiser

Le nombre de cartes animées n’est pas un indicateur de vie. Le pourcentage de vide n’est pas un indicateur de simplicité. La disparition d’un panneau n’est pas un gain si le même formulaire réapparaît dans une fenêtre flottante plus petite. Une police fine n’est pas plus élégante si elle impose de zoomer à chaque lecture.

La bonne question pour chaque surface est : **qu’est-ce que la personne essaie de reconnaître ou de décider ici ?** Pour le contexte initial, c’est « où écrire et que deviendra mon texte ? ». Pour une proposition, c’est « qu’est-ce qui changerait si je la retenais ? ». Pour un conflit d’équipe, c’est « comment conserver mon apport sans écraser celui d’un autre ? ». Le contrôle visuel doit répondre à cette question, pas afficher le schéma interne.

## Indicateurs de succès proposés

Le premier parcours sera évalué par observation : réussite de la saisie, absence de génération involontaire, compréhension du statut d’une proposition, capacité à retrouver le texte d’origine, succès du rejet puis de la réouverture. La perception esthétique est recueillie séparément. Quelqu’un peut préférer visuellement une variante et néanmoins faire davantage d’erreurs avec elle.

On mesure aussi les moments où une personne cherche une fonction au mauvais endroit. Ce signal est plus utile que de compter les boutons retirés. Une recherche de dix secondes suivie d’un clic correct reste une friction, même si le parcours finit par réussir.

Les objectifs chiffrés des protocoles sont des critères de développement provisoires. Ils ne permettent pas de présenter une expérience testée sur quelques personnes comme une norme universelle pour tous les utilisateurs d’Apple.


---

<a id="ch-02"></a>

# 10 — Matrice de transfert : ce qu’on garde, adapte ou refuse

## Pas de classement global des produits

Les références ne résolvent pas exactement le même problème. Freeform est un tableau libre, FigJam et Miro comportent des usages d’atelier collectif, MindNode structure des cartes et plans, les outils de connaissance relient ressources et lecture. Les comparer avec un score unique de « beau sur 100 » produirait une précision fictive.

La matrice suivante juge l’utilité d’un mécanisme **pour Kollio**, pas la qualité générale de la société qui le propose. Les faits minimaux viennent des chapitres précédents ; les décisions de la colonne finale sont des recommandations de recherche.

| Référence | Mécanisme étudié | Risque d’une copie littérale | Décision Kollio |
|---|---|---|---|
| Freeform | Contenus de formats variés | Refaire toute une boîte de dessin | Retenir l’hétérogénéité, garder les outils nécessaires |
| Freeform Scenes | Vues mémorisées | Confondre vue et scénario métier | Adapter pour présenter et revenir |
| Miro UI | Commandes regroupées | Récupérer le chrome d’un atelier universel | Retenir la hiérarchie, pas les panneaux |
| Miro attention | Suivi et rassemblement | Déplacer la caméra d’un lecteur sans choix | Suivi volontaire pour Kollio |
| Miro catch-up | Reprise des changements | Feed permanent trop détaillé | Résumé à la demande centré sur décisions et sources |
| FigJam Quick create | Ajout à côté d’un objet | Transformer chaque voisin en dépendance | Retenir avec sémantique explicite |
| FigJam accessibility | Parcours de régions/hiérarchies | Accessibilité derrière un réglage introuvable | Proposer une structure accessible d’emblée |
| Excalidraw | Grammaire de dessin simple | Confondre écriture manuscrite et facilité | Conserver peu de formes, typographie nette |
| tldraw | Contrats d’interaction accessibles | Importer tout le SDK web pour un problème natif | Réimplémenter les capacités utiles |
| Allume | Ressources et emplacements liés | Ajouter trop tôt un univers de sous-tableaux | Retenir provenance et retour local |
| MindNode | Focus, repli, plan | Imposer une hiérarchie d’arbre à tout raisonnement | Vue de lecture sans changer les relations |
| Heptabase | Vue d’ensemble et lecture | Inspecteur permanent obligatoire | Lecteur temporaire avec ancre |
| Scrintal | Notes et relations proches | Fiches uniformes trop volumineuses | Adapter les tailles au contenu |
| Obsidian/JSON Canvas | Fichiers et surface portable | Croire que JSON suffit à la décision | Préserver la sémantique Kollio |
| M26 | Référence non identifiée | Étudier arbitrairement un autre produit | Attendre le lien exact |

## Les questions auxquelles aucun concurrent ne répond à notre place

**Comment une hypothèse devient-elle une décision ?** Kollio doit montrer la portée, la raison et l’auteur. La visualisation d’une flèche ne répond pas à cela.

**Qu’a réellement changé une proposition ?** Le résultat peut créer un contenu, modifier un texte, ajouter une relation ou demander un état à revoir. Ces opérations nécessitent des présentations distinctes dans une même grammaire.

**Qui peut accepter ?** Le droit n’est pas déduit du fait que le modèle fonctionne sur la machine. Un contributeur peut explorer puis publier un candidat ; il ne peut pas transformer ce candidat en état commun par un bouton qui ressemblerait à Retenir.

**Que signifie “local” ?** Un modèle sur le Mac, une API sur localhost et un document synchronisé sont trois choses différentes. Le libellé doit nommer la destination effective quand elle compte.

## Arbitrages proposés

La première version visuelle doit porter trois niveaux d’information. Au repos, le sens principal est lisible. À la sélection, on découvre les actions et états utiles. À l’ouverture, on accède au texte complet et à la provenance. L’ordre n’est pas imposé par une loi HCI ; il est notre hypothèse de réduction de charge.

La limite de trois actions principales est conservée comme garde-fou, pas comme métrique. Un résultat peut n’en demander que deux. Une revue complexe peut nécessiter une surface plus large, mais temporaire. Le système ne doit pas ajouter une seconde rangée de huit icônes pour prétendre respecter trois « principales ».

Le vocabulaire doit résoudre les ambiguïtés : Retenir une proposition, Rouvrir une direction, Fermer un aperçu, Retirer du tableau. Un même mot Annuler ne peut pas simultanément fermer le champ, supprimer le brouillon, arrêter l’IA et inverser une décision partagée.

## Les cinq erreurs coûteuses à éviter

Un champ dont la phrase se perd derrière une animation de génération. Une proposition appliquée alors que le document a changé. Un objet accepté qui saute ailleurs. Une source manquante encore affichée comme vérifiée. Une invitation qui ne rend pas clair ce qui est envoyé à l’équipe.

Ces erreurs ont plus de poids que la perfection d’une courbe de Bézier. Le livre les transforme en scénarios d’essai et critères visuels. Le meilleur design pour Kollio sera celui qui préserve compréhension et contrôle sur ces situations, pas celui qui reproduit le plus exactement le dernier matériau système.


---

<a id="ch-11"></a>

# 25 — Décisions, amendements et traduction pour l’agent

## Ce livre n’écrase pas le cahier des charges

V2 reste la référence des fonctionnalités et de leurs règles. Ce travail apporte un langage visuel, une analyse des références, des hypothèses de mouvement et une recette. Les identifiants DOC/CAN/CTX/AI/DEC/TEAM/STU/COM/EXT restent inchangés.

Le registre fourni classe les décisions en **conserver**, **préciser** ou **expérimenter avant modification**. Une observation d’un autre produit n’est pas une autorisation de changer un raccourci, le format documentaire ou les droits d’équipe.

## Les amendements à examiner explicitement

| Décision | Sujet | Statut proposé | Effet sur V2 |
|---|---|---|---|
| DR-01 | Double-clic Explorer ou Éditer | Expérimenter | Ne pas changer CAN-04 / AI-03 sans résultat |
| DR-02 | Commandes secondaires découvrables | Préciser | Respecter U02 et une issue claire vers Plus |
| DR-03 | Minimalisme et dialogue ciblé | Préciser | U07/U08/U10 ne sont pas interdits |
| DR-04 | Texte fantôme opaque | Préciser | Statut par motif/label, pas faible contraste |
| DR-05 | Navigation et momentum système | Préciser | Ne pas ajouter ni retirer aveuglément l’inertie native |
| DR-06 | Taille de lecture macOS indépendante du zoom | Proposition à essayer | DOC-08 / CAN-10, pas promesse Dynamic Type universelle |
| DR-07 | Avant/après stable pour modifications | Préciser | Développer AI-07 au-delà des créations de nœuds |
| DR-08 | Fermer, Écarter, Retirer | Conserver et rendre explicite | Aucun changement métier caché derrière une croix |
| DR-09 | Suivi collectif volontaire | Conserver | TEAM-05/13, sortie au geste local |
| DR-10 | Repères de retour dans le grand canvas | Préciser | CAN-09, pas nouvelle hiérarchie métier |
| DR-11 | Lecture longue temporaire | Conserver et détailler | U05/U11, pas inspecteur permanent |
| DR-12 | M26 | Non résolu | Aucun transfert tant que référence inconnue |

## Travail initial recommandé à OpenCode

Lire les surfaces U00–U05 et les IX associées, puis comparer avec l’application exécutée. Choisir un parcours complet, pas une collection de composants. Le premier lot visuel doit couvrir contexte, sélection, saisie locale, proposition, acceptation et réouverture.

Ne pas changer le backend pour obtenir un bon effet d’apparition. Le renderer utilise les états réels : requête en cours, candidat validé, acceptation confirmée, échec ou conflit. Si une donnée nécessaire manque, ajouter un contrat minimal testable plutôt qu’un booléen de démonstration qui simule le succès.

Les fichiers du pack utilisent des clés techniques anglaises. Les contenus et notices sont en français pour la revue du porteur de produit ; la microcopie inclut FR/EN. Les tokens de design n’ont pas à être recopiés comme un nouveau framework entier : adapter les structures existantes avec une seule source de vérité.

## Une architecture de présentation suffisante

Le modèle métier produit des résultats de commande et des changements. Un coordinateur de présentation détermine les cibles et le type de transition. Les vues consomment des tokens et un état local. La caméra reste indépendante des décisions sauf navigation explicite.

Le rendu d’un candidat doit partager la géométrie d’un objet accepté. Les dimensions sont mesurées de manière cohérente. Le hit-test utilise les mêmes coordonnées. Toute divergence d’anchor point entre preview et contenu final est un bug à corriger avant de choisir une nouvelle courbe d’animation.

Les appels de modèle sont hors du chemin des gestes. Aucun layout ne dépend d’un appel IA pour se stabiliser. Une annulation ou un changement de document invalide les effets tardifs. Les animations ne sont pas sérialisées comme la mémoire du projet.

## Périmètre du lot design

**Appliquer les précisions non conflictuelles** : contraste, focus, labels manquants, texte non étiré, commandes atteignables, camera stable, erreurs locales lisibles. **Préparer des variantes isolées** pour DR-01 et la préférence de taille de lecture si elles ne sont pas déjà prévues. Ne pas imposer une refonte totale pour pouvoir comparer deux gestes.

La performance vient ensuite avec une scène de 100 objets/200 relations et une inférence active séparément mesurée. Les améliorations portent sur le travail effectivement coûteux, pas sur une croyance qu’un moteur bas niveau serait forcément meilleur.

Le travail d’équipe garde les mêmes conventions. Les états privé, publié et confirmé doivent venir du domaine et du serveur ; les avatars de test ne sont pas présentés comme des personnes réelles connectées.

## Livrable vérifiable

Le lot contient les modifications, les tests, des captures de l’application et de courts enregistrements des interactions ciblées lorsque les outils le permettent. Les captures sont datées avec le contexte de test. L’agent distingue inspection de code, test automatisé, manipulation synthétique et validation humaine.

Le fichier de suivi design référence les IDs V2 et IX, leur statut et les preuves. Les critères non exécutés restent visibles. Si un outil de capture manque, l’agent ne remplace pas la preuve par une image fabriquée. Il livre les parties testables et la liste précise des gestes à vérifier.

## Comment éviter le retour des longues sessions sans résultat

Conserver ce livre comme référence consultée par chapitre. Ne pas l’injecter intégralement dans AGENTS.md. Le contexte actif tient dans une tâche : cible, état de départ, IX concernées, critères et commande de vérification.

Un développeur ou un agent peut travailler longtemps sans multiplier les revues inutiles : il avance sur des tranches raccordées, teste, documente ce qui reste et reprend. La longueur de ce livre réduit les ambiguïtés ; elle ne justifie pas une cérémonie à chaque modification de marge.

La réussite finale ne se mesure pas à la fidélité à une capture de Miro. Elle se mesure à ce que l’utilisateur sait faire, comprendre et récupérer dans Kollio.


---

<a id="ch-26"></a>
