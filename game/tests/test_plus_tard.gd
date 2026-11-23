extends TestCase
## 0.1.25 : plus tard (châteaux de sable, orage au large, baleine et dauphins, succès à l'œil,
## carte de l'île, manette). PRD §19.32.

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e12
	gs.setup(cfg)


func after_each() -> void:
	gs.free()


func _noon() -> void:
	gs.day.time_s = 12.0 / 24.0 * gs.day.day_length_s


## Un point de sable plat, sec et libre (cherché sur la plage, du côté sud).
func _sand_spot() -> Vector3:
	gs.day.time_s = gs.config.tide_high_hour / 24.0 * gs.day.day_length_s  # marée haute : le pire cas
	for r in range(12, 40):
		for k in 24:
			var a := TAU * k / 24.0
			var p := Vector3(cos(a) * r * 0.9, 0.0, sin(a) * r * 0.9)
			p.y = gs.terrain.height(p.x, p.z)
			if gs.castle_reason(p) == "":
				return p
	return Vector3.INF


# --- Châteaux de sable --------------------------------------------------------------------

func test_castle_rules_live_in_the_data() -> void:
	assert_eq(gs.config.castle_max, 40)
	assert_eq(gs.config.castle_max_floors, 3)


func test_build_a_tower_then_add_floors_up_to_three() -> void:
	var p := _sand_spot()
	assert_true(p.is_finite(), "il y a du sable plat sur l'île")
	var c: Dictionary = gs.build_castle(p)
	assert_eq(int(c.floors), 1)
	assert_eq(gs.castles.size(), 1)
	gs.build_castle(p + Vector3(0.1, 0, 0))
	gs.build_castle(p)
	assert_eq(int(c.floors), 3, "trois étages")
	assert_eq(gs.castle_reason(p), "PROMPT_CASTLE_TOP")
	assert_true(gs.build_castle(p).is_empty())
	assert_eq(gs.castles.size(), 1, "toujours une seule tour")


func test_no_tower_on_earth_in_the_sea_or_over_the_limit() -> void:
	var earth := Vector3.INF
	for i in range(-30, 31):
		for j in range(-30, 31):
			if earth.is_finite():
				break
			if gs.terrain.height(i, j) > 0.3 and gs.terrain.soil(TerrainLogic.nearest_vertex(i, j)) == TerrainLogic.Soil.EARTH:
				earth = Vector3(i, 0, j)
	assert_true(earth.is_finite())
	assert_eq(gs.castle_reason(earth), "PROMPT_CASTLE_SAND", "pas sur la terre")
	assert_eq(gs.castle_reason(Vector3(80, 0, 0)), "PROMPT_CASTLE_SAND" if gs.terrain.soil(TerrainLogic.nearest_vertex(80, 0)) != TerrainLogic.Soil.SAND else "PROMPT_CASTLE_WET")
	var p := _sand_spot()
	gs.config.castle_max = 1
	gs.build_castle(p)
	assert_eq(gs.castle_reason(p + Vector3(3, 0, 0)), "PROMPT_CASTLE_LIMIT")


func test_the_tide_washes_low_towers_away() -> void:
	var p := _sand_spot()
	var c: Dictionary = gs.build_castle(p)
	assert_false(c.is_empty())
	gs.simulate(0.1)
	assert_eq(gs.castles.size(), 1, "au-dessus de la mer, elle tient")
	c.position.y = gs.water_level_y() - 0.05  # comme si la marée montait plus haut qu'elle
	gs.terrain.set_cell(TerrainLogic.cell_of(p.x, p.z), gs.water_level_y() - 0.05)
	gs.simulate(0.1)
	assert_eq(gs.castles.size(), 0, "la marée l'a effacée")


func test_castles_are_pure_play_and_saved() -> void:
	var p := _sand_spot()
	var stock_before: Dictionary = gs.stock.duplicate()
	gs.build_castle(p)
	gs.build_castle(p)
	assert_eq(gs.stock, stock_before, "aucun rendement")
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.castles.clear()
	gs.load_dict(data)
	assert_eq(gs.castles.size(), 1)
	assert_eq(int(gs.castles[0].floors), 2)


func test_a_tower_blocks_placement() -> void:
	var p := _sand_spot()
	gs.build_castle(p)
	assert_false(PlacementGrid.is_valid(PlacementGrid.circle_shape(p, 0.2), gs._blockers_except({}), INF))


# --- Orage au large ------------------------------------------------------------------------

