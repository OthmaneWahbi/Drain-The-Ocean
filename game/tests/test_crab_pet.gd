extends TestCase
## 0.1.19 : Pinçon, le crabe de compagnie (faim, affection, croquettes, accessoires, poses).

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	gs.setup(cfg)


func after_each() -> void:
	gs.free()


func _pet() -> CrabPetLogic:
	return CrabPetLogic.new(load("res://data/game_config.tres"))


# --- Logique -------------------------------------------------------------------------------

func test_new_crab_is_full_and_has_starting_treats() -> void:
	var p := _pet()
	assert_almost(p.hunger, 1.0)
	assert_eq(p.treats, 3)
	assert_eq(p.hearts(), 0)
	assert_false(p.wants_food(), "repu au début")


func test_hunger_drops_over_a_day_and_a_half() -> void:
	var p := _pet()
	p.step(900.0)
	assert_almost(p.hunger, 0.5, 1e-6)
	p.step(10000.0)
	assert_almost(p.hunger, 0.0, 1e-6, "jamais négatif :")


func test_full_crab_refuses_and_keeps_the_treat() -> void:
	var p := _pet()
	assert_eq(p.feed(), CrabPetLogic.Feed.FULL)
	assert_eq(p.treats, 3)


func test_feeding_fills_and_gives_affection() -> void:
	var p := _pet()
	p.step(1800.0)
	assert_eq(p.feed(), CrabPetLogic.Feed.FED)
	assert_almost(p.hunger, 0.4, 1e-6)
	assert_eq(p.treats, 2)
	assert_almost(p.affection, 8.0)


func test_no_treats_no_food() -> void:
	var p := _pet()
	p.treats = 0
	p.step(1800.0)
	assert_eq(p.feed(), CrabPetLogic.Feed.NO_TREATS)


func test_only_first_pat_of_the_day_counts() -> void:
	var p := _pet()
	assert_true(p.pet(1))
	assert_false(p.pet(1), "deuxième caresse du jour :")
	assert_true(p.pet(2))
	assert_almost(p.affection, 10.0)


func test_starving_crab_slowly_loses_affection_but_never_below_zero() -> void:
	var p := _pet()
	p.affection = 50.0
	p.step(1800.0)
	p.step(1000.0)
	assert_almost(p.affection, 45.0, 1e-3)
	p.step(1.0e6)
	assert_almost(p.affection, 0.0)


func test_hearts_and_moods() -> void:
	var p := _pet()
	p.affection = 100.0
	assert_eq(p.hearts(), 5)
	assert_eq(p.mood(false), CrabPetLogic.Mood.HAPPY)
	assert_eq(p.mood(true), CrabPetLogic.Mood.SLEEPY)
	p.affection = 41.0
	assert_eq(p.hearts(), 2)
	assert_eq(p.mood(false), CrabPetLogic.Mood.CONTENT)
	p.hunger = 0.2
	assert_eq(p.mood(false), CrabPetLogic.Mood.HUNGRY)


func test_gift_needs_love_and_a_full_belly() -> void:
	var p := _pet()
	assert_false(p.brings_gift())
	p.affection = 40.0
	assert_true(p.brings_gift())
	p.hunger = 0.1
	assert_false(p.brings_gift(), "affamé, il ne cherche pas de coquillage")


func test_pet_save_round_trip() -> void:
	var p := _pet()
	p.step(1000.0)
	p.affection = 33.0
	p.treats = 7
	p.give_accessory("chapeau")
	p.last_petted_day = 4
	var q := _pet()
	q.load_dict(p.to_dict())
	assert_almost(q.hunger, p.hunger)
	assert_almost(q.affection, 33.0)
	assert_eq(q.treats, 7)
	assert_true(q.has_accessory("chapeau"))
	assert_false(q.has_accessory("lunettes"))
	assert_eq(q.last_petted_day, 4)


# --- Poses ---------------------------------------------------------------------------------

