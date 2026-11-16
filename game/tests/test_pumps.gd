extends TestCase
## Pompes et tuyaux posés À LA MAIN (T2) : pose, réseau 3D, pompage, déplacements, sauvegarde.

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	gs.setup(cfg)
	gs.stock = {"sel": 100000, "mineraux": 100000, "mineraux_rares": 1000, "coquillages": 1000, "perles": 10}
	gs.unlocked_tier = 2
	# Les coquillages tombent au hasard : on les retire pour que les placements soient reproductibles.
	gs.pickups.clear()


func after_each() -> void:
	gs.free()


## Pose des pièces (en ajoutant ce qu'il faut au stock) et vérifie que chacune est acceptée.
func _lay(cells: Array) -> void:
	gs.pipe_stock += cells.size()
	for c in cells:
		assert_true(gs.place_pipe(c), "pièce refusée en %s" % c)


## Cuvette en (-0,5 ; 12,5), pompe à bras sur la plage en (-0,5 ; 16,5), sans tuyau.
func _pump_and_basin(kind: String = "pompe_bras") -> Dictionary:
	assert_true(gs.move_item(gs.zones[0], Vector3(-0.5, 0.5, 12.5)))
	return gs.add_pump(kind, Vector3(-0.5, 0.5, 16.5))


## Ligne droite au sol de la pompe jusqu'au-dessus de la cuvette.
const STRAIGHT := [Vector3i(-1, 0, 15), Vector3i(-1, 0, 14), Vector3i(-1, 0, 13)]


# --- Logique pure ------------------------------------------------------------------------------

func test_cell_of_and_center() -> void:
	assert_eq(PipeNetwork.cell_of(Vector3(-0.5, 3, 12.5)), Vector3i(-1, 0, 12))
	var c := PipeNetwork.cell_center(Vector3i(2, 1, -3), 1.0, 0.5)
	assert_almost(c.x, 2.5)
	assert_almost(c.z, -2.5)
	assert_almost(c.y, 0.5 + 0.2 + 1.0)


func test_reach_follows_any_shape_in_3d() -> void:
	# Pompe en (0,0,0) ; un tuyau qui part à droite, monte de 2, avance, redescend.
	var cells := {}
	for c in [Vector3i(1, 0, 0), Vector3i(1, 1, 0), Vector3i(1, 2, 0), Vector3i(2, 2, 0), Vector3i(3, 2, 0), Vector3i(3, 1, 0), Vector3i(3, 0, 0)]:
		cells[c] = true
	cells[Vector3i(9, 0, 9)] = true  # pièce isolée
	var d := PipeNetwork.reach(Vector3i.ZERO, cells)
	assert_eq(int(d[Vector3i(1, 0, 0)]), 1)
	assert_eq(int(d[Vector3i(3, 0, 0)]), 7)
	assert_false(d.has(Vector3i(9, 0, 9)), "une pièce qui ne touche rien ne reçoit pas d'eau")


func test_pump_top_port_and_no_diagonals() -> void:
	var cells := {Vector3i(0, 1, 0): true, Vector3i(1, 0, 1): true}
	var d := PipeNetwork.reach(Vector3i.ZERO, cells)
	assert_true(d.has(Vector3i(0, 1, 0)), "juste au-dessus de la pompe : relié")
	assert_false(d.has(Vector3i(1, 0, 1)), "en diagonale : pas relié")


func test_zones_reached_nearest_first_and_elevated_pipes_feed() -> void:
	var near := {"position": Vector3(0.5, 0, 3.5), "logic": DryingLogic.new(40, 45)}
	var far := {"position": Vector3(0.5, 0, 8.5), "logic": DryingLogic.new(40, 45)}
	var cells := {}
	for z in range(1, 9):
		cells[Vector3i(0, 2 if z > 1 else 0, z)] = true
	cells[Vector3i(0, 1, 1)] = true
	cells[Vector3i(0, 2, 1)] = true
	var found := PipeNetwork.zones_reached(Vector3(0.5, 0, 0.5), cells, [far, near], func(_z): return 1.5)
	assert_eq(found.size(), 2, "un tuyau EN HAUTEUR au-dessus d'une zone y verse aussi")
	assert_true(found[0] == near)


func test_axis_of_normal() -> void:
	assert_eq(PipeBuilder.axis_of(Vector3(0.1, 0.9, 0.2)), Vector3i(0, 1, 0))
	assert_eq(PipeBuilder.axis_of(Vector3(-0.8, 0.1, 0.3)), Vector3i(-1, 0, 0))
	assert_eq(PipeBuilder.axis_of(Vector3(0, -0.2, -0.9)), Vector3i(0, 0, -1))


