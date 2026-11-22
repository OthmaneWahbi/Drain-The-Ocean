extends TestCase
## 0.1.23 : explorer et vivre sur l'île (marais en série, bouteilles, épaves, détecteur et trésor,
## tortues, feu de camp, cocotiers plantés, longue-vue, décor du campement). PRD §19.30.

const GameStateScript := preload("res://core/game_state.gd")
const SoundBoard := preload("res://scenes/audio/sound_board.gd")
const Player := preload("res://scenes/player/player.gd")

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


## Creuse un trou de w × h cases, son fond à `depth` m sous `ground` (le sol de référence).
func _dig(origin: Vector2i, w: int, h: int, depth: float, ground: float) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var corners := []
	for j in h:
		for i in w:
			var c := origin + Vector2i(i, j)
			cells.append(c)
			corners.append_array(gs.terrain.set_cell(c, ground - depth))
	gs.terrain_changed.emit(corners)
	return cells


## Le plus bas des sols d'origine autour des deux trous des tests de série.
func _ground() -> float:
	var g := INF
	for x in range(6, 12):
		for y in range(6, 8):
			g = minf(g, SaltMarsh.base_mean(gs.terrain, Vector2i(x, y)))
	return g


# --- Marais en série -----------------------------------------------------------------------

func test_marshes_two_cells_apart_are_linked_three_are_not() -> void:
	var a := {"cells": [Vector2i(0, 0)]}
	var b := {"cells": [Vector2i(3, 0)]}
	var c := {"cells": [Vector2i(4, 0)]}
	assert_true(gs.marshes_linked(a, b), "deux cases (un muret) entre les deux")
	assert_false(gs.marshes_linked(a, c), "trois cases")


func test_water_flows_down_the_series_and_the_last_marsh_gives_more_minerals() -> void:
	# Deux trous séparés par un muret de 2 cases ; le second est plus profond.
	var g := _ground()
	var high: Dictionary = gs.add_marsh(_dig(Vector2i(6, 6), 2, 2, 0.3, g))
	var low: Dictionary = gs.add_marsh(_dig(Vector2i(10, 6), 2, 2, 0.45, g))
	assert_eq(gs.marshes().size(), 2, "deux marais distincts (le muret tient)")
	assert_true(float(low.position.y) < float(high.position.y), "le second est plus bas")
	var targets: Dictionary = gs.marsh_flow_targets()
	assert_eq((targets[high.id] as Dictionary).get("id"), low.id)
	assert_true(gs.is_last_of_series(low, targets))
	assert_false(gs.is_last_of_series(high, targets))
	var hl: DryingLogic = high.logic
	hl.water_l = hl.capacity_l
	gs.simulate(1.0)
	assert_true((low.logic as DryingLogic).water_l > 0.0, "l'eau est descendue")
	assert_almost((low.logic as DryingLogic).mineral_chance, gs.config.mineral_chance * gs.config.marsh_last_mineral_mult, 1e-9)
	assert_almost(hl.mineral_chance, gs.config.mineral_chance, 1e-9)


func test_water_stops_flowing_at_half_full() -> void:
	var g := _ground()
	var high: Dictionary = gs.add_marsh(_dig(Vector2i(6, 6), 2, 2, 0.3, g))
	var low: Dictionary = gs.add_marsh(_dig(Vector2i(10, 6), 2, 2, 0.45, g))
	var hl: DryingLogic = high.logic
	hl.water_l = hl.capacity_l * 0.4
	gs.simulate(1.0)
	assert_almost((low.logic as DryingLogic).water_l, 0.0, 1e-9, "sous la moitié, rien ne descend")


# --- Bouteilles à la mer -------------------------------------------------------------------

func test_bottles_bring_each_drawing_once_then_random() -> void:
	var seen: Array[String] = []
	for i in gs.config.bottle_drawings.size():
		var d: String = gs.next_bottle_drawing()
		assert_false(seen.has(d), "pas deux fois le même tant qu'il en manque")
		seen.append(d)
		gs.add_to_collection("bouteille_" + d)
	assert_true(gs.config.bottle_drawings.has(gs.next_bottle_drawing()))


func test_opening_the_map_bottle_buries_the_treasure_once() -> void:
	var p: Dictionary = gs.add_pickup("bottle", Vector3(3, 0.5, 3))
	var drawn := []
	gs.bottle_opened.connect(func(d): drawn.append(d))
	assert_true(gs.take_pickup(p))
	assert_eq(drawn, ["carte"])
	assert_true(gs.has_found("bouteille_carte"))
	var treasures: Array = gs.buried.filter(func(b): return b.kind == "tresor")
	assert_eq(treasures.size(), 1)
	gs._open_bottle()
	gs.collection.erase("bouteille_carte")
	gs._open_bottle()
	assert_eq(gs.buried.filter(func(b): return b.kind == "tresor").size(), 1, "un seul trésor")


func test_treasure_spot_is_sand_you_can_dig() -> void:
	var t: Vector2 = gs.config.treasure_spot
	var v := TerrainLogic.nearest_vertex(t.x, t.y)
	assert_eq(gs.terrain.soil(v), TerrainLogic.Soil.SAND)
	assert_eq(gs.scoop_reason(v, true), "")


