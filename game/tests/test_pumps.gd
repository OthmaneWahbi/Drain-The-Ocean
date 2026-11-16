extends TestCase
## Pompe à bras et tuyaux (T2) : réseau, pompage, placement au bord de l'eau, sauvegarde.

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	gs.setup(cfg)
	gs.stock = {"sel": 100000, "mineraux": 100000, "mineraux_rares": 1000, "coquillages": 1000, "perles": 10}
	gs.unlocked_tier = 2


func after_each() -> void:
	gs.free()


func _zone(cap: float = 40.0, pos := Vector3.ZERO) -> Dictionary:
	var logic := DryingLogic.new(cap, 45.0)
	return {"position": pos, "logic": logic}


## Une pompe sur la plage sud, près de la cuvette déplacée à côté.
func _pump_next_to_basin() -> Dictionary:
	var basin: Dictionary = gs.zones[0]
	assert_true(gs.move_item(basin, Vector3(-0.5, 0.5, 12.5)))
	return gs.add_pump("pompe_bras", Vector3(-0.5, 0.5, 16.5))


func test_segments_needed() -> void:
	assert_eq(PipeNetwork.segments_needed(Vector3.ZERO, Vector3.ZERO, 2.0, 4.0), 1, "même collé, il faut un tronçon")
	assert_eq(PipeNetwork.segments_needed(Vector3.ZERO, Vector3(6.5, 0, 0), 2.5, 4.0), 1, "4 m pile = 1 tronçon")
	assert_eq(PipeNetwork.segments_needed(Vector3.ZERO, Vector3(9, 0, 0), 2.5, 4.0), 2)
	assert_eq(PipeNetwork.segments_needed(Vector3.ZERO, Vector3(0, 5, 9), 2.5, 4.0), 2, "la hauteur ne compte pas")


func test_links_are_greedy_nearest_first_and_share_pipes() -> void:
	var near := _zone(40.0, Vector3(5, 0, 0))
	var far := _zone(40.0, Vector3(15, 0, 0))
	var pump := {"position": Vector3.ZERO}
	var r := func(_z): return 1.0
	assert_eq(PipeNetwork.links([pump], [far, near], 0, 4.0, r).size(), 0, "sans tuyau, rien")
	var l1 := PipeNetwork.links([pump], [far, near], 1, 4.0, r)
	assert_eq(l1.size(), 1)
	assert_true(l1[0].zone == near, "la plus proche d'abord")
	assert_eq(PipeNetwork.links([pump], [far, near], 5, 4.0, r).size(), 2)
	var pump2 := {"position": Vector3(15, 0, 3)}
	var shared := PipeNetwork.links([pump, pump2], [far, near], 2, 4.0, r)
	assert_eq(shared.size(), 2, "1 tronçon pour pompe 1 → proche, 1 pour pompe 2 → loin")
	assert_true(shared[1].pump == pump2 and shared[1].zone == far)


func test_edge_point_stops_at_zone_border() -> void:
	var e := PipeNetwork.edge_point(Vector3(10, 0, 0), Vector3.ZERO, 2.0)
	assert_almost(e.x, 2.0)
	assert_almost(e.z, 0.0)
	var inside := PipeNetwork.edge_point(Vector3(1, 0, 0), Vector3.ZERO, 2.0)
	assert_almost(inside.x, 1.0, 1e-6, "pompe dans le rayon : le point ne dépasse pas la pompe")


func test_distribute_fills_in_order_and_never_overflows() -> void:
	var a := _zone(10.0)
	var b := _zone(10.0)
	assert_almost(PipeNetwork.distribute(15.0, [a, b]), 15.0)
	assert_almost(a.logic.water_l, 10.0)
	assert_almost(b.logic.water_l, 5.0)
	assert_almost(PipeNetwork.distribute(100.0, [a, b]), 5.0, 1e-6, "le reste n'est pas pompé")


func test_pump_must_go_on_the_shore() -> void:
	var pump: Dictionary = gs.add_pump("pompe_bras", Vector3(-0.5, 0.5, 16.5))
	assert_true(gs.can_place(pump, Vector3(-0.5, 0.5, 16.5)))
	assert_false(gs.can_place(pump, Vector3(-0.5, 0.5, -6.5)), "au milieu de l'île : non")
	assert_false(gs.can_place(pump, Vector3(-0.5, 0.5, 19.5)), "dans l'eau : non")


