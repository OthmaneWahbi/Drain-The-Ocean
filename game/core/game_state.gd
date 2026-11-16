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
## La barre d'outils de 5 cases : quel outil on tient (M-27).
var toolbar: ToolbarLogic = ToolbarLogic.new()
## Endurance du personnage (pas sauvegardée : elle est pleine au chargement).
var stamina: StaminaLogic
## Faim et soif (sauvegardées).
var survival: SurvivalLogic
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
	rng.randomize()
	new_game()


func new_game() -> void:
	_reset_state()
	add_zone("cuvette", find_free_spot(footprint_of("cuvette"), config.basin_position))
	_morning_refill()
	_emit_all()


## Remet tout à zéro (sans cuvette) et prévient les vues qu'elles doivent tout effacer.
func _reset_state() -> void:
	ocean = OceanModel.new(config.total_ocean_volume_l, config.drain_threshold_ratio)
	bucket = BucketLogic.new(config.starting_bucket_capacity_l, config.bucket_fill_time_s)
	day = DayCycleLogic.new(config.day_length_s, config.start_hour)
	phone = PhoneLogic.new()
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
	toolbar = ToolbarLogic.new(config.toolbar_slots)
	stamina = StaminaLogic.new(config.stamina_run_s, config.stamina_swim_s, config.stamina_regen_s, config.stamina_exhausted_ratio)
	survival = SurvivalLogic.new(config.food_empty_s, config.water_empty_s, config.starving_penalty_max, config.starving_penalty_time_s)
	pickups = []
	stations = []
	mirrors = []
	slides = []
	pumps = []
	pipes = {}
	pipe_stock = 0
	auto_pumped_l = 0.0
	demo_done = false
	depot = {"id": "depot", "kind": "palette", "position": config.depot_position, "rotation_deg": 0.0}
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
		if phone.on_new_morning(rng, config.offer_chance_per_day, offer_candidates()):
			phone_changed.emit()
		new_morning.emit()
	var base := day.evaporation_multiplier(config.night_evaporation_factor)
	for zone in zones:
		(zone.logic as DryingLogic).step(delta, base * zone_boost(zone), rng)
	for st in stations:
		(st.logic as StationLogic).step(delta)
	_run_auto_pumps(delta)
	_run_slides(delta)
	check_milestones()
	survival.step(delta)
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


## Bonus d'évaporation des miroirs solaires proches (+50 % chacun, PRD §7).
func zone_boost(zone: Dictionary) -> float:
	var n := 0
	for m in mirrors:
		if (m.position as Vector3).distance_to(zone.position) <= config.mirror_radius_m:
			n += 1
	return 1.0 + config.mirror_bonus * n


# --- Le seau --------------------------------------------------------------------------------

## Remplit le seau dans la mer. Peut remonter un coquillage (et rarement une perle).
func fill_bucket() -> void:
	var taken := ocean.remove_water(bucket.missing_l())
	bucket.water_l += taken
	if rng.randf() < config.shell_chance_per_scoop:
		add_carried({"coquillages": 1})
		if rng.randf() < config.pearl_chance_per_shell:
			add_carried({"perles": 1})
	ocean_changed.emit()
	bucket_changed.emit()
	check_milestones()


## Verse le seau dans une zone de séchage. Renvoie la quantité acceptée.
func pour_bucket_into(zone: Dictionary) -> float:
	var logic: DryingLogic = zone.logic
	var accepted := logic.add_water(bucket.water_l)
	bucket.water_l -= accepted
	bucket_changed.emit()
	return accepted


## Vide le seau ailleurs : sur le sable ou dans la mer, l'eau retourne à l'océan (M-33, M-34).
func pour_bucket_out() -> void:
	ocean.return_water(bucket.empty_out())
	ocean_changed.emit()
	bucket_changed.emit()


# --- Récolte, transport, palette -----------------------------------------------------------

func carried_count() -> int:
	return Economy.count(carried)


func carry_space() -> int:
	return maxi(carry_capacity - carried_count(), 0)


