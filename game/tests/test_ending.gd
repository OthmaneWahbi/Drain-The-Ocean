extends TestCase
## La vraie fin (M-04, PRD §11) et les traits du palmier (M-84).

const GameStateScript := preload("res://core/game_state.gd")
const DIR := "user://test_saves_ending"

var gs: Node


func before_each() -> void:
	SaveSystem.delete(1, DIR)
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	gs.setup(cfg)
	gs.save_dir = DIR


func after_each() -> void:
	gs.free()
	SaveSystem.delete(1, DIR)


func _total_ending_s() -> float:
	var t := 0.0
	for v in gs.config.ending_durations.values():
		t += float(v)
	return t


func test_phases_follow_each_other_in_order() -> void:
	var e := EndingLogic.new({"drain": 1.0, "gurgle": 1.0, "walk": 1.0, "plane": 1.0, "time": 1.0, "credits": 1.0})
	var seen: Array = [e.phase]
	for i in 70:
		if e.step(0.1):
			seen.append(e.phase)
	assert_eq(seen, [EndingLogic.Phase.DRAIN, EndingLogic.Phase.GURGLE, EndingLogic.Phase.WALK, EndingLogic.Phase.PLANE, EndingLogic.Phase.TIME, EndingLogic.Phase.CREDITS, EndingLogic.Phase.DONE])
	assert_true(e.is_done())
	assert_false(e.step(1.0), "plus rien après la fin")


func test_a_big_step_can_cross_several_phases() -> void:
	var e := EndingLogic.new({"drain": 1.0, "gurgle": 1.0, "walk": 1.0, "plane": 1.0, "time": 1.0, "credits": 1.0})
	e.step(2.5)
	assert_eq(e.phase, EndingLogic.Phase.WALK)
	assert_almost(e.progress(), 0.5, 1e-5)


func test_only_the_time_screen_and_credits_can_be_skipped() -> void:
	var e := EndingLogic.new({"drain": 1.0, "gurgle": 1.0, "walk": 1.0, "plane": 1.0, "time": 1.0, "credits": 1.0})
	e.skip()
	assert_eq(e.phase, EndingLogic.Phase.DRAIN, "la scène ne se saute pas")
	e.step(4.0)
	assert_eq(e.phase, EndingLogic.Phase.TIME)
	e.skip()
	assert_eq(e.phase, EndingLogic.Phase.CREDITS)
	e.skip()
	assert_true(e.is_done())


func test_the_ending_drains_the_ocean_and_stops_the_clock() -> void:
	gs.ocean.remove_water(1000.0)
	gs.play_time_s = 600.0
	var level_before: float = gs.water_level_y()
	gs.start_ending()
	assert_true(gs.ui_open, "le joueur ne bouge plus")
	gs._process(gs.config.ending_durations.drain)
	assert_true(gs.water_level_y() < level_before - 1.0, "l'eau descend : la bonde apparaît")
	gs._process(gs.config.ending_durations.gurgle + 0.01)
	assert_true(gs.ocean.is_empty() or gs.ocean.remaining_l() <= 0.0, "l'océan est vide")
	assert_almost(gs.play_time_s, 600.0, 1e-6, "le chronomètre est arrêté")


func test_finishing_returns_to_menu_and_keeps_best_time() -> void:
	var finished := [0]
	gs.run_finished.connect(func(): finished[0] += 1)
	gs.play_slot(1)
	gs.play_time_s = 900.0
	gs.start_ending()
	gs.start_ending()  # déjà lancée : ignorée
	for i in int(_total_ending_s()) + 2:
		gs._process(1.0)
	assert_eq(finished[0], 1)
	assert_true(gs.ending == null)
	assert_false(gs.ui_open)
	assert_almost(gs.best_time_s, 900.0)
	assert_almost(float(SaveSystem.summary(1, DIR).best_time_s), 900.0, 0.01, "le menu montre le meilleur temps")


func test_a_finished_save_reopens_just_before_the_drain() -> void:
	gs.play_slot(1)
	gs.ocean.remove_water(5000.0)
	gs.start_ending()
	for i in int(_total_ending_s()) + 2:
		gs._process(1.0)
	gs.new_game()
	assert_true(gs.load_game(1))
	assert_almost(gs.ocean.removed_l, 5000.0, 0.01, "l'eau d'avant la chaîne est revenue")
	assert_eq(gs.finished_runs, 1)
	assert_true(gs.ending == null)


func test_drowning_wakeups_are_counted_and_saved() -> void:
	var n := [0]
	gs.wakeups_changed.connect(func(): n[0] += 1)
	gs.register_wakeup()
	gs.register_wakeup()
	assert_eq(gs.wakeups, 2)
	assert_eq(n[0], 2)
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(JSON.parse_string(JSON.stringify(gs.to_dict())))
	assert_eq(other.wakeups, 2)
	other.new_game()
	assert_eq(other.wakeups, 0, "nouvelle partie : palmier vierge")
	other.free()


func test_tally_marks_come_in_groups_of_five() -> void:
	assert_true(EndingLogic.tally_marks(0).is_empty())
	var marks := EndingLogic.tally_marks(7)
	assert_eq(marks.size(), 7)
	for i in 4:
		assert_almost(float(marks[i].angle), 0.0)
	assert_true(float(marks[4].angle) > 30.0, "le 5e trait barre le paquet")
	assert_true(float(marks[5].x) > float(marks[3].x), "le paquet suivant est plus loin")
	# 11 traits : on passe à la rangée du dessous.
	var many := EndingLogic.tally_marks(11)
	assert_true(float(many[10].y) < 0.0)
	assert_almost(float(many[9].y), 0.0)
	for m in many:
		assert_true(float(m.x) < 0.4, "tient sur le tronc")