func test_pump_from_crate_lands_on_the_shore_without_overlap() -> void:
	var requested := []
	gs.placement_requested.connect(func(it): requested.append(it))
	gs.open_crate(gs.order(["pompe_bras"]))
	assert_eq(gs.pumps.size(), 1)
	var p: Dictionary = gs.pumps[0]
	assert_true(Vector2(p.position.x, p.position.z).length() >= gs.config.shore_only_kinds["pompe_bras"] - 1e-6)
	assert_true(gs.can_place(p, p.position))
	assert_eq(requested.size(), 1, "on passe en mode déplacement pour la poser")


func test_pipes_from_crate_add_segments() -> void:
	gs.open_crate(gs.order(["tuyau", "tuyau", "tuyau"]))
	assert_eq(gs.pipe_segments, 3)


func test_pump_without_pipes_does_nothing() -> void:
	var pump := _pump_next_to_basin()
	var before: float = gs.ocean.removed_l
	assert_almost(gs.run_pump(pump, 1.0), 0.0)
	assert_almost(gs.ocean.removed_l, before)


func test_pump_fills_linked_basin_and_takes_from_ocean() -> void:
	var pump := _pump_next_to_basin()
	gs.pipe_segments = 1
	var basin: Dictionary = gs.zones[0]
	assert_eq(gs.zones_for_pump(pump).size(), 1)
	var poured: float = gs.run_pump(pump, 0.5)
	assert_almost(poured, gs.config.pump_rates_lps["pompe_bras"] * 0.5)
	assert_almost(basin.logic.water_l, poured)
	assert_almost(gs.ocean.removed_l, poured, 1e-6, "chaque litre pompé sort de l'océan")


func test_pump_stops_when_full_and_returns_nothing_extra() -> void:
	var pump := _pump_next_to_basin()
	gs.pipe_segments = 1
	var basin: Dictionary = gs.zones[0]
	for i in 20:
		gs.run_pump(pump, 1.0)
	assert_almost(basin.logic.water_l, basin.logic.capacity_l)
	assert_almost(gs.ocean.removed_l, basin.logic.capacity_l, 1e-6, "pas un litre de trop")
	assert_almost(gs.run_pump(pump, 1.0), 0.0)


func test_pump_with_almost_empty_ocean() -> void:
	var pump := _pump_next_to_basin()
	gs.pipe_segments = 1
	gs.ocean.remove_water(gs.ocean.remaining_l() - 3.0)
	assert_true(gs.run_pump(pump, 1.0) <= 3.0 + 1e-6)
	assert_true(gs.ocean.remaining_l() >= -1e-6)


func test_moving_basin_away_breaks_the_link() -> void:
	var pump := _pump_next_to_basin()
	gs.pipe_segments = 1
	var changed := [0]
	gs.network_changed.connect(func(): changed[0] += 1)
	assert_true(gs.move_item(gs.zones[0], Vector3(-0.5, 0.5, -12.5)))
	assert_eq(gs.zones_for_pump(pump).size(), 0, "trop loin pour 1 tronçon")
	assert_true(changed[0] > 0)
	gs.pipe_segments = 10
	assert_eq(gs.zones_for_pump(pump).size(), 1)


func test_pump_is_movable_and_saved() -> void:
	var pump := _pump_next_to_basin()
	gs.pipe_segments = 4
	assert_true(gs.movable_items().has(pump))
	assert_true(gs.move_item(pump, Vector3(-3.5, 0.5, 16.5), 90.0))
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(other.pumps.size(), 1)
	assert_eq(other.pipe_segments, 4)
	assert_almost(other.pumps[0].position.x, -3.5)
	assert_almost(other.item_rotation(other.pumps[0]), 90.0)
	assert_eq(other.zones_for_pump(other.pumps[0]).size(), 1)
	other.free()


func test_unknown_pump_kind_is_refused() -> void:
	assert_true(gs.add_pump("pompe_magique", Vector3(0, 0.5, 16.5)).is_empty())
	assert_eq(gs.pumps.size(), 0)


func test_pumps_are_tier_2() -> void:
	gs.unlocked_tier = 1
	assert_false(gs.can_buy(gs.catalog.find(&"pompe_bras")))
	assert_false(gs.can_buy(gs.catalog.find(&"tuyau")))


func test_time_alone_never_runs_a_hand_pump() -> void:
	_pump_next_to_basin()
	gs.pipe_segments = 1
	gs.advance_time(60.0)
	assert_almost(gs.zones[0].logic.water_l, 0.0)
