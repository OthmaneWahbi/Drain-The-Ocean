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
signal pickup_added(pickup: Dictionary)
signal pickup_removed(pickup: Dictionary)
signal station_added(station: Dictionary)
signal station_removed(station: Dictionary)
signal survival_changed
signal game_reset

const CONFIG_PATH := "res://data/game_config.tres"
const CATALOG_PATH := "res://data/catalog.tres"

var config: GameConfig
var catalog: CatalogDatabase
var rng := RandomNumberGenerator.new()

var ocean: OceanModel
var bucket: BucketLogic
var day: DayCycleLogic
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
## Endurance du personnage (pas sauvegardée : elle est pleine au chargement).
var stamina: StaminaLogic
## Faim et soif (sauvegardées).
var survival: SurvivalLogic
## Petits objets à ramasser avec E : {id, kind: "coconut" | "shell", position}.
var pickups: Array[Dictionary] = []
## Objets posés qui contiennent des portions : {id, kind: "condenseur" | "rations", position, logic: StationLogic}.
var stations: Array[Dictionary] = []
var play_time_s: float = 0.0
var current_slot: int = 1
## Vrai quand un menu (catalogue…) a la main : le joueur ne bouge plus.
var ui_open: bool = false

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
	rng.randomize()
	new_game()


func new_game() -> void:
	_reset_state()
	add_zone("cuvette", config.basin_position)
	_morning_refill()
	_emit_all()


## Remet tout à zéro (sans cuvette) et prévient les vues qu'elles doivent tout effacer.
func _reset_state() -> void:
	ocean = OceanModel.new(config.total_ocean_volume_l, config.drain_threshold_ratio)
	bucket = BucketLogic.new(config.starting_bucket_capacity_l, config.bucket_fill_time_s)
	day = DayCycleLogic.new(config.day_length_s, config.start_hour)
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
	stamina = StaminaLogic.new(config.stamina_run_s, config.stamina_swim_s, config.stamina_regen_s, config.stamina_exhausted_ratio)
	survival = SurvivalLogic.new(config.food_empty_s, config.water_empty_s, config.starving_penalty_max, config.starving_penalty_time_s)
	pickups = []
	stations = []
	play_time_s = 0.0
	_autosave_timer = 0.0
	_next_id = 1
	_deliveries_count = 0
	game_reset.emit()


func _process(delta: float) -> void:
	# Chronomètre de partie : ne tourne que quand le jeu n'est pas en pause (PRD §11).
	play_time_s += delta
	if day.step(delta):
		_morning_refill()
		new_morning.emit()
	var multiplier := day.evaporation_multiplier(config.night_evaporation_factor)
	for zone in zones:
		(zone.logic as DryingLogic).step(delta, multiplier, rng)
	for st in stations:
		(st.logic as StationLogic).step(delta)
	survival.step(delta)
	stamina.set_max(survival.stamina_cap())
	_autosave_timer += delta
	if _autosave_timer >= config.autosave_interval_s:
		_autosave_timer = 0.0
		save_game()


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
func add_carried(items: Dictionary) -> Dictionary:
	var leftover := {}
	for k in items:
		var key := String(k)
		var n := int(items[k])
		var take := mini(n, carry_space())
		if take > 0:
			carried[key] = int(carried.get(key, 0)) + take
		if n - take > 0:
			leftover[key] = n - take
	carried_changed.emit()
	return leftover


## Récolte le dépôt d'une zone (M-39) : quelques unités par clic à la main, tout d'un coup
## avec le râteau. Ce qu'on ne peut pas porter reste dans la zone.
func harvest(zone: Dictionary) -> void:
	var logic: DryingLogic = zone.logic
	var n := carry_space() if has_rake else mini(config.manual_harvest_per_click, carry_space())
	var leftover := add_carried(logic.take_some(n))
	Economy.add(logic.deposit, leftover)


