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

## 3. Chaque idée, côté code (M0 → PR #4)

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
- `GameState._process` appelle `step()` sur **toutes** les zones à chaque image, avec le multiplicateur jour/nuit. C'est pour ça que le séchage continue même loin du joueur.
- Une zone dans GameState = `{id, kind, position, logic}`. `add_zone()` la crée et émet `zone_added(zone)`.
- `scenes/world/drying_zone_view.gd` : `main.gd` reçoit `zone_added` et crée cette vue. Elle construit la cuvette ou la bâche, et à chaque image règle la hauteur de son disque d'eau selon `logic.fill_ratio()`.
- Le **tas de sel** est une classe interne `SaltPile` (un `StaticBody3D` à côté de la zone). Il grossit avec le dépôt, désactive sa collision quand il est vide, et son `interact()` appelle `GameState.harvest(zone)`.

### Récolter, porter, déposer, payer

- `GameState.carried` (les bras) et `GameState.stock` (la palette) sont deux dictionnaires de ressources. `core/economy.gd` regroupe les opérations : `add`, `count`, `can_afford`, `pay_from`.
- `harvest(zone)` prend 3 unités du dépôt (`take_some`, les plus rares d'abord), ou tout avec le râteau, dans la limite de `carry_space()`. Ce qui ne rentre pas retourne dans le dépôt.
- `scenes/world/depot.gd` (la palette) : `interact()` appelle `unload_to_stock()`, qui vide les bras dans le stock. Son tas grossit selon `stock`.
- `order(ids)` : `Economy.pay_from([carried, stock], prix)` vérifie d'abord la **somme** des deux, puis retire des bras, puis de la palette.

### Le téléphone, le catalogue, la livraison

- `scenes/world/phone.gd` : `interact()` appelle `open_catalogue` sur le groupe `"catalogue"`. Un groupe est une étiquette sur des nœuds : on peut les appeler sans connaître leur chemin dans la scène.
- `scenes/ui/catalogue.gd` (un `CanvasLayer`) : construit le panneau en code (une ligne par `CatalogItem`). Ouvert, il met `GameState.ui_open = true` (le joueur ignore alors ses touches) et libère la souris. Le panier est une liste d'ids ; `CatalogueFormat.format_cart()` les regroupe en « Nom ×N ».
- « Commander » → `GameState.order(panier)` : paie, marque les objets uniques comme possédés, crée une caisse `{id, position, items}` à `next_drop_position()` (une spirale autour du point de livraison, pour ne pas empiler), et émet `crate_added(caisse, true)`.
- `main.gd` reçoit ce signal et crée une `CrateView` cachée et un `DeliveryPlane`. L'avion suit une trajectoire animée (`Tween`) : il passe au-dessus de la palette puis du point de largage, et émet `dropped`. Alors la caisse apparaît et descend en parachute (`drop_from`, un autre `Tween`).
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

### Les outils admin

- `admin/admin_tools.gd` est un autoload indépendant : il écoute les touches F1, F6 à F12 dans `_unhandled_input`, et ne fait qu'appeler des fonctions publiques de GameState. Il se supprime lui-même hors version de debug (`OS.is_debug_build()`). Rien ne l'appelle, donc on peut l'enlever sans rien casser.

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
