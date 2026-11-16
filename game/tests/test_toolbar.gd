extends TestCase
## La barre d'outils de 5 cases (M-27) : choisir, faire défiler, outils pas encore achetés.

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	gs.setup(cfg)


func after_each() -> void:
	gs.free()


func test_starts_with_the_bucket() -> void:
	assert_eq(gs.current_tool(), "seau")
	assert_eq(gs.toolbar.slots.size(), 5)


func test_select_by_number() -> void:
	gs.select_tool(1)
	assert_eq(gs.current_tool(), "mains")
	gs.select_tool(0)
	assert_eq(gs.current_tool(), "seau")


func test_cannot_select_rake_before_buying_it_nor_empty_slots() -> void:
	gs.select_tool(2)
	assert_eq(gs.current_tool(), "seau", "pas de râteau encore")
	gs.select_tool(3)
	assert_eq(gs.current_tool(), "seau", "case vide")
	gs.select_tool(99)
	gs.select_tool(-1)
	assert_eq(gs.current_tool(), "seau")


func test_wheel_cycles_and_skips_unavailable() -> void:
	gs.cycle_tool(1)
	assert_eq(gs.current_tool(), "mains")
	gs.cycle_tool(1)
	assert_eq(gs.current_tool(), "seau", "râteau pas acheté et cases vides sautés : retour au début")
	gs.cycle_tool(-1)
	assert_eq(gs.current_tool(), "mains")
	gs.has_rake = true
	gs.cycle_tool(1)
	assert_eq(gs.current_tool(), "rateau")


func test_tool_changed_is_emitted_only_on_real_change() -> void:
	var n := [0]
	gs.tool_changed.connect(func(): n[0] += 1)
	gs.select_tool(0)
	assert_eq(n[0], 0, "déjà le seau")
	gs.select_tool(1)
	assert_eq(n[0], 1)
	gs.select_tool(2)
	assert_eq(n[0], 1, "râteau refusé")


func test_changing_tool_cancels_a_fill_in_progress() -> void:
	gs.bucket.hold_fill(0.3)
	assert_true(gs.bucket.fill_progress_ratio() > 0.0)
	gs.select_tool(1)
	assert_almost(gs.bucket.fill_progress_ratio(), 0.0)


func test_hands_harvest_three_rake_harvests_all() -> void:
	var basin: Dictionary = gs.zones[0]
	basin.logic.deposit = {"sel": 9}
	gs.has_rake = true
	gs.select_tool(1)
	gs.harvest(basin)
	assert_eq(gs.carried_count(), 3)
	gs.select_tool(2)
	gs.harvest(basin)
	assert_eq(gs.carried_count(), 9)


func test_selected_tool_is_saved_and_checked_on_load() -> void:
	gs.has_rake = true
	gs.select_tool(2)
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(other.current_tool(), "rateau")
	# Sauvegarde abîmée : le râteau tenu sans être possédé → retour au seau.
	data["upgrades"]["has_rake"] = false
	other.load_dict(data)
	assert_eq(other.current_tool(), "seau")
	data["upgrades"]["tool"] = 42
	other.load_dict(data)
	assert_eq(other.current_tool(), "seau")
	other.free()


func test_new_game_gives_back_the_bucket() -> void:
	gs.select_tool(1)
	gs.new_game()
	assert_eq(gs.current_tool(), "seau")


func test_toolbar_logic_alone() -> void:
	var tb := ToolbarLogic.new(PackedStringArray(["a", "", "b"]))
	var owned := func(t): return t == "a" or t == "b"
	assert_true(tb.cycle(1, owned))
	assert_eq(tb.current(), "b")
	assert_true(tb.cycle(1, owned))
	assert_eq(tb.current(), "a")
	var nothing := ToolbarLogic.new(PackedStringArray(["a", ""]))
	assert_false(nothing.cycle(1, func(_t): return false), "rien d'autre de disponible")
