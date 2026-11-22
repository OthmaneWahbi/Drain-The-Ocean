extends Node
## État global de la partie en cours (autoload « GameState »).
##
## C'est la SEULE source de vérité du jeu : l'océan, le seau, les zones de séchage, le stock,
## les caisses livrées… Les objets 3D de la scène ne sont que des « vues » qui lisent cet état
## et appellent ses fonctions. Avantages : la logique se teste sans scène 3D, et la sauvegarde
## n'a qu'un seul endroit à lire.

signal ocean_changed
signal stock_changed
signal carried_changed
signal bucket_changed
signal zone_added(zone: Dictionary)
signal crate_added(crate: Dictionary, animate: bool)
signal crate_removed(crate: Dictionary)
signal decor_added(decor: Dictionary)
signal new_morning
## Un jalon comparatif vient d'être franchi (M-70) : {"id", "icon", "liters", "reward"}.
signal milestone_reached(milestone: Dictionary)
## Le téléphone se met à sonner, s'arrête, ou une offre change (PRD §9, M-48, M-54).
signal phone_changed
## On a décroché : `reason` vaut PhoneLogic.Ring.TUTORIAL ou OFFER.
signal phone_answered(reason: int)
signal pickup_added(pickup: Dictionary)
signal pickup_removed(pickup: Dictionary)
signal station_added(station: Dictionary)
signal station_removed(station: Dictionary)
signal survival_changed
signal mirror_added(mirror: Dictionary)
## Toboggan à sacs (T2, N-09, M-28) posé, et sacs qu'il envoie à la palette.
signal slide_added(slide: Dictionary)
signal slide_sent(slide: Dictionary, items: Dictionary)
## Une pompe vient d'être posée.
signal pump_added(pump: Dictionary)
## Le réseau de tuyaux a pu changer (objet déplacé, zone ou pompe ajoutée, tuyaux achetés).
signal network_changed
## Le moulin-pompe a assez pompé tout seul : c'est la fin de la démo (M-05). Une seule fois.
signal demo_finished
## On a changé d'outil dans la barre (M-27).
signal tool_changed
signal tier_unlocked(tier: int)
## Un objet déplaçable a changé de place (zone, objet à portions, miroir, décor).
signal item_moved(item: Dictionary)
## Un objet vient de sortir d'une caisse : le jeu passe tout de suite en mode déplacement.
signal placement_requested(item: Dictionary)
signal game_reset
## La vraie fin (M-04) : commence (touche de debug), change de phase, se termine (retour au menu).
signal ending_started
signal ending_phase_changed(phase: int)
signal run_finished
## Un réveil de plus après une noyade : un trait de plus sur le palmier (M-84).
signal wakeups_changed
## Le sable a été travaillé (pelle), ou la partie a changé : les sommets du terrain qui ont bougé
## (indices de sommet, tous les 50 cm depuis 0.1.11).
signal terrain_changed(corners: Array)
## Un coup de pelle (0.1.11), juste AVANT terrain_changed : le point visé (m), la hauteur d'avant
## et d'après de chaque sommet qui bouge (Vector2i -> float ; 0.1.12 : avec le sable qui s'éboule
## autour), et les pelletées prises (> 0) ou posées (< 0). Pour l'animation (la pelle, le sable
## qui vole et qui glisse, la poussière).
signal sand_moved(center: Vector3, before: Dictionary, after: Dictionary, scoops: float)
## Le sable porté sur la pelle a changé (ou la pelle vient d'être achetée).
signal shovel_changed
## 0.1.19 : le crabe de compagnie a changé (faim, affection, croquettes, accessoires)…
signal pet_changed
## …ou réagit à quelque chose (CrabPose.Anim : mange, refuse, est content) : la vue l'anime.
signal pet_reacted(anim: int)
## 0.1.20 : un marais salant disparaît (rebouché, vide).
signal zone_removed(zone: Dictionary)
## 0.1.20 : une trouvaille entre dans la collection (étoile de mer…).
signal collection_changed
## 0.1.20 : une flaque de marée basse a changé (garnie, vidée, couverte).
signal tide_pools_changed
## 0.1.20 (juice) : `n` unités d'un matériau viennent de tomber sur le tas d'une zone.
signal salt_dropped(zone: Dictionary, resource: String, n: int)
## 0.1.21 : un équipement porté a changé (masque…).
signal gear_changed
## 0.1.21 : le joueur a dormi dans le hamac en `spot` (jusqu'au matin).
signal slept(spot: Vector3)
## 0.1.21 : les coquillages du récif ont changé.
signal reef_changed
## 0.1.22 : le temps de la journée a changé (chaque matin).
signal weather_changed
## 0.1.22 : une ressource « trouvée seulement » (fleur de sel, sel rose) vient d'être trouvée.
signal resources_discovered
## 0.1.22 : la commande de l'agence a changé (nouvelle, ou envoyée).
signal agency_order_changed
## 0.1.23 : une bouteille à la mer est ouverte : son dessin (« carte », « chaine »…).
signal bottle_opened(drawing: String)
## 0.1.23 : une épave apparaît au large, ou disparaît (ouverte).
signal wreck_added(wreck: Dictionary)
signal wreck_removed(wreck: Dictionary)
## 0.1.23 : la pelle a sorti un objet enterré (« piece », « perle », « ferraille », « tresor »).
signal dug_up(kind: String, position: Vector3)
## 0.1.23 : une tortue a pondu (nouveau nid), ou les petites tortues sont sorties.
signal turtle_laid(nest: Dictionary)
signal turtles_hatched(nest: Dictionary)
## 0.1.23 : les cocotiers plantés ont changé (planté, poussé), ou la noix en main.
signal planted_changed

const CONFIG_PATH := "res://data/game_config.tres"
const FAR_AWAY := Vector3(1.0e9, 0.0, 1.0e9)
## Renvoyé quand aucune case libre n'a été trouvée.
const NO_SPOT := Vector3(INF, INF, INF)
const CATALOG_PATH := "res://data/catalog.tres"

var config: GameConfig
var catalog: CatalogDatabase
var rng := RandomNumberGenerator.new()

var ocean: OceanModel
var bucket: BucketLogic
var day: DayCycleLogic
var phone: PhoneLogic
var milestones: MilestoneLogic
## Ressources posées sur la palette (servent à payer l'agence).
var stock: Dictionary = {}
## Ressources que le joueur porte dans les bras (M-28).
var carried: Dictionary = {}
## Zones de séchage : {id, kind, position: Vector3, logic: DryingLogic}.
var zones: Array[Dictionary] = []
## Caisses livrées pas encore ouvertes : {id, position: Vector3, items: Array[String]}.
var crates: Array[Dictionary] = []
## Objets décoratifs (gags) : {kind, position: Vector3}.
var decor: Array[Dictionary] = []
## Achats uniques déjà faits (id -> true).
var owned: Dictionary = {}
## Améliorations appliquées (caisses ouvertes) : contenance d'un seau, nombre de seaux (palanche),
## capacité de transport (brouette), multiplicateur de vitesse (tongs), râteau.
var bucket_unit_l: float
var bucket_count: int = 1
var carry_capacity: int
var speed_multiplier: float = 1.0
var has_rake: bool = false
## La pelle s'achète au catalogue (0.1.11), et porte `shovel_sand` pelletées de sable.
var has_shovel: bool = false
var shovel_sand: float = 0.0
## 0.1.16 : ce que porte la pelle (TerrainLogic.Soil : sable ou terre ; compte quand elle n'est pas vide).
var shovel_soil: int = TerrainLogic.Soil.SAND
## 0.1.15 : le geste en cours, lu par les vues pendant sand_moved (l'aplanissement s'anime
## autrement qu'une pelletée : court, sans rebond).
enum Gesture { SCOOP, LEVEL }
var sand_gesture: Gesture = Gesture.SCOOP
## La barre d'outils de 5 cases : quel outil on tient (M-27).
var toolbar: ToolbarLogic = ToolbarLogic.new()
## Endurance du personnage (pas sauvegardée : elle est pleine au chargement).
var stamina: StaminaLogic
## Faim et soif (sauvegardées).
var survival: SurvivalLogic
## Le crabe de compagnie (0.1.19) : sa faim, son affection, ses croquettes et ses accessoires.
var pet: CrabPetLogic
## Où il se trouve (mis à jour par sa vue) : son cadeau du matin tombe près de lui.
var pet_position: Vector3 = FAR_AWAY
## 0.1.20 : les trouvailles (pas des ressources) : id -> combien. Voir la vitrine (0.1.21).
var collection: Dictionary = {}
## 0.1.20 : les flaques de marée basse : {position, items: Array[String], low, pet_low}.
var tide_pools: Array[Dictionary] = []
## 0.1.21 : l'équipement porté (masque…) : id -> vrai.
var gear: Dictionary = {}
## 0.1.21 : les coquillages posés au fond du récif (positions).
var reef_shells: Array[Vector3] = []
## 0.1.21 : la liste de la vitrine (data/collection.json).
var collection_rows: Array = []
## 0.1.22 : le temps de la journée (une clé de config.weather_table).
var weather: String = WeatherLogic.DEFAULT
## 0.1.22 : les ressources « trouvées seulement » déjà trouvées : id -> vrai.
var discovered: Dictionary = {}
## 0.1.22 : les commandes possibles de l'agence (data/orders.json), et celle du moment :
## {id, sent: bool}. Vide s'il n'y en a pas.
var agency_orders: Array = []
var agency_order: Dictionary = {}
## 0.1.23 : les épaves qui dérivent : {id, position, target, landed}.
var wrecks: Array[Dictionary] = []
## 0.1.23 : l'heure de l'épave du jour (−1 : déjà venue).
var wreck_hour: float = -1.0
## 0.1.23 : les objets enterrés : {kind, position}. Le trésor de la carte n'est enterré qu'une fois.
var buried: Array[Dictionary] = []
var treasure_buried: bool = false
## 0.1.23 : les nids de tortue : {id, position, laid_day}.
var nests: Array[Dictionary] = []
var _turtle_day: int = -1
## 0.1.23 : les cocotiers plantés : {id, position, planted_day} ; les noix de coco en main.
var planted: Array[Dictionary] = []
var coconuts_held: int = 0
## 0.1.24 : l'eau des récipients tenus en main (arrosoir, seau percé), en litres.
var vessels: Dictionary = {}
## Petits objets à ramasser avec E : {id, kind: "coconut" | "shell", position}.
var pickups: Array[Dictionary] = []
## Objets posés qui contiennent des portions : {id, kind: "condenseur" | "rations", position, logic: StationLogic}.
var stations: Array[Dictionary] = []
## Miroirs solaires posés : {id, position}.
var mirrors: Array[Dictionary] = []
## Toboggans à sacs : {id, kind, position, rotation_deg, timer}.
var slides: Array[Dictionary] = []
## Pompes posées : {id, kind: "pompe_bras", position, rotation_deg}.
var pumps: Array[Dictionary] = []
## Tuyaux POSÉS par le joueur : case (Vector3i, y = niveau) -> true. Voir PipeNetwork.
var pipes: Dictionary = {}
## Pièces de tuyau en stock, pas encore posées.
var pipe_stock: int = 0
## Litres pompés par les pompes AUTOMATIQUES (le moulin-pompe), et fin de démo déjà vue.
var auto_pumped_l: float = 0.0
var demo_done: bool = false
## La palette de dépôt : {id: "depot", kind: "palette", position, rotation_deg}. Déplaçable comme le reste.
var depot: Dictionary = {}
## Où se tient le joueur (mis à jour par sa vue) : rien n'apparaît ni ne se pose sur lui.
## Très loin par défaut (tests sans scène).
var player_position: Vector3 = FAR_AWAY
## Palier débloqué : 1 au départ, 2 avec le Manuel du bricoleur (PRD §7).
var unlocked_tier: int = 1
var play_time_s: float = 0.0
var current_slot: int = 1
## Faux tant qu'aucun emplacement n'est choisi (menu principal) : rien n'est écrit sur le disque,
## ni toutes les 2 min, ni en quittant. Sinon on écraserait l'emplacement 1 avec une partie vide.
var autosave_enabled: bool = false
## La forme du terrain (hauteur du sol partout), créée avec la configuration.
var terrain: TerrainLogic
## La vraie fin en cours (EndingLogic), ou null.
var ending: EndingLogic = null
## De combien l'eau descend en plus pendant la fin (la bonde, puis le glouglou).
var ending_drop_m: float = 0.0
## Réveils après une noyade (traits sur le palmier).
var wakeups: int = 0
## Meilleur temps d'une partie finie (0 = jamais finie). Une partie finie se rouvre juste avant
## le drain (Q-25).
var best_time_s: float = 0.0
## L'eau retirée au moment de tirer la chaîne : une partie finie se rouvre là.
var pre_ending_removed_l: float = 0.0
## Combien de fois cette partie a été finie.
var finished_runs: int = 0
## Dossier des sauvegardes (les tests en utilisent un autre).
var save_dir: String = SaveSystem.DEFAULT_DIR
## Le catalogue papier est arrivé (caisse du premier appel) : il est enchaîné dans la cabine.
var catalogue_delivered: bool = false
## Les conversations au téléphone de la cabine (data/dialogues.json).
var dialogues: Dictionary = {}
## Vrai quand un menu (catalogue…) a la main : le joueur ne bouge plus.
var ui_open: bool = false
## Vrai pendant le mode déplacement d'un objet (G) : le joueur ne puise ni n'interagit.
var placing: bool = false

var _autosave_timer: float = 0.0
var _next_id: int = 1
var _deliveries_count: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	setup()


## Charge la configuration et démarre une partie neuve. Séparé de _ready pour les tests.
func setup(config_override: GameConfig = null) -> void:
	config = config_override if config_override else load(CONFIG_PATH) as GameConfig
	catalog = load(CATALOG_PATH) as CatalogDatabase
	# La forme de l'île (0.1.1) : la même pour le rendu, la collision et les décors.
	terrain = TerrainLogic.new(config.ground_y, config.build_radius_m, config.seabed_y)
	terrain.inland_above_y = config.sea_level_y + config.land_mask_above_sea_m
	dialogues = DialogueLogic.load_file()
	collection_rows = load_collection_rows()
	agency_orders = load_agency_orders()
	rng.randomize()
	if not terrain_changed.is_connected(_on_terrain_changed_marshes):
		terrain_changed.connect(_on_terrain_changed_marshes)
	new_game()


func new_game() -> void:
	_reset_state()
	add_zone("cuvette", find_free_spot("cuvette", config.basin_position))
	_morning_refill()
	_refill_reef()
	_new_agency_order()
	_refill_buried()
	_emit_all()


## Remet tout à zéro (sans cuvette) et prévient les vues qu'elles doivent tout effacer.
func _reset_state() -> void:
	var old_corners := terrain.clear_edits() if terrain else []
	ocean = OceanModel.new(config.total_ocean_volume_l, config.drain_threshold_ratio)
	bucket = BucketLogic.new(config.starting_bucket_capacity_l, config.bucket_fill_time_s)
	day = DayCycleLogic.new(config.day_length_s, config.start_hour)
	phone = PhoneLogic.new()
	catalogue_delivered = false
	milestones = MilestoneLogic.new(config.milestones)
	stock = Economy.empty_stock()
	carried = {}
	zones = []
	crates = []
	decor = []
	owned = {}
	bucket_unit_l = config.starting_bucket_capacity_l
	bucket_count = 1
	carry_capacity = config.hand_carry_capacity
	speed_multiplier = 1.0
	has_rake = false
	has_shovel = false
	shovel_sand = 0.0
	shovel_soil = TerrainLogic.Soil.SAND
	toolbar = ToolbarLogic.new(config.toolbar_slots)
	stamina = StaminaLogic.new(config.stamina_run_s, config.stamina_swim_s, config.stamina_regen_s, config.stamina_exhausted_ratio)
	survival = SurvivalLogic.new(config.food_empty_s, config.water_empty_s, config.starving_penalty_max, config.starving_penalty_time_s)
	pet = CrabPetLogic.new(config)
	collection = {}
	tide_pools = _make_tide_pools()
	gear = {}
	reef_shells = []
	weather = WeatherLogic.DEFAULT
	discovered = {}
	agency_order = {}
	wrecks = []
	wreck_hour = -1.0
	buried = []
	treasure_buried = false
	nests = []
	_turtle_day = -1
	planted = []
	coconuts_held = 0
	vessels = {}
	pickups = []
	stations = []
	mirrors = []
	slides = []
	pumps = []
	pipes = {}
	pipe_stock = 0
	auto_pumped_l = 0.0
	demo_done = false
	depot = {"id": "depot", "kind": "palette", "position": snap_item("palette", config.depot_position), "rotation_deg": 0.0}
	unlocked_tier = 1
	play_time_s = 0.0
	ending = null
	ending_drop_m = 0.0
	wakeups = 0
	best_time_s = 0.0
	pre_ending_removed_l = 0.0
	finished_runs = 0
	_autosave_timer = 0.0
	_next_id = 1
	_deliveries_count = 0
	game_reset.emit()
	if not old_corners.is_empty():
		terrain_changed.emit(old_corners)


func _process(delta: float) -> void:
	if ending != null:
		_step_ending(delta)  # le chronomètre est arrêté : la partie est finie
		return
	# Chronomètre de partie : ne tourne que quand le jeu n'est pas en pause (PRD §11).
	play_time_s += delta
	simulate(delta)
	_autosave_timer += delta
	if _autosave_timer >= config.autosave_interval_s:
		_autosave_timer = 0.0
		autosave()


## Fait avancer le monde de `delta` secondes : heure, séchage, objets à portions, faim et soif.
## Tout ce qui « vit avec le temps » passe par ici, pour que l'avance rapide (admin) le touche aussi.
func simulate(delta: float) -> void:
	if day.step(delta):
		_morning_refill()
		_refill_reef()
		_new_weather()
		if agency_order.is_empty() or agency_order.get("sent", false):
			_new_agency_order()
		_island_morning()
		_pet_morning_gift()
		if phone.on_new_morning(rng, config.offer_chance_per_day, offer_candidates()):
			phone_changed.emit()
		new_morning.emit()
	var base := day.evaporation_multiplier(config.night_evaporation_factor) * weather_value("dry")
	var flower := config.flower_chance_per_salt if weather == config.flower_weather and day.is_day() else 0.0
	_wind_rects = _all_rects()  # une seule fois par pas, pour toutes les zones (voir is_windward)
	for zone in zones:
		var logic: DryingLogic = zone.logic
		logic.flower_chance = flower
		var before := logic.deposit.duplicate()
		logic.step(delta, base * zone_boost(zone), rng)
		if logic.deposit != before:
			for k in logic.deposit:
				var n := int(logic.deposit[k]) - int(before.get(k, 0))
				if n > 0:
					_discover(String(k))
					salt_dropped.emit(zone, String(k), n)
	_wind_rects.clear()
	_run_tides(delta)
	_leak_vessels(delta)
	_run_marsh_series(delta)
	_run_wrecks(delta)
	_run_turtles()
	for st in stations:
		(st.logic as StationLogic).step(delta)
	_run_auto_pumps(delta)
	_run_slides(delta)
	check_milestones()
	survival.step(delta)
	pet.step(delta)
	stamina.set_max(survival.stamina_cap())
	survival_changed.emit()


