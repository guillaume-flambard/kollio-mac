# 10 — Microanimations : cinq fonctions, trois horloges et des contrats

## Ne pas confondre animation et délai métier

Kollio a au moins trois horloges. L’horloge de l’entrée mesure quand une pression est reconnue. L’horloge du travail suit génération, sauvegarde et synchronisation. L’horloge du rendu accompagne l’état déjà décidé ou sa prévisualisation. Les mélanger produit des erreurs : attendre la fin d’un ressort pour écrire sur disque, afficher « accepté » avant le commit partagé ou rejouer un résultat après annulation.

Les transitions ne portent pas l’autorité. Un fichier enregistré reste enregistré même si l’animation est interrompue. Une proposition encore en attente ne devient pas canonique parce que sa couleur a changé. Chaque contrat `MIC` précise donc l’événement de commit séparément de ses propriétés animées.

## Les cinq fonctions retenues

**Retour d’entrée.** Montrer ce qui est pointé ou pressé. Il doit être rapide, local et sans déplacement de la cible. Un bouton ne se dérobe pas pour paraître vivant.

**Orientation.** Montrer d’où arrive un contenu et où l’on reviendra. Elle se justifie pour l’ouverture locale ou une navigation demandée, pas pour déplacer la caméra à chaque réponse.

**Transformation.** Préserver l’identité entre aperçu et élément accepté, détail et repli. La transformation peut être visuelle alors que les coordonnées restent identiques.

**Explication d’impact.** Faire remarquer les objets affectés. Elle doit se terminer sur une présentation stable et lisible. Aucun fait ne doit être compréhensible uniquement pendant 200 millisecondes.