func test_digging_up_the_treasure_gives_pearls_and_the_chest() -> void:
	gs._open_bottle()
	var t: Vector2 = gs.config.treasure_spot
	var pearls := int(gs.carried.get("perles", 0)) + int(gs.stock.get("perles", 0))
	var found := []
	gs.dug_up.connect(func(k, _p): found.append(k))
	gs._check_buried(Vector3(t.x, 0, t.y))
	assert_true(found.has("tresor"))
	assert_true(gs.has_found("coffre"))
	assert_eq(int(gs.carried.get("perles", 0)) + int(gs.stock.get("perles", 0)), pearls + gs.config.treasure_pearls)


func test_morning_brings_a_bottle_sometimes() -> void:
	gs.config.bottle_chance_per_morning = 1.0
	var before: int = gs.pickups.filter(func(p): return p.kind == "bottle").size()
	gs._island_morning()
	assert_eq(gs.pickups.filter(func(p): return p.kind == "bottle").size(), before + 1)
	gs.config.bottle_chance_per_morning = 0.0
	gs._island_morning()
	assert_eq(gs.pickups.filter(func(p): return p.kind == "bottle").size(), before + 1)


# --- Épaves --------------------------------------------------------------------------------

func test_wreck_drifts_to_the_beach_then_opens_once() -> void:
	var w: Dictionary = gs.spawn_wreck()
	assert_false(w.is_empty())
	assert_false(w.landed)
	assert_true(gs.open_wreck(w).is_empty(), "pas d'ouverture tant qu'elle flotte")
	var start: Vector3 = w.position
	gs._run_wrecks(1.0)
	assert_true((w.position as Vector3).distance_to(w.target) < start.distance_to(w.target), "elle se rapproche")
	gs._run_wrecks(10000.0)
	assert_true(w.landed)
	var loot: Dictionary = gs.open_wreck(w)
	assert_true(int(loot.get("sel", 0)) >= 5)
	assert_false(gs.wrecks.has(w))
	assert_true(gs.open_wreck(w).is_empty())


func test_one_wreck_per_day_at_its_hour() -> void:
	gs._island_morning()
	var h: float = gs.wreck_hour
	assert_true(h >= gs.config.wreck_hour_min and h <= gs.config.wreck_hour_max)
	_set_hour(h + 0.1)
	gs._run_wrecks(0.01)
	assert_eq(gs.wrecks.size(), 1)
	gs._run_wrecks(0.01)
	assert_eq(gs.wrecks.size(), 1, "une seule par jour")


func test_wrecks_saved() -> void:
	var w: Dictionary = gs.spawn_wreck()
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.wrecks.clear()
	gs.load_dict(data)
	assert_eq(gs.wrecks.size(), 1)
	assert_almost((gs.wrecks[0].target as Vector3).distance_to(w.target), 0.0, 1e-3)


# --- Détecteur et objets enterrés ----------------------------------------------------------

func test_there_are_always_some_buried_things() -> void:
	assert_eq(gs.buried.size(), gs.config.buried_count)
	gs.buried.clear()
	gs._refill_buried()
	assert_eq(gs.buried.size(), gs.config.buried_count)


func test_detector_signal_grows_as_you_get_closer() -> void:
	gs.buried.clear()
	gs.buried.append({"kind": "ferraille", "position": Vector3(10, 0.5, 0)})
	assert_eq(gs.detector_signal(Vector3(30, 0, 0)), 0.0)
	var far: float = gs.detector_signal(Vector3(15, 0, 0))
	var near: float = gs.detector_signal(Vector3(11, 0, 0))
	assert_true(far > 0.0 and near > far)
	assert_almost(gs.detector_signal(Vector3(10, 0, 0)), 1.0, 1e-6)


func test_beep_gets_faster_with_the_signal() -> void:
	assert_true(SoundBoard.beep_interval(0.9) < SoundBoard.beep_interval(0.2))
	assert_almost(SoundBoard.beep_interval(1.0), 0.1, 1e-6)


func test_detector_is_a_tool_only_once_bought() -> void:
	assert_false(gs.owns_tool("detecteur"))
	gs.gear["detecteur"] = true
	assert_true(gs.owns_tool("detecteur"))


func test_scrap_gives_minerals_and_the_first_coin_goes_to_the_collection() -> void:
	gs._reward_buried("ferraille")
	assert_eq(int(gs.carried.get("mineraux", 0)) + int(gs.stock.get("mineraux", 0)), gs.config.buried_scrap_minerals)
	gs._reward_buried("piece")
	assert_true(gs.has_found("piece_ancienne"))


# --- Tortues -------------------------------------------------------------------------------

func test_turtle_lays_at_night_and_the_nest_hatches_after_three_nights() -> void:
	gs.config.turtle_night_chance = 1.0
	_set_hour(gs.config.turtle_hour + 0.5)
	gs._run_turtles()
	assert_eq(gs.nests.size(), 1)
	gs.config.turtle_night_chance = 0.0
	var hatched := []
	gs.turtles_hatched.connect(func(n): hatched.append(n))
	for i in gs.config.turtle_hatch_nights:
		gs.day.day_index += 1
		gs._run_turtles()
	assert_eq(hatched.size(), 1)
	assert_true(gs.nests.is_empty())
	assert_true(gs.has_found("oeuf_tortue"))


