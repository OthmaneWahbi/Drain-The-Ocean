extends TestCase
## Le téléphone (M-48, M-54) : premier appel tutoriel, offres spéciales, crochet de l'avion.

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	gs.setup(cfg)
	gs.rng.seed = 5


func after_each() -> void:
	gs.free()


func _answer_tutorial() -> void:
	assert_eq(gs.answer_phone(), PhoneLogic.Ring.TUTORIAL)


## Fait passer la nuit jusqu'au matin suivant.
func _next_morning() -> void:
	var before: int = gs.day.day_index
	var guard := 0
	while gs.day.day_index == before and guard < 10000:
		gs.simulate(5.0)
		guard += 1


# --- Logique pure ----------------------------------------------------------------------------

func test_logic_starts_ringing_for_the_tutorial() -> void:
	var p := PhoneLogic.new()
	assert_true(p.is_ringing())
	assert_eq(p.answer(0), PhoneLogic.Ring.TUTORIAL)
	assert_true(p.tutorial_done)
	assert_false(p.is_ringing())
	assert_eq(p.answer(0), PhoneLogic.Ring.NONE, "plus rien à décrocher")


func test_no_offer_before_the_tutorial() -> void:
	var p := PhoneLogic.new()
	var rng := RandomNumberGenerator.new()
	assert_false(p.on_new_morning(rng, 1.0, ["bache"]))
	assert_eq(p.ringing, PhoneLogic.Ring.TUTORIAL)


func test_offer_only_counts_once_answered_and_only_that_day() -> void:
	var p := PhoneLogic.new()
	p.answer(0)
	var rng := RandomNumberGenerator.new()
	assert_true(p.on_new_morning(rng, 1.0, ["bache"]))
	assert_false(p.has_offer("bache", 1), "pas encore décroché")
	assert_eq(p.answer(1), PhoneLogic.Ring.OFFER)
	assert_true(p.has_offer("bache", 1))
	assert_false(p.has_offer("bache", 2), "le lendemain, c'est fini")
	assert_false(p.has_offer("grand_seau", 1))


func test_missed_call_is_a_missed_offer() -> void:
	var p := PhoneLogic.new()
	p.answer(0)
	var rng := RandomNumberGenerator.new()
	p.on_new_morning(rng, 1.0, ["bache"])
	p.on_new_morning(rng, 0.0, ["bache"])
	assert_false(p.is_ringing(), "la sonnerie s'arrête avec la nuit")
	assert_eq(p.answer(2), PhoneLogic.Ring.NONE)
	assert_false(p.has_offer("bache", 2))


func test_no_candidates_no_ring() -> void:
	var p := PhoneLogic.new()
	p.answer(0)
	assert_false(p.on_new_morning(RandomNumberGenerator.new(), 1.0, []))


func test_discount_rounds_up_and_never_free() -> void:
	assert_eq(PhoneLogic.discounted({"sel": 15, "mineraux": 1}, 0.5), {"sel": 8, "mineraux": 1})
	assert_eq(PhoneLogic.discounted({"sel": 0}, 0.5), {"sel": 0})


func test_phone_save_and_old_saves() -> void:
	var p := PhoneLogic.new()
	p.answer(0)
	p.on_new_morning(RandomNumberGenerator.new(), 1.0, ["bache"])
	var q := PhoneLogic.new()
	q.load_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	assert_eq(q.ringing, PhoneLogic.Ring.OFFER)
	assert_eq(q.pending_offer(), "bache")
	var old := PhoneLogic.new()
	old.load_dict({})
	assert_true(old.tutorial_done, "vieille sauvegarde : pas de tutoriel")
	assert_false(old.is_ringing())


# --- Dans la partie --------------------------------------------------------------------------

func test_new_game_rings_and_tutorial_sends_the_catalogue_to_the_booth() -> void:
	assert_true(gs.phone.is_ringing())
	var added := []
	gs.crate_added.connect(func(c, _a): added.append(c))
	_answer_tutorial()
	assert_eq(added.size(), 1)
	assert_eq(added[0].items, ["catalogue_papier"])
	assert_true(added[0].get("free", false), "caisse offerte : rien à arracher sur la palette")
	assert_almost(float(added[0].delay_s), gs.config.hold_music_s, 1e-6, "après la musique d'attente")
	assert_false(gs.catalogue_delivered, "pas de catalogue avant d'ouvrir la caisse")
	gs.open_crate(added[0])
	assert_true(gs.catalogue_delivered, "le catalogue part dans la cabine")
	assert_eq(gs.decor.size(), 0, "rien n'est posé au sol (0.1.2)")


