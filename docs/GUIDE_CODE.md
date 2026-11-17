# Guide du code — Drain the Ocean

> Comment chaque idée du jeu est implémentée **côté code** : quels fichiers, quels nœuds, quels signaux, quel chemin suivent les données.
> Complète la section « Architecture et logique » de [`HANDOFF.md`](../HANDOFF.md) (qui reste sans code). Mis à jour à chaque version (section « Par version » en bas).
> Tous les chemins sont relatifs à `game/`.

---

## 1. Les fondations

### Démarrage du jeu

1. Godot lit `project.godot`. La scène principale est `scenes/main.tscn`.
2. Avant la scène, Godot crée les **autoloads** (des nœuds globaux toujours présents, accessibles par leur nom partout dans le code) :
   - `InputSetup` (`core/input_setup.gd`) : déclare les actions de contrôle.
   - `GameState` (`core/game_state.gd`) : l'état de la partie.
   - `Admin` (`admin/admin_tools.gd`) : les touches de triche.
3. La scène `main.tscn` se charge. Son script `scenes/main.gd` appelle `GameState.continue_or_new()` : reprendre l'emplacement 1, sinon nouvelle partie.

### Les contrôles en touches physiques

- `InputSetup.register_defaults()` crée des **actions** (`move_forward`, `jump`, `interact`, `use_tool`…) dans l'`InputMap` de Godot.
- Chaque action est liée à un `physical_keycode` : la **position** de la touche, pas la lettre. La touche W d'un QWERTY est à la place du Z d'un AZERTY, donc ZQSD marche sans réglage.
- Le reste du code ne parle jamais de touches, seulement d'actions : `Input.is_action_pressed(&"sprint")`.

### Les données d'équilibrage

- `core/game_config.gd` déclare une classe `GameConfig` (une `Resource`) avec des variables `@export` : volume de l'océan, temps de séchage, vitesses, endurance…
- Les **valeurs** sont dans `data/game_config.tres`, un fichier texte que l'éditeur Godot sait modifier. Le code lit toujours `GameState.config.xxx`, jamais un chiffre en dur.
- Le catalogue suit le même principe : `core/catalog_item.gd` (un article : id, prix, effet…) et `core/catalog_database.gd` (la liste), avec les valeurs dans `data/catalog.tres`.

### Les traductions

- `localization/strings.csv` : une ligne par clé (`HUD_STOCK,Palette,Pallet`). Godot génère les fichiers `.translation` à l'import.
- Dans le code, on écrit `tr("HUD_STOCK")`, qui renvoie le texte dans la langue active.

### Les sauvegardes

- `core/save_system.gd` (classe `SaveSystem`, fonctions statiques) : écrit un **dictionnaire** en JSON dans `user://saves/slot_N.json`.
- Écriture **atomique** : on écrit dans `slot_N.json.tmp`, puis on renomme. Si le jeu plante pendant l'écriture, l'ancienne sauvegarde reste intacte.
- Chaque fichier porte un `save_version`. `migrate()` met à jour les vieilles sauvegardes quand le format change.
- Le dictionnaire vient de `GameState.to_dict()`, et revient par `GameState.load_dict()`.

### Les tests et la CI

- `tests/run_tests.gd` est un script qui remplace la boucle principale de Godot (`extends SceneTree`). Il charge chaque `tests/test_*.gd`, appelle chaque méthode `test_*`, compte les échecs et quitte avec un code d'erreur s'il y en a.
- `tests/test_case.gd` (classe `TestCase`) fournit `assert_true`, `assert_eq`, `assert_almost`, et `before_each` / `after_each`.
- `.github/workflows/ci.yml` : sur chaque PR, GitHub télécharge Godot 4.7.2, importe le projet, lance les tests, puis lance la scène principale 120 images (test de fumée : la scène démarre sans erreur).

---

## 2. Le motif central : logique pure → GameState → vues

```
data/*.tres ──► GameConfig / CatalogDatabase
                       │
core/*_logic.gd ◄──── GameState (autoload) ────► signaux ────► vues (scenes/…)
  (règles pures)        │  ▲                                     │
                        │  └──────────── appels de fonctions ◄───┘
                        ▼
                  SaveSystem (JSON)
```

- **Logique pure** (`core/*_logic.gd`, `economy.gd`, `ocean_model.gd`) : des classes `RefCounted` (de simples objets, pas des nœuds de scène). Elles ne touchent ni à l'écran ni au son. Exemple : `DryingLogic.step(delta, multiplicateur, rng)` fait évaporer l'eau et ajoute du sel au dépôt.
- **GameState** possède une instance de chaque objet logique et des dictionnaires (stock, bras, zones, caisses…). Les vues l'appellent (`GameState.fill_bucket()`), il modifie l'état puis **émet un signal** (`bucket_changed`, `stock_changed`…).
- **Vues** : des nœuds 3D ou d'interface. Elles se branchent sur les signaux (`GameState.stock_changed.connect(_refresh)`) ou relisent l'état à chaque image dans `_process`.
- Un objet du monde est **interactif** s'il a les méthodes `get_prompt(player)` (le texte affiché), `use(player)` (clic, l'outil) ou `interact(player)` (E, les mains). Le joueur ne connaît pas les types d'objets : il demande seulement « as-tu cette méthode ? » (`has_method`). Ajouter un objet interactif ne demande donc aucune modification du joueur.

---

## 3. Chaque idée, côté code (M0 → PR #7)

### Le monde greybox

- `scenes/main.tscn` contient l'île (cylindres CSG avec collision : `Island/Top`, `Shore`, `Seabed`), les palmiers et rochers, le téléphone, la palette, le plan d'eau `Ocean`, le joueur, le HUD et le catalogue.
- `scenes/world/greybox.gd` (classe `Greybox`) : des fabriques statiques (`box`, `cylinder`, `box_collision`…) et la palette de couleurs. Toutes les vues construisent leurs formes avec, en code, sans modèle 3D.

### Le joueur (`scenes/player/player.gd`, un `CharacterBody3D`)

- **Déplacement** (`_physics_process`) : on lit `Input.get_vector(...)`, on le tourne selon l'orientation du joueur, on mélange en douceur la vitesse actuelle vers la vitesse voulue (`lerpf`), puis `move_and_slide()` gère les collisions. Sauter = donner une vitesse verticale si `is_on_floor()`.
- **Souris** (`_unhandled_input`) : le mouvement horizontal tourne tout le corps ; le vertical tourne seulement la tête (`Head`), limité à ±85°.
- **1re / 3e personne** : deux caméras, `Head/FirstPersonCamera` et `Head/SpringArm/ThirdPersonCamera`. V change laquelle est `current`. Le `SpringArm3D` rapproche la caméra si un mur est derrière.
- **Visée** (`_find_target`) : un rayon part du centre de la caméra active (`intersect_ray`). Si l'objet touché a `get_prompt`, il devient la cible ; le HUD affiche son invite.
- **Outil** (`_handle_tool`), par priorité : la cible a `use()` → on l'appelle au clic ; sinon, dans l'eau et seau pas plein → maintenir le clic remplit ; sinon, seau non vide → clic vide le seau.

### L'océan et le niveau de l'eau

- `core/ocean_model.gd` garde le **volume retiré** (pas le restant). Raison : 2,8 × 10¹⁸ − 10 = 2,8 × 10¹⁸ en nombres à virgule ; les 10 L disparaîtraient. Le volume retiré, lui, part de 0 et compte chaque litre.
- `level_drop_m(surface)` = volume retiré (m³) ÷ surface (m²). `GameState.water_level_y()` = niveau de la mer − cette baisse.
- `main.gd` place le plan `Ocean` à cette hauteur à chaque image, et le décale avec la caméra (par pas de 100 m) pour qu'on n'en voie jamais le bord.
- `scenes/world/water_gauge.gd` (classe `WaterGauge`) : le cadran. `needle_ratio()` convertit la baisse en position d'aiguille par un logarithme (chaque graduation = ×10). `format_drop_mm()` écrit la vraie valeur (« −3,5 × 10⁻¹³ mm »).

### Le seau