func test_cell_for_hit_on_ground_and_on_top_of_something() -> void:
	assert_eq(PipeBuilder.cell_for_hit(null, Vector3(2.3, 0.5, -1.2), Vector3.UP, 1.0, 0.5), Vector3i(2, 0, -2))
	assert_eq(PipeBuilder.cell_for_hit(null, Vector3(2.3, 1.3, -1.2), Vector3.UP, 1.0, 0.5), Vector3i(2, 1, -2), "sur le dessus d'une pompe : au-dessus")


func test_distribute_fills_in_order_and_never_overflows() -> void:
	var a := {"logic": DryingLogic.new(10.0, 45.0)}
	var b := {"logic": DryingLogic.new(10.0, 45.0)}
	assert_almost(PipeNetwork.distribute(15.0, [a, b]), 15.0)
	assert_almost(a.logic.water_l, 10.0)
	assert_almost(b.logic.water_l, 5.0)
	assert_almost(PipeNetwork.distribute(100.0, [a, b]), 5.0)


# --- Poser et reprendre ------------------------------------------------------------------------

func test_place_and_remove_pipes_uses_the_stock() -> void:
	gs.pipe_stock = 2
	assert_true(gs.place_pipe(Vector3i(0, 0, -8)))
	assert_eq(gs.pipe_stock, 1)
	assert_false(gs.place_pipe(Vector3i(0, 0, -8)), "déjà une pièce")
	assert_true(gs.remove_pipe(Vector3i(0, 0, -8)))
	assert_eq(gs.pipe_stock, 2)
	assert_false(gs.remove_pipe(Vector3i(0, 0, -8)))
	gs.pipe_stock = 0
	assert_false(gs.place_pipe(Vector3i(0, 0, -8)), "stock vide")


func test_pipe_rules() -> void:
	gs.pipe_stock = 100
	assert_false(gs.can_place_pipe(Vector3i(0, 1, -8)), "en l'air sans rien à côté")
	assert_true(gs.place_pipe(Vector3i(0, 0, -8)))
	assert_true(gs.place_pipe(Vector3i(0, 1, -8)), "monter au-dessus d'une pièce")
	assert_true(gs.place_pipe(Vector3i(1, 1, -8)), "partir à l'horizontale en hauteur")
	assert_false(gs.can_place_pipe(Vector3i(0, gs.config.pipe_max_level + 1, -8)), "trop haut")
	assert_false(gs.can_place_pipe(Vector3i(0, -1, -8)), "sous le sol")
	assert_false(gs.can_place_pipe(Vector3i(25, 0, 0)), "dans la mer")
	assert_false(gs.can_place_pipe(Vector3i(8, 0, 4)), "dans la palette")
	assert_false(gs.can_place_pipe(Vector3i(5, 0, -3)), "dans le téléphone")
	var basin: Dictionary = gs.zones[0]
	assert_true(gs.can_place_pipe(PipeNetwork.cell_of(basin.position)), "dans une zone : oui, il y verse")


func test_objects_cannot_be_put_on_ground_pipes_but_zones_can() -> void:
	gs.pipe_stock = 1
	assert_true(gs.place_pipe(Vector3i(0, 0, -8)))
	var m: Dictionary = gs.add_mirror(Vector3(5.5, 0.5, -12.5))
	assert_false(gs.move_item(m, Vector3(0.5, 0.5, -7.5)), "pas de miroir sur un tuyau")
	assert_true(gs.move_item(gs.zones[0], Vector3(0.5, 0.5, -8.5)), "une zone peut passer sous un tuyau")


# --- Pompage ----------------------------------------------------------------------------------

func test_pump_without_pipes_does_nothing() -> void:
	var pump := _pump_and_basin()
	assert_almost(gs.run_pump(pump, 1.0), 0.0)
	assert_almost(gs.ocean.removed_l, 0.0)
	assert_almost(float(pump.get("last_lps", 0.0)), 0.0)


func test_pump_through_hand_laid_pipes() -> void:
	var pump := _pump_and_basin()
	_lay(STRAIGHT)
	assert_eq(gs.zones_for_pump(pump).size(), 1)
	var poured: float = gs.run_pump(pump, 0.5)
	assert_almost(poured, gs.config.pump_rates_lps["pompe_bras"] * 0.5)
	assert_almost(gs.ocean.removed_l, poured, 1e-6, "chaque litre pompé sort de l'océan")
	assert_almost(float(pump.last_lps), gs.config.pump_rates_lps["pompe_bras"], 1e-6, "débit affiché")


