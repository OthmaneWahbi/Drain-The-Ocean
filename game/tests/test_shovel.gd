extends TestCase
## La pelle (0.1.10, remarque 5) : aplanir, creuser, remonter le sable pour poser où on veut.
## 0.1.11 : la pelle s'achète et porte le sable (pelletées). Les tests généraux lui donnent une
## très grande pelle pleine à moitié ; ceux de la charge utilisent la vraie.

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	cfg.shovel_capacity_scoops = 1000
	gs.setup(cfg)
	gs.has_shovel = true
	gs._sync_toolbar()
	gs.shovel_sand = 500


func after_each() -> void:
	gs.free()


## Une case de la plage, hors du plateau de départ, loin de tout objet.
func _beach_cell() -> Vector2i:
	for j in range(24, 27):
		var cell := Vector2i(-6, j)
		if gs.dig_reason(cell, 0.5) == "" and is_nan(gs.terrain.cell_level(cell)):
			return cell
	return Vector2i(-6, 25)


func test_the_shovel_is_bought_not_given() -> void:
	gs.new_game()
	assert_false(gs.owns_tool("pelle"), "0.1.11 : plus donnée au départ")
	assert_eq(gs.toolbar.index_of("pelle"), -1)
	var item: CatalogItem = gs.catalog.find(&"pelle")
	assert_true(item != null and item.tier == 1, "au catalogue dès le début")
	gs.stock = {"sel": int(item.price.get("sel", 0))}
	gs.open_crates(gs.order(["pelle"]))
	assert_true(gs.owns_tool("pelle"))
	assert_true(gs.toolbar.index_of("pelle") >= 0)
	assert_eq(gs.shovel_sand, 0, "elle arrive vide")


func test_flattening_makes_a_cell_flat_at_the_level_asked() -> void:
	var cell := _beach_cell()
	assert_true(is_nan(gs.terrain.cell_level(cell)), "la plage n'est pas plate au départ")
	assert_true(gs.work_cell(cell, gs.Dig.FLATTEN, 0.5))
	assert_almost(gs.terrain.cell_level(cell), 0.5, 1e-4)
	var c: float = gs.config.grid_cell_m
	assert_almost(gs.terrain.height((cell.x + 0.5) * c, (cell.y + 0.5) * c), 0.5, 1e-3, "le maillage suit")
	assert_true(gs.terrain.cell_worked(cell))


func test_dig_and_raise_move_by_one_step_and_stay_in_bounds() -> void:
	var cell := Vector2i(0, 5)  # sur le plateau
	gs.work_cell(cell, gs.Dig.FLATTEN, 0.5)
	assert_true(gs.work_cell(cell, gs.Dig.DIG))
	assert_almost(gs.terrain.cell_level(cell), 0.5 - gs.config.dig_step_m, 1e-4)
	assert_true(gs.work_cell(cell, gs.Dig.RAISE))
	assert_true(gs.work_cell(cell, gs.Dig.RAISE))
	assert_almost(gs.terrain.cell_level(cell), 0.5 + gs.config.dig_step_m, 1e-4)
	for i in 40:
		gs.work_cell(cell, gs.Dig.DIG)
	assert_true(gs.terrain.cell_level(cell) >= gs.water_level_y() + gs.config.dig_min_above_water_m - 1e-4, "jamais sous l'eau")
	for i in 40:
		gs.work_cell(cell, gs.Dig.RAISE)
	assert_true(gs.terrain.cell_level(cell) <= gs.config.ground_y + gs.config.dig_max_above_ground_m + 1e-4)


func test_cannot_dig_the_sea_or_under_an_object() -> void:
	assert_eq(gs.dig_reason(Vector2i(0, 40), 0.5), "PROMPT_DIG_WATER")
	var basin: Dictionary = gs.zones[0]
	var under := TerrainLogic.cell_of(basin.position.x, basin.position.z)
	assert_eq(gs.dig_reason(under, 0.25), "PROMPT_DIG_BLOCKED")
	assert_false(gs.work_cell(under, gs.Dig.DIG))


func test_cannot_move_a_corner_shared_with_an_object() -> void:
	var basin: Dictionary = gs.zones[0]
	var rect: Rect2 = gs.item_rect(basin)
	var beside := Vector2i(floori(rect.end.x / gs.config.grid_cell_m), floori(rect.position.y / gs.config.grid_cell_m))
	assert_eq(gs.dig_reason(beside, 0.25), "PROMPT_DIG_NEAR_OBJECT", "la case collée à la cuvette")
	assert_eq(gs.dig_reason(beside, gs.config.ground_y), "", "la garder au même niveau, c'est permis")