## Ajoute des ressources dans les bras, dans la limite de ce qu'on peut porter.
## Renvoie ce qui n'a pas pu être pris.
## Chaque matériau porté prend une case de la barre : sans case libre, on ne le prend pas.
func add_carried(items: Dictionary) -> Dictionary:
	_sync_toolbar()
	var leftover := {}
	for k in items:
		var key := String(k)
		var n := int(items[k])
		var take := mini(n, carry_space()) if has_slot_for(key) else 0
		if take > 0:
			carried[key] = int(carried.get(key, 0)) + take
			toolbar.put(key)
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
	return carry_space() > 0 and has_slot_for(key)


## Récolte le dépôt d'une zone (M-39) : quelques unités par clic à la main, tout d'un coup
## avec le râteau. Ce qu'on ne peut pas porter reste dans la zone.
## `resource` : le tas visé (un tas par matériau) ; vide = n'importe lequel.
func harvest(zone: Dictionary, resource: String = "") -> void:
	var logic: DryingLogic = zone.logic
	# Le râteau ramasse tout d'un coup, mais seulement si on le TIENT (barre d'outils).
	var n := carry_space() if current_tool() == "rateau" else mini(config.manual_harvest_per_click, carry_space())
	var leftover := add_carried(logic.take_some(n, resource))
	Economy.add(logic.deposit, leftover)


# --- Barre d'outils (M-27) --------------------------------------------------------------------

## Les outils, dans l'ordre où ils prennent une case quand on les obtient.
const TOOLS: Array[String] = ["seau", "rateau", "tuyaux"]


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
		"rateau":
			return has_rake
		"tuyaux":
			return pipe_stock > 0 or not pipes.is_empty()
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
	return find_free_spot(footprint_of("caisse"), wanted)


## Ouvre une caisse : applique l'effet de chaque objet à l'endroit de la caisse.
func open_crate(crate: Dictionary) -> void:
	if not crates.has(crate):
		return
	crates.erase(crate)
	var placed: Array[Dictionary] = []
	for id in crate.items:
		var item := catalog.find(StringName(id))
		if item:
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
		position = find_free_spot(footprint_of(kind), position, min_center_radius_of(kind))
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
		if PlacementGrid.is_valid(spot, footprint_of("coquillage"), blockers, config.build_radius_m):
			return spot
	return NO_SPOT


## Vrai si rien n'occupe ce cercle. `with_coconut_spots` : compter aussi les places des noix de coco.
func _spot_is_free(pos: Vector3, radius: float, with_coconut_spots: bool = true) -> bool:
	return PlacementGrid.is_valid(pos, radius, _blockers_except({}, with_coconut_spots), INF)


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
			survival.eat(config.coconut_food)
			survival.drink(config.coconut_water)
			survival_changed.emit()
		"shell":
			if not can_carry("coquillages"):
				return false
			var found := {"coquillages": 1}
			if rng.randf() < config.pearl_chance_per_shell:
				found["perles"] = 1
			add_carried(found)
	pickups.erase(p)
	pickup_removed.emit(p)
	return true


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
	return PipeNetwork.zones_reached(pump.position, pipes, zones, inlet_radius, config.grid_cell_m)


## Rayon dans lequel une pièce de tuyau verse dans la zone (le bac, sans le tas de sel).
func inlet_radius(zone: Dictionary) -> float:
	return float(config.inlet_radius.get(String(zone.kind), 1.0))


## Les pièces où passe l'eau d'au moins une pompe (pour les colorer).
func wet_pipes() -> Dictionary:
	var out := {}
	for pump in pumps:
		out.merge(PipeNetwork.reach(PipeNetwork.cell_of(pump.position, config.grid_cell_m), pipes))
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
	if flat.length() + 0.5 > config.build_radius_m:
		return false
	if cell.y == 0:
		for b in _blockers_except({}, true, false, false):
			var bp: Vector3 = b.position
			if flat.distance_to(Vector2(bp.x, bp.z)) < float(b.radius) + config.pipe_radius_m - 1e-6:
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
		var zp: Vector3 = z.position
		if Vector2(zp.x - sp.x, zp.z - sp.z).length() <= footprint(z) + config.slide_reach_m:
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


func footprint(item: Dictionary) -> float:
	return footprint_of(item_kind(item))


func footprint_of(kind: String) -> float:
	return float(config.footprints.get(kind, 1.0))