func test_walk_moves_the_two_leg_groups_in_turn() -> void:
	for t in [0.05, 0.1, 0.27, 0.4]:
		var p := CrabPose.pose(CrabPose.Anim.WALK, t)
		for i in CrabPose.LEGS:
			for j in CrabPose.LEGS:
				if CrabPose.gait_group(i) != CrabPose.gait_group(j):
					assert_false(p.leg_lift[i] > 0.01 and p.leg_lift[j] > 0.01, "deux groupes jamais levés ensemble")
	var lifted := 0
	for i in CrabPose.LEGS:
		lifted += 1 if CrabPose.pose(CrabPose.Anim.WALK, 0.05).leg_lift[i] > 0.01 else 0
	assert_eq(lifted, CrabPose.LEGS / 2, "la moitié des pattes en l'air")


func test_neighbour_legs_alternate() -> void:
	assert_true(CrabPose.gait_group(0) != CrabPose.gait_group(1))
	assert_true(CrabPose.gait_group(0) != CrabPose.gait_group(CrabPose.LEGS_PER_SIDE), "même rang, l'autre côté")


func test_eyes_blink_now_and_then_but_mostly_open() -> void:
	var closed := 0
	var seen_blink := false
	for k in 1000:
		var b := CrabPose.blink(k * 0.01)
		seen_blink = seen_blink or b > 0.9
		closed += 1 if b > 0.5 else 0
	assert_true(seen_blink, "il cligne en 10 s")
	assert_true(closed < 100, "yeux ouverts la plupart du temps : %d" % closed)


func test_sleeping_crab_has_closed_eyes_and_folded_stalks() -> void:
	var p := CrabPose.pose(CrabPose.Anim.SLEEP, 2.0)
	assert_almost(p.blink, 1.0)
	assert_true(p.stalk_tilt[0] > 1.0)
	assert_true(p.body_y < 0.0, "il se couche")


func test_happy_crab_hops_with_claws_up() -> void:
	var top := 0.0
	for k in 60:
		var p := CrabPose.pose(CrabPose.Anim.HAPPY, k * 0.02)
		assert_true(p.body_y >= 0.0)
		assert_true(p.claw_raise[0] > 0.9 and p.claw_raise[1] > 0.9)
		top = maxf(top, p.body_y)
	assert_true(top > 0.05, "il saute")


func test_eating_crab_chews_and_brings_claws_to_mouth() -> void:
	var mouth := 0.0
	var claw := 0.0
	for k in 60:
		var p := CrabPose.pose(CrabPose.Anim.EAT, k * 0.03)
		mouth = maxf(mouth, p.mouth)
		claw = maxf(claw, p.claw_raise[0])
	assert_true(mouth > 0.9)
	assert_true(claw > 0.9)


func test_every_pose_is_finite() -> void:
	for a in CrabPose.Anim.values():
		for k in 20:
			var p := CrabPose.pose(a, k * 0.37)
			for key in p:
				var v = p[key]
				if v is float:
					assert_true(is_finite(v), "%s %s" % [a, key])
				elif v is Array:
					for x in v:
						assert_true(is_finite(x), "%s %s" % [a, key])


# --- Dans la partie ------------------------------------------------------------------------

func test_game_has_a_pet_and_it_gets_hungry_with_time() -> void:
	assert_true(gs.pet != null)
	gs.advance_time(900.0)
	assert_almost(gs.pet.hunger, 0.5, 0.01)


func test_interacting_feeds_when_hungry_and_pets_otherwise() -> void:
	var reactions := []
	gs.pet_reacted.connect(func(a): reactions.append(a))
	assert_eq(gs.interact_pet(), CrabPose.Anim.HAPPY, "repu : une caresse")
	gs.pet.hunger = 0.2
	assert_eq(gs.interact_pet(), CrabPose.Anim.EAT)
	assert_eq(gs.pet.treats, 2)
	assert_eq(reactions, [CrabPose.Anim.HAPPY, CrabPose.Anim.EAT])


func test_hungry_crab_without_treats_gets_a_pat() -> void:
	gs.pet.treats = 0
	gs.pet.hunger = 0.1
	assert_eq(gs.interact_pet(), CrabPose.Anim.HAPPY)