- `core/bucket_logic.gd` : contenance, eau, et `hold_fill(delta)` qui accumule le temps de clic et renvoie vrai quand le remplissage (1 s) est fini.
- `GameState.fill_bucket()` : retire les litres de l'océan (`ocean.remove_water`), remplit le seau, et tire au sort coquillage et perle avec `rng`.
- `GameState.pour_bucket_out()` : l'eau retourne à l'océan (`ocean.return_water`).

### Le séchage

- `core/drying_logic.gd` : une zone a `capacity_l`, `dry_time_s`, `water_l` et un `deposit` (dictionnaire `{"sel": 4, ...}`).
- `step()` : évapore `capacité ÷ temps × multiplicateur × delta` litres, les ajoute à un compteur, et chaque fois que le compteur dépasse `liters_per_salt` (4 L), ajoute 1 sel et tire au sort minéraux et minéraux rares.
- `GameState._process` appelle `simulate(delta)`, qui fait avancer **tout ce qui vit avec le temps** : l'heure (et le matin), toutes les zones de séchage, les objets à portions, la faim et la soif. C'est pour ça que le séchage continue même loin du joueur.
- `advance_time(secondes)` appelle `simulate()` par pas de 5 s : l'avance rapide (F6) fait donc vivre tout le monde, pas seulement l'horloge.
- Le multiplicateur d'une zone = jour/nuit × `zone_boost(zone)`. `zone_boost` compte les miroirs solaires à moins de 6 m (+50 % chacun).
- Une zone dans GameState = `{id, kind, position, logic}`. `add_zone()` la crée et émet `zone_added(zone)`.
- `scenes/world/drying_zone_view.gd` : `main.gd` reçoit `zone_added` et crée cette vue. Elle construit la cuvette ou la bâche, et à chaque image règle la hauteur de son disque d'eau selon `logic.fill_ratio()`.
- Le **tas de sel** est une classe interne `SaltPile` (un `StaticBody3D` à côté de la zone). Il grossit avec le dépôt, désactive sa collision quand il est vide, et son `interact()` appelle `GameState.harvest(zone)`.

### Récolter, porter, déposer, payer

