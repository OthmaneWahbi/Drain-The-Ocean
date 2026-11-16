extends TestCase
## Le moulin-pompe (première machine automatique) et la fin de la démo (M-05).

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


func _windmill_next_to_basin() -> Dictionary:
	assert_true(gs.move_item(gs.zones[0], Vector3(-0.5, 0.5, 12.5)))
	return gs.add_pump("moulin_pompe", Vector3(-0.5, 0.5, 16.5))


func test_windmill_pumps_on_its_own_with_time() -> void:
	_windmill_next_to_basin()
	gs.pipe_segments = 1
	gs.advance_time(2.0, 1.0)
	# (une partie s'évapore déjà : on compte ce qui est sorti de l'océan)
	assert_almost(gs.ocean.removed_l, 2.0 * gs.config.pump_rates_lps["moulin_pompe"], 1e-6)
	assert_true(gs.auto_pumped_l > 0.0)


func test_windmill_without_pipes_does_nothing() -> void:
	_windmill_next_to_basin()
	gs.advance_time(30.0)
	assert_almost(gs.ocean.removed_l, 0.0)
	assert_almost(gs.auto_pumped_l, 0.0)


func test_hand_pump_never_counts_as_automatic() -> void:
	assert_true(gs.move_item(gs.zones[0], Vector3(-0.5, 0.5, 12.5)))
	var hand: Dictionary = gs.add_pump("pompe_bras", Vector3(-0.5, 0.5, 16.5))
	gs.pipe_segments = 1
	gs.run_pump(hand, 5.0)
	assert_almost(gs.auto_pumped_l, 0.0)
	assert_false(gs.is_auto_pump(hand))


func test_demo_ends_once_after_enough_automatic_water() -> void:
	_windmill_next_to_basin()
	gs.pipe_segments = 20
	gs.add_zone("bassin_bois", gs.find_free_spot(gs.footprint_of("bassin_bois"), Vector3(-6.5, 0.5, 12.5)))
	var ends := [0]
	gs.demo_finished.connect(func(): ends[0] += 1)
	gs.advance_time(5.0)
	assert_eq(ends[0], 0, "pas encore assez")
	gs.advance_time(60.0)
	assert_true(gs.auto_pumped_l >= gs.config.demo_end_auto_pumped_l, "pompé : %.0f L" % gs.auto_pumped_l)
	assert_eq(ends[0], 1)
	gs.advance_time(60.0)
	assert_eq(ends[0], 1, "une seule fois")


func test_demo_end_is_saved() -> void:
	gs.demo_done = true
	gs.auto_pumped_l = 250.0
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	var ends := [0]
	other.demo_finished.connect(func(): ends[0] += 1)
	other.load_dict(data)
	other.advance_time(10.0)
	assert_true(other.demo_done)
	assert_eq(ends[0], 0, "on ne revoit pas la fin après un chargement")
	other.free()


func test_windmill_is_unique_shore_only_and_tier_2() -> void:
	var item: CatalogItem = gs.catalog.find(&"moulin_pompe")
	assert_true(item.unique)
	assert_true(gs.can_buy(item))
	gs.open_crate(gs.order(["moulin_pompe"]))
	assert_false(gs.can_buy(item), "un seul moulin")
	var w: Dictionary = gs.pumps[0]
	assert_true(Vector2(w.position.x, w.position.z).length() >= 15.5 - 1e-6)
	assert_false(gs.can_place(w, Vector3(0.5, 0.5, 0.5)))
	gs.unlocked_tier = 1
	gs.owned.clear()
	assert_false(gs.can_buy(item))


func test_new_game_resets_demo() -> void:
	gs.demo_done = true
	gs.auto_pumped_l = 999.0
	gs.new_game()
	assert_false(gs.demo_done)
	assert_almost(gs.auto_pumped_l, 0.0)
