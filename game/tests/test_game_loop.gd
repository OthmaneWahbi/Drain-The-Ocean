extends TestCase
## La boucle complète du MVP, sans scène 3D : puiser → sécher → récolter → déposer → commander → ouvrir.

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	cfg.shell_chance_per_scoop = 0.0
	cfg.mineral_chance = 0.0
	cfg.rare_mineral_chance = 0.0
	gs.setup(cfg)


func after_each() -> void:
	gs.free()


func _dry_all(seconds: float) -> void:
	for z in gs.zones:
		z.logic.step(seconds, 1.0, gs.rng)


func test_new_game_has_the_starting_basin() -> void:
	assert_eq(gs.zones.size(), 1)
	assert_eq(gs.zones[0].kind, "cuvette")
	assert_almost(gs.bucket.capacity_l, 10.0)


func test_scoop_removes_water_from_ocean() -> void:
	gs.fill_bucket()
	assert_almost(gs.bucket.water_l, 10.0)
	assert_almost(gs.ocean.removed_l, 10.0)


func test_pour_on_sand_returns_water_to_ocean() -> void:
	gs.fill_bucket()
	gs.pour_bucket_out()
	assert_almost(gs.ocean.removed_l, 0.0, 1e-6, "M-34 :")
	assert_true(gs.bucket.is_empty())


func test_full_loop_to_first_purchase() -> void:
	var basin: Dictionary = gs.zones[0]
	# 15 sel = 150 L : 4 seaux par cuvette, séchés en 45 s.
	for round in 4:
		for i in 4:
			gs.fill_bucket()
			gs.pour_bucket_into(basin)
		_dry_all(45.0)
		gs.harvest(basin)
		gs.unload_to_stock()
	assert_eq(int(gs.stock["sel"]), 16)
	var crate: Dictionary = gs.order(["bache"])
	assert_false(crate.is_empty(), "commande acceptée :")
	assert_eq(int(gs.stock["sel"]), 1)
	gs.open_crate(crate)
	assert_eq(gs.zones.size(), 2)
	assert_eq(gs.zones[1].kind, "bache")
	assert_true(gs.crates.is_empty())


func test_order_refused_without_enough_stock() -> void:
	assert_true(gs.order(["bache"]).is_empty())
	assert_true(gs.crates.is_empty())


func test_hand_carry_limit_leaves_rest_in_zone() -> void:
	var basin: Dictionary = gs.zones[0]
	basin.logic.deposit = {"sel": 14}
	gs.harvest(basin)
	assert_eq(gs.carried_count(), 10)
	assert_eq(int(basin.logic.deposit["sel"]), 4)


func test_big_bucket_is_unique_and_upgrades() -> void:
	gs.stock["sel"] = 100
	var crate: Dictionary = gs.order(["grand_seau"])
	gs.open_crate(crate)
	assert_almost(gs.bucket.capacity_l, 20.0)
	assert_true(gs.order(["grand_seau"]).is_empty(), "achat unique :")


func test_boat_arrives_in_a_bottle() -> void:
	gs.stock["sel"] = 999
	gs.open_crate(gs.order(["bateau"]))
	assert_eq(gs.decor.size(), 1)
	assert_eq(gs.decor[0].kind, "bateau_en_bouteille")


func test_save_round_trip_keeps_everything() -> void:
	gs.stock["sel"] = 200
	gs.open_crate(gs.order(["bache"]))
	var pending: Dictionary = gs.order(["grand_seau"])
	gs.fill_bucket()
	gs.pour_bucket_into(gs.zones[1])
	gs.carried = {"coquillages": 2}
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(other.zones.size(), 2)
	assert_almost(other.zones[1].logic.water_l, 10.0)
	assert_eq(other.crates.size(), 1, "caisse pas encore ouverte :")
	assert_eq(int(other.carried["coquillages"]), 2)
	assert_eq(int(other.stock["sel"]), 200 - 15 - 40)
	assert_true(other.owned.has("grand_seau"))
	assert_almost(other.ocean.removed_l, 10.0)
	other.free()
