extends TestCase
## Palette : la hauteur d'un tas grandit vite au début, puis ralentit, et reste plafonnée.

const Depot := preload("res://scenes/world/depot.gd")


func test_pile_height() -> void:
	assert_eq(Depot.pile_height(0), 0.0)
	assert_true(Depot.pile_height(10) > Depot.pile_height(1))
	assert_true(Depot.pile_height(100) - Depot.pile_height(10) < Depot.pile_height(10), "ralentit :")
	assert_true(Depot.pile_height(1000000) <= 1.5)


func test_big_piles_are_never_stretched() -> void:
	# 0.1.6 (Othmane) : au-delà d'une certaine quantité, les tas paraissaient déformés (ils ne
	# grandissaient plus qu'en hauteur). Ils restent maintenant dans leurs proportions.
	for count in [1, 10, 100, 1000, 100000]:
		var s: Vector3 = Depot.pile_scale(Depot.pile_height(count), 0.68)
		assert_almost(s.x, s.z)
		assert_true(s.y <= s.x * Depot.PILE_MAX_STRETCH + 1e-6, "%d : %s" % [count, s])
		assert_true(s.x * Depot.PILE_MODEL_W <= 0.68 + 1e-6, "%d : tient sur sa place" % count)
	var small: Vector3 = Depot.pile_scale(Depot.pile_height(2), 0.68)
	assert_almost(small.x, small.y, 1e-6, "un petit tas grandit d'un bloc")
