# Kollio V3 — Client macOS et parité produit

**Statut** : chantier de réconciliation en revue. Cette documentation ne change pas encore le produit macOS.

## Contrat produit commun

La vision V3, les 5 scènes, la matrice d'écarts et la roadmap sont tenues dans [kollio/docs/v3 sur la branche de reconciliation](https://github.com/guillaume-flambard/kollio/tree/docs/kollio-v3-reconciliation/docs/v3), jusqu'à validation puis intégration de la PR.

Ce dépôt reste **client macOS**, pas une deuxième source de vérité produit. Ne pas réimplémenter une vision V3 différente dans `docs/PRODUCT_BLUEPRINT.md` avant la validation de R1.

## Baseline observée

- Référence : `main@536e7553a4eb6bc2fd3ec0d54102cf4c98ca4897` (2026-09-26).
- Domaine réutilisable : `packages/KollioCore` — `KollioDocument`, `DocumentCodec`, `DocumentStore`, commandes, propositions et `ProposalValidator`.
- UI réutilisable : moteur de canvas `packages/KollioApp/Sources/KollioApp/Canvas`, adaptateurs de modèles.
- Écarts V3 : accueil, navigation commune, modes Document/Canvas/Comparer, inspecteur, tokens aubergine/porcelain vs bleu/sauge actuel.
- `docs/known-limitations.md` avertit que le parcours manuel au trackpad et certaines cartes ne sont pas validés par observation humaine, que `run-app.sh --shot` peut capturer une autre fenêtre et que des fonctionnalités restent uniquement spécifiées.

## Pack de captures R0 — non réalisé

Pour chaque scène (Accueil, Création, Contenu, Proposition, Décision/Historique) :
- référence SHA, macOS/Xcode, écran et dimensions, langue et thème ;
- fixture sans données personnelles ;
- capture **de la fenêtre Kollio**, pas du bureau entier ;
- ouverture et inspection visuelle de l'image ; noter toute scène indisponible ;
- état : `missing` jusqu'à vraie capture, **jamais mockup prétendu screenshot**.

**Ne pas déclarer R0 terminé** avant comparaison avec les captures runtime Web.

## Ce qui doit rester stable pendant la réconciliation

- Édition manuelle et fichier `.kollio` lisible même sans IA ;
- une proposition ne devient pas une mutation sans validation et décision humaine ;
- identifiants stables, source et révisions ;
- comportement explicite en cas de modèle absent ;
- pas de migration destructive ni copie de la base Web dans Swift.

## Première tranche après validation R1

1. `AppShell` et navigation communs ;
2. même écran Accueil/création ;
3. vue Document puis Canvas sur un état partagé ;
4. `ProposalDiff` et inspecteur communs ;
5. contrat d'import/export versionné testé contre des fixtures Web.

**Priorité immédiate :** capturer l'application réelle, comparer, puis maquetter les mêmes cinq scènes Web et Mac.

## Attention — travail local plus récent que GitHub

Un examen **read-only** sur le Mac a révélé que `the local Mac checkout of Kollio` est à `e8d24c9` (HEAD détachée) avec des modifications en cours. Un pack produit plus récent se trouve dans `docs/product-pack/`, notamment `P13_VISUAL_LANGUAGE_V3.md`. **Ne pas écraser ni faire checkout dans cette copie.** La PR courante ne modifie que GitHub, dans une branche documentaire isolée.

Ce pack décrit le canvas comme l'application et la préférence pour un chrome très discret ; cela doit être confronté à la navigation à sections du Web. Voir [l'arbitrage A/B](https://github.com/guillaume-flambard/kollio/blob/docs/kollio-v3-reconciliation/docs/v3/05-design-arbitrations.md) avant de modifier le shell SwiftUI.

Des captures historiques ont été identifiées dans le dossier local `build/` : `kollio-presentation.png`, `kollio-comparison.png`, `kollio-window.png` et d'autres. Elles ne sont ni publiées ni certifiées comme état courant. Ne pas les uploader sans revue de confidentialité et provenance.
