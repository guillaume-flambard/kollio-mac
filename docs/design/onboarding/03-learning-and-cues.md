# 06 — Apprentissage progressif : un ensemble d’actions, pas une checklist commerciale

## État d’apprentissage proposé

Nous retenons quelques observations locales : contexte créé, source ouverte, proposition examinée, modification retenue, branche écartée/rouverte, recherche utilisée, proposition publiée en équipe. Chaque événement a une portée. Ouvrir un exemple n’atteste pas qu’une source réelle a été lue ; exécuter une action ne prouve pas une maîtrise durable.

L’état est séparé du document et des permissions. Il ne fait pas partie du `.kollio` portable par défaut. Exporter une idée ne doit pas exporter l’historique d’utilisation du logiciel de son auteur. Si une synchronisation future des aides est proposée, elle sera explicitement conçue ; ce livre ne l’exige pas.

Un ensemble de drapeaux locaux et datés suffit au départ. Pas de score de maturité, segmentation psychologique ou LLM qui lit le contenu pour choisir un tutoriel. Le coordinateur utilise les événements du produit, la surface active et la préférence de la personne.

## Valeur et apprentissage : deux axes

On peut connaître les gestes et ne rien obtenir d’utile. On peut obtenir un résultat grâce au modèle sans comprendre comment le corriger. Les mesures doivent garder ces deux situations distinctes.

Nous proposons de noter séparément : **artefact utile rapporté**, **contrôle observé**, **récupération réussie**, **provenance comprise**. En expérimentation, l’enquêteur peut demander quel élément a aidé ; la télémétrie ne peut pas affirmer automatiquement qu’un texte est utile parce qu’il a été retenu. Le rapport doit qualifier ce signal de proxy.

La notion d’activation reste un outil d’analyse, pas une obligation produit. Un viewer n’a pas besoin de devenir éditeur pour avoir réussi sa visite. Une équipe n’est pas mieux onboardée parce que le propriétaire a invité cinq collègues plutôt qu’un seul collègue réellement concerné.

## Aider après une action réussie

Un raccourci peut être suggéré après que la personne a utilisé la commande visible, lorsque l’interface est redevenue calme. Le bénéfice est compréhensible : une autre manière d’effectuer ce qu’elle vient de faire. Le conseil ne précède pas la première action en exigeant de mémoriser un clavier entier.

La difficulté d’un rappel n’est pas seulement son nombre de mots. Si la cible s’est déplacée, si la personne ouvre une autre fenêtre ou si un message de sauvegarde demande attention, le conseil doit être revalidé ou écarté. Une file de bulles en attente n’est pas une file de tâches obligatoires que l’utilisateur doit vider.

## Pourquoi la checklist n’est pas l’écran d’accueil proposé

Une checklist peut aider une procédure explicite, par exemple réunir les conditions d’une publication. Dans Kollio individuel, elle risque de transformer la découverte en collecte de coches : créer, inviter, connecter un compte, ajouter un fichier, exporter. Plusieurs de ces actions n’ont aucune utilité dans une session de pensée précise.

Le mécanisme retenu est plus léger : une aide demandée, des conseils contextuels rares et un exemple isolé. Si la recherche montre que les utilisateurs ne saisissent pas le modèle mental sans repère plus global, tester une courte feuille « Comment le document évolue » accessible, plutôt qu’imposer un parcours à compléter à tout le monde.

## Fin du guidage

Un conseil complété est retiré ; un conseil fermé volontairement respecte cette fermeture. « Ne plus afficher les conseils » n’interdit pas les informations essentielles de sécurité ou de sauvegarde. Une personne doit pouvoir retrouver une explication à la demande même après désactivation du coaching.

Ne pas réinitialiser l’aide après chaque mise à jour. Une nouvelle fonction réellement différente peut recevoir un identifiant de conseil distinct, mais le même geste ne redevient pas nouveau parce que le texte marketing a changé. Les versions des règles servent à la compatibilité, pas à contourner une préférence de non-affichage.



---

<a id="ch-07"></a>

# 07 — Les aides contextuelles : conditions, priorités et refus respectés

## Une règle d’éligibilité n’est pas une décision d’afficher

La politique proposée distingue trois questions : le conseil a-t-il du sens pour cette personne et cette action ? Peut-il être montré maintenant sans interrompre ? Sa surface existe-t-elle réellement et est-elle accessible ? Un conseil peut être éligible mais temporairement supprimé par un état d’édition, une fenêtre inactive ou un conflit.

Le moteur doit être déterministe et inspectable. TipKit peut fournir la présentation et une partie de la mécanique ; un coordinateur local de Kollio conserve les règles de priorité du produit. Il ne faut pas créer un deuxième système complet qui duplique tous les compteurs du framework. Choisir une source de vérité et adapter les états nécessaires, en vérifiant les API du SDK installé. [R03](#source-r03) · [R04](#source-r04)

## Priorité de l’attention

| Niveau | Exemples | Comportement proposé |
|---|---|---|
| 0 — intégrité du travail | Échec de sauvegarde, accès perdu, conflit bloquant | Message durable, action de récupération ; suspend le coaching. |
| 1 — décision nécessaire | Autoriser un traitement distant, choisir une version | Surface focalisée à la demande ; pas une info-bulle marketing. |
| 2 — aide demandée | Pourquoi cette proposition ? Comment relier ? | Ouvrir l’explication de la cible ; ne pas afficher un autre conseil. |
| 3 — guidage facultatif | Première proposition, raccourci utile | Une seule aide, pertinente, pouvant être fermée. |
| 4 — nouveautés | Nouvelle capacité non requise | Discrète et différée ; ne masque jamais le travail en cours. |

Ce classement est une décision Kollio. Il ne doit pas devenir un moteur de notifications général ou un moyen de repousser tous les messages jusqu’à ce qu’ils n’aient plus d’utilité. Une erreur critique appartient à un canal indépendant : désactiver les conseils ne désactive pas les erreurs.

## Politique initiale à tester

Une seule aide facultative visible par fenêtre, et une limite globale empêchant deux fenêtres de réclamer l’attention en même temps. Deux conseils facultatifs au maximum dans la première session d’essai constituent un point de départ prudent, non une norme scientifique. Entre deux conseils, attendre une nouvelle action pertinente et un état stable ; aucun compte à rebours ne crée seul un besoin.

L’affichage est interdit pendant la frappe, un drag, un pinch, un menu natif actif, une modalité de partage, une erreur non résolue ou une présentation suivie. Il est aussi interdit si la cible est hors écran. L’application ne déplace pas la caméra pour rendre un tip éligible.

Un conseil affiché peut être fermé par Échap ou un bouton. Le focus retourne au point logique. Si la personne choisit de ne plus voir ce conseil, l’état est durable. Le bouton « Plus tard », s’il existe, doit avoir une vraie politique de retour : autre session ou nouvelle occurrence utile, pas trente secondes plus tard au même endroit. Nous privilégions une fermeture sans relance automatique dans cette première version.

## Exemple de règle

`ONB-02` concerne la première proposition reçue. Conditions : proposition valide présente, rôle permettant de l’examiner, absence d’aide demandée et d’erreur, cible visible, préférence de conseils active, aucun accomplissement antérieur équivalent. Le texte précise que rien n’est appliqué automatiquement. L’action observée — examen, correction, acceptation ou refus explicite — invalide le conseil correspondant. Aucun clic d’acceptation n’est forcé pour le faire disparaître.

La règle ne lit pas le sujet sensible du document et ne transmet pas son contenu à un système analytique. Elle sait que le statut est `pending`, pas pourquoi l’utilisateur réfléchit ou s’il est intelligent. Si la proposition devient `stale`, le conseil n’est pas présenté ; l’information d’obsolescence prend sa place.

## Éviter la dette de conseils

Un changement de fenêtre, une annulation ou une nouvelle version de candidat invalide l’ancre initiale. Ne pas conserver une notification différée contenant un ancien identifiant de vue. Au prochain état stable, recalculer l’éligibilité à partir des objets actuels. Si l’action a été réalisée entre-temps, l’aide disparaît de la liste des candidates.

Le mode de diagnostic doit expliquer pourquoi rien n’a été montré : déjà effectué, fermé, rôle incompatible, cible cachée, budget atteint ou interaction active. Il n’apparaît pas sur le canvas utilisateur. Cela permet de tester la politique sans introduire un panneau de paramètres du coaching dans l’application.



---

<a id="ch-08"></a>
