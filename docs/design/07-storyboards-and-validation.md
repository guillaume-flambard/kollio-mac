# 22 — Huit storyboards de comportement, du geste à la compréhension

Les chronologies ci-dessous sont des **scénarios de conception proposés**. Les temps relatifs de rendu commencent à un événement connu, pas au début d’un calcul dont la durée serait inventée. Aucun de ces storyboards n’est une capture de l’application existante. Ils définissent ce qu’un enregistrement de recette devra permettre d’observer.

## SB-01 — Une première pensée, sans démo imposée

**Question à résoudre :** la personne comprend-elle que son texte devient un document durable avant toute réponse du modèle ?

Le participant saisit le contexte synthétique de J01. L’état avant validation contient l’invitation, le champ multiligne et Explorer. Aucun autre document n’est affiché. À la validation, les mots sont conservés, une commande crée le contexte et le rendu possède une cible stable.

| Moment relatif | Visible | Traitement réel | Ce qui ne doit pas arriver |
|---|---|---|---|
| Action | Feedback du bouton | Une seule demande de création | Deux documents au double-clic |
| Contexte créé | Texte posé sur le canvas | Identité et sauvegarde locales | Perte des mots en cas de panne IA |
| Génération active | Indication sur l’ancre | Entrée bornée au service choisi | Caméra verrouillée ou login imposé |
| Candidat validé | Quelques relations et éléments | Aperçu non canonique | Apparition du scénario Sarah hors sujet |
| Lecture | Retenir/Écarter, Basé sur… | Rien accepté | Pourcentage de confiance inventé |
| Acceptation | Branche stabilisée au même endroit | Transaction et sauvegarde | Nouvelle géométrie inattendue |

Une animation de 220 ms peut accompagner l’installation du contexte. La phase de génération n’a pas une durée dessinée. À disponibilité, la branche apparaît en environ 280 ms de départ. L’utilisateur peut l’examiner dès qu’elle est valide ; aucun bouton n’attend la fin d’une cascade décorative.

La personne doit ensuite pouvoir rouvrir le texte intégral. Le test ne se termine pas sur une capture de la branche : il vérifie également la persistance et la compréhension du statut de proposition.

## SB-02 — Sarah : une alternative évite une dépendance sans la résoudre

**Question :** comprend-on la différence entre contourner une contrainte et la rendre satisfaite ?

```text
                Récupérer la liste des prospects
                        sans dépendre du CRM
                         /               \
              Connexion directe       Export CSV
                     |                    |
          Identifiants indisponibles  Export disponible
                                          |
                               Peut-on récupérer les tags ?
```

Le participant ajoute l’information d’un export manuel pour cette initiative. Cette phrase devient un apport local, pas un message volatil. Une proposition peut ensuite expliquer que la voie CSV évite le besoin d’identifiants pour ce parcours. La branche CRM reste bloquée par la même contrainte ; les identifiants ne sont pas magiquement apparus.

La revue met en évidence les relations concernées et une courte raison. Écarter la voie CRM replie ses détails exclusifs tout en conservant son nom et son motif. Aucun fit global ne change le viewport. Un objet technique partagé reste visible s’il est utilisé ailleurs.

Pour rouvrir, le participant clique Rouvrir. Les anciennes positions reviennent sans appel IA. Le mouvement ne doit pas donner l’impression d’une nouvelle génération. L’histoire reste inspectable.

**Échec de design à détecter :** le participant dit « l’IA a résolu le problème de CRM » alors que seule une autre approche est devenue pertinente. Dans ce cas, la forme du graphe, le label ou la couleur ont induit une fausse conclusion.

## SB-03 — Un fichier change une preuve, pas tout le projet

**Question :** la personne comprend-elle la portée d’un constat déterministe ?

Un CSV synthétique avec `name,email,tags` est déposé sur l’export. La source apparaît avec le nom du fichier et l’état importé. L’aperçu montre les colonnes. La phrase « Colonne tags présente dans cette version » se rattache à la question correspondante.

Le résultat de parsing ne donne pas une validité commerciale aux tags. Une décision de résolution garde sa source et la limite. Lorsque le fichier est remplacé par une version sans la colonne, la preuve ancienne reste liée à l’ancienne version ; la décision passe à revoir selon le contrat.

La chronologie visuelle suit : nouvelle version → signal local sur la source → indication d’impact → revue stable → décision explicite. Les branches sans dépendance ne sont pas recolorées. La scène doit rester compréhensible avec les animations désactivées.

Un test demande de localiser la source de la décision puis de revenir au canvas. Le parcours échoue si la personne doit lire des identifiants techniques ou si le lecteur de fichier efface sa position de travail.

## SB-04 — Corriger une proposition pendant qu’une réponse arrive

**Question :** le produit garde-t-il la main de l’utilisateur au-dessus de l’automatisation ?

Une exploration est lancée sur un contexte. Pendant l’attente, la personne modifie une contrainte pertinente. Le candidat revient avec ses préconditions d’origine. L’UI ne le transforme pas immédiatement en objets acceptables sans revalidation.

Si le candidat est obsolète, sa surface garde les éléments utiles mais désactive Retenir avec un motif. Revoir indique les références changées. Actualiser crée une demande explicite, sans écraser le texte de l’utilisateur. Fermer conserve ce qui doit l’être selon V2.

Répéter avec un simple déplacement de caméra : cette opération ne modifie pas le sens. Le même candidat peut rester recevable. Le test doit distinguer les deux, sinon le produit frustrera l’utilisateur à chaque navigation.

La motion est volontairement minimale : passage de statut, pas effacement spectaculaire. La personne lit un fait de version. Le backend ou l’adaptateur fournit la donnée de fraîcheur ; le renderer ne l’invente pas selon un délai arbitraire.

## SB-05 — Nora publie, Alex examine une version précise

**Question :** qui a le droit de changer le document commun, et quelle version est acceptée ?

Nora est contributrice. Elle travaille dans un aperçu privé. Alex ne voit ni les frappes ni les mouvements de ce brouillon. Nora choisit Publier la proposition ; la version 1 devient visible, attribuée et encore en attente.

Alex ouvre la revue. Nora publie une correction version 2. L’ancienne vue d’Alex doit montrer qu’une nouvelle version existe. S’il essaie de retenir la version 1, le système refuse l’acceptation périmée et ne lui substitue pas silencieusement la version 2.

Après lecture de la version 2, Alex accepte. La transition graphique stabilise les mêmes objets que ceux examinés. Une seule transaction commune est créée. Les deux clients reçoivent les mêmes identifiants. Une animation de présence n’est jamais une preuve que le commit est durable.

La microcopie « Publiée par Nora » doit se distinguer de « Générée sur son Mac » : la première indique une action attribuée à un compte, la seconde une provenance technique déclarée. Aucun badge ne prétend certifier que l’IA dit vrai.

## SB-06 — Une édition concurrente, deux phrases conservées

**Question :** la personne peut-elle comprendre et résoudre un conflit sans perdre ses mots ?

Alex et Nora éditent le même titre à partir d’un état commun. Alex confirme en premier. La demande de Nora est refusée pour conflit, mais son brouillon est conservé. Une revue ciblée montre version commune et sa variante, avec les actions prévues par V2.

Nora choisit de conserver la phrase d’Alex et de créer une variante séparée avec sa propre formulation. Les deux apports restent attribués. Le document ne ressemble pas à un historique Git ; la comparaison est au niveau de l’objet et de son sens.

Aucun fondu en boucle ne remplace l’avant/après. Les textes sont stables. Le focus annonce les titres des deux versions. Échap ne choisit pas une résolution. Les autres opérations indépendantes peuvent continuer si leur contrat le permet.

Répéter avec deux objets différents permet de vérifier que le produit ne présente pas un conflit global pour toute action distante. Le but est une récupération compréhensible, pas la multiplication des écrans d’approbation.

## SB-07 — Deux produits, une même contribution

**Question :** la réutilisation garde-t-elle une identité compréhensible pour le non-développeur ?

Le premier outil utilise Lire le CSV, Vérifier les colonnes et Préparer l’export. Un deuxième besoin réutilise deux de ces capacités avec une autre méthode. Les deux assemblages montrent la même version de contribution, pas deux copies indépendantes présentées comme similaires.

Ouvrir la provenance donne « Utilisée dans 2 produits » et les liens autorisés. Une mise à jour disponible n’altère pas automatiquement les deux outils. Un aperçu indique l’ancienne et la nouvelle version, les changements de contrat et les tests concernés.

Pour l’essai, les données fictives produisent réellement une sortie. Le mode n’affiche pas une estimation de revenus ni une fausse réussite à côté d’un script non exécuté. L’utilisateur peut choisir de garder la version actuelle.

Le succès est la compréhension du lien : demander au participant « Si tu déplaces cette carte, que devient l’autre produit ? Si tu adoptes la nouvelle version ici, que devient l’autre assemblage ? ». Le modèle de données doit être visible dans les conséquences, pas expliqué uniquement par un développeur.

## SB-08 — L’attente et les besoins d’accessibilité ne cassent pas le parcours

**Question :** les mêmes décisions restent-elles accessibles sans effets ni gestes précis ?

Activer Réduire les animations et travailler au clavier. Le participant crée un contexte, atteint une question, ajoute une précision, ouvre la provenance puis rejette une direction. Les changements sont annoncés et les transitions géométriques décoratives absentes. La suppression d’un effet ne supprime pas un état.