## Où est le tas d'un matériau, par rapport au centre de sa zone (avant rotation) : chaque
## matériau a sa propre case, côte à côte (config.pile_slots), dans l'emprise de la zone.
func pile_offset(zone: Dictionary, resource: String = "sel") -> Vector3:
	var x := float(config.pile_offset_cells.get(String(zone.kind), 2))
	var z := float(config.pile_slots.get(resource, 0))
	return Vector3(x, 0.0, z) * config.grid_cell_m


## Tous les objets qu'on peut déplacer.
func movable_items() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	all.append_array(zones)
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
			out.append({"position": other.position, "radius": footprint(other)})
	for c in crates:
		out.append({"position": c.position, "radius": footprint_of("caisse")})
	for o in config.fixed_obstacles:
		out.append({"position": Vector3(o.x, 0.0, o.y), "radius": o.z})
	if with_coconut_spots:
		for spot in config.coconut_spots:
			out.append({"position": spot, "radius": config.coconut_radius_m})
	for pk in pickups:
		if pk != item and pk.kind != "coconut":  # les noix sont déjà comptées par leur place
			out.append({"position": pk.position, "radius": footprint_of("coquillage")})
	out.append({"position": player_position, "radius": config.player_radius_m})
	# Les tuyaux au sol gênent tout, sauf les zones de séchage (on peut poser un bac sous un tuyau).
	if with_pipes and not zones.has(item):
		for c in pipes:
			if c.y == 0:
				out.append({"position": PipeNetwork.cell_center(c, config.grid_cell_m, 0.0), "radius": config.pipe_radius_m})
	return out


## La case libre la plus proche de `near` pour une emprise de rayon `radius` (cherche en carrés
## de plus en plus grands). Si rien n'est libre, renvoie la case de `near`.
func find_free_spot(radius: float, near: Vector3, min_center_radius: float = 0.0) -> Vector3:
	var cell := config.grid_cell_m
	var start := PlacementGrid.snap(near, cell)
	var blockers := _blockers_except({})
	# Assez d'anneaux pour couvrir toute l'île, même en partant d'un bord.
	var rings := int(ceil(config.build_radius_m * 2.0 / cell)) + 1
	for ring in rings:
		for dx in range(-ring, ring + 1):
			for dz in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dz)) != ring:
					continue
				var p := start + Vector3(dx * cell, 0.0, dz * cell)
				if PlacementGrid.is_valid(p, radius, blockers, config.build_radius_m, min_center_radius):
					return p
	return start


func can_place(item: Dictionary, pos: Vector3) -> bool:
	return PlacementGrid.is_valid(pos, footprint(item), blockers_for(item), config.build_radius_m, min_center_radius_of(item_kind(item)))


## Distance minimale au centre de l'île pour ce type (les pompes vont au bord de l'eau).
func min_center_radius_of(kind: String) -> float:
	return float(config.shore_only_kinds.get(kind, 0.0))


## Déplace (et tourne) un objet sur la case visée. Renvoie faux si l'emplacement n'est pas valide.
## Sans `rotation_deg`, l'objet garde son orientation.
func move_item(item: Dictionary, pos: Vector3, rotation_deg: float = NAN) -> bool:
	var snapped := PlacementGrid.snap(pos, config.grid_cell_m)
	snapped.y = (item.position as Vector3).y
	if not can_place(item, snapped):
		return false
	item.position = snapped
	if not is_nan(rotation_deg):
		item.rotation_deg = PlacementGrid.wrap_deg(rotation_deg)
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


# --- Niveau de l'eau -----------------------------------------------------------------------