func test_storm_is_a_rare_sixth_weather() -> void:
	var t: Dictionary = gs.config.weather_table
	assert_eq(t.size(), 6)
	var total := 0.0
	for k in t:
		total += float(t[k].weight)
	assert_almost(float(t["orage"].weight) / total, 0.05, 1e-6, "5 %")
	assert_almost(gs.config.weather_table["orage"].dry, 0.8, 1e-6)
	assert_true(gs.config.weather_order.has("orage"))
	gs.set_weather("orage")
	assert_almost(gs.weather_value("waves"), 2.0, 1e-6, "vagues deux fois plus hautes")
	assert_almost(gs.weather_value("storm"), 1.0, 1e-6)
	gs.set_weather("calme")
	assert_almost(gs.weather_value("waves"), 0.0, 1e-6, "pas d'orage, pas de vagues en plus")


func test_storm_sends_two_more_wrecks_next_morning() -> void:
	gs.config.wreck_hour_min = 23.0
	gs.config.wreck_hour_max = 23.5  # l'épave du jour plus tard : on ne compte que celles de l'orage
	gs.day.time_s = (DayCycleLogic.DAY_START_H - 0.1) / 24.0 * gs.day.day_length_s
	gs.set_weather("orage")
	var before: int = gs.wrecks.size()
	gs.simulate(0.2 / 24.0 * gs.day.day_length_s)
	assert_eq(gs.wrecks.size() - before, gs.config.storm_wrecks)


func test_no_storm_no_extra_wreck() -> void:
	gs.config.wreck_hour_min = 23.0
	gs.config.wreck_hour_max = 23.5
	gs.day.time_s = (DayCycleLogic.DAY_START_H - 0.1) / 24.0 * gs.day.day_length_s
	gs.set_weather("calme")
	var before: int = gs.wrecks.size()
	gs.simulate(0.2 / 24.0 * gs.day.day_length_s)
	assert_eq(gs.wrecks.size() - before, 0)


func test_thunder_comes_after_the_flash() -> void:
	assert_true(WeatherView.thunder_delay(170.0) > 0.0)
	assert_true(WeatherView.thunder_delay(1000.0) >= WeatherView.thunder_delay(170.0))


# --- Baleine et dauphins -------------------------------------------------------------------

func test_sea_life_appears_now_and_then_by_day() -> void:
	_noon()
	gs.sea_life_t = 1.0
	gs.simulate(0.5)
	assert_true(gs.sea_life.is_empty())
	gs.simulate(0.6)
	assert_false(gs.sea_life.is_empty(), "une apparition")
	var r: Array = gs.config.sea_life_distance_m[gs.sea_life.kind]
	var d: float = Vector2(gs.sea_life.position.x, gs.sea_life.position.z).length()
	assert_true(d >= float(r[0]) - 0.01 and d <= float(r[1]) + 0.01, "à sa distance")
	assert_true(gs.sea_life_t >= gs.config.sea_life_interval_s * 0.7 - 0.01, "la prochaine dans quelques minutes")
	gs.simulate(float(gs.sea_life.duration) + 0.1)
	assert_true(gs.sea_life.is_empty(), "elle repart")


func test_no_sea_life_at_night() -> void:
	gs.day.time_s = 1.0 / 24.0 * gs.day.day_length_s
	gs.sea_life_t = 0.1
	gs.simulate(0.2)
	assert_true(gs.sea_life.is_empty())


func test_seen_close_or_with_the_spyglass_goes_to_the_collection() -> void:
	gs.start_sea_life("dauphins")
	assert_false(gs.spot_sea_life(400.0, false), "trop loin à l'œil nu")
	assert_false(gs.has_found("dauphin"))
	assert_true(gs.spot_sea_life(200.0, false), "de près")
	assert_true(gs.has_found("dauphin"))
	gs.start_sea_life("baleine")
	assert_true(gs.spot_sea_life(1000.0, true), "à la longue-vue")
	assert_true(gs.has_found("baleine"))
	gs.start_sea_life("baleine")
	assert_false(gs.spot_sea_life(1000.0, true), "une seule fois dans la collection")


func test_sea_life_in_the_showcase() -> void:
	var slots: Array[String] = gs.collection_slots()
	assert_true(slots.has("baleine") and slots.has("dauphin"))


func test_sea_life_view_helpers() -> void:
	assert_true(SeaLifeView.in_view(Vector3.FORWARD, Vector3(0, 0, -100), 70.0))
	assert_false(SeaLifeView.in_view(Vector3.FORWARD, Vector3(0, 0, 100), 70.0))
	assert_true(SeaLifeView.dolphin_jump(SeaLifeView.JUMP_PERIOD * 0.225) > 1.0, "en haut du saut")
	assert_true(SeaLifeView.dolphin_jump(SeaLifeView.JUMP_PERIOD * 0.8) < 0.0, "sous l'eau entre deux sauts")
	assert_true(SeaLifeView.whale_rise(5.0, 14.0) > SeaLifeView.whale_rise(0.0, 14.0), "le dos affleure")


# --- Succès à l'œil -------------------------------------------------------------------------

