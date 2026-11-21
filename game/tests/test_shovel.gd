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
	assert_almost(gs.shovel_sand, 0.0, 1e-6, "elle arrive vide")


func test_flattening_makes_a_cell_flat_at_the_level_asked() -> void:
	var cell := _beach_cell()
	assert_true(is_nan(gs.terrain.cell_level(cell)), "la plage n'est pas plate au départ")
	assert_true(gs.flatten_cell(cell, 0.5))
	assert_almost(gs.terrain.cell_level(cell), 0.5, 1e-4)
	var c: float = gs.config.grid_cell_m
	assert_almost(gs.terrain.height((cell.x + 0.5) * c, (cell.y + 0.5) * c), 0.5, 1e-3, "le maillage suit")
	assert_true(gs.terrain.cell_worked(cell))


func test_cannot_dig_the_sea_or_under_an_object() -> void:
	assert_eq(gs.dig_reason(Vector2i(0, 40), 0.5), "PROMPT_DIG_WATER")
	var basin: Dictionary = gs.zones[0]
	var under := TerrainLogic.cell_of(basin.position.x, basin.position.z)
	assert_eq(gs.dig_reason(under, 0.25), "PROMPT_DIG_BLOCKED")
	assert_false(gs.flatten_cell(under, 0.25))
	var v := TerrainLogic.nearest_vertex(basin.position.x, basin.position.z)
	assert_eq(gs.scoop_reason(v, true), "PROMPT_DIG_BLOCKED")
	assert_false(gs.shovel_scoop(v, true))
	assert_eq(gs.scoop_reason(TerrainLogic.nearest_vertex(0.0, 40.0), true), "PROMPT_DIG_WATER")


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
	gs.flatten_cell(cell, 0.75)
	assert_true(gs.spot_ok("rations", pos, 0.0, gs.blockers_for({})), "posable une fois aplanie")
	assert_almost(gs.ground_level(gs.footprint_rect("rations", pos, 0.0)), 0.75, 1e-4)


func test_cells_at_different_levels_are_not_placeable_together() -> void:
	gs.flatten_cell(Vector2i(2, 4), 0.5)
	gs.flatten_cell(Vector2i(3, 4), 0.75)
	assert_true(is_nan(gs.ground_level(Rect2(2, 4, 2, 1))))
	assert_almost(gs.ground_level(Rect2(2, 4, 1, 1)), 0.5, 1e-4)


func test_worked_sand_is_saved_and_new_game_resets_it() -> void:
	gs.flatten_cell(Vector2i(1, 6), 0.25)
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
	gs.config.shovel_capacity_scoops = 3
	gs.shovel_sand = 0.0


func test_shovel_and_its_sand_are_saved() -> void:
	_real_shovel()
	gs.shovel_scoop(Vector2i(2, 12), true)
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_true(other.has_shovel)
	assert_almost(other.shovel_sand, 1.0, 1e-3)
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


func test_flying_clump_starts_and_lands_on_its_points() -> void:
	var a := Vector3(0, 0.5, 0)
	var b := Vector3(1, 1.5, 2)
	assert_true(SandFx.arc_point(a, b, 0.0, 0.4).is_equal_approx(a))
	assert_true(SandFx.arc_point(a, b, 1.0, 0.4).is_equal_approx(b))
	assert_true(SandFx.arc_point(a, b, 0.5, 0.4).y > (a.y + b.y) / 2.0, "en arc, au-dessus de la ligne droite")


# --- Du vrai sable (0.1.12) : pelletées comptées, éboulement --------------------------------------

## Le volume de sable autour d'un sommet (m³ au-dessus de y = 0), sur une fenêtre de ±r sommets.
func _volume(center: Vector2i, r: int = 14) -> float:
	var s := 0.0
	for j in range(-r, r + 1):
		for i in range(-r, r + 1):
			s += gs.terrain.vertex(center.x + i, center.y + j).y * SandPhysics.AREA
	return s