Pendant une génération, l’utilisateur ouvre une source. À son retour, la proposition est disponible sans avoir pris le focus de sa lecture. Une panne du modèle conserve les données ; l’application ne choisit pas un cloud à sa place.

Le protocole répète ensuite les opérations avec une taille de lecture accrue et un pointeur simple sans drag. Relier deux éléments doit disposer d’une alternative utilisable. Une erreur persistante ne disparaît pas avant d’être lue.

Le succès est un parcours comparable en sens, pas un ordre de clics rigoureusement identique. Les adaptations de lecture et de contrôle sont une propriété du produit, pas une version dégradée réservée à des utilisateurs secondaires.


---

<a id="ch-23"></a>

# 24 — Plan de recherche utilisateur et de validation

## Ce que la recherche documentaire ne permet pas de trancher

Elle ne dit pas si Julie découvrira Explorer sans aide, si le double-clic sera utilisé pour écrire ou générer, si trois branches suffisent, ni si 280 ms convient sur le Mac cible. Les sources fournissent des hypothèses, des contraintes et des exemples. Il faut maintenant des observations de Kollio.

Le plan ci-dessous est proposé, non exécuté. Aucun résultat, taux de succès ou gain de productivité n’a été inventé. Les données de test sont synthétiques ou explicitement autorisées. Les enregistrements nécessitent le consentement des participants et doivent exclure leurs fenêtres privées.

## Trois niveaux d’étude

**Évaluation de mécanisme.** Un petit prototype interactif ou la fonction native isolée sert à comparer deux gestes, une position de barre ou deux transitions. Il ne valide pas l’application entière.

**Parcours intégré.** La personne crée son contexte, explore, corrige, décide, sauvegarde et revient. Cette étude révèle les incohérences entre composants, même lorsque chacun semble bon isolément.

**Usage d’équipe.** Deux sessions et deux rôles réalisent publication, revue, conflit et reprise. Les participants ne connaissent pas automatiquement l’état de l’autre. Un rôle joué par le modérateur ne remplace pas toujours cette asymétrie réelle.

## Participants et limites de l’échantillon

Proposition de travail : deux vagues formatives de six à huit personnes, avec plusieurs profils non développeurs et quelques utilisateurs de canvas expérimentés. Inclure des besoins d’accessibilité pertinents et des personnes travaillant au clavier. Ce n’est pas une règle « huit utilisateurs suffisent » et cela ne donnera pas une estimation représentative du marché.

Pour l’équipe, prévoir plusieurs paires distinctes. Une paire qui a conçu le produit ne suffit pas. Les personnes doivent comprendre un contexte de test sans recevoir un cours sur l’ontologie de Kollio.

Documenter l’expérience préalable, le matériel, la langue et les réglages utilisés. Ces facteurs aident à interpréter une difficulté ; ils ne servent pas à excuser automatiquement un défaut en disant que la personne « n’est pas la bonne cible ».

## Protocole d’une séance individuelle

Commencer par une intention, pas une procédure : « Prépare une manière de résoudre ce problème et garde les raisons de ton choix ». Observer la première action. Ne pas dire où cliquer, sauf lorsque la personne est bloquée et que cette aide est enregistrée.

La première partie est effectuée sans verbalisation imposée si l’on veut mesurer des temps comparables. Une seconde passe peut explorer le raisonnement de la personne. Mélanger pensée à voix haute et chronométrage comme si les temps étaient naturels fausserait l’interprétation.

À la fin d’une étape, demander ce qui est accepté, proposé ou seulement affiché. Le vocabulaire utilisé spontanément révèle le modèle mental. Demander « Est-ce clair ? » donne moins d’informations que « Que se passerait-il si tu fermais cet aperçu ? ».

## Dix expériences prioritaires

| ID | Question | Variantes proposées | Mesure décisive |
|---|---|---|---|
| UX-01 | Commencer sans formation | Input actuel vs input avec une aide courte | Début autonome, erreurs d’envoi, texte conservé |
| UX-02 | Double-clic | V2 Explore vs variante Éditer | Générations accidentelles et temps de correction |
| UX-03 | Trouver une action | Trois labels locaux vs labels partiellement iconiques | Mauvaises routes et compréhension |
| UX-04 | Lire une proposition | Fantôme lisible vs transparence plus forte | Identification du statut et lecture exacte |
| UX-05 | Comparer une modification | Fondu seul vs avant/après stable | Détection des mots qui changent le sens |
| UX-06 | Comprendre le mouvement | Instantané vs transition courte | Conservation d’identité et temps de reprise |
| UX-07 | Se repérer dans un grand document | Vue libre seule vs repères/retour | Retour à la question et faux rejets |
| UX-08 | Rejeter sans perdre | Écarter/fermer distincts vs présentation actuelle | Réouverture et compréhension de la mémoire |
| UX-09 | Travailler avec un collègue | Deux rôles et candidat révisé | Version acceptée, brouillon préservé |
| UX-10 | Continuer sans modèle/réseau | Indisponibilité et conflit | Récupération et aucune fausse synchronisation |