## Saute `seconds` secondes de temps de jeu, par petits pas (pour garder le jour/nuit juste).
## Ne compte pas dans le temps de partie : c'est un outil de test.
func advance_time(seconds: float, step_s: float = 5.0) -> void:
	var left := seconds
	while left > 0.0:
		var d := minf(step_s, left)
		simulate(d)
		left -= d
	ocean_changed.emit()


## Bonus d'évaporation d'une zone : miroirs solaires proches (+50 % chacun, PRD §7), et depuis
## 0.1.24 le voisinage (moulin proche, côté du vent dégagé) et le dernier marais d'une série
## (plus lent). Voir `zone_boost_at`.
func zone_boost(zone: Dictionary) -> float:
	var k := zone_boost_at(zone, zone.position, item_rotation(zone))
	if is_marsh(zone) and _last_of_series.has(zone.get("id", "")):
		k *= config.marsh_last_dry_factor
	return k


## Le bonus qu'aurait `zone` posée en `pos` (aussi pour l'aperçu du mode G, 0.1.24).
func zone_boost_at(zone: Dictionary, pos: Vector3, rotation_deg: float = 0.0) -> float:
	var n := 0
	for m in mirrors:
		if (m.position as Vector3).distance_to(pos) <= config.mirror_radius_m:
			n += 1
	var k := 1.0 + config.mirror_bonus * n
	if near_windmill(pos):
		k *= 1.0 + config.windmill_boost
	if is_windward(zone, pos, rotation_deg):
		k *= 1.0 + config.windward_boost
	return k


## Un moulin-pompe à moins de `windmill_boost_radius_m` : le vent de ses pales.
func near_windmill(pos: Vector3) -> bool:
	for p in pumps:
		if String(p.kind) == "moulin_pompe" and Vector2(p.position.x - pos.x, p.position.z - pos.z).length() <= config.windmill_boost_radius_m:
			return true
	return false


## Face au vent dominant (l'est, +X) : rien de posé dans la bande de `windward_clear_m` qui
## longe le côté est de l'emprise de la zone.
func is_windward(zone: Dictionary, pos: Vector3, rotation_deg: float = 0.0) -> bool:
	var r: Rect2 = footprint_rect(item_kind(zone), pos, rotation_deg) if not is_marsh(zone) else _marsh_rect(zone)
	var band := Rect2(r.end.x, r.position.y, config.windward_clear_m, r.size.y)
	var rects: Array = _wind_rects if not _wind_rects.is_empty() else _all_rects()
	for pair in rects:
		if pair[0] != zone and band.intersects(pair[1]):
			return false
	return true


## [objet, emprise un peu rétrécie] de tout ce qui est posé (objets déplaçables et marais).
var _wind_rects: Array = []


func _all_rects() -> Array:
	var out := []
	for other in movable_items():
		out.append([other, item_rect(other).grow(-0.01)])
	for z in zones:
		if is_marsh(z):
			out.append([z, _marsh_rect(z).grow(-0.01)])
	return out


func _marsh_rect(zone: Dictionary) -> Rect2:
	var r := Rect2()
	var first := true
	for c: Vector2i in zone.get("cells", []):
		var cr := Rect2(c.x * config.grid_cell_m, c.y * config.grid_cell_m, config.grid_cell_m, config.grid_cell_m)
		r = cr if first else r.merge(cr)
		first = false
	return r


## Le multiplicateur de séchage d'une zone en ce moment (jour/nuit, temps, bonus).
func zone_dry_multiplier(zone: Dictionary) -> float:
	return day.evaporation_multiplier(config.night_evaporation_factor) * weather_value("dry") * zone_boost(zone)


## Secondes avant que la zone soit sèche à ce rythme (INF si elle ne sèche pas).
func zone_seconds_to_dry(zone: Dictionary) -> float:
	return (zone.logic as DryingLogic).seconds_to_dry(zone_dry_multiplier(zone))


# --- Le seau --------------------------------------------------------------------------------

## Remplit le seau dans la mer. Peut remonter un coquillage (et rarement une perle).
func fill_bucket() -> void:
	var taken := ocean.remove_water(bucket.missing_l())
	bucket.water_l += taken
	if rng.randf() < config.shell_chance_per_scoop:
		_gain_shell()
	ocean_changed.emit()
	bucket_changed.emit()
	check_milestones()


## Verse le seau dans une zone de séchage. Renvoie la quantité acceptée.
func pour_bucket_into(zone: Dictionary) -> float:
	var logic: DryingLogic = zone.logic
	var accepted := logic.add_water(bucket.water_l)
	bucket.water_l -= accepted
	# 0.1.20 : un marais dans le sable boit une part de l'eau (elle retourne à la mer).
	var lost := accepted * marsh_loss(zone)
	if lost > 0.0:
		logic.water_l -= lost
		ocean.return_water(lost)
		ocean_changed.emit()
	bucket_changed.emit()
	return accepted


## Vide le seau ailleurs : sur le sable ou dans la mer, l'eau retourne à l'océan (M-33, M-34).
func pour_bucket_out() -> void:
	ocean.return_water(bucket.empty_out())
	ocean_changed.emit()
	bucket_changed.emit()


# --- Arrosoir et seau percé (0.1.24, PRD §19.31) ---------------------------------------------

func is_vessel(tool: String) -> bool:
	return config.vessel_capacity_l.has(tool)


func vessel_capacity(tool: String) -> float:
	return float(config.vessel_capacity_l.get(tool, 0.0))


func vessel_l(tool: String) -> float:
	return float(vessels.get(tool, 0.0))


## Remplit le récipient dans la mer (d'un coup). Renvoie les litres puisés.
func fill_vessel(tool: String) -> float:
	if not is_vessel(tool) or not owns_tool(tool):
		return 0.0
	var taken := ocean.remove_water(vessel_capacity(tool) - vessel_l(tool))
	vessels[tool] = vessel_l(tool) + taken
	ocean_changed.emit()
	bucket_changed.emit()
	check_milestones()
	return taken


## Les zones que l'eau versée en `point` atteint : l'arrosoir arrose tout à moins de
## `watering_radius_m` ; le seau percé verse dans la seule zone visée (la plus proche, à 1,5 m).
func vessel_targets(tool: String, point: Vector3) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var reach := config.watering_radius_m if tool == "arrosoir" else 1.5
	var best := INF
	for z in zones:
		var d := _distance_to_zone(z, point)
		if d > reach or (z.logic as DryingLogic).free_space_l() <= 0.0:
			continue
		if tool == "arrosoir":
			out.append(z)
		elif d < best:
			best = d
			out.clear()
			out.append(z)
	return out


## Distance au sol de `point` à l'emprise d'une zone (0 dedans).
func _distance_to_zone(z: Dictionary, point: Vector3) -> float:
	var r: Rect2 = _marsh_rect(z) if is_marsh(z) else item_rect(z)
	var p := Vector2(point.x, point.z)
	var c := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	return p.distance_to(c)


## Verse le récipient vers `point` : l'eau est partagée entre les zones atteintes (en plusieurs
## tours : ce qu'une zone pleine refuse va aux autres). Renvoie les litres versés.
func pour_vessel(tool: String, point: Vector3) -> float:
	var targets := vessel_targets(tool, point)
	var left := vessel_l(tool)
	var poured := 0.0
	for _pass in 4:
		if targets.is_empty() or left <= 0.001:
			break
		var share := left / targets.size()
		var still: Array[Dictionary] = []
		for z in targets:
			var logic: DryingLogic = z.logic
			var acc := logic.add_water(share)
			var lost := acc * marsh_loss(z)
			if lost > 0.0:
				logic.water_l -= lost
				ocean.return_water(lost)
			left -= acc
			poured += acc
			if logic.free_space_l() > 0.0:
				still.append(z)
		targets = still
	vessels[tool] = maxf(left, 0.0)
	ocean_changed.emit()
	bucket_changed.emit()
	return poured


## Le seau percé fuit (l'eau retourne à la mer), même posé dans la barre.
func _leak_vessels(delta: float) -> void:
	for tool in config.vessel_leak_lps:
		var have := vessel_l(String(tool))
		if have <= 0.0:
			continue
		var lost := minf(have, float(config.vessel_leak_lps[tool]) * delta)
		vessels[tool] = have - lost
		ocean.return_water(lost)
		if int(have) != int(have - lost):
			bucket_changed.emit()  # la case de la barre affiche les litres


# --- Récolte, transport, palette -----------------------------------------------------------

func carried_count() -> int:
	return Economy.count(carried)


## La place pour un matériau (0.1.4) : chaque case de la barre en porte `carry_capacity`
## (64, 128 avec la brouette). Sans `key` : la plus grande place, pour n'importe quel matériau
## (une case vide, sinon la case la moins pleine).
func carry_space(key: String = "") -> int:
	if key != "":
		if not has_slot_for(key):
			return 0
		return maxi(carry_capacity - int(carried.get(key, 0)), 0)
	var best := carry_capacity if toolbar.first_free() >= 0 else 0
	for k in carried:
		best = maxi(best, carry_capacity - int(carried[k]))
	return best


## Ajoute des ressources dans les bras, dans la limite de ce qu'on peut porter.
## Renvoie ce qui n'a pas pu être pris.
## Chaque matériau porté prend une case de la barre : sans case libre, on ne le prend pas.
func add_carried(items: Dictionary) -> Dictionary:
	_sync_toolbar()
	var leftover := {}
	for k in items:
		var key := String(k)
		var n := int(items[k])
		var take := mini(n, carry_space(key))
		if take > 0:
			carried[key] = int(carried.get(key, 0)) + take
			toolbar.put(key)
			_discover(key)
		if n - take > 0:
			leftover[key] = n - take
	carried_changed.emit()
	_sync_toolbar()
	return leftover


## Vrai si ce matériau a déjà sa case dans la barre, ou s'il reste une case vide.
func has_slot_for(key: String) -> bool:
	return toolbar.index_of(key) >= 0 or toolbar.first_free() >= 0


## Vrai si on peut prendre au moins une unité de ce matériau (place dans les bras ET une case).
func can_carry(key: String) -> bool:
	return carry_space(key) > 0


## Récolte le dépôt d'une zone (M-39) : quelques unités par clic à la main, tout d'un coup
## avec le râteau. Ce qu'on ne peut pas porter reste dans la zone.
## `resource` : le tas visé (un tas par matériau) ; vide = n'importe lequel.
func harvest(zone: Dictionary, resource: String = "") -> void:
	var logic: DryingLogic = zone.logic
	# Le râteau ramasse tout d'un coup, mais seulement si on le TIENT (barre d'outils).
	var budget := 1 << 30 if current_tool() == "rateau" else config.manual_harvest_per_click
	var keys: Array = [resource] if resource != "" else Economy.RESOURCES.duplicate()
	if resource == "":
		keys.reverse()  # les plus rares d'abord
	# Chaque matériau a sa case et sa limite (64 par case) : on prend ce qui rentre, le reste reste.
	for key: String in keys:
		if budget <= 0:
			break
		if key == "fleur_de_sel" and not has_gear("lousse"):
			continue  # 0.1.22 : la fleur de sel ne se cueille qu'avec la lousse
		var n := mini(budget, carry_space(key))
		if n <= 0:
			continue
		var got := logic.take_some(n, key)
		var leftover := add_carried(got)
		Economy.add(logic.deposit, leftover)
		budget -= Economy.count(got) - Economy.count(leftover)


# --- Barre d'outils (M-27) --------------------------------------------------------------------

## Les outils, dans l'ordre où ils prennent une case quand on les obtient.
const TOOLS: Array[String] = ["seau", "pelle", "rateau", "tuyaux", "detecteur", "noix_de_coco", "arrosoir", "seau_perce"]


## Ce que contient la case tenue : un outil ("seau", "rateau", "tuyaux"), un matériau porté
## ("sel"…) ou "" (les mains nues).
func current_tool() -> String:
	return toolbar.current()


## Vrai si on possède cet outil (le seau dès le départ, le râteau après achat) ou si on porte ce matériau.
func owns_tool(tool: String) -> bool:
	if Economy.RESOURCES.has(tool):
		return int(carried.get(tool, 0)) > 0
	match tool:
		"", "seau":
			return true
		"pelle":
			return has_shovel
		"rateau":
			return has_rake
		"tuyaux":
			return pipe_stock > 0 or not pipes.is_empty()
		"detecteur":
			return has_gear("detecteur")
		"noix_de_coco":
			return coconuts_held > 0
		"arrosoir", "seau_perce":
			return has_gear(tool)
	return false


func select_tool(index: int) -> void:
	if toolbar.select(index, owns_tool):
		_on_tool_changed()


func cycle_tool(direction: int) -> void:
	if toolbar.cycle(direction, owns_tool):
		_on_tool_changed()


func _on_tool_changed() -> void:
	bucket.cancel_fill()
	tool_changed.emit()


## Échange deux cases de la barre (menu de réorganisation). On garde en main ce qu'on tenait.
func swap_slots(a: int, b: int) -> bool:
	if not toolbar.swap(a, b):
		return false
	tool_changed.emit()
	return true


## Range la barre : libère les cases des matériaux qu'on ne porte plus et des outils perdus,
## puis donne une case aux outils possédés (d'abord) et aux matériaux portés qui n'en ont pas.
func _sync_toolbar() -> void:
	var before := toolbar.slots.duplicate()
	var before_selected := toolbar.selected
	for i in toolbar.slots.size():
		var entry := toolbar.slots[i]
		if entry != "" and not owns_tool(entry):
			toolbar.slots[i] = ""
	for t in TOOLS:
		if owns_tool(t):
			toolbar.put(t)
	for key in Economy.RESOURCES:
		if int(carried.get(key, 0)) > 0:
			toolbar.put(key)
	toolbar.ensure_valid(owns_tool)
	if toolbar.slots != before or toolbar.selected != before_selected:
		if toolbar.selected != before_selected or toolbar.slots[toolbar.selected] != before[before_selected]:
			bucket.cancel_fill()
		tool_changed.emit()


## Pose tout ce qu'on porte sur la palette : ça devient le stock utilisable pour payer.
func unload_to_stock() -> int:
	var n := carried_count()
	Economy.add(stock, carried)
	carried = {}
	carried_changed.emit()
	_sync_toolbar()
	stock_changed.emit()
	return n


# --- Zones de séchage ----------------------------------------------------------------------

func add_zone(kind: String, position: Vector3) -> Dictionary:
	var logic: DryingLogic
	match kind:
		"cuvette":
			logic = DryingLogic.new(config.basin_capacity_l, config.basin_dry_time_s)
		"bache":
			logic = DryingLogic.new(config.tarp_capacity_l, config.tarp_dry_time_s)
		"bassin_bois":
			logic = DryingLogic.new(config.wood_basin_capacity_l, config.wood_basin_dry_time_s)
		_:
			push_error("Type de zone inconnu : %s" % kind)
			return {}
	logic.liters_per_salt = config.liters_per_salt
	logic.mineral_chance = config.mineral_chance
	logic.rare_mineral_chance = config.rare_mineral_chance
	var zone := {"id": _new_id("zone"), "kind": kind, "position": position, "logic": logic}
	zones.append(zone)
	zone_added.emit(zone)
	network_changed.emit()
	return zone


# --- Marais salants, marées, flaques (0.1.20, PRD §19.27) ---------------------------------

func is_marsh(zone: Dictionary) -> bool:
	return String(zone.get("kind", "")) == "marais"


func marshes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for z in zones:
		if is_marsh(z):
			out.append(z)
	return out


## La case de 1 m qui contient ce point (X, Z).
func cell_at(pos: Vector3) -> Vector2i:
	return TerrainLogic.cell_of(pos.x, pos.z)


## Le marais qui contient cette case, ou {}.
func marsh_at_cell(cell: Vector2i) -> Dictionary:
	for z in zones:
		if is_marsh(z) and (z.cells as Array).has(cell):
			return z
	return {}


## Le trou sous ce point, s'il fait un nouveau marais (cases), sinon [].
func hole_region_at(pos: Vector3) -> Array[Vector2i]:
	var cell := cell_at(pos)
	var none: Array[Vector2i] = []
	if not marsh_at_cell(cell).is_empty():
		return none
	var taken := {}
	for m in marshes():
		for c in m.cells:
			taken[c] = true
	var excluded := func(c: Vector2i) -> bool:
		return taken.has(c) or _marsh_cell_excluded(c)
	var cells := SaltMarsh.region(terrain, cell, config.marsh_min_depth_m, config.marsh_max_cells, excluded)
	if not SaltMarsh.is_valid(terrain, cells, config.marsh_min_cells, config.marsh_max_spread_m):
		return none
	return cells


## Une case qui ne peut pas faire partie d'un marais : dans la mer, ou trop loin.
func _marsh_cell_excluded(c: Vector2i) -> bool:
	var mid := Vector2((c.x + 0.5) * config.grid_cell_m, (c.y + 0.5) * config.grid_cell_m)
	return _spot_reason(mid) != ""


## Verser le seau dans un trou (0.1.20) : le trou devient un marais (ou on verse dans le sien).
## Renvoie la quantité versée (0 : pas de trou ici).
func pour_bucket_into_hole(pos: Vector3) -> float:
	if bucket.is_empty():
		return 0.0
	var zone := marsh_at_cell(cell_at(pos))
	if zone.is_empty():
		var cells := hole_region_at(pos)
		if cells.is_empty():
			return 0.0
		zone = add_marsh(cells)
	return pour_bucket_into(zone)


## Crée un marais sur ces cases (déjà vérifiées).
func add_marsh(cells: Array) -> Dictionary:
	if cells.is_empty():
		return {}
	var logic := DryingLogic.new(config.marsh_l_per_cell * cells.size(), config.marsh_dry_time_s)
	logic.liters_per_salt = config.liters_per_salt
	logic.mineral_chance = config.mineral_chance
	logic.rare_mineral_chance = config.rare_mineral_chance
	var typed: Array[Vector2i] = []
	for c in cells:
		typed.append(c)
	var zone := {"id": _new_id("zone"), "kind": "marais", "cells": typed, "logic": logic, "rotation_deg": 0.0}
	_update_marsh_geometry(zone)
	zones.append(zone)
	zone_added.emit(zone)
	network_changed.emit()
	return zone


## La position du marais (le milieu de sa case centrale, au niveau de son fond) et ses tas.
func _update_marsh_geometry(zone: Dictionary) -> void:
	var cells: Array = zone.cells
	var c := SaltMarsh.center_cell(cells)
	var g := config.grid_cell_m
	zone.position = Vector3((c.x + 0.5) * g, SaltMarsh.floor_y(terrain, cells), (c.y + 0.5) * g)
	# 0.1.22 : un fond de terre donne du sel rose.
	zone["rose"] = SaltMarsh.earth_ratio(terrain, cells) >= config.rose_min_earth_ratio
	(zone.logic as DryingLogic).rose_chance = config.rose_chance_per_salt if zone.rose else 0.0
	zone.piles = _marsh_pile_spots(zone)


