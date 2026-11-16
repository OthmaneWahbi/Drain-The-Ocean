extends TestCase
## Tout ce qui apparaît (coquillages, noix de coco, caisses, objets sortis des caisses) regarde
## ce qui occupe déjà la place. Et tous les cas tordus du placement qu'on a pu imaginer.

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	gs.setup(cfg)
	gs.rng.seed = 1234


func after_each() -> void:
	gs.free()


func _rich() -> void:
	gs.stock = {"sel": 100000, "mineraux": 100000, "mineraux_rares": 100000, "coquillages": 100000, "perles": 100}
	gs.unlocked_tier = 2


## Aucune emprise ne chevauche une autre (objets, caisses, ramassables, obstacles fixes).
func _assert_nothing_overlaps(label: String) -> void:
	var things := []
	for it in gs.movable_items():
		things.append({"position": it.position, "radius": gs.footprint(it), "name": gs.item_kind(it)})
	for c in gs.crates:
		things.append({"position": c.position, "radius": gs.footprint_of("caisse"), "name": "caisse"})
	for p in gs.pickups:
		var r: float = gs.config.coconut_radius_m if p.kind == "coconut" else gs.footprint_of("coquillage")
		things.append({"position": p.position, "radius": r, "name": p.kind})
	for o in gs.config.fixed_obstacles:
		things.append({"position": Vector3(o.x, 0, o.y), "radius": o.z, "name": "fixe"})
	for i in things.size():
		for j in range(i + 1, things.size()):
			var a: Dictionary = things[i]
			var b: Dictionary = things[j]
			var d: float = Vector2(a.position.x, a.position.z).distance_to(Vector2(b.position.x, b.position.z))
			if d < a.radius + b.radius - 1e-6:
				fail("%s : %s et %s se chevauchent (%.2f m)" % [label, a.name, b.name, d])
				return


func test_new_game_has_no_overlap() -> void:
	_assert_nothing_overlaps("nouvelle partie")


func test_shells_never_land_on_things_over_many_mornings() -> void:
	# Des objets posés sur la plage, puis 40 matins d'affilée (on ramasse tout chaque jour).
	gs.add_mirror(Vector3(0.5, 0.5, 17.5))
	gs.add_station("rations", Vector3(-17.5, 0.5, 0.5))
	gs.add_zone("bache", Vector3(12.5, 0.5, -12.5))
	for day in 40:
		for p in gs.pickups.duplicate():
			if p.kind == "shell":
				gs.pickups.erase(p)
		gs._morning_refill()
		_assert_nothing_overlaps("matin %d" % day)
	var shells: Array = gs.pickups.filter(func(p): return p.kind == "shell")
	assert_eq(shells.size(), gs.config.shells_per_morning)
	for s in shells:
		assert_almost(fposmod(s.position.x, 1.0), 0.5, 1e-6, "coquillage au centre d'une case :")


func test_full_beach_spawns_nothing_instead_of_overlapping() -> void:
	gs.pickups.clear()
	gs.config.player_radius_m = 1000.0  # le « joueur » couvre toute l'île
	gs.player_position = Vector3(0, 0.5, 0)
	gs._morning_refill()
	assert_eq(gs.pickups.size(), 0, "ni coquillage ni noix de coco sur le joueur :")
	assert_false(gs._random_beach_spot().is_finite())


func test_coconut_does_not_respawn_under_an_object() -> void:
	# Cas d'une vieille sauvegarde : un objet posé sur la place d'une noix de coco.
	var spot: Vector3 = gs.config.coconut_spots[0]
	gs.pickups = gs.pickups.filter(func(p): return (p.position as Vector3).distance_to(spot) > 0.1)
	gs.add_station("rations", spot)
	gs._morning_refill()
	for p in gs.pickups:
		assert_true((p.position as Vector3).distance_to(spot) > 0.1, "pas de noix sous la caisse de rations")


func test_coconut_respawns_when_its_spot_is_free() -> void:
	var spot: Vector3 = gs.config.coconut_spots[0]
	gs.pickups = gs.pickups.filter(func(p): return (p.position as Vector3).distance_to(spot) > 0.1)
	gs._morning_refill()
	assert_true(gs._has_pickup_at("coconut", spot))


func test_crate_in_flight_blocks_placement_and_other_crates() -> void:
	_rich()
	var c1: Dictionary = gs.order(["bache"])
	var c2: Dictionary = gs.order(["bache"])
	assert_false(c1.is_empty())
	assert_true(c1.position.distance_to(c2.position) >= 2.0 * gs.footprint_of("caisse") - 1e-6, "deux caisses pas au même endroit")
	var basin: Dictionary = gs.zones[0]
	assert_false(gs.move_item(basin, c1.position), "on ne pose rien là où une caisse va tomber")
	_assert_nothing_overlaps("caisses")


func test_crate_avoids_object_on_drop_spot() -> void:
	_rich()
	var wanted: Vector3 = gs.config.delivery_center
	gs.add_mirror(PlacementGrid.snap(wanted, 1.0))
	var c: Dictionary = gs.order(["tongs"])
	_assert_nothing_overlaps("caisse sur miroir")


