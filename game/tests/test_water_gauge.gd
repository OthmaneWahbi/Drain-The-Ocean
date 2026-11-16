extends TestCase
## Repère de niveau d'eau (N-10) : chiffre honnête, aiguille logarithmique.


func test_needle_moves_from_the_first_bucket() -> void:
	# 10 L sur 2,83 × 10¹³ m² ≈ 3,5 × 10⁻¹⁶ m.
	var drop := 10.0 / 1000.0 / 2.83e13
	assert_true(WaterGauge.needle_ratio(drop) > 0.0)
	assert_eq(WaterGauge.needle_ratio(0.0), 0.0)
	assert_eq(WaterGauge.needle_ratio(5.0), 1.0, "butée à 1 m :")


func test_each_power_of_ten_is_one_step() -> void:
	var step := WaterGauge.needle_ratio(1e-6) - WaterGauge.needle_ratio(1e-7)
	assert_almost(step, 1.0 / 16.0, 1e-6)


func test_honest_text() -> void:
	assert_eq(WaterGauge.format_drop_mm(0.0), "0 mm")
	assert_eq(WaterGauge.format_drop_mm(3.5e-16), "−3,5 × 10⁻¹³ mm")
	assert_eq(WaterGauge.format_drop_mm(0.0123), "−12,3 mm")
