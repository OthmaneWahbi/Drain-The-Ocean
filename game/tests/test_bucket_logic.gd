extends TestCase


func test_fill_needs_holding_for_fill_time() -> void:
	var b := BucketLogic.new(10.0, 1.0)
	assert_false(b.hold_fill(0.5))
	assert_true(b.hold_fill(0.6), "rempli après ~1 s :")


func test_release_cancels_progress() -> void:
	var b := BucketLogic.new(10.0, 1.0)
	b.hold_fill(0.8)
	b.cancel_fill()
	assert_false(b.hold_fill(0.5))


func test_full_bucket_does_not_fill() -> void:
	var b := BucketLogic.new(10.0, 1.0)
	b.water_l = 10.0
	assert_false(b.hold_fill(5.0))


func test_empty_out_returns_water() -> void:
	var b := BucketLogic.new(10.0, 1.0)
	b.water_l = 7.0
	assert_almost(b.empty_out(), 7.0)
	assert_true(b.is_empty())
