extends TestCase
## 0.1.22 : le temps qu'il fait, la fleur de sel, le sel rose, les commandes de l'agence. PRD §19.29.

const GameStateScript := preload("res://core/game_state.gd")
const DryingZoneView := preload("res://scenes/world/drying_zone_view.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e12
	gs.setup(cfg)


func after_each() -> void:
	gs.free()


func _set_hour(h: float) -> void:
	gs.day.time_s = h / 24.0 * gs.day.day_length_s


func _zone() -> Dictionary:
	return gs.zones[0]


## Fait sécher `liters` litres dans la cuvette de départ, et renvoie le dépôt.
func _dry(liters: float) -> Dictionary:
	var logic: DryingLogic = _zone().logic
	logic.capacity_l = maxf(logic.capacity_l, liters)
	logic.water_l = liters
	for i in 4000:
		gs.simulate(0.5)
		if logic.water_l <= 0.0:
			break
	return logic.deposit


# --- Le temps ---------------------------------------------------------------------------------

func test_weather_table_and_defaults() -> void:
	assert_eq(gs.weather, "calme", "une partie commence par temps calme")
	for id in ["calme", "venteux", "canicule", "couvert", "averse"]:
		assert_true(gs.config.weather_table.has(id), id)
		assert_true(gs.config.weather_order.has(id), "%s sur le baromètre" % id)
	assert_almost(WeatherLogic.value(gs.config.weather_table, "canicule", "dry"), 1.6, 1e-6)
	assert_almost(WeatherLogic.value(gs.config.weather_table, "inconnu", "dry"), 1.0, 1e-6, "multiplicateur neutre")
	assert_almost(WeatherLogic.value(gs.config.weather_table, "inconnu", "wind"), 0.0, 1e-6)


func test_pick_follows_the_weights() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var seen := {}
	for i in 4000:
		var w := WeatherLogic.pick(gs.config.weather_table, rng)
		seen[w] = int(seen.get(w, 0)) + 1
	for id in gs.config.weather_table:
		var expected: float = gs.config.weather_table[id].weight / 100.0
		assert_almost(seen.get(id, 0) / 4000.0, expected, 0.03, id)


func test_new_weather_each_morning() -> void:
	gs.rng.seed = 5
	var got := {}
	for d in 30:
		_set_hour(5.9)
		gs.simulate(0.2 / 24.0 * gs.day.day_length_s)
		got[gs.weather] = true
	assert_true(got.size() >= 3, "le temps change d'un jour à l'autre (%s)" % [got.keys()])


func test_weather_changes_drying() -> void:
	_set_hour(12.0)
	gs.set_weather("canicule")
	var logic: DryingLogic = _zone().logic
	logic.water_l = 20.0
	gs.simulate(2.0)
	var hot: float = 20.0 - logic.water_l
	gs.set_weather("couvert")
	logic.water_l = 20.0
	gs.simulate(2.0)
	var grey: float = 20.0 - logic.water_l
	assert_almost(hot / grey, 1.6 / 0.7, 0.05, "la canicule sèche plus vite que le temps couvert")


func test_heatwave_makes_you_thirsty_faster() -> void:
	gs.set_weather("canicule")
	gs.survival.water = 1.0
	gs.survival.step(60.0)
	var hot: float = 1.0 - gs.survival.water
	gs.set_weather("calme")
	gs.survival.water = 1.0
	gs.survival.step(60.0)
	var calm: float = 1.0 - gs.survival.water
	assert_almost(hot / calm, 1.5, 1e-3)


func test_weather_saved() -> void:
	gs.set_weather("averse")
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.set_weather("calme")
	gs.load_dict(data)
	assert_eq(gs.weather, "averse")
	data.weather = "tempête"
	gs.load_dict(data)
	assert_eq(gs.weather, "calme", "un temps inconnu redevient calme")


# --- Fleur de sel -----------------------------------------------------------------------------

func test_flower_only_on_calm_days() -> void:
	gs.config.flower_chance_per_salt = 1.0
	_set_hour(9.0)
	gs.set_weather("venteux")
	assert_eq(int(_dry(20.0).get("fleur_de_sel", 0)), 0, "pas de fleur par vent")
	_zone().logic.deposit = {}
	gs.set_weather("calme")
	var dep := _dry(20.0)
	assert_eq(int(dep.get("fleur_de_sel", 0)), int(dep.get("sel", 0)), "une fleur par sel (chance 1)")


func test_flower_not_at_night() -> void:
	gs.config.flower_chance_per_salt = 1.0
	gs.config.night_evaporation_factor = 1.0
	_set_hour(22.0)
	gs.set_weather("calme")
	var logic: DryingLogic = _zone().logic
	logic.water_l = 8.0
	gs.simulate(5.0)
	assert_eq(int(logic.deposit.get("fleur_de_sel", 0)), 0)


func test_flower_needs_the_lousse() -> void:
	_zone().logic.deposit = {"fleur_de_sel": 3, "sel": 2}
	assert_false(gs.harvest_flower(_zone()), "sans lousse")
	gs.harvest(_zone())  # E sur un tas : jamais la fleur de sel
	assert_eq(int(gs.carried.get("fleur_de_sel", 0)), 0)
	assert_eq(int(_zone().logic.deposit.get("fleur_de_sel", 0)), 3)
	gs.apply_item(gs.catalog.find(&"lousse"), Vector3.ZERO)
	assert_true(gs.has_gear("lousse"))
	assert_true(gs.harvest_flower(_zone()))
	assert_true(int(gs.carried.get("fleur_de_sel", 0)) > 0)


func test_flower_prompt() -> void:
	_zone().logic.deposit = {"fleur_de_sel": 2}
	# La vue lit l'autoload ; ici on vérifie seulement qu'aucune fleur = aucun texte.
	var z := {"logic": DryingLogic.new()}
	assert_eq(DryingZoneView.flower_prompt(z), "")


func test_flakes_count() -> void:
	assert_eq(FlowerFlakes.visible_flakes(0), 0)
	assert_eq(FlowerFlakes.visible_flakes(3), 3)
	assert_eq(FlowerFlakes.visible_flakes(500), FlowerFlakes.MAX_FLAKES)


# --- Sel rose et ressources « trouvées seulement » --------------------------------------------

func test_rose_salt_replaces_white_salt() -> void:
	var logic := DryingLogic.new(40.0, 10.0)
	logic.liters_per_salt = 1.0
	logic.rose_chance = 1.0
	logic.water_l = 20.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	logic.step(100.0, 1.0, rng)
	assert_eq(int(logic.deposit.get("sel", 0)), 0)
	assert_eq(int(logic.deposit.get("sel_rose", 0)), 20)


func test_rose_share() -> void:
	var logic := DryingLogic.new(4000.0, 10.0)
	logic.liters_per_salt = 1.0
	logic.rose_chance = 0.3
	logic.water_l = 2000.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	logic.step(100.0, 1.0, rng)
	var share := float(logic.deposit.get("sel_rose", 0)) / 2000.0
	assert_almost(share, 0.3, 0.04)


func test_marsh_pile_keys() -> void:
	assert_false(gs.marsh_pile_keys({}).has("sel_rose"))
	assert_true(gs.marsh_pile_keys({"rose": true}).has("sel_rose"))


func test_found_only_resources_are_hidden_first() -> void:
	assert_false(gs.is_known("fleur_de_sel"))
	assert_false(gs.is_known("sel_rose"))
	assert_true(gs.is_known("sel"))
	assert_false(gs.known_resources().has("sel_rose"))
	assert_false(CatalogueFormat.format_items({}, true).contains("rose"), "pas de « 0 sel rose »")
	var got := []
	gs.resources_discovered.connect(func() -> void: got.append(1))
	gs.add_carried({"sel_rose": 2})
	assert_true(gs.is_known("sel_rose"))
	assert_eq(got.size(), 1)
	assert_true(gs.known_resources().has("sel_rose"))
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.new_game()
	assert_false(gs.is_known("sel_rose"), "nouvelle partie : caché de nouveau")
	gs.load_dict(data)
	assert_true(gs.is_known("sel_rose"), "sauvegardé")


func test_drying_discovers() -> void:
	gs.config.flower_chance_per_salt = 1.0
	_set_hour(10.0)
	gs.set_weather("calme")
	_dry(8.0)
	assert_true(gs.is_known("fleur_de_sel"))


# --- Catalogue chic et commandes --------------------------------------------------------------

func test_chic_items() -> void:
	assert_eq(gs.catalog.find(&"lousse").effect, CatalogItem.Effect.GEAR)
	assert_eq(int(gs.catalog.find(&"flamant_sel").price.get("sel_rose", 0)), 20)
	assert_eq(int(gs.catalog.find(&"parasol").price.get("fleur_de_sel", 0)), 8)
	var sal: CatalogItem = gs.catalog.find(&"saliere")
	assert_eq(int(sal.price.get("fleur_de_sel", 0)), 10)
	assert_eq(int(sal.price.get("sel_rose", 0)), 10)


func test_gift_contents() -> void:
	var lot: Dictionary = GameStateScript.gift_contents("mineraux_rares=3, perles=1,licorne=4")
	assert_eq(lot, {"mineraux_rares": 3, "perles": 1})


func test_orders_data() -> void:
	assert_true(gs.agency_orders.size() >= 5)
	for o in gs.agency_orders:
		var item: CatalogItem = gs.catalog.find(StringName(o.surprise))
		assert_true(item != null, "surprise %s" % o.surprise)
		assert_true(item.hidden, "%s : pas au catalogue" % o.surprise)
		for k in o.price:
			assert_true(Economy.RESOURCES.has(String(k)), "%s : %s" % [o.id, k])


func test_first_order_and_candidates() -> void:
	assert_eq(gs.agency_order.get("id", ""), "o_sel", "la plus simple d'abord")
	assert_false(gs.agency_order_candidates().has("o_rose"), "pas de sel rose avant d'en avoir trouvé")
	gs.add_carried({"sel_rose": 1})
	assert_true(gs.agency_order_candidates().has("o_rose"))


func test_send_order() -> void:
	assert_false(gs.can_send_agency_order(), "pas de quoi payer")
	assert_true(gs.send_agency_order().is_empty())
	gs.stock = {"sel": 100, "mineraux": 10}
	assert_true(gs.can_send_agency_order())
	var before: int = gs.crates.size()
	var crate: Dictionary = gs.send_agency_order()
	assert_false(crate.is_empty())
	assert_eq(gs.crates.size(), before + 1)
	assert_eq(crate.items, ["surprise_rares"])
	assert_eq(crate.paid, {"sel": 40, "mineraux": 5}, "l'avion emporte le paiement")
	assert_eq(int(gs.stock.sel), 60)
	assert_true(gs.agency_order.sent)
	assert_false(gs.can_send_agency_order(), "une seule fois")
	gs.open_crate(crate)
	assert_eq(int(gs.stock.get("mineraux_rares", 0)), 3, "la surprise arrive sur la palette")
	assert_eq(int(gs.stock.get("perles", 0)), 1)


func test_new_order_next_morning() -> void:
	gs.stock = {"sel": 100, "mineraux": 10}
	gs.send_agency_order()
	_set_hour(5.9)
	gs.simulate(0.2 / 24.0 * gs.day.day_length_s)
	assert_false(gs.agency_order.sent, "nouvelle commande")
	assert_true(gs.agency_order.id != "o_sel", "jamais la même deux fois de suite")


func test_unsent_order_stays() -> void:
	_set_hour(5.9)
	gs.simulate(0.2 / 24.0 * gs.day.day_length_s)
	assert_eq(gs.agency_order.id, "o_sel", "une commande non envoyée reste affichée")


func test_order_saved() -> void:
	gs.stock = {"sel": 100, "mineraux": 10}
	gs.send_agency_order()
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.new_game()
	gs.load_dict(data)
	assert_eq(gs.agency_order.id, "o_sel")
	assert_true(gs.agency_order.sent)


func test_surprise_decor() -> void:
	var d: Dictionary = gs.apply_item(gs.catalog.find(&"surprise_bouee"), Vector3(-6, 0.5, 6))
	assert_eq(d.kind, "bouee_canard")


# --- Ce qu'on voit -----------------------------------------------------------------------------

func test_view_helpers() -> void:
	assert_almost(WeatherView.wave_factor(0.0), 1.0, 1e-6)
	assert_true(WeatherView.wave_factor(1.0) > 1.5, "plus de vagues par vent")
	assert_almost(WeatherView.palm_bend(0.0, 3.0, 1), 0.0, 1e-6, "pas de vent, pas de ploiement")
	assert_true(absf(WeatherView.palm_bend(1.0, 3.0, 1)) > 0.01)
	var last := -10.0
	for i in 5:
		var a := SaltGoods.barometer_angle(i, 5)
		assert_true(a > last, "le baromètre tourne dans l'ordre")
		assert_true(absf(a) < PI / 2 + 0.3)
		last = a