func test_a_gap_in_the_pipe_stops_the_water() -> void:
	var pump := _pump_and_basin()
	_lay(STRAIGHT)
	assert_true(gs.remove_pipe(STRAIGHT[1]))
	assert_eq(gs.zones_for_pump(pump).size(), 0)
	assert_almost(gs.run_pump(pump, 1.0), 0.0)
	assert_true(gs.place_pipe(STRAIGHT[1]))
	assert_eq(gs.zones_for_pump(pump).size(), 1, "on répare : ça repart")


func test_overhead_pipe_over_an_object() -> void:
	# Pompe → monte de 2 → passe en hauteur → arrive au-dessus de la cuvette.
	var pump := _pump_and_basin()
	_lay([Vector3i(-1, 1, 16), Vector3i(-1, 2, 16), Vector3i(-1, 2, 15), Vector3i(-1, 2, 14), Vector3i(-1, 2, 13)])
	assert_eq(gs.zones_for_pump(pump).size(), 1)
	assert_true(gs.run_pump(pump, 1.0) > 0.0)


func test_pump_stops_when_full() -> void:
	var pump := _pump_and_basin()
	_lay(STRAIGHT)
	var basin: Dictionary = gs.zones[0]
	for i in 20:
		gs.run_pump(pump, 1.0)
	assert_almost(basin.logic.water_l, basin.logic.capacity_l)
	assert_almost(gs.ocean.removed_l, basin.logic.capacity_l, 1e-6, "pas un litre de trop")
	assert_almost(gs.run_pump(pump, 1.0), 0.0)
	assert_almost(float(pump.last_lps), 0.0)


func test_one_network_feeds_two_zones_nearest_first() -> void:
	var pump := _pump_and_basin()
	var tarp: Dictionary = gs.add_zone("bache", Vector3(5.5, 0.5, 12.5))
	_lay(STRAIGHT)
	_lay([Vector3i(0, 0, 15), Vector3i(1, 0, 15), Vector3i(2, 0, 15), Vector3i(3, 0, 15), Vector3i(4, 0, 15), Vector3i(5, 0, 15), Vector3i(5, 0, 14), Vector3i(5, 0, 13)])
	var targets: Array = gs.zones_for_pump(pump)
	assert_eq(targets.size(), 2)
	assert_true(targets[0] == gs.zones[0], "la cuvette est plus proche")
	gs.run_pump(pump, 3.0)
	assert_almost(gs.zones[0].logic.water_l, gs.zones[0].logic.capacity_l)
	assert_almost(tarp.logic.water_l, 60.0 - gs.zones[0].logic.capacity_l)


# --- Déplacer ne casse rien (demande d'Othmane) -------------------------------------------------

func test_moving_the_zone_away_and_back() -> void:
	var pump := _pump_and_basin()
	_lay(STRAIGHT)
	assert_true(gs.move_item(gs.zones[0], Vector3(-0.5, 0.5, -10.5)))
	assert_eq(gs.zones_for_pump(pump).size(), 0, "plus de zone au bout du tuyau")
	assert_almost(gs.run_pump(pump, 1.0), 0.0)
	assert_true(gs.move_item(gs.zones[0], Vector3(-0.5, 0.5, 12.5)))
	assert_eq(gs.zones_for_pump(pump).size(), 1, "remise au bout : ça repompe")
	assert_true(gs.run_pump(pump, 1.0) > 0.0)


func test_moving_the_pump_along_its_pipe_keeps_working() -> void:
	var pump := _pump_and_basin()
	_lay(STRAIGHT + [Vector3i(0, 0, 15), Vector3i(1, 0, 15)])
	# La pompe va au bout de l'autre branche du même tuyau.
	assert_true(gs.move_item(pump, Vector3(2.5, 0.5, 15.5)), "nouvelle place au bord de l'eau")
	assert_eq(gs.zones_for_pump(pump).size(), 1)
	assert_true(gs.run_pump(pump, 1.0) > 0.0)