func test_you_cannot_dig_in_a_nest() -> void:
	var n: Dictionary = gs.lay_nest()
	var p: Vector3 = n.position
	var v := TerrainLogic.nearest_vertex(p.x, p.z)
	assert_eq(gs.scoop_reason(v, true), "PROMPT_TURTLE_NEST")


# --- Feu de camp et cocotiers --------------------------------------------------------------

func test_campfire_grills_coconuts_only_at_night_nearby() -> void:
	gs.decor.append({"id": "d1", "kind": "feu_de_camp", "position": Vector3(0, 0.5, 0)})
	_set_hour(12.0)
	assert_false(gs.is_near_lit_fire(Vector3(1, 0, 0)), "il ne brûle que la nuit")
	_set_hour(22.0)
	assert_true(gs.is_near_lit_fire(Vector3(1, 0, 0)))
	assert_false(gs.is_near_lit_fire(Vector3(10, 0, 0)))


func test_keep_a_coconut_and_plant_it_on_soil_only() -> void:
	var p: Dictionary = gs.add_pickup("coconut", Vector3(5, 0.5, 5))
	assert_false(gs.pick_coconut(p), "le seau en main : on ne la garde pas")
	gs.select_tool(gs.toolbar.first_free())
	assert_true(gs.pick_coconut(p))
	assert_eq(gs.coconuts_held, 1)
	assert_true(gs.owns_tool("noix_de_coco"))
	# Sur le sable : refusé.
	var sand := Vector3(gs.config.treasure_spot.x, 0, gs.config.treasure_spot.y)
	assert_eq(gs.plant_reason(sand), "PROMPT_PLANT_EARTH")
	var earth := _earth_spot()
	assert_true(earth.is_finite(), "il y a de la terre sur l'île")
	var pl: Dictionary = gs.plant_coconut(earth)
	assert_false(pl.is_empty())
	assert_eq(gs.coconuts_held, 0)
	assert_false(gs.owns_tool("noix_de_coco"))
	assert_eq(gs.plant_reason(earth), "PROMPT_PLANT_NO_NUT")


func test_planted_palm_grows_then_gives_a_coconut_each_morning() -> void:
	gs.coconuts_held = 1
	var pl: Dictionary = gs.plant_coconut(_earth_spot())
	assert_false(gs.is_grown(pl))
	gs.day.day_index += gs.config.planted_palm_days
	assert_true(gs.is_grown(pl))
	var before: int = gs.pickups.filter(func(p): return p.kind == "coconut").size()
	gs._island_morning()
	gs._island_morning()
	assert_eq(gs.pickups.filter(func(p): return p.kind == "coconut").size(), before + 1, "une seule à la fois")


func _earth_spot() -> Vector3:
	var held: int = gs.coconuts_held
	gs.coconuts_held = maxi(held, 1)
	var found := Vector3.INF
	for x in range(-20, 21):
		for z in range(-20, 21):
			var p := Vector3(x + 0.5, 0, z + 0.5)
			if not found.is_finite() and gs.plant_reason(p) == "":
				found = p
	gs.coconuts_held = held
	return found


# --- Longue-vue et décor --------------------------------------------------------------------

func test_spyglass_zoom_narrows_the_view() -> void:
	assert_almost(Player.spy_fov(75.0, 1.0), 75.0, 1e-4)
	var x4 := Player.spy_fov(75.0, gs.config.spyglass_zoom_min)
	var x12 := Player.spy_fov(75.0, gs.config.spyglass_zoom_max)
	assert_true(x4 < 25.0 and x12 < x4)


func test_path_tiles_come_by_five() -> void:
	var item: CatalogItem = gs.catalog.find(&"dalles")
	assert_eq(int(item.effect_value), 5)
	var before: int = gs.decor.filter(func(d): return d.kind == "dalle").size()
	var crate := {"id": "c1", "items": ["dalles"], "position": Vector3(2, 0.5, 2)}
	gs.crates.append(crate)
	gs.open_crate(crate)
	assert_eq(gs.decor.filter(func(d): return d.kind == "dalle").size(), before + 5)


func test_new_collection_rows_exist() -> void:
	for id: String in ["bouteille_carte", "bouteille_chaine", "bouteille_avion", "bouteille_crabe", "piece_ancienne", "coffre", "oeuf_tortue"]:
		assert_true(gs.collection_slots().has(id), id)


func test_nests_planted_palms_and_buried_saved() -> void:
	gs.lay_nest()
	gs.coconuts_held = 1
	gs.plant_coconut(_earth_spot())
	var n: int = gs.nests.size()
	var b: int = gs.buried.size()
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.nests.clear()
	gs.planted.clear()
	gs.buried.clear()
	gs.load_dict(data)
	assert_eq(gs.nests.size(), n)
	assert_eq(gs.planted.size(), 1)
	assert_eq(gs.buried.size(), b)
