extends TestCase

var rng := RandomNumberGenerator.new()


func before_each() -> void:
	rng.seed = 42


func test_zone_refuses_water_when_full() -> void:
	var z := DryingLogic.new(40.0, 45.0)
	assert_almost(z.add_water(30.0), 30.0)
	assert_almost(z.add_water(30.0), 10.0, 1e-6, "seulement 10 L de place :")
	assert_almost(z.free_space_l(), 0.0)


func test_full_basin_dries_in_dry_time() -> void:
	# Évaporation limitée par la surface : 40 L en 45 s au soleil (M-37).
	var z := DryingLogic.new(40.0, 45.0)
	z.add_water(40.0)
	for i in 45:
		z.step(1.0, 1.0, rng)
	assert_almost(z.water_l, 0.0, 1e-3)
	assert_eq(int(z.deposit.get("sel", 0)), 4, "1 sel par 10 L :")


func test_night_is_slower() -> void:
	var z := DryingLogic.new(40.0, 45.0)
	z.add_water(40.0)
	z.step(45.0, 0.3, rng)
	assert_almost(z.water_l, 28.0, 1e-3, "×0,3 la nuit :")


func test_harvest_empties_deposit() -> void:
	var z := DryingLogic.new(10.0, 10.0)
	z.add_water(10.0)
	z.step(10.0, 1.0, rng)
	assert_true(z.has_deposit())
	var taken := z.take_deposit()
	assert_eq(int(taken["sel"]), 1)
	assert_false(z.has_deposit())


func test_mineral_rates_are_roughly_right() -> void:
	var z := DryingLogic.new(100000.0, 1.0)
	z.add_water(100000.0)  # 10 000 tirages
	z.step(1.0, 1.0, rng)
	var minerals := int(z.deposit.get("mineraux", 0))
	assert_eq(int(z.deposit["sel"]), 10000)
	assert_true(minerals > 850 and minerals < 1150, "~10 %% de minéraux, obtenu %d" % minerals)


func test_round_trip() -> void:
	var z := DryingLogic.new(40.0, 45.0)
	z.add_water(25.0)
	z.deposit = {"sel": 3}
	var c := DryingLogic.new(40.0, 45.0)
	c.load_dict(z.to_dict())
	assert_almost(c.water_l, 25.0)
	assert_eq(int(c.deposit["sel"]), 3)