## Une case libre au bord du trou pour chaque tas (les plus proches du centre d'abord).
func _marsh_pile_spots(zone: Dictionary) -> Dictionary:
	var g := config.grid_cell_m
	var blockers := _blockers_except(zone, true, true, false)
	for m in marshes():
		if m != zone:
			blockers.append_array(_marsh_shapes_of(m, true))
	var rim := SaltMarsh.rim(zone.cells)
	var center := Vector2(zone.position.x, zone.position.z)
	rim.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := Vector2((a.x + 0.5) * g, (a.y + 0.5) * g).distance_squared_to(center)
		var db := Vector2((b.x + 0.5) * g, (b.y + 0.5) * g).distance_squared_to(center)
		return da < db if absf(da - db) > 1e-6 else (a.x < b.x or (a.x == b.x and a.y < b.y)))
	var out := {}
	var keys: Array = marsh_pile_keys(zone)
	for cell in rim:
		if out.size() >= keys.size():
			break
		if SaltMarsh.is_dug(terrain, cell, config.marsh_min_depth_m * 0.5) or _marsh_cell_excluded(cell):
			continue
		if _cell_blocked(cell, blockers):
			continue
		var p := Vector2((cell.x + 0.5) * g, (cell.y + 0.5) * g)
		out[keys[out.size()]] = Vector3(p.x, terrain.height(p.x, p.y), p.y)
	# Pas assez de place autour : les tas restants se posent au bord du marais (jamais perdus).
	for k in keys:
		if not out.has(k):
			out[k] = zone.position + Vector3(0.0, 0.05, 0.0)
	return out


## Les formes d'un marais pour les autres : ses tas, et ses cases s'il n'est pas vide
## (`with_cells_if_full`) ou toujours (placement : on ne pose rien dans un trou).
func _marsh_shapes_of(zone: Dictionary, for_digging: bool) -> Array:
	var out := []
	var g := config.grid_cell_m
	for k in zone.get("piles", {}):
		var p: Vector3 = zone.piles[k]
		out.append(PlacementGrid.rect_shape(Rect2(p.x - g / 2.0, p.z - g / 2.0, g, g)))
	if not for_digging or not marsh_is_empty(zone):
		for c: Vector2i in zone.cells:
			out.append(PlacementGrid.rect_shape(Rect2(c.x * g, c.y * g, g, g)))
	return out


func _marsh_shapes(except: Dictionary, for_digging: bool) -> Array:
	var out := []
	for m in marshes():
		if m != except:
			out.append_array(_marsh_shapes_of(m, for_digging))
	return out


func marsh_is_empty(zone: Dictionary) -> bool:
	var logic: DryingLogic = zone.logic
	return logic.water_l <= 0.01 and not logic.has_deposit()


## Ce qu'un marais perd de l'eau versée : rien si sa bordure est en terre, sinon une part.
func marsh_loss(zone: Dictionary) -> float:
	if not is_marsh(zone):
		return 0.0
	if SaltMarsh.earth_ratio(terrain, SaltMarsh.rim(zone.cells)) >= config.marsh_earth_rim_ratio:
		return 0.0
	return config.marsh_sand_loss


## Le sable a bougé : chaque marais vide suit son trou (il grandit, rétrécit, ou disparaît).
## Un marais qui n'est pas vide ne bouge pas (la pelle n'y touche pas).
func _on_terrain_changed_marshes(_corners: Array) -> void:
	for zone in marshes():
		if not marsh_is_empty(zone):
			continue
		var taken := {}
		for m in marshes():
			if m != zone:
				for c in m.cells:
					taken[c] = true
		var excluded := func(c: Vector2i) -> bool:
			return taken.has(c) or _marsh_cell_excluded(c)
		var start: Vector2i = SaltMarsh.center_cell(zone.cells)
		var cells: Array[Vector2i] = []
		for c: Vector2i in zone.cells:
			cells = SaltMarsh.region(terrain, c, config.marsh_min_depth_m, config.marsh_max_cells, excluded)
			if not cells.is_empty():
				start = c
				break
		if not SaltMarsh.is_valid(terrain, cells, config.marsh_min_cells, config.marsh_max_spread_m):
			remove_zone(zone)
			continue
		zone.cells = cells
		(zone.logic as DryingLogic).capacity_l = config.marsh_l_per_cell * cells.size()
		_update_marsh_geometry(zone)
		item_moved.emit(zone)


## Retire une zone (un marais rebouché).
func remove_zone(zone: Dictionary) -> void:
	if not zones.has(zone):
		return
	zones.erase(zone)
	zone_removed.emit(zone)
	network_changed.emit()


func _zone_to_dict(z: Dictionary) -> Dictionary:
	var d := {"kind": z.kind, "position": _v2a(z.position), "rotation_deg": item_rotation(z), "logic": (z.logic as DryingLogic).to_dict()}
	if is_marsh(z):
		d["cells"] = (z.cells as Array).map(func(c: Vector2i): return [c.x, c.y])
	return d


func _cells_from(raw: Variant) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if raw is Array:
		for c in raw:
			if c is Array and c.size() == 2:
				out.append(Vector2i(int(c[0]), int(c[1])))
	return out


## Les marées : un marais près de la mer, au fond plus bas que la surface, se remplit tout seul ;
## les flaques se garnissent à marée basse et se vident à marée haute.
func _run_tides(delta: float) -> void:
	var surface := water_level_y()
	for zone in marshes():
		var logic: DryingLogic = zone.logic
		if logic.free_space_l() <= 0.0 or float(zone.position.y) >= surface:
			continue
		if not zone.has("sea") or zone.get("sea_cells_n", -1) != (zone.cells as Array).size():
			zone.sea = SaltMarsh.touches_sea(zone.cells, config.marsh_sea_reach_cells, func(c: Vector2i) -> bool:
				return sea_at((c.x + 0.5) * config.grid_cell_m, (c.y + 0.5) * config.grid_cell_m))
			zone.sea_cells_n = (zone.cells as Array).size()
		if not zone.sea:
			continue
		var want := config.marsh_tide_fill_lps_per_cell * (zone.cells as Array).size() * delta
		var taken := ocean.remove_water(minf(want, logic.free_space_l()))
		logic.add_water(taken)
	_update_tide_pools()


func _make_tide_pools() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var want_y := config.sea_level_y - config.tide_pool_depth_m
	for i in mini(config.tide_pool_count, config.tide_pool_angles_deg.size()):
		var a := deg_to_rad(config.tide_pool_angles_deg[i])
		var dir := Vector2(cos(a), sin(a))
		var coast := terrain.coast_at(a)
		var best := coast
		var best_err := INF
		var r := coast - 8.0
		while r < coast + 6.0:
			var p := dir * r
			var err := absf(terrain.base_height(p.x, p.y) - want_y)
			if err < best_err:
				best_err = err
				best = r
			r += 0.25
		var pos := dir * best
		out.append({"position": Vector3(pos.x, want_y, pos.y), "items": [], "low": -1, "pet_low": -1})
	return out


func tide_is_low() -> bool:
	return TideLogic.is_low(day.hour(), config.tide_high_hour)


## Une flaque est découverte quand la surface est sous son bord.
func tide_pool_uncovered(pool: Dictionary) -> bool:
	return water_level_y() < float(pool.position.y) - 0.02


func _update_tide_pools() -> void:
	var low := TideLogic.low_index(day.day_index, day.hour(), config.tide_high_hour)
	var changed := false
	var low_now := tide_is_low()
	for pool in tide_pools:
		if low_now and int(pool.low) != low:
			pool.low = low
			pool.items = []
			for k in rng.randi_range(1, maxi(config.tide_pool_max_items, 1)):
				pool.items.append(_pick_pool_item())
			changed = true
		elif TideLogic.is_high(day.hour(), config.tide_high_hour) and not (pool.items as Array).is_empty():
			pool.items = []  # la marée haute les remporte
			changed = true
		# Pinçon fouille la flaque où se tient le joueur : un coquillage de plus par marée basse.
		if low_now and int(pool.pet_low) != low and pet_follows() \
				and pet_position.distance_to(pool.position) <= config.tide_pool_pet_reach_m \
				and player_position.distance_to(pool.position) <= config.tide_pool_pet_reach_m:
			pool.pet_low = low
			pool.items.append("coquillage")
			pet_reacted.emit(CrabPose.Anim.HAPPY)
			changed = true
	if changed:
		tide_pools_changed.emit()


func _pick_pool_item() -> String:
	var total := 0
	for k in config.tide_pool_items:
		total += int(config.tide_pool_items[k])
	var roll := rng.randi_range(1, maxi(total, 1))
	var keys: Array = config.tide_pool_items.keys()
	keys.sort()
	for k in keys:
		roll -= int(config.tide_pool_items[k])
		if roll <= 0:
			return String(k)
	return "coquillage"


## Pinçon suit-il le joueur ? (2 cœurs et plus, 0.1.19)
func pet_follows() -> bool:
	return pet.hearts() >= config.pet_follow_hearts


## Ramasse la première trouvaille d'une flaque. Renvoie son id ("" si rien, ou pas de place).
func take_from_pool(pool: Dictionary) -> String:
	var items: Array = pool.items
	if items.is_empty() or not tide_pool_uncovered(pool):
		return ""
	var what := String(items[0])
	if what == "coquillage":
		if not can_carry("coquillages"):
			return ""
		_gain_shell()
	else:
		add_to_collection(what)
	items.remove_at(0)
	tide_pools_changed.emit()
	return what


## Une trouvaille de plus dans la collection.
func add_to_collection(id: String, n: int = 1) -> void:
	collection[id] = int(collection.get(id, 0)) + n
	collection_changed.emit()


# --- La nuit et la collection (0.1.21, PRD §19.28) ----------------------------------------

## La liste de la vitrine, lue dans les données : [{id, items: [..]}, …].
static func load_collection_rows(path := "res://data/collection.json") -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var data = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary):
		return []
	return data.get("rows", [])


## Toutes les cases de la vitrine, dans l'ordre.
func collection_slots() -> Array[String]:
	var out: Array[String] = []
	for row in collection_rows:
		for id in row.get("items", []):
			out.append(String(id))
	return out


func has_found(id: String) -> bool:
	return int(collection.get(id, 0)) > 0


## Combien de cases de la vitrine sont remplies.
func collection_found_count() -> int:
	var n := 0
	for id in collection_slots():
		if has_found(id):
			n += 1
	return n


## Un coquillage de plus dans les bras : sa forme va dans la collection ; parfois une perle.
func _gain_shell() -> void:
	add_carried({"coquillages": 1})
	add_to_collection(_pick_weighted(config.shell_shapes, "coq_petoncle"))
	if rng.randf() < config.pearl_chance_per_shell:
		add_carried({"perles": 1})
		add_to_collection("perle")


func _pick_weighted(weights: Dictionary, fallback: String) -> String:
	var total := 0
	for k in weights:
		total += int(weights[k])
	var roll := rng.randi_range(1, maxi(total, 1))
	var keys: Array = weights.keys()
	keys.sort()
	for k in keys:
		roll -= int(weights[k])
		if roll <= 0:
			return String(k)
	return fallback


func has_gear(id: String) -> bool:
	return gear.get(id, false)


## L'équipement change des réglages : le masque rend la nage moins chère en endurance.
func _apply_gear() -> void:
	if stamina:
		stamina.swim_s = config.stamina_swim_s / (config.mask_swim_cost if has_gear("masque") else 1.0)
	gear_changed.emit()


## Dormir dans le hamac (la nuit seulement) : le temps passe jusqu'au matin, tout ce qui vit
## avec le temps avance (séchage de nuit, faim, soif, Pinçon). Le chronomètre de la partie ne
## compte pas la nuit sautée (Q-30). Renvoie faux le jour.
func sleep(spot: Vector3 = FAR_AWAY) -> bool:
	if day.is_day():
		return false
	var hours := fposmod(config.wake_hour - day.hour(), 24.0)
	advance_time(hours / 24.0 * day.day_length_s)
	slept.emit(spot)
	return true


## Le récif : un point au hasard dans l'anneau où le fond est entre `reef_min_depth_m` et
## `reef_max_depth_m` sous la mer. FAR_AWAY si on n'en trouve pas.
func random_reef_spot(gen: RandomNumberGenerator = null) -> Vector3:
	var g := gen if gen else rng
	for _try in 60:
		var a := g.randf_range(0.0, TAU)
		var coast := terrain.coast_at(a)
		var r := g.randf_range(coast + 2.0, coast + 16.0)
		var x := cos(a) * r
		var z := sin(a) * r
		var y := terrain.height(x, z)
		var depth := config.sea_level_y - y
		if depth >= config.reef_min_depth_m and depth <= config.reef_max_depth_m:
			return Vector3(x, y, z)
	return FAR_AWAY


## Chaque matin, de nouveaux coquillages au fond du récif.
func _refill_reef() -> void:
	reef_shells = []
	for i in config.reef_shells_per_morning:
		var p := random_reef_spot()
		if p != FAR_AWAY:
			reef_shells.append(p)
	reef_changed.emit()


## Ramasse le coquillage du récif n° `index` (en plongée). Vrai si c'est fait.
func take_reef_shell(index: int) -> bool:
	if index < 0 or index >= reef_shells.size() or not can_carry("coquillages"):
		return false
	reef_shells.remove_at(index)
	_gain_shell()
	reef_changed.emit()
	return true


## Un poisson vu de près avec le masque : il entre dans la collection (une seule fois).
func see_fish(species: String) -> bool:
	if has_found(species) or not has_gear("masque"):
		return false
	add_to_collection(species)
	return true


# --- Le temps qu'il fait, fleur de sel, sel rose, commandes (0.1.22, PRD §19.29) ----------

## Une valeur de la table du temps pour le temps du jour (séchage, soif, vent…).
func weather_value(key: String) -> float:
	return WeatherLogic.value(config.weather_table, weather, key)


## Chaque matin : le temps de la journée (le temps de la veille compte moitié moins).
func _new_weather() -> void:
	weather = WeatherLogic.pick(config.weather_table, rng, weather)
	_apply_weather()


func set_weather(id: String) -> void:
	if config.weather_table.has(id):
		weather = id
		_apply_weather()


func _apply_weather() -> void:
	if survival:
		survival.thirst_factor = weather_value("thirst")
	weather_changed.emit()


## Vrai si la ressource a sa place partout (palette, bon de commande) : les ressources de base
## toujours, la fleur de sel et le sel rose une fois trouvés (Q-29).
func is_known(resource: String) -> bool:
	return not Economy.FOUND_ONLY.has(resource) or discovered.has(resource)


## Les ressources connues, dans l'ordre d'Economy.RESOURCES.
func known_resources() -> Array[String]:
	var out: Array[String] = []
	for r in Economy.RESOURCES:
		if is_known(r):
			out.append(r)
	return out


func _discover(resource: String, emit := true) -> void:
	if is_known(resource) or not Economy.FOUND_ONLY.has(resource):
		return
	discovered[resource] = true
	if emit:
		resources_discovered.emit()


## Les tas d'un marais : ceux des zones, plus le sel rose si son fond est en terre.
func marsh_pile_keys(zone: Dictionary) -> Array:
	var keys: Array = config.pile_slots.keys()
	keys.sort()
	if zone.get("rose", false):
		keys.append("sel_rose")
	return keys


## Cueillir la fleur de sel d'une zone : seulement avec la lousse.
func harvest_flower(zone: Dictionary) -> bool:
	if not has_gear("lousse") or int((zone.logic as DryingLogic).deposit.get("fleur_de_sel", 0)) <= 0:
		return false
	var before := Economy.count(carried)
	harvest(zone, "fleur_de_sel")
	return Economy.count(carried) > before


## Les commandes de l'agence, lues dans les données : [{id, price, surprise}, …].
static func load_agency_orders(path := "res://data/orders.json") -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var data = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary):
		return []
	return data.get("orders", [])


func agency_order_def(id: String) -> Dictionary:
	for o in agency_orders:
		if String(o.get("id", "")) == id:
			return o
	return {}


## Le prix de la commande du moment ({} s'il n'y en a pas).
func agency_order_price() -> Dictionary:
	var d := agency_order_def(String(agency_order.get("id", "")))
	var out := {}
	var price: Dictionary = d.get("price", {})
	for k in price:
		out[String(k)] = int(price[k])
	return out


## Une commande ne demande que des ressources déjà trouvées (pas de sel rose avant un marais de terre).
func agency_order_candidates() -> Array:
	var out := []
	for o in agency_orders:
		var ok := true
		for k in o.get("price", {}):
			if not is_known(String(k)):
				ok = false
		if ok:
			out.append(String(o.id))
	return out


## Une nouvelle commande (jamais la même que la précédente quand on a le choix).
func _new_agency_order() -> void:
	var list := agency_order_candidates()
	var last := String(agency_order.get("id", ""))
	if list.size() > 1:
		list.erase(last)
	if list.is_empty():
		agency_order = {}
	else:
		# La toute première commande d'une partie est la première de la liste (la plus simple).
		var id: String = list[0] if last == "" else list[rng.randi_range(0, list.size() - 1)]
		agency_order = {"id": id, "sent": false}
	agency_order_changed.emit()


func can_send_agency_order() -> bool:
	return not agency_order.is_empty() and not agency_order.get("sent", false) and Economy.can_afford(available_resources(), agency_order_price())


## Envoie la commande : on paie comme un achat (bras puis palette), l'avion emporte le paiement et
## largue la caisse surprise. Une nouvelle commande arrive le lendemain matin.
func send_agency_order() -> Dictionary:
	if not can_send_agency_order():
		return {}
	var price := agency_order_price()
	if not Economy.pay_from([carried, stock], price):
		return {}
	for k in carried.keys():
		if int(carried[k]) <= 0:
			carried.erase(k)
	carried_changed.emit()
	_sync_toolbar()
	var d := agency_order_def(String(agency_order.id))
	var crate := _new_crate([String(d.get("surprise", ""))], 0.0)
	crate["paid"] = price
	crate["surprise"] = true
	agency_order.sent = true
	stock_changed.emit()
	agency_order_changed.emit()
	crate_added.emit(crate, true)
	autosave()
	return crate


# --- Explorer et vivre sur l'île (0.1.23, PRD §19.30) ---------------------------------------

## Chaque matin : une bouteille peut-être, l'heure de l'épave du jour, un objet enterré de plus,
## et une noix de coco au pied de chaque cocotier planté devenu palmier.
func _island_morning() -> void:
	if rng.randf() < config.bottle_chance_per_morning:
		var spot := _random_beach_spot()
		if spot.is_finite():
			add_pickup("bottle", spot)
	wreck_hour = rng.randf_range(config.wreck_hour_min, config.wreck_hour_max)
	_refill_buried()
	for pl in planted:
		if is_grown(pl):
			var spot: Vector3 = pl.position + Vector3(0.6, 0.0, 0.4)
			if not _has_pickup_at("coconut", spot):
				spot.y = terrain.height(spot.x, spot.z) + 0.02
				add_pickup("coconut", spot)
	planted_changed.emit()