Pour les variantes expérimentales, conserver la même tâche et un contenu de difficulté comparable. Contrebalancer l’ordre. Ne pas montrer toujours la version souhaitée en dernier. Lorsque l’apprentissage rend la comparaison trop biaisée, utiliser des tâches parallèles ou des groupes différents.

## Mesures utiles

**Réussite sans aide.** La personne atteint le résultat correct sans indication du modérateur. Les aides sont comptées séparément.

**Erreurs de sens.** Croire qu’une hypothèse est vérifiée, confondre écarter et supprimer, accepter une version non lue, prendre une simulation pour un service réel. Ces erreurs pèsent davantage qu’un clic de trop.

**Temps par segment.** Première prise, correction, revue, reprise. Séparer latence technique, lecture et recherche de commandes. Un long temps total ne signifie pas toujours mauvaise performance du modèle.

**Coût de récupération.** Actions et temps pour retrouver un brouillon, une caméra, une source ou résoudre un conflit. Le parcours nominal seul ne révèle pas cette qualité.

**Préférence esthétique.** Demander quelle version semble plus agréable, puis la comparer aux mesures de compréhension. Ne pas transformer cette préférence en preuve de productivité.

## Seuils de travail, pas scores marketing

Pour une validation formative, viser par exemple que presque tous les participants réussissent les gestes critiques et qu’aucune perte de texte ou confusion de permission ne reste sans correction. Les résultats exacts doivent être rapportés avec le dénominateur : « 6 sur 8 » plutôt qu’un pourcentage isolé donnant une illusion de précision.

Une erreur de sécurité ou de données bloque la diffusion même si la majorité aime le design. À l’inverse, un petit écart de préférence entre deux durées ne justifie pas une réécriture du renderer. Prioriser gravité, fréquence observée et récupérabilité.

Pour une étude comparative prétendant établir un gain quantitatif, définir population, taille d’échantillon, variance et méthode d’analyse avant collecte. Le protocole formatif de ce livre n’est pas cette étude statistique.

## Mesurer les animations sur l’application réelle

Enregistrer la même interaction avec les mêmes données, sans ralentir le système par une capture excessivement lourde. Déclarer machine, écran, fréquence et outil. Mesurer les frames, les arrêts visibles et le temps avant feedback lorsqu’un outil fiable le permet.

Comparer à froid et à chaud si l’inférence locale ou le chargement de ressources affectent le comportement. Ne pas attribuer au ressort un retard qui vient d’une sauvegarde synchrone ou d’un recalcul complet de relations.

Le banc HTML fourni est un support de discussion sur les états, non un benchmark SwiftUI. Sa réussite ne compte pas comme test de performance natif.

## Format du rapport

Pour chaque observation : tâche, état initial, action, résultat attendu, résultat observé, preuve, gravité, hypothèse de cause et prochaine vérification. Séparer « bouton absent » d’« utilisateur ne le remarque pas ». Séparer « code semble ne pas traiter le scroll » de « scroll réellement reproduit sans effet ».

Les fichiers de recette commencent à `notRun`. L’agent ne peut les passer à `passed` parce qu’il a écrit une fonction. Les critères humains gardent leur statut tant que la séance n’a pas eu lieu.

## Itération sans nouveau mega prompt

Après une vague, changer une famille de problèmes à la fois : priorité d’édition, lisibilité des propositions ou retour de navigation. Garder une capture et un résultat avant/après. Rejouer les parcours non modifiés pour détecter les régressions.

L’objectif n’est pas une recherche interminable. C’est d’éliminer rapidement les hypothèses qui cassent le sens, puis d’affiner les détails sur une base fonctionnelle. Une nouvelle palette ne doit pas servir à éviter de réparer un input perdu.

## Deux protocoles de validation technique complémentaires

**UX-11** mesure les gestes natifs et la performance sur le matériel déclaré, avec 6 puis 100 objets/200 relations, et sépare les conditions avec et sans inférence. **UX-12** contrôle lecture et action avec clavier, texte agrandi, mouvement réduit et technologies d’assistance réellement disponibles. Ils sont détaillés avec UX-01 à UX-10 dans `validation/research-protocols.md`. Aucun de ces protocoles n’a été exécuté dans la présente recherche.


---

<a id="ch-25"></a>
