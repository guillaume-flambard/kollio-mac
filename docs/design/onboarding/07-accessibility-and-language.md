# 14 — Clavier, accessibilité, français et adaptation tactile

## Une interface visuelle n’est pas seulement un ensemble de pixels

Chaque objet doit avoir un rôle, un titre et des actions compréhensibles par les moyens d’accès utilisés. Une annonce comme « Export CSV, direction écartée, rouvrir disponible » apporte davantage qu’un simple « carte ». Le lecteur du document doit pouvoir suivre le sens sans parcourir un à un tous les pixels du canvas.

La navigation clavier doit distinguer le déplacement du focus de celui d’une instance. Une flèche destinée à lire la prochaine idée ne doit pas modifier sa position. Le focus revient au point d’origine après la fermeture d’un détail. Quand la cible disparaît, il rejoint un parent logique ou une commande document stable, pas le premier bouton arbitraire de la fenêtre.

## Modalités séparées dans la recette

Tester au clavier seul ; puis au pointeur par clics sans drag ; puis au trackpad ; puis avec VoiceOver et réglages de mouvement/contraste. Réussir un de ces tests ne remplace pas les autres. Une personne utilisant un dispositif de pointage adapté n’utilise pas nécessairement des raccourcis clavier.

Les petites surfaces de contrôle restent à taille écran quand le document est dézoomé. Le hit testing doit correspondre à leur position visible. Une aide peut être atteinte avec une grande taille de pointeur sans recouvrir sa propre cible. Le contenu focalisé reste visible lors de l’ouverture d’un clavier logiciel ou d’une surface temporaire. [R25](#source-r25) · [R26](#source-r26) · [R31](#source-r31)

## Réduire les animations sans supprimer l’information

Le réglage retire les translations décoratives, les zooms automatiques et les rebonds inutiles. Il ne supprime pas la sélection, la différence avant/après ou l’état d’une proposition. Le déplacement direct au pointeur reste un changement de position nécessaire à la tâche ; il ne se transforme pas en attente figée.

Une animation remplacée par une mise à jour immédiate doit aboutir au même état et au même focus. Les tests de données ne dépendent pas de la durée. En contraste renforcé, les frontières et labels fonctionnels gagnent en présence. Le fantôme reste provisoire par son style et son texte, pas par une opacité rendant le contenu illisible. [R27](#source-r27) · [R32](#source-r32)

## Français et anglais : le comportement aussi doit être localisé

Les textes de commande existent dans les String Catalogs. Les clés restent techniques en anglais ; les textes authored restent dans leur langue. Un placeholder anglais dans une interface française de démonstration n’est pas « du contenu utilisateur » s’il a été généré par l’application elle-même.

Tester les longues phrases françaises, les apostrophes, les pluriels et le nom complet d’un document. Les contrôles ne se contentent pas de trois points partout. Une action destructrice tronquée n’est pas acceptable parce que l’anglais tient dans sa largeur fixe. Les labels d’accessibilité et les erreurs suivent la même langue d’interface.

Enter, Cmd+Enter et Échap sont testés pendant la composition d’une saisie. La modification d’un contexte ne relance pas l’IA à chaque caractère. Le texte de la demande ne doit pas être lu par le moteur de coaching pour inférer la langue ou le profil quand la préférence explicite est déjà disponible.

## Adaptation iPad/iPhone : étudier, ne pas miniaturiser

Sur iPad, une surface proche du toucher doit éviter d’être masquée par la main. Une action par survol devient une action par sélection. L’annulation a une entrée visible sans supposer un clavier. Le Pencil peut enrichir plus tard la capture, mais aucune action fondamentale ne l’exige.

Sur iPhone, la lecture guidée d’une branche et le retour au point d’origine peuvent être plus utiles qu’une carte réduite à des centaines de minuscules objets. Cela reste une hypothèse de design pour l’extension future, pas un ordre de remplacer le canvas Mac. Les cibles tactiles se dimensionnent selon les règles de la plateforme concernée ; on ne transpose pas une densité macOS brute.

La validation principale porte sur le Mac actuel. Une page HTML responsive du livre ou du banc ne démontre aucune de ces interactions natives iPad/iOS. Ces limites figurent dans le rapport de livraison pour éviter qu’un agent considère une capture mobile du document comme un test de l’application.



---

<a id="ch-15"></a>