# Marais en série --------------------------------------------------------------------------

## Deux marais sont reliés si une case de l'un est à `marsh_link_gap_cells` case(s) ou moins
## d'une case de l'autre (des cases vides entre les deux).
func marshes_linked(a: Dictionary, b: Dictionary) -> bool:
	var gap := config.marsh_link_gap_cells + 1
	for ca: Vector2i in a.cells:
		for cb: Vector2i in b.cells:
			if maxi(absi(ca.x - cb.x), absi(ca.y - cb.y)) <= gap:
				return true
	return false


## Pour chaque marais, celui (plus bas) vers lequel son eau descend ({} s'il n'y en a pas) :
## le plus bas des marais reliés et plus bas que lui.
func marsh_flow_targets() -> Dictionary:
	var out := {}
	var list := marshes()
	for a in list:
		var best: Dictionary = {}
		for b in list:
			if b == a or float(b.position.y) >= float(a.position.y) - 0.01 or not marshes_linked(a, b):
				continue
			if best.is_empty() or float(b.position.y) < float(best.position.y):
				best = b
		out[a.id] = best
	return out


## Le dernier marais d'une série : il reçoit l'eau d'un autre et n'en envoie à aucun.
func is_last_of_series(zone: Dictionary, targets: Dictionary) -> bool:
	if not (targets.get(zone.id, {}) as Dictionary).is_empty():
		return false
	for k in targets:
		var t: Dictionary = targets[k]
		if not t.is_empty() and t.id == zone.id:
			return true
	return false


## Les marais qui finissent une série (recalculé à chaque pas de `simulate`).
var _last_of_series: Dictionary = {}


func _run_marsh_series(delta: float) -> void:
	var list := marshes()
	if list.size() < 2:
		_last_of_series.clear()
		for m in list:
			(m.logic as DryingLogic).mineral_chance = config.mineral_chance
			(m.logic as DryingLogic).rare_mineral_chance = config.rare_mineral_chance
		return
	var targets := marsh_flow_targets()
	_last_of_series.clear()
	for m in list:
		var logic: DryingLogic = m.logic
		var last := is_last_of_series(m, targets)
		if last:
			_last_of_series[m.id] = true
		logic.mineral_chance = config.mineral_chance * (config.marsh_last_mineral_mult if last else 1.0)
		logic.rare_mineral_chance = config.rare_mineral_chance * (config.marsh_last_rare_mult if last else 1.0)
		var t: Dictionary = targets.get(m.id, {})
		if t.is_empty() or logic.fill_ratio() <= config.marsh_link_above_ratio:
			continue
		var move := minf(config.marsh_link_lps * delta, logic.water_l - logic.capacity_l * config.marsh_link_above_ratio)
		var accepted := (t.logic as DryingLogic).add_water(maxf(move, 0.0))
		logic.water_l -= accepted


# Bouteilles à la mer ----------------------------------------------------------------------

## Le dessin de la prochaine bouteille : d'abord ceux qu'on n'a pas, dans l'ordre ; puis au hasard.
func next_bottle_drawing() -> String:
	for d in config.bottle_drawings:
		if not has_found("bouteille_" + d):
			return d
	return config.bottle_drawings[rng.randi_range(0, config.bottle_drawings.size() - 1)]


func _open_bottle() -> void:
	var d := next_bottle_drawing()
	add_to_collection("bouteille_" + d)
	if d == "carte" and not treasure_buried:
		treasure_buried = true
		buried.append({"kind": "tresor", "position": Vector3(config.treasure_spot.x, terrain.height(config.treasure_spot.x, config.treasure_spot.y), config.treasure_spot.y)})
	bottle_opened.emit(d)


# Épaves ------------------------------------------------------------------------------------

func _add_wreck(position: Vector3, target: Vector3, landed: bool) -> Dictionary:
	var w := {"id": _new_id("wreck"), "position": position, "target": target, "landed": landed}
	wrecks.append(w)
	wreck_added.emit(w)
	return w


## Une épave part au large, face à une plage libre, et dérive vers elle.
func spawn_wreck() -> Dictionary:
	var target := _random_beach_spot()
	if not target.is_finite():
		return {}
	var a := atan2(target.z, target.x)
	var start_r := terrain.coast_at(a) + config.wreck_start_offshore_m
	var start := Vector3(cos(a) * start_r, config.sea_level_y, sin(a) * start_r)
	return _add_wreck(start, target, false)


func _run_wrecks(delta: float) -> void:
	if wreck_hour >= 0.0 and day.hour() >= wreck_hour and day.is_day():
		wreck_hour = -1.0
		spawn_wreck()
	for w in wrecks:
		if w.landed:
			continue
		var to: Vector3 = w.target - w.position
		to.y = 0.0
		var step := config.wreck_speed_mps * delta
		if to.length() <= step:
			w.position = w.target
			w.landed = true
		else:
			w.position += to.normalized() * step
			w.position.y = maxf(water_level_y(), terrain.height(w.position.x, w.position.z))


## Ouvre une épave échouée : son contenu va dans les bras, le reste sur la palette.
func open_wreck(w: Dictionary) -> Dictionary:
	if not wrecks.has(w) or not w.landed:
		return {}
	var loot := {}
	for k in config.wreck_loot:
		var r: Array = config.wreck_loot[k]
		var n := rng.randi_range(int(r[0]), int(r[1]))
		if n > 0:
			loot[String(k)] = n
	if rng.randf() < config.wreck_pearl_chance:
		loot["perles"] = 1
	_give(loot)
	wrecks.erase(w)
	wreck_removed.emit(w)
	return loot


## Donne des ressources : dans les bras ce qui rentre, le reste sur la palette.
func _give(items: Dictionary) -> void:
	var leftover := add_carried(items)
	if not leftover.is_empty():
		Economy.add(stock, leftover)
		for r in leftover:
			_discover(String(r))
		stock_changed.emit()


# Détecteur de métaux et objets enterrés ----------------------------------------------------

## Toujours `buried_count` objets enterrés (le trésor de la carte en plus).
func _refill_buried() -> void:
	var count := buried.filter(func(b): return b.kind != "tresor").size()
	for i in maxi(config.buried_count - count, 0):
		var spot := _random_beach_spot()
		if spot.is_finite():
			buried.append({"kind": _pick_weighted(config.buried_weights, "ferraille"), "position": spot})


## Le signal du détecteur à `pos` : 0 (rien à portée) à 1 (juste dessus).
func detector_signal(pos: Vector3) -> float:
	var best := 0.0
	for b in buried:
		var d := Vector2(pos.x - b.position.x, pos.z - b.position.z).length()
		if d < config.detector_range_m:
			best = maxf(best, 1.0 - d / config.detector_range_m)
	return best


## Le geste de pelle en `pos` sort ce qui est enterré à moins de `detector_dig_m`.
func _check_buried(pos: Vector3) -> void:
	for b in buried.duplicate():
		if Vector2(pos.x - b.position.x, pos.z - b.position.z).length() <= config.detector_dig_m:
			buried.erase(b)
			_reward_buried(String(b.kind))
			dug_up.emit(String(b.kind), b.position)


func _reward_buried(kind: String) -> void:
	match kind:
		"piece":
			if not has_found("piece_ancienne"):
				add_to_collection("piece_ancienne")
			else:
				_give({"mineraux": config.buried_coin_minerals})
		"perle":
			_give({"perles": 1})
		"ferraille":
			_give({"mineraux": config.buried_scrap_minerals})
		"tresor":
			_give({"perles": config.treasure_pearls})
			add_to_collection("coffre")


# Tortues ------------------------------------------------------------------------------------

## Vers 22 h, une fois par nuit : peut-être une tortue qui pond ; les nids de 3 nuits éclosent.
func _run_turtles() -> void:
	if day.hour() < config.turtle_hour or _turtle_day == day.day_index:
		return
	_turtle_day = day.day_index
	for n in nests.duplicate():
		if day.day_index - int(n.laid_day) >= config.turtle_hatch_nights:
			nests.erase(n)
			if not has_found("oeuf_tortue"):
				add_to_collection("oeuf_tortue")
			turtles_hatched.emit(n)
	if rng.randf() < config.turtle_night_chance:
		lay_nest()


## Une tortue pond sur une case libre de la plage.
func lay_nest() -> Dictionary:
	var spot := _random_beach_spot()
	if not spot.is_finite():
		return {}
	var n := {"id": _new_id("nest"), "position": spot, "laid_day": day.day_index}
	nests.append(n)
	turtle_laid.emit(n)
	return n


func _vertex_in_nest(v: Vector2i) -> bool:
	var p := TerrainLogic.vertex_xz(v)
	for n in nests:
		if footprint_rect("nid", n.position).grow(0.01).has_point(p):
			return true
	return false


# Feu de camp ----------------------------------------------------------------------------------

## Vrai la nuit à moins de `campfire_radius_m` d'un feu de camp (il ne brûle que la nuit).
func is_near_lit_fire(pos: Vector3) -> bool:
	if day.is_day():
		return false
	for d in decor:
		if d.kind == "feu_de_camp" and Vector2(pos.x - d.position.x, pos.z - d.position.z).length() <= config.campfire_radius_m:
			return true
	return false


# Cocotiers plantés ------------------------------------------------------------------------

## Mains vides + clic sur une noix de coco : elle va dans la barre (au lieu d'être mangée).
func pick_coconut(p: Dictionary) -> bool:
	if not pickups.has(p) or p.kind != "coconut" or current_tool() != "":
		return false
	if toolbar.index_of("noix_de_coco") < 0 and toolbar.first_free() < 0:
		return false
	pickups.erase(p)
	pickup_removed.emit(p)
	coconuts_held += 1
	_sync_toolbar()
	planted_changed.emit()
	return true


## Ce qui empêche de planter en `pos` ("" si rien).
func plant_reason(pos: Vector3) -> String:
	if coconuts_held <= 0:
		return "PROMPT_PLANT_NO_NUT"
	if planted.size() >= config.planted_palm_max:
		return "PROMPT_PLANT_MAX"
	var spot := snap_item("pousse", pos)
	if terrain.soil(TerrainLogic.nearest_vertex(spot.x, spot.z)) != TerrainLogic.Soil.EARTH:
		return "PROMPT_PLANT_EARTH"
	# Un cocotier pousse aussi sur une pente : on ne demande pas un sol plat, juste la place.
	if not PlacementGrid.is_valid(PlacementGrid.rect_shape(footprint_rect("pousse", spot)), _blockers_except({}), INF):
		return "PROMPT_PLANT_BLOCKED"
	return ""


func plant_coconut(pos: Vector3) -> Dictionary:
	if plant_reason(pos) != "":
		return {}
	var spot := snap_item("pousse", pos)
	spot.y = terrain.height(spot.x, spot.z)
	var pl := {"id": _new_id("palm"), "position": spot, "planted_day": day.day_index}
	planted.append(pl)
	coconuts_held -= 1
	_sync_toolbar()
	planted_changed.emit()
	return pl


func is_grown(pl: Dictionary) -> bool:
	return day.day_index - int(pl.planted_day) >= config.planted_palm_days


# --- Catalogue et livraison ----------------------------------------------------------------

func cart_price(item_ids: Array) -> Dictionary:
	var prices := []
	for id in item_ids:
		var item := catalog.find(StringName(id))
		if item:
			prices.append(price_of(item))
	return Economy.sum(prices)


## Le prix d'un article aujourd'hui : réduit si c'est l'offre du jour décrochée au téléphone.
func price_of(item: CatalogItem) -> Dictionary:
	if phone.has_offer(String(item.id), day.day_index):
		return PhoneLogic.discounted(item.price, config.offer_price_factor)
	return item.price


## Les articles qui peuvent faire l'objet d'une offre : achetables et pas cachés.
func offer_candidates() -> Array:
	var out := []
	for item in catalog.items:
		if can_buy(item) and not item.price.is_empty():
			out.append(String(item.id))
	return out


## On décroche le téléphone. Le premier appel (tutoriel muet) fait tomber, après la musique
## d'attente, une caisse avec le catalogue papier. Une offre devient valable pour la journée.
func answer_phone() -> int:
	var why := phone.answer(day.day_index)
	if why == PhoneLogic.Ring.TUTORIAL:
		var crate := _new_crate([config.tutorial_crate_item], config.hold_music_s)
		crate["free"] = true
		crate_added.emit(crate, true)
	phone_changed.emit()
	phone_answered.emit(why)
	return why


## Tout ce qui peut servir à payer : la palette plus ce qu'on a dans les bras.
func available_resources() -> Dictionary:
	return Economy.sum([stock, carried])


func is_unlocked(item: CatalogItem) -> bool:
	return item.tier <= unlocked_tier


func can_buy(item: CatalogItem) -> bool:
	return not item.hidden and is_unlocked(item) and not (item.unique and owned.has(String(item.id)))


## Passe commande : paie avec les bras puis la palette, et crée la caisse qui sera larguée.
## Renvoie la caisse, ou un dictionnaire vide si le stock ne suffit pas.
## Commande : paie, puis l'avion largue les caisses. Chaque objet À POSER (zone, pompe, miroir…)
## a sa propre caisse ; tout le reste (améliorations, tuyaux…) partage une caisse.
## Renvoie la liste des caisses (vide si la commande est refusée).
func order(item_ids: Array) -> Array[Dictionary]:
	var none: Array[Dictionary] = []
	if item_ids.is_empty():
		return none
	for id in item_ids:
		var item := catalog.find(StringName(id))
		if item == null or not can_buy(item):
			return none
	# On paie avec ce qu'on porte d'abord, puis avec la palette (retour d'Othmane).
	var price := cart_price(item_ids)
	if not Economy.pay_from([carried, stock], price):
		return none
	for k in carried.keys():
		if int(carried[k]) <= 0:
			carried.erase(k)
	carried_changed.emit()
	_sync_toolbar()
	for id in item_ids:
		var item := catalog.find(StringName(id))
		if item.unique:
			owned[String(item.id)] = true
	var groups: Array = []
	var others: Array = []
	for id in item_ids:
		if is_placeable(catalog.find(StringName(id))):
			groups.append([String(id)])
		else:
			others.append(String(id))
	if not others.is_empty():
		groups.append(others)
	var made: Array[Dictionary] = []
	for g in groups:
		made.append(_new_crate(g, made.size() * config.crate_stagger_s))
	if not made.is_empty():
		made[0]["paid"] = price  # l'avion de la première caisse emporte le paiement
	stock_changed.emit()
	for crate in made:
		crate_added.emit(crate, true)
	autosave()  # sauvegarde après un achat (M-77)
	return made


## Une caisse sur une case libre, qui sera larguée après `delay_s` secondes.
func _new_crate(items: Array, delay_s: float) -> Dictionary:
	var crate := {"id": _new_id("crate"), "position": next_drop_position(), "items": items, "delay_s": delay_s}
	crates.append(crate)
	_deliveries_count += 1
	return crate


## « mineraux_rares=3,perles=1 » -> {"mineraux_rares": 3, "perles": 1} (ressources connues seulement).
static func gift_contents(param: String) -> Dictionary:
	var out := {}
	for part in param.split(",", false):
		var kv := part.split("=")
		if kv.size() == 2 and Economy.RESOURCES.has(kv[0].strip_edges()):
			out[kv[0].strip_edges()] = int(kv[1])
	return out


## Vrai pour un article qui se pose sur l'île (il aura sa propre caisse).
func is_placeable(item: CatalogItem) -> bool:
	return item != null and item.effect in [CatalogItem.Effect.DRYING_ZONE, CatalogItem.Effect.STATION, CatalogItem.Effect.MIRROR, CatalogItem.Effect.DECOR, CatalogItem.Effect.PUMP, CatalogItem.Effect.SLIDE]


## Ouvre plusieurs caisses d'un coup (outils admin, tests).
func open_crates(list: Array) -> void:
	for crate in list:
		open_crate(crate)


## Points de largage en spirale autour du centre, pour que les caisses (et les bâches posées
## à leur place) ne tombent pas toutes au même endroit.
func next_drop_position() -> Vector3:
	var i := _deliveries_count
	var angle := deg_to_rad(137.5 * i)
	var radius := 1.5 * sqrt(float(i))
	var wanted := config.delivery_center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	return find_free_spot("caisse", wanted)


## Ouvre une caisse : applique l'effet de chaque objet à l'endroit de la caisse.
func open_crate(crate: Dictionary) -> void:
	if not crates.has(crate):
		return
	crates.erase(crate)
	var placed: Array[Dictionary] = []
	for id in crate.items:
		var item := catalog.find(StringName(id))
		if item:
			# 0.1.23 : un lot de décor (les dalles par 5) pose plusieurs objets.
			var n := maxi(int(item.effect_value), 1) if item.effect == CatalogItem.Effect.DECOR else 1
			for k in n:
				var obj := apply_item(item, crate.position)
				if not obj.is_empty():
					placed.append(obj)
	crate_removed.emit(crate)
	# Chaque objet à poser passe en mode déplacement, l'un après l'autre.
	for obj in placed:
		placement_requested.emit(obj)


## Applique l'effet d'un article. Renvoie l'objet posé sur l'île (zone, objet à portions,
## miroir, décor), ou un dictionnaire vide pour une amélioration.
func apply_item(item: CatalogItem, position: Vector3) -> Dictionary:
	# Un objet posé prend la case libre la plus proche de la caisse, jamais sur un autre objet.
	if is_placeable(item):
		var kind := "miroir" if item.effect == CatalogItem.Effect.MIRROR else String(item.effect_param)
		position = find_free_spot(kind, position)
	match item.effect:
		CatalogItem.Effect.DRYING_ZONE:
			return add_zone(item.effect_param, position)
		CatalogItem.Effect.BUCKET_CAPACITY:
			bucket_unit_l = maxf(bucket_unit_l, item.effect_value)
			_refresh_bucket()
		CatalogItem.Effect.BUCKET_COUNT:
			bucket_count = maxi(bucket_count, int(item.effect_value))
			_refresh_bucket()
		CatalogItem.Effect.CARRY_CAPACITY:
			carry_capacity = maxi(carry_capacity, int(item.effect_value))
			carried_changed.emit()
		CatalogItem.Effect.WALK_SPEED:
			speed_multiplier = maxf(speed_multiplier, item.effect_value)
		CatalogItem.Effect.RAKE:
			has_rake = true
			_sync_toolbar()  # le râteau prend une case
		CatalogItem.Effect.SHOVEL:
			has_shovel = true
			_sync_toolbar()  # la pelle prend une case
			shovel_changed.emit()
		CatalogItem.Effect.STATION:
			return add_station(item.effect_param, position)
		CatalogItem.Effect.UNLOCK_TIER:
			unlocked_tier = maxi(unlocked_tier, int(item.effect_value))
			tier_unlocked.emit(unlocked_tier)
		CatalogItem.Effect.MIRROR:
			return add_mirror(position)
		CatalogItem.Effect.SLIDE:
			return add_slide(item.effect_param, position)
		CatalogItem.Effect.PUMP:
			return add_pump(item.effect_param, position)
		CatalogItem.Effect.PIPES:
			pipe_stock += maxi(int(item.effect_value), 1)
			network_changed.emit()
			_sync_toolbar()  # les tuyaux prennent une case
		CatalogItem.Effect.CATALOGUE:
			# Le catalogue ne se pose pas au sol : il part tout seul dans la cabine.
			catalogue_delivered = true
			phone_changed.emit()
		CatalogItem.Effect.PET:
			# 0.1.19 : des croquettes pour le crabe, ou un accessoire qu'il porte tout de suite.
			if item.effect_param == "croquettes":
				pet.add_treats(maxi(int(item.effect_value), 1))
			else:
				pet.give_accessory(item.effect_param)
			pet_changed.emit()
			pet_reacted.emit(CrabPose.Anim.HAPPY)
		CatalogItem.Effect.GEAR:
			gear[item.effect_param] = true
			_apply_gear()
			_sync_toolbar()  # 0.1.23 : le détecteur prend une case
		CatalogItem.Effect.GIFT:
			# 0.1.22 : un lot de ressources de la caisse surprise, posé sur la palette.
			var lot := gift_contents(item.effect_param)
			Economy.add(stock, lot)
			for r in lot:
				_discover(String(r))
			stock_changed.emit()
		CatalogItem.Effect.DECOR:
			var d := {"id": _new_id("decor"), "kind": item.effect_param, "position": position}
			decor.append(d)
			decor_added.emit(d)
			return d
	return {}


