extends TestCase
## Déplacer les objets sur la grille (M-22) : règles pures, puis GameState.move_item.

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	gs.setup(cfg)


func after_each() -> void:
	gs.free()


func test_snap_goes_to_cell_centre_and_keeps_height() -> void:
	var p := PlacementGrid.snap(Vector3(2.2, 0.7, -0.9), 1.0)
	assert_almost(p.x, 2.5)
	assert_almost(p.z, -0.5)
	assert_almost(p.y, 0.7)
	p = PlacementGrid.snap(Vector3(-3.01, 0.0, 3.99), 1.0)
	assert_almost(p.x, -3.5)
	assert_almost(p.z, 3.5)


func test_is_valid_checks_island_edge_and_overlaps() -> void:
	var others := [{"position": Vector3(0, 0, 0), "radius": 1.0}]
	assert_true(PlacementGrid.is_valid(Vector3(3, 0, 0), 1.0, others, 10.0))
	assert_false(PlacementGrid.is_valid(Vector3(1.5, 0, 0), 1.0, others, 10.0), "chevauche :")
	assert_false(PlacementGrid.is_valid(Vector3(9.5, 0, 0), 1.0, others, 10.0), "déborde de l'île :")
	# La hauteur ne compte pas.
	assert_false(PlacementGrid.is_valid(Vector3(1.5, 5, 0), 1.0, others, 10.0))


func test_move_item_snaps_and_emits() -> void:
	var basin: Dictionary = gs.zones[0]
	var moved := []
	gs.item_moved.connect(func(it): moved.append(it))
	assert_true(gs.move_item(basin, Vector3(-4.2, 9.0, -6.3)))
	assert_almost(basin.position.x, -4.5)
	assert_almost(basin.position.z, -6.5)
	assert_almost(basin.position.y, 0.5, 1e-6, "la hauteur d'origine est gardée :")
	assert_eq(moved.size(), 1)


func test_move_item_refuses_bad_spots() -> void:
	var basin: Dictionary = gs.zones[0]
	var before: Vector3 = basin.position
	assert_false(gs.move_item(basin, Vector3(30, 0.5, 0)), "dans la mer :")
	assert_false(gs.move_item(basin, Vector3(8, 0.5, 4)), "sur le dépôt :")
	gs.add_mirror(Vector3(0.5, 0.5, 0.5))
	assert_false(gs.move_item(basin, Vector3(1.5, 0.5, 0.5)), "sur le miroir :")
	assert_eq(basin.position, before)


func test_mirror_boost_follows_a_moved_mirror() -> void:
	var basin: Dictionary = gs.zones[0]
	var mirror: Dictionary = gs.add_mirror(Vector3(-0.5, 0.5, -10.5))
	assert_almost(gs.zone_boost(basin), 1.0)
	assert_true(gs.move_item(mirror, basin.position + Vector3(4, 0, 0)))
	assert_almost(gs.zone_boost(basin), 1.5)


func test_station_and_decor_are_movable_and_saved() -> void:
	var st: Dictionary = gs.add_station("rations", Vector3(0.5, 0.5, 0.5))
	assert_true(gs.move_item(st, Vector3(2.5, 0.5, -6.5)))
	assert_true(gs.movable_items().has(st))
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_almost(other.stations[0].position.x, 2.5)
	assert_almost(other.stations[0].position.z, -6.5)
	other.free()


func test_decor_gets_an_id() -> void:
	var item: CatalogItem = null
	for it in gs.catalog.items:
		if it.effect == CatalogItem.Effect.DECOR:
			item = it
	assert_true(item != null)
	gs.apply_item(item, Vector3(0.5, 0.5, 0.5))
	assert_true(String(gs.decor[0].get("id", "")) != "")


func test_rotation_is_kept_and_saved() -> void:
	var basin: Dictionary = gs.zones[0]
	assert_true(gs.move_item(basin, basin.position, 450.0))
	assert_almost(gs.item_rotation(basin), 90.0, 1e-6, "450° = 90° :")
	assert_true(gs.move_item(basin, basin.position + Vector3(1, 0, 0)))
	assert_almost(gs.item_rotation(basin), 90.0, 1e-6, "sans angle, on garde l'orientation :")
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_almost(other.item_rotation(other.zones[0]), 90.0)
	other.free()


func test_depot_is_movable_and_saved() -> void:
	assert_true(gs.movable_items().has(gs.depot))
	assert_true(gs.move_item(gs.depot, Vector3(4.5, 0.5, -9.5), 180.0))
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_almost(other.depot.position.x, 4.5)
	assert_almost(other.depot.position.z, -9.5)
	assert_almost(other.item_rotation(other.depot), 180.0)
	other.free()


func test_old_saves_without_rotation_still_load() -> void:
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	data.erase("depot")
	data["mirrors"] = [[0.5, 0.5, -10.5]]
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(other.mirrors.size(), 1)
	assert_eq(other.depot.position, gs.config.depot_position)
	other.free()


## Les objets livrés, les caisses et les coquillages tombent toujours sur une case libre.
func test_spawned_things_take_a_free_cell() -> void:
	var basin: Dictionary = gs.zones[0]
	var spot: Vector3 = gs.find_free_spot(gs.footprint_of("rations"), basin.position)
	assert_true(spot.distance_to(basin.position) > 0.1, "pas sur la cuvette :")
	assert_true(PlacementGrid.is_valid(spot, gs.footprint_of("rations"), gs.blockers_for({}), gs.config.build_radius_m))
	assert_almost(fposmod(spot.x, 1.0), 0.5, 1e-6, "au centre d'une case :")
	var item: CatalogItem = gs.catalog.find(&"rations")
	gs.apply_item(item, basin.position)
	var st: Dictionary = gs.stations[0]
	assert_true(gs.can_place(st, st.position), "la caisse de rations n'est sur rien :")
	for i in 30:
		var shell_spot: Vector3 = gs._random_beach_spot()
		assert_true(PlacementGrid.is_valid(shell_spot, 0.25, gs.blockers_for({}), gs.config.build_radius_m))
	for i in 6:
		var drop: Vector3 = gs.next_drop_position()
		assert_true(PlacementGrid.is_valid(drop, gs.footprint_of("caisse"), gs.blockers_for({}), gs.config.build_radius_m))


func test_salt_pile_sits_inside_its_zone_footprint() -> void:
	for kind in ["cuvette", "bache", "bassin_bois"]:
		var z := {"kind": kind}
		var off: Vector3 = gs.pile_offset(z)
		assert_true(off.x + 0.5 <= gs.footprint_of(kind) + 1e-6, "%s : le tas déborde :" % kind)
		assert_almost(fposmod(off.x, 1.0), 0.0, 1e-6, "le tas est à un nombre entier de cases :")
