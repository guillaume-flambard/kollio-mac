# 03 — Ce que la recherche permet de conclure sur le mouvement

## Deux résultats utiles, mais pas une loi générale

Heer et Robertson ont étudié les transitions animées dans des graphiques statistiques. Le résumé primaire rapporte deux expériences montrant un intérêt pour certaines tâches de perception des transformations. Ce travail date de 2007 ; il ne porte pas sur l’acceptation de propositions d’un LLM. [R03]

Le travail de Robertson et collègues sur la visualisation de tendances présente un contrepoint : selon la tâche, des traces ou petites vues statiques peuvent mieux servir l’analyse, tandis qu’une animation reste attractive et peut s’accompagner de davantage d’erreurs. La page consultée est le résumé primaire d’un travail de 2008. [R04]

La conclusion transférable avec prudence est limitée : **le plaisir et la compréhension ne se mesurent pas par la même variable**. Le corpus ne permet ni de déclarer l’animation toujours supérieure, ni de recommander de supprimer tout mouvement.

## Quatre tâches à ne pas confondre

**Repérer un changement.** Quelque chose vient d’apparaître. Un court mouvement local peut indiquer le point d’origine et l’objet concerné. La personne n’a pas besoin de mémoriser un long état précédent.

**Suivre une identité.** Un objet s’ouvre, se replie ou change de place sur demande. Le mouvement sert à conserver son identité perceptible. La durée doit permettre de reconnaître le lien sans immobiliser l’application.

**Comparer deux contenus.** « Utiliser un export manuel » devient « demander un accès API ». L’utilisateur doit lire l’ancien et le nouveau. Un fondu entre les deux phrases l’oblige à retenir la première. Un avant/après stable est une hypothèse de conception plus adaptée.

**Évaluer une conséquence.** Une modification de source rend trois décisions à revoir. Une cascade colorée peut attirer l’œil, mais elle ne suffit pas à montrer la portée. Il faut des relations, des raisons et un accès persistant aux changements.

Ces quatre catégories orientent l’atlas : le même ressort ne peut pas résoudre toutes les tâches cognitives.

## Les invariants perceptifs proposés pour Kollio

Un objet doit conserver un noyau reconnaissable : son titre ou son extrait, son point d’ancrage, sa provenance et son chemin de retour. L’animation peut révéler du contenu sans remplacer simultanément titre, position, taille, couleur et relations. Plus de propriétés changent ensemble, plus l’attribution de continuité devient un problème à tester.

Une proposition acceptée ne saute pas à une nouvelle position. Si le placement final doit être différent à cause d’une nouvelle collision, le client le montre avant l’acceptation ou demande une organisation explicite. L’utilisateur n’accepte pas un résultat A pour obtenir un résultat B.

La caméra n’est pas un projecteur que l’IA dirige librement. Un changement hors écran peut générer un repère « Voir la proposition ». La personne décide de s’y rendre. Revenir à son emplacement antérieur est une opération de navigation, pas un undo du document.

## Définir la simplicité par la tâche

La divulgation progressive consiste à distinguer fréquent et secondaire, tout en rendant le passage au secondaire évident. NN/g insiste sur ces deux conditions ; le simple fait de cacher des contrôles ne suffit pas. [R05]

Pour Kollio, il faut observer si « Modifier » est moins fréquent qu’« Explorer ». Le V2 le place dans un accès secondaire pour les idées ordinaires. Si les personnes tentent d’abord d’éditer leurs propres phrases, il faudra changer cette priorité. La réponse ne se déduit ni du nombre maximal de boutons ni d’une capture appréciée.

De la même manière, les repères historiques de délai de NN/g fournissent un vocabulaire utile, pas une garantie qu’une génération locale doit s’achever en une seconde. [R06] On distingue réponse de l’interface, attente de l’inférence et acceptation. Le clic peut recevoir un retour immédiat alors que la proposition demande plusieurs secondes.

## Concevoir la confiance sans embellir l’incertitude

Les recommandations Human-AI de Microsoft et le HAX Toolkit organisent l’expérience avant, pendant, lors d’une erreur et dans la durée. [R01, R02] Le transfert proposé pour Kollio est de rendre les capacités, les erreurs et la correction accessibles dans la même surface.

Ne pas utiliser une longue animation de construction pour faire paraître approfondie une proposition médiocre. Ne pas afficher « vérifié » parce que le JSON respecte son schéma. Ne pas présenter une vitesse de génération comme une confiance de raisonnement. Les indicateurs de provenance et les raisons restent factuels.

## Le protocole qui départage les variantes

Pour une transition donnée, faire réaliser la même tâche avec une vue instantanée, une transition courte et un avant/après statique lorsque pertinent. Recueillir : résultat correct, erreurs, temps de lecture, perte de cible et préférence subjective. Contrebalancer l’ordre pour limiter l’apprentissage. Une personne ne doit pas toujours voir la version séduisante en dernier.

On ne conclut pas à partir d’un ressenti du concepteur. Le livre fournit des hypothèses de départ et des mesures. Les témoignages du type « ça semble plus fluide » sont utiles, mais ne remplacent pas la capacité à expliquer ce qui a réellement changé.


---

<a id="ch-04"></a>

# 13 — Les deux premières minutes : de sa phrase à son document