## Contenance totale = un seau × nombre de seaux (la palanche en porte deux).
func _refresh_bucket() -> void:
	bucket.capacity_l = bucket_unit_l * bucket_count
	bucket_changed.emit()


# --- Survie légère et plage (N-02, N-03, M-44) ------------------------------------------

## Chaque matin : une noix de coco revient sous chaque palmier qui n'en a plus, et la plage
## reçoit de nouveaux coquillages (on complète jusqu'à `shells_per_morning`).
func _morning_refill() -> void:
	# On regarde ce qui est déjà là avant de faire apparaître quoi que ce soit.
	for spot in config.coconut_spots:
		if not _has_pickup_at("coconut", spot) and _spot_is_free(spot, config.coconut_radius_m, false):
			add_pickup("coconut", spot)
	var shells := pickups.filter(func(p): return p.kind == "shell").size()
	for i in maxi(config.shells_per_morning - shells, 0):
		var spot := _random_beach_spot()
		if spot.is_finite():
			add_pickup("shell", spot)


## Un coquillage tombe au centre d'une case libre de la plage : ni sous un objet, ni sur une
## caisse, ni sur un autre coquillage, ni sur le joueur. NO_SPOT si la plage est pleine.
func _random_beach_spot() -> Vector3:
	var blockers := _blockers_except({})
	for attempt in 40:
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(config.beach_radius_min, config.beach_radius_max)
		var spot := PlacementGrid.snap(Vector3(cos(angle) * radius, 0.52, sin(angle) * radius), config.grid_cell_m)
		if PlacementGrid.is_valid(PlacementGrid.rect_shape(footprint_rect("coquillage", spot)), blockers, config.build_radius_m) \
				and spot_ok("coquillage", spot, 0.0, blockers):
			spot.y = terrain.height(spot.x, spot.z) + 0.02
			return spot
	return NO_SPOT


## Vrai si rien n'occupe ce cercle. `with_coconut_spots` : compter aussi les places des noix de coco.
func _spot_is_free(pos: Vector3, radius: float, with_coconut_spots: bool = true) -> bool:
	return PlacementGrid.is_valid(PlacementGrid.circle_shape(pos, radius), _blockers_except({}, with_coconut_spots), INF)


func _has_pickup_at(kind: String, position: Vector3) -> bool:
	for p in pickups:
		if p.kind == kind and (p.position as Vector3).distance_to(position) < 0.1:
			return true
	return false


func add_pickup(kind: String, position: Vector3) -> Dictionary:
	var p := {"id": _new_id("pickup"), "kind": kind, "position": position}
	pickups.append(p)
	pickup_added.emit(p)
	return p


## Ramasser avec E : la noix de coco se mange tout de suite ; le coquillage va dans les bras
## (2 % de chance d'y trouver une perle, N-07). Renvoie faux si les bras sont pleins.
func take_pickup(p: Dictionary) -> bool:
	if not pickups.has(p):
		return false
	match p.kind:
		"coconut":
			# 0.1.23 : grillée près d'un feu de camp allumé, elle nourrit plus.
			survival.eat(config.coconut_food * (config.grilled_food_mult if is_near_lit_fire(player_position) else 1.0))
			survival.drink(config.coconut_water)
			survival_changed.emit()
		"bottle":
			_open_bottle()
		"shell":
			if not can_carry("coquillages"):
				return false
			_gain_shell()
	pickups.erase(p)
	pickup_removed.emit(p)
	return true


# --- Le crabe de compagnie (0.1.19) ---------------------------------------------------------

## E sur le crabe : une croquette s'il a faim et qu'il en reste, sinon une caresse.
## Renvoie l'animation jouée (CrabPose.Anim).
func interact_pet() -> int:
	if pet.wants_food() and pet.treats > 0:
		return feed_pet()
	pet_crab()
	return CrabPose.Anim.HAPPY


## Lui donner une croquette. Renvoie l'animation jouée : il mange, ou refuse (repu, ou sachet vide).
func feed_pet() -> int:
	var result := pet.feed()
	var anim := CrabPose.Anim.EAT if result == CrabPetLogic.Feed.FED else CrabPose.Anim.REFUSE
	pet_changed.emit()
	pet_reacted.emit(anim)
	return anim


## Une caresse (la première du jour compte en affection). Il est toujours content.
func pet_crab() -> bool:
	var counted := pet.pet(day.day_index)
	pet_changed.emit()
	pet_reacted.emit(CrabPose.Anim.HAPPY)
	return counted


## Chaque matin, un crabe qui vous aime rapporte un coquillage, posé près de lui.
func _pet_morning_gift() -> void:
	if not pet.brings_gift():
		return
	var spot := _spot_near_pet()
	if spot.is_finite():
		add_pickup("shell", spot)


## Une case libre de sable à moins de 3 m du crabe ; ailleurs sur la plage s'il n'y en a pas.
func _spot_near_pet() -> Vector3:
	if not pet_position.is_finite() or pet_position == FAR_AWAY:
		return _random_beach_spot()
	var blockers := _blockers_except({})
	for attempt in 30:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.8, 3.0)
		var spot := PlacementGrid.snap(pet_position + Vector3(cos(a) * r, 0.0, sin(a) * r), config.grid_cell_m)
		if PlacementGrid.is_valid(PlacementGrid.rect_shape(footprint_rect("coquillage", spot)), blockers, config.build_radius_m) \
				and spot_ok("coquillage", spot, 0.0, blockers):
			spot.y = terrain.height(spot.x, spot.z) + 0.02
			return spot
	return _random_beach_spot()


# --- Pompes et tuyaux (T2) -------------------------------------------------------------------

func add_pump(kind: String, position: Vector3) -> Dictionary:
	if not config.pump_rates_lps.has(kind):
		push_error("Type de pompe inconnu : %s" % kind)
		return {}
	var p := {"id": _new_id("pump"), "kind": kind, "position": position, "rotation_deg": 0.0}
	pumps.append(p)
	pump_added.emit(p)
	network_changed.emit()
	return p


func is_auto_pump(pump: Dictionary) -> bool:
	return config.auto_pump_kinds.has(String(pump.kind))


## Les pompes automatiques (moulin-pompe) tournent seules, avec le temps.
func _run_auto_pumps(delta: float) -> void:
	for pump in pumps:
		if is_auto_pump(pump):
			auto_pumped_l += run_pump(pump, delta)
	if not demo_done and auto_pumped_l >= config.demo_end_auto_pumped_l:
		demo_done = true
		demo_finished.emit()


## Les zones reliées à une pompe par les tuyaux posés, de la plus proche à la plus lointaine.
## Recalculé à chaque appel : il n'y a pas de réseau mémorisé qui pourrait se désynchroniser.
func zones_for_pump(pump: Dictionary) -> Array:
	return PipeNetwork.zones_reached(pump.position, pipes, zones, pipe_feeds, config.grid_cell_m, pump_cells(pump))


## Les cases (X, Z) qu'occupe une pompe : les tuyaux se branchent tout autour (0.1.5).
func pump_cells(pump: Dictionary) -> Rect2i:
	var r := item_rect(pump)
	var c := config.grid_cell_m
	var lo := Vector2i(floori(r.position.x / c + 0.01), floori(r.position.y / c + 0.01))
	var hi := Vector2i(ceili(r.end.x / c - 0.01), ceili(r.end.y / c - 0.01))
	return Rect2i(lo, hi - lo)


## La pompe dont l'emprise contient cette case (au niveau du sol), ou vide.
func pump_at_cell(cell: Vector3i) -> Dictionary:
	for pump in pumps:
		if cell.y == PipeNetwork.cell_of(pump.position, config.grid_cell_m).y and pump_cells(pump).has_point(Vector2i(cell.x, cell.z)):
			return pump
	return {}


## L'arrivée d'eau d'une zone, au sol (X, Z) : les cases du milieu du bac (config.inlet_cells,
## dans le repère de la zone), tournées avec elle. Un tuyau ne verse que là (0.1.6).
func inlet_rect(zone: Dictionary) -> Rect2:
	var c := config.grid_cell_m
	var v: Array = config.inlet_cells.get(String(zone.kind), [-c / 2.0, -c / 2.0, c / 2.0, c / 2.0])
	var local := Rect2(float(v[0]), float(v[1]), float(v[2]) - float(v[0]), float(v[3]) - float(v[1]))
	return PlacementGrid.rect_at(local, zone.position, item_rotation(zone))


## Vrai si cette pièce de tuyau verse dans la zone : un bloc au-dessus, vers le milieu du bac.
## 0.1.10 : le niveau « un bloc au-dessus » suit la hauteur de la zone (posée sur du sable
## creusé ou remonté à la pelle).
func pipe_feeds(cell: Vector3i, zone: Dictionary) -> bool:
	return PipeNetwork.feeds(cell, inlet_rect(zone), pour_level_for(zone), config.grid_cell_m)


## Le niveau de tuyau qui verse dans cette zone : `pour_level` au-dessus de son sol.
func pour_level_for(zone: Dictionary) -> int:
	var y := (zone.position as Vector3).y
	return maxi(config.pour_level + roundi((y - config.ground_y) / config.grid_cell_m), 0)


## Ce que ferait une pièce posée en `cell` (pour le fantôme et le texte d'aide, 0.1.10) :
## "feeds" (elle verserait dans une zone), "wet" (l'eau d'une pompe y passerait), ou "".
func pipe_preview(cell: Vector3i) -> String:
	for zone in zones:
		if pipe_feeds(cell, zone):
			return "feeds"
	var wet := wet_pipes()
	for d in PipeNetwork.DIRS:
		if wet.has(cell + d):
			return "wet"
	for pump in pumps:
		if cell.y == PipeNetwork.cell_of(pump.position, config.grid_cell_m).y:
			var foot := pump_cells(pump).grow(1)
			if foot.has_point(Vector2i(cell.x, cell.z)):
				return "wet"
	return ""


## Les pièces où passe l'eau d'au moins une pompe (pour les colorer).
func wet_pipes() -> Dictionary:
	var out := {}
	for pump in pumps:
		out.merge(PipeNetwork.reach(PipeNetwork.cell_of(pump.position, config.grid_cell_m), pipes, pump_cells(pump)))
	return out


# --- Poser les tuyaux à la main ---------------------------------------------------------------

## Une pièce peut-elle aller dans cette case ?
## - case libre, niveau entre 0 et `pipe_max_level`, sur l'île ;
## - au sol : pas dans un objet (sauf une zone de séchage, où le tuyau verse), ni sur un élément fixe ;
## - en hauteur : il faut une pièce voisine ou une pompe juste en dessous (pas de tuyau qui flotte seul).
func can_place_pipe(cell: Vector3i) -> bool:
	if pipes.has(cell) or cell.y < 0 or cell.y > config.pipe_max_level:
		return false
	var center := PipeNetwork.cell_center(cell, config.grid_cell_m, 0.0)
	var flat := Vector2(center.x, center.z)
	# Sur l'île, ou au-dessus de l'eau jusqu'aux pompes (0.1.4 : elles sont dans l'eau).
	var limit := maxf(config.build_radius_m, terrain.coast_at(atan2(flat.y, flat.x)) + config.pump_max_offshore_m + 1.0)
	if flat.length() + 0.5 > limit:
		return false
	# Pas dans une dune : la pièce doit être au-dessus du sable (on passe par-dessus, en hauteur).
	if terrain.height(center.x, center.z) > PipeNetwork.cell_center(cell, config.grid_cell_m, config.ground_y).y - 0.1:
		return false
	var piece := PlacementGrid.circle_shape(center, config.pipe_radius_m)
	# Les tuyaux sont solides (0.1.6) : jamais une pièce dans le joueur (il fait deux blocs de haut).
	if cell.y <= 1 and PlacementGrid.overlaps(piece, PlacementGrid.circle_shape(player_position, config.player_radius_m)):
		return false
	if cell.y == 0:
		for b in _blockers_except({}, true, false):
			if PlacementGrid.overlaps(piece, b):
				return false
		return true
	if not PipeNetwork.neighbors(cell, pipes).is_empty():
		return true
	for pump in pumps:
		if PipeNetwork.cell_of(pump.position, config.grid_cell_m) + Vector3i(0, 1, 0) == cell:
			return true
	return false


## Poser une pièce (prise dans le stock).
func place_pipe(cell: Vector3i) -> bool:
	if pipe_stock <= 0 or not can_place_pipe(cell):
		return false
	pipes[cell] = true
	pipe_stock -= 1
	network_changed.emit()
	return true


## Reprendre une pièce (elle retourne dans le stock).
func remove_pipe(cell: Vector3i) -> bool:
	if not pipes.has(cell):
		return false
	pipes.erase(cell)
	pipe_stock += 1
	network_changed.emit()
	return true


## Actionner une pompe pendant `delta` secondes : elle aspire dans l'océan et remplit les zones
## reliées (la plus proche d'abord). Renvoie les litres pompés (0 si rien n'est relié ou tout est plein).
func run_pump(pump: Dictionary, delta: float) -> float:
	pump.last_lps = 0.0
	var targets := zones_for_pump(pump)
	if targets.is_empty() or delta <= 0.0:
		return 0.0
	var room := 0.0
	for z in targets:
		room += (z.logic as DryingLogic).free_space_l()
	var wanted := minf(float(config.pump_rates_lps.get(pump.kind, 0.0)) * delta, room)
	if wanted <= 0.0:
		return 0.0
	var taken := ocean.remove_water(wanted)
	var poured := PipeNetwork.distribute(taken, targets)
	if poured < taken:
		ocean.return_water(taken - poured)
	pump.last_lps = poured / delta
	pump.last_run_ms = Time.get_ticks_msec()  # pour l'affichage (filets d'eau aux becs)
	ocean_changed.emit()
	return poured


# --- Jalons comparatifs (M-70) -----------------------------------------------------------

## Regarde si l'eau retirée franchit un jalon ; chaque jalon donne sa récompense sur la palette.
func check_milestones() -> void:
	for m in milestones.update(ocean.removed_l):
		Economy.add(stock, m.get("reward", {}))
		stock_changed.emit()
		milestone_reached.emit(m)


# --- Toboggan à sacs (T2, N-09, M-28 : le stock devient automatique) ---------------------

func add_slide(kind: String, position: Vector3) -> Dictionary:
	var sl := {"id": _new_id("slide"), "kind": kind, "position": position, "timer": 0.0}
	slides.append(sl)
	slide_added.emit(sl)
	return sl


## Les zones dont le sel est assez près du toboggan pour y être versé tout seul.
func zones_for_slide(slide: Dictionary) -> Array:
	var out := []
	var sp: Vector3 = slide.position
	for z in zones:
		if PlacementGrid.distance_to(PlacementGrid.rect_shape(item_rect(z)), sp) <= config.slide_reach_m:
			out.append(z)
	return out


## E sur le toboggan : on y jette ce qu'on porte, ça glisse jusqu'à la palette.
func slide_unload(slide: Dictionary) -> int:
	var items := carried.duplicate()
	var n := unload_to_stock()
	if n > 0:
		slide_sent.emit(slide, items)
	return n


## Toutes les `slide_period_s`, chaque toboggan envoie à la palette les dépôts des zones proches.
func _run_slides(delta: float) -> void:
	for sl in slides:
		sl.timer = float(sl.get("timer", 0.0)) + delta
		if sl.timer < config.slide_period_s:
			continue
		sl.timer = 0.0
		var sent := {}
		for z in zones_for_slide(sl):
			var logic: DryingLogic = z.logic
			if logic.has_deposit():
				Economy.add(sent, logic.take_deposit())
		if not sent.is_empty():
			Economy.add(stock, sent)
			stock_changed.emit()
			slide_sent.emit(sl, sent)


func add_mirror(position: Vector3) -> Dictionary:
	var m := {"id": _new_id("mirror"), "kind": "miroir", "position": position}
	mirrors.append(m)
	mirror_added.emit(m)
	return m


func add_station(kind: String, position: Vector3) -> Dictionary:
	var logic: StationLogic
	match kind:
		"condenseur":
			logic = StationLogic.new(0, config.condenser_capacity, config.condenser_period_s)
		"rations":
			logic = StationLogic.new(config.ration_portions, config.ration_portions, 0.0)
		_:
			push_error("Type d'objet inconnu : %s" % kind)
			return {}
	var st := {"id": _new_id("station"), "kind": kind, "position": position, "logic": logic}
	stations.append(st)
	station_added.emit(st)
	return st


## E sur une bâche de condensation : boire une gorgée ; sur une caisse de rations : manger.
func use_station(st: Dictionary) -> bool:
	var logic: StationLogic = st.logic
	if not logic.take_one():
		return false
	match st.kind:
		"condenseur":
			survival.drink(config.condenser_water)
		"rations":
			survival.eat(config.ration_food)
	survival_changed.emit()
	if logic.is_spent():
		stations.erase(st)
		station_removed.emit(st)
	return true


# --- Déplacer les objets (grille) -------------------------------------------------------------

## Le « type » d'un objet déplaçable, qui donne son emprise : "cuvette", "miroir"…
func item_kind(item: Dictionary) -> String:
	return String(item.get("kind", "miroir"))


