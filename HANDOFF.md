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

- **Phase :** PR #2 à #5 fusionnées (M0, M2, retours de test, survie légère). Correctifs et début de T2 en PR #6, fusionnée directement à la demande d'Othmane. Déplacement des objets sur une grille (rotation, palette déplaçable, cases libres pour tout ce qui apparaît) en PR #7, fusionnée à la demande d'Othmane. PR #8 : vérification des cases avant toute apparition, mode déplacement automatique à l'ouverture d'une caisse, CI plus stricte. PR #9 : pompe à bras et tuyaux. PR #10 : moulin-pompe et fin de la démo.
- **Documents :** PRD v0.20. Guide du code : `docs/GUIDE_CODE.md`. Décisions du MVP en PRD §19.2 et §19.3.
- **Ce qui marche :** la boucle complète *puiser → verser dans la cuvette → attendre le séchage → récolter → porter à la palette → commander au téléphone → avion → caisse en parachute → ouvrir → objet posé*. Premier achat vers 1 min 30. Nage avec endurance, noyade et retour sur la plage. Catalogue : bâche, grand seau, brouette, tongs, râteau, palanche, bateau en bouteille. Jauge à aiguille du niveau d'eau. Cycle jour/nuit de 20 min avec lune. Tas de sel à côté des zones. Paiement avec les bras + la palette. Outils admin dans `game/admin/`. Faim et soif, noix de coco, rations, bâche de condensation, coquillages chaque matin. Palette à un tas par ressource. Manuel du bricoleur → T2 : bassin en bois, miroir solaire. Sauvegarde de toute la partie. Déplacer et tourner les objets posés, palette comprise (G, R, grille de 1 m, vert/rouge). Pompe à bras (clic maintenu, 20 L/s) et tuyaux de 4 m qui se branchent tout seuls aux zones les plus proches. Moulin-pompe (10 L/s tout seul) et écran de fin de démo. 136 tests.
- **À valider par Othmane :** la règle de séchage et le rendement de 4 L par sel (PRD §6.3), les détails de la nage (§10), la jauge logarithmique (§8.2), le prix de la brouette (30 sel), les détails du placement sur grille (§10 : cases de 1 m, emprises, quart de tour avec R).
- **Prochaine étape :** la barre d'outils (M-27), et la fin de M1 (shader d'eau, terrain de fond, mesure de perf).
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
- **Récolter et porter :** le dépôt d'une zone s'affiche comme un **tas à côté d'elle**, qui grossit avec la quantité. E sur le tas : 3 unités passent dans les mains (les plus rares d'abord), ou tout le tas avec le râteau. Le clic sur la zone ne sert qu'à verser. On porte 10 unités au maximum (40 avec la brouette). Ce qui ne rentre pas reste dans la zone.
- **Déposer :** E sur la palette de dépôt : tout ce qui est porté passe dans le **stock**. Seul le stock de la palette sert à payer (troc).
- **Commander :** E sur le téléphone : le catalogue s'ouvre (le jeu ignore alors les touches du joueur). On remplit un panier (articles identiques regroupés « ×N ») ; « Commander » vérifie qu'on peut payer avec les bras + la palette, retire le prix des bras d'abord puis de la palette, marque les objets uniques comme possédés et crée une **caisse**.
- **Livrer :** un avion traverse le ciel, passe au-dessus de la palette, largue la caisse qui descend en parachute (5 s au total). Les caisses successives tombent en spirale autour du point de livraison pour ne pas s'empiler.
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

- L'île est découpée en **cases de 1 m**. Chaque objet posé a une **emprise** : un cercle autour de son centre (2 m pour la cuvette, 3 m pour le bassin, 0,7 m pour le miroir…), réglée dans les données.
- Une place est valide si l'emprise reste sur le sable sec (moins de 19,5 m du centre de l'île) et ne touche ni un autre objet posé, ni un élément fixe (téléphone, palette, palmiers, rochers, repère d'eau, listés dans les données).
- En jeu : viser un objet + **G**. L'objet lui-même sert d'aperçu et suit le regard case par case ; un disque vert ou rouge montre son emprise et la grille s'affiche autour. Clic = poser (GameState vérifie encore et annonce « objet déplacé ») ; G ou Échap = annuler. Pendant ce mode, le seau et E sont coupés.
- **R** tourne l'objet d'un quart de tour pendant le déplacement. L'orientation est dans l'état de l'objet, comme sa position.
- La **palette** se déplace comme le reste ; le téléphone reste fixe.
- Tout ce qui apparaît tout seul prend une case libre : une caisse livrée ou un objet qui en sort va sur la case libre la plus proche de l'endroit prévu ; un coquillage tombe au centre d'une case libre de la plage ; le tas de sel d'une zone a sa propre case, à l'intérieur de l'emprise de la zone (il tourne avec elle). Les noix de coco au pied des palmiers bloquent aussi leur place.
- Avant d'apparaître, tout regarde ce qui est déjà là : objets posés, caisses (même encore en vol), coquillages, places des noix de coco, éléments fixes, et le joueur. S'il n'y a plus de place, rien n'apparaît. Une noix de coco ne repousse pas sous un objet.
- Ouvrir une caisse qui contient des objets à poser enchaîne le mode déplacement pour chacun, l'un après l'autre.
- La position et l'orientation sont sauvegardées, et les miroirs déplacés boostent les zones de leur nouvel emplacement.

### Pompes et tuyaux (T2)

- La pompe à bras se pose au bord de l'eau. Clic maintenu : elle aspire 20 L/s dans l'océan, mais seulement ce que les zones reliées peuvent recevoir (jamais un litre perdu).
- Les tuyaux sont un stock de tronçons de 4 m. Le réseau se calcule tout seul à chaque changement : pompe par pompe, on relie les zones de la plus proche à la plus lointaine tant qu'il reste assez de tronçons pour atteindre leur bord.
- L'eau remplit la zone la plus proche d'abord. Les tuyaux sont dessinés de la pompe au bord de chaque zone reliée.
- Le moulin-pompe est une pompe « automatique » : la même étape qui fait vivre le monde le fait pomper (10 L/s), sans le joueur. On compte ce qu'il a pompé ; à 200 L, c'est la fin de la démo (une seule fois, mémorisée dans la sauvegarde).

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

---

## Journal

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