func _steepest_around(center: Vector2i, r: int = 10) -> float:
	var ctx: Dictionary = gs._sand_context()
	var vs := []
	for j in range(-r, r + 1):
		for i in range(-r, r + 1):
			vs.append(center + Vector2i(i, j))
	var read := func(k: Vector2i) -> float: return gs.terrain.vertex(k.x, k.y).y
	var can := func(k: Vector2i) -> bool: return gs._vertex_movable(k, ctx)
	return SandPhysics.steepest({}, read, can, vs)


## Un sommet du plateau de départ, loin des objets.
const SPOT := Vector2i(2, 12)


func test_left_click_digs_one_scoop_onto_the_shovel_and_right_click_puts_it_back() -> void:
	_real_shovel()
	var v0 := _volume(SPOT)
	assert_eq(gs.scoop_reason(SPOT, false), "PROMPT_DIG_SHOVEL_EMPTY", "rien à poser au départ")
	assert_true(gs.shovel_scoop(SPOT, true))
	assert_almost(gs.shovel_sand, 1.0, 1e-3, "une pelletée sur la pelle")
	assert_almost(v0 - _volume(SPOT), gs.config.dig_scoop_m3, 0.02, "exactement le sable enlevé du sol")
	assert_true(gs.terrain.vertex(SPOT.x, SPOT.y).y < gs.config.ground_y - 0.1, "un creux au centre")
	var other := SPOT + Vector2i(8, 0)
	var w0 := _volume(other)
	assert_true(gs.shovel_scoop(other, false), "on repose le sable ailleurs")
	assert_almost(gs.shovel_sand, 0.0, 1e-3)
	assert_almost(_volume(other) - w0, gs.config.dig_scoop_m3, 0.02, "tout le sable porté est reposé")
	assert_false(gs.shovel_scoop(other, false), "pelle vide : pas de sable qui sort de nulle part")


func test_the_shovel_holds_three_scoops_then_must_be_emptied() -> void:
	_real_shovel()
	for i in 3:
		assert_true(gs.shovel_scoop(SPOT + Vector2i(i * 4, 0), true))
	assert_almost(gs.shovel_sand, 3.0, 1e-3)
	assert_eq(gs.scoop_reason(SPOT + Vector2i(0, 4), true), "PROMPT_DIG_SHOVEL_FULL")
	assert_false(gs.shovel_scoop(SPOT + Vector2i(0, 4), true), "pelle pleine : on ne creuse plus")
	assert_true(gs.shovel_scoop(SPOT + Vector2i(0, 4), false), "on la vide")
	assert_almost(gs.shovel_sand, 2.0, 1e-3)


func test_flattening_counts_the_real_volume() -> void:
	_real_shovel()
	var cell := _beach_cell()
	var y: float = gs.flatten_level(cell)
	var need: float = gs.dig_scoops(cell, y)
	gs.shovel_sand = 2.0
	assert_true(gs.flatten_cell(cell, y))
	assert_almost(gs.shovel_sand, 2.0 + need, 1e-3, "le sable pris ou posé, au centième près")
	gs.shovel_sand = 0.0
	assert_eq(gs.dig_reason(cell, y + 0.5), "PROMPT_DIG_SHOVEL_EMPTY", "remonter demande du sable")


func test_a_deep_hole_caves_in_and_never_stands_steeper_than_sand() -> void:
	gs.shovel_sand = 0.0
	gs.config.dig_min_above_water_m = -5.0  # l'océan a déjà bien baissé : on peut creuser profond
	gs.config.sand_wet_band_m = -10.0  # et le sable est sec partout
	var limit := tan(deg_to_rad(gs.config.sand_repose_deg))
	for i in 16:
		gs.shovel_scoop(SPOT, true)
	assert_true(gs.terrain.vertex(SPOT.x, SPOT.y).y < gs.config.ground_y - 0.4, "un vrai trou")
	assert_true(_steepest_around(SPOT) <= limit + 0.05, "les bords se sont éboulés (pente %.2f)" % _steepest_around(SPOT))
	var far := SPOT + Vector2i(3, 0)  # à 1,5 m, hors de la pelletée
	assert_true(gs.terrain.vertex(far.x, far.y).y < gs.config.ground_y - 0.05, "le sable autour a glissé dans le trou")