## L'emprise d'un type, dans son propre repère (avant rotation) : un rectangle de cases entières
## (config.footprints, [x0, z0, x1, z1] en mètres). Une case si le type est inconnu.
func footprint_of(kind: String) -> Rect2:
	var c := config.grid_cell_m
	var v: Array = config.footprints.get(kind, [-c / 2.0, -c / 2.0, c / 2.0, c / 2.0])
	return Rect2(float(v[0]), float(v[1]), float(v[2]) - float(v[0]), float(v[3]) - float(v[1]))


## L'emprise d'un type posé en `pos` et tourné de `rotation_deg` : un rectangle au sol (X, Z).
func footprint_rect(kind: String, pos: Vector3, rotation_deg: float = 0.0) -> Rect2:
	return PlacementGrid.rect_at(footprint_of(kind), pos, rotation_deg)


## L'emprise d'un objet tel qu'il est posé.
func item_rect(item: Dictionary) -> Rect2:
	return footprint_rect(item_kind(item), item.position, item_rotation(item))


## Aligne un objet de ce type sur la grille, au plus près de `pos` (les bords de son emprise
## tournée tombent sur les lignes de la grille).
func snap_item(kind: String, pos: Vector3, rotation_deg: float = 0.0) -> Vector3:
	return PlacementGrid.snap_rect(pos, footprint_of(kind), rotation_deg, config.grid_cell_m)


## Où est le tas d'un matériau, par rapport au centre de sa zone (avant rotation) : chaque
## matériau a sa propre case, côte à côte (config.pile_slots), dans l'emprise de la zone.
func pile_offset(zone: Dictionary, resource: String = "sel") -> Vector3:
	var x := float(config.pile_offset_cells.get(String(zone.kind), 2))
	var z := float(config.pile_slots.get(resource, 0))
	return Vector3(x, 0.0, z) * config.grid_cell_m


## Tous les objets qu'on peut déplacer.
func movable_items() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for z in zones:
		if not is_marsh(z):  # 0.1.20 : un marais est un trou, on ne le déplace pas
			all.append(z)
	all.append_array(stations)
	all.append_array(mirrors)
	all.append_array(slides)
	all.append_array(pumps)
	all.append_array(decor)
	all.append(depot)
	return all


## Emprises qui gênent `item` (tous les autres objets + les obstacles fixes).
func blockers_for(item: Dictionary) -> Array:
	return _blockers_except(item)


## Toutes les emprises sauf celle de `item` : objets posés, caisses (au sol ou en vol), obstacles
## fixes, places des noix de coco, ramassables (coquillages…), et le joueur.
func _blockers_except(item: Dictionary, with_coconut_spots: bool = true, with_pipes: bool = true, with_zones: bool = true) -> Array:
	var out := []
	for other in movable_items():
		if not with_zones and zones.has(other):
			continue
		if other != item:
			out.append(PlacementGrid.rect_shape(item_rect(other)))
	for c in crates:
		out.append(PlacementGrid.rect_shape(footprint_rect("caisse", c.position)))
	for o in config.fixed_obstacles:
		out.append(PlacementGrid.circle_shape(Vector3(o.x, 0.0, o.y), o.z))
	if with_zones:
		out.append_array(_marsh_shapes(item, false))
	if with_coconut_spots:
		for spot in config.coconut_spots:
			out.append(PlacementGrid.circle_shape(spot, config.coconut_radius_m))
	for pk in pickups:
		if pk != item and pk.kind != "coconut":  # les noix sont déjà comptées par leur place
			out.append(PlacementGrid.rect_shape(footprint_rect("coquillage", pk.position)))
	# 0.1.23 : les nids de tortue, les cocotiers plantés et les épaves échouées.
	for n in nests:
		out.append(PlacementGrid.rect_shape(footprint_rect("nid", n.position)))
	for pl in planted:
		out.append(PlacementGrid.rect_shape(footprint_rect("pousse", pl.position)))
	for w in wrecks:
		if w.landed:
			out.append(PlacementGrid.rect_shape(footprint_rect("epave", w.position)))
	out.append(PlacementGrid.circle_shape(player_position, config.player_radius_m))
	# Les tuyaux au sol gênent tout, zones de séchage comprises : depuis 0.1.6, un tuyau verse d'un
	# bloc au-dessus du bac, jamais posé dedans.
	if with_pipes:
		for c in pipes:
			if c.y == 0:
				out.append(PlacementGrid.circle_shape(PipeNetwork.cell_center(c, config.grid_cell_m, 0.0), config.pipe_radius_m))
	return out


## L'emplacement libre le plus proche de `near` pour un objet de ce type (et cette orientation),
## aligné sur la grille : on cherche en carrés de plus en plus grands. Si rien n'est libre, renvoie
## l'emplacement aligné le plus proche de `near`.
func find_free_spot(kind: String, near: Vector3, rotation_deg: float = 0.0) -> Vector3:
	var cell := config.grid_cell_m
	var start := snap_item(kind, near, rotation_deg)
	var blockers := _blockers_except({})
	var rings := int(ceil(config.build_radius_m * 2.0 / cell)) + 1
	if is_water_kind(kind):
		# Une pompe part du rivage le plus proche, et cherche dans l'eau.
		var a := atan2(near.z, near.x)
		var shore := terrain.coast_at(a) + 2.0
		start = snap_item(kind, Vector3(cos(a) * shore, near.y, sin(a) * shore), rotation_deg)
		rings = int(ceil((terrain.coast_radius + config.pump_max_offshore_m) * 2.0 / cell)) + 1
	for ring in rings:
		for dx in range(-ring, ring + 1):
			for dz in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dz)) != ring:
					continue
				var p := start + Vector3(dx * cell, 0.0, dz * cell)
				if spot_ok(kind, p, rotation_deg, blockers):
					if not is_water_kind(kind):
						p.y = ground_level(footprint_rect(kind, p, rotation_deg))
					return p
	return start


## Peut-on poser `item` en `pos` (avec cette orientation, ou la sienne) ?
func can_place(item: Dictionary, pos: Vector3, rotation_deg: float = NAN) -> bool:
	var rot := item_rotation(item) if is_nan(rotation_deg) else rotation_deg
	return spot_ok(item_kind(item), pos, rot, blockers_for(item))


## Vrai si le joueur est assez près pour poser cet objet là : le bord de son emprise est à moins
## de `place_reach_m` de lui (0.1.6). Le mode déplacement (G) l'exige en plus de `can_place`.
func in_place_reach(item: Dictionary, pos: Vector3, rotation_deg: float) -> bool:
	var shape := PlacementGrid.rect_shape(footprint_rect(item_kind(item), pos, rotation_deg))
	return PlacementGrid.distance_to(shape, player_position) <= config.place_reach_m


## Ce qui empêche de poser `item` en `pos` : les formes qu'il chevaucherait (vide si rien ne gêne).
func placement_conflicts(item: Dictionary, pos: Vector3, rotation_deg: float) -> Array:
	var shape := PlacementGrid.rect_shape(footprint_rect(item_kind(item), pos, rotation_deg))
	return PlacementGrid.conflicts(shape, blockers_for(item))


## Un emplacement valide pour ce type : sur l'île (zone constructible), ou dans l'eau près du
## rivage pour les pompes (0.1.4). L'emprise (tournée) ne chevauche aucune autre forme.
func spot_ok(kind: String, pos: Vector3, rotation_deg: float, blockers: Array) -> bool:
	var shape := PlacementGrid.rect_shape(footprint_rect(kind, pos, rotation_deg))
	if not is_water_kind(kind):
		# 0.1.10 : plus de cercle constructible fixe. Le sol sous l'emprise doit être plat et au même
		# niveau (le plateau de départ, ou du sable aplani à la pelle).
		if is_nan(ground_level(footprint_rect(kind, pos, rotation_deg))):
			return false
		return PlacementGrid.is_valid(shape, blockers, INF)
	return is_water_spot(pos) and PlacementGrid.is_valid(shape, blockers, INF)


## Le niveau du sol sous un rectangle (X, Z) si on peut y poser un objet, sinon NAN : chaque case
## couverte est plate (TerrainLogic.cell_level), toutes au même niveau, et au-dessus de l'eau.
func ground_level(rect: Rect2) -> float:
	var c := config.grid_cell_m
	var level := NAN
	for j in range(floori(rect.position.y / c + 1e-4), ceili(rect.end.y / c - 1e-4)):
		for i in range(floori(rect.position.x / c + 1e-4), ceili(rect.end.x / c - 1e-4)):
			var l := terrain.cell_level(Vector2i(i, j))
			if is_nan(l):
				return NAN
			if is_nan(level):
				level = l
			elif absf(l - level) > 0.03:
				return NAN
	if is_nan(level):
		return NAN
	# 0.1.14 : au fond d'un trou à l'intérieur de l'île, pas d'eau : on peut y poser.
	var mid := rect.get_center()
	if level < water_level_y() + config.dig_min_above_water_m and sea_at(mid.x, mid.y):
		return NAN
	return level


## Pourquoi on ne peut pas poser `kind` là (texte d'aide), ou "" si c'est possible.
func placement_reason(item: Dictionary, pos: Vector3, rotation_deg: float) -> String:
	var kind := item_kind(item)
	if not is_water_kind(kind) and is_nan(ground_level(footprint_rect(kind, pos, rotation_deg))):
		return "PROMPT_GROUND_NOT_FLAT"
	return "" if can_place(item, pos, rotation_deg) else "PROMPT_CANT_PLACE"


## Les types qui se posent dans l'eau (les pompes).
func is_water_kind(kind: String) -> bool:
	return config.shore_only_kinds.has(kind)


## Dans l'eau, assez profond, et pas plus loin du rivage que `pump_max_offshore_m`.
func is_water_spot(pos: Vector3) -> bool:
	if water_level_y() - terrain.height(pos.x, pos.z) < config.pump_min_depth_m:
		return false
	var flat := Vector2(pos.x, pos.z)
	return flat.length() - terrain.coast_at(atan2(pos.z, pos.x)) <= config.pump_max_offshore_m


## Déplace (et tourne) un objet sur la case visée. Renvoie faux si l'emplacement n'est pas valide.
## Sans `rotation_deg`, l'objet garde son orientation.
func move_item(item: Dictionary, pos: Vector3, rotation_deg: float = NAN) -> bool:
	var rot := item_rotation(item) if is_nan(rotation_deg) else PlacementGrid.wrap_deg(rotation_deg)
	var snapped := snap_item(item_kind(item), pos, rot)
	snapped.y = (item.position as Vector3).y
	if not can_place(item, snapped, rot):
		return false
	if not is_water_kind(item_kind(item)):
		snapped.y = ground_level(footprint_rect(item_kind(item), snapped, rot))  # posé sur ce sol
	item.position = snapped
	item.rotation_deg = rot
	item_moved.emit(item)
	network_changed.emit()
	return true


## Orientation d'un objet autour de la verticale, en degrés (0 si jamais tourné).
static func item_rotation(item: Dictionary) -> float:
	return float(item.get("rotation_deg", 0.0))


## À la lecture d'une sauvegarde : remet l'orientation, et prévient la vue.
func _load_rotation(item: Dictionary, src: Dictionary) -> void:
	if item.is_empty():
		return
	item.rotation_deg = PlacementGrid.wrap_deg(float(src.get("rotation_deg", 0.0)))
	item_moved.emit(item)


# --- Travailler le sable : la pelle (0.1.10, 0.1.12 : du vrai sable) ------------------------

## La hauteur arrondie au cran de pelle le plus proche (les terrasses tombent juste).
func dig_snap(y: float) -> float:
	var step := config.dig_step_m
	return config.ground_y + roundf((y - config.ground_y) / step) * step


## Le plus bas où l'on creuse au bord de l'eau (jamais trop près de l'eau) et le plus haut où
## l'on entasse.
func dig_floor_y() -> float:
	return water_level_y() + config.dig_min_above_water_m


## 0.1.14 : le plus bas où l'on creuse en (x, z) : à l'intérieur de l'île, bien plus profond
## (`dig_max_below_sea_m` sous la mer de départ) ; au bord de l'eau, comme avant.
func dig_floor_at(x: float, z: float) -> float:
	var f := dig_floor_y()
	if terrain.inland(x, z):
		f = minf(f, config.sea_level_y - config.dig_max_below_sea_m)
	return f


## Vrai si la mer est au-dessus de ce point quand il est sous son niveau (hors de l'intérieur de
## l'île, où elle est cachée) : on y nage, on y puise.
func sea_at(x: float, z: float) -> bool:
	return terrain == null or not terrain.inland(x, z)


func dig_ceil_y() -> float:
	return config.ground_y + config.dig_max_above_ground_m


## Le niveau d'aplanissement d'une case (au niveau `ref`, ou au sien), arrondi, borné.
## 0.1.15 : arrondi au pas fin `level_step_m` (avant : au cran de pelle, 25 cm).
func flatten_level(cell: Vector2i, ref := NAN) -> float:
	var y := level_snap(ref) if not is_nan(ref) else level_snap(terrain.cell_mean(cell))
	var c := config.grid_cell_m
	var lo := level_snap(dig_floor_at((cell.x + 0.5) * c, (cell.y + 0.5) * c) + config.level_step_m * 0.49)
	return clampf(y, lo, dig_ceil_y())


## La hauteur arrondie au pas d'aplanissement (0.1.15).
func level_snap(y: float) -> float:
	var step := config.level_step_m
	return config.ground_y + roundf((y - config.ground_y) / step) * step


## 0.1.15 : les cases du carré d'aplanissement centré sur `cell` (level_brush_cells de côté).
func level_area(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var n := maxi(config.level_brush_cells, 1)
	var lo := -(n - 1) / 2
	for j in range(lo, lo + n):
		for i in range(lo, lo + n):
			out.append(cell + Vector2i(i, j))
	return out


## 0.1.15 (demande d'Othmane) : le niveau proposé pour aplanir autour de `cell`. Si un sol déjà
## plat tout proche (nivelé, ou le plateau de départ) est à peu près à la hauteur moyenne du carré,
## on prend exactement son niveau (les lots se raccordent) ; sinon, la hauteur moyenne du carré
## (le sable pris d'un côté comble l'autre : la pelle n'a presque rien à porter).
## Renvoie [niveau, vrai si c'est celui d'un sol voisin].
func auto_level(cell: Vector2i) -> Array:
	var area := level_area(cell)
	var mean := 0.0
	for c in area:
		mean += terrain.cell_mean(c)
	mean /= area.size()
	var best := NAN
	var best_d := INF
	var r := config.level_snap_cells
	var n := maxi(config.level_brush_cells, 1)
	var lo := -(n - 1) / 2
	for j in range(lo - r, lo + n + r):
		for i in range(lo - r, lo + n + r):
			var c := cell + Vector2i(i, j)
			var lev := terrain.cell_level(c)
			if is_nan(lev):
				continue
			var d := absf(lev - mean)
			if d < best_d:
				best_d = d
				best = lev
	if best_d <= config.level_snap_m:
		return [flatten_level(cell, best), true]
	return [flatten_level(cell, mean), false]


## Pelletées de sable qu'il faut prendre (> 0) ou poser (< 0) pour aplanir la case au niveau `y` :
## le vrai volume entre le sol et ce niveau (une pelletée = dig_scoop_m3).
func dig_scoops(cell: Vector2i, y: float) -> float:
	var v := 0.0
	for c in TerrainLogic.cell_vertices(cell):
		v += (terrain.vertex(c.x, c.y).y - y) * SandPhysics.AREA
	return v / config.dig_scoop_m3


## Ce qui empêche d'aplanir cette case au niveau `y` ("" si rien) : une clé de texte d'aide.
## On ne touche ni à la mer, ni sous un objet, ni à côté d'un objet si un sommet partagé devait
## bouger (l'objet flotterait ou s'enfoncerait). La pelle doit avoir la place de prendre le sable,
## ou en porter assez.
func dig_reason(cell: Vector2i, y: float) -> String:
	var reason := _cell_reason(cell, y, _dig_blockers())
	if reason != "":
		return reason
	var scoops := dig_scoops(cell, y)
	reason = _load_reason(scoops)
	if reason != "":
		return reason
	return _soil_reason(_cut_soil(_level_heights(TerrainLogic.cell_vertices(cell), y)), scoops)


## Les sommets mis à la hauteur `y` (pour _cut_soil).
func _level_heights(vertices: Array, y: float) -> Dictionary:
	var out := {}
	for v: Vector2i in vertices:
		out[v] = y
	return out


## La pelle peut-elle prendre (> 0) ou donner (< 0) ces pelletées ? ("" si oui)
func _load_reason(scoops: float) -> String:
	if scoops > 0.0 and shovel_sand + scoops > config.shovel_capacity_scoops + 0.01:
		return "PROMPT_DIG_SHOVEL_FULL"
	if scoops < 0.0 and shovel_sand + scoops < -0.01:
		return "PROMPT_DIG_SHOVEL_EMPTY"
	return ""


## Ce qui empêche d'aplanir la case, sans compter la pelle (la mer, un objet dessus ou à côté).
func _cell_reason(cell: Vector2i, y: float, blockers: Array) -> String:
	var center := Vector2((cell.x + 0.5) * config.grid_cell_m, (cell.y + 0.5) * config.grid_cell_m)
	var reason := _spot_reason(center)
	if reason != "":
		return reason
	# 0.1.14 : chaque coin de la case aussi (une case à cheval sur le rivage touchait la mer).
	for v in TerrainLogic.cell_corners(cell):
		reason = _spot_reason(TerrainLogic.vertex_xz(v))
		if reason != "":
			return reason
	if _cell_blocked(cell, blockers):
		return "PROMPT_DIG_BLOCKED"
	for v in TerrainLogic.cell_vertices(cell):
		if absf(terrain.vertex(v.x, v.y).y - y) <= TerrainLogic.FLAT_TOLERANCE:
			continue
		for other in TerrainLogic.cells_of_vertex(v):
			if other != cell and _cell_blocked(other, blockers):
				return "PROMPT_DIG_NEAR_OBJECT"
	return ""


## 0.1.15 : les cases du carré autour de `cell` qu'on peut aplanir au niveau `y` d'un seul geste,
## et les pelletées que ça demande : [cases, pelletées, raison]. Les cases bloquées (la mer, un
## objet) sont laissées ; si la pelle ne peut pas tout prendre ou tout donner, on garde les cases
## les plus proches du centre qui tiennent. `raison` dit pourquoi aucune case ne va ("" sinon).
func level_plan(cell: Vector2i, y: float) -> Array:
	var blockers := _dig_blockers()
	var cand: Array[Vector2i] = []
	var first := ""
	for c in level_area(cell):
		var r := _cell_reason(c, y, blockers)
		if r == "":
			cand.append(c)
		elif first == "" or c == cell:
			first = r
	cand.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return (a - cell).length_squared() < (b - cell).length_squared())
	var cells: Array[Vector2i] = []
	var seen := {}
	var scoops := 0.0
	for c in cand:
		var add := 0.0
		var mine: Array[Vector2i] = []
		for v in TerrainLogic.cell_vertices(c):
			if not seen.has(v):
				mine.append(v)
				add += (terrain.vertex(v.x, v.y).y - y) * SandPhysics.AREA
		add /= config.dig_scoop_m3
		var r := _load_reason(scoops + add)
		if r != "":
			if first == "" or cells.is_empty():
				first = r
			continue
		scoops += add
		cells.append(c)
		for v in mine:
			seen[v] = true
	if not cells.is_empty():
		var soil_reason := _soil_reason(_cut_soil(_level_heights(seen.keys(), y)), scoops)
		if soil_reason != "":
			var none: Array[Vector2i] = []
			return [none, 0.0, soil_reason]
	return [cells, scoops, "" if not cells.is_empty() else first]


