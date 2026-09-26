# 14 — Ce que ce livre change, et ce qu'il ne change pas

Comparaison entre le livre *Patterns UX, onboarding & interactivité* et ce qui
est déjà écrit comme exigence. Elle est écrite après coup, donc elle décrit un
état réel et non une intention.

## Le recouvrement est réel et il est assumé

Le livre apporte **20 contrats MIC**. L'atlas V1 en apportait **44 IX**. Ce ne
sont pas deux jeux de règles concurrents : ce sont deux angles sur les mêmes
gestes. `MIC-01 Le contexte devient un objet` et `IX-02 Transformer la saisie en
contexte` décrivent le même moment depuis deux positions — l'une par le
comportement, l'autre par le moment où la personne l'apprend.

La règle appliquée est celle de l'atlas lui-même : **l'exigence l'emporte, le
livre reste l'histoire.** Les 44 IX sont déjà devenues 21 exigences dans
`openspec/changes/l0-design-contract/specs/interaction/spec.md`, et chacune cite
les IX qu'elle absorbe. Les 20 MIC n'y ajoutent donc **aucune exigence**.

Ce qui suit compte ce qui reste.

## Table de correspondance

| MIC | IX déjà exigés | Verdict |
|---|---|---|
| MIC-01 contexte devient objet | IX-02 | déjà couvert |
| MIC-02 sélection et actions | IX-04, IX-06 | déjà couvert |
| MIC-03 trajet vers une commande | IX-06 | déjà couvert |
| MIC-04 drag sans ressort | IX-09 | déjà couvert |
| MIC-05 vue et objet séparés | IX-10, IX-11 | déjà couvert |
| MIC-06 saisie attachée | IX-03, IX-07 | déjà couvert |
| MIC-07 accusé de réception | IX-17 | déjà couvert |
| MIC-08 apparition de branche | IX-18 | déjà couvert |
| MIC-09 candidat retenu au même endroit | IX-18, IX-20 | déjà couvert |
| MIC-10 lire une modification | IX-19 | déjà couvert |
| MIC-11 écarter garde une trace | IX-22 | déjà couvert |
| MIC-12 rouvrir n'est pas régénérer | IX-23 | déjà couvert |
| MIC-14 modèle indisponible | IX-27 | déjà couvert |
| MIC-15 échec de sauvegarde | IX-27, IX-32 | déjà couvert |
| MIC-16 invitation comprise | IX-33, IX-34 | déjà couvert |
| MIC-17 brouillon publié | IX-35 | déjà couvert |
| MIC-18 conflit ciblé | IX-37 | déjà couvert |
| MIC-19 suivi interrompu | IX-38 | déjà couvert |
| MIC-20 revenir à une cible | IX-30 | déjà couvert |
| **MIC-13 conseil contextuel non bloquant** | **aucun** | **nouveau** |

Dix-neuf sur vingt sont des reformulations. **Un seul apporte quelque chose.**

## Ce qui est réellement nouveau

### La politique de coaching, qui n'existe nulle part

`MIC-13` est le seul contrat sans exigence, et il ouvre un sujet absent de tout
le dépôt. Aucun des 16 deltas, aucune des 38 exigences accumulées et aucun des 21
contrats d'interaction ne dit quoi que ce soit sur **quand une aide a le droit
d'apparaître**.

Le livre y ajoute un registre de 10 conseils `ONB-01` à `ONB-10`, avec pour
chacun un déclencheur, une ancre, un texte FR/EN et une condition de fin. Et
surtout une politique : cinq niveaux de priorité, une aide automatique visible
par fenêtre, deux apparitions par session, une impression par conseil,
interdiction pendant la frappe, le drag, le pinch, un menu actif, une erreur non
résolue ou une présentation.

C'est une exigence, pas une intention. Elle est testable sans personne : la règle
d'éligibilité est déterministe, donc un test peut décider qu'aucun conseil
n'apparaît pendant une saisie, et que deux fenêtres ne réclament pas l'attention
en même temps.

**Proposé :** une capability `guidance` avec trois exigences — l'éligibilité est
déterministe et inspectable, la priorité du travail passe avant le coaching, un
conseil ne réapparaît pas après un refus ou une action — et le registre `ONB`
comme donnée, pas comme code.

Ce qui n'est **pas** proposé, volontairement : aucune exigence sur le *contenu*
des conseils. « Ces éléments sont proposés, examinez-les avant de les retenir »
est une phrase d'interface, pas une règle. Elle se teste en lisant, pas en
assertant.

### Les 36 patterns PAT : un catalogue, pas des exigences

`PAT-01` à `PAT-36` sont des séquences proposées avec un anti-pattern et une
récupération. La plupart décrivent ce que les exigences `interaction` couvrent
déjà, en insistant sur la variations. Un pattern est une illustration ; il ne
devient pas une règle sans avoir à montrer qu'il peut échouer.

Deux exceptions méritent un jour une exigence, parce qu'elles n'ont pas de
contrepartie actuelle :

- **PAT-10** — un conseil ne change pas d'identifiant pour contourner un refus.
  C'est une règle de conception qui protège une préférence, et c'est testable.
- **PAT-20** — la divulgation progressive exige que l'accès au secondaire soit
  *évident*. C'est le complément manquant de l'exigence « contextual actions are
  few, named and reachable », qui dit combien mais pas comment le secondaire se
  signale.

### Les 10 protocoles EXP et les 8 parcours ONJ : observation, pas spécification

`EXP-01` à `EXP-10` sont des protocoles d'étude. `ONJ-01` à `ONJ-08` sont des
scripts de recette qui se recouvrent largement avec `J01`–`J14` du cahier des
charges. Aucun des deux ne devient une exigence : ils demandent une personne, et
une exigence qu'aucun test du dépôt ne peut décider serait une exigence que
personne ne vérifierait.

`EXP-03` est le protocole de `DR-01`. Il est déjà mentionné dans
`l0/tasks.md` comme décision en attente. Les deux documents concordent, ce qui est
le résultat utile : le sujet est identifié, la décision n'est pas prise, et
personne ne l'a prise par défaut.

## Un point que ce livre corrige

Le livre répète une erreur que j'ai faite plus tôt dans cette session : il
presentent certains matériaux comme des faits alors que ce sont des propositions. Sa
section 25 dit que « le critère décisif » est qu'après un changement la personne
sache où elle est. C'est une bonne question, pas un critère mesuré, et le livre
le sait — il dit lui-même qu'aucune séance n'a eu lieu.

Ce qui manque au livre, et que le dépôt a maintenant : un mécanisme qui empêche
un chapitre de recherche de devenir une source de vérité. Ici, c'est
`scripts/check-spec-deltas.py`, qui échoue si une exigence du présent accumulé
n'a plus de delta derrière elle. Les 20 MIC peuvent être réécrits demain sans
casser la vérification, précisément parce qu'ils n'ont aucune exigence.