func test_a_pile_spreads_into_a_cone() -> void:
	gs.shovel_sand = 50.0
	var limit := tan(deg_to_rad(gs.config.sand_repose_deg))
	var v0 := _volume(SPOT)
	for i in 20:
		gs.shovel_scoop(SPOT, false)
	assert_true(_steepest_around(SPOT) <= limit + 0.05, "pas plus raide que la pente d'éboulement")
	var far := SPOT + Vector2i(3, 0)  # à 1,5 m, hors de la pelletée
	assert_true(gs.terrain.vertex(far.x, far.y).y > gs.config.ground_y + 0.05, "le tas s'étale")
	assert_almost(_volume(SPOT) - v0, 20.0 * gs.config.dig_scoop_m3, 0.05, "aucun sable perdu dans l'éboulement")


func test_digging_stops_above_the_water() -> void:
	gs.shovel_sand = 0.0
	for i in 40:
		gs.shovel_scoop(SPOT, true)
	assert_true(gs.terrain.vertex(SPOT.x, SPOT.y).y >= gs.dig_floor_y() - 1e-4, "jamais sous l'eau")
	if gs.shovel_sand < gs.config.shovel_capacity_scoops - 0.05:
		assert_eq(gs.scoop_reason(SPOT, true), "PROMPT_DIG_TOO_DEEP")


func test_sand_under_an_object_holds() -> void:
	gs.shovel_sand = 0.0
	var basin: Dictionary = gs.zones[0]
	var rect: Rect2 = gs.item_rect(basin)
	var edge := TerrainLogic.nearest_vertex(rect.end.x + 1.0, rect.get_center().y)
	var inside := TerrainLogic.nearest_vertex(rect.end.x - 0.25, rect.get_center().y)
	var h0: float = gs.terrain.vertex(inside.x, inside.y).y
	for i in 8:
		gs.shovel_scoop(edge, true)
	assert_almost(gs.terrain.vertex(inside.x, inside.y).y, h0, 1e-5, "la cuvette ne s'enfonce pas")


func test_sand_moved_gives_before_and_after_before_the_rebuild() -> void:
	_real_shovel()
	var got := []
	var order := []
	gs.sand_moved.connect(func(center, before, after, scoops): got.append([center, before, after, scoops]); order.append("sand"))
	gs.terrain_changed.connect(func(_c): order.append("terrain"))
	gs.shovel_scoop(SPOT, true)
	assert_eq(got.size(), 1)
	var p := TerrainLogic.vertex_xz(SPOT)
	assert_almost((got[0][0] as Vector3).x, p.x, 1e-4)
	var before: Dictionary = got[0][1]
	var after: Dictionary = got[0][2]
	assert_true(after.has(SPOT) and before.has(SPOT))
	assert_true(float(after[SPOT]) < float(before[SPOT]))
	assert_almost(float(got[0][3]), 1.0, 1e-3)
	assert_eq(order, ["sand", "terrain"], "l'animation est prévenue avant la reconstruction")


func test_relax_alone_conserves_sand_and_respects_wet_sand() -> void:
	# Une colonne de sable de 2 m sur un sol plat : elle s'étale en cône, sans rien perdre.
	var h := {Vector2i(0, 0): 6.0}
	var read := func(_k: Vector2i) -> float: return 0.0
	var everywhere := func(k: Vector2i) -> bool: return absi(k.x) < 20 and absi(k.y) < 20
	var moved := SandPhysics.relax(h, read, everywhere, [Vector2i(0, 0)], 0.67, 0.67, -10.0)
	var total := 0.0
	for k in h:
		total += float(h[k])
	assert_almost(total, 6.0, 1e-6, "le volume ne change pas")
	assert_true(moved.size() > 9, "le sable a coulé plus loin que les voisins")
	assert_true(SandPhysics.steepest(h, read, everywhere, h.keys()) <= 0.67 + 0.02)
	# Mouillé, le même sable tient plus raide : le tas reste plus haut.
	var wet := {Vector2i(0, 0): 6.0}
	SandPhysics.relax(wet, read, everywhere, [Vector2i(0, 0)], 0.67, 1.2, 10.0)
	assert_true(float(wet[Vector2i(0, 0)]) > float(h[Vector2i(0, 0)]) + 0.1)