- `GameState.carried` (les bras) et `GameState.stock` (la palette) sont deux dictionnaires de ressources. `core/economy.gd` regroupe les opérations : `add`, `count`, `can_afford`, `pay_from`.
- `harvest(zone)` prend 3 unités du dépôt (`take_some`, les plus rares d'abord), ou tout avec le râteau, dans la limite de `carry_space()`. Ce qui ne rentre pas retourne dans le dépôt.
- `scenes/world/depot.gd` (la palette) : `interact()` appelle `unload_to_stock()`, qui vide les bras dans le stock. La palette a un emplacement par ressource (boucle sur `Economy.RESOURCES`) : un tas coloré dont la hauteur suit `pile_height()` (logarithme, plafonnée à 1,5 m), le nombre au-dessus (un `Label3D` toujours tourné vers la caméra) et le nom peint devant. Le tout se rafraîchit sur `stock_changed`.
- `order(ids)` : `Economy.pay_from([carried, stock], prix)` vérifie d'abord la **somme** des deux, puis retire des bras, puis de la palette.

### Le téléphone, le catalogue, la livraison

- `scenes/world/phone.gd` : `interact()` appelle `open_catalogue` sur le groupe `"catalogue"`. Un groupe est une étiquette sur des nœuds : on peut les appeler sans connaître leur chemin dans la scène.
- `scenes/ui/catalogue.gd` (un `CanvasLayer`) : construit le panneau en code (une ligne par `CatalogItem`). Ouvert, il met `GameState.ui_open = true` (le joueur ignore alors ses touches) et libère la souris. Le panier est une liste d'ids ; `CatalogueFormat.format_cart()` les regroupe en « Nom ×N ».
- « Commander » → `GameState.order(panier)` : paie, marque les objets uniques comme possédés, puis crée **une caisse par objet à poser** (`is_placeable()` : zone, station, miroir, décor, pompe) et une seule caisse pour tout le reste (améliorations, tuyaux). Chaque caisse `{id, position, items, delay_s}` prend une case libre avec `next_drop_position()` ; `delay_s` = rang × `config.crate_stagger_s`. `order()` renvoie la liste (vide si la commande est refusée) et émet `crate_added(caisse, true)` pour chacune.
- `main.gd` reçoit ce signal, attend `delay_s` (les avions passent l'un après l'autre) et crée une `CrateView` cachée et un `DeliveryPlane`. L'avion suit une trajectoire animée (`Tween`) : il passe au-dessus de la palette puis du point de largage, et émet `dropped`. Alors la caisse apparaît et descend en parachute (`drop_from`, un autre `Tween`) jusqu'à `rest_position()` : 5 rayons tirés vers le bas (centre et 4 coins), on garde le point le plus haut, donc une caisse qui tombe sur un objet reste posée dessus.
- E sur la caisse posée → `GameState.open_crate()` → `apply_item()` pour chaque objet, selon son `effect` :
  - `DRYING_ZONE` : `add_zone("bache", position)` ;
  - `BUCKET_CAPACITY` (grand seau), `BUCKET_COUNT` (palanche), `CARRY_CAPACITY` (brouette), `WALK_SPEED` (tongs), `RAKE` (râteau) : changent une caractéristique de GameState ;
  - `DECOR` : ajoute un décor (le bateau en bouteille, `decor_view.gd`).
- Puis `crate_removed` : `main.gd` supprime la vue de la caisse.

### Nage et endurance

- `core/stamina_logic.gd` : une valeur de 0 à 1. `step(delta, activité)` la baisse (course, nage), la monte (repos sur terre) ou la laisse (marche). `exhausted` bloque la course jusqu'à 25 %.
- Dans `player.gd`, `swimming` est vrai si les pieds sont à plus de 1,2 m sous `water_level_y()`. Dans ce cas, la gravité est remplacée par `_swim_vertical()` : une vitesse qui ramène doucement le corps vers la profondeur de flottaison. Espace pousse vers le haut. Contre un mur (`is_on_wall()`) en avançant, on monte : c'est l'escalade du rivage.
- Endurance à zéro en nageant → `_drown()` : un `Tween` fait passer un rectangle noir plein écran à opaque, téléporte le joueur au point de départ, remplit l'endurance, puis refait la lumière.
- `scenes/ui/hud.gd` affiche une barre d'endurance quand elle n'est pas pleine.

### Le jour, la nuit, le ciel

- `core/day_cycle_logic.gd` : un temps de 0 à `day_length_s` (1 200 s) → une heure (0-24 h), `is_day()` (6 h-20 h), le multiplicateur d'évaporation et la hauteur du soleil en degrés.
- `main.gd` (`_update_sun`) tourne la lumière `Sun` selon cette hauteur, l'éteint sous l'horizon et baisse la lumière ambiante. La lune est une deuxième lumière, plus faible et bleutée, tournée à l'opposé, plus une sphère blanche « non éclairée » placée à 4 km de la caméra dans sa direction.

### Le HUD

- `scenes/ui/hud.tscn` + `hud.gd` : des `Label` en haut à gauche, rafraîchis par signaux (`ocean_changed`, `stock_changed`…), et l'invite au centre, lue sur `player.prompt` à chaque image.
- `format_liters()` écrit les gros nombres (k, M, Md, T).

### Les paliers (T2)

- Chaque `CatalogItem` a un `tier`. `GameState.unlocked_tier` vaut 1 ; l'effet `UNLOCK_TIER` du Manuel du bricoleur le passe à 2.
- `is_unlocked(item)` = `item.tier <= unlocked_tier`, et `can_buy()` l'exige. Le catalogue garde chaque ligne en mémoire (`_item_rows`) et grise celles d'un palier verrouillé, en remplaçant la description par « Requiert le Manuel du bricoleur ».
- Bassin en bois : une zone de séchage de plus (`kind = "bassin_bois"`) ; `add_zone()` lui donne 200 L, et `drying_zone_view.gd` la dessine.
- Miroir solaire : l'effet `MIRROR` appelle `add_mirror(position)`, qui l'ajoute à `mirrors` et émet `mirror_added` ; `main.gd` crée `mirror_view.gd`. Le miroir n'a aucune logique propre : c'est `zone_boost()` qui le compte.

### La survie légère et la plage

- `core/survival_logic.gd` (classe `SurvivalLogic`) : `food` et `water` de 1 à 0. `step()` les fait baisser ; seul le temps passé **à zéro** fait grandir une pénalité. `stamina_cap()` = 1 − pénalités. `eat()` / `drink()` remontent le besoin et effacent sa pénalité.
- Chaque image, `GameState._process` appelle `survival.step()`, puis `stamina.set_max(survival.stamina_cap())` : c'est le seul lien entre faim/soif et endurance.
- `core/station_logic.gd` (classe `StationLogic`) : un objet à portions. Avec une période (> 0), il produit une portion à chaque période jusqu'à sa capacité (la bâche de condensation). Sans période, il ne fait que se vider (la caisse de rations) ; `is_spent()` dit quand le retirer.
- Dans GameState :
  - `pickups` : les petits objets à ramasser `{id, kind, position}` (noix de coco, coquillages). `_morning_refill()` remet une noix sur chaque emplacement vide (`config.coconut_spots`) et complète la plage jusqu'à 5 coquillages, à des positions tirées au hasard sur un anneau. Appelé à la nouvelle partie et à chaque passage de 6 h.
  - `take_pickup()` : la noix est mangée tout de suite ; le coquillage va dans les bras (2 % de perle).
  - `stations` : `{id, kind, position, logic: StationLogic}`, créés par l'effet `STATION` d'un article du catalogue ; `use_station()` boit ou mange une portion.
  - Signaux : `pickup_added/removed`, `station_added/removed`, `survival_changed`.
- `main.gd` crée les vues `scenes/world/pickup_view.gd` et `station_view.gd` sur ces signaux, et les retient par id pour les supprimer. Les deux vues n'ont que `get_prompt()` et `interact()` (E).
- Le HUD affiche « Faim : ▮▮▮▯▯ · Soif : ▮▯▯▯▯ », en rouge quand un besoin est vide.

### Déplacer les objets (grille)

- `core/placement_grid.gd` (classe `PlacementGrid`, logique pure, deux fonctions statiques) :
  - `snap(pos, cell)` ramène un point au **centre** de sa case (`snappedf` décalé d'une demi-case) ;
  - `is_valid(pos, radius, others, build_radius)` : en 2D (X, Z), l'emprise doit tenir dans le cercle constructible et ne toucher aucun cercle de `others` (distance < somme des rayons = chevauchement).
- Données (`GameConfig`, groupe « Placement ») : `grid_cell_m`, `build_radius_m`, `footprints` (type → rayon ; rectangle depuis 0.1.5, voir plus bas), `fixed_obstacles` (un `PackedVector3Array` où chaque élément est `(x, z, rayon)`).
- Dans GameState :
  - `movable_items()` = zones + stations + miroirs + décors : tous des dictionnaires `{id, kind, position…}`. Les décors ont maintenant un `id`, les miroirs un `kind = "miroir"`, pour être traités pareil.
  - `blockers_for(item)` : les emprises de tous les AUTRES objets + les obstacles fixes. `can_place(item, pos)` appelle `PlacementGrid.is_valid`.
  - `move_item(item, pos)` : aligne, garde la hauteur d'origine, vérifie, écrit `item.position` et émet `item_moved`. Comme la position vit dans le dictionnaire, la sauvegarde et `zone_boost()` (miroirs) suivent sans code en plus.
  - `placing` : vrai pendant le mode déplacement ; `player.gd` s'arrête alors au début de `_process` (pas de seau, pas de E).
- Les vues déplaçables (`drying_zone_view`, `station_view`, `mirror_view`, `decor_view`) exposent `get_movable()` (duck typing, comme `get_prompt` / `interact`). `player.gd` ajoute « [G] Déplacer » à l'invite de tout objet visé qui l'a.
- `scenes/world/placement_controller.gd` (classe `PlacementController`, créé par `main.gd`) :
  - G sur un objet visé → `start(view)` : retient la vue et son dictionnaire, met `placing` à vrai.
  - Chaque image, `_follow_aim()` tire un rayon depuis la caméra (14 m) en excluant le joueur ET la vue déplacée (sinon le rayon toucherait l'objet lui-même), aligne le point touché, demande `can_place`, déplace la vue (elle sert d'aperçu), colore le disque d'emprise (`CylinderMesh`) et redessine la grille avec un `ImmediateMesh` en lignes.
  - Clic → `confirm()` → `GameState.move_item`. G ou souris libérée (Échap) → `cancel()` : la vue reprend `item.position`.
  - Il est ajouté à la scène après le joueur, donc traité après lui dans la même image : le clic qui pose l'objet ne vide pas aussi le seau.
- `main.gd` retient aussi les zones et décors par id (`_spawn_view`) et, sur `item_moved`, recale la vue : position ET `rotation_degrees.y` (utile au chargement et si un autre code que le contrôleur déplace un objet).
- **Rotation** : chaque dictionnaire déplaçable peut avoir `rotation_deg`. `move_item(item, pos, rotation_deg = NAN)` : NAN veut dire « garder l'orientation ». Dans le contrôleur, R ajoute `config.rotation_step_deg` à l'angle d'aperçu ; `confirm()` le passe à `move_item`. Les emprises sont des cercles : tourner ne change donc jamais la validité.
- **Palette** : `GameState.depot = {id: "depot", kind: "palette", position, rotation_deg}`, dans `movable_items()`. Sa vue reste le nœud `Depot` de `main.tscn` (`depot.gd` a `get_movable()`), et `_on_item_moved` la reconnaît à son id. `_emit_all()` émet `item_moved(depot)` pour la remettre en place après une nouvelle partie ou un chargement.
- **Tout ce qui apparaît prend une case** : `find_free_spot(radius, near)` part de la case de `near` et teste des carrés de plus en plus grands avec `PlacementGrid.is_valid` contre `_blockers_except({})` (objets, caisses au sol, obstacles fixes, noix de coco). Appelé par `next_drop_position()` (caisses), `apply_item()` (objets posés) et `new_game()` (cuvette). `_random_beach_spot()` aligne le coquillage et retire au sort s'il tombe sur quelque chose.
- **Vérifier avant d'apparaître** : `_blockers_except(item, with_coconut_spots)` liste tout ce qui gêne, y compris les coquillages et `player_position` (que `player.gd` met à jour à chaque image physique). `_random_beach_spot()` renvoie `NO_SPOT` (infini) après 40 essais ratés, et `_morning_refill()` saute alors le coquillage ; une noix ne revient que si `_spot_is_free()`.
- **Mode G automatique** : `apply_item()` renvoie l'objet posé (ou `{}`), `open_crate()` émet `placement_requested(obj)` pour chacun. `PlacementController.request()` les met dans `_queue` ; à chaque image, s'il n'est pas déjà en train de déplacer et que la souris est capturée, `_start_next_in_queue()` prend le suivant (en sautant ceux qui ont disparu) et retrouve sa vue avec `view_for` (fourni par `main.gd`).
- **Tas de sel** : `GameState.pile_offset(zone)` = nombre entier de cases (`config.pile_offset_cells`) le long de l'axe X local. `drying_zone_view._add_pile()` s'en sert ; le tas est un enfant de la vue, donc il tourne avec elle. Les emprises des zones l'englobent, donc il ne peut pas toucher un autre objet.

### Pompes et tuyaux (T2)

- **Tuyaux posés à la main (PR #12).** Chaque pièce est une case 3D : `Vector3i(x, niveau, z)`, `x`/`z` = case de la grille au sol, `niveau` = 0 (au sol) à `config.pipe_max_level`. GameState garde `pipes` (dictionnaire case → vrai, un ensemble) et `pipe_stock` (pièces pas encore posées, +5 par lot acheté).
- `core/pipe_network.gd` (classe `PipeNetwork`, logique pure, fonctions statiques) :
  - `cell_of(pos)` / `cell_center(cell, cell_m, ground_y)` : passage case ↔ position 3D ;
  - `neighbors(cell, cells)` : les pièces voisines parmi les 6 directions (`DIRS`) ;
  - `pump_ports(pump_cell)` : les 4 cases autour de la pompe et celle au-dessus, là où l'eau entre ;
  - `reach(pump_cell, cells)` : parcours en largeur depuis les ports, renvoie case → distance (le nombre de pièces à traverser) ;
  - `feeds(cell, zone_pos, rayon)` : une pièce verse dans une zone si son centre est à moins de `config.inlet_radius[type]` du centre de la zone, à plat (la hauteur ne compte pas : un tuyau au-dessus d'un bassin y verse) ;
  - `zones_reached(...)` : les zones touchées, triées par distance de tuyau ; `distribute(liters, zones)` verse dans cet ordre.
- GameState : `can_place_pipe(cell)` (case libre, dans l'île, au sol rien d'autre que des zones dessous, en hauteur une pièce voisine ou une pompe juste dessous), `place_pipe()` / `remove_pipe()` (stock ±1, `network_changed`), `zones_for_pump(pump)`, `wet_pipes()` (les pièces atteintes par une pompe, pour les colorer). Rien n'est mis en cache : `run_pump()` recalcule le parcours à chaque appel. C'est pour ça qu'un déplacement ne peut rien casser : il n'y a aucun lien stocké qui pourrait devenir faux.
- Au sol, les pièces s'ajoutent aux obstacles de `_blockers_except()` (rayon `config.pipe_radius_m` = 0,2 m, sauf pour les zones). `can_place_pipe()` fait le même calcul dans l'autre sens (rayon de l'objet + rayon du tuyau), donc une pompe peut toucher une pièce dans la case voisine.
- `scenes/world/pipe_builder.gd` (`PipeBuilder`) : actif quand l'outil tenu est « tuyaux ». Il lance un rayon de 6 m, calcule la case avec `cell_for_hit()` (sur une pièce : la case voisine du côté de la face visée ; ailleurs : la case juste devant la surface touchée), affiche un cube fantôme vert ou rouge et pose au clic.
- `scenes/world/pipes_view.gd` se redessine sur `network_changed`, `item_moved` et `game_reset`. Chaque pièce est un `PipePiece` (`StaticBody3D`, champ `cell`) : un moyeu carré plus un bras vers chaque voisin, chaque pompe qui la touche et chaque zone où elle verse. Bleu si mouillée, gris sinon. `PipePiece.interact()` reprend la pièce quand on tient l'outil.
- `run_pump()` note `pump.last_lps` (litres réellement pompés ÷ delta). `pump_view.gd` lisse ce chiffre dans une étiquette `Label3D` (toujours face caméra) visible à moins de 7 m de `GameState.player_position` ; pour la pompe à bras, il vaut 0 sauf pendant les 2 images qui suivent un `hold_use()`.
- Placement « au bord de l'eau » : `PlacementGrid.is_valid(..., min_center_radius)` ; `GameState.min_center_radius_of(kind)` lit `config.shore_only_kinds`. `find_free_spot()` le prend aussi, donc une pompe sortie d'une caisse apparaît déjà sur la plage.
- Moulin-pompe : c'est une pompe comme une autre (`kind = "moulin_pompe"`), mais listée dans `config.auto_pump_kinds`. `simulate()` appelle `_run_auto_pumps(delta)`, qui fait `run_pump()` pour chaque pompe automatique et additionne dans `auto_pumped_l`. Au seuil (`demo_end_auto_pumped_l`), `demo_done` passe à vrai et `demo_finished` est émis une seule fois.
- `scenes/ui/demo_end.gd` (créé par `main.gd`) écoute `demo_finished` : il fait passer un gros avion sombre (des boîtes noires) avec un `Tween`, puis au bout de 6 s affiche le panneau (bilan avec `Hud.format_time`, `format_liters`, `WaterGauge.format_drop_mm`), met `ui_open` et libère la souris. Le bouton referme tout.
- `pump_view.gd` construit soit le levier, soit la tour du moulin ; les pales tournent vite quand `auto_pumped_l` a augmenté depuis l'image précédente.
- Clic maintenu : `player.gd` regarde d'abord si la cible a `hold_use(player, delta)` et l'appelle à chaque image tant que le clic est enfoncé. `pump_view.gd` s'en sert et fait bouger son levier quand de l'eau passe.

### La barre d'outils (M-27) et les matériaux en main

- `core/toolbar_logic.gd` (classe `ToolbarLogic`) : `slots` (5 textes : un outil, un matériau ou `""` pour une case vide = les mains), `selected`. `select()` / `cycle()` reçoivent un `Callable` qui dit si une case est utilisable (vide : toujours ; sinon possédée) : la logique ne connaît pas GameState. Pour ranger : `put(nom)` (première case vide, ou celle qui l'a déjà), `clear(nom)`, `first_free()`, `index_of()`, `swap(a, b)` (la sélection suit ce qu'on tenait).
- GameState décide de ce qui va dans les cases :
  - `owns_tool(x)` : le seau toujours, le râteau si `has_rake`, les tuyaux s'il en reste ou si on en a posé, un matériau si on en porte.
  - `_sync_toolbar()` range tout : vide les cases devenues fausses (matériau posé ou dépensé), donne une case aux outils de `TOOLS` (d'abord) puis aux matériaux portés qui n'en ont pas, vérifie la case tenue et émet `tool_changed` seulement si quelque chose a changé. Appelée dans `add_carried`, `unload_to_stock`, le paiement de `order`, l'achat du râteau ou des tuyaux et le chargement.
  - `add_carried(items)` ne prend un matériau que si `has_slot_for(clé)` ; le reste revient (« leftover »), comme quand les bras sont pleins. `can_carry(clé)` = place dans les bras **et** une case (utilisé par les coquillages et les invites).
  - `swap_slots(a, b)` pour le menu ; la disposition est sauvegardée dans `upgrades.toolbar` et revérifiée au chargement (en dernier, car elle dépend des tuyaux et de ce qu'on porte).
- `harvest(zone, resource)` : `DryingLogic.take_some(n, only)` ne prend que le matériau du tas visé ; le râteau tenu prend tout ce tas.
- `scenes/ui/toolbar_menu.gd` (créé par `main.gd`, nommé « ToolbarMenu ») : action `toolbar_menu` (Tab) dans `input_setup.gd`. Il met `ui_open`, libère la souris et affiche 5 boutons ; `click_slot()` choisit une case puis appelle `GameState.swap_slots()` avec la suivante.
- `hud.gd` : `slot_text(entrée)` (statique, réutilisé par le menu) écrit « Seau », « Sel ×3 » ou « Mains » ; la barre se redessine sur `tool_changed` et `carried_changed`. `player.gd` : 1-5 et molette, seau et râteau visibles selon la case tenue.
- Les tas : `drying_zone_view.gd` crée un `SaltPile` par entrée de `config.pile_slots` (sel 0, minéraux +1, minéraux rares −1 case), placé à `GameState.pile_offset(zone, matériau)`, avec sa couleur. Chaque tas affiche et ramasse seulement son matériau.

### Le monde vivant (PR #14)

- **Océan** (`scenes/world/ocean_view.gd`, `shaders/ocean.gdshader`) : la technique classique des **vagues de Gerstner** (GPU Gems 1, chapitre 1). Chaque vague déplace les sommets en cercle (x, z suivent `cos`, y suit `sin`) ; on additionne trois vagues et on calcule la normale avec les dérivées (tangente × binormale). Elles sont calculées en coordonnées du monde, donc le maillage peut suivre la caméra (aligné sur 1 m pour que rien ne glisse). Un carré de 160 m très découpé porte les vagues ; un plan de 12 km, 2 cm plus bas, va jusqu'à l'horizon (les vagues s'éteignent avec la distance).
- **Couleur selon la profondeur** : le fragment lit le tampon de profondeur (`hint_depth_texture`), reconstruit la distance de la scène derrière l'eau (`INV_PROJECTION_MATRIX`) et la compare à celle de la surface : peu d'eau = turquoise et écume, beaucoup = bleu profond. Une ligne `#if CURRENT_RENDERER == RENDERER_COMPATIBILITY` gère les deux moteurs de rendu. `FRONT_FACING` faux = on voit la surface d'en dessous.
- **Sous l'eau** (`scenes/ui/underwater_overlay.gd`, `shaders/underwater.gdshader`) : un `ColorRect` plein écran lit l'image (`hint_screen_texture`), la fait onduler, la teinte et assombrit les bords ; en même temps, le brouillard de l'`Environment` passe au bleu épais (et revient à l'ancien en sortant). `is_camera_under(y caméra, niveau)` est statique et testée.
- **Vie** : `core/ambient_motion.gd` (pur : cercle, tangente, profondeur permise aux poissons, point dans un anneau, retour de l'autre côté, battement d'ailes). `fauna.gd` contient trois petites classes (`Seagull`, `Fish`, `Crab`) faites de boîtes ; `clouds.gd` déplace 16 nuages avec le vent ; `seabed_decor.gd` pose rochers, algues et coraux avec une graine fixe. Aucun n'a de collision ni de règle : `main.gd` les crée et on peut retirer chacun sans rien casser.

### Le téléphone (PR #15)

- `core/phone_logic.gd` (`PhoneLogic`, pur) : `ringing` (`Ring.NONE`, `TUTORIAL`, `OFFER`), `tutorial_done`, l'offre en attente (`_pending_item`) et l'offre valable (`offer_item`, `offer_day`). `answer(jour)` rend la raison de l'appel et active l'offre pour ce jour ; `on_new_morning(rng, chance, candidats)` fait (ou non) sonner ; `discounted(prix, facteur)` arrondit au-dessus.
- GameState : `phone` ; à chaque matin de `simulate()`, `phone.on_new_morning(…, offer_candidates())`. `answer_phone()` : tutoriel → `_new_crate(["catalogue_papier"], hold_music_s)` marquée `free` ; émet `phone_changed` et `phone_answered(raison)`. `price_of(article)` applique l'offre, `cart_price()` s'en sert, donc la commande paie le bon prix sans autre changement.
- `CatalogItem.hidden` : l'article n'est pas dans la liste du catalogue et `can_buy()` le refuse (le catalogue papier n'arrive que par le premier appel).
- `phone.gd` lit `GameState.phone` à chaque image (tremblement, « Dring ! ») ; `interact()` décroche s'il sonne, sinon ouvre le catalogue. Sur `phone_answered(OFFER)`, il ouvre le catalogue ; `catalogue.gd` affiche le prix de l'offre en jaune.
- Crochet : `order()` met `paid` (le prix) sur la première caisse. `main.gd` relie `plane.hooked` (émis au passage bas au-dessus de la palette) à `plane.carry_bundle(couleurs)`. Le crochet est un `Node3D` dont la rotation globale est remise à zéro à chaque image : la corde reste verticale.

### Toboggan à sacs et objet en perle (PR #16)

- `CatalogItem.Effect.SLIDE` (ajouté en dernier : les fichiers de données stockent les effets par numéro). `apply_item()` → `add_slide(kind, position)` ; `is_placeable()` le compte, donc il arrive dans sa propre caisse et passe en mode déplacement.
- `zones_for_slide(slide)` : zones dont le bord (centre + emprise) est à moins de `config.slide_reach_m`. Rien n'est mémorisé : déplacer le toboggan ou la zone change tout de suite qui est servi.
- `_run_slides(delta)` (dans `simulate()`) : un minuteur par toboggan ; à `slide_period_s`, il prend les dépôts des zones servies (`take_deposit()`), les ajoute au stock et émet `slide_sent(toboggan, ressources)`. `slide_unload()` réutilise `unload_to_stock()`.
- `slide_view.gd` écoute `slide_sent` et fait glisser des sacs (des `Tween`) le long de la goulotte.
- Le flamant est un article `DECOR` ordinaire au prix `{"perles": 1}` : le paiement en perle n'a demandé aucun code, le troc gère déjà toutes les ressources.

### Les jalons comparatifs (PR #17)

- `core/milestone_logic.gd` (`MilestoneLogic`, pur) : la liste (triée par litres) et `reached`, le nombre de jalons atteints. `update(retiré)` rend les jalons franchis à l'instant (plusieurs d'un coup si besoin, jamais deux fois) ; `next()` et `progress(retiré)` servent à l'affichage.
- GameState : `milestones` ; `check_milestones()` est appelé après `fill_bucket()` et à chaque `simulate()` (pompes, moulin) ; chaque jalon franchi ajoute sa récompense au stock et émet `milestone_reached`. Au chargement d'une vieille sauvegarde, on recalcule les jalons sans redonner les récompenses.
- `scenes/ui/milestone_icon.gd` (`MilestoneIcon`) dessine le pictogramme avec `_draw()` (rectangles, lignes, cercles) et le remplit d'eau selon `fill`. `milestone_panel.gd` lit `GameState.milestones` à chaque image pour le petit pictogramme, et met les jalons franchis dans une file pour les montrer l'un après l'autre (un `Tween` qui fait grossir puis s'effacer).

### Menus, emplacements et options (PR #18)

- `core/settings_logic.gd` (`SettingsLogic`, pur) : les valeurs, `sanitize()` (bornes), `to_dict`/`load_dict`, et `bob_offset()` (le balancement de tête, une sinusoïde nulle à l'arrêt ou si l'option est coupée).
- `Settings` (`core/settings.gd`) : **classe à variables statiques**, pas un autoload (depuis le correctif de la PR #22 : un autoload dépend d'une ligne de `project.godot` que l'éditeur peut perdre). `Settings.data` est chargé de `user://settings.json` au premier accès ; `Settings.set_value(clé, valeur)` applique (langue via `TranslationServer`, volume du bus Master, plein écran), enregistre et émet `Settings.events.changed`. `main.gd` appelle `Settings.apply()` au lancement. `Settings.persist = false` empêche d'écrire.
- Le joueur lit `Settings.data` à chaque image (FOV, sensibilité, balancement) : rien à brancher.
- `scenes/ui/menu_style.gd` (`MenuStyle`) : panneau, titre, fond, thème communs. `options_panel.gd` (`OptionsPanel`) est un seul panneau réutilisé par les deux menus. Les textes des boutons sont des **clés** de traduction : Godot les retraduit seul quand on change de langue.
- `main_menu.gd` (`MainMenu`, `PROCESS_MODE_ALWAYS`) met l'arbre en pause, coupe la sauvegarde auto, lit `SaveSystem.summary(slot)` ; Jouer appelle `GameState.play_slot(slot)` (charge, ou partie neuve sauvegardée tout de suite). `pause_menu.gd` (`PauseMenu`) répond à Échap seulement si aucun autre menu n'a la main (`GameState.ui_open`).
- `GameState.autosave_enabled` est faux tant qu'aucun emplacement n'est choisi : ni la minuterie, ni l'achat, ni la fermeture de la fenêtre n'écrasent un emplacement. `save_dir` permet aux tests d'écrire ailleurs.

### L'anti-blocage (PR #19)

- `core/physics_layers.gd` (`PhysicsLayers`) : couche 1 = SOLID, couche 2 = WALK_THROUGH. `make_walk_through(corps)` met un objet sur la couche 2 sans masque. Le joueur a `collision_mask = SOLID` : il traverse la couche 2. Son rayon de visée utilise `AIM = SOLID | WALK_THROUGH` : il trouve toujours les tas et les tuyaux.
- `core/unstuck_logic.gd` (`UnstuckLogic`, pur) : `update(delta, veut_avancer, déplacement)` rend vrai après 1 s sans bouger ; `probe_directions()` (8 vecteurs), `is_trapped()`, `candidates()` (cercles de plus en plus grands, triés par distance).
- Dans `player.gd` : `is_trapped()` appelle `test_move()` (méthode de `CharacterBody3D` qui simule un déplacement sans le faire) dans les 8 directions ; `find_free_spot()` essaie chaque place avec `intersect_shape` (la capsule du joueur y tient-elle ?) puis un rayon vers le bas (y a-t-il du sol ?). `rescue()` sert au bouton du menu pause.
- `tests/scenarios/softlock.gd` : un script `SceneTree` qui charge la vraie scène, appuie sur les touches (`Input.action_press`) et vérifie les positions : c'est un test d'intégration, à côté des tests unitaires.

### La vraie fin, les traits du palmier et « Nouvelle partie » (PR #20)

- `core/ending_logic.gd` (`EndingLogic`, pur) : `enum Phase`, `step(delta)` (peut traverser plusieurs phases), `progress()`, `skip()` (temps et générique seulement), et `tally_marks(n)` qui place les traits par paquets de 5.
- GameState : `start_ending()` crée l'EndingLogic, bloque le joueur (`ui_open`) et mémorise l'eau retirée. Pendant la fin, `_process` n'avance que la fin (chronomètre arrêté) et règle `ending_drop_m`, que `water_level_y()` soustrait : l'océan, le filtre sous l'eau et le joueur voient tous la même eau. À l'entrée de WALK l'océan est vidé ; à DONE, `finish_run()` garde le meilleur temps, sauvegarde et émet `run_finished` (main.gd ouvre alors le menu).
- `scenes/world/ending_director.gd` (`EndingDirector`) écoute `ending_started` / `ending_phase_changed` et construit tout dans un nœud `_scene` effacé à la fin : sa propre `Camera3D`, la bonde, les anneaux du tourbillon, le marcheur, l'avion (réutilise `delivery_plane.gd`, crochet caché) avec une banderole `Label3D` (`double_sided = false` pour une face par côté), et l'écran du temps / le générique dans un `CanvasLayer`.
- `scenes/world/palm_marks.gd` (`PalmMarks`) redessine les traits à chaque `wakeups_changed`. La noyade appelle `rescue()` puis `GameState.register_wakeup()`.
- Menu principal : `new_game(slot)` lance tout de suite sur un emplacement vide, sinon `ask()` affiche une question Oui / Annuler à la place du menu ; `pick_new_game_slot()` choisit le premier vide ou le plus ancien ; `GameState.new_game_in_slot()` écrit la partie neuve.

### Les sons de base (PR #21)

- `core/sound_synth.gd` (`SoundSynth`, pur) : chaque son est une recette qui remplit un tableau d'échantillons (-1..1) à 22 050 Hz. Briques : bruit blanc passé dans un filtre passe-bas à un pôle (`y += a·(x − y)`), sinusoïde dont la fréquence glisse (le « plop »), tons alternés (le téléphone), notes qui se superposent (l'arpège), dent de scie avec effet Doppler (l'avion). Le bruit utilise une graine fixe (`hash(nom)`) : le son est identique à chaque lancement, donc testable. Les boucles (vagues, glouglou) commencent et finissent à zéro pour ne pas claquer. `stream(nom)` emballe le tout dans un `AudioStreamWAV` 16 bits.
- `scenes/audio/sound_board.gd` (`SoundBoard`) : fabrique les 9 sons une fois au démarrage, garde une petite réserve de 6 `AudioStreamPlayer` (pour jouer plusieurs sons à la fois), et **observe** GameState : il compare l'eau du seau d'une image à l'autre (plus = puiser, moins = verser), regarde `phone.is_ringing()`, et écoute quelques signaux (`milestone_reached`, `pickup_removed`, `crate_added`, `ending_phase_changed`). GameState ne sait rien des sons.
- `tests/scenarios/perf.gd` : relève `Performance.get_monitor(...)` (temps de calcul, appels de dessin, primitives, nœuds, mémoire) sur l'île de départ puis sur une île remplie.

### Correctif : Settings sans autoload (PR #22)

- `Settings` devient une classe statique (voir « Menus, emplacements et options »). `tests/test_project.gd` charge **chaque** script du projet et vérifie qu'il compile, et que les autoloads attendus sont bien déclarés : une ligne perdue dans `project.godot` ou un script cassé que les autres tests n'atteignent pas fait échouer la CI.

### Le terrain low poly (PR #23)

- **`core/terrain_logic.gd` (`TerrainLogic`)** : pure logique. `height(x, z)` donne la hauteur du sol partout ; `color(y, pente, …)` sa couleur. Trois bruits `FastNoiseLite` à graine fixe : un sur l'angle (côte irrégulière, dunes), un pour les dunes, un pour le relief fin. Dans le rayon constructible, le sol est plat à `ground_y` (les objets posés ne bougent pas). Au-delà : `_beach()` (pente vers le rivage, plateau sous-marin, puis fond à `seabed_y`) et, si `dune_amount(angle) > 0`, une bosse découpée par `terrace()`. Créé par `GameState.setup()` (`GameState.terrain`), pour que tout le monde lise le même sol.
- **`scenes/world/terrain_view.gd` (`TerrainView`)** : construit une grille légèrement décalée au hasard (graine fixe), deux triangles par case, chaque triangle avec sa propre normale (facettes plates) et la couleur de `TerrainLogic`. Tous les triangles ont le même sens, et la collision vient du même maillage (`create_trimesh_shape`).
- **Eau** (`shaders/ocean.gdshader`) : la profondeur sous la surface donne une couleur arrondie en `color_bands` bandes ; normale calculée par `dFdx/dFdy` pour les facettes ; écume = bande nette près du sol.
- **Ciel** (`shaders/sky.gdshader`, `SkyStyle`) : dégradé selon la hauteur du soleil (`LIGHT0_DIRECTION`), disque et halo, étoiles la nuit. `main.gd._update_sun` colore la lumière avec `SkyStyle.sun_color()`.
- Ceux qui posent des choses au sol (décor du fond, marcheur de la fin, `player.find_free_spot`) demandent `GameState.terrain.height()` ou lancent un rayon vers le bas.

### La cabine, les dialogues, le catalogue et l'interface (PR #24)

- **`scenes/world/models.gd` (`Models`)** : charge un modèle CC0 (`load_model`), remplace ses matériaux par des couleurs cartoon (`RECOLOR`, faces des deux côtés), le pose au sol (`fit_on_ground`). `palm()` ajoute une deuxième couronne tournée et des noix de coco, et range le profil du tronc en méta (`trunk_at` sert aux traits des réveils). `coconut()` et `facet_sphere()` font des boules à facettes ; `phone_booth()` construit la cabine (nœuds `Shake`, `Shake/Phone/Handset`, `Shake/Catalogue`).
- **`scenes/world/island_props.gd` (`IslandProps`)** : place les palmiers et rochers de `GameConfig` sur `GameState.terrain`, et sème buissons et bois flotté (graine fixe, hors zone constructible, sans collision).
- **`scenes/world/phone.gd`** : la cabine. `interact()` choisit la conversation (`tutorial`, `offer`, `call` ou `no_catalogue`) et la lance dans la `DialogueBox` ; pour le premier appel, `GameState.answer_phone()` n'est appelé qu'à la fin (la caisse part après la musique d'attente). L'action `open_catalogue` ouvre le catalogue : c'est le seul chemin vers lui.
- **`core/dialogue_logic.gd` (`DialogueLogic`)** + **`data/dialogues.json`** : une conversation = des répliques (interlocuteur, texte ou variantes, `next` ou `choices`, `action`). `advance()`, `choose(i)`, `errors()` (vérifie le fichier), `text_keys()` (vérifie les traductions).
- **`scenes/ui/dialogue_box.gd` (`DialogueBox`)** : affiche la réplique lettre par lettre, puis les réponses ; E/Espace/clic avance, 1-4 répond, Échap raccroche ; signal `finished`.
- **`scenes/ui/ui_theme.gd` (`UiTheme`)** : couleurs, polices (avec la police de Godot en secours pour ♪ ▮ ★), le `Theme` commun (variantes `Title`, `Price`, `Fine`, `Hud`, `Tag`) et des fabriques : `paper()`, `banner()`, `price_tag()`, `stamp()`. `MenuStyle` passe par lui.
- **`scenes/ui/catalogue.gd`** : grille de vignettes (`ProductPhoto` = un `SubViewport` avec son propre monde 3D, le modèle de `ProductModels` sur un plateau tournant, rendu seulement quand il est visible) et bon de commande.
- **`GameState.catalogue_delivered`** : mis à vrai par l'effet `CATALOGUE` du catalogue papier ; sauvegardé ; une vieille sauvegarde qui avait le catalogue au sol est migrée.

### L'île agrandie et le HUD léger (PR #25)

- **`TerrainLogic`** : `coast_at()` retire `cove_depth` autour de +Z (la crique) ; `_islets()` ajoute des dômes de sable au large (`islets`, (x, z, rayon)). Les couleurs : herbe au-dessus de 1,4 m, touffes sèches sur les terrasses selon le hasard de la facette.
- **`IslandProps`** : place aussi `GameConfig.outer_palms` (sauf s'ils tombent dans l'eau).
- **`scenes/ui/need_gauge.gd` (`NeedGauge`)** : un `Control` dessiné à la main (`_draw`) : médaillon, liquide découpé dans le cercle avec une vague en sinus, pictogramme (pilon ou goutte). `level` est la cible, `shown` la rejoint ; sous 25 % il bat (échelle) et le bord rougit. Le HUD met à jour `level` à chaque image.
- **`PauseMenu.island_report(gs)`** : le bilan texte du panneau « Mon île ».

### Tous les modèles, 64 par case, pompes dans l'eau (PR #26)

- **`Props` (`scenes/world/props.gd`)** fabrique les modèles des objets. Ce sont des Node3D sans physique, posés sur (0, 0, 0). Les vues ajoutent la collision et retrouvent les pièces animées par leur nom : `Lever` (pompe), `Blades` (moulin), `Propeller` et `Cockpit` (avion), `Water` (zones, seaux).
  - Briques de base : `box`, `cyl`, `beam` (une barre de A à B), `torus`, `ball` (sphère à facettes), `dome` (pour les tas), `painted` (texte peint). Les matériaux sont partagés par couleur.
  - Triangles faits main : `tri_from(st, a, b, c, inside)` tourne la face vers l'extérieur, dans le sens horaire qu'attend Godot.
- **Tas :** `Props.pile(ressource)` est un monticule de la couleur du socle avec des morceaux dessus : cristaux de sel, `crystal_rock`, `crystal` et `gem_pink`, coquillages, perles. La palette le met à l'échelle avec `Depot.pile_scale` (plafond de largeur par case). Les tas des zones (`SaltPile`) le grossissent d'un bloc.
- **Personnages :** `Props.character(nom, hauteur, animation)` et `Props.play(noeud, animation)`. `Models.vertices` applique les os de la pose de repos (`Models._skinned`), sinon la taille d'un modèle animé est fausse.
- **Seaux :** `player.gd` reconstruit les seaux quand on reçoit le grand seau (`_rebuild_buckets`). `_update_bucket_water` suit `water_l / capacity_l`, plus la montée pendant qu'on puise (`fill_progress_ratio`). `_drip` lâche une goutte qui tombe. Le corps (`_body`) remplace la capsule ; `_animate_body` choisit l'animation.
- **Portage :** `GameState.carry_space(clé)` = `carry_capacity` (par case) − ce qu'on porte de ce matériau, 0 sans case. `harvest` parcourt les matériaux et prend chacun dans la limite de sa case.
- **Pompes dans l'eau :**
  - `spot_ok(type, pos, rayon, gêneurs)` est la règle unique de placement, utilisée par `can_place` et `find_free_spot`. Pour une pompe, elle vérifie `is_water_spot` : assez de fond sous la plateforme, pas trop loin du rivage.
  - `can_place_pipe` accepte les cases au-dessus de l'eau jusqu'à `coast_at + pump_max_offshore_m`, mais refuse une case enterrée dans une dune.
  - `PumpView._update_stilts` met les pilotis à la profondeur sous la pompe, à chaque image : elle peut être déplacée.
- **Raccords (`PipesView`) :** une bride côté pompe ; `_spout` ajoute une descente, un bec et un filet d'eau (`Stream`) au-dessus d'une zone. `_process` n'affiche le filet que si une pompe a débité il y a moins de 0,3 s (`pump.last_run_ms`). Un piquet porte les pièces au-dessus d'un creux.

### La grille de placement colle aux modèles (PR #27)

- **Les formes (`PlacementGrid`, logique pure)** : une forme est `{"rect": Rect2}` (X, Z du monde) ou `{"position", "radius"}` (cercle). `overlaps(a, b)` gère rectangle/rectangle (marge `EPS` : se toucher n'est pas chevaucher), rectangle/cercle (point du rectangle le plus proche du centre) et cercle/cercle. `fits` vérifie les 4 coins contre `build_radius`. `is_valid(forme, autres, rayon)` = `fits` + aucun `conflicts`.
- **Rotation :** `rect_at(local, pos, angle)` tourne les 4 coins comme la vue (`Vector3.rotated(UP, angle)`, le même sens que `rotation_degrees.y`), prend le rectangle qui les englobe et arrondit au dixième de millimètre.
- **Alignement :** `snap_rect(pos, local, angle, case)` déplace l'objet pour que le coin bas de son rectangle tourné tombe sur une ligne. Avec des côtés en cases entières, tous les bords y tombent. C'est ce qui place un miroir (2 cases) sur une ligne et une cuvette (bac de 3 cases) au milieu d'une case.
- **Données :** `config.footprints[type] = [x0, z0, x1, z1]`. `GameState.footprint_of(type)` en fait un `Rect2` ; `footprint_rect(type, pos, angle)` le pose ; `item_rect(objet)` lit sa position et son `rotation_deg` ; `snap_item(type, pos, angle)` aligne.
- **Une seule règle :** `spot_ok(type, pos, angle, gêneurs)`. `can_place(objet, pos, angle = NAN)` (NAN : l'angle actuel), `move_item` (aligne avec le nouvel angle, puis vérifie avec lui : tourner sur place peut être refusé), `find_free_spot(type, près, angle)` (carrés de plus en plus grands autour de la position alignée).
- **Gêneurs :** `_blockers_except` donne des rectangles pour les objets posés, les caisses et les coquillages, des cercles pour les obstacles fixes, les noix, le joueur et les tuyaux. `placement_conflicts(objet, pos, angle)` renvoie ceux qu'on chevauche.
- **Tuyaux et pompes :** `GameState.pump_cells(pompe)` = cases de son emprise (`Rect2i`). `PipeNetwork.pump_ports(case, emprise)` liste les cases qui la bordent (pas les diagonales) et celle au-dessus du centre ; `reach` et `zones_reached` le reçoivent. `pump_at_cell(case)` sert à `PipesView._touches_pump` pour la bride.
- **Toboggan :** `zones_for_slide` utilise `PlacementGrid.distance_to(rectangle de la zone, toboggan) <= slide_reach_m`.
- **Aperçu (`PlacementController`) :** `_follow_aim` vise le milieu de l'emprise (on retire le décalage du centre du rectangle tourné), aligne avec `snap_item`, puis `show_footprint(pos, angle)` :
  - une dalle `BoxMesh` de la taille du rectangle (verte ou rouge) ;
  - la grille en lignes sur le rectangle agrandi de `GRID_MARGIN_CELLS` ;
  - un `ImmediateMesh` à deux surfaces : les voiles (triangles, cachés par les objets) et les contours (lignes, `no_depth_test`), en bleu pour les voisins, en rouge pour les gêneurs. Le joueur n'est montré que s'il gêne.
- **Le test qui garde les emprises honnêtes (`test_footprints.gd`) :** `_model(type)` assemble ce que la vue montre (zone + tas au plus gros, pompe + pilotis…) ; `Models.bounds` donne son rectangle au sol. L'emprise doit le couvrir (à `OVERHANG` = 12 cm près) et chaque côté doit toucher le modèle à moins d'une case. Si on change un modèle, ce test dit quelle emprise ajuster.

### Les outils admin

- `admin/admin_tools.gd` est un autoload indépendant (F6 appelle `GameState.advance_time()`) : il écoute les touches F1, F6 à F12 dans `_unhandled_input`, et ne fait qu'appeler des fonctions publiques de GameState. Il se supprime lui-même hors version de debug (`OS.is_debug_build()`). Rien ne l'appelle, donc on peut l'enlever sans rien casser.

---

## 4. Par version

### PR #2 — M0 : fondations
Projet, autoloads, contrôles physiques, `OceanModel`, `SaveSystem`, île greybox, joueur 1re/3e personne, HUD, tests et CI.

### PR #3 — M2 : boucle de base
Logiques pures (séchage, seau, économie, jour/nuit, endurance), GameState source unique de vérité, vues (zones, téléphone, palette, avion, caisse, jauge), catalogue, nage.

### PR #4 — Retours de test
`Economy.pay_from` (bras + palette), `CatalogueFormat.group_cart`, tas `SaltPile` à côté des zones, lune, module `admin/`.

### PR #5 — Survie légère et plage vivante
`SurvivalLogic` (faim, soif, plafond d'endurance), `StationLogic` (bâche de condensation, rations), ramassables (`pickups` : noix de coco, coquillages du matin), vues `pickup_view.gd` et `station_view.gd`, effet `STATION` du catalogue, jauges dans le HUD, ce guide.

### PR #6 — Correctifs et début de T2
`GameState.simulate()` / `advance_time()` (F6 fait vivre le monde), palette à un tas par ressource, `unlocked_tier` + catalogue grisé, Manuel du bricoleur, bassin en bois, miroir solaire (`mirrors`, `zone_boost`), panneau du catalogue opaque et défilant.

### PR #7 — Déplacer les objets sur une grille
`PlacementGrid` (aligner, valider), `GameState.move_item` / `can_place` / `item_moved` / `placing`, emprises et obstacles fixes dans `GameConfig`, `get_movable()` sur les vues, `PlacementController` (touche G, aperçu, disque vert/rouge, grille en `ImmediateMesh`), `test_placement.gd`. Puis : rotation (R, `rotation_deg`), palette déplaçable (`GameState.depot`), `find_free_spot()` pour caisses, objets livrés et coquillages, tas de sel dans sa propre case (`pile_offset`).

### PR #8 — Vérifier la place, mode G automatique
Coquillages et joueur dans les emprises qui gênent, `NO_SPOT`, `_spot_is_free()`, `placement_requested` + file d'attente dans `PlacementController`, `test_spawning.gd` (20 cas), lanceur et CI qui échouent sur une erreur de script.

### PR #9 — Pompe à bras et tuyaux
`PipeNetwork`, `GameState.pumps` / `pipe_segments` / `run_pump` / `network_changed`, effets `PUMP` et `PIPES`, `shore_only_kinds`, `pump_view.gd`, `pipes_view.gd`, `hold_use` dans le joueur, `test_pumps.gd`.

### PR #10 — Moulin-pompe et fin de la démo
`auto_pump_kinds`, `_run_auto_pumps()`, `auto_pumped_l`, `demo_done`, `demo_finished`, vue du moulin, `demo_end.gd`, `test_windmill.gd`.

### PR #11 — Barre d'outils
`ToolbarLogic`, `GameState.toolbar` / `current_tool` / `select_tool` / `cycle_tool` / `tool_changed`, entrées 1-5 et molette, râteau tenu, barre du HUD, `test_toolbar.gd`.

### PR #12 — Tuyaux à la main, débit des pompes, plusieurs caisses
`PipeNetwork` réécrit (cases 3D, parcours en largeur), `GameState.pipes` / `pipe_stock` / `place_pipe` / `remove_pipe` / `can_place_pipe`, `PipeBuilder`, `PipePiece`, étiquette de débit (`last_lps`), `GameState.order()` qui renvoie une liste de caisses (`delay_s`), `open_crates()`, `crate_view.rest_position()` (5 rayons vers le bas : la caisse se pose sur ce qu'elle touche), `test_pumps.gd` réécrit (~30 tests).

### PR #13 — Un tas par matériau, matériaux dans la barre, menu pour la ranger
`ToolbarLogic` (`put`, `clear`, `swap`, cases vides utilisables), `GameState._sync_toolbar` / `has_slot_for` / `can_carry` / `swap_slots`, `harvest(zone, resource)`, `DryingLogic.take_some(n, only)`, `config.pile_slots`, emprises des zones agrandies, `toolbar_menu.gd`, `Hud.slot_text`, `test_toolbar.gd` réécrit (21 tests).

### PR #14 — Monde vivant
`OceanView` + shader de Gerstner et de profondeur, `UnderwaterOverlay` + shader plein écran, `SeabedDecor`, `Clouds`, `Fauna`, `AmbientMotion`, `test_ambient.gd`.

### PR #15 — Téléphone
`PhoneLogic`, `GameState.answer_phone` / `price_of` / `offer_candidates` / `_new_crate`, `CatalogItem.hidden`, catalogue papier, sonnerie et musique d'attente (`phone.gd`), crochet et pilote (`delivery_plane.gd`), `test_phone.gd`. Aussi : `find_free_spot` cherche sur toute l'île.

### PR #16 — Toboggan à sacs, flamant payé en perle
`Effect.SLIDE`, `GameState.slides` / `add_slide` / `zones_for_slide` / `slide_unload` / `_run_slides`, `slide_view.gd`, décor `flamant`, `test_content.gd`.

### PR #17 — Jalons comparatifs
`MilestoneLogic`, `GameConfig.milestones`, `GameState.check_milestones` / `milestone_reached`, `MilestoneIcon`, `milestone_panel.gd`, `test_milestones.gd`.

### PR #18 — Menus et options
`SettingsLogic`, autoload `Settings`, `MenuStyle`, `OptionsPanel`, `MainMenu`, `PauseMenu`, `SaveSystem.summary`, `GameState.play_slot` / `autosave`, `test_settings.gd`.

### PR #19 — Anti-blocage
`PhysicsLayers`, `UnstuckLogic`, `player.is_trapped` / `find_free_spot` / `rescue`, bouton « Me débloquer », `test_unstuck.gd`, `tests/scenarios/softlock.gd`.

### PR #20 — Vraie fin, traits du palmier, Nouvelle partie
`EndingLogic`, `GameState.start_ending` / `finish_run` / `register_wakeup` / `new_game_in_slot`, `EndingDirector`, `PalmMarks`, F4, menu Nouvelle partie avec confirmation, `test_ending.gd`.

### PR #21 — Sons et perf
`SoundSynth`, `SoundBoard`, `test_sound.gd`, `tests/scenarios/perf.gd`.

### PR #22 — Settings sans autoload
`Settings` en classe statique, `test_project.gd`, `test_settings_static.gd`.

### PR #23 — Version 0.1.1 : terrain, eau, ciel
`TerrainLogic`, `TerrainView`, `SkyStyle`, `sky.gdshader`, `ocean.gdshader` cartoon, `GameState.terrain`, `GameConfig.seabed_y`, `test_terrain.gd`.

### PR #24 — Version 0.1.2 : cabine, dialogues, catalogue, interface
`Models`, `IslandProps`, `DialogueLogic`, `data/dialogues.json`, `DialogueBox`, `UiTheme`, `ProductModels`, `ProductPhoto`, catalogue refait, `GameState.catalogue_delivered`, `CatalogItem.Effect.CATALOGUE`, `test_dialogue.gd`, `test_models.gd`.

### PR #25 — Version 0.1.3 : île agrandie, HUD léger
`TerrainLogic` (crique, îlots), `GameConfig.outer_palms`, camp avancé vers la plage, `NeedGauge`, panneau « Mon île », `test_hud_light.gd`.

### PR #26 — Version 0.1.4 : tous les modèles, 64 par case, pompes dans l'eau
`Props`, CC0 ajoutés (cristaux, crabe, poisson, fleurs, personnages), seaux qui se remplissent, corps animé, `carry_space(clé)`, `spot_ok` / `is_water_spot`, pilotis, raccords de tuyaux, `test_props.gd`.

### PR #27 — Version 0.1.5 : la grille colle aux modèles
Emprises en rectangles de cases (`config.footprints`), `PlacementGrid.rect_at` / `snap_rect` / `overlaps`, `spot_ok` avec rotation, `find_free_spot(type, …)`, ports de pompe tout autour de l'emprise, aperçu des cases (`show_footprint`), `test_footprints.gd`.
