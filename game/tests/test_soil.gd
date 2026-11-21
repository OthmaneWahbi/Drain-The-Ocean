extends TestCase
## 0.1.16 (demande d'Othmane) : les zones vertes sont de la terre. On la creuse, la porte et la
## pose comme le sable ; la terre va sur le sable et le sable sur la terre ; l'herbe ne disparaît
## que là où l'on a vraiment travaillé ; une pente d'origine ne s'éboule pas toute seule.

const GameStateScript := preload("res://core/game_state.gd")
const HudScript := preload("res://scenes/ui/hud.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	cfg.shovel_capacity_scoops = 3
	gs.setup(cfg)
	gs.has_shovel = true
	gs._sync_toolbar()
	gs.shovel_sand = 0.0


func after_each() -> void:
	gs.free()


## Un sommet d'herbe au milieu de l'herbe (tous ses voisins à 1 m aussi), qu'on peut creuser.
func _grass_vertex() -> Vector2i:
	var best := Vector2i.ZERO
	var best_d := INF
	for j in range(-80, 80):
		for i in range(-80, 80):
			var v := Vector2i(i, j)
			if Vector2(v).length() >= best_d or not gs.terrain.grassy(v):
				continue
			var ok := true
			for dj in range(-2, 3):
				for di in range(-2, 3):
					if not gs.terrain.grassy(v + Vector2i(di, dj)):
						ok = false
			if ok and gs.scoop_reason(v, true) == "":
				best = v
				best_d = Vector2(v).length()
	assert_true(best_d < INF, "pas d'herbe trouvée")
	return best


## Un sommet de sable sec, loin de l'herbe et des objets, qu'on peut creuser.
func _sand_vertex() -> Vector2i:
	return Vector2i(2, 12)


func _grassy_set(c: Vector2i, r: int) -> Dictionary:
	var out := {}
	for j in range(-r, r + 1):
		for i in range(-r, r + 1):
			var v := c + Vector2i(i, j)
			if gs.terrain.grassy(v):
				out[v] = true
	return out


func _volume(center: Vector2i, r: int) -> float:
	var s := 0.0
	for j in range(-r, r + 1):
		for i in range(-r, r + 1):
			s += gs.terrain.vertex(center.x + i, center.y + j).y * SandPhysics.AREA
	return s


# --- La matière d'origine ---------------------------------------------------------------------

func test_green_dune_tops_are_earth_and_the_plateau_is_sand() -> void:
	var g := _grass_vertex()
	assert_eq(gs.terrain.soil(g), TerrainLogic.Soil.EARTH)
	assert_true(gs.terrain.base_vertex(g.x, g.y).y > gs.config.ground_y + 0.9, "en haut d'une dune")
	assert_eq(gs.terrain.soil(_sand_vertex()), TerrainLogic.Soil.SAND)
	assert_false(gs.terrain.grassy(_sand_vertex()))


func test_base_soil_never_depends_on_the_current_height() -> void:
	var g := _grass_vertex()
	var before: Array = gs.terrain.base_soil_info(g).duplicate()
	gs.terrain.set_vertices({g: 0.0})
	assert_eq(gs.terrain.base_soil_info(g), before, "creuser ne change pas ce qu'il y avait")
	assert_eq(gs.terrain.soil(g), TerrainLogic.Soil.EARTH, "sous l'herbe, encore de la terre")
	assert_false(gs.terrain.grassy(g), "mais plus d'herbe : on a travaillé")


# --- Creuser, porter, poser -------------------------------------------------------------------

func test_digging_earth_puts_earth_on_the_shovel() -> void:
	var g := _grass_vertex()
	assert_true(gs.shovel_scoop(g, true))
	assert_eq(gs.shovel_soil, TerrainLogic.Soil.EARTH)
	assert_true(gs.shovel_sand > 0.9)
	assert_eq(HudScript.shovel_load_key(gs.shovel_sand, gs.shovel_soil), "HUD_SHOVEL_LOAD_EARTH", "la barre dit « Terre »")


func test_digging_sand_puts_sand_on_the_shovel() -> void:
	assert_true(gs.shovel_scoop(_sand_vertex(), true))
	assert_eq(gs.shovel_soil, TerrainLogic.Soil.SAND)
	assert_eq(HudScript.shovel_load_key(gs.shovel_sand, gs.shovel_soil), "HUD_SHOVEL_LOAD")


func test_the_shovel_never_mixes_earth_and_sand() -> void:
	var g := _grass_vertex()
	assert_true(gs.shovel_scoop(_sand_vertex(), true))
	assert_eq(gs.scoop_reason(g, true), "PROMPT_SHOVEL_HAS_SAND")
	assert_false(gs.shovel_scoop(g, true))
	assert_almost(gs.shovel_sand, 1.0, 1e-3, "rien de pris")
	# Une fois vidée, elle prend la terre.
	gs.shovel_sand = 0.0
	assert_true(gs.shovel_scoop(g, true))
	assert_eq(gs.scoop_reason(_sand_vertex(), true), "PROMPT_SHOVEL_HAS_EARTH")


func test_earth_goes_on_sand_and_can_be_dug_back() -> void:
	var g := _grass_vertex()
	for k in 2:
		gs.shovel_scoop(g, true)
	assert_eq(gs.shovel_soil, TerrainLogic.Soil.EARTH)
	var s := _sand_vertex()
	var h0: float = gs.terrain.vertex(s.x, s.y).y
	assert_true(gs.shovel_scoop(s, false))
	assert_true(gs.terrain.vertex(s.x, s.y).y > h0 + 0.05, "un petit tas")
	assert_eq(gs.terrain.soil(s), TerrainLogic.Soil.EARTH, "de la terre sur le sable")
	assert_false(gs.terrain.grassy(s), "de la terre retournée, sans herbe")
	# La pelle encore à moitié pleine de terre : on reprend ce tas de terre.
	assert_eq(gs.scoop_reason(s, true), "", "reprendre la terre posée")
	gs.shovel_sand = 0.0
	# On creuse jusqu'à repasser sous le sol d'origine : on retrouve le sable.
	for k in 6:
		gs.shovel_scoop(s, true)
		if gs.terrain.soil(s) == TerrainLogic.Soil.SAND:
			break
		gs.shovel_sand = 0.0
	assert_true(gs.terrain.vertex(s.x, s.y).y <= gs.terrain.base_vertex(s.x, s.y).y + 0.005)
	assert_eq(gs.terrain.soil(s), TerrainLogic.Soil.SAND, "sous la terre posée, le sable d'origine")


func test_sand_goes_on_grass() -> void:
	var g := _grass_vertex()
	gs.shovel_scoop(_sand_vertex(), true)
	assert_true(gs.shovel_scoop(g, false))
	assert_eq(gs.terrain.soil(g), TerrainLogic.Soil.SAND, "du sable sur la terre")
	assert_false(gs.terrain.grassy(g))


func test_every_raised_vertex_gets_what_was_dropped() -> void:
	var g := _grass_vertex()
	gs.shovel_scoop(g, true)
	gs.shovel_scoop(g, true)
	var s := _sand_vertex()
	var before := {}
	for j in range(-8, 9):
		for i in range(-8, 9):
			var v := s + Vector2i(i, j)
			before[v] = gs.terrain.vertex(v.x, v.y).y
	assert_true(gs.shovel_scoop(s, false))
	var raised := 0
	for v: Vector2i in before:
		if gs.terrain.edits.has(v) and gs.terrain.vertex(v.x, v.y).y > float(before[v]) + 0.003:
			raised += 1
			assert_eq(gs.terrain.soil(v), TerrainLogic.Soil.EARTH, "monté : de la terre (%s)" % v)
	assert_true(raised > 5)


# --- L'herbe ne disparaît plus au hasard --------------------------------------------------------

func test_grass_only_goes_where_the_ground_was_worked() -> void:
	var g := _grass_vertex()
	var edits0: Dictionary = gs.terrain.edits.duplicate()
	var grass0 := _grassy_set(g, 30)
	# Creuser et poser tout près de l'herbe, puis lisser et aplanir.
	gs.shovel_scoop(g + Vector2i(4, 0), true)
	gs.shovel_scoop(g + Vector2i(-6, 2), false)
	gs.smooth_sand(g + Vector2i(0, 5))
	var cell := TerrainLogic.cell_of(TerrainLogic.vertex_xz(g).x, TerrainLogic.vertex_xz(g).y)
	gs.config.shovel_capacity_scoops = 1000
	gs.flatten_area(cell + Vector2i(3, 3), float(gs.auto_level(cell + Vector2i(3, 3))[0]))
	var lost := 0
	for v: Vector2i in grass0:
		if not gs.terrain.grassy(v):
			lost += 1
			assert_true(gs.terrain.edits.has(v) and not edits0.has(v), "l'herbe n'est partie que là où l'on a travaillé (%s)" % v)
	assert_true(lost > 0, "on a bien travaillé dans l'herbe")
	assert_true(lost < grass0.size() / 2, "pas toute l'herbe (%d sur %d)" % [lost, grass0.size()])


func test_a_natural_slope_does_not_collapse_by_itself() -> void:
	# Une pelletée sur une dune ne fait plus s'ébouler toute la dune (et disparaître son herbe).
	var g := _grass_vertex()
	assert_true(gs.shovel_scoop(g, true))
	for v: Vector2i in gs.terrain.edits:
		assert_true((v - g).length() < 10.0, "rien ne bouge à plus de 5 m (%s)" % v)


func test_earth_holds_steeper_than_sand() -> void:
	gs.config.shovel_capacity_scoops = 1000
	var g := _grass_vertex()
	for k in 6:
		gs.shovel_scoop(g, true)
	gs.shovel_sand = 40.0
	var s := _sand_vertex()
	for k in 30:
		gs.shovel_scoop(s, false)
	var ctx: Dictionary = gs._sand_context()
	var vs := []
	for j in range(-10, 11):
		for i in range(-10, 11):
			vs.append(s + Vector2i(i, j))
	var read := func(k: Vector2i) -> float: return gs.terrain.vertex(k.x, k.y).y
	var can := func(k: Vector2i) -> bool: return gs._vertex_movable(k, ctx)
	var steep := SandPhysics.steepest({}, read, can, vs)
	assert_true(steep > tan(deg_to_rad(gs.config.sand_repose_deg)) + 0.05, "un tas de terre tient plus raide que le sable (%.2f)" % steep)
	assert_true(steep <= tan(deg_to_rad(gs.config.earth_repose_deg)) + 0.08, "mais pas plus que la terre (%.2f)" % steep)


func test_relax_keeps_a_natural_slope_and_still_moves_new_sand() -> void:
	# Une marche d'origine de 1 m sur 0,5 m (bien plus raide que 34°) tient ; un tas posé dessus glisse.
	var base := {}
	for j in range(-6, 7):
		for i in range(-6, 7):
			base[Vector2i(i, j)] = 1.0 if i < 0 else 0.0
	var read := func(k: Vector2i) -> float: return float(base.get(k, 0.0))
	var can := func(k: Vector2i) -> bool: return absi(k.x) <= 5 and absi(k.y) <= 5
	var land := func(k: Vector2i) -> Vector2: return Vector2(float(base.get(k, 0.0)), 0.0)
	var tan34 := tan(deg_to_rad(34.0))
	var h := {}
	var moved := SandPhysics.relax(h, read, can, [Vector2i(-1, 0), Vector2i(0, 0)], tan34, tan34, -10.0, {}, 60000, land)
	assert_true(moved.is_empty(), "la marche d'origine tient")
	h = {Vector2i(-1, 0): 2.0}
	moved = SandPhysics.relax(h, read, can, [Vector2i(-1, 0)], tan34, tan34, -10.0, {}, 60000, land)
	assert_true(float(h[Vector2i(-1, 0)]) < 2.0, "le sable posé en haut glisse")


# --- Aplanir et lisser --------------------------------------------------------------------------

func test_flattening_earth_takes_earth() -> void:
	gs.config.shovel_capacity_scoops = 1000
	var g := _grass_vertex()
	var cell := TerrainLogic.cell_of(TerrainLogic.vertex_xz(g).x, TerrainLogic.vertex_xz(g).y)
	var y: float = gs.level_snap(gs.terrain.cell_mean(cell)) - 0.3
	assert_true(gs.flatten_cell(cell, y))
	assert_eq(gs.shovel_soil, TerrainLogic.Soil.EARTH, "le dessus raboté était de la terre")
	for v in TerrainLogic.cell_vertices(cell):
		assert_eq(gs.terrain.soil(v), TerrainLogic.Soil.EARTH, "une case de terre aplanie reste de la terre")


func test_flattening_refuses_to_mix_with_the_shovel_load() -> void:
	gs.config.shovel_capacity_scoops = 1000
	var g := _grass_vertex()
	gs.shovel_scoop(_sand_vertex(), true)
	var cell := TerrainLogic.cell_of(TerrainLogic.vertex_xz(g).x, TerrainLogic.vertex_xz(g).y)
	var y: float = gs.level_snap(gs.terrain.cell_mean(cell)) - 0.3
	assert_eq(gs.dig_reason(cell, y), "PROMPT_SHOVEL_HAS_SAND")
	assert_eq(gs.level_plan(cell, y)[2], "PROMPT_SHOVEL_HAS_SAND")
	assert_false(gs.flatten_area(cell, y))


func test_smoothing_earth_keeps_earth() -> void:
	var g := _grass_vertex()
	gs.smooth_sand(g)
	for j in range(-3, 4):
		for i in range(-3, 4):
			var v := g + Vector2i(i, j)
			if gs.terrain.edits.has(v) and gs.terrain.base_soil(v) == TerrainLogic.Soil.EARTH:
				assert_eq(gs.terrain.soil(v), TerrainLogic.Soil.EARTH, "pas de sable venu de nulle part (%s)" % v)


# --- Sauvegarde ---------------------------------------------------------------------------------

func test_soil_and_shovel_load_are_saved() -> void:
	var g := _grass_vertex()
	gs.shovel_scoop(g, true)
	gs.shovel_scoop(g, true)
	gs.shovel_scoop(_sand_vertex(), false)
	assert_false(gs.terrain.cover.is_empty())
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(other.shovel_soil, TerrainLogic.Soil.EARTH)
	assert_almost(other.shovel_sand, gs.shovel_sand, 1e-3)
	assert_eq(other.terrain.cover.size(), gs.terrain.cover.size())
	for v: Vector2i in gs.terrain.cover:
		assert_eq(other.terrain.soil(v), gs.terrain.soil(v))
	for v: Vector2i in _grassy_set(g, 12):
		assert_true(other.terrain.grassy(v))
	other.free()


func test_old_saves_have_no_cover_and_carry_sand() -> void:
	gs.shovel_scoop(_sand_vertex(), true)
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	data.erase("soil_cover")
	data["upgrades"].erase("shovel_soil")
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(other.shovel_soil, TerrainLogic.Soil.SAND)
	assert_true(other.terrain.cover.is_empty())
	other.free()


func test_new_game_forgets_the_cover() -> void:
	var g := _grass_vertex()
	gs.shovel_scoop(g, true)
	gs.shovel_scoop(_sand_vertex(), false)
	gs.new_game()
	assert_true(gs.terrain.cover.is_empty())
	assert_true(gs.terrain.grassy(g), "l'herbe revient")
	assert_eq(gs.shovel_soil, TerrainLogic.Soil.SAND)


# --- Le dessin ----------------------------------------------------------------------------------

func test_the_mesh_paints_grass_earth_and_sand() -> void:
	var g := _grass_vertex()
	var t: TerrainLogic = gs.terrain
	gs.shovel_scoop(g + Vector2i(0, 0), true)
	var rect := Rect2i(g - Vector2i(6, 6), Vector2i(12, 12))
	var data := TerrainView.new_arrays(rect, false)
	TerrainView.fill(t, rect, rect, [], {}, data)
	var cols: PackedColorArray = data.cols
	var uvs: PackedVector2Array = data.uvs
	var verts: PackedVector3Array = data.verts
	var seen := {"grass": 0, "earth": 0}
	for q in verts.size():
		var v := TerrainLogic.nearest_vertex(verts[q].x, verts[q].z)
		if t.grassy(v):
			assert_true(uvs[q].y > 0.5 and cols[q].g > cols[q].r, "herbe verte en %s" % v)
			seen.grass += 1
		elif t.soil(v) == TerrainLogic.Soil.EARTH and t.edits.has(v):
			assert_true(uvs[q].x > 0.5 and uvs[q].y < 0.5 and cols[q].r > cols[q].g, "terre retournée en %s" % v)
			seen.earth += 1
	assert_true(seen.grass > 0 and seen.earth > 0, "%s" % seen)


# --- Au hasard, dans l'herbe et le sable mêlés ----------------------------------------------------

func test_random_shovel_work_in_mixed_ground_keeps_every_rule() -> void:
	var g := _grass_vertex()
	_fuzz_soil(g, 16, 4242)


func test_random_shovel_work_in_mixed_ground_keeps_every_rule_2() -> void:
	var g := _grass_vertex()
	_fuzz_soil(g + Vector2i(10, -6), 20, 77)


func _fuzz_soil(center: Vector2i, r: int, rng_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var done := 0
	var refused := {}
	for step in 900:
		var v := center + Vector2i(rng.randi_range(-r, r), rng.randi_range(-r, r))
		var kind := rng.randi_range(0, 12)
		if kind == 12:
			# On vide la pelle ailleurs (hors de la zone), pour changer de matière.
			gs.shovel_sand = 0.0
			continue
		var load0: float = gs.shovel_sand
		var soil0: int = gs.shovel_soil
		var aimed: int = gs.terrain.soil(v)
		var edits0: Dictionary = gs.terrain.edits.duplicate()
		var grass0 := _grassy_set(v, 10)
		var pinned0: Dictionary = gs.terrain._pinned.duplicate()
		var vol0: float = _volume(v, 24) + gs.shovel_sand * gs.config.dig_scoop_m3
		var h0 := {}
		for j in range(-8, 9):
			for i in range(-8, 9):
				var k := v + Vector2i(i, j)
				h0[k] = gs.terrain.vertex(k.x, k.y).y
		if kind <= 7:
			var dig := kind <= 3
			var why: String = gs.scoop_reason(v, dig)
			var ok: bool = gs.shovel_scoop(v, dig)
			assert_eq(ok, why == "", "permis ⇔ fait (%s, %s, %s)" % [v, dig, why])
			if ok:
				done += 1
				if dig:
					assert_eq(gs.shovel_soil, aimed, "la pelle porte ce qu'on a creusé (%s)" % v)
					if load0 > 0.05:
						assert_eq(soil0, aimed, "pas de mélange sur la pelle")
				else:
					for k: Vector2i in h0:
						if gs.terrain.edits.has(k) and gs.terrain.vertex(k.x, k.y).y > float(h0[k]) + 0.003:
							assert_eq(gs.terrain.soil(k), soil0, "ce qui monte est ce qu'on a posé (%s)" % k)
			else:
				refused[why] = int(refused.get(why, 0)) + 1
				assert_almost(gs.shovel_sand, load0, 1e-9)
				if why.begins_with("PROMPT_SHOVEL_HAS_"):
					assert_true(load0 > 0.05 and soil0 != aimed, "refus de mélange justifié")
		elif kind <= 9:
			gs.smooth_sand(v)
			assert_almost(gs.shovel_sand, load0, 1e-9, "lisser ne touche pas à la pelle")
		else:
			var p := TerrainLogic.vertex_xz(v)
			var cell := TerrainLogic.cell_of(p.x, p.y)
			var lv: Array = gs.auto_level(cell)
			var plan: Array = gs.level_plan(cell, float(lv[0]))
			var ok: bool = gs.flatten_area(cell, float(lv[0]))
			if (plan[0] as Array).is_empty():
				assert_false(ok, "aplanir refusé ne change rien")
			elif float(plan[1]) > 0.01 and load0 > 0.05:
				assert_eq(gs.shovel_soil, soil0, "aplanir ne mélange pas la pelle")
		# Le sable (sol + pelle) ne se crée ni ne se perd, à chaque geste. Seuls les sommets qui
		# viennent d'être recalés sur la grille changent un peu de hauteur sans que du sable bouge
		# (ils perdent leur petit décalage au hasard) : on enlève ça du compte.
		var drift := 0.0
		for k: Vector2i in gs.terrain._pinned:
			if not pinned0.has(k) and absi(k.x - v.x) <= 24 and absi(k.y - v.y) <= 24:
				drift += (gs.terrain.vertex(k.x, k.y).y - gs.terrain.base_vertex(k.x, k.y).y) * SandPhysics.AREA
		var vol1: float = _volume(v, 24) + gs.shovel_sand * gs.config.dig_scoop_m3
		assert_almost(vol1 - drift, vol0, 0.01, "pas %d (%s, genre %d) : le sable ne se crée ni ne se perd" % [step, v, kind])
		# Toujours : la pelle reste entre 0 et sa contenance.
		assert_true(gs.shovel_sand >= -1e-6 and gs.shovel_sand <= gs.config.shovel_capacity_scoops + 1e-6)
		# L'herbe ne part que là où ce geste a travaillé.
		for k: Vector2i in grass0:
			if not gs.terrain.grassy(k):
				assert_true(gs.terrain.edits.has(k) and not edits0.has(k), "herbe perdue hors du geste (%s, pas %d)" % [k, step])
		# Ailleurs, une pente d'origine jamais touchée ne bouge pas.
		for k: Vector2i in h0:
			if not gs.terrain.edits.has(k) and not edits0.has(k) and not gs.terrain._pinned.has(k):
				assert_almost(gs.terrain.vertex(k.x, k.y).y, float(h0[k]), 1e-6, "un sommet jamais touché ne bouge pas")
		# Une matière posée n'existe que sur du sol travaillé.
		for k: Vector2i in gs.terrain.cover:
			assert_true(gs.terrain.edits.has(k), "couverture sans travail (%s)" % k)
		if failures.size() > 10:
			break
	assert_true(done > 100, "assez de gestes réussis (%d, refus %s)" % [done, refused])
	print("    gestes réussis : %d, refus : %s" % [done, refused])