func test_ten_trophies_in_order() -> void:
	assert_eq(gs.config.trophies.size(), 10)
	assert_true(gs.trophies.is_empty())
	gs.check_trophies()
	assert_true(gs.trophies.is_empty(), "rien de gagné au départ")


func test_first_purchase_and_salt_trophies() -> void:
	var won: Array = []
	gs.trophy_won.connect(func(id): won.append(id))
	gs.stock = {"sel": 500}
	gs.order(["seau_perce"])
	gs.check_trophies()
	assert_true(gs.trophies.has("premier_achat"))
	var z: Dictionary = gs.zones[0]
	(z.logic as DryingLogic).deposit = {"sel": 100}
	for i in 200:
		gs.harvest(z, "sel")
	assert_true(int(gs.stats.get("sel_harvested", 0)) > 0, "le sel récolté est compté")
	gs.stats.sel_harvested = 100
	gs.check_trophies()
	assert_true(gs.trophies.has("sel_100"))
	assert_eq(won.count("premier_achat"), 1, "une seule fois")


func test_trophies_from_the_game() -> void:
	gs.stats.slept = 1
	gs.stats.dug = 3
	gs.unlocked_tier = 2
	gs.ocean.removed_l = 1000.0
	gs.check_trophies()
	for id in ["hamac", "tresors_3", "palier_2", "litres_1000"]:
		assert_true(gs.trophies.has(id), id)
	assert_false(gs.trophies.has("collection"))


func test_sleeping_and_digging_are_counted() -> void:
	gs.day.time_s = 23.0 / 24.0 * gs.day.day_length_s
	assert_true(gs.sleep())
	assert_eq(int(gs.stats.slept), 1)
	gs.buried.clear()
	gs.buried.append({"kind": "ferraille", "position": Vector3(10, 0.5, 10)})
	gs._check_buried(Vector3(10, 0.5, 10))
	assert_eq(int(gs.stats.dug), 1)


func test_shell_row_and_whole_collection() -> void:
	for id in ["coq_petoncle", "coq_bigorneau", "coq_couteau", "coq_conque", "coq_nautile"]:
		gs.add_to_collection(id)
	gs.check_trophies()
	assert_true(gs.trophies.has("coquillages"))
	assert_false(gs.trophies.has("collection"))
	for id in gs.collection_slots():
		gs.add_to_collection(id)
	gs.check_trophies()
	assert_true(gs.trophies.has("collection"))


func test_trophies_saved() -> void:
	gs.stats.slept = 1
	gs.check_trophies()
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.trophies.clear()
	gs.stats.clear()
	gs.load_dict(data)
	assert_true(gs.trophies.has("hamac"))
	assert_eq(int(gs.stats.slept), 1)


func test_trophy_stand_blocks_placement_and_has_a_slot_per_trophy() -> void:
	var r: Rect2 = gs.trophy_stand_rect()
	var c := Vector3(r.get_center().x, 0.5, r.get_center().y)
	assert_false(PlacementGrid.is_valid(PlacementGrid.circle_shape(c, 0.2), gs._blockers_except({}), INF))
	var seen := {}
	for i in gs.config.trophies.size():
		var p := LaterGoods.slot_position(i, gs.config.trophies.size())
		assert_true(absf(p.x) < 0.95 and absf(p.z) < 0.35, "le plot %d est sur la dalle" % i)
		seen[p] = true
	assert_eq(seen.size(), gs.config.trophies.size(), "des plots tous différents")


# --- Carte et manette ----------------------------------------------------------------------

func test_map_key_and_projection() -> void:
	assert_true(InputMap.has_action(&"map"))
	var r: float = gs.config.map_radius_m
	assert_eq(IslandMap.world_to_map(Vector3.ZERO, r), Vector2(0.5, 0.5))
	assert_eq(IslandMap.world_to_map(Vector3(r, 0, -r), r), Vector2(1.0, 0.0), "l'est à droite, le nord en haut")
	var w := IslandMap.pixel_to_world(Vector2(0, 0), 100, r)
	assert_almost(w.x, -r, 1e-4)


func test_every_action_has_a_gamepad_button() -> void:
	var skip := ["tool_1", "tool_2", "tool_3", "tool_4", "tool_5", "tool_6"]  # la barre : gâchettes hautes
	for action: StringName in preload("res://core/input_setup.gd").KEY_BINDINGS:
		if skip.has(String(action)):
			continue
		var pad := false
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				pad = true
		assert_true(pad, "%s à la manette" % action)
	for action in [&"use_tool", &"use_tool_alt", &"tool_next", &"tool_prev", &"look_left", &"look_up"]:
		assert_true(InputMap.has_action(action), String(action))


func test_storm_and_new_sounds_exist() -> void:
	for name in ["thunder", "chime", "blow", "splash"]:
		var data := SoundSynth.samples(name)
		assert_true(data.size() > 0, name)
		assert_true(SoundSynth.peak(data) <= 1.0, name)