func test_carve_takes_less_where_the_floor_is_close() -> void:
	var w := SandPhysics.brush(Vector2i.ZERO, 1.2)
	assert_almost(float(w[Vector2i.ZERO]), 1.0, 1e-6)
	assert_false(w.has(Vector2i(3, 0)), "rayon de 1,2 m : pas à 1,5 m")
	var heights := {}
	for k in w:
		heights[k] = 0.5
	var full := SandPhysics.carve(heights, w, 0.25, true, 0.0, 9.0)
	assert_almost(float(full.volume), 0.25, 1e-4, "loin du plancher : une pelletée entière")
	heights[Vector2i.ZERO] = 0.05  # presque au plancher
	var r := SandPhysics.carve(heights, w, 0.25, true, 0.0, 9.0)
	assert_true(float(r.volume) < 0.25 and float(r.volume) > 0.15, "un peu moins de sable")
	assert_almost(float(r.heights[Vector2i.ZERO]), 0.0, 1e-6, "le centre s'arrête au plancher")
	assert_almost(float(r.heights[Vector2i(1, 0)]), float(full.heights[Vector2i(1, 0)]), 1e-6, "le reste comme d'habitude")


func test_animated_heights_go_from_before_to_after() -> void:
	var before := {Vector2i(2, 2): 0.5, Vector2i(3, 2): 0.6}
	var after := {Vector2i(2, 2): 0.25, Vector2i(3, 2): 0.3}
	var delays := {Vector2i(2, 2): 0.0, Vector2i(3, 2): 0.2}
	var start := TerrainView.anim_heights(before, after, delays, 0.0, 0.3)
	assert_almost(start[Vector2i(3, 2)], 0.6, 1e-4)
	var mid := TerrainView.anim_heights(before, after, delays, 0.15, 0.3)
	assert_almost(mid[Vector2i(3, 2)], 0.6, 1e-4, "le sable plus loin glisse après")
	var end := TerrainView.anim_heights(before, after, delays, 0.5, 0.3)
	assert_almost(end[Vector2i(2, 2)], 0.25, 1e-4)
	assert_almost(end[Vector2i(3, 2)], 0.3, 1e-4)
	var r := TerrainView.anim_rect([Vector2i(2, 12), Vector2i(5, 14)])
	assert_true(r.has_point(Vector2i(2, 12)) and r.has_point(Vector2i(0, 10)) and r.has_point(Vector2i(6, 15)), "les sommets et une couronne")


func test_smoothing_keeps_the_height_and_flattens_the_sand() -> void:
	const MID := Vector2i(3, 13)  # le centre d'une case de 1 m
	gs.shovel_sand = 10.0
	for i in 4:
		gs.shovel_scoop(MID, false)  # un petit tas
	var load_before: float = gs.shovel_sand
	var v0 := _volume(MID)
	var peak: float = gs.terrain.vertex(MID.x, MID.y).y
	assert_true(gs.smooth_sand(MID))
	assert_true(gs.terrain.vertex(MID.x, MID.y).y < peak, "le haut du tas baisse")
	assert_almost(_volume(MID), v0, 0.01, "même volume : on ne crée ni ne perd de sable")
	assert_almost(gs.shovel_sand, load_before, 1e-6, "la pelle ne change pas")
	for i in 30:
		gs.smooth_sand(MID)
	var cell := TerrainLogic.cell_of(TerrainLogic.vertex_xz(MID).x, TerrainLogic.vertex_xz(MID).y)
	assert_false(is_nan(gs.terrain.cell_level(cell)), "en insistant, le sable devient plat (posable)")


func test_shovel_load_text() -> void:
	assert_eq(ShovelTool.load_text(2.0), "2")
	assert_eq(ShovelTool.load_text(0.04), "0")


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
