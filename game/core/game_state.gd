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
	dialogues = DialogueLogic.load_file()
	rng.randomize()
	new_game()


func new_game() -> void:
	_reset_state()
	add_zone("cuvette", find_free_spot("cuvette", config.basin_position))
	_morning_refill()
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
		var n := mini(budget, carry_space(key))
		if n <= 0:
			continue
		var got := logic.take_some(n, key)
		var leftover := add_carried(got)
		Economy.add(logic.deposit, leftover)
		budget -= Economy.count(got) - Economy.count(leftover)


# --- Barre d'outils (M-27) --------------------------------------------------------------------

## Les outils, dans l'ordre où ils prennent une case quand on les obtient.
const TOOLS: Array[String] = ["seau", "pelle", "rateau", "tuyaux"]


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
			out.append(PlacementGrid.rect_shape(item_rect(other)))
	for c in crates:
		out.append(PlacementGrid.rect_shape(footprint_rect("caisse", c.position)))
	for o in config.fixed_obstacles:
		out.append(PlacementGrid.circle_shape(Vector3(o.x, 0.0, o.y), o.z))
	if with_coconut_spots:
		for spot in config.coconut_spots:
			out.append(PlacementGrid.circle_shape(spot, config.coconut_radius_m))
	for pk in pickups:
		if pk != item and pk.kind != "coconut":  # les noix sont déjà comptées par leur place
			out.append(PlacementGrid.rect_shape(footprint_rect("coquillage", pk.position)))
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
	if is_nan(level) or level < water_level_y() + config.dig_min_above_water_m:
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


## Le plus bas où l'on creuse (jamais trop près de l'eau) et le plus haut où l'on entasse.
func dig_floor_y() -> float:
	return water_level_y() + config.dig_min_above_water_m


func dig_ceil_y() -> float:
	return config.ground_y + config.dig_max_above_ground_m


## Le niveau d'aplanissement d'une case (au niveau `ref`, ou au sien), arrondi au cran, borné.
func flatten_level(cell: Vector2i, ref := NAN) -> float:
	var y := dig_snap(ref) if not is_nan(ref) else dig_snap(terrain.cell_mean(cell))
	var lo := dig_snap(dig_floor_y() + config.dig_step_m * 0.49)
	return clampf(y, lo, dig_ceil_y())


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
	var center := Vector2((cell.x + 0.5) * config.grid_cell_m, (cell.y + 0.5) * config.grid_cell_m)
	var reason := _spot_reason(center)
	if reason != "":
		return reason
	var blockers := _dig_blockers()
	if _cell_blocked(cell, blockers):
		return "PROMPT_DIG_BLOCKED"
	for v in TerrainLogic.cell_vertices(cell):
		if absf(terrain.vertex(v.x, v.y).y - y) <= TerrainLogic.FLAT_TOLERANCE:
			continue
		for other in TerrainLogic.cells_of_vertex(v):
			if other != cell and _cell_blocked(other, blockers):
				return "PROMPT_DIG_NEAR_OBJECT"
	var scoops := dig_scoops(cell, y)
	if scoops > 0.0 and shovel_sand + scoops > config.shovel_capacity_scoops + 0.01:
		return "PROMPT_DIG_SHOVEL_FULL"
	if scoops < 0.0 and shovel_sand + scoops < -0.01:
		return "PROMPT_DIG_SHOVEL_EMPTY"
	return ""


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
	var scoops := dig_scoops(cell, y)
	var target := {}
	var locked := {}
	for v in TerrainLogic.cell_vertices(cell):
		target[v] = y
		locked[v] = true
	var center := Vector3((cell.x + 0.5) * config.grid_cell_m, y, (cell.y + 0.5) * config.grid_cell_m)
	return _move_sand(center, target, scoops, locked)


## La pelletée : creuser (clic gauche, `dig` vrai) ou poser le sable porté (clic droit), autour du
## sommet `v`. Ce qui empêche le geste ("" si rien), en clé de texte d'aide.
func scoop_reason(v: Vector2i, dig: bool) -> String:
	var reason := _spot_reason(TerrainLogic.vertex_xz(v))
	if reason != "":
		return reason
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
	return ""


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
	return _move_sand(center, plan.heights, scoops if dig else -scoops, {}, ctx)


## Lisser (Maj + clic gauche, 0.1.12, demande d'Othmane) : le sable sous la brosse se rapproche
## de sa hauteur moyenne. Il garde la même hauteur (le même volume : rien ne va sur la pelle ni
## n'en vient) mais devient plus plat ; en insistant, il devient tout à fait plat (posable).
## Ce qui empêche le geste ("" si rien).
func smooth_reason(v: Vector2i) -> String:
	var reason := _spot_reason(TerrainLogic.vertex_xz(v))
	if reason != "":
		return reason
	if not _vertex_movable(v, _sand_context()):
		return "PROMPT_DIG_BLOCKED"
	return ""


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
	return _move_sand(Vector3(p.x, terrain.vertex(v.x, v.y).y, p.y), target, 0.0, {}, ctx)


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
	return SandPhysics.carve(heights, weights, volume, dig, dig_floor_y(), dig_ceil_y())


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
func _move_sand(center: Vector3, target: Dictionary, scoops: float, locked: Dictionary, ctx: Dictionary = {}) -> bool:
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
	var slid := SandPhysics.relax(h, read, can_move, seeds, tan(deg_to_rad(config.sand_repose_deg)), tan(deg_to_rad(config.sand_wet_repose_deg)), wet, locked)
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
	if absf(scoops) > 0.0001:
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


## Les formes qui interdisent de toucher au sable : objets posés, caisses, palmiers, rochers,
## noix de coco, tuyaux (tous niveaux : leurs piquets sont dans le sable).
func _dig_blockers() -> Array:
	var out := []
	for other in movable_items():
		out.append(PlacementGrid.rect_shape(item_rect(other)))
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
		"catalogue_delivered": catalogue_delivered,
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
		"terrain": terrain.edits_to_array(),
		"terrain_sub": TerrainLogic.SUB,
		"auto_pumped_l": auto_pumped_l,
		"demo_done": demo_done,
		"depot": {"position": _v2a(depot.position), "rotation_deg": item_rotation(depot)},
		"upgrades": {"unlocked_tier": unlocked_tier, "bucket_unit_l": bucket_unit_l, "bucket_count": bucket_count, "carry_capacity": carry_capacity, "speed_multiplier": speed_multiplier, "has_rake": has_rake, "has_shovel": has_shovel, "shovel_sand": shovel_sand, "tool": toolbar.selected, "toolbar": Array(toolbar.slots)},
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
		if String(d.get("kind", "")) == "catalogue_papier":
			catalogue_delivered = true
			continue
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
	shovel_changed.emit()


func _new_id(prefix: String) -> String:
	_next_id += 1
	return "%s_%d" % [prefix, _next_id]


static func _v2a(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


static func _a2v(a: Variant) -> Vector3:
	if typeof(a) == TYPE_ARRAY and a.size() == 3:
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO
