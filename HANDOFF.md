# HANDOFF — Journal vivant du projet

> Ce fichier est le **journal de bord** de Drain the Ocean. On y consigne **tout** : chaque décision, chaque modification, chaque test qui échoue, chaque question ouverte.
> Le [`docs/PRD.md`](docs/PRD.md) décrit l'état *actuel* du jeu ; ce fichier raconte *comment et pourquoi* on en est arrivé là.

## Règles d'écriture

1. **On ajoute, on n'efface jamais.** Une décision annulée reçoit une nouvelle entrée qui la remplace (et cite l'ancienne).
2. **Plus récent en haut** du journal.
3. **Une entrée par événement**, au format ci-dessous.
4. Toute session (humaine ou IA) qui modifie le projet met ce fichier à jour **dans le même commit** que la modification.
5. Un test qui échoue est consigné **même s'il est corrigé juste après** (avec la cause et la correction).

### Types d'entrées

| Type | Quand l'utiliser |
|---|---|
| `DÉCISION` | Un choix validé par Othmane (gameplay, technique, organisation) |
| `MODIF` | Un changement dans le code, les données, les assets ou la documentation |
| `TEST ÉCHOUÉ` | Un test automatique ou manuel qui ne passe pas (cause, correction ou piste) |
| `QUESTION` | Une question ouverte qui attend une décision |
| `NOTE` | Une information utile pour la suite (piste, découverte, limite connue) |

### Format d'une entrée

```
### AAAA-MM-JJ — TYPE — Titre court
- **Quoi :** …
- **Pourquoi :** …
- **Impact :** fichiers / sections du PRD concernés
- **Par :** qui (Othmane, Claude, …)
```

---

## État actuel (résumé à tenir à jour)

- **Phase :** PR #2 à #5 fusionnées (M0, M2, retours de test, survie légère). Correctifs et début de T2 en PR #6, fusionnée directement à la demande d'Othmane. Déplacement des objets sur une grille (rotation, palette déplaçable, cases libres pour tout ce qui apparaît) en PR #7, fusionnée à la demande d'Othmane. PR #8 : vérification des cases avant toute apparition, mode déplacement automatique à l'ouverture d'une caisse, CI plus stricte. PR #9 : pompe à bras et tuyaux. PR #10 : moulin-pompe et fin de la démo. PR #11 : barre d'outils. PR #12 : tuyaux posés à la main, débit des pompes, une caisse par objet. PR #13 : un tas par matériau, matériaux dans la barre, menu pour la ranger. Puis les releases qui finissent la démo (PRD §19.5) : PR #14 monde vivant, PR #15 téléphone, PR #16 toboggan et flamant, PR #17 jalons, PR #18 menus et options, PR #19 anti-blocage, PR #20 vraie fin et Nouvelle partie, PR #21 sons et perf. Toute la liste du PRD §19.1 est construite. PR #22 : `Settings` devient une classe statique. **Version 0.1.0** gardée sur la branche `version/0.1.0`. PR #23 : version 0.1.1, le terrain low poly cartoon (PRD §19.6). PR #24 : version 0.1.2, palmiers et rochers CC0, cabine téléphonique, dialogues, catalogue illustré, interface « catalogue » (PRD §19.7). PR #25 : version 0.1.3, île 50 % plus grande avec crique et îlot, HUD allégé (PRD §19.8). PR #26 : version 0.1.4, tous les modèles, 64 par case, pompes dans l'eau (PRD §19.9).
- **Documents :** PRD v0.38. Guide du code : `docs/GUIDE_CODE.md`. Décisions du MVP en PRD §19.2 et §19.3.
- **Ce qui marche :** la boucle complète *puiser → verser dans la cuvette → attendre le séchage → récolter → porter à la palette → commander au téléphone → avion → caisse en parachute → ouvrir → objet posé*. Premier achat vers 1 min 30. Nage avec endurance, noyade et retour sur la plage. Catalogue : bâche, grand seau, brouette, tongs, râteau, palanche, bateau en bouteille. Jauge à aiguille du niveau d'eau. Cycle jour/nuit de 20 min avec lune. Tas de sel (un par matériau) à côté des zones. Paiement avec les bras + la palette. Outils admin dans `game/admin/`. Faim et soif, noix de coco, rations, bâche de condensation, coquillages chaque matin. Palette à un tas par ressource. Manuel du bricoleur → T2 : bassin en bois, miroir solaire. Sauvegarde de toute la partie. Déplacer et tourner les objets posés, palette comprise (G, R, grille de 1 m, vert/rouge). Pompe à bras (clic maintenu, 20 L/s) et tuyaux posés à la main pièce par pièce, au sol ou en hauteur, avec le débit affiché au-dessus des pompes. Moulin-pompe (10 L/s tout seul) et écran de fin de démo. Barre de 5 cases où vont les outils et les matériaux portés (un par case), menu Tab pour la ranger. Un tas par matériau à côté des zones. Une caisse par objet à poser. Océan à vagues avec filtre sous l'eau, fond marin, nuages, animaux. Téléphone (tutoriel, offres du jour, paiement arraché au crochet). Toboggan à sacs, flamant payé en perle. 3 jalons comparatifs. Menu principal à 3 emplacements (Continuer, Nouvelle partie, Effacer), menu pause, options. Anti-blocage. Vraie fin (F4), traits sur le palmier. Sons de base. Île générée low poly (plage, dunes en terrasses, rivage irrégulier), eau et ciel cartoon. Palmiers, rochers et buissons CC0, cabine téléphonique avec dialogues (Ginette), Grand Catalogue illustré, interface papier crème et polices cartoon. Île 50 % plus grande (crique, îlot), faim et soif en jauges animées, panneau « Mon île » au menu pause. Tous les objets ont leur modèle (tas qui ressemblent à leur contenu, coquillages, caisse et parachute, biplan, pompes sur pilotis, moulin, seaux qui se remplissent, personnage animé), 64 par case, pompes dans l'eau. Grille de placement en rectangles de cases qui collent aux modèles (0.1.5). Tuyaux solides qui versent au milieu des zones, portée de pose (0.1.6). Aperçu du mode G sans clignotement (0.1.7). 310 tests + scénarios physiques et de perf.
- **À valider par Othmane :** la règle de séchage et le rendement de 4 L par sel (PRD §6.3), les détails de la nage (§10), la jauge logarithmique (§8.2), le prix de la brouette (30 sel), les détails du placement sur grille (§10 : cases de 1 m, emprises, quart de tour avec R).
- **Prochaine étape :** Othmane valide la 0.1.7 (plus de clignotement en mode G), la 0.1.6 (tuyaux solides qui versent au milieu, portée de pose de 6 m, tas qui ne s'étirent plus, tuyaux en main affichés), la 0.1.5 (grille de placement : emprises en cases qui collent aux modèles) et la 0.1.4 (modèles, 64 par case, pompes dans l'eau, brouette à 128 par case). Puis le test de 30-45 min par un testeur extérieur (PRD §19.1) et la mesure de perf sur le PC de référence. Plus tard : banques de sons CC0 (M-76), assets low-poly (M-06/M-07).
- **Questions ouvertes :** seulement celles de long terme (PRD §18) ; aucune ne bloque.

---

## Architecture et logique (à tenir à jour)

> Cette section décrit **comment le jeu est construit et comment il raisonne**, sans détail de code. Elle est mise à jour à chaque étape qui change l'architecture ou une règle.

### Les quatre couches

1. **Les données** (`game/data/`) : tous les chiffres d'équilibrage (volume de l'océan, capacités, temps de séchage, probabilités, prix) et le catalogue de l'agence. On règle le jeu en modifiant ces fichiers, jamais le code.
2. **La logique pure** (`game/core/`) : de petits objets qui ne savent rien de la 3D ni de l'écran. Chacun gère une seule règle : l'océan, le seau, une zone de séchage, le cycle jour/nuit, le calcul des ressources. On peut les tester seuls, sans lancer de scène.
3. **L'état de la partie** (`GameState`, chargé en permanence) : la **source unique de vérité**. Il possède l'océan, le seau, le stock, ce que le joueur porte, les zones de séchage, les caisses, les décors, les objets achetés, l'heure et le temps de jeu. Toute action du jeu passe par lui. Quand quelque chose change, il l'annonce (« le stock a changé », « une caisse est arrivée »…).
4. **Les vues** (`game/scenes/`) : la 3D et l'interface. Elles **affichent** l'état et **demandent** des actions à GameState, mais ne décident jamais d'une règle. Par exemple, la cuvette 3D ne calcule pas l'évaporation : elle lit le niveau d'eau de sa zone et ajuste la hauteur de son eau.

Pourquoi : la logique est testable automatiquement ; la sauvegarde n'a qu'un seul endroit à lire ; on pourra remplacer les formes grises par de vrais modèles sans toucher aux règles ; et le futur mini-jeu clicker pourra réutiliser la même logique.

### La boucle de base (M2)

- **Puiser :** le joueur, debout dans l'eau, maintient le clic environ 1 s ; le seau se remplit (10 L, ou 20 L avec le grand seau). Ces litres sont **retirés de l'océan** à ce moment. Chaque seau a une petite chance de remonter un coquillage, et un coquillage une petite chance d'être une perle.
- **Verser :** visée sur une zone de séchage + clic. La zone n'accepte que la place libre ; le reste reste dans le seau. Vider le seau ailleurs (sable, mer) **rend l'eau à l'océan** (M-33, M-34).
- **Sécher :** chaque zone évapore à débit fixe (`capacité ÷ 45 s` de jour, ×0,3 la nuit). Tous les 4 L évaporés (réglage `liters_per_salt`), elle ajoute 1 sel à son dépôt, plus un tirage de minéral et de minéral rare. Le séchage continue partout, même loin du joueur (M-42).
- **La palette** a un emplacement par ressource : chaque tas a sa couleur, sa hauteur (qui grandit vite au début puis ralentit) et son compteur.
- **Récolter et porter :** le dépôt d'une zone s'affiche comme un **tas à côté d'elle**, qui grossit avec la quantité. E sur le tas : 3 unités passent dans les mains (les plus rares d'abord), ou tout le tas avec le râteau. Le clic sur la zone ne sert qu'à verser. Chaque case de la barre porte jusqu'à 64 unités de son matériau (128 avec la brouette), sans limite totale (0.1.4). Ce qui ne rentre pas reste dans la zone.
- **Déposer :** E sur la palette de dépôt : tout ce qui est porté passe dans le **stock**. Seul le stock de la palette sert à payer (troc).
- **Commander :** E sur le téléphone : le catalogue s'ouvre (le jeu ignore alors les touches du joueur). On remplit un panier (articles identiques regroupés « ×N ») ; « Commander » vérifie qu'on peut payer avec les bras + la palette, retire le prix des bras d'abord puis de la palette, marque les objets uniques comme possédés et crée **une caisse par objet à poser** (plus une caisse commune pour les améliorations).
- **Livrer :** un avion traverse le ciel, passe au-dessus de la palette, largue la caisse qui descend en parachute (5 s au total). Les caisses successives tombent en spirale autour du point de livraison pour ne pas s'empiler ; les avions d'une même commande passent l'un après l'autre, et une caisse qui tombe sur un objet reste posée dessus.
- **Ouvrir :** E sur la caisse posée : chaque objet est appliqué (nouvelle zone de séchage posée à côté, seau agrandi, décor posé), puis la caisse disparaît.

### Les améliorations

- Les objets « outils » ne créent rien dans le monde : ils changent des **caractéristiques** tenues par GameState et sauvegardées avec la partie : contenance d'un seau (grand seau), nombre de seaux (palanche, ×2), capacité de transport (brouette), vitesse de marche (tongs, +20 %), râteau (récolte complète).
- La contenance du seau se calcule toujours : contenance d'un seau × nombre de seaux. Grand seau + palanche = 2 × 20 L = 40 L.
- Un objet « unique » est marqué possédé dès la commande (on ne peut pas le recommander pendant que sa caisse tombe), mais son effet ne s'applique qu'à l'ouverture de la caisse.

### Le niveau de l'eau (M1)

- Une seule variable de vérité : le volume retiré. La hauteur de la surface s'en déduit : volume retiré ÷ surface du bassin (2,8 × 10¹³ m²). Pour l'instant le bassin a des bords droits ; plus tard, une table hauteur = f(volume) tirée de la forme du fond.
- Le plan d'eau 3D est placé à cette hauteur à chaque image, et tout ce qui dépend de l'eau (puiser, nager) utilise cette même hauteur.
- La jauge à aiguille sur la plage affiche la vraie baisse en millimètres, et son aiguille suit une échelle logarithmique (chaque graduation = ×10) pour bouger dès le premier seau.

### Le corps : nage et endurance

- L'endurance est une valeur de 0 à 1, gérée par un petit objet de logique pure. Courir la vide en 10 s, nager en 30 s. Elle ne remonte qu'à l'arrêt sur la terre ferme ; marcher ne la change pas ; dans l'eau, elle ne remonte jamais. Vidée en courant, on ne peut plus courir avant d'être remonté à 25 %.
- On nage quand les pieds sont à plus de 1,2 m sous la surface : la gravité est remplacée par une flottaison qui ramène la tête hors de l'eau. Espace fait monter. Avancer contre un bord (le rivage) fait se hisser jusqu'à reprendre pied.
- Endurance à zéro dans l'eau : noyade. Fondu au noir, retour au point de départ sur la plage, endurance pleine, rien n'est perdu (N-04).
- La jauge d'endurance apparaît en bas de l'écran seulement quand elle n'est pas pleine ; elle devient rouge sous 25 % ou quand on est essoufflé.

