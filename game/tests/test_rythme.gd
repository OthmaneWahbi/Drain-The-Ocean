extends TestCase
## 0.1.24 : le rythme et le confort (temps avant séchage, bonus de voisinage, arrosoir, seau
## percé, mode photo, musique). PRD §19.31.

const GameStateScript := preload("res://core/game_state.gd")
const DryingZoneView := preload("res://scenes/world/drying_zone_view.gd")
const Placement := preload("res://scenes/world/placement_controller.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e12
	gs.setup(cfg)


func after_each() -> void:
	gs.free()


func _noon() -> void:
	gs.day.time_s = 12.0 / 24.0 * gs.day.day_length_s


func _zone() -> Dictionary:
	return gs.zones[0]


# --- Horloges ------------------------------------------------------------------------------

func test_clocks_live_in_the_data() -> void:
	assert_almost(gs.config.basin_dry_time_s, 45.0)
	assert_almost(gs.config.tarp_dry_time_s, 45.0)
	assert_almost(gs.config.marsh_dry_time_s, 60.0)
	assert_true(gs.config.marsh_last_dry_factor < 1.0, "le dernier marais d'une série est plus lent")


func test_seconds_to_dry() -> void:
	var logic := DryingLogic.new(40.0, 40.0)
	assert_eq(logic.seconds_to_dry(1.0), 0.0, "vide : déjà sèche")
	logic.water_l = 20.0
	assert_almost(logic.seconds_to_dry(1.0), 20.0, 1e-6)
	assert_almost(logic.seconds_to_dry(2.0), 10.0, 1e-6)
	assert_false(is_finite(logic.seconds_to_dry(0.0)))


func test_zone_prompt_says_when_it_will_be_dry() -> void:
	_noon()
	gs.set_weather("calme")
	var z := _zone()
	(z.logic as DryingLogic).water_l = 10.0
	var s: float = gs.zone_seconds_to_dry(z)
	assert_almost(s, 10.0 / (z.logic as DryingLogic).evaporation_rate_lps() / gs.zone_boost(z), 1e-3)
	assert_eq(DryingZoneView.format_dry(32.2), TranslationServer.translate("ZONE_DRY_IN") % 33)
	assert_eq(DryingZoneView.format_dry(300.0), TranslationServer.translate("ZONE_DRY_IN_MIN") % 5)
	assert_eq(DryingZoneView.format_dry(INF), "")


# --- Voisinage -----------------------------------------------------------------------------

func test_windward_zone_dries_faster_until_something_is_put_east_of_it() -> void:
	var z := _zone()
	assert_true(gs.is_windward(z, z.position), "rien à l'est de la cuvette de départ")
	assert_almost(gs.zone_boost(z), 1.0 + gs.config.windward_boost, 1e-6)
	var r: Rect2 = gs.item_rect(z)
	gs.add_station("rations", Vector3(r.end.x + 1.5, 0.5, r.get_center().y))
	assert_false(gs.is_windward(z, z.position))
	assert_almost(gs.zone_boost(z), 1.0, 1e-6)


func test_something_west_does_not_block_the_wind() -> void:
	var z := _zone()
	var r: Rect2 = gs.item_rect(z)
	gs.add_station("rations", Vector3(r.position.x - 1.5, 0.5, r.get_center().y))
	assert_true(gs.is_windward(z, z.position))


func test_windmill_nearby_boosts_drying() -> void:
	var z := _zone()
	gs.config.windward_boost = 0.0
	assert_false(gs.near_windmill(z.position))
	gs.pumps.append({"id": "p1", "kind": "moulin_pompe", "position": z.position + Vector3(-5, 0, 0)})
	assert_true(gs.near_windmill(z.position))
	assert_almost(gs.zone_boost(z), 1.0 + gs.config.windmill_boost, 1e-6)
	gs.pumps[0].position = z.position + Vector3(-20, 0, 0)
	assert_almost(gs.zone_boost(z), 1.0, 1e-6)


func test_boosts_multiply_with_mirrors() -> void:
	var z := _zone()
	gs.pumps.append({"id": "p1", "kind": "moulin_pompe", "position": z.position + Vector3(-5, 0, 3)})
	gs.add_mirror(z.position + Vector3(-3, 0, -3))
	var k: float = gs.zone_boost(z)
	assert_almost(k, (1.0 + gs.config.mirror_bonus) * (1.0 + gs.config.windmill_boost) * (1.0 + gs.config.windward_boost), 1e-6)


func test_boost_preview_at_another_spot() -> void:
	var z := _zone()
	gs.add_mirror(Vector3(30.5, 0.5, 30.5))
	assert_true(gs.zone_boost_at(z, Vector3(31.5, 0.5, 33.5)) > gs.zone_boost(z) - 1e-6)
	assert_eq(Placement.boost_text(1.8), "×1,8")
	assert_eq(Placement.boost_text(1.0), "×1,0")


# --- Arrosoir et seau percé ----------------------------------------------------------------

func _give(tool: String) -> void:
	gs.apply_item(gs.catalog.find(StringName(tool)), Vector3.ZERO)


func test_watering_can_and_leaky_bucket_in_the_catalogue() -> void:
	var can: CatalogItem = gs.catalog.find(&"arrosoir")
	var leaky: CatalogItem = gs.catalog.find(&"seau_perce")
	assert_eq(can.price, {"sel": 35, "mineraux": 2})
	assert_eq(leaky.price, {"sel": 1})
	assert_false(gs.owns_tool("arrosoir"))
	_give("arrosoir")
	_give("seau_perce")
	assert_true(gs.owns_tool("arrosoir") and gs.owns_tool("seau_perce"))
	assert_true(gs.toolbar.index_of("arrosoir") >= 0, "l'arrosoir va dans la barre")


func test_fill_takes_water_from_the_ocean() -> void:
	_give("arrosoir")
	var before: float = gs.ocean.removed_l
	assert_almost(gs.fill_vessel("arrosoir"), 15.0, 1e-6)
	assert_almost(gs.vessel_l("arrosoir"), 15.0, 1e-6)
	assert_almost(gs.ocean.removed_l - before, 15.0, 1e-6)
	assert_almost(gs.fill_vessel("arrosoir"), 0.0, 1e-6, "déjà plein")


func test_watering_shares_between_zones_in_reach() -> void:
	_give("arrosoir")
	var a := _zone()
	var b: Dictionary = gs.add_zone("bache", a.position + Vector3(0, 0, 4))
	var far: Dictionary = gs.add_zone("bache", a.position + Vector3(0, 0, 30))
	var mid: Vector3 = (a.position + b.position) / 2.0
	assert_eq(gs.vessel_targets("arrosoir", mid).size(), 2)
	gs.fill_vessel("arrosoir")
	assert_almost(gs.pour_vessel("arrosoir", mid), 15.0, 1e-6)
	assert_almost((a.logic as DryingLogic).water_l, 7.5, 1e-6)
	assert_almost((b.logic as DryingLogic).water_l, 7.5, 1e-6)
	assert_almost((far.logic as DryingLogic).water_l, 0.0, 1e-6)
	assert_almost(gs.vessel_l("arrosoir"), 0.0, 1e-6)


func test_a_full_zone_passes_its_share_to_the_others() -> void:
	_give("arrosoir")
	var a := _zone()
	var b: Dictionary = gs.add_zone("bache", a.position + Vector3(0, 0, 4))
	var la: DryingLogic = a.logic
	la.water_l = la.capacity_l - 2.0
	gs.fill_vessel("arrosoir")
	gs.pour_vessel("arrosoir", (a.position + b.position) / 2.0)
	assert_almost(la.water_l, la.capacity_l, 1e-6)
	assert_almost((b.logic as DryingLogic).water_l, 13.0, 1e-6)


func test_leaky_bucket_leaks_back_to_the_sea() -> void:
	_give("seau_perce")
	gs.fill_vessel("seau_perce")
	assert_almost(gs.vessel_l("seau_perce"), 10.0, 1e-6)
	var removed: float = gs.ocean.removed_l
	gs.simulate(3.0)
	assert_almost(gs.vessel_l("seau_perce"), 7.0, 1e-6)
	assert_almost(removed - gs.ocean.removed_l, 3.0, 1e-6, "la fuite retourne à la mer")
	gs.simulate(20.0)
	assert_almost(gs.vessel_l("seau_perce"), 0.0, 1e-6)


func test_leaky_bucket_pours_into_the_aimed_zone_only() -> void:
	_give("seau_perce")
	var a := _zone()
	var b: Dictionary = gs.add_zone("bache", a.position + Vector3(0, 0, 4))
	gs.fill_vessel("seau_perce")
	assert_eq(gs.vessel_targets("seau_perce", a.position).size(), 1)
	gs.pour_vessel("seau_perce", a.position)
	assert_almost((a.logic as DryingLogic).water_l, 10.0, 1e-6)
	assert_almost((b.logic as DryingLogic).water_l, 0.0, 1e-6)


func test_vessels_saved() -> void:
	_give("arrosoir")
	gs.fill_vessel("arrosoir")
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.vessels.clear()
	gs.load_dict(data)
	assert_almost(gs.vessel_l("arrosoir"), 15.0, 1e-6)


# --- Mode photo et musique -----------------------------------------------------------------

func test_photo_mode_helpers() -> void:
	assert_true(InputMap.has_action(&"photo_mode"))
	assert_eq(PhotoMode.photo_path(123), "user://photos/photo_123.png")
	assert_eq(PhotoMode.clamp_fov(5.0), PhotoMode.FOV_MIN)
	assert_eq(PhotoMode.clamp_fov(500.0), PhotoMode.FOV_MAX)
	assert_eq(PhotoMode.FILTERS.size(), 4)


func test_music_moment_follows_the_hour() -> void:
	var m: Dictionary = gs.config.music_moments
	assert_eq(MusicBoard.moment_at(7.0, m), "matin")
	assert_eq(MusicBoard.moment_at(12.0, m), "midi")
	assert_eq(MusicBoard.moment_at(18.0, m), "soir")
	assert_eq(MusicBoard.moment_at(23.0, m), "nuit")
	assert_eq(MusicBoard.moment_at(3.0, m), "nuit", "avant 6 h, c'est encore la nuit")
	assert_almost(MusicBoard.fade_in(4.0, 8.0), 0.5, 1e-6)


func test_music_loops_are_whole_and_quiet_enough() -> void:
	for moment: String in SoundSynth.MUSIC:
		var data := SoundSynth.music_samples(moment)
		var r: Dictionary = SoundSynth.MUSIC_RECIPES[moment]
		var expected := int(16 * 60.0 / float(r.tempo) * SoundSynth.MUSIC_RATE)
		assert_eq(data.size(), expected, moment)
		var p := SoundSynth.peak(data)
		assert_true(p > 0.05 and p <= 1.0, "%s : crête %f" % [moment, p])
	assert_true(SoundSynth.MUSIC_RECIPES["nuit"].tempo < SoundSynth.MUSIC_RECIPES["matin"].tempo, "la nuit, plus lent")


func test_music_volume_setting() -> void:
	var s := SettingsLogic.new()
	s.load_dict({"music_volume": 3.0})
	assert_almost(s.music_volume, 1.0, 1e-6)
	assert_true(s.to_dict().has("music_volume"))
