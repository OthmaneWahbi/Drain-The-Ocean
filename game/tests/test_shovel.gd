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
	var o := cell * TerrainLogic.SUB + Vector2i(1, 1)
	gs.shovel_sand = 1.5
	var v0: float = _volume(o) + gs.shovel_sand * gs.config.dig_scoop_m3
	assert_true(gs.flatten_cell(cell, y))
	assert_almost(_volume(o) + gs.shovel_sand * gs.config.dig_scoop_m3, v0, 0.05, "le sable pris ou posé est sur la pelle")
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


func test_digging_inland_goes_deep() -> void:
	# 0.1.14 (Othmane : « on doit pouvoir creuser bien plus loin ») : à l'intérieur de l'île, la
	# mer est cachée et on creuse jusqu'à 3 m sous son niveau (avant : 30 cm sur le plateau).
	var p := TerrainLogic.vertex_xz(SPOT)
	assert_true(gs.terrain.inland(p.x, p.y))
	assert_almost(gs.dig_floor_at(p.x, p.y), gs.config.sea_level_y - gs.config.dig_max_below_sea_m, 1e-6)
	gs.shovel_sand = 0.0
	for i in 60:
		gs.shovel_scoop(SPOT, true)
		gs.shovel_sand = 0.0  # on vide la pelle ailleurs
	var y: float = gs.terrain.vertex(SPOT.x, SPOT.y).y
	assert_true(y < gs.config.ground_y - 1.0, "un vrai trou, bien plus profond qu'avant (%.2f)" % y)
	assert_true(y >= gs.dig_floor_at(p.x, p.y) - 1e-4, "jamais sous le plancher")
	assert_false(gs.sea_at(p.x, p.y), "pas de mer au fond du trou")


func test_digging_stops_above_the_water_at_the_shore() -> void:
	# Au bord de la mer (hors de l'intérieur de l'île), le plancher reste juste au-dessus de l'eau.
	for j in range(40, 80):
		var v := Vector2i(0, j)
		var p := TerrainLogic.vertex_xz(v)
		if gs.terrain.inland(p.x, p.y) or gs._spot_reason(p) != "":
			continue
		assert_true(gs.sea_at(p.x, p.y))
		assert_almost(gs.dig_floor_at(p.x, p.y), gs.dig_floor_y(), 1e-6)
		if gs.terrain.base_height(p.x, p.y) < gs.dig_floor_y() - 0.1:
			assert_eq(gs.scoop_reason(v, true), "PROMPT_DIG_TOO_DEEP", "le sable mouillé du rivage (%s)" % v)


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


# --- Finitions (0.1.13) ----------------------------------------------------------------------------

## Des milliers de gestes au hasard (creuser, poser, lisser, niveler) sur le plateau, la plage et
## autour de la cuvette : rien ne se crée ni ne se perd, les raisons de refus disent vrai, un
## geste permis marche, le sable reste entre ses bornes et ne bouge jamais sous un objet.
func test_thousands_of_random_shovel_gestures_keep_every_rule() -> void:
	_fuzz(Vector2i(0, 16), 22, 1234)  # le plateau, vers la plage, la cuvette


func test_random_shovel_gestures_at_the_water_edge() -> void:
	_fuzz(Vector2i(0, 66), 14, 99)  # la plage du sud, jusque dans l'eau