**Attente.** Montrer qu’une tâche existe, son état réel et comment l’interrompre. Une mesure disponible permet une progression ; une génération dont la durée est inconnue ne mérite pas une barre fictive. [R08](#source-r08)

## Valeurs de départ, pas bibliothèque de recettes magiques

| Famille | Valeur initiale proposée | Application |
|---|---:|---|
| Retour léger | 80–120 ms | Fond ou contour, jamais une attente avant action. |
| Apparition de commande | 120–160 ms | Opacité, micro-translation facultative. |
| Développement local | 180–240 ms | Enveloppe et contenu sans déformation des glyphes. |
| Nouvelle branche | 220–300 ms | Relation puis nouveaux objets ; anciens immobiles. |
| Navigation demandée | 200–300 ms | Caméra annulable au premier geste local. |
| Réduction des animations | Immédiat ou fondu court | Aucun déplacement décoratif requis. |

Ces intervalles couvrent les tokens V2, sans inventer des durées propres à Apple. Les travaux de plateforme sur la continuité et les ressorts expliquent pourquoi une transition doit être réorientable ; ils ne décident pas du rebond d’un objet métier particulier. [R05–R07]

## Le cas subtil de l’acceptation

Le groupe fantôme doit occuper la future géométrie réelle. Au clic Retenir, le moteur vérifie ses préconditions. En solo, une transaction validée peut rendre immédiatement le groupe actif. En équipe, le client distingue l’intention locale du commit confirmé. Dans les deux cas, changer la ligne discontinue en ligne pleine ne doit pas faire remesurer le bloc avec une autre police ou une marge qui déplacerait tous ses enfants.

Si le commit échoue, garder le candidat et sa place pour correction. Ne pas faire un « rollback animé » qui prétend que le document avait réellement été modifié si seule une demande avait été envoyée. Les états visibles doivent être nommés correctement.

## La première branche et les suivantes

La première exploration peut recevoir une révélation légèrement plus explicative. Les suivantes doivent devenir rapides et discrètes, sans imposer la même cérémonie. Les objets sont interactifs à leur position finale quand disponibles ; ils ne doivent pas être inclicables en attendant le dernier item d’une cascade.

Si six nouveaux éléments ne tiennent pas dans le viewport, ils sont placés localement et un accès « Voir la proposition » reste possible. Le renderer ne réduit pas tout le document jusqu’à rendre le contexte illisible. La densité et l’organisation restent un travail distinct de la génération.

## Tester ce qui casse pendant l’animation

Cliquer deux fois, changer de fenêtre, presser Échap, zoomer pendant l’arrivée, éditer le parent, recevoir une mise à jour distante : ces cas doivent être décrits. Le simple enregistrement d’une belle transition en conditions idéales n’est pas un test d’interactivité. Les contrats en annexe donnent une base pour ces essais, y compris la variante sans mouvement et le focus final.



---

<a id="ch-11"></a>

# 11 — UX de l’IA : faire comprendre sans construire une confiance artificielle

## Le résultat est une hypothèse de travail, pas une autorité graphique

Une branche propre, alignée et animée peut paraître plus définitive que le raisonnement qui l’a produite. Le design doit rendre visible la différence entre contenu proposé et contenu retenu. L’effet de qualité graphique ne doit pas masquer que la référence manque ou que le modèle n’a reçu qu’un fragment du projet.

HAX organise les questions d’interaction IA dans plusieurs moments de l’expérience. [R15](#source-r15) · [R16](#source-r16) Notre application proposée est de traiter l’arrivée, l’usage, l’erreur et la reprise comme des parties du même produit, plutôt que d’ajouter à la fin une mention générale « l’IA peut se tromper ».

## Avant l’appel

Le bouton décrit la portée : explorer cette idée, comparer cette sélection, résumer ce groupe. Le document ne devient pas implicitement un prompt global. Le contexte envoyé est accessible par un résumé « Basé sur… » et le traitement effectif est nommé. Le stockage partagé et le lieu d’inférence sont deux dimensions : « Sur ce Mac » ne signifie pas que le document d’équipe n’est jamais synchronisé.

Un changement vers une destination distante demande les permissions appropriées avant la première transmission. L’indisponibilité locale ne déclenche pas une bascule cloud silencieuse. L’explication n’a pas besoin de devenir une page de paramètres techniques ; elle doit indiquer le lieu, le contenu concerné et le choix disponible.

## Pendant le calcul

Le canvas reste manipulable. Une saisie dans une autre branche n’est pas bloquée par la génération. Un état `busy` n’est pas une erreur de l’utilisateur. L’indicateur demeure ancré à la demande et ne simule pas une phase « analyse approfondie » si le moteur n’expose aucun événement de ce type.

Ne pas profiter de l’attente pour afficher un nouveau module ou inviter l’utilisateur à partager son document. Cette attente appartient à son travail. Une aide déjà pertinente peut rester consultable sur demande, mais le logiciel n’y insère pas une publicité de fonctionnalités.

## À la réception

Les ajouts apparaissent comme candidats. Les mises à jour d’un texte montrent l’avant et l’après. Les décisions proposées expliquent leur portée et les éléments concernés. Tout cela utilise les mêmes opérations et validations que le V2, pas une seconde représentation impossible à appliquer.

Une clarification n’est pas un formulaire d’onboarding : c’est une question sur le projet. « Je ne sais pas » doit rester une réponse valide quand l’information est inconnue. Le modèle ne transforme pas cette absence en zéro, non ou faux. Si aucun changement utile n’est proposé, `noChange` n’est pas caché derrière trois cartes génériques.

## Au moment de décider

Le chemin principal doit rester une revue simple, pas une approbation automatique. Exposer ce qui change, les sources utiles et la possibilité d’éditer. La profondeur de revue peut augmenter pour un changement partagé ou irréversible. Il n’est pas nécessaire d’imposer la lecture de tout l’historique pour ajouter une note personnelle.

Le livre ne recommande ni pourcentage de « confiance » inventé, ni score d’aura graphique, ni bouton Retenir rendu beaucoup plus séduisant qu’Écarter pour gonfler une métrique. Les actions peuvent avoir une hiérarchie de lecture sans devenir une manipulation du choix.

## Après la décision

L’app conserve une trace compréhensible : proposition corrigée, acceptée, écartée ou masquée. Une nouvelle version de source peut signaler une décision à revoir sans réécrire le passé. Si le contexte change pendant une attente, la réponse est refusée ou revalidée selon la portée réelle. Le message explique ce qui a changé et propose une relance explicite ; il ne réinitialise pas tout le tableau.

Pour la recherche, distinguer échec du modèle et échec de l’interface. Une suggestion mauvaise mais facilement identifiée et refusée n’est pas la même situation qu’une suggestion correcte présentée comme déjà appliquée. Les métriques et comptes rendus doivent conserver cette différence.



---

<a id="ch-12"></a>