func test_catalogue_delivery_is_saved_and_old_saves_migrate() -> void:
	_answer_tutorial()
	gs.open_crate(gs.crates[0])
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.new_game()
	assert_false(gs.catalogue_delivered)
	gs.load_dict(data)
	assert_true(gs.catalogue_delivered)
	# Vieille sauvegarde : le catalogue papier était un décor posé au sol.
	data.erase("catalogue_delivered")
	data["decor"] = [{"kind": "catalogue_papier", "position": [1, 0.5, 1]}, {"kind": "flamant", "position": [2, 0.5, 2]}]
	gs.load_dict(data)
	assert_true(gs.catalogue_delivered)
	assert_eq(gs.decor.size(), 1, "le catalogue a quitté le sol, le flamant reste")
	assert_eq(gs.decor[0].kind, "flamant")


func test_paper_catalogue_is_not_for_sale() -> void:
	var item: CatalogItem = gs.catalog.find(&"catalogue_papier")
	assert_true(item.hidden)
	assert_false(gs.can_buy(item))
	gs.stock = {"sel": 100}
	assert_eq(gs.order(["catalogue_papier"]).size(), 0)
	assert_false(gs.offer_candidates().has("catalogue_papier"))


func test_morning_offer_halves_the_price_for_the_day() -> void:
	gs.config.offer_chance_per_day = 1.0
	_answer_tutorial()
	_next_morning()
	assert_eq(gs.phone.ringing, PhoneLogic.Ring.OFFER)
	var id: String = gs.phone.pending_offer()
	var item: CatalogItem = gs.catalog.find(StringName(id))
	assert_eq(gs.price_of(item), item.price, "pas décroché : plein tarif")
	assert_eq(gs.answer_phone(), PhoneLogic.Ring.OFFER)
	assert_eq(gs.price_of(item), PhoneLogic.discounted(item.price, 0.5))
	assert_eq(gs.cart_price([id, id]), Economy.sum([PhoneLogic.discounted(item.price, 0.5), PhoneLogic.discounted(item.price, 0.5)]))
	_next_morning()
	if gs.phone.offer_item == id and gs.phone.pending_offer() == "":
		pass
	assert_false(gs.phone.has_offer(id, gs.day.day_index), "l'offre ne dure qu'un jour")


func test_paying_with_the_offer_price() -> void:
	gs.config.offer_chance_per_day = 1.0
	_answer_tutorial()
	_next_morning()
	gs.answer_phone()
	var id: String = gs.phone.offer_item
	var item: CatalogItem = gs.catalog.find(StringName(id))
	gs.stock = PhoneLogic.discounted(item.price, 0.5)
	gs.unlocked_tier = 2
	assert_eq(gs.order([id]).size() > 0, true, "le prix réduit suffit")
	assert_eq(Economy.count(gs.stock), 0)


func test_no_offer_when_chance_is_zero() -> void:
	gs.config.offer_chance_per_day = 0.0
	_answer_tutorial()
	_next_morning()
	assert_false(gs.phone.is_ringing())


func test_order_tells_the_plane_what_to_snatch() -> void:
	gs.stock = {"sel": 1000, "mineraux": 100, "coquillages": 100}
	var list: Array = gs.order(["bache", "tongs"])
	assert_eq(list.size(), 2)
	assert_eq(list[0].get("paid", {}), gs.cart_price(["bache", "tongs"]))
	assert_false(list[1].has("paid"), "un seul crochet par commande")


func test_phone_state_is_saved() -> void:
	gs.config.offer_chance_per_day = 1.0
	_answer_tutorial()
	_next_morning()
	gs.answer_phone()
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_true(other.phone.tutorial_done)
	assert_true(other.phone.has_offer(gs.phone.offer_item, other.day.day_index))
	other.free()
