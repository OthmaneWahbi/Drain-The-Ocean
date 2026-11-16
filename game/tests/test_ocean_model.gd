extends TestCase


func test_ocean_starts_full() -> void:
	var o := OceanModel.new(1000.0)
	assert_almost(o.remaining_l(), 1000.0)
	assert_almost(o.remaining_ratio(), 1.0)
	assert_false(o.is_drain_visible())


func test_remove_water_reduces_volume() -> void:
	var o := OceanModel.new(1000.0)
	assert_almost(o.remove_water(10.0), 10.0)
	assert_almost(o.remaining_l(), 990.0)


func test_cannot_remove_more_than_remaining() -> void:
	var o := OceanModel.new(100.0)
	assert_almost(o.remove_water(250.0), 100.0)
	assert_true(o.is_empty())


func test_negative_amounts_are_ignored() -> void:
	var o := OceanModel.new(100.0)
	assert_almost(o.remove_water(-5.0), 0.0)
	o.return_water(-5.0)
	assert_almost(o.removed_l, 0.0)


func test_returned_water_goes_back_to_ocean() -> void:
	var o := OceanModel.new(100.0)
	o.remove_water(30.0)
	o.return_water(10.0)
	assert_almost(o.remaining_l(), 80.0)
	o.return_water(1000.0)
	assert_almost(o.remaining_l(), 100.0, 1e-6, "on ne peut pas dépasser le volume total :")


func test_drain_appears_at_five_percent() -> void:
	var o := OceanModel.new(1000.0, 0.05)
	o.remove_water(949.0)
	assert_false(o.is_drain_visible(), "à 5,1 % :")
	o.remove_water(1.0)
	assert_true(o.is_drain_visible(), "à 5 % :")


func test_small_bucket_counts_on_huge_ocean() -> void:
	# Un seau de 10 L sur 2,8e18 L doit être compté (on stocke le volume retiré).
	var o := OceanModel.new(2.8e18)
	o.remove_water(10.0)
	assert_almost(o.removed_l, 10.0)
	assert_true(o.removed_ratio() > 0.0, "la part retirée doit être non nulle :")


func test_round_trip_dict() -> void:
	var o := OceanModel.new(500.0)
	o.remove_water(123.0)
	var copy := OceanModel.new(500.0)
	copy.load_dict(o.to_dict())
	assert_almost(copy.removed_l, 123.0)


func test_load_dict_is_clamped() -> void:
	var o := OceanModel.new(500.0)
	o.load_dict({"removed_l": 9999.0})
	assert_almost(o.removed_l, 500.0)
