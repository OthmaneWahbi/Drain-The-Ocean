extends TestCase
## La pelle (0.1.10, remarque 5) : aplanir, creuser, remonter le sable pour poser où on veut.

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	gs.setup(cfg)


func after_each() -> void:
	gs.free()


## Une case de la plage, hors du plateau de départ, loin de tout objet.
func _beach_cell() -> Vector2i:
	for j in range(24, 27):
		var cell := Vector2i(-6, j)
		if gs.dig_reason(cell, 0.5) == "" and is_nan(gs.terrain.cell_level(cell)):
			return cell
	return Vector2i(-6, 25)


func test_the_shovel_is_a_starting_tool() -> void:
	assert_true(gs.owns_tool("pelle"))
	assert_true(gs.toolbar.index_of("pelle") >= 0)


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
	assert_eq(got.size(), 4)
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