func _fuzz(center: Vector2i, r: int, rng_seed: int) -> void:
	_real_shovel()
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var basin: Dictionary = gs.zones[0]
	var brect: Rect2 = gs.item_rect(basin)
	var under := TerrainLogic.nearest_vertex(brect.get_center().x, brect.get_center().y)
	var under_h: float = gs.terrain.vertex(under.x, under.y).y
	var total0: float = _volume(center, r + 8) + gs.shovel_sand * gs.config.dig_scoop_m3
	var refused := {}
	var done := 0
	for step in 1500:
		var v := center + Vector2i(rng.randi_range(-r, r), rng.randi_range(-r, r))
		var kind := rng.randi_range(0, 9)
		var before_sand: float = gs.shovel_sand
		if kind <= 3 or kind <= 7:
			var dig := kind <= 3
			var why: String = gs.scoop_reason(v, dig)
			var ok: bool = gs.shovel_scoop(v, dig)
			if why == "":
				assert_true(ok, "un geste permis marche (%s, %s)" % [v, "creuser" if dig else "poser"])
				if dig:
					assert_true(gs.shovel_sand > before_sand, "creuser remplit la pelle")
				else:
					assert_true(gs.shovel_sand < before_sand, "poser vide la pelle")
				done += 1
				# Juste après avoir creusé, on peut toujours reposer au même endroit.
				if dig:
					assert_eq(gs.scoop_reason(v, false), "", "reposer là où on vient de creuser (%s)" % v)
			else:
				assert_false(ok, "un geste refusé ne change rien")
				assert_almost(gs.shovel_sand, before_sand, 1e-9)
				refused[why] = int(refused.get(why, 0)) + 1
				if why == "PROMPT_DIG_SHOVEL_EMPTY":
					assert_true(before_sand < 0.05)
				if why == "PROMPT_DIG_SHOVEL_FULL":
					assert_true(before_sand > gs.config.shovel_capacity_scoops - 0.05)
		elif kind == 8:
			gs.smooth_sand(v)
			assert_almost(gs.shovel_sand, before_sand, 1e-9, "lisser ne touche pas à la pelle")
		else:
			var cell := TerrainLogic.cell_of(TerrainLogic.vertex_xz(v).x, TerrainLogic.vertex_xz(v).y)
			gs.flatten_cell(cell, gs.flatten_level(cell))
		assert_true(gs.shovel_sand >= -1e-6 and gs.shovel_sand <= gs.config.shovel_capacity_scoops + 1e-6, "la pelle reste entre 0 et 3")
	# Les bornes et le sable sous la cuvette.
	for k: Vector2i in gs.terrain.edits:
		var y := float(gs.terrain.edits[k])
		assert_false(is_nan(y))
		assert_true(y <= gs.dig_ceil_y() + 1e-4, "jamais plus haut que le plafond")
	assert_almost(gs.terrain.vertex(under.x, under.y).y, under_h, 1e-6, "le sable sous la cuvette n'a pas bougé")
	for k: Vector2i in gs.terrain.edits:
		var p := TerrainLogic.vertex_xz(k)
		assert_true(p.length() <= gs.terrain.coast_at(atan2(p.y, p.x)) - 0.5 + 1e-3, "le sable de la mer ne bouge pas (%s : %.2f m, côte %.2f m, %.2f)" % [k, p.length(), gs.terrain.coast_at(atan2(p.y, p.x)), float(gs.terrain.edits[k])])
	# Le sable total (sol + pelle) n'a pas changé. La seule dérive : les sommets recalés sur la
	# grille (on enlève leur petit décalage au hasard), quelques centimètres cubes.
	var total1: float = _volume(center, r + 8) + gs.shovel_sand * gs.config.dig_scoop_m3
	assert_almost(total1, total0, 0.6, "le sable ne se crée ni ne se perd")
	assert_true(done > 150, "assez de gestes réussis (%d)" % done)
	print("    gestes réussis : %d, refus : %s" % [done, refused])


func test_level_blends_its_edges_into_the_sand_around() -> void:
	_real_shovel()
	var cell := _beach_cell()
	var level: float = gs.flatten_level(cell) - gs.config.dig_step_m  # creusée d'un cran
	var o := cell * TerrainLogic.SUB
	var outside := [o + Vector2i(3, 1), o + Vector2i(-1, 1), o + Vector2i(1, 3), o + Vector2i(1, -1)]
	var gap_before := 0.0
	for v: Vector2i in outside:
		gap_before += absf(gs.terrain.vertex(v.x, v.y).y - level)
	var v0 := _volume(o + Vector2i(1, 1))
	assert_true(gs.flatten_cell(cell, level))
	var gap_after := 0.0
	for v: Vector2i in outside:
		gap_after += absf(gs.terrain.vertex(v.x, v.y).y - level)
	assert_true(gap_after < gap_before - 0.05, "le sable autour descend vers la case : une rampe (%.2f -> %.2f)" % [gap_before, gap_after])
	assert_almost(gs.terrain.cell_level(cell), level, 1e-4, "la case reste plate")
	assert_almost(_volume(o + Vector2i(1, 1)) + gs.shovel_sand * gs.config.dig_scoop_m3, v0, 0.05, "le sable du fondu est compté sur la pelle")


func test_level_drag_keeps_its_neighbour_flat() -> void:
	_real_shovel()
	gs.shovel_sand = 1.5
	gs.flatten_cell(Vector2i(1, 6), 0.5)
	gs.flatten_cell(Vector2i(2, 6), 0.5)
	gs.flatten_cell(Vector2i(3, 6), 0.5)
	for c in [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)]:
		assert_almost(gs.terrain.cell_level(c), 0.5, 1e-4, "le fondu ne défait pas une case déjà nivelée")


func test_the_shovel_load_is_shown_in_its_slot() -> void:
	_real_shovel()
	gs.shovel_sand = 1.5
	assert_eq(ShovelTool.load_text(1.5).replace(",", "."), "1.5")


func test_the_sea_is_hidden_inside_the_island() -> void:
	var tex := OceanView.land_mask(gs.terrain, gs.config.sea_level_y + gs.config.land_mask_above_sea_m)
	var img := tex.get_image()
	var mid := OceanView.MASK_PX / 2
	assert_true(img.get_pixel(mid, mid).r > 0.5, "au milieu de l'île : pas d'eau")
	assert_true(img.get_pixel(2, 2).r < 0.5, "au large : l'eau")


