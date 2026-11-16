extends TestCase
## Le HUD allégé (0.1.3) : faim et soif en jauges rondes animées, le reste dans le menu pause.


func test_need_gauge_follows_the_level_smoothly() -> void:
	var g := NeedGauge.new(NeedGauge.Kind.WATER)
	g.level = 0.2
	g._process(0.1)
	assert_true(g.shown < 1.0 and g.shown > 0.2, "elle descend en douceur : %f" % g.shown)
	for i in 60:
		g._process(0.1)
	assert_almost(g.shown, 0.2, 0.01)
	assert_true(g.liquid_color().b > g.liquid_color().r, "l'eau est bleue")
	assert_true(NeedGauge.new(NeedGauge.Kind.FOOD).liquid_color().r > 0.8, "la soupe est orange")
	g.free()


func test_need_gauge_beats_when_almost_empty() -> void:
	var g := NeedGauge.new(NeedGauge.Kind.FOOD)
	g.level = 0.1
	g.shown = 0.1
	var biggest := 1.0
	for i in 30:
		g._process(0.03)
		biggest = maxf(biggest, g.scale.x)
	assert_true(biggest > 1.03, "elle bat : %f" % biggest)
	g.level = 0.9
	g.shown = 0.9
	g._process(0.03)
	assert_almost(g.scale.x, 1.0)
	g.free()


func test_island_report_lists_what_the_hud_no_longer_shows() -> void:
	var gs: Node = load("res://core/game_state.gd").new()
	gs.setup()
	var text := PauseMenu.island_report(gs)
	gs.free()
	for key in ["HUD_OCEAN_REMAINING", "HUD_STOCK", "HUD_CARRIED", "PAUSE_INFO_HOUR"]:
		assert_true(text.contains(TranslationServer.translate(key)), key)
	assert_eq(text.split("\n").size(), 7)