## 0.1.15 : aplanit le carré autour de `cell` au niveau `y`, en un seul geste. Vrai si le sol a changé.
func flatten_area(cell: Vector2i, y: float) -> bool:
	var plan := level_plan(cell, y)
	if (plan[0] as Array).is_empty():
		return false
	return _flatten_cells(plan[0], y, float(plan[1]))


## Trop loin, ou dans l'eau ? (commun à toutes les actions de pelle)
func _spot_reason(p: Vector2) -> String:
	var h := (TerrainLogic.GRID_HALF - TerrainLogic.SUB) * TerrainLogic.VERTEX_STEP
	if absf(p.x) >= h or absf(p.y) >= h:
		return "PROMPT_DIG_TOO_FAR"
	if p.length() > terrain.coast_at(atan2(p.y, p.x)) - 0.5:
		return "PROMPT_DIG_WATER"
	return ""


## Aplanit une case au niveau `ref` (Maj + clic gauche, en glissant) : ses 9 sommets prennent ce
## niveau. Le sable en trop va sur la pelle, ce qui manque en vient. Le sable tassé de la case tient
## (il ne s'éboule pas pendant ce geste) ; autour, le sable trop raide s'éboule. Vrai si le sol a changé.
func flatten_cell(cell: Vector2i, ref := NAN) -> bool:
	var y := flatten_level(cell, ref)
	if dig_reason(cell, y) != "":
		return false
	return _flatten_cells([cell], y, dig_scoops(cell, y))


## Met les cases `cells` au niveau `y` (`scoops` : le sable que ça prend), avec le fondu autour.
func _flatten_cells(cells: Array, y: float, scoops: float) -> bool:
	var target := {}
	var locked := {}
	var sum := Vector2.ZERO
	for cell: Vector2i in cells:
		sum += Vector2(cell.x + 0.5, cell.y + 0.5)
		for v in TerrainLogic.cell_vertices(cell):
			target[v] = y
			locked[v] = true
	# 0.1.13 : le sable autour (deux rangs de sommets, hors des cases déjà nivelées) se fond en
	# rampe douce vers la case, au lieu d'une marche aux bords nets. Ce sable-là aussi est compté
	# sur la pelle ; s'il n'y a pas la place (ou pas assez de sable), le fondu est plus léger.
	var ctx := _sand_context()
	var ring := _blend_ring(cells, target, ctx)
	if not ring.is_empty():
		var read := func(k: Vector2i) -> float: return terrain.vertex(k.x, k.y).y
		var blended := SandPhysics.blend(target.duplicate(), read, ring, config.level_blend_passes, 0.6)
		var extra := 0.0
		for v: Vector2i in blended:
			extra += (terrain.vertex(v.x, v.y).y - float(blended[v])) * SandPhysics.AREA
		extra /= config.dig_scoop_m3
		var room_after := shovel_sand + scoops
		var f := 1.0
		if extra > 0.0:
			f = clampf((config.shovel_capacity_scoops - room_after) / extra, 0.0, 1.0)
		elif extra < 0.0:
			f = clampf(room_after / -extra, 0.0, 1.0)
		for v: Vector2i in blended:
			var h0 := terrain.vertex(v.x, v.y).y
			target[v] = lerpf(h0, float(blended[v]), f)
		scoops += extra * f
	sum /= cells.size()
	var center := Vector3(sum.x * config.grid_cell_m, y, sum.y * config.grid_cell_m)
	# Ce qui est raboté comble les creux ; ce que la pelle donne est ce qu'elle porte.
	var cut := _cut_soil(target)
	var deposit := shovel_soil if scoops < -0.01 or cut < 0 else cut
	sand_gesture = Gesture.LEVEL
	var ok := _move_sand(center, target, scoops, locked, ctx, deposit, cut)
	sand_gesture = Gesture.SCOOP
	return ok


## Les sommets autour des cases qu'on nivelle, que le fondu peut bouger : deux rangs autour de
## leurs sommets (`inner`), qui peuvent bouger, et qui ne sont pas sur une case déjà plate (nivelée
## à la pelle, ou le plateau de départ : on ne défait jamais un sol où l'on peut poser).
func _blend_ring(cells: Array, inner: Dictionary, ctx: Dictionary) -> Array:
	var out := []
	var seen := {}
	var r := config.level_blend_rings
	for cell: Vector2i in cells:
		var o := cell * TerrainLogic.SUB
		for j in range(-r, TerrainLogic.SUB + r + 1):
			for i in range(-r, TerrainLogic.SUB + r + 1):
				var v := o + Vector2i(i, j)
				if inner.has(v) or seen.has(v):
					continue
				seen[v] = true
				if _ring_vertex_ok(v, ctx):
					out.append(v)
	return out


func _ring_vertex_ok(v: Vector2i, ctx: Dictionary) -> bool:
	if not _vertex_movable(v, ctx):
		return false
	for c in TerrainLogic.cells_of_vertex(v):
		if not is_nan(terrain.cell_level(c)):  # nivelée, ou le plateau de départ
			return false
	return true


## La pelletée : creuser (clic gauche, `dig` vrai) ou poser le sable porté (clic droit), autour du
## sommet `v`. Ce qui empêche le geste ("" si rien), en clé de texte d'aide.
func scoop_reason(v: Vector2i, dig: bool) -> String:
	var reason := _spot_reason(TerrainLogic.vertex_xz(v))
	if reason != "":
		return reason
	if _vertex_in_full_marsh(v):
		return "PROMPT_MARSH_NOT_EMPTY"
	if _vertex_in_nest(v):
		return "PROMPT_TURTLE_NEST"
	var ctx := _sand_context()
	if not _vertex_movable(v, ctx):
		return "PROMPT_DIG_BLOCKED"
	if dig and shovel_sand > config.shovel_capacity_scoops - 0.05:
		return "PROMPT_DIG_SHOVEL_FULL"
	if not dig and shovel_sand < 0.05:
		return "PROMPT_DIG_SHOVEL_EMPTY"
	var plan := _plan_scoop(v, dig, ctx)
	if float(plan.volume) < 0.05 * config.dig_scoop_m3:
		return "PROMPT_DIG_TOO_DEEP" if dig else "PROMPT_DIG_TOO_HIGH"
	if dig:
		return _soil_reason(terrain.soil(v), 1.0)
	return ""


## 0.1.16 : la matière qu'un geste enlève (TerrainLogic.Soil), celle de la plupart du volume
## enlevé (`heights` : les nouvelles hauteurs) ; -1 si rien ne descend.
func _cut_soil(heights: Dictionary) -> int:
	var amount := [0.0, 0.0]
	for k: Vector2i in heights:
		var d := terrain.vertex(k.x, k.y).y - float(heights[k])
		if d > 0.0:
			amount[terrain.soil(k)] += d
	if amount[0] <= 0.0 and amount[1] <= 0.0:
		return -1
	return TerrainLogic.Soil.EARTH if amount[1] > amount[0] else TerrainLogic.Soil.SAND


## 0.1.16 : la pelle ne mélange pas : si elle porte du sable, elle ne prend pas de terre (et
## l'inverse). "" si la matière `cut` peut aller sur la pelle (`scoops` > 0 : on en prend).
func _soil_reason(cut: int, scoops: float) -> String:
	if scoops <= 0.01 or cut < 0 or shovel_sand <= 0.05 or cut == shovel_soil:
		return ""
	return "PROMPT_SHOVEL_HAS_EARTH" if shovel_soil == TerrainLogic.Soil.EARTH else "PROMPT_SHOVEL_HAS_SAND"


## Creuse (ou pose) une pelletée autour du sommet `v`, puis laisse le sable s'ébouler.
## Vrai si le sol a changé.
func shovel_scoop(v: Vector2i, dig: bool) -> bool:
	if scoop_reason(v, dig) != "":
		return false
	var ctx := _sand_context()
	var plan := _plan_scoop(v, dig, ctx)
	var scoops := float(plan.volume) / config.dig_scoop_m3
	var p := TerrainLogic.vertex_xz(v)
	var center := Vector3(p.x, terrain.vertex(v.x, v.y).y, p.y)
	if dig:
		# 0.1.16 : on prend la matière du sommet visé (le centre de la pelletée, le plus creusé).
		var done := _move_sand(center, plan.heights, scoops, {}, ctx, -1, terrain.soil(v))
		if done:
			_check_buried(center)  # 0.1.23 : la pelle sort ce qui est enterré tout près
		return done
	return _move_sand(center, plan.heights, -scoops, {}, ctx, shovel_soil)


## Lisser (Maj + clic gauche, 0.1.12, demande d'Othmane) : le sable sous la brosse se rapproche
## de sa hauteur moyenne. Il garde la même hauteur (le même volume : rien ne va sur la pelle ni
## n'en vient) mais devient plus plat ; en insistant, il devient tout à fait plat (posable).
## Ce qui empêche le geste ("" si rien).
func smooth_reason(v: Vector2i) -> String:
	var reason := _spot_reason(TerrainLogic.vertex_xz(v))
	if reason != "":
		return reason
	if _vertex_in_full_marsh(v):
		return "PROMPT_MARSH_NOT_EMPTY"
	if not _vertex_movable(v, _sand_context()):
		return "PROMPT_DIG_BLOCKED"
	return ""


## 0.1.20 : ce sommet touche-t-il une case d'un marais qui n'est pas vide ?
func _vertex_in_full_marsh(v: Vector2i) -> bool:
	for c in TerrainLogic.cells_of_vertex(v):
		var m := marsh_at_cell(c)
		if not m.is_empty() and not marsh_is_empty(m):
			return true
	return false


## Lisse le sable autour du sommet `v`. Vrai si le sol a changé.
func smooth_sand(v: Vector2i) -> bool:
	if smooth_reason(v) != "":
		return false
	var ctx := _sand_context()
	var weights := SandPhysics.brush(v, config.dig_brush_radius_m)
	var heights := {}
	for k: Vector2i in weights.keys():
		if _vertex_movable(k, ctx):
			heights[k] = terrain.vertex(k.x, k.y).y
		else:
			weights.erase(k)
	var target := SandPhysics.smooth(heights, weights, config.smooth_strength, TerrainLogic.FLAT_TOLERANCE * 0.75)
	var p := TerrainLogic.vertex_xz(v)
	# Ce qui est raboté comble les creux (de la terre reste de la terre).
	# 0.1.16 : animé comme l'aplanissement (doux, sans rebond, le temps d'une passe).
	sand_gesture = Gesture.LEVEL
	var ok := _move_sand(Vector3(p.x, terrain.vertex(v.x, v.y).y, p.y), target, 0.0, {}, ctx, _cut_soil(target))
	sand_gesture = Gesture.SCOOP
	return ok


## Ce que ferait une pelletée : {"heights": nouvelles hauteurs de la brosse, "volume": m³}.
func _plan_scoop(v: Vector2i, dig: bool, ctx: Dictionary) -> Dictionary:
	var weights := SandPhysics.brush(v, config.dig_brush_radius_m)
	var heights := {}
	for k: Vector2i in weights.keys():
		if _vertex_movable(k, ctx):
			heights[k] = terrain.vertex(k.x, k.y).y
		else:
			weights.erase(k)
	var room := config.shovel_capacity_scoops - shovel_sand if dig else shovel_sand
	var volume := minf(1.0, maxf(room, 0.0)) * config.dig_scoop_m3
	var floors := {}
	for k: Vector2i in heights:
		var p := TerrainLogic.vertex_xz(k)
		floors[k] = dig_floor_at(p.x, p.y)
	return SandPhysics.carve(heights, weights, volume, dig, dig_floor_y(), dig_ceil_y(), floors)


## Ce qu'il faut pour savoir quels sommets le sable peut bouger (calculé une fois par geste).
func _sand_context() -> Dictionary:
	return {"blockers": _dig_blockers(), "cells": {}, "vertices": {}}


## Un sommet que le sable peut bouger : sur l'île (pas dans la mer, pas au bord de la grille), et
## aucune de ses cases n'est sous un objet (l'objet le retient : il ne flotte ni ne s'enfonce).
func _vertex_movable(v: Vector2i, ctx: Dictionary) -> bool:
	var cache: Dictionary = ctx.vertices
	if cache.has(v):
		return cache[v]
	var ok := _spot_reason(TerrainLogic.vertex_xz(v)) == ""
	if ok:
		var cells: Dictionary = ctx.cells
		for c in TerrainLogic.cells_of_vertex(v):
			if not cells.has(c):
				cells[c] = _cell_blocked(c, ctx.blockers)
			if cells[c]:
				ok = false
				break
	cache[v] = ok
	return ok


## Pose les hauteurs `target` (Vector2i -> m), laisse le sable s'ébouler autour, met la pelle à
## jour (`scoops` pris > 0, posés < 0), et prévient les vues. Vrai si le sol a changé.
## 0.1.16 : `deposit` : la matière posée sur les sommets qui montent (-1 : rien de neuf) ;
## `taken` : celle qui va sur la pelle quand on en prend (elle devient ce que porte la pelle).
func _move_sand(center: Vector3, target: Dictionary, scoops: float, locked: Dictionary, ctx: Dictionary = {}, deposit: int = -1, taken: int = -1) -> bool:
	if ctx.is_empty():
		ctx = _sand_context()
	var h := target.duplicate()
	var read := func(k: Vector2i) -> float: return terrain.vertex(k.x, k.y).y
	var can_move := func(k: Vector2i) -> bool: return _vertex_movable(k, ctx)
	var seeds: Array = []
	for k: Vector2i in target:
		seeds.append(k)
		for d in SandPhysics.N8:
			seeds.append(k + d)
	var wet := water_level_y() + config.sand_wet_band_m
	var land := func(k: Vector2i) -> Vector2: return Vector2(terrain.base_vertex(k.x, k.y).y, 1.0 if terrain.soil(k) == TerrainLogic.Soil.EARTH else 0.0)
	var tan_earth := tan(deg_to_rad(config.earth_repose_deg))
	var slid := SandPhysics.relax(h, read, can_move, seeds, tan(deg_to_rad(config.sand_repose_deg)), tan(deg_to_rad(config.sand_wet_repose_deg)), wet, locked, 60000, land, tan_earth)
	# 0.1.15 : un bord de trou ou de tas arrondi (plus de pointes en étoile ni leurs ombres).
	# Seul l'éboulement est lissé : le fond creusé (ou le sommet posé) garde sa hauteur, sinon le
	# lissage rebouche le trou à chaque pelletée.
	var keep := locked.duplicate()
	for k: Vector2i in target:
		keep[k] = true
	var soft := SandPhysics.soften(h, read, can_move, slid.keys(), config.sand_soften_passes, config.sand_soften_k, keep)
	for k: Vector2i in soft:
		slid[k] = true
	# Le lissage peut raidir un peu la pente contre le fond (ou le sommet) qu'il ne touche pas :
	# un dernier éboulement, depuis les sommets lissés et ceux du geste, garde la pente limite.
	if not soft.is_empty():
		var again := SandPhysics.relax(h, read, can_move, soft.keys() + seeds, tan(deg_to_rad(config.sand_repose_deg)), tan(deg_to_rad(config.sand_wet_repose_deg)), wet, locked, 60000, land, tan_earth)
		for k: Vector2i in again:
			slid[k] = true
	_drop_tiny_moves(h, slid, target, read)
	var before := {}
	var after := {}
	for k: Vector2i in target:
		after[k] = h[k]
	for k: Vector2i in slid:
		after[k] = h[k]
	for k: Vector2i in after:
		before[k] = terrain.vertex(k.x, k.y).y
	var changed := terrain.set_vertices(after)
	if changed.is_empty():
		return false
	terrain.update_soil(before, after, deposit)
	if absf(scoops) > 0.0001:
		if scoops > 0.0 and taken >= 0 and shovel_sand <= 0.05:
			shovel_soil = taken
		shovel_sand = clampf(shovel_sand + scoops, 0.0, config.shovel_capacity_scoops)
		shovel_changed.emit()
	var touched := {}
	for k: Vector2i in after:
		touched[k] = true
	for pk in pickups:
		if touched.has(TerrainLogic.nearest_vertex(pk.position.x, pk.position.z)):
			pk.position.y = terrain.height(pk.position.x, pk.position.z)
			item_moved.emit(pk)
	sand_moved.emit(center, before, after, scoops)
	terrain_changed.emit(changed)
	return true


## 0.1.15 : les sommets que l'éboulement n'a bougés que de quelques millimètres restent intacts
## (sinon ils comptaient comme « travaillés » et dessinaient une étoile à pointes fines autour du
## trou). Leur sable va aux sommets qui ont vraiment bougé : le volume reste exact.
func _drop_tiny_moves(h: Dictionary, slid: Dictionary, target: Dictionary, read: Callable) -> void:
	var lost := 0.0
	var kept: Array[Vector2i] = []
	for k: Vector2i in slid.keys():
		if target.has(k):
			continue
		var d := float(h[k]) - float(read.call(k))
		if absf(d) < config.sand_min_move_m:
			lost += d
			h[k] = float(read.call(k))
			slid.erase(k)
		else:
			kept.append(k)
	if absf(lost) < 1e-9:
		return
	if kept.is_empty():
		for k: Vector2i in target:
			kept.append(k)
	if kept.is_empty():
		return
	var share := lost / kept.size()
	for k in kept:
		h[k] = float(h[k]) + share
		slid[k] = true


## Les formes qui interdisent de toucher au sable : objets posés, caisses, palmiers, rochers,
## noix de coco, tuyaux (tous niveaux : leurs piquets sont dans le sable).
func _dig_blockers() -> Array:
	var out := []
	for other in movable_items():
		out.append(PlacementGrid.rect_shape(item_rect(other)))
	# 0.1.20 : les tas des marais, et les marais qui ne sont pas vides (on ne rebouche pas de l'eau).
	out.append_array(_marsh_shapes({}, true))
	for c in crates:
		out.append(PlacementGrid.rect_shape(footprint_rect("caisse", c.position)))
	for o in config.fixed_obstacles:
		out.append(PlacementGrid.circle_shape(Vector3(o.x, 0.0, o.y), o.z))
	for spot in config.coconut_spots:
		out.append(PlacementGrid.circle_shape(spot, config.coconut_radius_m))
	for c: Vector3i in pipes:
		out.append(PlacementGrid.circle_shape(PipeNetwork.cell_center(c, config.grid_cell_m, 0.0), config.pipe_radius_m))
	return out


