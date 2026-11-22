extends TestCase
## 0.1.21 : la nuit et la collection (hamac, vitrine, masque, récif, poissons). PRD §19.28.

const GameStateScript := preload("res://core/game_state.gd")
const NightLife := preload("res://scenes/world/night_life.gd")

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


func _buy(id: String) -> void:
	gs.apply_item(gs.catalog.find(StringName(id)), Vector3.ZERO)


func test_sleep_refused_by_day() -> void:
	_set_hour(12.0)
	assert_false(gs.sleep(), "pas de sieste en plein jour")
	assert_almost(gs.day.hour(), 12.0, 1e-3, "l'heure n'a pas bougé")


func test_sleep_jumps_to_morning() -> void:
	_set_hour(22.0)
	var day_before: int = gs.day.day_index
	assert_true(gs.sleep(), "on dort la nuit")
	assert_almost(gs.day.hour(), gs.config.wake_hour, 0.05, "réveil au matin")
	assert_eq(gs.day.day_index, day_before + 1, "c'est un nouveau jour")


func test_sleep_after_midnight() -> void:
	_set_hour(2.0)
	var day_before: int = gs.day.day_index
	assert_true(gs.sleep())
	assert_almost(gs.day.hour(), gs.config.wake_hour, 0.05)
	assert_eq(gs.day.day_index, day_before + 1)


func test_sleep_does_not_count_on_the_chrono() -> void:
	_set_hour(22.0)
	var before: float = gs.play_time_s
	gs.sleep()
	assert_almost(gs.play_time_s, before, 1e-6, "le chrono ne compte que le temps réel (Q-30)")


func test_sleep_lets_things_dry() -> void:
	_set_hour(21.0)
	var zone: Dictionary = gs.zones[0]
	(zone.logic as DryingLogic).water_l = 10.0
	gs.sleep()
	assert_true((zone.logic as DryingLogic).water_l < 10.0, "la nuit sèche (lentement)")


func test_sleep_emits_spot() -> void:
	_set_hour(23.0)
	var got := []
	gs.slept.connect(func(p: Vector3) -> void: got.append(p))
	gs.sleep(Vector3(1, 2, 3))
	assert_eq(got.size(), 1)
	assert_eq(got[0], Vector3(1, 2, 3))


func test_mask_makes_swimming_cheaper() -> void:
	var base: float = gs.stamina.swim_s
	assert_false(gs.has_gear("masque"))
	_buy("masque")
	assert_true(gs.has_gear("masque"))
	assert_almost(gs.stamina.swim_s, base / gs.config.mask_swim_cost, 1e-4, "on nage plus longtemps")


func test_collection_rows_come_from_data() -> void:
	assert_true(gs.collection_rows.size() >= 3, "trois rangées au moins")
	var slots: Array[String] = gs.collection_slots()
	for shape in gs.config.shell_shapes:
		assert_true(slots.has(String(shape)), "la forme %s a sa case" % shape)
	assert_true(slots.has("perle"))
	assert_eq(gs.collection_found_count(), 0)


func test_every_slot_has_a_name() -> void:
	for id in gs.collection_slots():
		var m: Node3D = Finds.model(id) if not id in ["poisson_clown", "chirurgien_bleu", "poisson_perroquet", "raie"] else Finds.fish(id)
		assert_true(m != null and m.get_child_count() > 0, "%s : un modèle" % id)
		if m:
			m.free()


func test_shell_goes_into_collection() -> void:
	gs.rng.seed = 7
	gs._gain_shell()
	assert_eq(int(gs.carried.get("coquillages", 0)), 1)
	assert_eq(gs.collection_found_count() >= 1, true, "une forme trouvée")
	var shapes := 0
	for k in gs.collection:
		if gs.config.shell_shapes.has(k):
			shapes += 1
	assert_eq(shapes, 1)


