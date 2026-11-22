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
	cfg.pearl_chance_per_shell = 0.0
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
	for i in 500:
		var before: int = gs.carried_count()
		if not zone.logic.has_deposit():
			return
		gs.harvest(zone)
		if gs.carried_count() == before:
			return  # plus de place


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
	var crate: Dictionary = gs.order(["bache"])[0]
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


func test_can_pay_with_hands_and_pallet_together() -> void:
	gs.stock["sel"] = 10
	gs.carried = {"sel": 5}
	assert_false(gs.order(["bache"]).is_empty(), "5 dans les bras + 10 sur la palette = 15 :")
	assert_eq(gs.carried_count(), 0)
	assert_eq(int(gs.stock["sel"]), 0)


func test_order_refused_without_enough_stock() -> void:
	assert_true(gs.order(["bache"]).is_empty())
	assert_true(gs.crates.is_empty())


func test_manual_harvest_takes_a_few_per_click() -> void:
	var basin: Dictionary = gs.zones[0]
	basin.logic.deposit = {"sel": 8}
	gs.harvest(basin)
	assert_eq(gs.carried_count(), 3, "M-39, à la main :")
	assert_eq(int(basin.logic.deposit["sel"]), 5)


func test_slot_limit_leaves_rest_in_zone() -> void:
	# 0.1.4 : 64 par case (plus de limite totale de 10) ; le surplus reste dans la zone.
	var basin: Dictionary = gs.zones[0]
	basin.logic.deposit = {"sel": 70}
	_harvest_all(basin)
	assert_eq(gs.carried_count(), 64)
	assert_eq(int(basin.logic.deposit["sel"]), 6)


func test_each_slot_holds_64_of_its_material() -> void:
	# Six cases : le seau en prend une, il en reste cinq de 64 (Othmane, 0.1.4 ; 0.1.11 : la pelle
	# s'achète, une case de plus au départ). La pelle achetée en reprend une.
	gs.has_shovel = true
	gs._sync_toolbar()
	gs.add_carried({"sel": 64, "mineraux": 64, "coquillages": 64})
	assert_eq(gs.carried_count(), 192, "bien au-delà de l'ancienne limite de 40 :")
	assert_eq(gs.carry_space("sel"), 0)
	assert_eq(gs.carry_space("perles"), 64)
	var left: Dictionary = gs.add_carried({"perles": 70, "mineraux_rares": 5})
	assert_eq(int(left.get("perles", 0)), 6)
	assert_eq(int(left.get("mineraux_rares", 0)), 5, "plus de case libre :")


func test_rake_harvests_everything_at_once() -> void:
	gs.stock = {"sel": 60, "mineraux": 5}
	gs.open_crates(gs.order(["rateau"]))
	var basin: Dictionary = gs.zones[0]
	basin.logic.deposit = {"sel": 8}
	gs.harvest(basin)
	assert_eq(gs.carried_count(), 3, "râteau acheté mais pas en main : 3 par 3")
	gs.select_tool(gs.toolbar.index_of("rateau"))
	assert_eq(gs.current_tool(), "rateau")
	gs.harvest(basin)
	assert_eq(gs.carried_count(), 8)
	assert_false(basin.logic.has_deposit())


func test_wheelbarrow_carries_more() -> void:
	gs.stock["sel"] = 30
	gs.open_crates(gs.order(["brouette"]))
	assert_eq(gs.carry_capacity, 128)
	assert_eq(gs.carry_space("sel"), 128)


func test_yoke_doubles_buckets_and_stacks_with_big_bucket() -> void:
	gs.stock = {"sel": 200, "mineraux": 10}
	gs.open_crates(gs.order(["palanche"]))
	assert_almost(gs.bucket.capacity_l, 20.0, 1e-6, "2 × 10 L :")
	gs.open_crates(gs.order(["grand_seau"]))
	assert_almost(gs.bucket.capacity_l, 40.0, 1e-6, "2 × 20 L :")


func test_flip_flops_need_shells() -> void:
	gs.stock["sel"] = 25
	assert_true(gs.order(["tongs"]).is_empty(), "il manque 2 coquillages :")
	gs.stock["coquillages"] = 2
	gs.open_crates(gs.order(["tongs"]))
	assert_almost(gs.speed_multiplier, 1.2)


func test_water_level_drops_with_removed_volume() -> void:
	gs.config.ocean_surface_m2 = 1000.0
	gs.ocean.remove_water(1000.0)  # 1 m³ sur 1 000 m² = 1 mm
	assert_almost(gs.honest_water_level_y(), gs.config.sea_level_y - 0.001, 1e-9)


func test_big_bucket_is_unique_and_upgrades() -> void:
	gs.stock["sel"] = 100
	var crate: Dictionary = gs.order(["grand_seau"])[0]
	gs.open_crate(crate)
	assert_almost(gs.bucket.capacity_l, 20.0)
	assert_true(gs.order(["grand_seau"]).is_empty(), "achat unique :")


func test_boat_arrives_in_a_bottle() -> void:
	gs.stock["sel"] = 999
	gs.open_crates(gs.order(["bateau"]))
	assert_eq(gs.decor.size(), 1)
	assert_eq(gs.decor[0].kind, "bateau_en_bouteille")