### Le temps

- Une journée dure 20 min réelles, de 6 h à 20 h de jour ; la partie commence à 7 h. Le soleil tourne et la lumière baisse la nuit. L'évaporation de nuit est à 30 %.
- Le temps de partie compte tout le temps de jeu, et il est sauvegardé.

### La sauvegarde

- Toute la partie est décrite par GameState sous forme d'un dictionnaire (océan, seau, stock, mains, zones avec leur eau et leur dépôt, caisses non ouvertes, décors, objets possédés, heure, jour, temps de partie), écrit en JSON.
- Sauvegarde automatique toutes les 2 min et en quittant. Au chargement, l'ancienne scène est vidée, puis chaque zone, caisse et décor est recréé par sa vue, sans réanimer l'avion.
- En attendant le menu principal, le jeu reprend automatiquement l'emplacement 1 (ou commence une partie neuve s'il est vide).

### Le joueur et les interactions

- Un rayon part du centre de la caméra (portée 3 m, allongée en 3e personne). L'objet visé affiche une invite au centre de l'écran.
- Le clic gauche utilise l'**outil** (le seau), avec un ordre de priorité : agir sur l'objet visé (verser, récolter) ; sinon puiser si on est dans l'eau ; sinon vider le seau. La touche E sert aux **interactions** (téléphone, palette, caisse).

### Sauvegarde manuelle et outils admin

- **F5** sauvegarde (vraie fonction du jeu, M-78).
- Les outils de triche vivent **tous** dans un module à part, `game/admin/`, chargé au démarrage. Pour les retirer : supprimer ce dossier et sa ligne dans la liste des modules chargés au démarrage (`project.godot`). Rien d'autre n'en dépend. Ils se coupent seuls dans une version exportée « release ».
- Touches : **F1** affiche la liste, **F6** +3 h, **F7** maintenu vide l'océan, **F8** maintenu temps ×10, **F9** nouvelle partie, **F10** +50 sel +5 minéraux, **F11** +10 000 de chaque ressource, **F12** ouvre toutes les caisses tout de suite.

### Les paliers

- Le catalogue montre tous les articles. Ceux d'un palier pas encore débloqué sont grisés (« Requiert le Manuel du bricoleur ») et ne peuvent pas être commandés.
- Le Manuel du bricoleur débloque T2. Premiers articles T2 : le bassin en bois (grande zone de 200 L) et le miroir solaire, qui accélère de 50 % l'évaporation des zones à moins de 6 m (les miroirs s'additionnent).

### Déplacer les objets (grille)

- L'île est découpée en **cases de 1 m**. Chaque objet posé a une **emprise** : depuis 0.1.5, un **rectangle de cases entières** qui colle à son modèle (cuvette 4 × 3 avec ses tas, miroir 2 × 1, toboggan 1 × 3…), réglé dans les données et vérifié par un test contre le modèle. Il tourne avec l'objet. Ses bords tombent sur les lignes de la grille.
- On ne pose un objet qu'à portée : son bord à moins de 6 m du joueur (0.1.6).
- Le joueur, les palmiers, les rochers, les noix de coco et les tuyaux restent de petits cercles. Deux emprises qui se touchent par un bord ne se chevauchent pas.
- Une place est valide si l'emprise reste sur le sable sec (moins de 19,5 m du centre de l'île) et ne touche ni un autre objet posé, ni un élément fixe (téléphone, palette, palmiers, rochers, repère d'eau, listés dans les données).
- En jeu : viser un objet + **G**. L'objet lui-même sert d'aperçu et suit le regard case par case ; les cases qu'il occupera sont vertes ou rouges, la grille s'affiche autour, les emprises voisines en bleu et ce qui gêne en rouge. Cet aperçu épouse le relief, un peu au-dessus du sable, et l'objet ne tremble pas au ras d'une ligne (0.1.7). Clic = poser (GameState vérifie encore et annonce « objet déplacé ») ; G ou Échap = annuler. Pendant ce mode, le seau et E sont coupés.
- **R** tourne l'objet d'un quart de tour pendant le déplacement. L'orientation est dans l'état de l'objet, comme sa position.
- La **palette** se déplace comme le reste ; le téléphone reste fixe.
- Tout ce qui apparaît tout seul prend une case libre : une caisse livrée ou un objet qui en sort va sur la case libre la plus proche de l'endroit prévu ; un coquillage tombe au centre d'une case libre de la plage ; le tas de sel d'une zone a sa propre case, à l'intérieur de l'emprise de la zone (il tourne avec elle). Les noix de coco au pied des palmiers bloquent aussi leur place.
- Avant d'apparaître, tout regarde ce qui est déjà là : objets posés, caisses (même encore en vol), coquillages, places des noix de coco, éléments fixes, et le joueur. S'il n'y a plus de place, rien n'apparaît. Une noix de coco ne repousse pas sous un objet.
- Ouvrir une caisse qui contient des objets à poser enchaîne le mode déplacement pour chacun, l'un après l'autre.
- La position et l'orientation sont sauvegardées, et les miroirs déplacés boostent les zones de leur nouvel emplacement.

### Pompes et tuyaux (T2)

- Les pompes se posent dans l'eau, près du rivage (0.1.4) : la plateforme reste au-dessus de l'eau, sur des pilotis plantés dans le fond. Les tuyaux peuvent aller au-dessus de l'eau jusqu'à elles, mais pas à travers une dune.
- La pompe à bras, clic maintenu : elle aspire 20 L/s dans l'océan, mais seulement ce que les zones reliées peuvent recevoir (jamais un litre perdu).
- Les tuyaux se posent à la main, une pièce par case de 1 m, au sol ou en hauteur (niveaux 0 à 4). L'eau part de la pompe, suit les pièces qui se touchent et se verse dans une zone seulement depuis une pièce **un bloc au-dessus du milieu du bac** (0.1.6 ; avant : sous ou au bord d'une pièce), les plus proches (en longueur de tuyau) d'abord. Les tuyaux sont solides (0.1.6) : on s'y cogne, on monte dessus ; ils ne se posent ni dans une zone, ni dans le joueur.
- Rien n'est mémorisé sur les liaisons : le chemin de l'eau est recalculé à chaque pompage à partir des pièces posées. Déplacer un objet ne peut donc jamais laisser un réseau faux.
- Chaque pompe affiche son débit réel (0 si rien n'est relié ou si tout est plein).
- Le moulin-pompe est une pompe « automatique » : la même étape qui fait vivre le monde le fait pomper (10 L/s), sans le joueur. On compte ce qu'il a pompé ; à 200 L, c'est la fin de la démo (une seule fois, mémorisée dans la sauvegarde).

### La barre d'outils

- 5 cases. Une case contient un outil possédé, un matériau porté (avec sa quantité) ou rien (les mains nues). Au départ : le seau et 4 cases vides. Un outil obtenu ou un matériau ramassé prend la première case vide ; sans case libre, on ne ramasse pas ce matériau. Une case se libère quand on n'a plus ce matériau. Le menu (Tab) échange deux cases ; ce qu'on tient reste en main. Le seau ne puise et ne verse qu'en main ; le râteau ramasse tout un tas d'un coup s'il est en main. La disposition est sauvegardée.
- Chaque zone de séchage a un tas par matériau, côte à côte, chacun sur sa case dans l'emprise de la zone.

### Le temps qui passe

- Une seule étape fait vivre le monde : l'heure (et le matin), le séchage, les objets à portions, la faim et la soif. L'avance rapide de l'admin (F6) passe par la même étape, découpée en pas de 5 s.

### La survie légère et la plage

- **Faim et soif** baissent doucement (vides en 15 et 10 min). À zéro, pas de mort : une pénalité grandit et abaisse le plafond de l'endurance (jusqu'à −30 % par besoin). Manger ou boire l'efface aussitôt.
- **Ramassables** (E) : les noix de coco sous les palmiers se mangent sur place ; les coquillages de la plage vont dans les bras. Chaque matin, une noix revient sur chaque emplacement vide, et la plage est complétée jusqu'à 5 coquillages.
- **Objets à portions** livrés par l'agence : la bâche de condensation produit une gorgée d'eau douce toutes les 90 s (3 au plus) ; la caisse de rations contient 5 repas et disparaît vide.

### Le ciel