func _cell_blocked(cell: Vector2i, blockers: Array) -> bool:
	var c := config.grid_cell_m
	var shape := PlacementGrid.rect_shape(Rect2(cell.x * c + 0.02, cell.y * c + 0.02, c - 0.04, c - 0.04))
	return not PlacementGrid.conflicts(shape, blockers).is_empty()


# --- Niveau de l'eau -----------------------------------------------------------------------

## Hauteur réelle (honnête) de la surface de l'océan, en mètres.
## 0.1.20 : la surface VISIBLE, marée comprise (±30 cm, Q-27). C'est elle qu'on puise, où l'on
## nage, et que montre l'océan. La jauge et la fin lisent `honest_water_level_y`.
func water_level_y() -> float:
	return honest_water_level_y() + tide_offset_m()


## Hauteur réelle (honnête) de la surface : le volume retiré, sans la marée.
func honest_water_level_y() -> float:
	return config.sea_level_y - ocean.level_drop_m(config.ocean_surface_m2) - ending_drop_m


## La marée en ce moment (m). Plus de marée pendant la fin (l'océan s'en va).
func tide_offset_m() -> float:
	if ending != null or day == null:
		return 0.0
	return TideLogic.offset(day.hour(), config.tide_amplitude_m, config.tide_high_hour)


# --- La vraie fin et les réveils -----------------------------------------------------------

## Lance la vraie fin (M-04 : seulement par la touche de debug pour le MVP).
func start_ending() -> void:
	if ending != null:
		return
	ending = EndingLogic.new(config.ending_durations)
	ending_drop_m = 0.0
	pre_ending_removed_l = ocean.removed_l
	ui_open = true
	ending_started.emit()
	ending_phase_changed.emit(ending.phase)


## Clic pendant l'écran du temps ou le générique : on passe.
func skip_ending_screen() -> void:
	if ending != null:
		var before := ending.phase
		ending.skip()
		if ending.phase != before:
			_on_ending_phase(ending.phase)


func _step_ending(delta: float) -> void:
	if ending.step(delta):
		_on_ending_phase(ending.phase)
		if ending == null:
			return  # la run est finie
	# L'eau suit la mise en scène : on découvre la bonde, puis tout part dans le trou.
	match ending.phase:
		EndingLogic.Phase.DRAIN:
			ending_drop_m = config.ending_reveal_drop_m * ease(ending.progress(), 0.5)
		EndingLogic.Phase.GURGLE:
			ending_drop_m = lerpf(config.ending_reveal_drop_m, config.ending_empty_drop_m, ease(ending.progress(), 2.0))
		_:
			ending_drop_m = config.ending_empty_drop_m


func _on_ending_phase(phase: int) -> void:
	if phase == EndingLogic.Phase.WALK:
		ocean.remove_water(ocean.remaining_l())  # l'océan est vide
		ocean_changed.emit()
	ending_phase_changed.emit(phase)
	if phase == EndingLogic.Phase.DONE:
		finish_run()


## Fin de la run (Q-24) : on garde le meilleur temps, on sauvegarde, et on rend la main au menu.
func finish_run() -> void:
	best_time_s = play_time_s if finished_runs == 0 else minf(best_time_s, play_time_s)
	finished_runs += 1
	ending = null
	ui_open = false
	autosave()
	run_finished.emit()


## Réveil après une noyade : un trait de plus sur le palmier.
func register_wakeup() -> void:
	wakeups += 1
	wakeups_changed.emit()


# --- Sauvegarde ----------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"ocean": ocean.to_dict(),
		"bucket": bucket.to_dict(),
		"day": day.to_dict(),
		"phone": phone.to_dict(),
		"catalogue_delivered": catalogue_delivered,
		"milestones": milestones.to_dict(),
		"stock": stock.duplicate(),
		"carried": carried.duplicate(),
		"zones": zones.map(_zone_to_dict),
		"collection": collection.duplicate(),
		"gear": gear.duplicate(),
		"reef_shells": reef_shells.map(_v2a),
		"weather": weather,
		"discovered": discovered.keys(),
		"agency_order": agency_order.duplicate(),
		"wrecks": wrecks.map(func(w): return {"position": _v2a(w.position), "target": _v2a(w.target), "landed": w.landed}),
		"wreck_hour": wreck_hour,
		"buried": buried.map(func(b): return {"kind": b.kind, "position": _v2a(b.position)}),
		"treasure_buried": treasure_buried,
		"nests": nests.map(func(n): return {"position": _v2a(n.position), "laid_day": n.laid_day}),
		"turtle_day": _turtle_day,
		"planted": planted.map(func(pl): return {"position": _v2a(pl.position), "planted_day": pl.planted_day}),
		"coconuts_held": coconuts_held,
		"vessels": vessels.duplicate(),
		"tide_pools": tide_pools.map(func(tp): return {"items": tp.items.duplicate(), "low": tp.low, "pet_low": tp.pet_low}),
		"crates": crates.map(func(c): return {"position": _v2a(c.position), "items": c.items.duplicate()}),
		"decor": decor.map(func(d): return {"kind": d.kind, "position": _v2a(d.position), "rotation_deg": item_rotation(d)}),
		"owned": owned.duplicate(),
		"survival": survival.to_dict(),
		"pet": pet.to_dict(),
		"pickups": pickups.map(func(p): return {"kind": p.kind, "position": _v2a(p.position)}),
		"stations": stations.map(func(st): return {"kind": st.kind, "position": _v2a(st.position), "rotation_deg": item_rotation(st), "logic": (st.logic as StationLogic).to_dict()}),
		"slides": slides.map(func(sl): return {"kind": sl.kind, "position": _v2a(sl.position), "rotation_deg": item_rotation(sl)}),
		"mirrors": mirrors.map(func(m): return {"position": _v2a(m.position), "rotation_deg": item_rotation(m)}),
		"pumps": pumps.map(func(pu): return {"kind": pu.kind, "position": _v2a(pu.position), "rotation_deg": item_rotation(pu)}),
		"pipes": pipes.keys().map(func(c: Vector3i): return [c.x, c.y, c.z]),
		"pipe_stock": pipe_stock,
		"terrain": terrain.edits_to_array(),
		"terrain_sub": TerrainLogic.SUB,
		"soil_cover": terrain.cover_to_array(),
		"auto_pumped_l": auto_pumped_l,
		"demo_done": demo_done,
		"depot": {"position": _v2a(depot.position), "rotation_deg": item_rotation(depot)},
		"upgrades": {"unlocked_tier": unlocked_tier, "bucket_unit_l": bucket_unit_l, "bucket_count": bucket_count, "carry_capacity": carry_capacity, "speed_multiplier": speed_multiplier, "has_rake": has_rake, "has_shovel": has_shovel, "shovel_sand": shovel_sand, "shovel_soil": shovel_soil, "tool": toolbar.selected, "toolbar": Array(toolbar.slots)},
		"deliveries_count": _deliveries_count,
		"play_time_s": play_time_s,
		"wakeups": wakeups,
		"best_time_s": best_time_s,
		"pre_ending_removed_l": pre_ending_removed_l,
		"finished_runs": finished_runs,
	}


func load_dict(data: Dictionary) -> void:
	_reset_state()
	# Le sable travaillé d'abord : les objets posés dessus en dépendent.
	terrain.edits_from_array(data.get("terrain", []), int(data.get("terrain_sub", 1)))
	terrain.cover_from_array(data.get("soil_cover", []))
	if not terrain.edits.is_empty():
		terrain_changed.emit(terrain.edits.keys() + terrain.pinned_vertices())
	ocean.load_dict(data.get("ocean", {}))
	var up: Dictionary = data.get("upgrades", {})
	# Anciennes sauvegardes (sans "upgrades") : la contenance du seau suffit.
	bucket_unit_l = maxf(float(up.get("bucket_unit_l", float(data.get("bucket", {}).get("capacity_l", bucket_unit_l)))), config.starting_bucket_capacity_l)
	bucket_count = maxi(int(up.get("bucket_count", 1)), 1)
	carry_capacity = maxi(int(up.get("carry_capacity", carry_capacity)), config.hand_carry_capacity)
	speed_multiplier = maxf(float(up.get("speed_multiplier", 1.0)), 1.0)
	has_rake = bool(up.get("has_rake", false))
	# Avant 0.1.11, la pelle était donnée : une sauvegarde qui l'avait en barre la garde.
	has_shovel = bool(up.get("has_shovel", Array(up.get("toolbar", [])).has("pelle")))
	shovel_sand = clampf(float(up.get("shovel_sand", 0.0)), 0.0, config.shovel_capacity_scoops)
	shovel_soil = TerrainLogic.Soil.EARTH if int(up.get("shovel_soil", 0)) == TerrainLogic.Soil.EARTH else TerrainLogic.Soil.SAND
	unlocked_tier = maxi(int(up.get("unlocked_tier", 1)), 1)
	bucket.capacity_l = bucket_unit_l * bucket_count
	bucket.load_dict(data.get("bucket", {}))
	bucket.capacity_l = bucket_unit_l * bucket_count
	bucket.water_l = minf(bucket.water_l, bucket.capacity_l)
	day.load_dict(data.get("day", {}))
	phone.load_dict(data.get("phone", {}))
	# Vieille sauvegarde : le catalogue papier posé au sol part dans la cabine.
	catalogue_delivered = bool(data.get("catalogue_delivered", phone.tutorial_done))
	if data.has("milestones"):
		milestones.load_dict(data.milestones)
	else:
		# Vieille sauvegarde : les jalons déjà dépassés comptent, sans redonner les récompenses.
		milestones.update(ocean.removed_l)
	stock = Economy.empty_stock()
	Economy.add(stock, Economy.sanitize(data.get("stock", {})))
	carried = Economy.sanitize(data.get("carried", {}))
	for z in data.get("zones", []):
		var zone := add_marsh(_cells_from(z.get("cells", []))) if String(z.get("kind", "")) == "marais" else add_zone(String(z.get("kind", "")), _a2v(z.get("position", [])))
		if not zone.is_empty():
			(zone.logic as DryingLogic).load_dict(z.get("logic", {}))
			_load_rotation(zone, z)
	if zones.is_empty():
		add_zone("cuvette", config.basin_position)
	for c in data.get("crates", []):
		var crate := {"id": _new_id("crate"), "position": _a2v(c.get("position", [])), "items": Array(c.get("items", [])).map(func(i): return String(i))}
		crates.append(crate)
		crate_added.emit(crate, false)
	for d in data.get("decor", []):
		if String(d.get("kind", "")) == "catalogue_papier":
			catalogue_delivered = true
			continue
		var dec := {"id": _new_id("decor"), "kind": String(d.get("kind", "")), "position": _a2v(d.get("position", []))}
		decor.append(dec)
		decor_added.emit(dec)
		_load_rotation(dec, d)
	survival.load_dict(data.get("survival", {}))
	pet.load_dict(data.get("pet", {}))
	collection = {}
	var col = data.get("collection", {})
	if col is Dictionary:
		for k in col:
			if int(col[k]) > 0:
				collection[String(k)] = int(col[k])
	gear = {}
	for k in data.get("gear", {}):
		gear[String(k)] = true
	_apply_gear()
	weather = String(data.get("weather", WeatherLogic.DEFAULT))
	if not config.weather_table.has(weather):
		weather = WeatherLogic.DEFAULT
	_apply_weather()
	discovered = {}
	for r in data.get("discovered", []):
		if Economy.FOUND_ONLY.has(String(r)):
			discovered[String(r)] = true
	for src in [stock, carried]:
		for r in src:
			if int(src[r]) > 0:
				_discover(String(r), false)
	var ao = data.get("agency_order", {})
	agency_order = {}
	if ao is Dictionary and agency_order_def(String(ao.get("id", ""))) != {}:
		agency_order = {"id": String(ao.id), "sent": bool(ao.get("sent", false))}
	elif not data.has("agency_order"):
		_new_agency_order()
	for w in wrecks:
		wreck_removed.emit(w)
	wrecks = []
	for w in data.get("wrecks", []):
		_add_wreck(_a2v(w.get("position", [])), _a2v(w.get("target", [])), bool(w.get("landed", false)))
	wreck_hour = float(data.get("wreck_hour", -1.0))
	buried = []
	for b in data.get("buried", []):
		if config.buried_weights.has(String(b.get("kind", ""))) or String(b.get("kind", "")) == "tresor":
			buried.append({"kind": String(b.kind), "position": _a2v(b.get("position", []))})
	treasure_buried = bool(data.get("treasure_buried", false))
	if not data.has("buried"):
		_refill_buried()
	nests = []
	for n in data.get("nests", []):
		nests.append({"id": _new_id("nest"), "position": _a2v(n.get("position", [])), "laid_day": int(n.get("laid_day", 0))})
	_turtle_day = int(data.get("turtle_day", -1))
	planted = []
	for pl in data.get("planted", []):
		planted.append({"id": _new_id("palm"), "position": _a2v(pl.get("position", [])), "planted_day": int(pl.get("planted_day", 0))})
	coconuts_held = int(data.get("coconuts_held", 0))
	vessels = {}
	var vs: Dictionary = data.get("vessels", {})
	for k in vs:
		vessels[String(k)] = float(vs[k])
	reef_shells = []
	if data.has("reef_shells"):
		for r in data.get("reef_shells", []):
			reef_shells.append(_a2v(r))
	else:
		_refill_reef()
	var saved_pools: Array = data.get("tide_pools", [])
	for i in mini(saved_pools.size(), tide_pools.size()):
		var sp = saved_pools[i]
		if sp is Dictionary:
			tide_pools[i].items = Array(sp.get("items", [])).map(func(x): return String(x)).filter(func(x): return config.tide_pool_items.has(x))
			tide_pools[i].low = int(sp.get("low", -1))
			tide_pools[i].pet_low = int(sp.get("pet_low", -1))
	if data.has("pickups"):
		for p in data.get("pickups", []):
			add_pickup(String(p.get("kind", "")), _a2v(p.get("position", [])))
	else:
		_morning_refill()  # sauvegarde d'avant cette version : on garnit la plage
	for st in data.get("stations", []):
		var station := add_station(String(st.get("kind", "")), _a2v(st.get("position", [])))
		if not station.is_empty():
			(station.logic as StationLogic).load_dict(st.get("logic", {}))
			_load_rotation(station, st)
	for m in data.get("mirrors", []):
		if m is Array:
			add_mirror(_a2v(m))  # sauvegarde d'avant la rotation : juste la position
		else:
			_load_rotation(add_mirror(_a2v(m.get("position", []))), m)
	for sl in data.get("slides", []):
		_load_rotation(add_slide(String(sl.get("kind", "toboggan")), _a2v(sl.get("position", []))), sl)
	for pu in data.get("pumps", []):
		_load_rotation(add_pump(String(pu.get("kind", "")), _a2v(pu.get("position", []))), pu)
	for c in data.get("pipes", []):
		if c is Array and c.size() == 3:
			pipes[Vector3i(int(c[0]), int(c[1]), int(c[2]))] = true
	# Anciennes sauvegardes : des tronçons de 4 m deviennent 4 pièces en stock.
	pipe_stock = maxi(int(data.get("pipe_stock", int(data.get("pipe_segments", 0)) * 4)), 0)
	auto_pumped_l = maxf(float(data.get("auto_pumped_l", 0.0)), 0.0)
	demo_done = bool(data.get("demo_done", false))
	var dep: Dictionary = data.get("depot", {})
	if dep.has("position"):
		depot.position = _a2v(dep.position)
	_load_rotation(depot, dep)
	owned = data.get("owned", {}).duplicate()
	_deliveries_count = int(data.get("deliveries_count", 0))
	play_time_s = float(data.get("play_time_s", 0.0))
	wakeups = maxi(int(data.get("wakeups", 0)), 0)
	best_time_s = maxf(float(data.get("best_time_s", 0.0)), 0.0)
	pre_ending_removed_l = maxf(float(data.get("pre_ending_removed_l", 0.0)), 0.0)
	# Une partie finie se rouvre juste avant le drain (Q-25) : l'eau d'avant la chaîne revient.
	finished_runs = maxi(int(data.get("finished_runs", 0)), 0)
	if finished_runs > 0:
		ocean.removed_l = minf(ocean.removed_l, pre_ending_removed_l)
	# La barre en dernier : elle dépend des outils, des tuyaux et de ce qu'on porte.
	var saved_slots = up.get("toolbar", [])
	if saved_slots is Array and saved_slots.size() == toolbar.slots.size():
		for i in saved_slots.size():
			toolbar.slots[i] = String(saved_slots[i]) if saved_slots[i] is String else ""
	toolbar.selected = int(up.get("tool", 0))
	_sync_toolbar()
	_emit_all()


func save_game() -> Error:
	return SaveSystem.write(current_slot, to_dict(), save_dir)


func load_game(slot: int) -> bool:
	var data := SaveSystem.read(slot, save_dir)
	if data.is_empty():
		return false
	current_slot = slot
	load_dict(data)
	return true


## Sans menu principal (tests, captures) : on reprend l'emplacement 1 s'il existe.
func continue_or_new() -> void:
	if not load_game(current_slot):
		new_game()
	autosave_enabled = true


## Menu principal (M-71) : reprend l'emplacement `slot`, ou y commence une partie neuve.
## À partir de là, la partie est sauvegardée dans cet emplacement.
func play_slot(slot: int) -> void:
	current_slot = slot
	if not load_game(slot):
		new_game()
	autosave_enabled = true
	save_game()


## « Nouvelle partie » dans un emplacement : remplace ce qui s'y trouvait (le menu a demandé).
func new_game_in_slot(slot: int) -> void:
	current_slot = slot
	new_game()
	autosave_enabled = true
	save_game()


## Sauvegarde automatique (M-77) : seulement quand une partie a été choisie.
func autosave() -> void:
	if autosave_enabled:
		save_game()


## Efface un emplacement (menu principal). Ne touche pas à la partie en cours.
func delete_slot(slot: int) -> void:
	SaveSystem.delete(slot, save_dir)


func _notification(what: int) -> void:
	# Sauvegarde en quittant (M-77).
	if what == NOTIFICATION_WM_CLOSE_REQUEST and autosave_enabled:
		save_game()


# --- Outils internes -----------------------------------------------------------------------

func _emit_all() -> void:
	tool_changed.emit()
	phone_changed.emit()
	network_changed.emit()
	item_moved.emit(depot)  # la palette n'est pas recréée : on la remet à sa place
	survival_changed.emit()
	ocean_changed.emit()
	wakeups_changed.emit()
	stock_changed.emit()
	carried_changed.emit()
	bucket_changed.emit()
	shovel_changed.emit()
	pet_changed.emit()
	collection_changed.emit()
	tide_pools_changed.emit()
	gear_changed.emit()
	reef_changed.emit()
	weather_changed.emit()
	resources_discovered.emit()
	agency_order_changed.emit()
	planted_changed.emit()


func _new_id(prefix: String) -> String:
	_next_id += 1
	return "%s_%d" % [prefix, _next_id]


static func _v2a(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


static func _a2v(a: Variant) -> Vector3:
	if typeof(a) == TYPE_ARRAY and a.size() == 3:
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO
