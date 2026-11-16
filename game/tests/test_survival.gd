extends TestCase
## Faim et soif légères (N-03) et objets à portions (N-02).


func test_needs_empty_slowly() -> void:
	var s := SurvivalLogic.new(900.0, 600.0, 0.3, 120.0)
	s.step(300.0)
	assert_almost(s.water, 0.5, 1e-6)
	assert_almost(s.food, 1.0 - 300.0 / 900.0, 1e-6)
	assert_almost(s.stamina_cap(), 1.0, 1e-6, "pas de pénalité tant que rien n'est vide :")


func test_empty_need_lowers_max_stamina_without_death() -> void:
	var s := SurvivalLogic.new(900.0, 600.0, 0.3, 120.0)
	s.step(600.0)  # soif à zéro
	s.step(60.0)
	assert_almost(s.thirst_penalty, 0.15, 1e-6, "la pénalité grandit petit à petit :")
	s.step(10000.0)
	assert_almost(s.stamina_cap(), 0.4, 1e-6, "plafond : 1 − 0,3 − 0,3 :")


func test_drinking_clears_the_penalty_at_once() -> void:
	var s := SurvivalLogic.new(900.0, 600.0, 0.3, 120.0)
	s.step(2000.0)
	s.drink(0.5)
	assert_eq(s.thirst_penalty, 0.0)
	assert_almost(s.water, 0.5)


func test_stamina_is_capped() -> void:
	var st := StaminaLogic.new()
	st.set_max(0.4)
	assert_almost(st.value, 0.4)
	st.step(100.0, StaminaLogic.Activity.REST_ON_LAND)
	assert_true(st.is_full(), "pleine = au plafond :")


func test_condenser_fills_up_to_capacity() -> void:
	var c := StationLogic.new(0, 3, 90.0)
	c.step(200.0)
	assert_eq(c.amount, 2)
	c.step(1000.0)
	assert_eq(c.amount, 3)
	assert_true(c.take_one())
	assert_false(c.is_spent(), "elle produit encore :")


func test_rations_are_spent() -> void:
	var r := StationLogic.new(2, 2, 0.0)
	r.step(1000.0)
	assert_eq(r.amount, 2, "ne produit rien :")
	r.take_one()
	r.take_one()
	assert_false(r.take_one())
	assert_true(r.is_spent())