func test_flattened_beach_becomes_placeable() -> void:
	var cell := _beach_cell()
	var c: float = gs.config.grid_cell_m
	var pos := Vector3((cell.x + 0.5) * c, 0.5, (cell.y + 0.5) * c)
	assert_false(gs.spot_ok("rations", pos, 0.0, gs.blockers_for({})), "pas sur la pente")
	assert_eq(gs.placement_reason({"kind": "rations"}, pos, 0.0), "PROMPT_GROUND_NOT_FLAT")
	gs.work_cell(cell, gs.Dig.FLATTEN, 0.75)
	assert_true(gs.spot_ok("rations", pos, 0.0, gs.blockers_for({})), "posable une fois aplanie")
	assert_almost(gs.ground_level(gs.footprint_rect("rations", pos, 0.0)), 0.75, 1e-4)


func test_cells_at_different_levels_are_not_placeable_together() -> void:
	gs.work_cell(Vector2i(2, 4), gs.Dig.FLATTEN, 0.5)
	gs.work_cell(Vector2i(3, 4), gs.Dig.FLATTEN, 0.75)
	assert_true(is_nan(gs.ground_level(Rect2(2, 4, 2, 1))))
	assert_almost(gs.ground_level(Rect2(2, 4, 1, 1)), 0.5, 1e-4)


func test_terrain_changed_lists_the_moved_corners() -> void:
	var got := []
	gs.terrain_changed.connect(func(corners: Array): got.append_array(corners))
	gs.work_cell(Vector2i(1, 6), gs.Dig.DIG)
	for v in TerrainLogic.cell_vertices(Vector2i(1, 6)):
		assert_true(got.has(v), "tous les sommets de la case (0.1.11 : 9)")
	assert_eq(got.size(), 25, "et la couronne de voisins recalés sur la grille (16)")
	got.clear()
	gs.work_cell(Vector2i(1, 6), gs.Dig.FLATTEN, gs.terrain.cell_level(Vector2i(1, 6)))
	assert_eq(got.size(), 0, "rien ne bouge : pas de signal")


func test_worked_sand_is_saved_and_new_game_resets_it() -> void:
	gs.work_cell(Vector2i(1, 6), gs.Dig.DIG)
	var level: float = gs.terrain.cell_level(Vector2i(1, 6))
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_almost(other.terrain.cell_level(Vector2i(1, 6)), level, 1e-4)
	other.new_game()
	assert_false(other.terrain.cell_worked(Vector2i(1, 6)))
	other.free()


func test_shovel_cell_of_point() -> void:
	assert_eq(ShovelTool.cell_of_point(Vector3(0.2, 0, -0.2), 1.0), Vector2i(0, -1))
	assert_eq(ShovelTool.cell_of_point(Vector3(-1.5, 0, 2.99), 1.0), Vector2i(-2, 2))


# --- Le sable se déplace (0.1.11) --------------------------------------------------------------

func _real_shovel() -> void:
	gs.config.shovel_capacity_scoops = 6
	gs.shovel_sand = 0


func test_digging_fills_the_shovel_and_filling_empties_it() -> void:
	_real_shovel()
	var a := Vector2i(1, 6)
	var b := Vector2i(-2, -5)
	assert_true(gs.work_cell(a, gs.Dig.DIG))
	assert_eq(gs.shovel_sand, 1)
	assert_true(gs.work_cell(b, gs.Dig.RAISE), "on repose le sable ailleurs")
	assert_eq(gs.shovel_sand, 0)
	assert_almost(gs.terrain.cell_level(b), gs.config.ground_y + gs.config.dig_step_m, 1e-4)
	assert_eq(gs.dig_reason(b, gs.config.ground_y + 2.0 * gs.config.dig_step_m), "PROMPT_DIG_SHOVEL_EMPTY")
	assert_false(gs.work_cell(b, gs.Dig.RAISE), "pelle vide : pas de sable qui sort de nulle part")


func test_a_full_shovel_cannot_dig_more() -> void:
	_real_shovel()
	var cell := Vector2i(1, 6)
	for i in 6:
		gs.work_cell(cell + Vector2i(i, 0), gs.Dig.DIG)
	assert_eq(gs.shovel_sand, 6)
	assert_eq(gs.dig_reason(Vector2i(1, 8), gs.config.ground_y - gs.config.dig_step_m), "PROMPT_DIG_SHOVEL_FULL")
	assert_false(gs.work_cell(Vector2i(1, 8), gs.Dig.DIG))


func test_flattening_takes_or_gives_one_scoop_per_step() -> void:
	_real_shovel()
	var cell := Vector2i(1, 6)
	var step: float = gs.config.dig_step_m
	var g: float = gs.config.ground_y
	gs.shovel_sand = 3
	assert_eq(gs.dig_scoops(cell, g + 2.0 * step), -2)
	assert_true(gs.work_cell(cell, gs.Dig.FLATTEN, g + 2.0 * step))
	assert_eq(gs.shovel_sand, 1, "2 crans remblayés")
	assert_true(gs.work_cell(cell, gs.Dig.FLATTEN, g - step))
	assert_eq(gs.shovel_sand, 4, "3 crans creusés")
	assert_eq(gs.dig_reason(cell, g + 4.0 * step), "PROMPT_DIG_SHOVEL_EMPTY", "il en faudrait 5")
	assert_eq(gs.dig_reason(cell, g + 3.0 * step), "")


