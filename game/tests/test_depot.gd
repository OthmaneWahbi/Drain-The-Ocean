extends TestCase
## Palette : la hauteur d'un tas grandit vite au début, puis ralentit, et reste plafonnée.

const Depot := preload("res://scenes/world/depot.gd")


func test_pile_height() -> void:
	assert_eq(Depot.pile_height(0), 0.0)
	assert_true(Depot.pile_height(10) > Depot.pile_height(1))
	assert_true(Depot.pile_height(100) - Depot.pile_height(10) < Depot.pile_height(10), "ralentit :")
	assert_true(Depot.pile_height(1000000) <= 1.5)
