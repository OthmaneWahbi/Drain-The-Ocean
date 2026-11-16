extends TestCase


func test_pay_when_affordable() -> void:
	var stock := {"sel": 20, "mineraux": 1}
	assert_true(Economy.pay(stock, {"sel": 15}))
	assert_eq(int(stock["sel"]), 5)


func test_pay_refused_leaves_stock_untouched() -> void:
	var stock := {"sel": 20}
	assert_false(Economy.pay(stock, {"sel": 15, "coquillages": 1}))
	assert_eq(int(stock["sel"]), 20)


func test_sum_of_prices() -> void:
	var total := Economy.sum([{"sel": 15}, {"sel": 40}, {"coquillages": 2}])
	assert_eq(int(total["sel"]), 55)
	assert_eq(int(total["coquillages"]), 2)


func test_sanitize_drops_garbage() -> void:
	var clean := Economy.sanitize({"sel": "3", "mineraux": -2, "x": 0})
	assert_eq(clean, {"sel": 3})
	assert_eq(Economy.sanitize("pas un dict"), {})
