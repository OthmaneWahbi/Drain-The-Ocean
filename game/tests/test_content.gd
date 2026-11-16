extends TestCase
## Contenu de la démo : toboggan à sacs (N-09, stock automatique M-28) et objet payé en perle (N-07).

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	gs.setup(cfg)
	gs.pickups.clear()


func after_each() -> void:
	gs.free()


func _slide_next_to_basin() -> Dictionary:
	var basin: Dictionary = gs.zones[0]
	return gs.add_slide("toboggan", basin.position + Vector3(gs.footprint(basin) + 1.5, 0, 0))


func test_slide_is_tier_2_placeable_and_movable() -> void:
	var item: CatalogItem = gs.catalog.find(&"toboggan")
	assert_eq(item.tier, 2)
	assert_true(gs.is_placeable(item))
	gs.unlocked_tier = 2
	gs.stock = {"sel": 1000, "mineraux": 100}
	var list: Array = gs.order(["toboggan"])
	assert_eq(list.size(), 1)
	gs.open_crates(list)
	assert_eq(gs.slides.size(), 1)
	assert_true(gs.movable_items().has(gs.slides[0]))


func test_throwing_carried_bags_in_the_slide_fills_the_pallet() -> void:
	var sl := _slide_next_to_basin()
	gs.add_carried({"sel": 6, "coquillages": 1})
	var sent := []
	gs.slide_sent.connect(func(_s, items): sent.append(items))
	assert_eq(gs.slide_unload(sl), 7)
	assert_eq(int(gs.stock.sel), 6)
	assert_eq(gs.carried_count(), 0)
	assert_eq(sent.size(), 1)
	assert_eq(gs.slide_unload(sl), 0, "rien à jeter")
	assert_eq(sent.size(), 1, "pas d'animation pour rien")


func test_slide_sends_nearby_salt_by_itself() -> void:
	var sl := _slide_next_to_basin()
	var basin: Dictionary = gs.zones[0]
	assert_eq(gs.zones_for_slide(sl), [basin])
	basin.logic.deposit = {"sel": 5, "mineraux": 1}
	gs.simulate(gs.config.slide_period_s * 0.5)
	assert_eq(int(gs.stock.get("sel", 0)), 0, "pas encore")
	gs.simulate(gs.config.slide_period_s * 0.6)
	assert_true(int(gs.stock.get("sel", 0)) >= 5, "le sel est arrivé sur la palette")
	assert_true(int(gs.stock.get("mineraux", 0)) >= 1)
	assert_false(basin.logic.deposit.has("mineraux"))


func test_far_zones_are_not_served() -> void:
	var basin: Dictionary = gs.zones[0]
	var sl: Dictionary = gs.add_slide("toboggan", basin.position + Vector3(gs.footprint(basin) + gs.config.slide_reach_m + 1.0, 0, 0))
	assert_eq(gs.zones_for_slide(sl).size(), 0)
	basin.logic.deposit = {"sel": 5}
	gs.simulate(gs.config.slide_period_s * 1.1)
	assert_eq(int(basin.logic.deposit.sel), 5)


func test_moving_the_slide_or_the_zone_updates_who_is_served() -> void:
	var sl := _slide_next_to_basin()
	var basin: Dictionary = gs.zones[0]
	assert_eq(gs.zones_for_slide(sl).size(), 1)
	assert_true(gs.move_item(sl, Vector3(-0.5, 0.5, 15.5)))
	assert_eq(gs.zones_for_slide(sl).size(), 0)
	assert_true(gs.move_item(basin, Vector3(-0.5, 0.5, 11.5)))
	assert_eq(gs.zones_for_slide(sl).size(), 1)


func test_slides_are_saved() -> void:
	var sl := _slide_next_to_basin()
	gs.move_item(sl, sl.position, 90.0)
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(other.slides.size(), 1)
	assert_almost(other.slides[0].position.x, sl.position.x)
	assert_almost(other.item_rotation(other.slides[0]), 90.0)
	other.free()


func test_flamingo_costs_a_pearl_and_is_unique() -> void:
	var item: CatalogItem = gs.catalog.find(&"flamant")
	assert_eq(item.price, {"perles": 1})
	assert_true(item.unique)
	gs.stock = {"sel": 1000}
	assert_eq(gs.order(["flamant"]).size(), 0, "le sel ne suffit pas : il faut une perle")
	gs.stock = {"perles": 2}
	var list: Array = gs.order(["flamant"])
	assert_eq(list.size(), 1)
	assert_eq(int(gs.stock.perles), 1)
	gs.open_crates(list)
	assert_eq(gs.decor[gs.decor.size() - 1].kind, "flamant")
	assert_eq(gs.order(["flamant"]).size(), 0, "un seul par partie")


func test_every_catalog_item_has_texts_and_a_sane_price() -> void:
	for item in gs.catalog.items:
		assert_true(item.name_key != "" and item.desc_key != "", String(item.id))
		assert_true(tr(item.name_key) != "" , String(item.id))
		for k in item.price:
			assert_true(Economy.RESOURCES.has(String(k)), "%s : ressource inconnue %s" % [item.id, k])
			assert_true(int(item.price[k]) > 0)
		if not item.hidden:
			assert_false(item.price.is_empty(), "%s : gratuit ?" % item.id)
