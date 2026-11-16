extends TestCase
## Endurance (N-05) : ~20 s de course, ~60 s de nage, ne remonte qu'à l'arrêt sur terre.


func _make() -> StaminaLogic:
	return StaminaLogic.new(20.0, 60.0, 5.0, 0.25)


func test_running_empties_in_twenty_seconds() -> void:
	var s := _make()
	s.step(19.0, StaminaLogic.Activity.RUN)
	assert_true(s.can_run())
	s.step(1.0, StaminaLogic.Activity.RUN)
	assert_true(s.is_empty())
	assert_false(s.can_run(), "essoufflé :")


func test_swimming_lasts_sixty_seconds() -> void:
	var s := _make()
	s.step(59.0, StaminaLogic.Activity.SWIM)
	assert_false(s.is_empty())
	s.step(1.0, StaminaLogic.Activity.SWIM)
	assert_true(s.is_empty())


func test_never_recovers_in_water_nor_while_walking() -> void:
	var s := _make()
	s.step(30.0, StaminaLogic.Activity.SWIM)
	var before := s.value
	s.step(10.0, StaminaLogic.Activity.WALK_ON_LAND)
	assert_almost(s.value, before)


func test_recovers_at_rest_on_land_and_exhaustion_ends() -> void:
	var s := _make()
	s.step(20.0, StaminaLogic.Activity.RUN)
	s.step(1.0, StaminaLogic.Activity.REST_ON_LAND)  # 0,2
	assert_false(s.can_run(), "encore essoufflé à 20 % :")
	s.step(0.5, StaminaLogic.Activity.REST_ON_LAND)  # 0,3
	assert_true(s.can_run())
	s.step(10.0, StaminaLogic.Activity.REST_ON_LAND)
	assert_true(s.is_full())
