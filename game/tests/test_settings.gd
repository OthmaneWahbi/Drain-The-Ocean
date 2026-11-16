extends TestCase
## Menus et options (M-21, M-71, M-72, M-73, M-77) : options bornées, résumé des emplacements,
## choix d'un emplacement, sauvegarde automatique seulement une fois la partie choisie.

const GameStateScript := preload("res://core/game_state.gd")
const HudScript := preload("res://scenes/ui/hud.gd")
const DIR := "user://test_saves_menu"

var gs: Node


func before_each() -> void:
	for slot in [1, 2, 3]:
		SaveSystem.delete(slot, DIR)
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	gs.setup(cfg)
	gs.save_dir = DIR


func after_each() -> void:
	gs.free()
	for slot in [1, 2, 3]:
		SaveSystem.delete(slot, DIR)


# --- Options -------------------------------------------------------------------------------

func test_defaults_are_sane() -> void:
	var s := SettingsLogic.new()
	assert_almost(s.fov, 75.0)
	assert_true(s.head_bob)
	assert_false(s.show_timer, "chronomètre caché par défaut (M-73)")
	assert_eq(s.language, "fr")


func test_values_are_clamped_and_unknown_language_falls_back() -> void:
	var s := SettingsLogic.new()
	s.load_dict({"fov": 300.0, "mouse_sensitivity": -1.0, "volume": 4.0, "language": "xx"})
	assert_almost(s.fov, 110.0)
	assert_almost(s.mouse_sensitivity, 0.0005)
	assert_almost(s.volume, 1.0)
	assert_eq(s.language, "fr")


func test_settings_round_trip_through_json() -> void:
	var s := SettingsLogic.new()
	s.load_dict({"fov": 90.0, "head_bob": false, "language": "en", "show_timer": true, "volume": 0.3, "fullscreen": true})
	var other := SettingsLogic.new()
	other.load_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(other.to_dict(), s.to_dict())


func test_old_or_partial_settings_keep_defaults() -> void:
	var s := SettingsLogic.new()
	s.load_dict({"fov": 80.0})
	assert_almost(s.fov, 80.0)
	assert_true(s.head_bob)
	assert_almost(s.mouse_sensitivity, 0.0025)


func test_head_bob_is_off_when_disabled_or_still() -> void:
	assert_almost(SettingsLogic.bob_offset(1.3, 1.0, false), 0.0)
	assert_almost(SettingsLogic.bob_offset(1.3, 0.0, true), 0.0)
	var peak := 0.0
	for i in 100:
		peak = maxf(peak, absf(SettingsLogic.bob_offset(i * 0.02, 1.0, true)))
	assert_true(peak > 0.02 and peak < 0.06, "quelques centimètres : %f" % peak)


func test_speedrun_timer_format() -> void:
	assert_eq(HudScript.format_precise(0.0), "00:00:00.00")
	assert_eq(HudScript.format_precise(3725.9), "01:02:05.90")
	assert_eq(HudScript.format_precise(59.999), "00:01:00.00")


# --- Emplacements --------------------------------------------------------------------------

func test_summary_of_empty_and_saved_slot() -> void:
	assert_true(SaveSystem.summary(2, DIR).is_empty())
	gs.current_slot = 2
	gs.play_time_s = 125.0
	gs.ocean.remove_water(3400.0)
	gs.save_game()
	var sm := SaveSystem.summary(2, DIR)
	assert_almost(float(sm.play_time_s), 125.0)
	assert_almost(float(sm.removed_l), 3400.0, 0.01)
	assert_true(float(sm.saved_at_unix) > 1.0e9)


func test_slot_text_shows_empty_or_progress() -> void:
	var empty := MainMenu.slot_text(1, {})
	assert_true(empty.contains("1"), empty)
	var text := MainMenu.slot_text(3, {"play_time_s": 3725.0, "removed_l": 3400.0, "saved_at_unix": 1.79e9})
	assert_true(text.contains("01:02:05"), text)
	assert_true(text.contains("3.40 k"), text)


func test_play_empty_slot_starts_and_saves_a_new_game() -> void:
	assert_false(gs.autosave_enabled, "rien n'est écrit avant d'avoir choisi")
	gs.play_slot(3)
	assert_eq(gs.current_slot, 3)
	assert_true(gs.autosave_enabled)
	assert_true(SaveSystem.exists(3, DIR))
	assert_false(SaveSystem.exists(1, DIR), "l'emplacement 1 n'est pas touché")


func test_play_existing_slot_resumes_it() -> void:
	gs.current_slot = 2
	gs.stock = {"sel": 42}
	gs.play_time_s = 99.0
	gs.save_game()
	gs.new_game()
	gs.play_slot(2)
	assert_eq(int(gs.stock.get("sel", 0)), 42)
	assert_almost(gs.play_time_s, 99.0, 0.01)


func test_slots_are_independent_and_can_be_deleted() -> void:
	gs.play_slot(1)
	gs.stock = {"sel": 7}
	gs.save_game()
	gs.play_slot(2)
	assert_eq(int(gs.stock.get("sel", 0)), 0, "l'emplacement 2 est une partie neuve")
	gs.delete_slot(1)
	assert_false(SaveSystem.exists(1, DIR))
	assert_true(SaveSystem.exists(2, DIR))


func test_no_autosave_until_a_slot_is_chosen() -> void:
	gs.stock = {"sel": 1000, "mineraux": 100}
	gs.order(["bache"])
	gs._process(gs.config.autosave_interval_s + 1.0)
	assert_false(SaveSystem.exists(1, DIR), "menu ouvert : pas d'écriture")


func test_purchase_triggers_an_autosave() -> void:
	gs.play_slot(1)
	gs.stock = {"sel": 1000, "mineraux": 100}
	assert_eq(gs.order(["bache"]).size(), 1)
	var data := SaveSystem.read(1, DIR)
	assert_true(int(data.stock.get("sel", 0)) < 1000, "la sauvegarde contient l'achat (M-77)")