func test_pet_items_are_in_the_catalogue_and_work() -> void:
	var treats: CatalogItem = gs.catalog.find(&"croquettes")
	var hat: CatalogItem = gs.catalog.find(&"chapeau_crabe")
	var glasses: CatalogItem = gs.catalog.find(&"lunettes_crabe")
	assert_true(treats != null)
	assert_true(hat != null)
	assert_true(glasses != null)
	assert_false(treats.unique, "on rachète des croquettes")
	assert_true(hat.unique and glasses.unique)
	gs.apply_item(treats, Vector3.ZERO)
	assert_eq(gs.pet.treats, 9)
	gs.apply_item(hat, Vector3.ZERO)
	assert_true(gs.pet.has_accessory("chapeau"))
	assert_false(gs.is_placeable(hat), "un accessoire ne se pose pas au sol")


func test_pet_is_saved_with_the_game() -> void:
	gs.pet.affection = 60.0
	gs.pet.treats = 11
	gs.pet.give_accessory("lunettes")
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.load_dict(data)
	assert_almost(gs.pet.affection, 60.0)
	assert_eq(gs.pet.treats, 11)
	assert_true(gs.pet.has_accessory("lunettes"))


func test_old_save_without_pet_gets_a_fresh_crab() -> void:
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	data.erase("pet")
	gs.load_dict(data)
	assert_eq(gs.pet.treats, 3)
	assert_almost(gs.pet.hunger, 1.0)


func test_a_loving_crab_brings_a_shell_each_morning() -> void:
	gs.pet.affection = 80.0
	var shells_before: int = gs.pickups.filter(func(p): return p.kind == "shell").size()
	# Assez de coquillages sur la plage pour que le remplissage du matin n'en ajoute pas.
	gs.config.shells_per_morning = 0
	gs.advance_time(gs.config.day_length_s)
	var shells_after: int = gs.pickups.filter(func(p): return p.kind == "shell").size()
	assert_eq(shells_after, shells_before + 1, "un cadeau")


func test_an_unloved_crab_brings_nothing() -> void:
	gs.config.shells_per_morning = 0
	var shells_before: int = gs.pickups.filter(func(p): return p.kind == "shell").size()
	gs.advance_time(gs.config.day_length_s)
	assert_eq(gs.pickups.filter(func(p): return p.kind == "shell").size(), shells_before)


# --- La vue ---------------------------------------------------------------------------------

func test_pet_crab_view_is_articulated() -> void:
	var crab := PetCrab.new()
	crab._build()
	assert_eq(crab._legs.size(), 8, "8 pattes")
	assert_eq(crab._knees.size(), 8, "avec un genou chacune")
	assert_eq(crab._shoulders.size(), 2, "2 pinces")
	assert_eq(crab._fingers.size(), 2, "à doigt mobile")
	assert_eq(crab._stalks.size(), 2, "2 yeux sur tiges")
	assert_eq(crab._lids.size(), 2, "avec paupières")
	var box := Models.bounds(Models.vertices(crab))
	assert_true(box.size.x > 0.4 and box.size.x < 0.9, "largeur d'un petit crabe : %s" % box.size)
	assert_true(box.size.y > 0.2 and box.size.y < 0.6, "hauteur : %s" % box.size)
	# Les poses bougent vraiment les articulations.
	crab.apply_pose(CrabPose.pose(CrabPose.Anim.WALK, 0.05))
	var lifted: float = crab._legs[0].rotation.z
	crab.apply_pose(CrabPose.pose(CrabPose.Anim.WALK, 0.05 + 0.5 / CrabPose.STEP_HZ))
	assert_true(absf(crab._legs[0].rotation.z - lifted) > 0.2, "la patte monte et descend")
	crab.apply_pose(CrabPose.pose(CrabPose.Anim.SLEEP, 1.0))
	assert_almost(crab._lids[0].rotation.x, -PI / 2, 1e-4, "paupière fermée")
	crab.free()


func test_hearts_text() -> void:
	assert_eq(PetCrab.hearts_text(2, 5), "♥♥♡♡♡")
	assert_eq(PetCrab.hearts_text(5, 5), "♥♥♥♥♥")