## Pose tout ce qu'on porte sur la palette : ça devient le stock utilisable pour payer.
func unload_to_stock() -> int:
	var n := carried_count()
	Economy.add(stock, carried)
	carried = {}
	carried_changed.emit()
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
		_:
			push_error("Type de zone inconnu : %s" % kind)
			return {}
	logic.liters_per_salt = config.liters_per_salt
	logic.mineral_chance = config.mineral_chance
	logic.rare_mineral_chance = config.rare_mineral_chance
	var zone := {"id": _new_id("zone"), "kind": kind, "position": position, "logic": logic}
	zones.append(zone)
	zone_added.emit(zone)
	return zone


# --- Catalogue et livraison ----------------------------------------------------------------

func cart_price(item_ids: Array) -> Dictionary:
	var prices := []
	for id in item_ids:
		var item := catalog.find(StringName(id))
		if item:
			prices.append(item.price)
	return Economy.sum(prices)


## Tout ce qui peut servir à payer : la palette plus ce qu'on a dans les bras.
func available_resources() -> Dictionary:
	return Economy.sum([stock, carried])


func can_buy(item: CatalogItem) -> bool:
	return not (item.unique and owned.has(String(item.id)))


## Passe commande : paie avec les bras puis la palette, et crée la caisse qui sera larguée.
## Renvoie la caisse, ou un dictionnaire vide si le stock ne suffit pas.
func order(item_ids: Array) -> Dictionary:
	if item_ids.is_empty():
		return {}
	for id in item_ids:
		var item := catalog.find(StringName(id))
		if item == null or not can_buy(item):
			return {}
	# On paie avec ce qu'on porte d'abord, puis avec la palette (retour d'Othmane).
	var price := cart_price(item_ids)
	if not Economy.pay_from([carried, stock], price):
		return {}
	for k in carried.keys():
		if int(carried[k]) <= 0:
			carried.erase(k)
	carried_changed.emit()
	for id in item_ids:
		var item := catalog.find(StringName(id))
		if item.unique:
			owned[String(item.id)] = true
	var crate := {"id": _new_id("crate"), "position": next_drop_position(), "items": item_ids.map(func(i): return String(i))}
	crates.append(crate)
	_deliveries_count += 1
	stock_changed.emit()
	crate_added.emit(crate, true)
	return crate


## Points de largage en spirale autour du centre, pour que les caisses (et les bâches posées
## à leur place) ne tombent pas toutes au même endroit.
func next_drop_position() -> Vector3:
	var i := _deliveries_count
	var angle := deg_to_rad(137.5 * i)
	var radius := 1.5 * sqrt(float(i))
	return config.delivery_center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


## Ouvre une caisse : applique l'effet de chaque objet à l'endroit de la caisse.
func open_crate(crate: Dictionary) -> void:
	if not crates.has(crate):
		return
	crates.erase(crate)
	var offset := 0
	for id in crate.items:
		var item := catalog.find(StringName(id))
		if item:
			apply_item(item, crate.position + Vector3(offset * 2.5, 0, 0))
			offset += 1
	crate_removed.emit(crate)


func apply_item(item: CatalogItem, position: Vector3) -> void:
	match item.effect:
		CatalogItem.Effect.DRYING_ZONE:
			add_zone(item.effect_param, position)
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
		CatalogItem.Effect.STATION:
			add_station(item.effect_param, position)
		CatalogItem.Effect.DECOR:
			var d := {"kind": item.effect_param, "position": position}
			decor.append(d)
			decor_added.emit(d)


## Contenance totale = un seau × nombre de seaux (la palanche en porte deux).
func _refresh_bucket() -> void:
	bucket.capacity_l = bucket_unit_l * bucket_count
	bucket_changed.emit()


# --- Survie légère et plage (N-02, N-03, M-44) ------------------------------------------

## Chaque matin : une noix de coco revient sous chaque palmier qui n'en a plus, et la plage
## reçoit de nouveaux coquillages (on complète jusqu'à `shells_per_morning`).
func _morning_refill() -> void:
	for spot in config.coconut_spots:
		if not _has_pickup_at("coconut", spot):
			add_pickup("coconut", spot)
	var shells := pickups.filter(func(p): return p.kind == "shell").size()
	for i in maxi(config.shells_per_morning - shells, 0):
		add_pickup("shell", _random_beach_spot())


