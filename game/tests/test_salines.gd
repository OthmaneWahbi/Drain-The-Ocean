extends TestCase
## 0.1.20 : les salines (marais creusé, marées, flaques, juice du sel). PRD §19.27.

const GameStateScript := preload("res://core/game_state.gd")
const DeliveryPlane := preload("res://scenes/world/delivery_plane.gd")
const SoundBoard := preload("res://scenes/audio/sound_board.gd")
const DryingZoneView := preload("res://scenes/world/drying_zone_view.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e12
	gs.setup(cfg)


func after_each() -> void:
	gs.free()


## Creuse un trou de w × h cases à partir de `origin`, à `depth` m sous le sol d'origine.
func _dig(origin: Vector2i, w: int, h: int, depth: float) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var corners := []
	for j in h:
		for i in w:
			var c := origin + Vector2i(i, j)
			cells.append(c)
			corners.append_array(gs.terrain.set_cell(c, SaltMarsh.base_mean(gs.terrain, c) - depth))
	gs.terrain_changed.emit(corners)
	return cells


func _center(cells: Array) -> Vector3:
	var c: Vector2i = cells[0]
	return Vector3(c.x + 0.5, 0.0, c.y + 0.5)


func _full_bucket() -> void:
	gs.bucket.water_l = gs.bucket.capacity_l


# --- Marées --------------------------------------------------------------------------------

func test_tide_is_high_at_3_and_15_and_low_at_9_and_21() -> void:
	assert_almost(TideLogic.offset(3.0, 0.3, 3.0), 0.3, 1e-6)
	assert_almost(TideLogic.offset(15.0, 0.3, 3.0), 0.3, 1e-6)
	assert_almost(TideLogic.offset(9.0, 0.3, 3.0), -0.3, 1e-6)
	assert_almost(TideLogic.offset(21.0, 0.3, 3.0), -0.3, 1e-6)
	assert_true(TideLogic.is_low(9.0, 3.0) and TideLogic.is_high(15.0, 3.0))
	assert_false(TideLogic.is_low(12.0, 3.0), "à mi-marée, ni basse ni haute")


func test_low_index_changes_once_per_low_tide() -> void:
	var a := TideLogic.low_index(0, 9.0, 3.0)
	assert_eq(TideLogic.low_index(0, 10.0, 3.0), a, "la même marée basse")
	assert_eq(TideLogic.low_index(0, 21.0, 3.0), a + 1)
	assert_eq(TideLogic.low_index(1, 9.0, 3.0), a + 2)


func test_visible_water_follows_the_tide_but_not_the_volume() -> void:
	gs.day.time_s = 15.0 / 24.0 * gs.day.day_length_s
	assert_almost(gs.water_level_y() - gs.honest_water_level_y(), gs.config.tide_amplitude_m, 1e-6)
	var removed: float = gs.ocean.removed_l
	gs.day.time_s = 9.0 / 24.0 * gs.day.day_length_s
	assert_almost(gs.water_level_y() - gs.honest_water_level_y(), -gs.config.tide_amplitude_m, 1e-6)
	assert_almost(gs.ocean.removed_l, removed, 1e-9, "la marée ne change pas le volume :")


# --- Marais salant -------------------------------------------------------------------------

func test_a_shallow_or_small_hole_is_not_a_marsh() -> void:
	var small := _dig(Vector2i(-10, -12), 1, 2, 0.4)
	assert_true(gs.hole_region_at(_center(small)).is_empty(), "2 cases : trop petit")
	var shallow := _dig(Vector2i(-4, -12), 2, 2, 0.1)
	assert_true(gs.hole_region_at(_center(shallow)).is_empty(), "10 cm : pas assez creusé")


func test_pouring_into_a_dug_hole_makes_a_marsh_sized_by_its_surface() -> void:
	var cells := _dig(Vector2i(-10, -12), 3, 2, 0.4)
	assert_eq(gs.hole_region_at(_center(cells)).size(), 6)
	_full_bucket()
	var poured: float = gs.pour_bucket_into_hole(_center(cells))
	assert_almost(poured, 10.0, 1e-6)
	var m: Dictionary = gs.marsh_at_cell(cells[0])
	assert_false(m.is_empty(), "un marais est né")
	assert_almost((m.logic as DryingLogic).capacity_l, 60.0, 1e-6, "10 L par case :")
	assert_false(gs.movable_items().has(m), "on ne déplace pas un trou")


func test_sand_marsh_loses_a_quarter_earth_rim_loses_nothing() -> void:
	var cells := _dig(Vector2i(-10, -12), 2, 2, 0.4)
	_full_bucket()
	gs.pour_bucket_into_hole(_center(cells))
	var m: Dictionary = gs.marsh_at_cell(cells[0])
	assert_almost((m.logic as DryingLogic).water_l, 7.5, 1e-6, "25 % bus par le sable :")
	# Une bordure de terre : on recouvre de terre tous les sommets autour.
	for c in SaltMarsh.rim(cells):
		for v in TerrainLogic.cell_vertices(c):
			gs.terrain.cover[v] = TerrainLogic.Soil.EARTH
	assert_almost(gs.marsh_loss(m), 0.0, 1e-9)
	_full_bucket()
	gs.pour_bucket_into(m)
	assert_almost((m.logic as DryingLogic).water_l, 17.5, 1e-6)


func test_marsh_dries_into_salt_and_announces_each_grain() -> void:
	var cells := _dig(Vector2i(-10, -12), 2, 2, 0.4)
	_full_bucket()
	gs.pour_bucket_into_hole(_center(cells))
	var m: Dictionary = gs.marsh_at_cell(cells[0])
	var drops := []
	gs.salt_dropped.connect(func(z, r, n): drops.append([z, r, n]))
	gs.day.time_s = 12.0 / 24.0 * gs.day.day_length_s
	gs.advance_time(60.0, 1.0)
	assert_almost((m.logic as DryingLogic).water_l, 0.0, 1e-6, "un marais plein sèche en 60 s, celui-ci plus vite")
	assert_true(int((m.logic as DryingLogic).deposit.get("sel", 0)) >= 1)
	assert_true(drops.any(func(d): return d[0] == m and d[1] == "sel"), "chaque grain s'annonce (juice)")


func test_marsh_piles_sit_on_the_rim_outside_the_hole() -> void:
	var cells := _dig(Vector2i(-10, -12), 2, 2, 0.4)
	_full_bucket()
	gs.pour_bucket_into_hole(_center(cells))
	var m: Dictionary = gs.marsh_at_cell(cells[0])
	assert_eq((m.piles as Dictionary).size(), gs.config.pile_slots.size())
	var spots := {}
	for k in m.piles:
		var p: Vector3 = m.piles[k]
		var cell := TerrainLogic.cell_of(p.x, p.z)
		assert_false(cells.has(cell), "%s hors du trou" % k)
		assert_false(spots.has(cell), "un tas par case")
		spots[cell] = true


func test_cannot_fill_a_marsh_with_water_but_can_refill_an_empty_one() -> void:
	var cells := _dig(Vector2i(-10, -12), 2, 2, 0.4)
	_full_bucket()
	gs.pour_bucket_into_hole(_center(cells))
	var v: Vector2i = cells[0] * TerrainLogic.SUB + Vector2i(1, 1)
	gs.has_shovel = true
	gs.shovel_sand = 2.0
	assert_eq(gs.scoop_reason(v, false), "PROMPT_MARSH_NOT_EMPTY")
	var m: Dictionary = gs.marsh_at_cell(cells[0])
	(m.logic as DryingLogic).water_l = 0.0
	(m.logic as DryingLogic).deposit = {}
	var removed := []
	gs.zone_removed.connect(func(z): removed.append(z))
	# Reboucher (le sol revient à son niveau d'origine) : le marais vide disparaît.
	var corners := []
	for c in cells:
		corners.append_array(gs.terrain.set_cell(c, SaltMarsh.base_mean(gs.terrain, c)))
	gs.terrain_changed.emit(corners)
	assert_eq(removed.size(), 1)
	assert_false(gs.zones.has(m))


func test_empty_marsh_grows_with_its_hole() -> void:
	var cells := _dig(Vector2i(-10, -12), 2, 2, 0.4)
	_full_bucket()
	gs.pour_bucket_into_hole(_center(cells))
	var m: Dictionary = gs.marsh_at_cell(cells[0])
	(m.logic as DryingLogic).water_l = 0.0
	_dig(Vector2i(-8, -12), 1, 2, 0.4)
	assert_eq((m.cells as Array).size(), 6)
	assert_almost((m.logic as DryingLogic).capacity_l, 60.0, 1e-6)


func test_marsh_survives_save_and_load() -> void:
	var cells := _dig(Vector2i(-10, -12), 3, 2, 0.4)
	_full_bucket()
	gs.pour_bucket_into_hole(_center(cells))
	gs.add_to_collection("oursin")
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.load_dict(data)
	var m: Dictionary = gs.marsh_at_cell(cells[0])
	assert_false(m.is_empty())
	assert_eq((m.cells as Array).size(), 6)
	assert_almost((m.logic as DryingLogic).water_l, 7.5, 1e-6)
	assert_eq(int(gs.collection.get("oursin", 0)), 1)


func test_a_marsh_by_the_sea_fills_itself_at_high_tide() -> void:
	# Un trou au bord de la plage, côté est, plus bas que la marée haute.
	var a := 0.0
	var r: float = gs.terrain.coast_at(a) - 0.6
	var origin := Vector2i(floori(r) - 2, -1)
	var cells: Array[Vector2i] = []
	var corners := []
	for j in 2:
		for i in 2:
			var c := origin + Vector2i(i, j)
			cells.append(c)
			corners.append_array(gs.terrain.set_cell(c, gs.config.sea_level_y - 0.1))
	gs.terrain_changed.emit(corners)
	var m: Dictionary = gs.add_marsh(cells)
	gs.day.time_s = 15.0 / 24.0 * gs.day.day_length_s  # marée haute
	var removed: float = gs.ocean.removed_l
	gs.simulate(1.0)
	assert_true((m.logic as DryingLogic).water_l > 0.0, "la mer entre dans le marais")
	assert_true(gs.ocean.removed_l > removed, "cette eau vient de l'océan")


# --- Flaques -------------------------------------------------------------------------------

func test_tide_pools_show_finds_at_low_tide_and_lose_them_at_high_tide() -> void:
	assert_eq(gs.tide_pools.size(), gs.config.tide_pool_count)
	gs.day.time_s = 9.0 / 24.0 * gs.day.day_length_s
	gs.simulate(0.1)
	for pool in gs.tide_pools:
		assert_true(gs.tide_pool_uncovered(pool), "découverte à marée basse")
		assert_true((pool.items as Array).size() >= 1 and (pool.items as Array).size() <= gs.config.tide_pool_max_items)
	var first: Array = gs.tide_pools[0].items.duplicate()
	gs.simulate(0.1)
	assert_eq(gs.tide_pools[0].items, first, "garnie une seule fois par marée")
	gs.day.time_s = 15.0 / 24.0 * gs.day.day_length_s
	gs.simulate(0.1)
	assert_false(gs.tide_pool_uncovered(gs.tide_pools[0]), "couverte à marée haute")
	assert_true((gs.tide_pools[0].items as Array).is_empty(), "la mer remporte les trouvailles")


func test_taking_finds_from_a_pool() -> void:
	var pool: Dictionary = gs.tide_pools[0]
	gs.day.time_s = 9.0 / 24.0 * gs.day.day_length_s
	pool.low = 999999  # déjà garnie pour cette marée (on choisit le contenu)
	pool.items = ["etoile_de_mer", "coquillage"]
	assert_eq(gs.take_from_pool(pool), "etoile_de_mer")
	assert_eq(int(gs.collection.get("etoile_de_mer", 0)), 1, "une trouvaille de la collection")
	assert_eq(gs.take_from_pool(pool), "coquillage")
	assert_true(int(gs.carried.get("coquillages", 0)) >= 1, "un coquillage dans les bras")
	assert_eq(gs.take_from_pool(pool), "", "vide")


func test_pool_finds_are_not_taken_under_water() -> void:
	var pool: Dictionary = gs.tide_pools[0]
	gs.day.time_s = 15.0 / 24.0 * gs.day.day_length_s
	pool.items = ["oursin"]
	assert_eq(gs.take_from_pool(pool), "")


func test_pinchy_finds_an_extra_shell_in_the_pool_where_the_player_stands() -> void:
	gs.pet.affection = 100.0
	var pool: Dictionary = gs.tide_pools[1]
	gs.day.time_s = 9.0 / 24.0 * gs.day.day_length_s
	gs.simulate(0.1)
	var n: int = (pool.items as Array).size()
	gs.player_position = pool.position
	gs.pet_position = pool.position + Vector3(1, 0, 0)
	gs.simulate(0.1)
	assert_eq((pool.items as Array).size(), n + 1)
	assert_eq(String(pool.items[-1]), "coquillage")
	gs.simulate(0.1)
	assert_eq((pool.items as Array).size(), n + 1, "une fois par marée basse")


# --- Juice ---------------------------------------------------------------------------------

func test_plane_roll_is_one_full_turn() -> void:
	assert_almost(DeliveryPlane.roll_angle(0.0), 0.0, 1e-6)
	assert_almost(DeliveryPlane.roll_angle(5.0), TAU, 1e-6)
	assert_true(DeliveryPlane.roll_angle(1.0) > 0.0 and DeliveryPlane.roll_angle(1.0) < TAU)


func test_tink_is_higher_for_rarer_resources() -> void:
	assert_true(SoundBoard.tink_pitch("mineraux") > SoundBoard.tink_pitch("sel"))
	assert_true(SoundBoard.tink_pitch("mineraux_rares") > SoundBoard.tink_pitch("mineraux"))
	assert_true(SoundSynth.samples("tink").size() > 0)


func test_pile_pop_is_a_small_bump() -> void:
	assert_almost(DryingZoneView.SaltPile.pop_scale(0.0), 0.0, 1e-6)
	assert_almost(DryingZoneView.SaltPile.pop_scale(0.5), 0.15, 1e-6)
