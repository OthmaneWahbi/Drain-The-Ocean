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


func _harvest_all(zone: Dictionary) -> void:
	while zone.logic.has_deposit() and gs.carry_space() > 0:
		gs.harvest(zone)


func test_full_loop_to_first_purchase() -> void:
	var basin: Dictionary = gs.zones[0]
	# 4 L par sel : une cuvette pleine (40 L, séchée en 45 s) donne 10 sel. Deux tournées suffisent.
	for round in 2:
		for i in 4:
			gs.fill_bucket()
			gs.pour_bucket_into(basin)
		_dry_all(45.0)
		_harvest_all(basin)
		gs.unload_to_stock()
	assert_eq(int(gs.stock["sel"]), 20)
	var crate: Dictionary = gs.order(["bache"])
	assert_false(crate.is_empty(), "commande acceptée :")
	assert_eq(int(gs.stock["sel"]), 5)
	gs.open_crate(crate)
	assert_eq(gs.zones.size(), 2)
	assert_eq(gs.zones[1].kind, "bache")
	assert_true(gs.crates.is_empty())


## Rythme demandé par Othmane : premier achat vers 1 min 30. Le séchage des 15 sel de la bâche
## doit tenir dans ~70 s, pour laisser ~20 s aux trajets, à la récolte et à la commande.
func test_first_purchase_drying_time_fits_ninety_seconds() -> void:
	var cfg: GameConfig = gs.config
	var price: int = int(gs.catalog.find(&"bache").price["sel"])
	var liters: float = price * cfg.liters_per_salt
	var rate: float = cfg.basin_capacity_l / cfg.basin_dry_time_s
	assert_true(liters / rate <= 70.0, "séchage de %d sel : %.0f s" % [price, liters / rate])


func test_order_refused_without_enough_stock() -> void:
	assert_true(gs.order(["bache"]).is_empty())
	assert_true(gs.crates.is_empty())


func test_manual_harvest_takes_a_few_per_click() -> void:
	var basin: Dictionary = gs.zones[0]
	basin.logic.deposit = {"sel": 8}
	gs.harvest(basin)
	assert_eq(gs.carried_count(), 3, "M-39, à la main :")
	assert_eq(int(basin.logic.deposit["sel"]), 5)


func test_hand_carry_limit_leaves_rest_in_zone() -> void:
	var basin: Dictionary = gs.zones[0]
	basin.logic.deposit = {"sel": 14}
	_harvest_all(basin)
	assert_eq(gs.carried_count(), 10)
	assert_eq(int(basin.logic.deposit["sel"]), 4)


func test_rake_harvests_everything_at_once() -> void:
	gs.stock = {"sel": 60, "mineraux": 5}
	gs.open_crate(gs.order(["rateau"]))
	var basin: Dictionary = gs.zones[0]
	basin.logic.deposit = {"sel": 8}
	gs.harvest(basin)
	assert_eq(gs.carried_count(), 8)
	assert_false(basin.logic.has_deposit())


func test_wheelbarrow_carries_more() -> void:
	gs.stock["sel"] = 30
	gs.open_crate(gs.order(["brouette"]))
	assert_eq(gs.carry_capacity, 40)
	assert_eq(gs.carry_space(), 40)


func test_yoke_doubles_buckets_and_stacks_with_big_bucket() -> void:
	gs.stock = {"sel": 200, "mineraux": 10}
	gs.open_crate(gs.order(["palanche"]))
	assert_almost(gs.bucket.capacity_l, 20.0, 1e-6, "2 × 10 L :")
	gs.open_crate(gs.order(["grand_seau"]))
	assert_almost(gs.bucket.capacity_l, 40.0, 1e-6, "2 × 20 L :")


func test_flip_flops_need_shells() -> void:
	gs.stock["sel"] = 25
	assert_true(gs.order(["tongs"]).is_empty(), "il manque 2 coquillages :")
	gs.stock["coquillages"] = 2
	gs.open_crate(gs.order(["tongs"]))
	assert_almost(gs.speed_multiplier, 1.2)


func test_water_level_drops_with_removed_volume() -> void:
	gs.config.ocean_surface_m2 = 1000.0
	gs.ocean.remove_water(1000.0)  # 1 m³ sur 1 000 m² = 1 mm
	assert_almost(gs.water_level_y(), gs.config.sea_level_y - 0.001, 1e-9)


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


func test_save_keeps_upgrades() -> void:
	gs.stock = {"sel": 300, "mineraux": 20, "coquillages": 2}
	gs.open_crate(gs.order(["palanche", "grand_seau", "brouette", "rateau", "tongs"]))
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_almost(other.bucket.capacity_l, 40.0)
	assert_eq(other.carry_capacity, 40)
	assert_true(other.has_rake)
	assert_almost(other.speed_multiplier, 1.2)
	other.free()