func test_sand_heap_on_the_shovel_is_a_dome() -> void:
	var mesh := Props.sand_heap_mesh(0.1, 0.13, 0.11)
	var aabb := mesh.get_aabb()
	assert_almost(aabb.size.y, 0.11, 0.03, "hauteur du tas")
	assert_true(aabb.position.y >= -1e-4, "posé sur la lame, pas dessous")


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


# --- 0.1.14 : le sable fluide et profond ------------------------------------------------------

func test_a_high_heap_of_sand_never_turns_green() -> void:
	# Othmane : « le sable posé devient vert à partir d'une certaine hauteur ».
	var heights := {}
	for j in range(10, 18):
		for i in range(-30, -22):
			heights[Vector2i(i, j)] = gs.config.ground_y + 3.0
	gs.terrain.set_vertices(heights)
	var built := TerrainView.build_rect(gs.terrain, Rect2i(-29, 11, 6, 6), null)
	var mesh: ArrayMesh = built.mesh
	var cols: PackedColorArray = mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	assert_true(cols.size() > 0)
	for c in cols:
		assert_true(c.g < c.r, "du sable, pas de l'herbe (%s)" % c)


func test_redrawing_only_the_touched_cells_gives_the_same_terrain() -> void:
	# Un coup de pelle ne refait que les cases touchées : le résultat doit être celui d'un
	# morceau refait en entier.
	var rect := Rect2i(-16, 16, TerrainView.CHUNK, TerrainView.CHUNK)
	var data := TerrainView.new_arrays(rect, true)
	TerrainView.fill(gs.terrain, rect, rect, [], {}, data)
	var changed: Array = []
	for k in 6:
		gs.shovel_scoop(Vector2i(-4 + k, 24), k % 2 == 0)
	for k: Vector2i in gs.terrain.edits:
		changed.append(k)
	changed.append_array(gs.terrain.pinned_vertices())
	TerrainView.fill(gs.terrain, rect, TerrainView.dirty_rect(changed), [], {}, data)
	var full := TerrainView.new_arrays(rect, true)
	TerrainView.fill(gs.terrain, rect, rect, [], {}, full)
	assert_eq(data.verts, full.verts, "mêmes sommets")
	assert_eq(data.cols, full.cols, "mêmes couleurs")
	assert_eq(data.faces, full.faces, "même collision")


func test_a_hidden_cell_is_flat_but_keeps_its_collision() -> void:
	var rect := Rect2i(0, 0, 4, 4)
	var data := TerrainView.new_arrays(rect, true)
	TerrainView.fill(gs.terrain, rect, rect, [Rect2i(1, 1, 1, 1)], {}, data)
	var base := (1 * 4 + 1) * 6
	for q in 6:
		assert_eq(data.verts[base + q], data.verts[base], "case cachée : triangles plats")
	var faces: PackedVector3Array = data.faces[0]
	var fb := (1 * TerrainView.COL_BLOCK + 1) * 6  # la collision est rangée par blocs
	assert_true(faces[fb] != faces[fb + 2], "la collision garde la case")


func test_sea_is_only_outside_the_island() -> void:
	assert_false(gs.sea_at(0.0, 0.0), "le centre de l'île")
	assert_true(gs.sea_at(0.0, 60.0), "le large")


func test_dragging_the_level_steps_through_every_cell() -> void:
	var a := Vector2i(0, 0)
	var path := []
	while a != Vector2i(3, -2):
		a = ShovelTool.step_toward(a, Vector2i(3, -2))
		path.append(a)
	assert_eq(path, [Vector2i(1, -1), Vector2i(2, -2), Vector2i(3, -2)])


func test_pipes_are_redrawn_only_when_their_sand_moves() -> void:
	var pipes := {Vector3i(5, 0, 5): true}
	var pv: Script = load("res://scenes/world/pipes_view.gd")
	assert_true(pv.pipes_touched(pipes, [Vector2i(10, 10)]), "un coin de sa case")
	assert_false(pv.pipes_touched(pipes, [Vector2i(30, 30)]), "loin")


func test_a_big_relax_stays_fast_and_exact() -> void:
	# Un grand tas : 120 pelletées au même endroit (volume exact, pente tenue, en temps court).
	gs.config.sand_wet_band_m = -10.0
	var v0 := _volume(SPOT, 14)
	var t0 := Time.get_ticks_msec()
	for i in 120:
		gs.shovel_sand = 1.0
		gs.shovel_scoop(SPOT, false)
	var dt := Time.get_ticks_msec() - t0
	assert_almost(_volume(SPOT, 14) - v0, 120.0 * gs.config.dig_scoop_m3, 0.2, "rien ne se perd")
	assert_true(_steepest_around(SPOT) <= tan(deg_to_rad(gs.config.sand_repose_deg)) + 0.05)
	assert_true(dt < 120 * 40, "moins de 40 ms par pelletée en moyenne, même en CI (%d ms)" % dt)
