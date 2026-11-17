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


func _circle(x: float, z: float, r: float, y: float = 0.0) -> Dictionary:
	return PlacementGrid.circle_shape(Vector3(x, y, z), r)


func _box(x0: float, z0: float, x1: float, z1: float) -> Dictionary:
	return PlacementGrid.rect_shape(Rect2(x0, z0, x1 - x0, z1 - z0))


func test_is_valid_checks_island_edge_and_overlaps() -> void:
	var others := [_circle(0, 0, 1.0)]
	assert_true(PlacementGrid.is_valid(_circle(3, 0, 1.0), others, 10.0))
	assert_false(PlacementGrid.is_valid(_circle(1.5, 0, 1.0), others, 10.0), "chevauche :")
	assert_false(PlacementGrid.is_valid(_circle(9.5, 0, 1.0), others, 10.0), "déborde de l'île :")
	# La hauteur ne compte pas.
	assert_false(PlacementGrid.is_valid(_circle(1.5, 0, 1.0, 5.0), others, 10.0))


func test_rectangles_touching_by_an_edge_do_not_overlap() -> void:
	# Deux objets case contre case : permis. Une case en commun : refusé.
	assert_false(PlacementGrid.overlaps(_box(0, 0, 2, 1), _box(2, 0, 3, 1)), "bord contre bord")
	assert_false(PlacementGrid.overlaps(_box(0, 0, 2, 1), _box(2, 1, 3, 2)), "coin contre coin")
	assert_true(PlacementGrid.overlaps(_box(0, 0, 2, 1), _box(1, 0, 3, 1)), "une case en commun")
	assert_true(PlacementGrid.overlaps(_box(0, 0, 4, 4), _box(1, 1, 2, 2)), "l'une dans l'autre")
	# Rectangle et cercle (joueur, palmier, tuyau) : le point le plus proche du rectangle compte.
	assert_false(PlacementGrid.overlaps(_box(0, 0, 2, 2), _circle(2.5, 1, 0.5)), "cercle qui touche le bord")
	assert_true(PlacementGrid.overlaps(_box(0, 0, 2, 2), _circle(2.4, 1, 0.5)))
	assert_false(PlacementGrid.overlaps(_box(0, 0, 2, 2), _circle(2.4, 2.4, 0.5)), "près du coin, mais pas dessus")
	assert_true(PlacementGrid.overlaps(_circle(1, 1, 0.2), _box(0, 0, 2, 2)), "dans l'ordre inverse aussi")


func test_rect_at_rotates_by_quarter_turns_like_the_view() -> void:
	var local := Rect2(-0.5, -0.5, 1.0, 3.0)  # 1 case de large, 3 de long vers +Z (le toboggan)
	var r: Rect2 = PlacementGrid.rect_at(local, Vector3(10, 0, 20), 0.0)
	assert_eq(r, Rect2(9.5, 19.5, 1, 3))
	# Un quart de tour (rotation_degrees.y = 90) : +Z local part vers +X.
	r = PlacementGrid.rect_at(local, Vector3(10, 0, 20), 90.0)
	assert_eq(r, Rect2(9.5, 19.5, 3, 1))
	var probe := Node3D.new()
	probe.rotation_degrees.y = 90.0
	var tip := probe.transform * Vector3(0, 0, 2.5)
	assert_almost(tip.x, 2.5, 1e-4, "la vue tourne dans le même sens")
	probe.free()
	r = PlacementGrid.rect_at(local, Vector3.ZERO, 180.0)
	assert_eq(r, Rect2(-0.5, -2.5, 1, 3))
	r = PlacementGrid.rect_at(local, Vector3.ZERO, 270.0)
	assert_eq(r, Rect2(-2.5, -0.5, 3, 1))


func test_snap_rect_puts_the_edges_on_grid_lines() -> void:
	# Largeur impaire (3 cases) : centre au milieu d'une case. Paire (2 cases) : sur une ligne.
	var p := PlacementGrid.snap_rect(Vector3(2.2, 0.7, -0.9), Rect2(-1.5, -1.5, 3, 3), 0.0, 1.0)
	assert_almost(p.x, 2.5)
	assert_almost(p.z, -0.5)
	assert_almost(p.y, 0.7)
	p = PlacementGrid.snap_rect(Vector3(2.2, 0, -0.9), Rect2(-1, -1, 2, 2), 0.0, 1.0)
	assert_almost(p.x, 2.0)
	assert_almost(p.z, -1.0)
	# Le miroir (2 × 1) tourné d'un quart de tour devient 1 × 2 : l'alignement suit.
	p = PlacementGrid.snap_rect(Vector3(2.2, 0, -0.9), Rect2(-1, -0.5, 2, 1), 90.0, 1.0)
	assert_almost(p.x, 2.5)
	assert_almost(p.z, -1.0)
	var cells := PlacementGrid.cells_of(PlacementGrid.rect_at(Rect2(-1, -0.5, 2, 1), p, 90.0), 1.0)
	assert_eq(cells.size(), 2)
	assert_true(cells.has(Vector2i(2, -2)) and cells.has(Vector2i(2, -1)), str(cells))


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
	assert_false(gs.move_item(basin, Vector3(9, 0.5, 7)), "sur le dépôt :")
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
	assert_true(gs.move_item(gs.depot, Vector3(5, 0.5, -9), 180.0))
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_almost(other.depot.position.x, 5.0)
	assert_almost(other.depot.position.z, -9.0)
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
	var spot: Vector3 = gs.find_free_spot("rations", basin.position)
	assert_true(spot.distance_to(basin.position) > 0.1, "pas sur la cuvette :")
	assert_true(gs.spot_ok("rations", spot, 0.0, gs.blockers_for({})))
	assert_almost(fposmod(spot.x, 1.0), 0.5, 1e-6, "au centre d'une case :")
	var item: CatalogItem = gs.catalog.find(&"rations")
	gs.apply_item(item, basin.position)
	var st: Dictionary = gs.stations[0]
	assert_true(gs.can_place(st, st.position), "la caisse de rations n'est sur rien :")
	for i in 30:
		var shell_spot: Vector3 = gs._random_beach_spot()
		assert_true(gs.spot_ok("coquillage", shell_spot, 0.0, gs.blockers_for({})))
	for i in 6:
		var drop: Vector3 = gs.next_drop_position()
		assert_true(gs.spot_ok("caisse", drop, 0.0, gs.blockers_for({})))


func test_salt_pile_sits_inside_its_zone_footprint() -> void:
	for kind in ["cuvette", "bache", "bassin_bois"]:
		var z := {"kind": kind}
		var off: Vector3 = gs.pile_offset(z)
		var foot: Rect2 = gs.footprint_of(kind)
		for res in gs.config.pile_slots:
			var o: Vector3 = gs.pile_offset(z, res)
			var cell := Rect2(o.x - 0.5, o.z - 0.5, 1, 1)
			assert_true(foot.encloses(cell), "%s/%s : le tas déborde de %s" % [kind, res, foot])
		assert_almost(fposmod(off.x, 1.0), 0.0, 1e-6, "le tas est à un nombre entier de cases :")