func test_save_round_trip_keeps_everything() -> void:
	gs.stock["sel"] = 200
	gs.open_crates(gs.order(["bache"]))
	var pending: Dictionary = gs.order(["grand_seau"])[0]
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
	gs.open_crates(gs.order(["palanche", "grand_seau", "brouette", "rateau", "tongs"]))
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_almost(other.bucket.capacity_l, 40.0)
	assert_eq(other.carry_capacity, 128)
	assert_true(other.has_rake)
	assert_almost(other.speed_multiplier, 1.2)
	other.free()


func test_new_game_puts_coconuts_and_shells() -> void:
	var coconuts: Array = gs.pickups.filter(func(p): return p.kind == "coconut")
	var shells: Array = gs.pickups.filter(func(p): return p.kind == "shell")
	assert_eq(coconuts.size(), gs.config.coconut_spots.size())
	assert_eq(shells.size(), gs.config.shells_per_morning)


func test_eating_a_coconut_feeds_and_waters() -> void:
	gs.survival.food = 0.2
	gs.survival.water = 0.2
	var nut: Dictionary = gs.pickups.filter(func(p): return p.kind == "coconut")[0]
	assert_true(gs.take_pickup(nut))
	assert_almost(gs.survival.food, 0.55, 1e-6)
	assert_almost(gs.survival.water, 0.45, 1e-6)
	assert_false(gs.pickups.has(nut))


func test_shells_go_to_hands_and_come_back_each_morning() -> void:
	for shell in gs.pickups.filter(func(p): return p.kind == "shell"):
		gs.take_pickup(shell)
	assert_eq(int(gs.carried["coquillages"]), gs.config.shells_per_morning)
	gs._morning_refill()
	assert_eq(gs.pickups.filter(func(p): return p.kind == "shell").size(), gs.config.shells_per_morning)
	assert_eq(gs.pickups.filter(func(p): return p.kind == "coconut").size(), gs.config.coconut_spots.size(), "une seule noix par place :")


func test_condenser_and_rations_from_catalogue() -> void:
	gs.stock["sel"] = 28
	gs.open_crates(gs.order(["condenseur", "rations"]))
	assert_eq(gs.stations.size(), 2)
	var condenser: Dictionary = gs.stations.filter(func(st): return st.kind == "condenseur")[0]
	var rations: Dictionary = gs.stations.filter(func(st): return st.kind == "rations")[0]
	assert_false(gs.use_station(condenser), "vide au début :")
	condenser.logic.step(gs.config.condenser_period_s)
	gs.survival.water = 0.1
	assert_true(gs.use_station(condenser))
	assert_almost(gs.survival.water, 0.6, 1e-6)
	for i in gs.config.ration_portions:
		gs.use_station(rations)
	assert_false(gs.stations.has(rations), "caisse de rations vide = retirée :")


func test_save_keeps_survival_pickups_and_stations() -> void:
	gs.survival.food = 0.3
	gs.stock["sel"] = 20
	gs.open_crates(gs.order(["condenseur"]))
	gs.stations[0].logic.amount = 2
	gs.take_pickup(gs.pickups[0])
	var n: int = gs.pickups.size()
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(other.pickups.size(), n)
	assert_eq(other.stations.size(), 1)
	assert_eq(other.stations[0].logic.amount, 2)
	assert_almost(other.survival.food, gs.survival.food, 1e-6)
	other.free()


func test_fast_forward_moves_hunger_drying_and_condenser() -> void:
	var basin: Dictionary = gs.zones[0]
	basin.logic.add_water(40.0)
	gs.advance_time(150.0)
	assert_true(gs.survival.water < 1.0, "la soif baisse :")
	assert_true(gs.survival.food < 1.0, "la faim baisse :")
	assert_almost(basin.logic.water_l, 0.0, 1e-6, "la cuvette a séché :")


func test_tier_two_is_locked_until_the_manual() -> void:
	gs.stock = {"sel": 2000, "mineraux": 200, "mineraux_rares": 20, "coquillages": 20}
	assert_true(gs.order(["bassin_bois"]).is_empty(), "T2 verrouillé :")
	gs.open_crates(gs.order(["manuel"]))
	assert_eq(gs.unlocked_tier, 2)
	gs.open_crates(gs.order(["bassin_bois"]))
	var basin: Dictionary = gs.zones.filter(func(z): return z.kind == "bassin_bois")[0]
	assert_almost(basin.logic.capacity_l, 200.0)


func test_solar_mirror_boosts_nearby_zones_only() -> void:
	var basin: Dictionary = gs.zones[0]
	assert_almost(gs.zone_boost(basin), 1.0)
	gs.add_mirror(basin.position + Vector3(2, 0, 0))
	gs.add_mirror(basin.position + Vector3(50, 0, 0))
	assert_almost(gs.zone_boost(basin), 1.5, 1e-6, "un seul miroir assez proche :")
	basin.logic.add_water(40.0)
	gs.day.time_s = 12.0 / 24.0 * gs.day.day_length_s
	gs.simulate(10.0)
	assert_almost(basin.logic.water_l, 40.0 - 40.0 / 45.0 * 10.0 * 1.5, 1e-3)


func test_save_keeps_tier_and_mirrors() -> void:
	gs.unlocked_tier = 2
	gs.add_mirror(Vector3(1, 0.5, 2))
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(other.unlocked_tier, 2)
	assert_eq(other.mirrors.size(), 1)
	other.free()