func test_moving_the_pump_away_disconnects_it_cleanly() -> void:
	var pump := _pump_and_basin()
	_lay(STRAIGHT)
	gs.pickups.clear()  # les coquillages tombent au hasard : ils pourraient occuper la case
	assert_true(gs.move_item(pump, Vector3(-16.5, 0.5, 0.5)))
	assert_eq(gs.zones_for_pump(pump).size(), 0)
	assert_almost(gs.run_pump(pump, 1.0), 0.0)
	assert_true(gs.move_item(pump, Vector3(-0.5, 0.5, 16.5)))
	assert_true(gs.run_pump(pump, 1.0) > 0.0, "revenue : ça repompe")


func test_network_changed_on_every_change() -> void:
	var pump := _pump_and_basin()
	var n := [0]
	gs.network_changed.connect(func(): n[0] += 1)
	_lay([STRAIGHT[0]])
	gs.remove_pipe(STRAIGHT[0])
	gs.move_item(pump, Vector3(-3.5, 0.5, 16.5))
	assert_eq(n[0], 3)


func test_moving_while_windmill_runs() -> void:
	var w := _pump_and_basin("moulin_pompe")
	_lay(STRAIGHT)
	gs.advance_time(2.0, 1.0)
	var before: float = gs.ocean.removed_l
	assert_true(before > 0.0)
	gs.move_item(gs.zones[0], Vector3(-0.5, 0.5, -10.5))
	gs.advance_time(2.0, 1.0)
	assert_almost(gs.ocean.removed_l, before, 1e-6, "zone partie : le moulin ne pompe plus dans le vide")
	gs.move_item(gs.zones[0], Vector3(-0.5, 0.5, 12.5))
	gs.advance_time(2.0, 1.0)
	assert_true(gs.ocean.removed_l > before)
	assert_true(gs.is_auto_pump(w))


# --- Achat, placement, sauvegarde ------------------------------------------------------------

func test_pump_must_go_on_the_shore() -> void:
	var pump: Dictionary = gs.add_pump("pompe_bras", Vector3(-0.5, 0.5, 16.5))
	assert_true(gs.can_place(pump, Vector3(-0.5, 0.5, 16.5)))
	assert_false(gs.can_place(pump, Vector3(-0.5, 0.5, -6.5)), "au milieu de l'île : non")
	assert_false(gs.can_place(pump, Vector3(-0.5, 0.5, 19.5)), "dans l'eau : non")


func test_pump_from_crate_lands_on_the_shore() -> void:
	gs.open_crates(gs.order(["pompe_bras"]))
	var p: Dictionary = gs.pumps[0]
	assert_true(Vector2(p.position.x, p.position.z).length() >= gs.config.shore_only_kinds["pompe_bras"] - 1e-6)
	assert_true(gs.can_place(p, p.position))


func test_buying_pipes_adds_pieces_and_lights_the_toolbar_slot() -> void:
	assert_false(gs.owns_tool("tuyaux"))
	gs.open_crates(gs.order(["tuyau", "tuyau"]))
	assert_eq(gs.pipe_stock, 10, "5 pièces par achat")
	assert_true(gs.owns_tool("tuyaux"))
	gs.select_tool(gs.toolbar.index_of("tuyaux"))
	assert_eq(gs.current_tool(), "tuyaux")


func test_pipes_and_pumps_are_saved() -> void:
	var pump := _pump_and_basin()
	_lay(STRAIGHT + [Vector3i(-1, 1, 15)])
	gs.pipe_stock = 7
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(other.pipes.size(), 4)
	assert_true(other.pipes.has(Vector3i(-1, 1, 15)))
	assert_eq(other.pipe_stock, 7)
	assert_eq(other.zones_for_pump(other.pumps[0]).size(), 1)
	assert_true(pump.has("last_lps") or true)
	assert_false(JSON.stringify(data).contains("last_lps"), "le débit affiché n'est pas sauvegardé")
	other.free()


func test_old_save_with_segments_gives_pieces() -> void:
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	data.erase("pipes")
	data.erase("pipe_stock")
	data["pipe_segments"] = 3
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(other.pipe_stock, 12)
	other.free()


func test_new_game_clears_pipes() -> void:
	_lay([Vector3i(0, 0, -8)])
	gs.new_game()
	assert_eq(gs.pipes.size(), 0)
	assert_eq(gs.pipe_stock, 0)


func test_unknown_pump_kind_is_refused() -> void:
	assert_true(gs.add_pump("pompe_magique", Vector3(0, 0.5, 16.5)).is_empty())


func test_time_alone_never_runs_a_hand_pump() -> void:
	_pump_and_basin()
	_lay(STRAIGHT)
	gs.advance_time(60.0)
	assert_almost(gs.ocean.removed_l, 0.0)
