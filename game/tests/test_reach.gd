extends TestCase
## 0.1.6 (Othmane) : on ne pose pas un objet très loin de soi, et les tuyaux, désormais solides,
## ne se posent jamais dans le joueur.

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	gs.setup(cfg)
	gs.pickups.clear()


func after_each() -> void:
	gs.free()


func test_objects_are_placed_only_within_reach() -> void:
	var reach: float = gs.config.place_reach_m
	assert_true(reach >= 3.0 and reach <= 10.0, "une portée raisonnable : %f" % reach)
	var m: Dictionary = gs.add_mirror(Vector3(-15, 0.5, -15))
	gs.player_position = Vector3(-4, 0.5, -5)
	assert_true(gs.in_place_reach(m, Vector3(-4, 0.5, -7.5), 0.0), "à deux pas")
	# Le miroir fait 2 × 1 cases : son bord est à 0,5 m de son centre en z.
	assert_true(gs.in_place_reach(m, Vector3(-4, 0.5, -5 - reach + 0.4), 0.0), "le bord est à portée")
	assert_false(gs.in_place_reach(m, Vector3(-4, 0.5, -5 - reach - 1.5), 0.0), "trop loin")
	# Une grande cuvette se pose plus loin du joueur : c'est son bord qui compte.
	var basin: Dictionary = gs.zones[0]
	assert_true(gs.in_place_reach(basin, Vector3(-4.5 - reach - 1.0, 0.5, -5.5), 0.0), "le bac déborde vers le joueur")


func test_a_pipe_never_goes_into_the_player() -> void:
	gs.pipe_stock = 10
	gs.player_position = Vector3(-3.5, 0.5, -6.5)
	assert_false(gs.can_place_pipe(Vector3i(-4, 0, -7)), "à ses pieds")
	assert_true(gs.place_pipe(Vector3i(-3, 0, -7)), "juste à côté")
	assert_false(gs.can_place_pipe(Vector3i(-4, 1, -7)), "à hauteur de tête")
	assert_true(gs.place_pipe(Vector3i(-3, 1, -7)))
	assert_true(gs.place_pipe(Vector3i(-3, 2, -7)))
	assert_true(gs.place_pipe(Vector3i(-4, 2, -7)), "au-dessus de sa tête : oui")
