extends TestCase
## Les jalons comparatifs (M-70) : baignoire, piscine gonflable, piscine…

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e9
	gs.setup(cfg)


func after_each() -> void:
	gs.free()


func _list() -> Array:
	return [{"id": "b", "liters": 100.0, "reward": {"sel": 1}}, {"id": "a", "liters": 10.0, "reward": {}}, {"id": "c", "liters": 1000.0}]


func test_logic_sorts_and_reaches_in_order() -> void:
	var m := MilestoneLogic.new(_list())
	assert_eq(m.next().id, "a", "triés du plus petit au plus grand")
	assert_eq(m.update(5.0).size(), 0)
	var got := m.update(150.0)
	assert_eq(got.size(), 2, "deux d'un coup")
	assert_eq(got[0].id, "a")
	assert_eq(got[1].id, "b")
	assert_eq(m.update(150.0).size(), 0, "jamais deux fois")
	assert_eq(m.next().id, "c")


func test_reached_stays_reached_when_water_comes_back() -> void:
	var m := MilestoneLogic.new(_list())
	m.update(20.0)
	m.update(0.0)
	assert_eq(m.reached, 1)


func test_progress_between_milestones() -> void:
	var m := MilestoneLogic.new(_list())
	assert_almost(m.progress(5.0), 0.5)
	m.update(10.0)
	assert_almost(m.progress(55.0), 0.5)
	m.update(5000.0)
	assert_almost(m.progress(5000.0), 1.0)
	assert_true(m.next().is_empty())


func test_config_has_three_demo_milestones_first() -> void:
	var list: Array = gs.config.milestones
	assert_true(list.size() >= 3)
	assert_eq(String(list[0].id), "baignoire")
	for i in range(1, list.size()):
		assert_true(float(list[i].liters) > float(list[i - 1].liters))


func test_bathtub_reached_by_bucketing_gives_its_reward() -> void:
	var got := []
	gs.milestone_reached.connect(func(m): got.append(m))
	var before := int(gs.stock.get("sel", 0))
	# 15 seaux de 10 L = 150 L : une baignoire.
	for i in 15:
		gs.bucket.water_l = 0.0
		gs.fill_bucket()
	assert_eq(got.size(), 1)
	assert_eq(String(got[0].id), "baignoire")
	assert_eq(int(gs.stock.get("sel", 0)), before + 10)


func test_milestones_are_saved_and_old_saves_dont_pay_twice() -> void:
	gs.ocean.removed_l = 2500.0
	gs.check_milestones()
	assert_eq(gs.milestones.reached, 2)
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(other.milestones.reached, 2)
	data.erase("milestones")
	var stock_before := Economy.count(Economy.sanitize(data.stock))
	other.load_dict(data)
	assert_eq(other.milestones.reached, 2, "vieille sauvegarde : recalculé")
	assert_eq(Economy.count(other.stock), stock_before, "sans redonner les récompenses")
	other.free()


func test_new_game_resets_milestones() -> void:
	gs.ocean.removed_l = 200.0
	gs.check_milestones()
	gs.new_game()
	assert_eq(gs.milestones.reached, 0)