func test_shell_shapes_all_reachable() -> void:
	gs.rng.seed = 1
	var seen := {}
	for i in 400:
		seen[gs._pick_weighted(gs.config.shell_shapes, "?")] = true
	for shape in gs.config.shell_shapes:
		assert_true(seen.has(shape), "%s finit par sortir" % shape)


func test_reef_refills_each_morning() -> void:
	gs.reef_shells.clear()
	_set_hour(5.9)
	gs.advance_time(0.2 / 24.0 * gs.day.day_length_s)
	assert_true(gs.reef_shells.size() > 0, "des coquillages au récif ce matin")
	for p: Vector3 in gs.reef_shells:
		var depth: float = gs.config.sea_level_y - p.y
		assert_true(depth >= gs.config.reef_min_depth_m - 1e-3 and depth <= gs.config.reef_max_depth_m + 1e-3, "profondeur %f" % depth)


func test_reef_spot_is_underwater() -> void:
	var g := RandomNumberGenerator.new()
	g.seed = 3
	var p: Vector3 = gs.random_reef_spot(g)
	assert_true(p != gs.FAR_AWAY, "le récif existe")
	assert_true(p.y < gs.config.sea_level_y - gs.config.reef_min_depth_m + 1e-3)


func test_take_reef_shell() -> void:
	gs.reef_shells.assign([Vector3(30, -3, 0), Vector3(-30, -3, 0)])
	assert_false(gs.take_reef_shell(5), "pas de coquillage n° 5")
	assert_true(gs.take_reef_shell(0))
	assert_eq(gs.reef_shells.size(), 1)
	assert_eq(int(gs.carried.get("coquillages", 0)), 1)


func test_fish_needs_the_mask() -> void:
	assert_false(gs.see_fish("raie"), "sans masque, on ne voit rien")
	_buy("masque")
	assert_true(gs.see_fish("raie"))
	assert_false(gs.see_fish("raie"), "une seule fois")
	assert_true(gs.has_found("raie"))


func test_save_and_load_keeps_night_stuff() -> void:
	_buy("masque")
	gs.see_fish("poisson_clown")
	gs.reef_shells.assign([Vector3(20, -3, 4)])
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e12
	other.setup(cfg)
	other.load_dict(data)
	assert_true(other.has_gear("masque"))
	assert_almost(other.stamina.swim_s, gs.stamina.swim_s, 1e-4)
	assert_true(other.has_found("poisson_clown"))
	assert_eq(other.reef_shells.size(), 1)
	assert_almost((other.reef_shells[0] as Vector3).x, 20.0, 1e-4)
	other.free()


func test_night_amount() -> void:
	assert_almost(NightLife.night_amount(12.0), 0.0, 1e-6)
	assert_almost(NightLife.night_amount(23.0), 1.0, 1e-6)
	assert_almost(NightLife.night_amount(2.0), 1.0, 1e-6)
	assert_almost(NightLife.night_amount(20.5), 0.5, 1e-6)
	assert_almost(NightLife.night_amount(5.5), 0.5, 1e-6)


func test_catalog_has_night_items() -> void:
	for id in ["hamac", "vitrine", "masque"]:
		var item: CatalogItem = gs.catalog.find(StringName(id))
		assert_true(item != null, id)
		assert_true(item.unique, "%s : unique" % id)
	assert_eq(gs.catalog.find(&"masque").effect, CatalogItem.Effect.GEAR)


func test_hammock_and_shelf_are_decor() -> void:
	_buy("hamac")
	_buy("vitrine")
	var kinds: Array = gs.decor.map(func(d: Dictionary) -> String: return d.kind)
	assert_true(kinds.has("hamac"))
	assert_true(kinds.has("vitrine"))


func test_shelf_slots_fit_the_shelf() -> void:
	var cols := 5
	var rows := 3
	for r in rows:
		for c in cols:
			var p := IslandLife.shelf_slot(c, r, cols, rows)
			assert_true(absf(p.x) < (cols * IslandLife.SHELF_SLOT_W + 0.12) / 2.0, "case %d,%d" % [c, r])
