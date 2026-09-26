# 12 — Erreurs et récupération : l’onboarding se juge quand quelque chose échoue

## Le premier incident est un moment d’apprentissage réel

La personne apprend souvent davantage sur la fiabilité d’un produit lors du premier problème que pendant son écran de bienvenue. Cela n’autorise pas à provoquer de faux incidents en production. Les scénarios de recette, en revanche, doivent couvrir stockage impossible, modèle indisponible, réseau coupé, réponse obsolète et accès modifié.

Un message utile comporte trois éléments : ce qui ne s’est pas terminé, ce qui est conservé et l’action possible. Il ne doit pas promettre « votre texte est sauvegardé » si seule sa copie en mémoire existe. Les variantes de microcopie en annexe distinguent ces situations.

## Carte des récupérations

| Échec | Ce qui reste visible | Action utile | Effet interdit |
|---|---|---|---|
| Modèle indisponible | Contexte et raisons réellement disponibles | Manuel, réessayer, mode démo explicite | Injecter Sarah à la place. |
| Génération refusée | Demande et brouillon | Reformuler ou continuer autrement | Boucle de contournement automatique. |
| Réponse devenue obsolète | Candidat daté et objets modifiés | Examiner ou relancer sur nouvel état | Appliquer en ignorant les préconditions. |
| Sauvegarde impossible | Travail et statut non enregistré | Autre destination/réessayer | Afficher une coche de succès. |
| Sync indisponible | Copie locale et attente | Reconnexion puis résolution | Confondre local sauvegardé et partagé confirmé. |
| Source absente | Référence et origine | Localiser/remplacer explicitement | Citation présentée comme relue. |
| Rôle retiré | Version accessible selon politique et brouillon récupérable | Compte/demande accès/copie autorisée | Publier en utilisant une ancienne permission. |

## Toast ou message durable ?

Un court accusé de réception réversible peut être discret. Une information nécessaire à la prévention d’une perte ne doit pas disparaître avant lecture. Une erreur d’enregistrement se rattache à l’état du document et reste consultable avec sa récupération. Une erreur de proposition se rattache à la demande et ne bloque pas l’édition ailleurs.

L’annonce accessible n’a pas besoin de déplacer le focus sur chaque message. Les mises à jour de progression doivent être agrégées et pertinentes, pas récitées à chaque token. La règle W3C sur les messages d’état fournit un point de référence ; la mise en œuvre native doit être testée avec les outils macOS. [R28](#source-r28)

## Réessayer n’est pas forcément répéter

L’action Réessayer conserve l’instruction mais vérifie le contexte actuel. Un document modifié entre deux essais produit une nouvelle requête liée au nouvel état. Les identifiants d’opération servent à éviter les doublons de commit, pas à imposer qu’une réponse périmée soit reçue comme neuve.

Si la demande est annulée, les résultats tardifs n’apparaissent pas. Une annulation peut être visuellement immédiate alors que l’arrêt du calcul est coopératif ; l’app doit préserver cette différence sans répéter des messages alarmants. Un modèle disponible après une panne ne relance pas toutes les demandes abandonnées sans nouvelle action.

## Réparer sans punir

Ne pas demander de remplir à nouveau un formulaire complet pour une seule valeur invalide. Conserver les champs valides et amener l’erreur au bon endroit. En partage, ne pas forcer à supprimer le brouillon divergent pour poursuivre ; une variante locale ou une proposition adaptée peut être l’issue sûre.

La tonalité doit rester directe et utile. La personnalité de Kollio n’est pas une excuse pour écrire « Oups, petite catastrophe ! » en cas de risque sur un document. Les textes d’erreur originaux du pack privilégient l’état précis et la prochaine action ; ils ne simulent pas une émotion de l’IA. [R30](#source-r30)



---

<a id="ch-13"></a>

# 13 — L’onboarding d’équipe : comprendre le mandat avant d’apprendre les boutons

## Le collègue invité ne commence pas un projet vide

Son premier besoin est de comprendre pourquoi cette invitation lui a été adressée et ce qu’il peut apporter. Le parcours ne doit pas l’obliger à choisir une profession, créer un espace personnel et découvrir tous les raccourcis avant d’ouvrir le document reçu. L’authentification peut être nécessaire ; la visite générale ne l’est pas.

L’arrivée proposée montre le nom du document, l’origine de l’invitation lorsqu’elle est autorisée, le rôle traduit en capacités et le point de départ. Un message du propriétaire peut expliquer « donne ton avis sur ces deux pistes ». Il reste attribué à cette personne, pas présenté comme une instruction système qui changerait les permissions.

## Une vue de départ n’est pas un verrou de navigation

Miro documente une zone d’arrivée pour les nouveaux invités. [R20](#source-r20) Notre transfert consiste à associer une ancre au besoin de collaboration. À sa première ouverture, l’invité peut commencer près de cette cible ; lors des reprises, sa vue locale est prioritaire. Il reste libre de se déplacer et un mode de suivi éventuel se quitte au premier geste explicite.

Si l’ancre a été supprimée, montrer un point de départ cohérent et signaler le changement. Ne pas faire croire que l’invitation était pour un autre objet. Une zone visuelle ne protège pas des données confidentielles : les droits de lecture portent sur le document et ses ressources selon le V2.

## Trois états qui doivent se lire immédiatement

**Brouillon privé.** Ma frappe et mes essais ne sont pas publiés. Le bouton pertinent est Publier la proposition, non Retenir dans le projet commun lorsque mon rôle ne l’autorise pas.

**Proposition publiée.** Mon apport est visible avec auteur et version. Il peut être commenté ou révisé. La personne qui l’examine voit la version réelle, pas un flux de frappes changeant sous son regard.

**Modification commune.** Une acceptation autorisée a produit un commit. Les autres reçoivent les mêmes identifiants et le statut partagé confirmé. Une animation locale ne constitue pas cet accusé de réception.

Ces états sont des projections des règles V2. L’onboarding les enseigne au moment de publier ou revoir, et les textes restent présents ensuite aux points à risque. On ne leur substitue pas une fois pour toutes un tutoriel de bienvenue.

## Premier apport d’un contributeur

Le contributeur ouvre la piste, ajoute son contexte, examine l’aperçu et choisit de publier. Si l’éditeur demande une modification, le commentaire pointe l’élément concerné. La révision est explicite et l’ancienne version reste traçable selon le produit. Le contributeur peut savoir si son apport attend une revue sans recevoir une série de relances culpabilisantes.

Le guide ne pousse pas à accepter une suggestion simplement pour terminer l’exercice. Dans un test d’équipe, demander à l’éditeur de repérer une incohérence connue est plus informatif que de lui demander « cliquez sur Retenir ». On mesure la compréhension du rôle, pas le nombre de publications.

## Premier conflit

Deux personnes modifient le même texte. L’interface doit présenter les variantes et leur origine au point affecté. La personne peut conserver la version commune tout en gardant sa variante à part. Le logiciel n’ouvre pas un énorme merge de développeur pour une phrase, mais ne cache pas non plus un écrasement sous un message de succès.

Cette situation ne doit pas afficher un tip « découvrez les commentaires » : elle demande la résolution du conflit, prioritaire sur le coaching. Une fois résolue, le système peut fournir une aide volontaire sur la collaboration, sans rejouer l’incident.

## Reprise et rétention saine

« Depuis votre dernière visite » se consulte à la demande et présente les décisions, demandes de revue et mentions utiles. Le nombre de déplacements de souris n’y est pas un progrès du projet. Marquer lu reste personnel. Quitter la session après avoir répondu à la question reçue est un succès possible, pas un signe d’abandon à corriger par des notifications supplémentaires.



---

<a id="ch-14"></a>