## Hauteur réelle (honnête) de la surface de l'océan, en mètres.
func water_level_y() -> float:
	return config.sea_level_y - ocean.level_drop_m(config.ocean_surface_m2) - ending_drop_m


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
		"milestones": milestones.to_dict(),
		"stock": stock.duplicate(),
		"carried": carried.duplicate(),
		"zones": zones.map(func(z): return {"kind": z.kind, "position": _v2a(z.position), "rotation_deg": item_rotation(z), "logic": (z.logic as DryingLogic).to_dict()}),
		"crates": crates.map(func(c): return {"position": _v2a(c.position), "items": c.items.duplicate()}),
		"decor": decor.map(func(d): return {"kind": d.kind, "position": _v2a(d.position), "rotation_deg": item_rotation(d)}),
		"owned": owned.duplicate(),
		"survival": survival.to_dict(),
		"pickups": pickups.map(func(p): return {"kind": p.kind, "position": _v2a(p.position)}),
		"stations": stations.map(func(st): return {"kind": st.kind, "position": _v2a(st.position), "rotation_deg": item_rotation(st), "logic": (st.logic as StationLogic).to_dict()}),
		"slides": slides.map(func(sl): return {"kind": sl.kind, "position": _v2a(sl.position), "rotation_deg": item_rotation(sl)}),
		"mirrors": mirrors.map(func(m): return {"position": _v2a(m.position), "rotation_deg": item_rotation(m)}),
		"pumps": pumps.map(func(pu): return {"kind": pu.kind, "position": _v2a(pu.position), "rotation_deg": item_rotation(pu)}),
		"pipes": pipes.keys().map(func(c: Vector3i): return [c.x, c.y, c.z]),
		"pipe_stock": pipe_stock,
		"auto_pumped_l": auto_pumped_l,
		"demo_done": demo_done,
		"depot": {"position": _v2a(depot.position), "rotation_deg": item_rotation(depot)},
		"upgrades": {"unlocked_tier": unlocked_tier, "bucket_unit_l": bucket_unit_l, "bucket_count": bucket_count, "carry_capacity": carry_capacity, "speed_multiplier": speed_multiplier, "has_rake": has_rake, "tool": toolbar.selected, "toolbar": Array(toolbar.slots)},
		"deliveries_count": _deliveries_count,
		"play_time_s": play_time_s,
		"wakeups": wakeups,
		"best_time_s": best_time_s,
		"pre_ending_removed_l": pre_ending_removed_l,
		"finished_runs": finished_runs,
	}


func load_dict(data: Dictionary) -> void:
	_reset_state()
	ocean.load_dict(data.get("ocean", {}))
	var up: Dictionary = data.get("upgrades", {})
	# Anciennes sauvegardes (sans "upgrades") : la contenance du seau suffit.
	bucket_unit_l = maxf(float(up.get("bucket_unit_l", float(data.get("bucket", {}).get("capacity_l", bucket_unit_l)))), config.starting_bucket_capacity_l)
	bucket_count = maxi(int(up.get("bucket_count", 1)), 1)
	carry_capacity = maxi(int(up.get("carry_capacity", carry_capacity)), config.hand_carry_capacity)
	speed_multiplier = maxf(float(up.get("speed_multiplier", 1.0)), 1.0)
	has_rake = bool(up.get("has_rake", false))
	unlocked_tier = maxi(int(up.get("unlocked_tier", 1)), 1)
	bucket.capacity_l = bucket_unit_l * bucket_count
	bucket.load_dict(data.get("bucket", {}))
	bucket.capacity_l = bucket_unit_l * bucket_count
	bucket.water_l = minf(bucket.water_l, bucket.capacity_l)
	day.load_dict(data.get("day", {}))
	phone.load_dict(data.get("phone", {}))
	if data.has("milestones"):
		milestones.load_dict(data.milestones)
	else:
		# Vieille sauvegarde : les jalons déjà dépassés comptent, sans redonner les récompenses.
		milestones.update(ocean.removed_l)
	stock = Economy.empty_stock()
	Economy.add(stock, Economy.sanitize(data.get("stock", {})))
	carried = Economy.sanitize(data.get("carried", {}))
	for z in data.get("zones", []):
		var zone := add_zone(String(z.get("kind", "")), _a2v(z.get("position", [])))
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
		var dec := {"id": _new_id("decor"), "kind": String(d.get("kind", "")), "position": _a2v(d.get("position", []))}
		decor.append(dec)
		decor_added.emit(dec)
		_load_rotation(dec, d)
	survival.load_dict(data.get("survival", {}))
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


func _new_id(prefix: String) -> String:
	_next_id += 1
	return "%s_%d" % [prefix, _next_id]


static func _v2a(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


static func _a2v(a: Variant) -> Vector3:
	if typeof(a) == TYPE_ARRAY and a.size() == 3:
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO
