# 26 — Correspondance avec les 71 fonctionnalités V2

Cette matrice n’ajoute pas 71 nouvelles fonctions et ne déclare pas leur implémentation. Elle rattache l’index existant aux questions de design, chapitres et micro-interactions. Une fonction sans IX dédiée reste couverte par les principes et protocoles indiqués ; cela ne signifie pas qu’un nouveau composant doit être inventé.

| Fonction V2 | Point de design à vérifier | Chapitres | Interactions |
|---|---|---|---|
| **DOC-01** — Premier lancement et restauration | Entrée personnelle, focus initial et récupération non destructive. | 12, 13, 17 | IX-01 |
| **DOC-02** — Saisir un contexte et commencer | Phrase originale avant modèle, une seule création. | 12, 13, 17 | IX-01, IX-02 |
| **DOC-03** — Nouveau, ouvrir et documents multiples | Isolation des fenêtres, caméra et brouillons par session. | 12, 13, 17 | IX-31 |
| **DOC-04** — Sauvegarde, récupération et fermeture | Sauvegarde locale distincte du réseau et erreur persistante. | 12, 13, 17 | IX-27, IX-32 |
| **DOC-05** — Renommer, dupliquer, exporter | Périmètre visible, copie distincte, aperçu fidèle. | 12, 13, 17 | IX-33, IX-43 |
| **DOC-06** — Retrouver ses documents | Palette temporaire et origine des résultats. | 12, 13, 17 | IX-30, IX-31 |
| **DOC-07** — Archiver, corbeille et suppression | Archiver, corbeille et suppression définitive distincts. | 12, 13, 17 | Principes transversaux |
| **DOC-08** — Préférences et support diagnostic | Préférences lisibles sans polluer le canvas. | 12, 13, 17 | IX-44 |
| **CAN-01** — Naviguer au trackpad et à la souris | Pan/pinch directs, ancre et priorité des champs. | 11, 14, 20, 21, 23 | IX-10, IX-11, IX-12 |
| **CAN-02** — Sélectionner et accéder aux actions | Sélection, focus et actions atteignables. | 11, 14, 20, 21, 23 | IX-04, IX-05, IX-06, IX-21 |
| **CAN-03** — Déplacer une ou plusieurs instances | Prise directe, positions relatives et une seule annulation. | 11, 14, 20, 21, 23 | IX-09 |
| **CAN-04** — Éditer le contenu sur place | Édition native sans génération accidentelle. | 11, 14, 20, 21, 23 | IX-03, IX-07 |
| **CAN-05** — Créer, dupliquer et retirer des objets | Créer, dupliquer une occurrence et supprimer un objet distincts. | 11, 14, 20, 21, 23 | IX-13 |
| **CAN-06** — Relier, sélectionner et modifier une relation | Sens du lien, hit-area et alternative au drag. | 11, 14, 20, 21, 23 | IX-14, IX-15 |
| **CAN-07** — Regrouper et replier visuellement | Repli de présentation non confondu avec décision. | 11, 14, 20, 21, 23 | IX-16 |
| **CAN-08** — Placer des propositions et organiser localement | Même géométrie en preview et après acceptation. | 11, 14, 20, 21, 23 | IX-18 |
| **CAN-09** — Chercher et naviguer dans le document | Retrouver sans modifier le statut de la cible. | 11, 14, 20, 21, 23 | IX-12, IX-30 |
| **CAN-10** — Présentation et lisibilité accessible | Lecture structurée, focus et vue concentrée. | 11, 14, 20, 21, 23 | IX-08, IX-16, IX-44 |
| **CTX-01** — Ajouter une information à un endroit précis | Apport durable, cible explicite, brouillon préservé. | 15, 17, 22 | IX-02, IX-03, IX-13 |
| **CTX-02** — Déposer des ressources et les lire | Dépôt expliqué, état d’extraction et lecture longue. | 15, 17, 22 | IX-28 |
| **CTX-03** — Citer et vérifier la provenance | Retour exact à la source et limites de preuve. | 15, 17, 22 | IX-08 |
| **CTX-04** — Définir une hypothèse ou contrainte | Rôle et portée compréhensibles sans label technique dominant. | 15, 17, 22 | Principes transversaux |
| **CTX-05** — Comprendre l’impact d’une nouvelle information | Impact borné, avant/après stable, pas de cascade globale. | 15, 17, 22 | IX-24, IX-29 |
| **CTX-06** — Voir et limiter ce que l’IA utilisera | Ce qui est utilisé et envoyé, sans chaîne de pensée. | 15, 17, 22 | Principes transversaux |
| **CTX-07** — Mettre à jour une ressource sans effacer l’histoire | Versions de source et décisions à revoir visibles. | 15, 17, 22 | IX-29 |
| **AI-01** — Disponibilité et choix de l’intelligence | Destination réelle et modèle indisponible sans blocage. | 13, 15, 16, 20 | IX-17 |
| **AI-02** — Première exploration de son propre contexte | Première branche depuis le vrai contexte. | 13, 15, 16, 20 | IX-17, IX-18 |
| **AI-03** — Explorer une branche | Exploration locale sans effacer l’existant. | 13, 15, 16, 20 | IX-17, IX-18 |
| **AI-04** — Répondre à une clarification | Question attachée et réponse conservée. | 13, 15, 16, 20 | IX-03 |
| **AI-05** — Comparer des pistes sans inventer des scores | Comparaison lisible avec références, aucun score inventé. | 13, 15, 16, 20 | Principes transversaux |
| **AI-06** — Synthétiser et préparer un livrable | Synthèse liée à une révision, original intact. | 13, 15, 16, 20 | Principes transversaux |
| **AI-07** — Examiner et corriger une proposition | Ajout, modification et impact ont une revue adaptée. | 13, 15, 16, 20 | IX-18, IX-19, IX-24, IX-25 |
| **AI-08** — Retenir, écarter ou masquer une proposition | Retenir, écarter et masquer explicitement différents. | 13, 15, 16, 20 | IX-20, IX-21, IX-22 |
| **AI-09** — Annuler, reprendre et comprendre les erreurs | Annulation, conservation et messages actionnables. | 13, 15, 16, 20 | IX-17, IX-25, IX-26, IX-27 |
| **AI-10** — Choisir un traitement cloud explicitement | Consentement de destination avant envoi. | 13, 15, 16, 20 | Principes transversaux |
| **AI-11** — Voir les raisons et la destination d’une proposition | Origines inspectables et vocabulaire honnête. | 13, 15, 16, 20 | Principes transversaux |
| **AI-12** — Gérer une grande quantité de contexte | Limite de contexte sans troncature cachée. | 13, 15, 16, 20 | Principes transversaux |
| **DEC-01** — Prendre une décision explicite | Acte humain et portée, pas certificat de vérité. | 15, 18, 22 | IX-20, IX-24 |
| **DEC-02** — Écarter et rouvrir un chemin | Trace compacte, raison, réouverture sans modèle. | 15, 18, 22 | IX-22, IX-23 |
| **DEC-03** — Annuler et rétablir sans perdre autrui | Annulation propre à la tâche, conservation d’autrui. | 15, 18, 22 | Principes transversaux |
| **DEC-04** — Construire une expérience de validation | Protocole d’essai local et mesurable, pas tracker de tâches. | 15, 18, 22 | Principes transversaux |
| **DEC-05** — Enregistrer un résultat et apprendre | Résultat et limites liés aux preuves. | 15, 18, 22 | Principes transversaux |
| **DEC-06** — Comprendre comment on en est arrivé là | Histoire orientée décisions, pas replay de pixels. | 15, 18, 22 | IX-08, IX-41 |
| **TEAM-01** — Se connecter et créer un espace | Connexion secondaire qui ne bloque pas le solo. | 18, 22, 23 | Principes transversaux |
| **TEAM-02** — Partager un document privé | Qui verra quoi, aperçu avant transfert. | 18, 22, 23 | IX-33 |
| **TEAM-03** — Inviter et rejoindre | Destinataire, rôle et expiration avant acceptation. | 18, 22, 23 | IX-34 |
| **TEAM-04** — Appliquer les droits et gérer les membres | Action disponible selon droits, perte d’accès compréhensible. | 18, 22, 23 | IX-34, IX-40 |
| **TEAM-05** — Présence réelle et suivi volontaire | Présence réelle et caméra volontaire. | 18, 22, 23 | IX-38 |
| **TEAM-06** — Discuter et mentionner au bon endroit | Discussion attachée, mention distincte d’invitation. | 18, 22, 23 | IX-36 |
| **TEAM-07** — Contribuer sans écraser le document commun | Brouillon privé puis publication d’une version. | 18, 22, 23 | IX-19, IX-35 |
| **TEAM-08** — Revoir, demander une modification et accepter | Acceptation de la version effectivement examinée. | 18, 22, 23 | IX-20, IX-25, IX-36 |
| **TEAM-09** — Éditer en parallèle et résoudre un conflit | Avant/après sans perte d’apport. | 18, 22, 23 | IX-37 |
| **TEAM-10** — Travailler hors ligne puis synchroniser | Sauvegarde locale, outbox et réseau séparés. | 18, 22, 23 | IX-32, IX-39 |
| **TEAM-11** — Reprendre une session et voir ce qui a changé | Reprise à la demande des changements significatifs. | 18, 22, 23 | IX-41 |
| **TEAM-12** — Quitter, révoquer et garder une copie autorisée | Accès perdu différent de fichier supprimé. | 18, 22, 23 | IX-40 |
| **TEAM-13** — Présenter ensemble sans piloter les autres | Suivi explicite, sortie immédiate au geste local. | 18, 22, 23 | IX-38 |
| **STU-01** — Transformer son savoir-faire en méthode réutilisable | Méthode lisible, exemples et limites en développement local. | 08, 19, 22 | Principes transversaux |
| **STU-02** — Enregistrer une capacité technique | Capacité comprise sans exposer tout le schéma. | 08, 19, 22 | Principes transversaux |
| **STU-03** — Trouver des contributions pertinentes | Contribution près du besoin, provenance et limites. | 08, 19, 22 | Principes transversaux |
| **STU-04** — Assembler un petit produit | Assemblage lisible sans workflow builder universel. | 08, 19, 22 | IX-42 |
| **STU-05** — Tester un outil avec des données de démonstration | Essai réellement réactif, état et données fictives explicites. | 08, 19, 22 | IX-42 |
| **STU-06** — Réutiliser et mettre à jour une contribution | Référence, variante et version épinglée distinctes. | 08, 19, 22 | Principes transversaux |
| **STU-07** — Voir les auteurs et négocier la répartition | Attribution et accord séparés ; pas de royalties par clic. | 08, 19, 22 | Principes transversaux |
| **STU-08** — Préparer une publication privée ou publique | Préparation privée, publication explicitement confirmée. | 08, 19, 22 | Principes transversaux |
| **STU-09** — Consulter un produit comme utilisateur final | Résultat utile sans montrer le canvas de fabrication. | 08, 19, 22 | IX-42 |
| **COM-01** — Acheter un accès à un produit | Droit acheté et prix réels, pas de faux progrès. | 19, 22 | Principes transversaux |
| **COM-02** — Calculer et consulter les revenus | Simulation distincte de revenu réel et historique lisible. | 19, 22 | Principes transversaux |
| **COM-03** — Support, signalement et remboursement | Recours retrouvable, erreur et responsabilité nommées. | 19, 22 | Principes transversaux |
| **EXT-01** — Exporter un document vivant et le lire sur le web | Vue figée et document vivant distincts. | 07, 17, 19 | IX-43 |
| **EXT-02** — Recevoir une proposition d’un autre assistant | Proposition étrangère soumise aux mêmes contrôles et revue. | 07, 17, 19 | Principes transversaux |
| **EXT-03** — Commandes natives et partage système | Conventions natives et retour au document. | 07, 17, 19 | Principes transversaux |


---

<a id="ch-27"></a>