func test_sand_moved_tells_the_animation_where_from_and_where_to() -> void:
	_real_shovel()
	var got := []
	gs.sand_moved.connect(func(cell, before, to_y, scoops): got.append([cell, before, to_y, scoops]))
	var order := []
	gs.sand_moved.connect(func(_a, _b, _c, _d): order.append("sand"))
	gs.terrain_changed.connect(func(_c): order.append("terrain"))
	gs.work_cell(Vector2i(1, 6), gs.Dig.DIG)
	assert_eq(got.size(), 1)
	assert_eq(got[0][0], Vector2i(1, 6))
	assert_eq((got[0][1] as Dictionary).size(), 9, "la hauteur d'avant de chaque sommet")
	assert_almost(float((got[0][1] as Dictionary).values()[0]), gs.config.ground_y, 0.05)
	assert_almost(got[0][2], gs.config.ground_y - gs.config.dig_step_m, 1e-4)
	assert_eq(got[0][3], 1)
	assert_eq(order, ["sand", "terrain"], "l'animation est prévenue avant la reconstruction")


func test_shovel_and_its_sand_are_saved() -> void:
	_real_shovel()
	gs.work_cell(Vector2i(1, 6), gs.Dig.DIG)
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_true(other.has_shovel)
	assert_eq(other.shovel_sand, 1)
	other.free()


func test_old_saves_keep_the_given_shovel_and_their_worked_sand() -> void:
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	# Une sauvegarde 0.1.10 : pas de has_shovel (la pelle était en barre), grille de 1 m.
	data["upgrades"].erase("has_shovel")
	data["upgrades"].erase("shovel_sand")
	data["upgrades"]["toolbar"] = ["seau", "pelle", "", "", "", ""]
	data.erase("terrain_sub")
	data["terrain"] = [[1, 6, 0.25], [2, 6, 0.25], [1, 7, 0.25], [2, 7, 0.25], [5, 5, 1.0]]
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_true(other.has_shovel)
	assert_almost(other.terrain.cell_level(Vector2i(1, 6)), 0.25, 1e-4, "la case aplanie reste plate")
	assert_almost(other.terrain.vertex(10, 10).y, 1.0, 1e-4, "un coin isolé garde sa hauteur")
	data["upgrades"]["toolbar"] = ["seau", "", "", "", "", ""]
	other.load_dict(data)
	assert_false(other.has_shovel)
	other.free()


func test_animated_heights_go_from_before_to_after() -> void:
	var before := {Vector2i(2, 2): 0.5, Vector2i(3, 2): 0.6}
	var start := TerrainView.anim_heights(before, 0.25, 0.0)
	assert_almost(start[Vector2i(3, 2)], 0.6, 1e-4)
	var end := TerrainView.anim_heights(before, 0.25, 1.0)
	assert_almost(end[Vector2i(2, 2)], 0.25, 1e-4)
	assert_almost(end[Vector2i(3, 2)], 0.25, 1e-4)
	var r := TerrainView.anim_rect(Vector2i(1, 6))
	assert_true(r.has_point(Vector2i(2, 12)) and r.has_point(Vector2i(1, 11)) and r.has_point(Vector2i(4, 14)), "la case et sa couronne")
	assert_eq(r.size, Vector2i(TerrainLogic.SUB + 2, TerrainLogic.SUB + 2))


func test_flying_clump_starts_and_lands_on_its_points() -> void:
	var a := Vector3(0, 0.5, 0)
	var b := Vector3(1, 1.5, 2)
	assert_true(SandFx.arc_point(a, b, 0.0, 0.4).is_equal_approx(a))
	assert_true(SandFx.arc_point(a, b, 1.0, 0.4).is_equal_approx(b))
	assert_true(SandFx.arc_point(a, b, 0.5, 0.4).y > (a.y + b.y) / 2.0, "en arc, au-dessus de la ligne droite")


# --- Les tuyaux suivent la hauteur des zones (0.1.10) -----------------------------------------

func test_pour_level_follows_the_zone_height() -> void:
	var basin: Dictionary = gs.zones[0]
	assert_eq(gs.pour_level_for(basin), gs.config.pour_level)
	var inlet: Rect2 = gs.inlet_rect(basin)
	var c := inlet.get_center()
	var cell := Vector3i(floori(c.x), gs.config.pour_level, floori(c.y))
	assert_true(gs.pipe_feeds(cell, basin))
	assert_eq(gs.pipe_preview(cell), "feeds")
	basin.position.y += 1.0  # posée sur du sable remonté d'un mètre
	assert_eq(gs.pour_level_for(basin), gs.config.pour_level + 1)
	assert_false(gs.pipe_feeds(cell, basin))
	assert_true(gs.pipe_feeds(cell + Vector3i(0, 1, 0), basin))


func test_pipe_preview_is_empty_far_from_everything() -> void:
	assert_eq(gs.pipe_preview(Vector3i(-12, 0, -12)), "")
