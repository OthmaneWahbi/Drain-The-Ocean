extends TestCase


func test_day_and_night() -> void:
	var d := DayCycleLogic.new(1200.0, 12.0)
	assert_true(d.is_day())
	assert_almost(d.evaporation_multiplier(0.3), 1.0)
	d = DayCycleLogic.new(1200.0, 23.0)
	assert_false(d.is_day())
	assert_almost(d.evaporation_multiplier(0.3), 0.3)


func test_new_morning_is_detected() -> void:
	var d := DayCycleLogic.new(1200.0, 5.5)
	var hour_s := 1200.0 / 24.0
	assert_true(d.step(hour_s), "5 h 30 → 6 h 30 :")
	assert_eq(d.day_index, 1)
	assert_false(d.step(hour_s))


func test_sun_is_up_at_noon_and_down_at_midnight() -> void:
	assert_true(DayCycleLogic.new(1200.0, 13.0).sun_elevation_deg() > 60.0)
	assert_true(DayCycleLogic.new(1200.0, 0.0).sun_elevation_deg() < 0.0)