func _random_beach_spot() -> Vector3:
	var angle := rng.randf() * TAU
	var radius := rng.randf_range(config.beach_radius_min, config.beach_radius_max)
	return Vector3(cos(angle) * radius, 0.52, sin(angle) * radius)


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
			if carry_space() <= 0:
				return false
			var found := {"coquillages": 1}
			if rng.randf() < config.pearl_chance_per_shell:
				found["perles"] = 1
			add_carried(found)
	pickups.erase(p)
	pickup_removed.emit(p)
	return true


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


# --- Niveau de l'eau -----------------------------------------------------------------------

## Hauteur réelle (honnête) de la surface de l'océan, en mètres.
func water_level_y() -> float:
	return config.sea_level_y - ocean.level_drop_m(config.ocean_surface_m2)


# --- Sauvegarde ----------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"ocean": ocean.to_dict(),
		"bucket": bucket.to_dict(),
		"day": day.to_dict(),
		"stock": stock.duplicate(),
		"carried": carried.duplicate(),
		"zones": zones.map(func(z): return {"kind": z.kind, "position": _v2a(z.position), "logic": (z.logic as DryingLogic).to_dict()}),
		"crates": crates.map(func(c): return {"position": _v2a(c.position), "items": c.items.duplicate()}),
		"decor": decor.map(func(d): return {"kind": d.kind, "position": _v2a(d.position)}),
		"owned": owned.duplicate(),
		"survival": survival.to_dict(),
		"pickups": pickups.map(func(p): return {"kind": p.kind, "position": _v2a(p.position)}),
		"stations": stations.map(func(st): return {"kind": st.kind, "position": _v2a(st.position), "logic": (st.logic as StationLogic).to_dict()}),
		"upgrades": {"bucket_unit_l": bucket_unit_l, "bucket_count": bucket_count, "carry_capacity": carry_capacity, "speed_multiplier": speed_multiplier, "has_rake": has_rake},
		"deliveries_count": _deliveries_count,
		"play_time_s": play_time_s,
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
	bucket.capacity_l = bucket_unit_l * bucket_count
	bucket.load_dict(data.get("bucket", {}))
	bucket.capacity_l = bucket_unit_l * bucket_count
	bucket.water_l = minf(bucket.water_l, bucket.capacity_l)
	day.load_dict(data.get("day", {}))
	stock = Economy.empty_stock()
	Economy.add(stock, Economy.sanitize(data.get("stock", {})))
	carried = Economy.sanitize(data.get("carried", {}))
	for z in data.get("zones", []):
		var zone := add_zone(String(z.get("kind", "")), _a2v(z.get("position", [])))
		if not zone.is_empty():
			(zone.logic as DryingLogic).load_dict(z.get("logic", {}))
	if zones.is_empty():
		add_zone("cuvette", config.basin_position)
	for c in data.get("crates", []):
		var crate := {"id": _new_id("crate"), "position": _a2v(c.get("position", [])), "items": Array(c.get("items", [])).map(func(i): return String(i))}
		crates.append(crate)
		crate_added.emit(crate, false)
	for d in data.get("decor", []):
		var dec := {"kind": String(d.get("kind", "")), "position": _a2v(d.get("position", []))}
		decor.append(dec)
		decor_added.emit(dec)
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
	owned = data.get("owned", {}).duplicate()
	_deliveries_count = int(data.get("deliveries_count", 0))
	play_time_s = float(data.get("play_time_s", 0.0))
	_emit_all()


func save_game() -> Error:
	return SaveSystem.write(current_slot, to_dict())


func load_game(slot: int) -> bool:
	var data := SaveSystem.read(slot)
	if data.is_empty():
		return false
	current_slot = slot
	load_dict(data)
	return true


## En attendant le menu principal (M-71) : on reprend l'emplacement 1 s'il existe.
func continue_or_new() -> void:
	if not load_game(current_slot):
		new_game()


func _notification(what: int) -> void:
	# Sauvegarde en quittant (M-77).
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


# --- Outils internes -----------------------------------------------------------------------

func _emit_all() -> void:
	survival_changed.emit()
	ocean_changed.emit()
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