## Hypothèse de parcours

La personne doit obtenir rapidement un contexte durable et une première structure compréhensible. « Deux minutes » est un cadre de test, pas un délai de génération garanti. Le temps du modèle et celui de la lecture sont mesurés séparément.

Le scénario J01 fournit une situation synthétique : organiser une découverte d’atelier avec une salle de trente places, deux intervenants et aucun budget publicitaire. Le test ne nécessite pas un compte, une équipe ou une promesse de stratégie commerciale parfaite.

## État 1 — l’invitation

La composition est légèrement au-dessus du centre vertical du viewport. La largeur maximale du champ suit V2 ; elle se réduit dans une fenêtre étroite. Le titre est accueillant sans être un slogan. Le champ possède une zone de clic évidente, un caret et une aide courte. Il peut grandir jusqu’à six lignes puis faire défiler son contenu.

L’accessibilité annonce le rôle de saisie et la consigne. Le focus ne doit pas se déplacer parce que l’état du modèle se met à jour en arrière-plan. Un texte collé reste dans le champ jusqu’à l’action explicite.

Test : coller trois paragraphes en français, ajouter une ligne, revenir dans la première et déplacer le caret. Aucun de ces gestes ne déclenche Explorer. Le bouton est inactif pour des espaces seuls, mais le texte n’est pas effacé si le stockage manque.

## État 2 — création locale avant intelligence

Cmd+Entrée enregistre le contexte et fait apparaître son objet. Le texte ne se contracte pas jusqu’à devenir illisible. On peut animer l’enveloppe et déplacer légèrement le groupe, mais le contenu garde une continuité.

L’attente de génération est attachée à ce contexte. La personne peut déjà le relire et le modifier. Si la saisie initiale est longue, un extrait lui donne une présence sur le canvas ; l’intégralité reste accessible. Aucune animation ne remplace les mots originaux par une reformulation du modèle.

Le feedback doit correspondre à un état réel : création réussie, sauvegarde en cours ou erreur. On ne montre pas un symbole « enregistré » avant confirmation du mécanisme local. Le contexte n’est pas perdu si l’inférence échoue ensuite.

## État 3 — les premières propositions

La structure initiale contient au plus quelques éléments utiles selon V2. Une question ouverte peut être préférable à trois stratégies arbitraires. La connexion au contexte explique d’où ils viennent. Un label Proposition situe leur statut ; le contenu reste parfaitement lisible.

Les éléments peuvent apparaître brièvement après les relations, mais la personne n’attend pas une chorégraphie séquentielle de dix secondes pour interagir. Une fois le candidat validé, les commandes fonctionnent. Les nouveaux objets ne partent pas d’une taille nulle et n’étirent pas leurs lettres.

L’explication locale reste courte : ce que la proposition apporte et la limite importante. Une commande Basé sur… révèle les éléments réellement utilisés. Ce n’est pas une reconstruction du raisonnement interne du modèle.

## État 4 — sa première correction

Demander au participant de modifier un titre candidat. La correction doit se faire là où le titre est visible, avec une distinction entre candidat et contenu accepté. Le reste du groupe demeure stable. Si la modification viole une règle, le message nomme le problème et laisse le texte modifiable.

Retenir transforme le statut sans changer la géométrie. La personne doit reconnaître exactement la branche qu’elle vient d’examiner. Cmd+Z annule cette transaction, pas la création de son contexte original ni un ancien déplacement sans rapport.

Écarter conserve une trace selon la sémantique V2. Fermer l’aperçu peut seulement le masquer. Les deux ne doivent pas partager une croix ambiguë.

## État 5 — continuer ou revenir

Après une première décision, l’interface montre une prochaine prise possible sans pousser à une exploration infinie. Un point sélectionné expose Explorer ou Ajouter. Il n’y a pas de compteur incitant à générer encore des idées ni de barre de progression vers une « complétude » fictive.

Quitter et rouvrir doit ramener au document et à la caméra, pas à l’onboarding ou à Sarah. Une courte indication peut confirmer la récupération ; elle ne lance pas une nouvelle analyse sans demande.

## Variantes indispensables

**Modèle indisponible.** Le contexte est présent ; explication exacte, manuel et démo explicite restent accessibles. Ne pas transformer cette panne en écran d’achat de crédits.

**Contexte trop long.** Le document conserve le texte. Une demande de cadrage permet de sélectionner la partie à explorer. Le modèle n’ignore pas silencieusement une contrainte pour rentrer dans une limite.

**Deux fenêtres.** La réponse de A ne s’affiche pas dans B. Le focus et le brouillon appartiennent à leur fenêtre. Une animation ne peut pas sauver une mauvaise association de requête.

**Arrêt puis résultat tardif.** L’annulation ferme le cycle actif ; aucun résultat ultérieur ne surgit comme s’il était encore demandé. Le texte initial reste intact.

## Recette

Observer sans expliquer le produit : entrée du texte, première correction, acceptation, annulation et reprise. Demander ensuite de raconter ce que l’application a conservé et ce qu’elle a seulement proposé. La confusion sur cette différence est un défaut prioritaire, même si toutes les étapes sont techniquement cliquables.


---

<a id="ch-14"></a>

# 14 — Gestes, sélection et édition : enlever l’ambiguïté

## L’ordre des événements est du design

Le V2 donne priorité à la saisie, aux contrôles, aux poignées actives, aux objets, aux relations, puis au fond. Cette hiérarchie doit être testée avec les gestes réels. Une carte sous un champ n’a pas le droit de se déplacer parce que la personne sélectionne une phrase.

Une fois le drag commencé, le propriétaire du geste reste stable jusqu’au relâchement ou à l’annulation. Quitter la carte avec le pointeur ne transfère pas subitement le geste au fond. À la perte de focus, les deltas temporaires sont réinitialisés et l’état de commit est explicite.

La fluidité recherchée est d’abord l’absence de surprise. Un déplacement direct sans ressort vaut mieux qu’un suivi légèrement retardé mais animé. Les transcriptions Apple relient justement fluidité et contrôle immédiat ; elles ne demandent pas d’appliquer un ressort à chaque propriété. [A02, A05]

## Double-clic : un amendement à tester, pas à imposer

Le contrat V2 associe le double-clic sur une idée à Explorer et place l’édition via Modifier/F2. C’est une décision produit actuelle. Elle entre potentiellement en tension avec l’attente d’ouvrir ou d’éditer un texte au double-clic.

Deux variantes doivent être testées : **A conserve V2**, avec un double-clic d’exploration et un Modifier très découvrable ; **B réserve le double-clic à l’édition**, tandis qu’Explorer reste un bouton local explicite. La recherche ne décide pas silencieusement B. Le registre DR-01 garde ce changement en proposition jusqu’à validation.

Le critère déterminant est la génération accidentelle : si la personne voulait corriger une phrase et déclenche un modèle, le coût est cognitif et éventuellement matériel. Le second critère est le temps pour une vraie exploration. Il faut des tâches distinctes pour éviter de favoriser une seule variante.

## Le pan n’est pas un déplacement d’objet

Sur le canvas, le scroll à deux doigts déplace la caméra. Le pincement garde son ancre. Dans un champ long, le scroll sert d’abord le texte. Les événements de momentum déjà produits par le système ne doivent pas être doublés par une inertie maison, ni supprimés arbitrairement sous la bannière « pas d’animation ».

Cmd+1 rétablit 100 % en conservant le point central, non la translation d’origine. Cmd+0 cadre le contenu que le contrat définit comme visible. Les branches écartées ne rouvrent pas parce qu’on change d’échelle.

Pour la souris, le mapping doit rester documenté et stable. Une préférence de navigation peut être examinée si les essais montrent des usages incompatibles ; elle ne doit pas devenir un écran obligatoire au démarrage.

## Sélection et actions

Le clic simple sélectionne. Maj+clic ajuste le groupe. Le rectangle de sélection suit V2 avec Maj+glisser dans le vide. Un clic vide désélectionne, il ne crée pas une nouvelle note. Les styles de sélection et focus ne se confondent pas : plusieurs objets peuvent être sélectionnés alors qu’un seul contrôle reçoit le clavier.

La barre contextuelle ne clignote pas pendant le mouvement du pointeur. Elle ne fuit pas sous la souris pour éviter une collision ; son placement se décide à l’apparition et ne change que si le viewport ou la cible rendent l’emplacement inutilisable.

Une cible partiellement hors écran peut conserver un repère. Le contrôle reste dans une zone sûre, avec une association visible à l’objet. Il ne semble pas appartenir à la carte voisine.

## Alternatives sans drag

La règle W3C sur les mouvements de glisser demande, dans son périmètre web, une alternative au pointeur simple sans drag ; une alternative clavier seule ne suffit pas à ce critère précis. [W05] Pour Kollio natif, nous retenons l’intention comme exigence de qualité.

Proposition : une action Déplacer ici après sélection et choix d’un emplacement, ou des commandes d’alignement/organisation nommées. Relier peut se faire par source puis cible, pas uniquement en tirant une poignée. Ces alternatives utilisent les mêmes commandes transactionnelles.

Il ne faut pas surcharger la barre principale : les alternatives peuvent être dans le menu secondaire, accessible au clic, avec un état temporaire clair et une sortie Échap. Leur existence doit être indiquée dans l’aide de raccourcis et accessible aux technologies d’assistance.

## La forme de la relation doit correspondre à sa direction

Un lien « bloque » doit permettre de savoir quel objet bloque lequel. L’orientation, la flèche et le label suivent le modèle. Une ligne est sélectionnable sur une zone écran plus large que son trait. À une intersection, le label et une surbrillance de préselection facilitent la bonne cible.

Les relations essentielles restent lisibles au repos. Tout cacher jusqu’au survol ferait disparaître le sens du diagramme. En revanche, les poignées d’édition et détails de version ne doivent pas encombrer les connexions non sélectionnées.

## Tests à effectuer avant un nouveau style

Déplacer la même carte à 80, 100 et 180 %, éditer son titre, sélectionner plusieurs objets, atteindre la barre près d’un bord, annuler le drag et rouvrir une branche. Tester avec une souris puis un trackpad. Le test de géométrie ne suffit pas à prouver la capture d’événements ; un enregistrement réel doit montrer le pointeur et le résultat.


---

<a id="ch-15"></a>

# 15 — Afficher les propositions IA : trois familles de changements

## Une branche fantôme ne résout pas tous les cas

Le V2 définit une proposition comme un ensemble de changements en attente. L’UI doit donc représenter les changements, pas seulement les nouveaux objets. Une idée ajoutée se prête bien à la ramification. Une phrase modifiée ou une relation retirée exige une autre explication.

Nous proposons trois présentations compatibles : **ajout**, **remplacement ciblé**, **changement de portée**. Elles utilisent les mêmes actions de revue et les mêmes préconditions. Elles n’introduisent ni modal universelle de proposition ni panneau d’administration.

## Famille A — ajout de contenu

Le candidat apparaît près de sa cible avec un lien discontinu et le mot Proposition. Son texte est opaque et lisible. Un petit groupe Retenir/Écarter agit sur la transaction proposée. Basé sur… et Modifier restent accessibles sans devenir un formulaire complet.

Les connexions apparaissent avec les objets nécessaires. Les IDs ne sont jamais visibles comme explication utilisateur. Un nom de contributeur ou une source précise est préférable à « object_123 ». Les limites importantes sont formulées en langage métier.

Si trois objets dépendent d’un quatrième, accepter seulement les trois ne doit pas devenir possible par des cases indépendantes. L’interface explique la dépendance ou ne propose que l’acceptation du groupe cohérent.

## Famille B — modification du contenu existant

L’objet original reste en place. Une petite indication signale qu’un changement est proposé. Le lecteur ouvre un avant/après stable, centré sur les phrases réellement différentes. Le titre ou la première ligne peut montrer un aperçu, mais le texte original n’est pas recouvert avant acceptation.

La comparaison peut rester locale pour quelques lignes. Pour un contenu long, une lecture dédiée temporaire est acceptable, avec le titre de la cible et Retour au canvas. La vue ne doit pas limiter le texte à trois lignes au point de cacher le mot qui change le sens.

Une animation peut relier les états après acceptation. Elle n’est pas le seul moyen de les comparer. Ce choix s’appuie sur la prudence issue des travaux sur transitions et analyse de tendances ; il reste une transposition spécifique à tester dans Kollio. [R03, R04]

## Famille C — contrainte ou décision affectée

Une information contredit une hypothèse de la branche A. Le groupe de revue montre la source, l’hypothèse et les décisions susceptibles d’être revues. La branche B reste active, même si elle utilise une contribution commune. La présentation indique la portée exacte : « cette hypothèse est à revoir », pas « tout ce projet est invalide ».

Les relations concernées peuvent être accentuées une seule fois à l’apparition. Ensuite, le résultat reste lisible sans mouvement. Aucun clignotement permanent ne représente une incertitude.

Éviter le symbole vert de certification pour une simple acceptation. Une décision humaine a un auteur et une raison ; elle n’est pas transformée en vérité universelle. Une preuve importée a une version et des limites. La ligne qui la relie ne prouve pas à elle seule sa justesse.

## Corriger le candidat

L’utilisateur peut changer un texte candidat avant de retenir. Le groupe passe en état modifié et reste une proposition. La validation vérifie que cette correction ne laisse pas une référence cassée. La provenance distingue contenu généré, correction humaine et acte d’acceptation.

Le modèle ne reprend pas automatiquement la main à chaque frappe. Après une correction, une nouvelle génération est explicite. Cela évite une interface où le curseur lutte contre des reformulations en continu.

## Réponse obsolète

Pendant la génération, l’utilisateur modifie le contexte. La réponse arrivante vise l’ancienne version. Le design montre « Des éléments utilisés ont changé » et permet de revoir ou relancer selon le contrat. Il ne la pose pas silencieusement sur un document différent.

Un simple pan n’obsolète pas le raisonnement. Une modification du texte utilisé peut l’obsoléter. Le message doit éviter le vague « erreur inconnue » qui donne l’impression d’une panne réseau. L’utilisateur doit comprendre ce qui a changé et ce qu’il peut conserver.

## Plusieurs propositions

Une exploration ne détruit pas le candidat précédent. Pour rester sobre, on affiche le candidat actif et une trace accessible des autres, avec leur ancre. La comparaison entre deux alternatives est explicite. Le canvas n’est pas rempli par toutes les générations simultanément.

Une proposition peut être masquée sans être rejetée. Une direction écartée garde sa mémoire. Ces états ont des libellés différents. Une croix de fermeture ne doit pas signifier une décision définitive.

## Recette de compréhension

Après une proposition, demander : « Qu’est-ce qui est déjà dans le document ? Qu’est-ce qui changerait si tu cliquais Retenir ? Qu’est-ce qui restera si tu fermes l’aperçu ? » Le participant doit pouvoir répondre sans lire un manuel.

Tester un ajout, un changement de texte, une contrainte à revoir et un candidat périmé. Une belle démonstration limitée à l’ajout de cartes n’évalue pas la promesse de document vivant.


---

<a id="ch-16"></a>

# 16 — Latence, erreurs et contrôle : une application vivante même sans réponse

## Trois horloges distinctes

Il y a le temps de réaction au clic, le temps du calcul et le temps nécessaire à la personne pour comprendre. Une bonne UI répond vite au premier, annonce honnêtement le deuxième et n’accélère pas artificiellement le troisième. Les repères de délai de NN/g sont des heuristiques historiques ; le spinner d’un modèle n’est pas une preuve qu’un seuil universel a été respecté. [R06]

Les indicateurs Apple recommandent un progrès cohérent avec ce qui est réellement connu. Pour Kollio, aucun « 87 % du raisonnement » ne sera inventé. On peut connaître qu’un fichier a été lu à moitié ; on ne connaît pas nécessairement la fraction restante d’une réponse générative. [A10]

## Attente près de la cible

Après Explorer, la cible conserve son titre, sa position et ses actions non contradictoires. Un état court indique la destination : Sur ce Mac, Cloud Apple, Service distant ou Démonstration, selon le mode réellement utilisé. Une action Annuler reste disponible pendant l’attente utile.

L’indication n’occupe pas le centre de toute la fenêtre. La personne peut explorer visuellement une autre partie du document, lire une source ou déplacer un objet. Le logiciel ne montre pas un voile modal bloquant pour un calcul qui concerne une branche.

Si le résultat arrive immédiatement, ne pas le retarder pour laisser admirer l’indicateur. Si l’attente se prolonge, montrer une information concrète lorsqu’elle existe : modèle occupé, requête en cours, limite de contexte. Ne pas simuler plusieurs phases d’analyse pour animer l’écran.

## Conserver le travail lors d’un échec

Le texte de la demande reste récupérable. Le contexte déjà créé reste dans le document. Une erreur est attachée à la requête, pas transformée en carte métier permanente. Réessayer relance une action explicite ; la version du contexte est vérifiée.

Une limitation de modèle n’autorise pas un transfert cloud. Une connexion perdue n’autorise pas un autre fournisseur. L’UI peut proposer un choix, mais doit expliquer ce qui quitterait le Mac avant l’appel. L’utilisateur n’a pas à comprendre Vapor pour savoir où ses informations sont traitées.

## Une erreur peut être silencieuse visuellement, pas conceptuellement

Une notification de sauvegarde réussie peut être discrète. Un échec persistant ne doit pas disparaître en deux secondes. L’état du document reste signalé et l’action de récupération est trouvable. Le statut Enregistré localement reste distinct de Synchronisé avec l’équipe.

Une ressource devenue inaccessible conserve son titre et ses références avec un état précis. Le résultat qui s’appuyait sur elle peut être à revoir. Le logiciel n’efface pas l’élément, ne le marque pas vérifié et ne remplace pas son contenu par une approximation.

## Refus et “aucun changement”

Un résultat noChange n’est pas un crash. Il doit pouvoir dire qu’aucune proposition nouvelle n’est utile dans la portée demandée, sans inventer du contenu pour remplir la scène. Une question de clarification peut apparaître sur son ancre et rester réversible.

Un refus du modèle n’est pas une invitation à lancer automatiquement dix reformulations. Le message explique la possibilité de modifier sa demande ou continuer manuellement. Le traitement ne demande pas à la personne de cliquer sur un mode moins sûr pour obtenir une réponse.

## Annuler et les réponses tardives

Quand l’utilisateur annule, le cycle visuel quitte running et passe dans un état final explicite. Un résultat tardif ne s’ajoute pas au canvas. La personne peut reprendre volontairement la demande, mais la nouvelle requête possède une identité propre.

Une animation de sortie du spinner ne doit pas être le mécanisme qui arrête la tâche. La logique d’annulation et la validation de fraîcheur sont indépendantes du moteur d’animation. Le modèle peut ne pas s’arrêter instantanément ; l’interface ne promet pas l’absence de coût ou d’activité matérielle tant que le service ne le confirme pas.

## Contrat de microcopie

Préférer « L’exploration n’a pas abouti. Votre texte est conservé. » à « Oups, notre IA a eu un petit problème ». Préférer « Le document a changé pendant l’exploration » à « 409 conflict ». Préférer « La colonne tags n’a pas été trouvée dans cette version du fichier » à « Les tags n’existent pas ».

Ces formulations sont proposées dans le catalogue FR/EN. Le code de diagnostic reste dans les logs expurgés, pas dans le texte principal. La raison doit être aussi précise que les preuves disponibles, et pas davantage.

## Tests à provoquer volontairement

Modèle indisponible, contexte trop long, réponse mal formée, annulation, fermeture de la fenêtre, changement de document, disque plein simulé, source manquante, conflit d’équipe. Pour chaque cas, vérifier les mêmes questions : où est mon texte ? qu’est-ce qui a changé ? que puis-je faire maintenant ? à qui les données ont-elles été envoyées ?

Le design n’est robuste que si ces états font partie de la démonstration, pas seulement du code d’erreur inaccessible.


---

<a id="ch-17"></a>

# 18 — Le design du collectif : présence, proposition et décision

## Trois personnes visibles ne prouvent pas une collaboration

Un ensemble d’avatars peut rendre une capture convaincante sans définir ce que les personnes peuvent faire. Kollio V2 fixe les rôles du document : owner, editor, contributor, viewer. Le design doit traduire ces droits dans les actions, sans transformer le canvas en panneau de permissions permanent.

L’accès local à un modèle n’augmente pas les droits sur le document. Une personne peut produire un brouillon privé et ne pas avoir le droit de l’accepter dans l’état commun. Le bouton doit alors être Publier la proposition, pas Retenir. La différence n’est pas cosmétique : elle explique la responsabilité.

## Partager : un moment de portée globale

Depuis le menu document, le propriétaire ouvre une surface temporaire claire. Elle affiche la destination, les personnes ou l’espace, les droits et le périmètre partagé. Les branches écartées et sources sont mentionnées lorsqu’elles sont incluses. Fermer cette surface n’envoie rien.

Un état de préparation peut exister tant que les actifs ne sont pas prêts. L’utilisateur ne doit pas copier un lien présenté comme utilisable alors que le contenu n’est pas encore disponible. En cas d’échec, son document local reste accessible. Il peut reprendre le partage au bon endroit sans tout reconstruire.

Pour une invitation, le destinataire voit le document et son rôle avant d’accepter. Un mauvais compte, une invitation expirée et un accès retiré demandent des messages différents. Le design évite une erreur générique d’authentification qui ferait croire que le fichier est perdu.

## Présence : un état éphémère

Les avatars représentent des personnes réellement connectées. Le pointeur et la sélection distants sont des signaux d’attention facultatifs, pas des modifications durables. Leur animation ne doit pas être rejouée à l’ouverture du document.

Une étiquette de nom apparaît quand elle aide à identifier l’activité. Elle ne doit pas suivre chaque mouvement de manière à couvrir le texte. Lorsqu’un participant se déconnecte, sa présence expire ; ses contributions et décisions restent attribuées. Absence de curseur ne signifie pas absence de droit.

Un suivi de présentation est explicite et identifiable. Le lecteur reprend la main au premier geste local de navigation, sans provoquer le déplacement du présentateur. La recherche sur les références concurrentes motive cette distinction, mais le mode volontaire reste une décision Kollio.

## Du brouillon privé à la proposition publiée

Nora prépare une alternative en tant que contributor. Ses frappes restent privées. L’aperçu indique cet état. Elle peut demander une exploration locale, modifier le candidat et consulter les sources autorisées. La publication est un acte séparé, avec une version.

Alex voit la proposition publiée près de son ancre, avec auteur, résumé et changements. Il peut demander une précision ou une modification. Les commentaires ne deviennent pas automatiquement des faits du document. Une action explicite peut promouvoir une information en contexte avec provenance.

Si Nora révise le candidat, l’interface signale une nouvelle version. Alex ne doit pas accepter silencieusement une version différente de celle qu’il a lue. La revue montre la version actuelle et les différences utiles ; une ancienne approbation ne reste pas valable par simple ressemblance du texte.

## Acceptation et erreur de concurrence

Quand Alex retient une proposition, les contrôles indiquent que l’action est en cours de confirmation commune. Le client peut présenter un état optimiste seulement s’il est clairement distinct de la validation du serveur. Une déconnexion ne transforme pas cet état en décision confirmée.

Si un autre éditeur a déjà accepté ou rejeté la même version, la réponse ne doit pas créer un deuxième résultat. L’UI affiche la décision actuelle et son auteur. Un double-clic ne duplique pas le graphe.

Le mouvement d’acceptation conserve les positions et l’identité de la proposition. Il est court, sans célébration. Une action collective est un changement d’état, pas un événement de jeu.

## Conflit : conserver les deux apports

Pour un même titre modifié en parallèle, montrer version commune et ma variante dans une surface ciblée. Les actions sont Conserver la commune, Soumettre ma variante, Modifier. La dernière option ouvre un texte éditable sans cacher les références.

Le conflit doit nommer son objet. Il ne place pas tout le document dans un écran bloqué. Les modifications indépendantes peuvent continuer si leur contrat le permet. Une opération qui dépend de la résolution reste explicitement en attente.

Pour une longue méthode, une surface de comparaison plus large est acceptable. La simplicité ne signifie pas que l’on doit tronquer les contenus pour rester dans un petit popover. Le retour au canvas est immédiat après la résolution.

## Hors ligne et perte d’accès

L’état Enregistré sur ce Mac / Non synchronisé doit pouvoir rester visible jusqu’à résolution. Il n’a pas besoin de clignoter. Au retour de connexion, l’application ne rejoue pas toute la séance sous forme d’animations. Elle synchronise puis montre les changements pertinents.

Si l’accès a été retiré, les opérations ne sont pas envoyées comme si rien n’avait changé. Le brouillon local et les droits de copie sont traités selon le contrat, avec un message compréhensible. L’UI ne promet pas de récupérer un accès ni d’effacer rétroactivement des exports hors de son contrôle.

## Reprise du travail

« Depuis votre dernière visite » présente quelques événements significatifs : source remplacée, décision à revoir, proposition publiée, mention. Les déplacements graphiques intermédiaires ne saturent pas ce résumé. Choisir un événement revient à sa cible et sa justification ; le marquage lu est personnel.

Le test d’équipe doit utiliser deux sessions distinctes. Un mock qui montre deux avatars ne permet pas de juger l’arrivée d’une nouvelle version pendant la lecture. La recette observe autorité, compréhension et récupération, pas uniquement la synchronisation de coordonnées.


---

<a id="ch-19"></a>

# 19 — Résultats, contributions et adaptation tactile

## Le résultat n’est pas le canvas de fabrication

Kollio peut produire une synthèse, une méthode ou un petit outil. Le destinataire n’a pas toujours besoin de voir tout le graphe. Le V2 prévoit U11 pour une fiche de résultat et U12 pour un lecteur ou une présentation. La conception doit rendre ce passage simple et réversible.

Ouvrir un résultat depuis le canvas conserve un retour à son point d’origine. La fiche montre ce qu’elle permet, ses données nécessaires, sa sortie et ses limites. Le détail technique et la provenance restent accessibles, mais ne dominent pas l’usage courant.

Une méthode réutilisable présente un exemple utile et une limite claire. Une brique technique présente une capacité, pas seulement un nom de package. L’utilisateur métier doit comprendre ce qu’il gagne à la retenir, sans apprendre un format de contrat d’entrée/sortie.

## Composer un petit outil sans devenir un workflow builder

L’assemblage montre quelques contributions et leurs dépendances utiles. Un raccord valide doit avoir une explication lisible. Un raccord à adapter ne se contente pas de devenir orange : il nomme ce qui manque. Une incompatibilité ne doit pas produire une prévisualisation trompeuse de succès.

Dans le scénario synthétique Sarah, ParseCSV, ValidateColumns et ExportNormalizedCSV peuvent être présentés par leur fonction : Lire le fichier, Vérifier les colonnes, Préparer l’export. La méthode indique quelles colonnes sont nécessaires et ce qui doit être contrôlé par une personne.

L’essai utilise des données explicitement fictives. Le résultat d’une validation déterministe est distinct d’une interprétation générative. Un bouton Essayer doit réellement modifier son résultat selon les entrées ; il ne fait pas défiler une capture préparée.

Le graphisme du mode essai peut être plus guidé que celui de l’exploration. Il s’agit d’accomplir une tâche précise, pas d’examiner toutes les alternatives. Le retour au canvas permet de modifier la méthode ou une contribution, sans perdre les conditions de l’essai.

## Attribution et réutilisation

Une petite surface de provenance nomme les auteurs et versions utilisées. Si la même brique sert dans deux outils, le compteur et les liens sont réels. Dupliquer sa carte ne crée ni un autre auteur ni une nouvelle rémunération.

La version d’une contribution est épinglée dans l’assemblage. Une mise à jour disponible est une proposition de changement, pas une modification silencieuse du produit. L’UI explique son effet sur les tests et permet de comparer avant d’adopter.

Un problème de droits est présenté comme une condition non satisfaite, pas comme une erreur de l’utilisateur. La fiche peut rester privée tant que la publication n’est pas autorisée. Le design ne doit pas transformer une préparation de publication en mise en ligne implicite.

## Achat et usage, seulement lorsque le parcours existe

Les fonctionnalités COM du V2 sont conditionnelles. Leur design doit rester distinct de l’atelier : fiche claire, périmètre de l’accès, prix effectivement configuré, limites et recours. Aucun compte à rebours, faux avis, revenu garanti ou incitation à publier prématurément.

Une vente simulée est nommée comme telle. Une confirmation visuelle de paiement ne précède pas la confirmation du service compétent. Le lecteur final ne reçoit pas les sources privées de l’auteur pour pouvoir essayer un outil.

## Ce qui change sur iPad

La cible tactile demande des surfaces plus généreuses et des commandes hors de la zone occultée par la main. Le clavier logiciel réduit la hauteur disponible. La même idée peut être éditée dans une surface temporaire plus large sans changer sa géométrie canonique.

Le premier profil propose : un toucher sélectionne, les actions nommées apparaissent, un geste à deux doigts navigue, une commande accessible permet de déplacer ou relier sans précision de drag. Le Pencil est une capacité facultative, pas un passage obligé ni une excuse pour accepter des marques involontaires.

Ces règles sont des hypothèses pour une future adaptation. Elles ne prétendent pas que tous les gestes de FigJam ou Freeform doivent être copiés, et elles ne déclenchent pas le développement iPad maintenant.

## Ce qui change sur iPhone

Un grand graphe complet n’a pas à devenir une miniature illisible. Le téléphone peut commencer par le contexte, une branche ou un parcours de décision. Le canvas reste disponible, mais une lecture locale prend davantage de place et les actions contextuelles se regroupent dans une zone basse stable.

Le passage de la carte au détail doit préserver le point de retour. Les informations importantes ne doivent pas être accessibles uniquement en pinçant jusqu’à lire du texte minuscule. Une version en lecture structurée est une autre projection du même document, pas un nouveau document résumé qui oublierait les contraintes.

## Ne pas élargir le périmètre sous couvert de recherche

Ce chapitre décrit la direction STUDIO/ECOSYSTEM et les adaptations tactiles afin que le langage visuel soit extensible. Le prochain travail de l’agent reste conditionné aux fonctions réellement disponibles. Aucun nouvel écran de paiement, tablette ou catalogue n’est requis pour corriger les interactions macOS.


---

<a id="ch-20"></a>

# 20 — Système de mouvement : une grammaire exécutable

## Pourquoi une bibliothèque de durées ne suffit pas

Un token `duration: 220` ne dit ni ce qui bouge, ni ce qui se passe si l’utilisateur clique à nouveau. Chaque animation doit définir son déclencheur, ses objets concernés, ses propriétés, ses limites, son interruption et sa variante sans mouvement. Elle doit aussi indiquer quelle mutation métier a déjà eu lieu et laquelle attend encore une décision.

Les recommandations Apple sur le mouvement et la session sur les ressorts fournissent un cadre de continuité. [A01, A05] Les valeurs ci-dessous sont nos points de départ pour Kollio. Aucune n’est présentée comme la durée exacte d’un produit concurrent ou une exigence universelle d’Apple.

## Cinq familles

**Feedback.** Survol, pression, focus, choix d’un outil. La modification est immédiate ; une brève transition de fond ou de contour peut l’accompagner. Pas de délai avant de reconnaître le clic.

**Révélation.** Actions, texte développé, résultat disponible. Le composant apparaît près de son ancre, avec une opacité et éventuellement une translation courte. Le texte ne se déforme pas.

**Transformation.** Aperçu vers contenu accepté, groupe vers branche repliée, contexte initial vers objet. L’identité et les points de retour sont conservés.

**Navigation.** Recentrage, déplacement vers un résultat, présentation. La caméra bouge uniquement à la demande ou dans un suivi explicitement accepté, et s’interrompt au geste local.

**Manipulation directe.** Drag, pan, pinch, sélection. Elle ne reçoit pas une interpolation qui crée du retard entre le geste et le contenu. Le système peut fournir du momentum de navigation ; on ne lui ajoute pas une inertie concurrente.

## Tokens proposés

| Token | Départ | Usage | Ce qu’il ne signifie pas |
|---|---:|---|---|
| `feedback` | 100 ms | Fond, contour, état de bouton | Délai avant prise en compte |
| `reveal` | 140 ms | Actions locales et petits messages | Attente minimum à imposer |
| `dismiss` | 160 ms | Fermer un développement temporaire | Suppression d’un brouillon |
| `expand` | 220 ms | Surface qui révèle son contenu | Délai de sauvegarde |
| `branch` | 280 ms | Quelques nouveaux éléments | Temps autorisé au modèle |
| `camera` | 260 ms | Recentrage demandé | Animation obligatoire de tout changement |
| `stagger` | 40 ms, cumulé ≤120 ms | Légère lisibilité d’un groupe | File d’attente de boutons inutilisables |

Le ressort non rebondissant est un candidat pour certaines transformations d’enveloppe. Les fades peuvent employer une courbe courte. Une manipulation directe n’a pas de durée nominale : elle suit les événements.

## Propriétés et unités

Le contenu se place en coordonnées monde, mais les petits mouvements décoratifs d’apparition sont définis en points écran. Si on décide de les appliquer dans la couche monde, convertir une fois selon le zoom. Ne pas faire une entrée de huit points devenir vingt points lorsque le document est agrandi.

Les contrôles contextuels restent à taille écran. Les traits essentiels ont une largeur lisible ; les repères décoratifs peuvent s’alléger selon le zoom. Les labels d’une relation suivent sa géométrie, mais pas une simulation oscillante.

Le passage candidat/accepté utilise le même rectangle de référence. L’écart autorisé est uniquement celui de l’arrondi du renderer, pas un nouveau placement. Un changement de contenu qui modifie la hauteur est recalculé avant de montrer la revue finale.

## Interruption

Si l’utilisateur reclique pendant une expansion, l’état cible change à partir de l’état visuel courant ; il ne rejoue pas l’animation depuis le début. Si une caméra se recadre, le pan manuel arrête cette navigation. Si une proposition est annulée, sa disparition n’empêche pas de créer une autre demande.

Lorsqu’un document change de fenêtre ou se ferme, les effets locaux sont annulés avec la session. Un résultat tardif ne fait pas revivre une animation sur un autre document. Les objets d’animation ne deviennent pas des références durables dans le fichier.

## Priorités de mouvement

Priorité absolue aux gestes, ensuite au focus et aux changements indispensables, puis aux effets décoratifs. Si plusieurs événements arrivent ensemble, ne pas animer chaque détail. Regrouper les modifications distantes et présenter leur sens ; l’arrivée de cinquante mouvements ne devient pas une chorégraphie obligatoire.

Un nombre limité d’apparitions peut être animé. Les objets hors écran n’ont pas à consommer une animation invisible. Les erreurs et conflits ne secouent pas le canvas pour attirer l’attention. Un message ciblé et persistant est plus approprié.

## Mode réduit

Réduire les animations supprime translations décoratives, rebonds et caméra animée. Les changements restent visibles par l’opacité, le contour, le texte et les états. Le suivi direct du doigt ou du pointeur reste intact. Le critère W3C sur l’animation d’interaction est AAA ; ce livre l’utilise comme repère volontaire, pas comme une certification AA de Kollio. [W07]

## Raccord au frontend

Le moteur métier émet un résultat de transaction. Le coordinateur de présentation calcule les éléments ajoutés, modifiés ou retirés et choisit une transition connue. Le LLM ne décide pas des couleurs, polices, durées ou ressorts. Un même changement a le même langage visuel qu’il vienne d’un humain, d’Apple local ou du backend, tout en gardant une provenance distincte.

Les tests unitaires contrôlent géométrie et invariants. Les tests de vue vérifient focus et présence. Le passage réel contrôle interruption, lisibilité et confort. Aucun screenshot seul ne mesure la qualité temporelle.


---

<a id="ch-21"></a>
