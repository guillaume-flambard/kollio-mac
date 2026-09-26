# 18 — Huit parcours d’onboarding, de reprise et de collaboration

## Des scénarios de recherche et de recette

Ces huit parcours complètent J01–J14 du cahier des charges. Ils mettent l’accent sur les différences d’entrée, la maîtrise d’une action, la récupération et l’aide au bon moment. Les personnages d’équipe et les données sont synthétiques. Aucune personne n’a encore exécuté ces scripts pour cette livraison.

### ONJ-01 — Première valeur sans connaître le vocabulaire

**Entrée :** Nouveau document individuel ; données synthétiques.

**Tâche :** Organiser une découverte d’atelier avec 30 places, deux intervenants et aucun budget publicitaire.

| Moment | Action | Résultat attendu | Politique d’aide |
|---|---|---|---|
| Arrivée | Lire puis écrire son contexte | Champ actif, exemple secondaire, aucune connexion obligatoire | Aucun conseil automatique sur dix fonctions |
| Validation | Cmd+Entrée | Contexte visible et sauvegarde distinguée de la génération | La première aide ne couvre pas les mots saisis |
| Proposition | Lire deux pistes et une question | Libellé Proposition, actions et ressources de contexte | ONB-01 seulement si éligible et ancre stable |
| Contrôle | Refuser une piste inadaptée et en corriger une autre | Le refus ne demande pas de terminer un tutoriel ; modification du candidat visible | Une action observée clôt le conseil pertinent |
| Reprise | Retenir, quitter puis rouvrir | Même contexte et même décision ; aide déjà refusée non rejouée | Aucun onboarding depuis zéro |

**Point de vigilance.** Ne pas considérer la simple apparition du candidat comme une valeur obtenue. Demander ce qui a été utile et si cela fait déjà partie du document.

**Patterns :** PAT-01, PAT-03, PAT-05, PAT-21 · **Parcours V2 :** J01, J04.

### ONJ-02 — Sarah découvre une limite et la conserve

**Entrée :** Ouverture volontaire de la fixture Sarah existante.

**Tâche :** Comparer CRM et export sans transformer une absence d’identifiants en accès disponible.

| Moment | Action | Résultat attendu | Politique d’aide |
|---|---|---|---|
| Sélection | Cliquer la piste CRM | Actions localement visibles | Pas de qualification professionnelle demandée |
| Précision | Ajouter Pas d’accès API pour cette initiative | Phrase conservée et liée ; la requête suivante la reçoit | Pas de tip pendant la frappe |
| Décision | Écarter la piste et expliquer | Branche repliée, caméra stable | ONB-03 envisageable une fois après stabilisation |
| Alternative | Explorer CSV puis poser une question sur les tags | La question reste inconnue faute de fichier observé | Aucune colonne prétendument vérifiée |
| Retour | Rouvrir CRM pour lecture et réexamen | Ancienne raison retrouvée, pas de nouvelles générations | La réouverture observée clôt son conseil |

**Point de vigilance.** Sarah reste une fixture sans biographie ajoutée. Le rejet n’annule pas le bloc réutilisé dans une autre direction.

**Patterns :** PAT-14, PAT-24, PAT-26, PAT-35 · **Parcours V2 :** J02, J03.

### ONJ-03 — Premier lancement sur Mac sans modèle prêt

**Entrée :** État de disponibilité simulé pour tests ; pas de cloud autorisé.

**Tâche :** Conserver une idée et créer une relation manuellement.

| Moment | Action | Résultat attendu | Politique d’aide |
|---|---|---|---|
| Saisie | Écrire un vrai contexte de test | Le champ ne promet pas une génération garantie | Aucune permission cloud anticipée |
| Indisponibilité | Explorer | Motif réel et Continuer manuellement | Erreur/situation utile prioritaire sur toute aide |
| Travail | Ajouter une idée et la relier par clics | Objet réel et lien undoable | Action locale indépendante du modèle |
| Récupération | Relancer plus tard avec le modèle disponible | Ancien travail toujours là | Pas de rejeu automatique des demandes |
| Choix | Explorer explicitement l’objet | Proposition adaptée au document courant | L’aide tient compte des actions déjà pratiquées |

**Point de vigilance.** Le manuel n’est ni un échec ni un faux mode démo. Une donnée non sauvée sur disque n’est pas annoncée récupérable après crash.

**Patterns :** PAT-07, PAT-16, PAT-19 · **Parcours V2 :** J12.

### ONJ-04 — Invité lecteur qui arrive pour comprendre

**Entrée :** Invitation de lecture autorisée, ancrée à une décision.

**Tâche :** Comprendre la décision et retrouver sa source sans créer un projet.

| Moment | Action | Résultat attendu | Politique d’aide |
|---|---|---|---|
| Invitation | Ouvrir avec le compte attendu | Document, intention et rôle visibles | Aucun tour de créateur |
| Arrivée | Lire la zone désignée | Ancre lisible et contexte accessible | ONB de publication non éligible au viewer |
| Enquête | Ouvrir la source puis revenir | Origine et limitations accessibles | Pas de geste obligatoire au survol |
| Navigation | Explorer la carte en lecture | Caméra personnelle | Aucun changement du graphe commun |
| Départ | Fermer | Aucune création ou invitation ajoutée pour compléter un parcours | La lecture utile peut être une session réussie |

**Point de vigilance.** Un lien profond ne doit pas révéler un titre ou contenu à un compte non autorisé ; une ancre disparue demande un état explicite.

**Patterns :** PAT-09, PAT-18, PAT-27 · **Parcours V2 :** J06, J09.

### ONJ-05 — Contributeur puis réviseur : deux onboardings différents

**Entrée :** Nora contributor, Alex editor ; comptes fictifs de recette.

**Tâche :** Publier une variante et la faire accepter après révision exacte.

| Moment | Action | Résultat attendu | Politique d’aide |
|---|---|---|---|
| Brouillon | Nora modifie et explore en privé | Aperçu local ; Alex ne voit pas ses frappes | ONB-07 près de Publier, pas Retenir |
| Publication | Nora choisit Publier | Auteur et version visibles après confirmation | Pas de succès avant confirmation |
| Revue | Alex ouvre v1 | Comparaison et actions de revue | ONB-08 peut expliquer la portée de version |
| Changement | Nora publie v2 pendant la lecture | Alex conserve la version qu’il lisait | Pas de remplacement silencieux |
| Acceptation | Alex doit revoir v2 avant commit | Une transaction commune et mêmes IDs | Conflit/version prime sur l’aide d’apprentissage |

**Point de vigilance.** Une réduction du taux de clic Retenir peut signifier une revue plus exacte, pas un moins bon onboarding.

**Patterns :** PAT-27, PAT-28, PAT-29 · **Parcours V2 :** J06, J07.

### ONJ-06 — Réduire les animations et éviter le drag

**Entrée :** Clavier, pointeur simple, grande taille de texte ; tests séparés.

**Tâche :** Créer une relation, lire une différence et retrouver le contexte.

| Moment | Action | Résultat attendu | Politique d’aide |
|---|---|---|---|
| Ajout | Ajouter une idée par bouton ou clavier | Focus à la bonne cible | Aucune aide exclusivement déclenchée par hover |
| Liaison | Relier puis cliquer une cible | Lien créé sans pression maintenue | Alternative de pointeur distincte du clavier |
| Proposition | Ouvrir un candidat modifiant une phrase | Avant/après statique | Pas de disparition d’informations avec Reduce Motion |
| Lecture | Fermer le détail | Focus restauré au point de départ | Aucun retour au début de fenêtre |
| Reprise | Chercher une branche écartée | Lecture temporaire sans réactivation | Aide masquable et focus visible |

**Point de vigilance.** Une capture responsive du livre ne prouve aucun geste natif. VoiceOver nécessite une vraie recette dédiée.

**Patterns :** PAT-16, PAT-22, PAT-35, PAT-36 · **Parcours V2 :** J05, J14.

### ONJ-07 — Erreur pendant une aide et reconnexion

**Entrée :** Document partagé ; une aide peut être éligible, pas forcément montrée.

**Tâche :** Éditer hors ligne, fermer, revenir et résoudre un conflit.

| Moment | Action | Résultat attendu | Politique d’aide |
|---|---|---|---|
| Début | Lire un conseil sur les états de stockage | Sur le Mac et partagé sont distingués | Pas de données privées dans l’état de coaching |
| Coupure | Éditer puis réseau perdu | Sauvegarde locale et outbox indiquées | L’erreur suspend l’aide facultative |
| Fermeture | Quitter normalement | Travail conservé si écriture réellement réussie | Pas de promesse de synchronisation |
| Retour | Reconnecter | Conflit ciblé avec les variantes | Aucun accueil de nouveauté au-dessus du conflit |
| Résolution | Conserver une variante et synchroniser | Statut exact après commit | Le conseil rejeté ne réapparaît pas |

**Point de vigilance.** Un timeout ne dit pas si un fournisseur a déjà calculé. Un réessai réseau doit suivre les règles d’idempotence, pas seulement le design du bouton.

**Patterns :** PAT-19, PAT-30, PAT-31 · **Parcours V2 :** J08, J12.

### ONJ-08 — Découvrir une capacité avancée sans refaire la formation

**Entrée :** Utilisateur déjà autonome ; première méthode réutilisable.

**Tâche :** Enregistrer un groupe comme méthode puis la réutiliser.

| Moment | Action | Résultat attendu | Politique d’aide |
|---|---|---|---|
| Intention | Sélectionner un groupe et ouvrir son menu secondaire | Enregistrer comme méthode devient une action contextuelle pertinente | Pas de publicité de marketplace au premier lancement |
| Préparation | Renseigner limites et exemple manquants | Progression du contenu utile, pas checklist marketing | Seuls les prérequis réels sont demandés |
| Enregistrement | Sauver en privé | Contribution et version identifiées | Pas de publication ni droits financiers implicites |
| Réutilisation | Ajouter dans un autre document | Même contribution référencée | Pas de copie silencieuse et attribution perdue |
| Aide | Ouvrir volontairement une explication | Fonctionnement des versions et droits | L’aide ne relance pas les conseils de pan/zoom |

**Point de vigilance.** Décrire cette arrivée ne constitue pas une implémentation du studio ; sa recette intervient au lot V2 correspondant.

**Patterns :** PAT-06, PAT-10, PAT-20 · **Parcours V2 :** J10, J13.



---

<a id="ch-19"></a>
