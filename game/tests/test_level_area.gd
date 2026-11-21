extends TestCase
## 0.1.15 : aplanir plus simple (un carré de 3 × 3 m, niveau choisi tout seul) et des bords de
## trou arrondis (lissage du sable qui s'éboule, sans pointes).

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


## Le centre d'un carré de plage sans sol plat autour, que l'on peut aplanir en entier.
func _beach_center() -> Vector2i:
	for j in range(18, 40):
		for i in range(-12, 12):
			var c := Vector2i(i, j)
			var ok := true
			for dj in range(-3, 4):
				for di in range(-3, 4):
					if not is_nan(gs.terrain.cell_level(c + Vector2i(di, dj))):
						ok = false
			if not ok:
				continue
			var blockers: Array = gs._dig_blockers()
			for k: Vector2i in gs.level_area(c):
				if gs._cell_reason(k, 0.5, blockers) != "":
					ok = false
			if ok:
				return c
	assert_true(false, "pas de carré de plage trouvé")
	return Vector2i(-6, 25)


func _area_mean(c: Vector2i) -> float:
	var s := 0.0
	for k: Vector2i in gs.level_area(c):
		s += gs.terrain.cell_mean(k)
	return s / 9.0


func _volume(center: Vector2i, r: int = 14) -> float:
	var s := 0.0
	var o: Vector2i = center * TerrainLogic.SUB
	for j in range(-r, r + 1):
		for i in range(-r, r + 1):
			s += gs.terrain.vertex(o.x + i, o.y + j).y * SandPhysics.AREA
	return s


func test_soften_keeps_the_volume_and_rounds_a_spike() -> void:
	var h := {}
	for j in range(-3, 4):
		for i in range(-3, 4):
			h[Vector2i(i, j)] = 0.0
	h[Vector2i.ZERO] = 1.0
	var read := func(k: Vector2i) -> float: return 0.0
	var can := func(k: Vector2i) -> bool: return absi(k.x) <= 3 and absi(k.y) <= 3
	var before := 0.0
	for k: Vector2i in h:
		before += float(h[k])
	var changed := SandPhysics.soften(h, read, can, [Vector2i.ZERO], 4, 0.2)
	var after := 0.0
	for k: Vector2i in h:
		after += float(h[k])
	assert_almost(after, before, 1e-9, "le lissage ne crée ni ne perd de sable")
	assert_true(float(h[Vector2i.ZERO]) < 1.0, "la pointe s'arrondit")
	assert_true(float(h[Vector2i(1, 0)]) > 0.0, "et se répand autour")
	assert_true(changed.has(Vector2i(1, 1)), "les diagonales aussi (bord rond, pas en croix)")


func test_soften_never_moves_locked_vertices() -> void:
	var h := {Vector2i.ZERO: 1.0, Vector2i(1, 0): 0.0}
	var read := func(k: Vector2i) -> float: return 0.0
	var can := func(k: Vector2i) -> bool: return true
	SandPhysics.soften(h, read, can, [Vector2i.ZERO], 3, 0.2, {Vector2i.ZERO: true})
	assert_almost(float(h[Vector2i.ZERO]), 1.0, 1e-9)


func test_a_dug_hole_has_no_far_flung_spikes() -> void:
	# Les sommets que l'éboulement ne touche qu'au millimètre restent intacts (ils dessinaient
	# une étoile de « sable travaillé » autour du trou).
	var v := Vector2i(4, 26)
	gs.shovel_sand = 0.0
	for i in 8:
		gs.shovel_scoop(v, true)
		gs.shovel_sand = 0.0
	for j in range(-12, 13):
		for i in range(-12, 13):
			var k := v + Vector2i(i, j)
			if gs.terrain.edits.has(k) and Vector2(i, j).length() > 9.0:
				assert_true(false, "un sommet loin du trou compte comme travaillé : %s" % k)
				return


func test_auto_level_takes_a_close_flat_neighbour() -> void:
	var c := _beach_center()
	var mean := _area_mean(c)
	var n := c + Vector2i(3, 0)
	var lev: float = gs.level_snap(mean) + 0.1
	assert_true(gs.flatten_cell(n, lev), "un sol plat juste à côté")
	var auto: Array = gs.auto_level(c)
	assert_true(bool(auto[1]), "le niveau du voisin est proche : on le prend")
	assert_almost(float(auto[0]), gs.terrain.cell_level(n), 1e-4, "exactement le même niveau")


func test_auto_level_uses_the_area_mean_otherwise() -> void:
	var c := _beach_center()
	var auto: Array = gs.auto_level(c)
	assert_false(bool(auto[1]), "aucun sol plat autour")
	assert_almost(float(auto[0]), _area_mean(c), gs.config.level_step_m * 0.5 + 1e-4, "la hauteur moyenne du carré")


func test_flatten_area_levels_the_whole_square_in_one_gesture() -> void:
	var c := _beach_center()
	var y := float(gs.auto_level(c)[0])
	var moved := [0]
	gs.sand_moved.connect(func(_a: Vector3, _b: Dictionary, _c: Dictionary, _d: float) -> void: moved[0] += 1)
	assert_true(gs.flatten_area(c, y))
	assert_eq(moved[0], 1, "un seul geste (une seule animation)")
	for k: Vector2i in gs.level_area(c):
		assert_almost(gs.terrain.cell_level(k), y, 1e-4, "case %s plate au niveau" % k)
	assert_eq(gs.sand_gesture, gs.Gesture.SCOOP, "le geste revient à la pelletée")


func test_flatten_area_at_the_mean_barely_needs_the_shovel() -> void:
	gs.config.shovel_capacity_scoops = 3
	gs.shovel_sand = 1.5
	var c := _beach_center()
	var v0 := _volume(c)
	var y := float(gs.auto_level(c)[0])
	assert_true(gs.flatten_area(c, y))
	assert_true(absf(gs.shovel_sand - 1.5) < 1.5, "la moyenne : la pelle prend ou rend peu (%.2f)" % gs.shovel_sand)
	assert_almost(_volume(c) + (gs.shovel_sand - 1.5) * gs.config.dig_scoop_m3, v0, 0.05, "le sable est compté")


func test_flatten_area_keeps_what_fits_in_the_shovel() -> void:
	gs.config.shovel_capacity_scoops = 3
	gs.shovel_sand = 3.0  # pelle pleine
	var c := _beach_center()
	var y: float = gs.level_snap(_area_mean(c)) - 0.2  # tout est à creuser
	var plan: Array = gs.level_plan(c, y)
	assert_true((plan[0] as Array).is_empty())
	assert_eq(plan[2], "PROMPT_DIG_SHOVEL_FULL")
	assert_false(gs.flatten_area(c, y))
	gs.shovel_sand = 1.0
	plan = gs.level_plan(c, y)
	var cells: Array = plan[0]
	assert_true(cells.size() > 0 and cells.size() < 9, "les cases qui tiennent (%d)" % cells.size())
	assert_true(cells.has(c), "le centre d'abord")
	assert_true(gs.shovel_sand + float(plan[1]) <= 3.01)


func test_level_animation_is_smooth_without_bounce() -> void:
	var before := {Vector2i.ZERO: 1.0}
	var after := {Vector2i.ZERO: 0.0}
	var last := 1.0
	for i in 11:
		var y: float = TerrainView.anim_heights(before, after, {}, i * 0.016, 0.16, true)[Vector2i.ZERO]
		assert_true(y <= last + 1e-6 and y >= -1e-6, "descend sans dépasser (%.3f)" % y)
		last = y
	assert_almost(last, 0.0, 1e-4)