func test_opening_crate_requests_placement_for_each_placed_object_only() -> void:
	_rich()
	var requested := []
	gs.placement_requested.connect(func(it): requested.append(it))
	var c: Dictionary = gs.order(["bache", "tongs", "miroir", "bache"])
	gs.open_crate(c)
	assert_eq(requested.size(), 3, "2 bâches + 1 miroir ; les tongs ne se posent pas :")
	assert_eq(gs.item_kind(requested[0]), "bache")
	assert_eq(gs.item_kind(requested[1]), "miroir")
	assert_true(gs.movable_items().has(requested[2]))
	_assert_nothing_overlaps("contenu de la caisse")


func test_opening_crate_with_only_upgrades_requests_nothing() -> void:
	_rich()
	var requested := []
	gs.placement_requested.connect(func(it): requested.append(it))
	gs.open_crate(gs.order(["tongs", "grand_seau"]))
	assert_eq(requested.size(), 0)


func test_opening_the_same_crate_twice_does_nothing() -> void:
	_rich()
	var requested := []
	gs.placement_requested.connect(func(it): requested.append(it))
	var c: Dictionary = gs.order(["bache"])
	gs.open_crate(c)
	gs.open_crate(c)
	assert_eq(requested.size(), 1)
	assert_eq(gs.zones.size(), 2)


func test_big_crate_full_of_basins_never_overlaps() -> void:
	_rich()
	var ids := []
	for i in 6:
		ids.append("bassin_bois")
	ids.append_array(["condenseur", "rations", "miroir", "miroir", "bateau"])
	gs.open_crate(gs.order(ids))
	_assert_nothing_overlaps("grosse caisse")


func test_nothing_spawns_or_lands_on_the_player() -> void:
	_rich()
	gs.player_position = gs.config.delivery_center
	var c: Dictionary = gs.order(["bache"])
	gs.player_position = c.position  # le joueur se tient sur la caisse pour l'ouvrir
	gs.open_crate(c)
	var tarp: Dictionary = gs.zones[gs.zones.size() - 1]
	var d: float = Vector2(tarp.position.x, tarp.position.z).distance_to(Vector2(c.position.x, c.position.z))
	assert_true(d >= gs.footprint(tarp) + gs.config.player_radius_m - 1e-6, "la bâche n'apparaît pas sur le joueur")


func test_player_blocks_placement() -> void:
	var basin: Dictionary = gs.zones[0]
	var target := Vector3(-0.5, 0.5, -8.5)
	gs.player_position = target + Vector3(1, 0, 0)
	assert_false(gs.move_item(basin, target), "le joueur est dans l'emprise")
	gs.player_position = GameStateScript.FAR_AWAY
	assert_true(gs.move_item(basin, target))


func test_shell_blocks_placement_until_picked_up() -> void:
	var basin: Dictionary = gs.zones[0]
	var target := Vector3(-0.5, 0.5, -8.5)
	var shell: Dictionary = gs.add_pickup("shell", target + Vector3(1, 0, 0))
	assert_false(gs.move_item(basin, target))
	assert_true(gs.take_pickup(shell))
	assert_true(gs.move_item(basin, target))


func test_item_can_stay_or_turn_on_its_own_cell() -> void:
	var basin: Dictionary = gs.zones[0]
	assert_true(gs.move_item(basin, basin.position), "un objet ne se bloque pas lui-même")
	assert_true(gs.move_item(basin, basin.position, 270.0))
	assert_almost(gs.item_rotation(basin), 270.0)


func test_failed_move_changes_nothing_and_emits_nothing() -> void:
	var basin: Dictionary = gs.zones[0]
	var before: Vector3 = basin.position
	var moved := []
	gs.item_moved.connect(func(it): moved.append(it))
	assert_false(gs.move_item(basin, Vector3(100, 0.5, 100), 90.0))
	assert_eq(basin.position, before)
	assert_almost(gs.item_rotation(basin), 0.0, 1e-6, "la rotation non plus")
	assert_eq(moved.size(), 0)


func test_moving_a_zone_keeps_its_water_and_salt() -> void:
	var basin: Dictionary = gs.zones[0]
	basin.logic.add_water(30.0)
	basin.logic.deposit = {"sel": 4}
	assert_true(gs.move_item(basin, Vector3(-0.5, 0.5, -8.5)))
	assert_almost(basin.logic.water_l, 30.0)
	assert_eq(int(basin.logic.deposit.get("sel", 0)), 4)
	gs.harvest(basin)
	assert_eq(int(gs.carried.get("sel", 0)), 3)


func test_find_free_spot_is_valid_even_when_crowded() -> void:
	for i in 8:
		var spot: Vector3 = gs.find_free_spot(gs.footprint_of("bassin_bois"), Vector3.ZERO)
		assert_true(spot.is_finite())
		gs.add_zone("bassin_bois", spot)
	_assert_nothing_overlaps("8 bassins")


func test_overlapping_old_save_still_loads() -> void:
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	data["mirrors"] = [{"position": [-5.5, 0.5, 2.5], "rotation_deg": 45}, [-5.5, 0.5, 2.5]]
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(other.mirrors.size(), 2, "on ne perd rien, même mal rangé")
	other.free()


func test_new_game_resets_depot_and_player_free_cells() -> void:
	assert_true(gs.move_item(gs.depot, Vector3(4.5, 0.5, -9.5)))
	gs.new_game()
	assert_eq(gs.depot.position, gs.config.depot_position)
	assert_almost(gs.item_rotation(gs.depot), 0.0)