- Le soleil suit une courbe selon l'heure et s'éteint sous l'horizon. La lune suit le chemin inverse : une lumière bleutée très faible, plus un disque blanc dessiné loin dans le ciel.
- Le plan d'eau suit le joueur à l'horizontale (on n'en voit jamais le bord), et le bas du ciel a la couleur de la mer, pour éviter une bande claire à l'horizon.

### Tests

- Chaque règle de la logique pure a ses tests (océan, séchage, seau, économie, jour/nuit, endurance, jauge). Un test « boucle complète » joue toute la partie de M2 sans écran, sur un petit océan et sans hasard : puiser, verser, sécher, récolter, déposer, commander, ouvrir, puis sauvegarder et recharger.

### La cabine, les dialogues et le catalogue (0.1.2)

Le téléphone est une cabine. Parler à la cabine ouvre une conversation (des répliques écrites dans un fichier de données, avec des choix de réponse) ; une réponse peut déclencher une action, comme ouvrir le catalogue. C'est le seul chemin vers le catalogue. Le catalogue papier n'est plus un objet posé : sa livraison est un simple drapeau de la partie, et la cabine l'affiche sur sa tablette. Toute l'interface prend ses couleurs et ses polices à un seul endroit (le thème « catalogue ») ; les modèles téléchargés sont retouchés au chargement par un seul module, pour qu'on puisse en changer sans toucher au reste.

---

## Journal

### 2026-11-17 — MODIF — Version 0.1.7 : plus de clignotement en mode G
- **Causes trouvées :** (1) la dalle des cases, les voiles et la grille étaient plats, à 2-5 cm au-dessus de la hauteur de l'objet, alors que le sable a un léger relief : ils se battaient avec le sol (z-fighting) ; (2) trois couches transparentes dans trois nœuds, triées par distance, qui s'inversaient quand la caméra bougeait ; (3) le rayon de visée n'ignorait que le corps principal de l'objet, pas ses tas (des corps à part) : il les touchait, l'objet sautait puis revenait ; (4) au ras d'une ligne, le balancement de la tête faisait changer de case à chaque image.
- **Corrections (`PlacementController`) :** un seul maillage d'aperçu qui suit le relief (`draped_y`, carreaux de 25 cm, de 6 à 9 cm au-dessus du sol, de l'eau ou de la plateforme d'une pompe), quatre matériaux à `render_priority` fixe sans écriture de profondeur ; `bodies_of(vue)` exclut tous les corps de l'objet du rayon ; `keep_target` (hystérésis de 15 cm).
- **Tests :** `test_placement_overlay.gd` (aperçu au-dessus du sol partout sur l'île, couches ordonnées, rayon qui ignore tous les corps, pas de tremblement sur une ligne). 310 tests.
- **Captures :** `captures/v017/`.
- **Par :** Claude

### 2026-11-17 — TEST ÉCHOUÉ — Type non inféré
- `test_placement_overlay.gd` ne compilait pas (`var px :=` sur un tableau non typé). **Correction :** type explicite.
- **Par :** Claude

### 2026-11-17 — DÉCISION — Corriger le clignotement en mode G
- Othmane trouve la 0.1.6 « pretty good » ; en mode G, les graphismes clignotent : à corriger, et s'assurer que ça ne revient pas.
- **Par :** Othmane

### 2026-11-17 — MODIF — Version 0.1.6 : tuyaux solides qui versent au milieu, portée de pose
- **Tuyaux en main :** la case « Tuyaux » de la barre affiche « N en main » (`HUD_PIPES_IN_HAND`), mise à jour à chaque `network_changed`.
- **Ombres :** les bras et les descentes des tuyaux projettent de nouveau leur ombre (elle était coupée).
- **Verser :** `PipeNetwork.feeds(case, arrivée, niveau)` ; `GameState.inlet_rect(zone)` (config `inlet_cells`, tourné avec la zone) et `pipe_feeds(case, zone)` ; `pour_level` = 1. `inlet_radius` est retiré. Les zones bloquent les tuyaux au sol, et les tuyaux au sol bloquent les zones.
- **Portée de pose :** `config.place_reach_m` (6 m), `GameState.in_place_reach` ; le mode G passe au rouge et affiche `PROMPT_PLACE_TOO_FAR`.
- **Tas :** `Depot.pile_scale` ne dépasse plus `PILE_MAX_STRETCH` (1,15) en hauteur ; le compteur suit la vraie hauteur du tas.
- **Tuyaux solides :** les pièces ne sont plus `WALK_THROUGH` ; collision sur le raccord et sur chaque bras. `can_place_pipe` refuse une pièce dans le joueur (niveaux 0 et 1).
- **Anti-blocage :** `UnstuckLogic.ESCAPE_M` passe de 0,8 à 1,5 m ; `player.find_free_spot` saute une place libre mais fermée (`_trapped_at`).
- **Tests :** `test_reach.gd`, un test de tas non étirés (`test_depot.gd`), un test « un bloc au-dessus du milieu » ; `test_pumps.gd` et `test_windmill.gd` (tuyaux qui montent d'un bloc et arrivent au milieu), scénario `softlock.gd` (sortir d'un enclos de tuyaux). 307 tests.
- **Captures :** `captures/v016/`.
- **Par :** Claude

### 2026-11-17 — TEST ÉCHOUÉ — Tuyaux solides et nouvelle règle de versement
- `test_pumps` / `test_windmill` (40 échecs) : les tuyaux d'essai allaient au sol dans la cuvette, ce qui est maintenant interdit et ne verse plus. **Correction :** les chemins montent d'un bloc devant le bac et arrivent au-dessus de son milieu.
- Scénario `softlock.gd` : « on traverse les tuyaux » échouait (0 m), normal puisqu'ils sont solides. Remplacé par « sortir d'un enclos de tuyaux ». Il échouait encore : un enclos d'une case laisse 1,6 m de jeu, assez pour passer la sonde de 0,8 m (puis de 1,2 m en diagonale), et la place de secours la plus proche était dans l'enclos. **Correction :** sonde de 1,5 m, et une place de secours doit elle-même ne pas être fermée.
- **Par :** Claude

### 2026-11-17 — DÉCISION — Tuyaux, portée de pose, tas
- Othmane : afficher le nombre de tuyaux en main ; les ombres des tuyaux reliés manquent ; un tuyau ne verse dans une zone que vers son centre et à un seul bloc au-dessus ; limiter la distance de pose des objets ; les tas se déforment au-delà d'une certaine quantité ; les tuyaux doivent avoir une collision (« c'est plus fun »).
- Cela remplace « les tuyaux se traversent » de l'anti-blocage (2026-11-16).
- **Par :** Othmane

### 2026-11-17 — MODIF — Version 0.1.5 : la grille de placement colle aux modèles
- **Emprises :** `config.footprints` donne pour chaque type un rectangle `[x0, z0, x1, z1]` en mètres (repère de l'objet), fait de cases entières, au lieu d'un rayon. Cuvette et bâche 4 × 3, bassin 6 × 3, condenseur 2 × 2, miroir 2 × 1, toboggan 1 × 3, palette 4 × 2, pompe à bras 1 × 2, moulin 3 × 3, le reste 1 × 1.
- **`PlacementGrid` :** formes « rectangle » ou « cercle », `rect_at` (rectangle tourné d'un quart de tour), `snap_rect` (bords sur les lignes de la grille), `overlaps` (se toucher n'est pas chevaucher), `conflicts`, `fits`, `distance_to`, `cells_of`.
- **`GameState` :** `footprint_of(type)` renvoie un `Rect2` ; `footprint_rect`, `item_rect`, `snap_item`, `placement_conflicts`. `spot_ok`, `can_place`, `move_item` et `find_free_spot(type, près, rotation)` tiennent compte de la rotation. Les cercles restent pour le joueur, les palmiers, les rochers, les noix et les tuyaux. La palette part de (9 ; 9) pour être alignée.
- **Tuyaux :** `PipeNetwork.pump_ports` prend les cases de l'emprise de la pompe (`GameState.pump_cells`) : un tuyau se branche sur toute case qui la borde. `PipesView` met la bride sur toute la pompe (`pump_at_cell`).
- **Toboggan :** `zones_for_slide` compte la portée depuis le bord de la zone.
- **Aperçu (G) :** la dalle verte/rouge prend la taille des cases occupées, la grille couvre l'emprise plus 3 cases, les emprises voisines sont en bleu et celles qui gênent en rouge (`PlacementController.show_footprint`). Le point visé est le milieu de l'objet.
- **Modèles :** `Props.stilts` (pilotis) remplace la fonction de la vue de pompe ; les pilotis de la pompe à bras sont un peu plus serrés (0,35 m).
- **Tests :** `test_footprints.gd` (chaque emprise couvre son modèle sans case de trop, case contre case, rotation, alignement, 40 cuvettes sur l'île, tuyaux à côté des objets, moulin branché de tous les côtés, portée du toboggan, sauvegarde). Tests existants passés aux rectangles. 303 tests.
- **Captures :** `captures/v015/`.
- **Par :** Claude

### 2026-11-17 — TEST ÉCHOUÉ — Tests à mettre aux rectangles
- `test_windmill` et `test_pumps` : le tuyau en (-1, 0, 15) tombait dans le moulin, qui fait maintenant 3 × 3 cases. **Correction :** le moulin des tests est posé une case plus loin (z = 17,5), et le tuyau se branche au bord de son emprise.
- `test_placement` : la cuvette posée en (8 ; 4) ne touchait plus la palette (les cercles étaient plus gros que les objets). **Correction :** le test vise (9 ; 7).
- `test_footprints` (nouveau) : deux emplacements choisis tombaient sur le palmier fixe de (5 ; 1,5) et le toboggan était réaligné hors de portée. **Correction :** le test se place plus loin, sur des cases alignées.
- **Par :** Claude

### 2026-11-17 — NOTE — Vieilles sauvegardes et grille
- Un objet de largeur paire (miroir, condenseur, palette) sauvegardé avant 0.1.5 est au milieu d'une case, donc décalé d'une demi-case par rapport à la grille. Il reste valide (les chevauchements se calculent au centimètre) et se réaligne dès qu'on le déplace.
- **Par :** Claude

### 2026-11-17 — DÉCISION — Travailler la grille de placement
- Othmane : « beaucoup d'objets prennent bien plus de place qu'ils ne devraient, et bien plus que ce qu'on voit, ce qui rend le placement pénible ».
- **Par :** Othmane

### 2026-11-17 — MODIF — Version 0.1.4 : tous les modèles, 64 par case, pompes dans l'eau
- **Modèles :** nouvelle classe `Props` (`scenes/world/props.gd`). Elle fabrique les tas (`pile`, un par ressource), les coquillages (Saint-Jacques, conque), les perles et les étoiles de mer, la caisse au tampon « AGENCE », le parachute rouge et crème, la palette, les sacs, le biplan, les trois zones de séchage, la pompe à bras, le moulin à huit pales, le toboggan, le miroir, les seaux (zinc rafistolé ou jaune, eau qui monte), le râteau, la palanche, le condenseur, les rations, les gouttes, et les personnages animés.
- **CC0 ajoutés :** `crystal`, `gem_pink`, `crystal_rock`, `crab`, `fish`, `flower_red`, `mini_male_a`, `mini_male_d` (voir `assets/CREDITS.md`).
- **Vues branchées :** palette, tas des zones, ramassables (coquillages, noix), caisses, avion (pilote animé, hélice, sacs au crochet), zones, pompes, moulin, toboggan, miroir, jauge, stations, décor, faune, fonds marins (rochers CC0, algues, coraux, étoiles, coquillages), fleurs et coquillages de décor (`dune_flowers`, `beach_shells`), marcheur de la fin. `ProductModels` réutilise `Props` pour les photos du catalogue.
- **Joueur :** corps animé en 3e personne (`mini_male_a` : idle, walk, sprint, jump, fall), eau des seaux qui suit le remplissage (et monte pendant qu'on puise), gouttes quand on marche.
- **Correctif (pause) :** l'aide « Clic pour jouer » se cache en pause ; elle et la barre d'endurance sont remontées au-dessus de la barre d'objets.
- **Portage :** `carry_capacity` devient la limite **par case** (64 ; brouette 128). `carry_space(clé)` donne la place pour un matériau ; `harvest` prend chaque matériau dans la limite de sa case.
- **Pompes dans l'eau :** `GameState.spot_ok`, `is_water_kind`, `is_water_spot` ; `find_free_spot(rayon, près, type)` cherche dans l'eau pour une pompe. Ajouts de config : `pump_min_depth_m` (0,25), `pump_max_offshore_m` (7). Les tuyaux vont au-dessus de l'eau jusqu'aux pompes, jamais dans une dune. La vue de pompe ajoute des pilotis jusqu'au fond.
- **Tuyaux :** bride au contact de la pompe, descente et bec au-dessus des zones, filet d'eau pendant le pompage (`pump.last_run_ms`), piquets sous les pièces au-dessus de l'eau.
- **`Models` :** les sommets d'un modèle animé se lisent avec ses os (`_skinned`). Le cache des matériaux tient compte de la texture. Les triangles fabriqués par code sont tournés dans le bon sens.
- **Tests :** `test_props.gd`, des tests de portage (64 par case) et de pompes dans l'eau ; `test_pumps.gd` et `test_windmill.gd` mis à jour. 287 tests.
- **Captures :** `captures/v014/`.

### 2026-11-17 — TEST ÉCHOUÉ — Faces sombres, taille des personnages, compilation des tests
- Les coquillages et les étoiles de mer étaient sombres. **Cause :** les triangles fabriqués par code étaient tournés à l'envers pour Godot (sens horaire = face avant), donc éclairés par l'arrière. **Correction :** ordre a, c, b dans `Props.tri_from` et `Models._tri`.
- Le personnage du joueur faisait moins d'un mètre et le crabe était énorme. **Cause :** la taille était lue sur le maillage brut d'un modèle animé. **Correction :** `Models._skinned` applique les os de la pose de repos.
- Le seau plein paraissait vide. **Cause :** le cylindre du seau avait un couvercle. **Correction :** seau ouvert et peint des deux côtés.
- Plusieurs fichiers de test ne compilaient pas : types non inférés (`var before :=`, `var left :=`, des tableaux non typés dans `Props`) et `assert_not_null`, qui n'existe pas. Tous corrigés.

### 2026-11-17 — NOTE — Recherche de modèles en ligne
- Accessibles depuis la session : le paquet npm `@netforge/asset-library-files` (copies CC0 de Kenney et Quaternius, origine dans son NOTICE). Bloqués : kenney.nl, poly.pizza, quaternius.com, jsdelivr, les archives GitHub.
- Rien de CC0 trouvé pour : coquillages, seaux, pompes, moulin, avion, caisse en bois, parachute, palette, toboggan. Ces objets sont donc fabriqués par code.
- La caisse et le baril du paquet sont de style science-fiction ; non retenus.

### 2026-11-16 — DÉCISION — 64 par case, pompes dans l'eau, tuyaux plus clairs, seaux remplis
- Othmane :
  - en pause, le texte passait sous la barre d'objets : à corriger ;
  - les seaux doivent se remplir, et le reste comme décrit dans le PRD ;
  - plus de limite de 40 portés : 64 par case sur les 5 cases ;
  - les tuyaux doivent se raccorder plus clairement et naturellement aux zones où ils versent ;
  - les pompes se posent dans l'eau (elles dépassent de l'eau mais reposent sur le fond).
- Cela tranche la QUESTION « Pompes loin de l'eau sur les côtés de l'île » (2026-11-16).

### 2026-11-16 — MODIF — Version 0.1.3 : île 50 % plus grande, HUD allégé
- **Terrain :** rivage moyen 38 m, zone constructible 24 m (`build_radius_m`), crique à +Z (`cove_depth` 8 m), îlot au large (`islets`), plateau sous-marin de 5 m, dunes de 3,2 m avec herbe en haut seulement. `TerrainView` couvre ±72 m.
- **Camp avancé de 4,5 m vers la plage :** cuvette, palette, centre des largages, réapparition, cabine ; jauge d'eau à z = 22 ; rochers à (19, 9) et (-20, 12) ; obstacles fixes mis à jour. Coquillages entre 21 et 23,7 m, crabe sur le même anneau, poissons et décor du fond repoussés, marcheur de la fin plus loin. Pompes à 20 m minimum du centre.
- **Décor :** `GameConfig.outer_palms` (9 palmiers hors zone constructible, dont 2 sur l'îlot), 85 buissons, 12 bois flottés.
- **HUD :** `NeedGauge` (faim : pilon et soupe orange ; soif : goutte et eau bleue ; vague animée ; bat en rouge sous 25 %) à gauche de la barre d'outils ; l'eau du seau dans sa case ; stock, bras, seau, faim en texte et heure retirés du HUD. Panneau « Mon île » dans le menu pause (`PauseMenu.island_report`).
- Tests : `test_hud_light.gd`, `test_terrain.gd` mis à jour (île plus grande, crique, îlot), positions de `test_pumps.gd` mises à jour. 279 tests. Captures : `captures/v013/`.

### 2026-11-16 — QUESTION — Pompes loin de l'eau sur les côtés de l'île
- Avec l'île plus grande, le bord de la zone constructible (24 m) est à ~6 m de l'eau dans la crique, mais à ~14 m sur les côtés. Une pompe posée sur les côtés est donc loin de l'eau. À décider : limiter les pompes à la crique, ou agrandir la zone constructible vers la mer.

### 2026-11-16 — DÉCISION — Île plus grande, HUD plus léger, passe sur tous les modèles
- Othmane aime la 0.1.2. Il demande : agrandir l'île d'environ 50 % et soigner le terrain ; faim et soif animées à côté de la barre d'objets ; les données inutiles seulement dans le menu ; puis une passe sur TOUS les modèles, en cherchant d'abord des modèles gratuits en ligne dans notre style (tas de sel et de minéraux qui ressemblent à ce qu'ils sont, vrais coquillages…). Continuer jusqu'au bout. Pas de réponse sur LFS : on garde git normal pour les petits assets.

### 2026-11-16 — MODIF — Version 0.1.2 : palmiers, cabine téléphonique, catalogue, dialogues, interface
- **Modèles CC0 :** palmiers, rochers, buissons et bois flotté du *Nature Kit* de Kenney (récupérés via le paquet npm `@netforge/asset-library-files`, décompressés pour Godot), dans `game/assets/models/cc0/`. `Models` les recolore en cartoon et les pose au sol ; couronne des palmiers doublée, noix de coco accrochées. `IslandProps` place palmiers et rochers (positions dans `GameConfig.palms` / `rocks`) et sème buissons et bois flotté sur les dunes et les plages. Les palmiers et rochers en CSG sont retirés de `main.tscn`.
- **Cabine téléphonique :** faite par code (aucune cabine gratuite accessible). Pleine (on n'entre pas dedans). « Driiing ! Driiing ! » saute au-dessus, la cabine tremble. Le catalogue papier ne se pose plus au sol : la caisse du premier appel l'envoie enchaîné dans la cabine (`GameState.catalogue_delivered`, effet `CATALOGUE`). Les vieilles sauvegardes sont migrées.
- **Dialogues :** `DialogueLogic` (pure) + `data/dialogues.json` + `DialogueBox` (sous-titres, réponses 1-4 ou clic, Échap raccroche). Ginette, de l'Agence. Le premier appel n'est décroché (caisse, musique d'attente) qu'à la fin de la conversation ; la sonnerie se tait pendant l'appel.
- **Catalogue :** refait en double page de catalogue drôle : photos 3D qui tournent (`ProductModels`, `ProductPhoto`), slogans (`ITEM_*_PITCH`), étiquettes de prix, tampons PROMO / BIENTÔT / DÉJÀ À VOUS, bon de commande.
- **Interface :** `UiTheme` (papier crème, encre, rouge, jaune ; polices Lilita One, Fredoka, Permanent Marker, dans `game/assets/fonts/`, crédits dans `game/assets/CREDITS.md`). Appliqué au HUD, menus, options, barre d'outils, jalons, fin de démo.
- Tests : `test_dialogue.gd`, `test_models.gd`, test du premier appel mis à jour. 274 tests. Captures : `captures/v012/`.
- Export : `data/*.json` ajouté au filtre d'inclusion (les dialogues sont lus comme fichier, pas comme ressource).

### 2026-11-16 — NOTE — Petits assets hors de Git LFS
- Le push des objets LFS est refusé depuis l'environnement de Claude (le serveur LFS de GitHub n'est pas joignable). Les polices et les modèles CC0 de la 0.1.2 sont tout petits (moins de 100 Ko chacun, environ 250 Ko en tout) : ils sont versionnés normalement grâce à une exception dans `.gitattributes` (`game/assets/fonts/*.ttf`, `game/assets/models/cc0/*.glb`). Les gros fichiers restent en LFS (M-12). **[PROPOSÉ]** : à valider par Othmane.

### 2026-11-16 — TEST ÉCHOUÉ — Palmier tourné au hasard, photo du miroir vue comme inconnue
- **Palmier :** le modèle penche en S (couronne presque au-dessus du pied), donc tourner selon la couronne donnait une direction au hasard. Correction : on tourne selon le « ventre » du tronc courbé.
- **Test des photos :** il comparait le nombre d'enfants au modèle « inconnu » (le miroir en a autant). Correction : le modèle inconnu porte une méta `unknown`.
- **Catalogue trop large :** les prix en plusieurs ressources (moulin-pompe) élargissaient toute la page. Correction : les étiquettes de prix passent à la ligne.

### 2026-11-16 — DÉCISION — Cabine, catalogue, dialogues, interface (0.1.2)
- Othmane valide le terrain et demande : palmiers, noix de coco, cabine téléphonique et interface. Le catalogue ne s'ouvre que face à la cabine, ce n'est plus un objet posé au sol, et il devient un vrai catalogue drôle avec images et prix. Toute l'interface prend sa direction artistique (polices, couleurs). Un système de dialogue avec sous-titres quand on parle à la cabine. Garder le « riiing » au-dessus de la cabine. PRD §9 et §19.7.

### 2026-11-16 — MODIF — Version 0.1.1 : le terrain low poly, l'eau, le ciel et le soleil
- **Terrain :** nouvelle logique `TerrainLogic` (hauteur et couleur en tout point, déterministe) et vue `TerrainView` (maillage à facettes + collision). L'ancien cylindre gris et le rivage CSG sont retirés. Le plateau constructible reste plat ; plage, rivage irrégulier, plateau sous-marin, fond ; dunes en terrasses sur les côtés, jamais vers la plage de départ.
- **Eau :** shader de l'océan en bandes de couleur selon la profondeur, facettes, écume nette.
- **Ciel et soleil :** nouveau ciel cartoon (`SkyStyle` + shader) avec disque de soleil, halo, coucher et étoiles ; la couleur du soleil suit sa hauteur.
- **Suivent le terrain :** décor du fond marin, marcheur de la fin, et l'anti-blocage (cherche le sol par un rayon, essaie un peu plus haut pour monter les marches).
- Nouveau test `test_terrain.gd` (plateau plat, plage praticable vers la mer, dunes, fond plat au loin, déterminisme, couleurs). 258 tests. Captures : `captures/terrain/`.

### 2026-11-16 — TEST ÉCHOUÉ — Terrain : blanc, puis le joueur passe au travers, puis fond pas plat
- **Terrain tout blanc :** couleurs de sommets trop claires et lues comme linéaires. Correction : `vertex_color_is_srgb` et palette assombrie.
- **Chute à travers le sol (scénario anti-blocage) :** triangles du maillage de collision dans des sens différents. Correction : même sens pour tous les triangles et collision des deux faces.
- **`test_seabed_is_flat_far_away` :** le petit bruit de surface s'ajoutait aussi au fond lointain (−2,99 au lieu de −3). Correction : ce bruit s'efface après le plateau sous-marin.

### 2026-11-16 — DÉCISION — Modèles gratuits en ligne plutôt que faits main
- Othmane : « là où c'est possible, utiliser des modèles low poly gratuits trouvés en ligne et les modifier si besoin, plutôt que les faire ». CC0 de préférence, sinon crédits notés. PRD §19.6.

### 2026-11-16 — DÉCISION — Version 0.1.0 gardée ; 0.1.X = les modèles
- Othmane : la démo greybox est « good enough ». Elle est gardée telle quelle comme version 0.1.0 (branche `version/0.1.0`, le push d'un tag est refusé depuis ce conteneur). Les versions 0.1.X passent aux modèles, style low poly cartoon « pas laid ». D'abord le terrain (sable à plusieurs niveaux, eau, ciel, soleil) ; les autres modèles après validation des terres. PRD §19.6.

### 2026-11-16 — TEST ÉCHOUÉ — « Identifier Settings not declared » chez Othmane
- **Cause :** sur le PC d'Othmane, `project.godot` n'avait plus la ligne de l'autoload `Settings` (l'éditeur ouvert pendant la mise à jour réécrit `project.godot` avec sa version en mémoire). Tous les scripts qui lisent les options (menu, options, joueur, HUD) ne compilaient plus. La CI ne le voyait pas : elle part du `project.godot` du dépôt, qui était correct.
- **Correction :** `Settings` n'est plus un autoload mais une classe à variables statiques (`class_name Settings`, `Settings.data`, `Settings.set_value()`, `Settings.events.changed`) : plus rien à déclarer dans `project.godot`. `main.gd` appelle `Settings.apply()` au lancement. Nouveaux tests : `test_project.gd` (chaque script du projet compile, les autoloads attendus existent, `Settings` n'en est pas un) et `test_settings_static.gd`.

### 2026-11-16 — NOTE — Mettre à jour le projet sans perdre project.godot
- Fermer l'éditeur Godot avant un `git pull`, puis le rouvrir. Si `git status` montre `game/project.godot` modifié sans raison, `git checkout game/project.godot`.

### 2026-11-16 — QUESTION — Modèles low-poly avec Blender
- Othmane demande si Claude peut faire du Blender (MCP Blender) et des modèles low-poly. Aucun connecteur Blender ici ; Blender lui-même n'est pas téléchargeable depuis ce conteneur, mais le module Python `bpy` (Blender sans interface) l'est : on peut écrire des modèles par script et les exporter en .glb. Le PRD prévoit des packs CC0 pour le MVP (M-07) et du sur-mesure Blender plus tard.

### 2026-11-16 — MODIF — Sons de base et mesure de perf
- **Quoi :** `core/sound_synth.gd` (9 sons par synthèse : bruit filtré, glissandos, arpège, bourdon, boucles sans clic, déterministes) ; `scenes/audio/sound_board.gd` (joue les sons en observant GameState : seau, téléphone, ramassage, jalon, avion, bonde) ; `tests/scenarios/perf.gd` (rapport de perf, lancé aussi par la CI pour attraper les erreurs) ; 6 tests (`test_sound.gd`) ; les 9 sons exportés en WAV dans `captures/sons/` du dossier du projet pour écoute.
- **Pourquoi :** PRD §19.1 (sons de base, mesure de perf).
- **Impact :** PRD v0.31, `game/core/`, `game/scenes/audio/`, `game/scenes/main.gd`, CI, tests, guide du code.

### 2026-11-16 — NOTE — Mesures de perf
- Logique : ~1 ms par image sans affichage, pic de ~34 ms une seule fois quand 40 tuyaux sont reconstruits d'un coup. Rendu (logiciel, llvmpipe) : 208 → 340 appels de dessin entre l'île de départ et une île remplie, ~67 000 primitives, 55-60 Mo. Pistes si besoin sur le PC de référence : fusionner les maillages des tuyaux (MultiMesh), réduire la grille de l'océan proche.

### 2026-11-16 — DÉCISION — Bouton « Nouvelle partie » dans le menu
- **Quoi :** Othmane veut pouvoir lancer une nouvelle partie depuis le menu.
- **Impact :** PRD v0.30 ; menu principal et menu pause.

### 2026-11-16 — MODIF — Vraie fin, traits du palmier, Nouvelle partie
- **Quoi :** `core/ending_logic.gd` (phases minutées, saut, disposition des traits) ; GameState : `start_ending()`, `ending_drop_m` (l'eau descend pour la mise en scène), `finish_run()`, `best_time_s`, `finished_runs`, `pre_ending_removed_l` (une partie finie se rouvre avant la chaîne), `wakeups` / `register_wakeup()`, `new_game_in_slot()` ; `scenes/world/ending_director.gd` (bonde, tourbillon, marcheur, avion publicitaire avec banderole Label3D, écran du temps, générique) ; `scenes/world/palm_marks.gd` ; F4 dans les outils admin ; HUD et jalons cachés pendant la fin ; noyade : retour par `rescue()` + un trait ; menu principal : Nouvelle partie, Continuer, confirmation ; 10 tests (`test_ending.gd`, `test_settings.gd`).
- **Pourquoi :** PRD §19.1 (vraie fin derrière une touche de debug, clins d'œil) et demande d'Othmane.
- **Impact :** PRD v0.30, `game/core/`, `game/scenes/`, `game/admin/`, traductions, tests, guide du code.

### 2026-11-16 — TEST ÉCHOUÉ — Fin de run et partie finie en 0 s
- **Cause :** (1) `_step_ending` lisait `ending.phase` après que `finish_run()` l'avait remis à null ; (2) « partie finie » était déduit de `best_time_s > 0`, faux pour une partie finie à 0 s (test).
- **Correction :** sortie immédiate après la fin ; compteur `finished_runs` à part.

### 2026-11-16 — DÉCISION — Aucun blocage possible
- **Quoi :** Othmane s'est retrouvé coincé dans un petit espace entre un tuyau et un tas de sel ; il demande qu'aucun blocage ne soit possible.
- **Impact :** PRD v0.29 (anti-blocage).

### 2026-11-16 — MODIF — Anti-blocage
- **Quoi :** `core/physics_layers.gd` (couches SOLID / WALK_THROUGH / AIM) : tas, tuyaux, coquillages et noix de coco traversables mais visables ; `core/unstuck_logic.gd` (minuterie « coincé », 8 directions, places de secours en cercles) ; le joueur teste `test_move` dans 8 directions puis cherche une place libre avec `intersect_shape` et un rayon vers le sol ; bouton « Me débloquer » dans le menu pause ; `GameConfig.unstuck_*` ; 6 tests unitaires (`test_unstuck.gd`) et un **scénario avec le vrai moteur physique** (`tests/scenarios/softlock.gd` : traverser des tuyaux, sortir seul d'une cage de murs, retour plage avec un mur sur le point de retour), lancé par la CI.
- **Pourquoi :** blocage signalé par Othmane.
- **Impact :** PRD v0.29, `game/core/`, `game/scenes/player/player.gd`, `game/scenes/world/`, menu pause, CI, tests, guide du code.

### 2026-11-16 — TEST ÉCHOUÉ — Cage trop large et somme de flottants
- **Cause :** (1) dans le scénario, une cage un peu plus large que le personnage n'était pas vue comme une prison (on testait 25 cm par direction) ; (2) 10 × 0,1 s donnait 0,9999… < 1 s dans la minuterie.
- **Correction :** il faut pouvoir partir de 80 cm dans au moins une direction (`ESCAPE_M`) ; marge de 1e-6 dans la comparaison.

### 2026-11-16 — MODIF — Menu principal, 3 emplacements, options, pause
- **Quoi :** `core/settings_logic.gd` (options bornées, lecture/écriture, balancement de tête) et l'autoload `Settings` (`core/settings.gd`, applique langue, volume, plein écran) ; `scenes/ui/main_menu.gd`, `pause_menu.gd`, `options_panel.gd`, `menu_style.gd` ; `SaveSystem.summary()` ; `GameState.play_slot()`, `delete_slot()`, `autosave()`, `autosave_enabled`, `save_dir` ; le joueur lit FOV, sensibilité et balancement dans `Settings` ; HUD : chronomètre caché sauf option speedrun (`format_precise`) ; sauvegarde après achat ; `DTO_SKIP_MENU=1` saute le menu (captures, essais) ; CI : deuxième test de fumée sans menu ; 13 tests (`test_settings.gd`).
- **Pourquoi :** PRD §19.1 (menu avec 3 emplacements, options complètes, chronomètre caché).
- **Impact :** PRD v0.28, `game/core/`, `game/scenes/ui/`, `game/scenes/main.gd`, `game/scenes/player/player.gd`, traductions, CI, tests, guide du code.

### 2026-11-16 — TEST ÉCHOUÉ — Appel de méthode inexistante dans un test
- **Cause :** `test_settings.gd` appelait `ocean.remove()` au lieu de `ocean.remove_water()` : erreur de script, le test s'arrêtait sans être compté en échec (la CI, elle, cherche « SCRIPT ERROR » dans le journal).
- **Correction :** bon nom de méthode.

### 2026-11-16 — MODIF — Les 3 premiers jalons comparatifs
- **Quoi :** `core/milestone_logic.gd` (liste triée, jalons franchis, avancement, sauvegarde) ; `GameConfig.milestones` (baignoire, piscine gonflable, piscine, piscine olympique, avec récompenses) ; `GameState.check_milestones()` (après chaque seau et à chaque pas de `simulate`), signal `milestone_reached` ; `scenes/ui/milestone_icon.gd` (pictogrammes dessinés à la main) et `milestone_panel.gd` (prochain jalon qui se remplit, grand pictogramme au passage) ; 7 tests (`test_milestones.gd`).
- **Pourquoi :** PRD §19.1 (progrès : 3 premiers jalons comparatifs).
- **Impact :** PRD v0.27, `game/core/`, `game/scenes/ui/`, `game/data/game_config.tres`, tests, guide du code.

### 2026-11-16 — MODIF — Toboggan à sacs et flamant payé en perle
- **Quoi :** nouvel effet `CatalogItem.Effect.SLIDE` ; `GameState` : `slides`, `add_slide`, `zones_for_slide`, `slide_unload`, `_run_slides` (dans `simulate`), signaux `slide_added` / `slide_sent`, sauvegarde ; `scenes/world/slide_view.gd` (tour, goulotte, sacs qui glissent) ; article `flamant` (1 perle) et son décor ; 8 tests (`test_content.gd`, dont une vérification de tous les articles du catalogue).
- **Pourquoi :** PRD §19.1 (contenu : toboggan à sacs, objet spécial en perle, stock automatique après un achat).
- **Impact :** PRD v0.26, `game/core/`, `game/scenes/`, `game/data/`, strings, tests, guide du code.

### 2026-11-16 — NOTE — Virgules dans les traductions
- Une description de catalogue contenait une virgule : dans `strings.csv`, ces champs doivent être entre guillemets. Vérifié par un script (toutes les lignes ont 3 colonnes).

### 2026-11-16 — MODIF — Téléphone : premier appel, offres du jour, crochet de l'avion
- **Quoi :** `core/phone_logic.gd` (sonnerie, tutoriel, offre du jour, prix réduit, sauvegarde) ; `GameState` : `phone`, `answer_phone`, `price_of`, `offer_candidates`, `_new_crate`, signaux `phone_changed` / `phone_answered`, `paid` sur la première caisse ; article caché `catalogue_papier` (`CatalogItem.hidden`) ; `phone.gd` (tremble, « Dring ! », musique d'attente) ; catalogue : prix de l'offre en jaune ; `delivery_plane.gd` : crochet, paquet arraché, pilote qui salue ; 14 tests (`test_phone.gd`).
- **Pourquoi :** PRD §19.1 (téléphone).
- **Impact :** PRD v0.25, `game/core/`, `game/scenes/`, `game/data/`, strings, tests, guide du code.

### 2026-11-16 — TEST ÉCHOUÉ — Bassin posé sur un coquillage quand l'île est pleine
- **Quoi :** `test_big_crate_full_of_basins_never_overlaps` a échoué une fois (bassin et coquillage à 4,24 m pour 4,25 m d'emprises).
- **Cause :** `find_free_spot` ne cherchait que sur 16 anneaux de cases autour du point de largage ; avec les emprises agrandies (bassin 4 m), il n'y avait plus de place dans ce carré et il rendait la case de départ, même occupée.
- **Correction :** la recherche couvre toute l'île (anneaux jusqu'à 2 × rayon constructible).

### 2026-11-16 — DÉCISION — Finir toute la démo, une branche par release
- **Quoi :** Othmane : « Continue à implémenter en testant à chaque bout toutes les fonctionnalités restantes et push en main, mais garde chaque release et les composants assez indépendants tout en utilisant des techniques recherchées pour les problèmes déjà résolus comme l'eau. […] si on est en dessous de la barre d'eau il n'y a pas de filtre bleu. Mais finis tout ! Test rigoureux avec un push final, mais chaque branche à part. »
- **Impact :** une PR par release (#14 et suivantes), PRD §19.5.

### 2026-11-16 — MODIF — Monde vivant : vagues, filtre sous l'eau, fond marin, nuages, animaux
- **Quoi :** `scenes/world/ocean_view.gd` + `shaders/ocean.gdshader` (vagues de Gerstner, couleur selon la profondeur lue dans le tampon de profondeur, écume, Fresnel ; carré découpé près de la caméra + grand plan au loin) ; `scenes/ui/underwater_overlay.gd` + `shaders/underwater.gdshader` (filtre plein écran et brouillard bleu sous la surface) ; `seabed_decor.gd`, `clouds.gd`, `fauna.gd` (mouettes, poissons, crabe) ; calculs purs dans `core/ambient_motion.gd` ; 8 tests (`test_ambient.gd`). L'ancien plan d'eau de `main.tscn` est retiré.
- **Pourquoi :** PRD §19.1 (monde) et demande d'Othmane (filtre sous l'eau).
- **Impact :** PRD v0.24, `game/core/`, `game/scenes/`, tests, guide du code.

### 2026-11-16 — TEST ÉCHOUÉ — Shader d'océan refusé par Godot 4.7
- **Quoi :** « DEPTH_TEXTURE has been removed in favor of using hint_depth_texture with a uniform ».
- **Correction :** un `uniform sampler2D depth_tex : hint_depth_texture`. Vérifié en capture avec le moteur de rendu de compatibilité (aucune erreur de shader).

### 2026-11-16 — DÉCISION — Un tas par matériau, matériaux dans la barre, menu
- **Quoi :** Othmane : chaque matériau récolté s'affiche à part à côté des zones de séchage (plus un seul tas de sel) ; chaque matériau différent prend une des 5 cases en main ; il faut un menu pour réorganiser les 5 cases.
- **Impact :** PRD v0.23 (§10 barre, grille).

### 2026-11-16 — MODIF — Un tas par matériau, matériaux dans la barre, menu « Ranger la barre »
- **Quoi :**
  - Zones de séchage : un tas par matériau (sel, minéraux, minéraux rares), chacun sur sa case (`config.pile_slots`) ; E ramasse 3 unités du tas visé, le râteau tout le tas. Emprises agrandies (cuvette et bâche 3 m, bassin 4 m) pour que les 3 tas restent dedans.
  - Barre : au départ le seau + 4 cases vides (= les mains, la case « Mains » fixe disparaît). Outils achetés et matériaux portés prennent les cases vides ; un matériau sans case libre reste par terre ; la case se libère à la palette ou au paiement. Disposition sauvegardée.
  - Menu Tab : cliquer deux cases pour les échanger (`scenes/ui/toolbar_menu.gd`).
  - `test_toolbar.gd` réécrit (21 tests) ; 173 tests.
- **Pourquoi :** demande d'Othmane ci-dessus.
- **Impact :** PRD v0.23, `game/core/`, `game/scenes/`, `game/data/game_config.tres`, strings, tests, guide du code.

### 2026-11-16 — TEST ÉCHOUÉ — Bâche posée sur une noix de coco dans un test
- **Quoi :** `test_shells_never_land_on_things_over_many_mornings` : « bâche et noix de coco se chevauchent ».
- **Cause :** le test pose la bâche directement (sans vérification) ; avec l'emprise passée à 3 m, elle touchait la place d'une noix de coco.
- **Correction :** le test pose la bâche sur une place libre (12,5 ; −2,5). Le jeu, lui, vérifie toujours la place.

### 2026-11-16 — DÉCISION — Tuyaux à la main, débit visible, plusieurs caisses
- **Quoi :** Othmane : « rework the piping system, the piping needs to be done manually by the player + on peut le faire vertical ou horizontal, comme on veut ». Les pompes montrent leur débit quand on s'approche, la pompe à bras quand on s'en sert. Une commande avec plusieurs objets à poser → plusieurs caisses. Une caisse qui tombe sur quelque chose reste dessus. « Make sure the pumping doesn't break when changing the position of something. » « Make everything and push to main. »
- **Impact :** PRD v0.22 (§9 T2, §15 livraison).

### 2026-11-16 — MODIF — Tuyaux posés à la main, débit des pompes, une caisse par objet
- **Quoi :**
  - `core/pipe_network.gd` réécrit : les tuyaux sont des pièces sur des cases 3D (grille de 1 m, niveaux 0 à 4) ; l'eau suit les pièces reliées depuis la pompe (parcours en largeur) et se verse dans les zones sous ou à côté d'une pièce, les plus proches d'abord.
  - `GameState` : `pipes`, `pipe_stock` (+5 pièces par lot de 50 sel), `can_place_pipe`, `place_pipe`, `remove_pipe`, `zones_for_pump`, `wet_pipes`, `last_lps` ; anciennes sauvegardes : chaque tronçon de 4 m devient 4 pièces en stock.
  - Nouvel outil « Tuyaux » (case 4 de la barre) et `scenes/world/pipe_builder.gd` (cube fantôme vert/rouge, clic pour poser, E pour reprendre) ; `pipes_view.gd` dessine chaque pièce (bleue si l'eau y passe).
  - `pump_view.gd` : étiquette de débit au-dessus des pompes (à moins de 7 m ; la pompe à bras seulement quand on pompe).
  - `GameState.order()` renvoie une liste de caisses (une par objet à poser + une pour le reste, avions décalés de 1,2 s) ; `open_crates()`. `crate_view.gd` : la caisse se pose sur ce qu'elle touche (5 rayons vers le bas).
  - `test_pumps.gd` réécrit (pose, hauteur, trous dans le réseau, deux zones, déplacements de pompe/zone/moulin, sauvegarde), 3 tests de caisses dans `test_spawning.gd`. 162 tests.
- **Pourquoi :** demande d'Othmane ci-dessus.
- **Impact :** PRD v0.22, `game/core/`, `game/scenes/`, `game/data/`, strings, tests, guide du code.

### 2026-11-16 — TEST ÉCHOUÉ — Pompe bloquée par sa propre pièce de tuyau
- **Quoi :** `test_moving_the_pump_along_its_pipe_keeps_working` : impossible de poser la pompe à côté d'une pièce au sol.
- **Cause :** l'objet comptait rayon de pompe (0,8) + rayon de tuyau (0,45) > 1 case, alors que la pose du tuyau ne comptait que le rayon de la pompe : règle pas symétrique.
- **Correction :** rayon d'une pièce 0,2 m, même calcul dans les deux sens ; emprise du moulin 0,8.

### 2026-11-16 — TEST ÉCHOUÉ — Tests de pompes qui dépendaient du hasard
- **Quoi :** `test_moving_the_pump_away_disconnects_it_cleanly` échouait parfois.
- **Cause :** un coquillage tiré au hasard occupait la case visée.
- **Correction :** `test_pumps.gd` et `test_windmill.gd` retirent les coquillages au départ. Aussi : le test de fin de démo vise un seuil que la seule cuvette reliée peut atteindre (60 L).

### 2026-11-16 — MODIF — Barre d'outils de 5 cases (M-27)
- **Quoi :** `core/toolbar_logic.gd` (cases, choix, molette qui saute les cases indisponibles, vérification au chargement), `GameState` (`toolbar`, `current_tool`, `owns_tool`, `select_tool`, `cycle_tool`, signal `tool_changed`, outil sauvegardé), touches 1-5 et molette dans `player.gd`, seau et râteau visibles selon l'outil, seau et râteau qui n'agissent qu'en main, barre dans le HUD, 10 tests (`test_toolbar.gd`). Le test « râteau » de la boucle complète demande maintenant de le prendre en main.
- **Pourquoi :** M-27, troisième des releases demandées.
- **Impact :** PRD §10 (v0.21), `game/core/`, `game/scenes/`, strings, tests.

### 2026-11-16 — TEST ÉCHOUÉ — Sauvegarde avec un outil hors barre
- **Quoi :** charger une sauvegarde où l'outil tenu vaut 42 provoquait « Out of bounds get index '42' ».
- **Cause :** `ToolbarLogic.is_available()` ne vérifiait pas l'indice.
- **Correction :** indice hors barre = indisponible, donc retour au seau. Couvert par `test_selected_tool_is_saved_and_checked_on_load`.

### 2026-11-16 — MODIF — Moulin-pompe et fin de la démo
- **Quoi :** type de pompe `moulin_pompe` (automatique, 10 L/s, au bord de l'eau, unique), `GameState._run_auto_pumps()` dans `simulate()`, `auto_pumped_l`, `demo_done`, signal `demo_finished` ; vue du moulin (tour, pales qui tournent quand l'eau passe) ; `scenes/ui/demo_end.gd` (gros avion teaser avec silhouettes T3, puis écran de fin avec bilan et « Continuer à jouer ») ; 7 tests (`test_windmill.gd`).
- **Pourquoi :** fin de T2 et fin de la démo (M-05, M-57), deuxième des trois releases demandées.
- **Impact :** PRD §7 (v0.20), `game/core/`, `game/data/`, `game/scenes/`, strings.

### 2026-11-16 — TEST ÉCHOUÉ — Le moulin « perdait » de l'eau
- **Quoi :** après 2 s, la cuvette contenait 19,1 L au lieu de 20 L.
- **Cause :** la cuvette s'évapore pendant qu'elle se remplit ; le test mesurait la mauvaise chose.
- **Correction :** le test vérifie ce qui est sorti de l'océan (20 L pile).

### 2026-11-16 — MODIF — Pompe à bras et tuyaux (T2)
- **Quoi :** `core/pipe_network.gd` (logique pure : liaisons, tronçons nécessaires, bord de zone, répartition), `GameState` (`pumps`, `pipe_segments`, `add_pump`, `pipe_links`, `zones_for_pump`, `run_pump`, signaux `pump_added` et `network_changed`), effets `PUMP` et `PIPES`, placement « au bord de l'eau » (`shore_only_kinds`), vues `pump_view.gd` (levier qui bouge) et `pipes_view.gd`, clic maintenu (`hold_use`) dans `player.gd`, articles « Pompe à bras » et « Tuyau », 16 tests (`test_pumps.gd`).
- **Pourquoi :** suite de T2 (liste M-57, M-58 pompe active), première des trois releases demandées par Othmane.
- **Impact :** PRD §7 (v0.19), `game/core/`, `game/data/`, `game/scenes/`, strings.

### 2026-11-16 — TEST ÉCHOUÉ — Pompe posée sur le repère d'eau
- **Quoi :** dans `test_pumps.gd`, déplacer la pompe en (2,5 ; 16,5) échouait.
- **Cause :** l'emprise touchait le repère de niveau d'eau (obstacle fixe en (3 ; 17)). Le placement avait raison, pas le test.
- **Correction :** le test vise une case libre.

### 2026-11-16 — DÉCISION — Vérifier la place avant d'apparaître, mode G automatique
- **Quoi :** Othmane : « Make sure que les coquillages et les autres spawnable objects prennent en compte qu'est-ce qui est où avant de spawner. When opening something from a crate that is to place like drying places, we switch to G mode automatically. […] run tests for all bug possibilities […] And make and push the next 3 releases but test in between ».
- **Impact :** PRD §10 (v0.18). Trois releases suivantes prévues : pompe à bras + tuyaux, moulin-pompe + fin de démo, barre d'outils (M-27).

### 2026-11-16 — MODIF — Cases vérifiées, mode G automatique, CI plus stricte
- **Quoi :**
  - Les emprises qui gênent comptent maintenant les coquillages et le joueur (`player_position`, rayon dans les données). Coquillage : 40 essais, sinon rien. Noix de coco : seulement si sa place est libre.
  - `apply_item` renvoie l'objet posé ; `open_crate` émet `placement_requested` pour chacun ; le contrôleur de placement les met en file et les lance l'un après l'autre (s'il a la main).
  - Le contrôleur annule si l'objet déplacé disparaît.
  - 20 tests de cas tordus (`test_spawning.gd`) : 40 matins sans chevauchement, plage pleine, noix sous un objet, caisse en vol, grosse caisse de 11 objets, joueur, coquillage qui bloque puis se ramasse, échec de déplacement sans effet, eau et sel gardés, vieille sauvegarde mal rangée…
- **Impact :** `game/core/game_state.gd`, `game_config`, `placement_controller.gd`, `main.gd`, `player.gd`, tests, CI.

### 2026-11-16 — TEST ÉCHOUÉ — Le lanceur de tests ignorait les erreurs
- **Quoi :** un fichier de tests qui ne compile pas était ignoré (« 93 tests, 0 échec ») ; une erreur de script au milieu d'un test le laissait « ok ». Trouvé en écrivant `test_spawning.gd` (type non déduit, puis une commande refusée car les tongs sont uniques).
- **Correction :** le lanceur compte un fichier qui ne compile pas comme un échec ; la CI échoue aussi si « SCRIPT ERROR » apparaît dans les tests ou dans le test de fumée.

### 2026-11-16 — DÉCISION — Rotation, palette déplaçable, cases pour ce qui apparaît
- **Quoi :** Othmane demande : « Ajoute la rotation et garde le telephone fixe et la palette doit etre movable. Fixe ca et merge au main directement », puis « pour le sel et autre qui sont générés, ils doivent letre dans la grille correspondante pour que ca ne soit pas sur un autre objet ».
- **Impact :** PRD §10 (v0.17). Détails (touche R, quart de tour, tas à 2 ou 3 cases) **[PROPOSÉ]**.

### 2026-11-16 — MODIF — Rotation (R), palette déplaçable, cases libres
- **Quoi :**
  - `rotation_deg` dans chaque objet déplaçable, sauvegardée ; `move_item(item, pos, rotation)` ; touche R (quart de tour, réglé dans les données).
  - `GameState.depot` : la palette devient un objet déplaçable comme les autres (position de départ dans les données) ; elle n'est plus un obstacle fixe.
  - `find_free_spot()` : case libre la plus proche ; utilisé pour la cuvette de départ, les caisses livrées, les objets sortis des caisses. Coquillages au centre d'une case libre. Les caisses au sol et les noix de coco bloquent leur place.
  - Tas de sel dans sa propre case (`pile_offset_cells`), emprises des zones agrandies pour l'inclure (cuvette et bâche 2,5 m, bassin 3,5 m).
  - Cuvette de départ et palette recalées au centre d'une case. Anciennes sauvegardes lues sans perte (miroirs en liste, pas de palette). 5 nouveaux tests, 93 au total.
- **Impact :** `game/core/`, `game/data/game_config.tres`, `game/scenes/`, strings, PRD v0.17, guide du code.

### 2026-11-16 — DÉCISION — Déplacer les objets avec une grille
- **Quoi :** Othmane veut pouvoir changer les objets de place dans cette release, et propose une grille (« we definitely need to be able to change places for things in it. Maybe a grid system would be good ? »).
- **Pourquoi :** la décision « déplacer plus tard » (PRD §19.2, M-22) devient prioritaire.
- **Impact :** PRD §10 et §19.2 (v0.16). Les détails (cases de 1 m, emprises, objets fixes, pas de rotation) restent **[PROPOSÉ]**.

### 2026-11-16 — MODIF — Mode déplacement sur grille (G)
- **Quoi :**
  - Nouvelles règles pures `core/placement_grid.gd` (aligner sur une case, vérifier l'île et les chevauchements).
  - GameState : `move_item`, `can_place`, `movable_items`, signal `item_moved`, drapeau `placing` ; les décors ont un id, les miroirs un type.
  - Données : taille de case, rayon constructible, emprise par type, obstacles fixes.
  - Nouvelle vue `scenes/world/placement_controller.gd` (aperçu, disque vert/rouge, grille dessinée), touche G, invites « [G] Déplacer », « [Clic] Poser · [G] Annuler », « Impossible ici ».
  - Les décors deviennent visables (corps physique). 7 nouveaux tests (`test_placement.gd`), 88 au total.
- **Pourquoi :** demande d'Othmane (entrée ci-dessus).
- **Impact :** `game/core/`, `game/data/game_config.tres`, `game/scenes/`, `game/localization/strings.csv`, PRD v0.16, `docs/GUIDE_CODE.md`.

### 2026-11-16 — TEST ÉCHOUÉ — Type non déduit dans le contrôleur de placement
- **Quoi :** au lancement de la scène (capture d'écran), `placement_controller.gd` ne compilait pas : « Cannot infer the type of "hit" ». Les tests automatiques passaient, car ils ne chargent pas la scène principale.
- **Cause :** le joueur est passé en `Node` non typé, donc le résultat du rayon n'a pas de type connu.
- **Correction :** type écrit en toutes lettres (`var hit: Dictionary`). Le test de fumée de la CI attrape ce genre d'erreur.

### 2026-11-16 — NOTE — Disque d'emprise et profondeur
- **Quoi :** dessiné « par-dessus tout », le disque vert recouvrait l'objet déplacé. Il est maintenant dessiné normalement, juste au-dessus du sable ; la grille est en bleu foncé pour rester visible sur le sable clair.

### 2026-11-16 — MODIF — F6 corrigé, palette par ressource, début de T2
- **Quoi :**
  - Une seule fonction fait vivre le monde (heure, séchage, objets à portions, faim, soif) ; le jeu et l'avance rapide F6 l'appellent tous les deux.
  - Palette agrandie (3,6 × 1,6 m), un tas coloré et un compteur par ressource, le nom peint devant.
  - Manuel du bricoleur (débloque T2, articles T2 grisés avant), bassin en bois (200 L), miroir solaire (+50 % à moins de 6 m).
  - Catalogue : panneau opaque, liste qui défile.
  - 5 nouveaux tests (81 au total).
- **Pourquoi :** retours d'Othmane, et « fais la prochaine release ».
- **Impact :** `game/core/game_state.gd`, `game_config.gd`, `catalog_item.gd`, `game/data/`, `game/admin/admin_tools.gd`, `game/scenes/` (depot, drying_zone_view, mirror_view, main, ui/catalogue), `game/localization/strings.csv`, `game/tests/`, `docs/GUIDE_CODE.md`, PRD v0.15 (§7, §9.2).
- **Par :** Claude

### 2026-11-16 — TEST ÉCHOUÉ — F6 n'avançait que l'horloge (test manuel d'Othmane)
- **Quoi :** avec F6, la faim et la soif ne baissaient pas.
- **Cause :** F6 faisait avancer seulement le cycle jour/nuit ; la faim, la soif, le séchage et la condensation n'avancent que dans la boucle par image.
- **Correction :** la boucle par image appelle désormais une fonction unique « faire vivre le monde de N secondes », et F6 l'appelle aussi. Test `test_fast_forward_moves_hunger_drying_and_condenser`.
- **Par :** Claude (trouvé par Othmane)

### 2026-11-16 — DÉCISION — Palette lisible, release suivante fusionnée directement
- **Quoi :** la palette doit être plus grande et montrer chaque ressource à part. Faire la release suivante avec les correctifs et la fusionner directement dans main pour qu'il teste.
- **Par :** Othmane

### 2026-11-16 — MODIF — Endurance réduite de moitié
- **Quoi :** `stamina_run_s` 20 → 10 s, `stamina_swim_s` 60 → 30 s dans les données. PRD v0.14.
- **Impact :** `game/data/game_config.tres`, `game/core/game_config.gd` (valeurs par défaut), PRD §4.1.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Endurance : moitié de N-05
- **Quoi :** Othmane trouve l'endurance « trop généreuse » : ~10 s de course et ~30 s de nage au lieu de ~20 s et ~60 s (remplace la durée de N-05 ; le reste de N-05 tient). Il demande ensuite de fusionner la PR #5.
- **Par :** Othmane

### 2026-11-16 — MODIF — Survie légère, plage vivante et guide du code
- **Quoi :**
  - Nouveau `docs/GUIDE_CODE.md` : comment chaque idée est implémentée côté code (fichiers, nœuds, signaux, flux de données), de M0 à aujourd'hui, avec une section par version. Règle ajoutée dans `CLAUDE.md`.
  - Faim et soif (`SurvivalLogic`) reliées au plafond d'endurance ; jauges dans le HUD.
  - Noix de coco sous les palmiers et coquillages sur la plage, renouvelés chaque matin (`pickups`).
  - Catalogue : bâche de condensation (20 sel) et rations (8 sel), via un nouvel effet `STATION` et `StationLogic`.
  - Tout est sauvegardé ; une ancienne sauvegarde reçoit des noix et des coquillages au chargement.
  - 11 nouveaux tests (76 au total).
- **Pourquoi :** demande d'Othmane : passer à la release suivante, et expliquer la logique de code de chaque version.
- **Impact :** `docs/GUIDE_CODE.md`, `CLAUDE.md`, `game/core/` (survival_logic, station_logic, stamina_logic, game_state, game_config, catalog_item), `game/data/`, `game/scenes/` (main, hud, world/pickup_view, world/station_view), `game/localization/strings.csv`, `game/tests/`, PRD v0.13 (§4.1, §19.2).
- **Par :** Claude

### 2026-11-16 — TEST ÉCHOUÉ — Pénalité de faim comptée trop tôt ; types non déduits
- **Quoi :**
  1. `test_empty_need_lowers_max_stamina_without_death` : un seul long pas de temps qui vidait la soif comptait **tout** ce pas dans la pénalité, même la partie où il restait de l'eau. Correction : seul le temps passé à zéro compte.
  2. `test_game_loop.gd` ne se chargeait pas (variables sans type déduit sur un objet non typé) ; corrigé par des types explicites.
- **Impact :** `game/core/survival_logic.gd`, `game/tests/test_game_loop.gd`.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Explications de code à chaque version
- **Quoi :** Othmane valide les retours de test (PR #4). Il veut qu'à chaque nouvelle version on lui explique brièvement la logique **de code** (pas seulement la logique de jeu), y compris pour les versions déjà faites, puis passer à la release suivante.
- **Pourquoi :** choix d'Othmane.
- **Impact :** `docs/GUIDE_CODE.md`, règle dans `CLAUDE.md`.
- **Par :** Othmane

### 2026-11-16 — MODIF — Retours du premier test : panier, paiement, tas de sel, lune, outils admin
- **Quoi :**
  - Panier : les articles identiques sont regroupés (« Nom ×N »).
  - Paiement avec les bras puis la palette ; le catalogue affiche les deux.
  - Le sel s'entasse à côté de chaque zone ; E sur le tas pour ramasser ; le clic sur la zone ne sert plus qu'à verser.
  - Ciel : le soleil s'éteint la nuit (fini le « soleil noir »), une lune apparaît ; le plan d'eau suit le joueur et le bas du ciel prend la couleur de la mer ; reflets de l'eau adoucis.
  - Outils admin regroupés dans `game/admin/admin_tools.gd` (touches F1, F6 à F12), retirés de la scène principale.
  - 5 nouveaux tests (65 au total).
- **Pourquoi :** retours d'Othmane après son premier test de M2.
- **Impact :** `game/core/economy.gd`, `game/core/game_state.gd`, `game/scenes/ui/catalogue*.gd`, `game/scenes/world/drying_zone_view.gd`, `game/scenes/main.gd`, `game/scenes/main.tscn`, `game/admin/`, `game/project.godot`, `game/localization/strings.csv`, `game/tests/`, PRD v0.12 (§6.3, §9.2, §10, §15, §19.1).
- **Par :** Claude

### 2026-11-16 — NOTE — La lueur à l'horizon dépend du rendu
- **Quoi :** sur les captures de Claude (rendu logiciel « Compatibility »), l'eau près de l'horizon reste plus claire qu'en vrai. Si Othmane voit encore une lueur sur son PC (Forward+), il faudra une capture de son écran pour viser la bonne cause (reflet du soleil, brouillard ou ciel).
- **Par :** Claude

### 2026-11-16 — DÉCISION — Retours du premier test de M2
- **Quoi :** Othmane demande : panier regroupé « Nom ×N » ; pouvoir payer avec ce qu'on porte + la réserve ; ne plus tout faire avec le même bouton (idée : le sel s'entasse à côté de l'eau) ; corriger la lueur à l'horizon et le « soleil noir » la nuit (une lune) ; pouvoir déplacer les objets de l'île (plus tard, consigné dans le PRD) ; des outils admin pour tout tester, faciles à retirer.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD v0.12.
- **Par :** Othmane

### 2026-11-16 — MODIF — Rythme 1 min 30, nage et endurance, niveau d'eau, outils T1
- **Quoi :**
  - Rythme : 4 L évaporés par sel au lieu de 10 (nouvelle valeur `liters_per_salt` dans les données ; c'était une constante dans le code, contraire à la règle du CLAUDE.md). Récolte à la main par 3 unités par clic.
  - Endurance (logique pure + 4 tests) et jauge dans le HUD.
  - Nage : flottaison, Espace pour monter, se hisser sur le rivage, noyade avec fondu au noir et retour sur la plage.
  - Niveau d'eau honnête calculé depuis le volume retiré ; le plan d'eau suit cette hauteur ; jauge à aiguille logarithmique sur la plage ; touche de debug F7.
  - Catalogue : brouette (30 sel, 40 unités), tongs (25 sel + 2 coquillages, +20 % de vitesse), râteau (60 sel + 5 minéraux), palanche (120 sel + 10 minéraux, deux seaux). Les améliorations sont sauvegardées.
  - Valeurs de déplacement (marche, course, nage) déplacées du joueur vers les données.
  - 17 nouveaux tests (60 au total). Vérifié en scène : on nage, on remonte sur le rivage, la noyade ramène sur la plage, l'eau baisse avec F7.
- **Pourquoi :** retours d'Othmane sur M2, puis « Continue ».
- **Impact :** `game/core/` (stamina_logic, drying_logic, ocean_model, game_state, game_config, catalog_item), `game/data/`, `game/scenes/` (player, main, hud, world/water_gauge), `game/tests/`, PRD v0.11 (§5.4, §6.3, §8.2, §10, §19.1, §19.4), section « Architecture et logique ».
- **Par :** Claude

### 2026-11-16 — TEST ÉCHOUÉ — Endurance pas tout à fait vide, nageur bloqué au rivage
- **Quoi :**
  1. `test_running_empties_in_twenty_seconds` et `test_swimming_lasts_sixty_seconds` échouaient : 19 s puis 1 s de course laissaient ~0,000001 d'endurance (arrondi des flottants). Correction : en dessous de 10⁻⁶, l'endurance vaut 0.
  2. Test en scène : le nageur qui avançait contre le rivage montait de quelques centimètres puis retombait sans fin. Cause : dès que les pieds dépassaient 1,2 m de profondeur, il ne « nageait » plus et l'escalade s'arrêtait. Correction : l'escalade continue tant que les pieds sont sous la surface et qu'on avance contre le bord.
  3. `test_game_loop.gd` ne se chargeait pas (types non déduits sur une variable non typée) ; corrigé par des types explicites.
- **Impact :** `game/core/stamina_logic.gd`, `game/scenes/player/player.gd`, `game/tests/test_game_loop.gd`.
- **Par :** Claude

### 2026-11-16 — NOTE — « ERR_CANT_OPEN » au lancement dans le conteneur de Claude
- **Quoi :** l'erreur « Condition status < 0 … ERR_CANT_OPEN » vient du pilote audio (ALSA) : le conteneur n'a pas de carte son. Sans effet sur un vrai PC.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Premier achat vers 1 min 30, et la nage tout de suite
- **Quoi :** après avoir testé M2, Othmane trouve le premier achat (3 min) « beaucoup trop long » : il le veut vers 1 min 30. Il demande aussi la nage dès maintenant, car tomber dans l'eau bloquait le joueur. Puis « Continue » : enchaîner sur la suite (niveau d'eau, râteau, brouette, palanche).
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §5.4 (remplace « moins de 3 minutes », M-59), §6.3, §10.
- **Par :** Othmane

### 2026-11-16 — MODIF — Jalon M2 : boucle de base jouable en greybox
- **Quoi :**
  - Logique pure : séchage, seau, économie (troc), cycle jour/nuit, catalogue piloté par fichier de données.
  - GameState réécrit en source unique de vérité : zones de séchage, mains (10 max), stock de la palette, commandes, caisses, décors, objets possédés, sauvegarde de tout.
  - Vues greybox : cuvette rocheuse et bâche (niveau d'eau et tas de sel visibles), téléphone, palette (le tas grandit avec le stock), avion de livraison, caisse en parachute, bateau en bouteille.
  - Interface : catalogue au téléphone (panier, total, commander), HUD enrichi (litres retirés, heure, stock, mains, seau, invite, barre de remplissage).
  - Cycle jour/nuit et soleil. Touches de debug F5, F8, F9, F10.
  - 26 nouveaux tests (43 au total), dont la boucle complète et l'aller-retour de sauvegarde.
- **Pourquoi :** demande d'Othmane de continuer l'implémentation après validation de M0.
- **Impact :** `game/core/`, `game/data/`, `game/scenes/`, `game/localization/strings.csv`, `game/tests/`, PRD §6.3 et §19.4 (v0.10), section « Architecture et logique » ci-dessus.
- **Par :** Claude

### 2026-11-16 — NOTE — Règle de séchage proposée (à valider)
- **Quoi :** M-37 (« 45 s ») est lu comme : une zone pleine sèche en 45 s, donc un débit d'évaporation fixe par zone proportionnel à sa capacité. 10 L évaporés = 1 sel. Détail en PRD §6.3, marqué **[PROPOSÉ]**.
- **Pourquoi :** c'est la seule lecture où la surface compte, et elle donne le premier achat vers 3 min (M-01).
- **Impact :** `game/core/drying_logic.gd`, `game/data/game_config.tres`.
- **Par :** Claude

### 2026-11-16 — NOTE — Reprise automatique de l'emplacement 1 et touches de debug
- **Quoi :** tant qu'il n'y a pas de menu principal, le jeu charge l'emplacement 1 au démarrage. F9 recommence une partie. F5, F8, F10 servent à tester vite. Ces touches seront retirées ou cachées avant la démo.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Expliquer le code, et tenir l'architecture dans HANDOFF
- **Quoi :** Othmane veut qu'on lui explique comment le jeu est codé (la logique, pas le détail du code), et que l'architecture et la logique soient décrites dans ce fichier, tenues à jour à chaque étape.
- **Pourquoi :** choix d'Othmane.
- **Impact :** nouvelle section « Architecture et logique » ; règle ajoutée dans `CLAUDE.md`.
- **Par :** Othmane

### 2026-11-16 — NOTE — Rendu des captures d'écran en environnement sans carte graphique
- **Quoi :** les captures prises par Claude passent par le moteur de rendu « Compatibility » (OpenGL logiciel, llvmpipe), qui éclaire plus fort que Forward+ : le sable y paraît presque blanc. Sur un vrai PC (Forward+), le rendu sera différent. Lumière et matériaux greybox ont été atténués (lumière ambiante en couleur fixe, spéculaire bas).
- **Impact :** `game/scenes/main.tscn`.
- **Par :** Claude

### 2026-11-16 — NOTE — Erreurs normales au tout premier import
- **Quoi :** au premier `--import` d'un clone neuf, Godot affiche « Cannot open file res://localization/strings.*.translation » : les traductions ne sont générées qu'à la fin de cet import. Les lancements suivants n'ont plus l'erreur. Les fichiers `.translation` sont ignorés par Git.
- **Par :** Claude

### 2026-11-16 — TEST ÉCHOUÉ — Précision d'un seau sur un océan de 10¹⁸ L
- **Quoi :** `test_small_bucket_counts_on_huge_ocean` échouait : après avoir retiré 10 L sur 2,8 × 10¹⁸ L, `remaining_ratio()` vaut encore exactement 1.0 (10 L sont sous la précision d'un nombre à virgule 64 bits).
- **Cause :** limite des flottants, attendue. Le volume retiré, lui, est bien compté.
- **Correction :** ajout de `OceanModel.removed_ratio()`, calculé depuis le volume retiré, et le test vérifie celui-ci. Conséquence de conception : le pourcentage restant affiché restera à 100,0000000000 % très longtemps (c'est la blague), d'où l'importance des compteurs en litres et de la jauge à aiguille (N-10).
- **Impact :** `game/core/ocean_model.gd`, `game/tests/test_ocean_model.gd`.
- **Par :** Claude

### 2026-11-16 — MODIF — Jalon M0 : projet Godot, greybox, tests et CI
- **Quoi :**
  - Projet Godot 4.7.2 dans `game/` (Forward+, 1080p, FR/EN par CSV).
  - Logique de base : `GameConfig` (valeurs dans `data/game_config.tres`), `OceanModel` (volume retiré comme variable de vérité, drain à 5 %), `SaveSystem` (JSON versionné, écriture atomique, migration, 3 emplacements ; la sauvegarde manuelle écrase l'automatique), `GameState` (autoload : océan, stock des 5 ressources, chronomètre, sauvegarde auto toutes les 2 min et en quittant), `InputSetup` (actions en touches physiques : ZQSD sur AZERTY sans réglage).
  - Scène greybox `scenes/main.tscn` : île en CSG, rivage peu profond, fond plat, téléphone rouge, seau, cuvette rocheuse, palette de dépôt, 3 palmiers, rochers, océan, ciel et brouillard.
  - Joueur : marcher, courir (Maj), sauter (Espace), souris, 1re personne avec bascule 3e personne (V), Échap libère la souris.
  - HUD : % d'océan restant (10 décimales) et temps de partie.
  - Tests : lanceur maison `tests/run_tests.gd` + 17 tests (océan, sauvegarde, contrôles, HUD). CI GitHub Actions : import, tests, lancement de la scène.
  - `.gitattributes` : fichiers binaires (modèles, images, sons, polices) suivis par Git LFS.
- **Pourquoi :** feu vert d'Othmane pour M0, greybox uniquement.
- **Impact :** `game/`, `.github/workflows/ci.yml`, `.gitattributes`, `CLAUDE.md`, `README.md`, PRD §16.1 et §19.4.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Lancement du jalon M0 en greybox
- **Quoi :** Othmane demande de fusionner la PR des docs (fusionnée par Claude à sa demande) et de lancer le projet Godot. Pour les débuts : uniquement des greyboxes.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PR #1 fusionnée ; jalon M0.
- **Par :** Othmane

### 2026-11-16 — MODIF — PRD v0.8 : questions de suite intégrées
- **Quoi :** §4.1 (nourriture, eau douce, endurance, faim/soif), §6.1 (perle), §8.1 (bassin immense, volume 10¹⁸-10¹⁹ L, traversée finale mise en scène), §8.2 (jauge à aiguille), §9 (offres spéciales), §10 (noyade, fin secrète), §16.3 (terrain détaillé seulement autour de l'île), §19.1 (contenu du MVP, ajouts au catalogue, tourbillon retiré), §19.3 (décisions N-01 à N-10).
- **Pourquoi :** réponses d'Othmane aux questions de suite.
- **Impact :** `docs/PRD.md`, `docs/QUESTIONS_MVP.md`.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Questions de suite N-01 à N-10
- **Quoi :** N-01 pas de tourbillon lointain dans le MVP ; N-02 noix de coco + rations, eau douce par bâche de condensation ; N-03 pas de mort de faim/soif, l'endurance max baisse ; N-04 noyade = retour sur la plage sans perte ; N-05 endurance ~20 s course / ~60 s nage, ne remonte **jamais dans l'eau** ; N-06 bassin réellement immense (milliers de km), volume ~10¹⁸-10¹⁹ L ; N-07 perle ~2 % des coquillages, pour un objet spécial ; N-08 offre spéciale ~1 fois par jour ; N-09 brouette (T1) puis toboggan à sacs (T2) ; N-10 jauge à aiguille.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §4, §6, §8, §9, §10, §16, §19.
- **Par :** Othmane

### 2026-11-16 — MODIF — Formulaire des questions de suite (N-01 à N-10)
- **Quoi :** les questions N-01 à N-10 sont proposées dans un second formulaire web (copie : `docs/questions-suite.html`). L'envoi du premier formulaire a été vérifié : les réponses reçues correspondent au texte collé par Othmane.
- **Pourquoi :** même format que le questionnaire MVP, plus simple pour répondre.
- **Impact :** `docs/questions-suite.html`.
- **Par :** Claude

### 2026-11-16 — QUESTION — 10 nouvelles questions issues du questionnaire (N-01 à N-10)
- **Quoi :** incohérence M-67/M-84 (tourbillon lointain), nourriture et eau douce, conséquences de la faim/soif, noyade, endurance, taille du monde pour la fin secrète à la nage, perle, offres spéciales du téléphone, achat qui automatise le transport, jauge de niveau d'eau.
- **Pourquoi :** les réponses d'Othmane ajoutent la survie légère, la noyade, la fin à la nage, la perle et les offres spéciales, qui demandent des précisions.
- **Impact :** PRD §19.3.
- **Par :** Claude

### 2026-11-16 — MODIF — PRD v0.7 : réponses au questionnaire MVP
- **Quoi :** les 85 réponses sont listées en PRD §19.2 et reportées dans les sections concernées (§4.1 survie et jour/nuit, §5.5, §6.1 perle, §8.2 repère de niveau, §9 catalogue, délai de 5 s, maquettes, §10 nage et fin secrète, §16.3 machine de référence et origine flottante, §18 questions tranchées, §19.1 périmètre).
- **Pourquoi :** Othmane a répondu au questionnaire.
- **Impact :** `docs/PRD.md`, `docs/QUESTIONS_MVP.md`.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Réponses au questionnaire MVP (M-01 à M-85)
- **Quoi :** recommandations acceptées partout sauf : M-24 nage avec endurance et noyade ; M-25 pas de limite artificielle, fin secrète si on nage des milliers de km ; M-26 survie légère (endurance façon BotW, faim, soif) ; M-28 transport à la main puis automatisé par un achat ; M-31 pas de ralentissement avec le seau ; M-32 gouttes purement visuelles ; M-33/M-34 l'eau reversée sur le sable compte aussi comme rendue à l'océan ; M-45 perle dans le MVP ; M-51 livraison en 5 s ; M-54 offres spéciales au téléphone ; M-62 le niveau doit bouger un tout petit peu dans la démo avec un repère ; M-67 pas de tourbillon lointain ; M-68 HUD petit et comique ; M-78 sauvegarde manuelle qui remplace la dernière auto. Machine de référence (M-11) : i9, RTX 4 Go VRAM, ~12 Go RAM. Assets sur-mesure faits sous Blender plus tard (M-07). Détail complet : PRD §19.2.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §4, §6, §8, §9, §10, §16, §18, §19.
- **Par :** Othmane

### 2026-11-16 — MODIF — Questionnaire MVP en formulaire interactif
- **Quoi :** les 85 questions de `docs/QUESTIONS_MVP.md` sont aussi disponibles en formulaire web (recommandations pré-cochées, commentaires, enregistrement automatique, export texte). Copie de la page dans `docs/questionnaire-mvp.html`.
- **Pourquoi :** Othmane ne pouvait pas répondre facilement au format Markdown.
- **Impact :** `docs/questionnaire-mvp.html`.
- **Par :** Claude

### 2026-11-16 — QUESTION — Questionnaire MVP (M-01 à M-85)
- **Quoi :** création de `docs/QUESTIONS_MVP.md` : 85 questions regroupées par thème (périmètre, technique, contrôles, personnage, seau, séchage, ressources, téléphone, contenu du catalogue, monde, interface, audio, sauvegarde, hors MVP), chacune avec une recommandation. Tant qu'une question n'est pas tranchée, le prototype suit la recommandation.
- **Pourquoi :** Othmane veut tout décortiquer avant de construire le MVP/la démo.
- **Impact :** `docs/QUESTIONS_MVP.md`, PRD §18 et §19.
- **Par :** Claude

### 2026-11-16 — MODIF — PRD v0.6 : périmètre du MVP
- **Quoi :** §19.1 décrit le contenu du MVP/de la démo (T0-T2, île de départ, fin accessible en debug seulement, critère de réussite), et ce qui en est exclu ; Q-26 tranchée.
- **Pourquoi :** préparer la construction du MVP.
- **Impact :** PRD §11, §18, §19.
- **Par :** Claude

### 2026-11-16 — DÉCISION — « Plop » à sec ; succès décidés en fin de projet (Q-26)
- **Quoi :** si le joueur ouvre le drain après avoir tout vidé au seau, le drain fait juste un petit « plop ». Les succès (secrets ou non) seront décidés en fin de projet.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §11.
- **Par :** Othmane

### 2026-11-16 — MODIF — PRD v0.5 : reprise des sauvegardes finies et vidage manuel
- **Quoi :** §11 complétée (drain facultatif, derniers litres au seau ou par le drain, point de reprise avant le drain) ; ajout du problème P-18 et de la question Q-26 ; Q-25 retirée.
- **Pourquoi :** décisions d'Othmane.
- **Impact :** PRD §11, §17, §18.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Le drain est facultatif, mais les derniers litres se vident au seau ou par le drain
- **Quoi :** le joueur doit pouvoir vider le reste de l'océan sans ouvrir le drain s'il le veut. Les derniers litres ne peuvent partir qu'à la main (seau) ou par le drain, et les finir au seau doit être fastidieux.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §11 ; les machines doivent cesser de fonctionner sous un seuil (proposition).
- **Par :** Othmane

### 2026-11-16 — DÉCISION — Une sauvegarde terminée se rouvre juste avant le drain (Q-25)
- **Quoi :** recharger une partie finie ramène le joueur au fond de l'océan, juste avant d'ouvrir le drain.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §11 ; système de sauvegarde (point de reprise).
- **Par :** Othmane

### 2026-11-16 — MODIF — PRD v0.4 : texte dans les textures et fin de la run
- **Quoi :** §11 (banderole, écran du temps, retour au menu), §12 (règle du texte assouplie), §2, §4.4, §16.1, P-16, §18 (Q-23 et Q-24 retirées, ajout de Q-25), §19 mis à jour. Ajout d'un chronomètre de temps de jeu réel dans la sauvegarde **[PROPOSÉ]**.
- **Pourquoi :** décisions d'Othmane sur Q-23 et Q-24.
- **Impact :** PRD §2, §4.4, §11, §12, §16.1, §17, §18, §19, §20.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Fin de la run : temps affiché, générique, retour au menu (Q-24)
- **Quoi :** à la fin, le temps pris par le joueur s'affiche **avant** le générique ; après le générique, retour au menu et la run est terminée. Pas d'exploration après la fin.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §11.
- **Par :** Othmane

### 2026-11-16 — DÉCISION — Le texte dans les textures est permis, mais sobre (Q-23)
- **Quoi :** la banderole de l'avion final porte un slogan écrit. Ce n'est pas le seul texte : plusieurs textures auront besoin de texte, mais il doit rester rare et sobre. La règle « pas de lore à lire » (pas de livres, pas de notes) reste valable.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §11, §12. Remplace la proposition « aucun texte lisible dans le monde » de la v0.1.
- **Par :** Othmane

### 2026-11-16 — MODIF — PRD v0.3 : la fin du jeu
- **Quoi :** §11 réécrite avec la fin décidée ; Q-16 retirée ; ajout de Q-23 (banderole : texte ou pictogrammes, car le jeu n'a sinon aucun texte dans le monde) et Q-24 (retour au menu ou exploration libre après le générique) ; jalon M5 mis à jour.
- **Pourquoi :** décision d'Othmane sur Q-16.
- **Impact :** PRD §11, §18, §19.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Fin du jeu : l'avion publicitaire (Q-16)
- **Quoi :** une fois l'océan drainé, le joueur traverse l'océan asséché à pied. Un avion publicitaire passe juste au-dessus de lui : la banderole annonce que l'agence de livraison qu'il utilisait est maintenant aussi une société de transport, qui peut vous emmener de n'importe où à n'importe où. Le joueur le voit en marchant, puis générique. Fin.
- **Pourquoi :** choix d'Othmane ; dernier gag qui répond à « pourquoi l'agence ne m'emmène pas ? ».
- **Impact :** PRD §11.
- **Par :** Othmane

### 2026-11-16 — MODIF — PRD v0.2 : intégration des décisions et vocabulaire « drain »
- **Quoi :** PRD passé en v0.2. Q-01, Q-07 et Q-13 passées en **[DÉCIDÉ]** et retirées de la liste des questions. Le mot « bonde » est remplacé par « **drain** » partout (terme d'Othmane), la §6.2 explique concrètement le troc, et Q-16 est reformulée avec des options concrètes (générique direct, exploration libre, épilogue comique, partir vraiment, mode infini).
- **Pourquoi :** réponses d'Othmane ; la question « après la bonde » n'était pas claire.
- **Impact :** PRD §1, §6.2, §10, §11, §15, §18.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Caméra : première personne avec bascule en troisième personne (Q-13)
- **Quoi :** la caméra principale est à la première personne ; le joueur peut basculer en troisième personne à tout moment.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §10. Il faut à la fois des bras/objets en vue subjective et un personnage complet animé.
- **Par :** Othmane

### 2026-11-16 — DÉCISION — Économie en troc direct (Q-07)
- **Quoi :** pas de monnaie ; chaque article du catalogue se paie directement en ressources (sel, minéraux, minéraux rares, coquillages).
- **Pourquoi :** choix d'Othmane, sur recommandation (chaque ressource garde sa valeur, plus lisible).
- **Impact :** PRD §6.2.
- **Par :** Othmane

### 2026-11-16 — DÉCISION — Jeu principal en 3D low-poly, style *How to Fish* (Q-01)
- **Quoi :** le jeu PC est en 3D low-poly, dans le même esprit visuel que *How to Fish*.
- **Pourquoi :** choix d'Othmane.
- **Impact :** PRD §1, §10, §15.
- **Par :** Othmane

### 2026-11-16 — MODIF — Création du dépôt et des documents fondateurs
- **Quoi :** commit initial (`README.md`) sur `main`, puis création de `docs/PRD.md` (v0.1), `HANDOFF.md`, `CLAUDE.md` et `.gitignore` (Godot 4) sur une branche dédiée, proposés en pull request.
- **Pourquoi :** formaliser le jeu avant toute ligne de code, à la demande d'Othmane.
- **Impact :** tout le dépôt.
- **Par :** Claude

### 2026-11-16 — QUESTION — 22 questions ouvertes listées dans le PRD
- **Quoi :** l'analyse de l'idée a fait ressortir 22 décisions à prendre (Q-01 à Q-22), chacune avec options et recommandation, ainsi que 17 problèmes de conception (P-01 à P-17) et 10 problèmes techniques (T-01 à T-10).
- **Pourquoi :** les propositions du PRD marquées **[PROPOSÉ]** ne deviennent des décisions qu'après validation d'Othmane.
- **Impact :** PRD §17 et §18.
- **Par :** Claude

### 2026-11-16 — DÉCISION — Fonctionnalités de base du jeu (énoncées par Othmane)
- **Quoi :** les éléments suivants sont décidés et font foi :
  - **Concept :** le joueur se réveille sur une île entourée d'océan à perte de vue. Il n'y a que lui, un téléphone rouge (style téléboutique) et un seau. Personne ne viendra l'aider ; il doit vider l'océan pour passer. Le problème : l'océan est trop grand.
  - **Téléphone :** il ne contacte qu'une agence de livraison, qui ne livre que des objets (pas de personnes). Aucun autre contact possible.
  - **Seau :** il sert à prendre l'eau de l'océan et à la mettre ailleurs pour qu'elle sèche.
  - **Ressources :** le séchage donne des items qui servent de monnaie. Peu d'items : sel, quelques minéraux, minéraux rares, coquillages.
  - **Échanges :** on commerce via le téléphone ; l'agence vient prendre le dépôt et dépose la livraison par avion, rapidement et de façon comique, sans attendre le joueur.
  - **Progression :** les achats permettent de vider plus vite grâce à des technologies de plus en plus poussées, jusqu'à de grandes machines.
  - **Fin :** quand il reste 5 % d'eau ou moins, un drain est visible au fond de l'océan ; le joueur peut simplement l'ouvrir pour vider le reste. C'est censé être drôle.
  - **Lore :** pas d'histoire à proprement parler. Uniquement des clins d'œil pour les joueurs attentifs, compréhensibles à l'œil. Pas de livres ni de textes à lire.
  - **Plateformes :** la version principale est sur PC (Windows). Elle contient un mini-jeu du même concept en clicker, pixel art très simple. Ce clicker sera ensuite porté sur téléphone, beaucoup plus tard.
  - **Moteur :** Godot.
- **Pourquoi :** vision d'origine du jeu.
- **Impact :** PRD §1, §3, §4, §6, §7, §9, §11, §12, §13, §14, §16.
- **Par :** Othmane

### 2026-11-16 — DÉCISION — Organisation de la documentation : PRD + HANDOFF
- **Quoi :**
  - `docs/PRD.md` est la **source unique de vérité** de toutes les fonctionnalités du jeu et du tech stack.
  - `HANDOFF.md` (ce fichier) est le **journal vivant** du projet : **toute décision prise, toute modification et tout test qui ne fonctionne pas doivent y être ajoutés automatiquement.** Cette règle elle-même y est consignée (cette entrée).
  - Aucune ligne de code n'est écrite avant que les fonctionnalités soient formalisées dans le PRD.
  - `CLAUDE.md` impose ces règles aux sessions d'IA qui travaillent sur le dépôt.
- **Pourquoi :** garder une trace complète de l'historique des choix et éviter de refaire les mêmes débats ou les mêmes erreurs.
- **Impact :** `docs/PRD.md`, `HANDOFF.md`, `CLAUDE.md`.
- **Par :** Othmane
