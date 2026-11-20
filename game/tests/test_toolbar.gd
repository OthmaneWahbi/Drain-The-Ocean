extends TestCase
## La barre de 6 cases en main (M-27 ; la pelle en case 2 depuis 0.1.10) : outils, matériaux portés (un par case), menu pour
## réorganiser, et un tas par matériau à côté des zones de séchage.
## 0.1.11 : la pelle s'achète. Ici on l'achète d'abord (elle prend la case 2), sauf dans les tests
## du tout début de partie.

const GameStateScript := preload("res://core/game_state.gd")

var gs: Node


func before_each() -> void:
	gs = GameStateScript.new()
	var cfg: GameConfig = load("res://data/game_config.tres").duplicate()
	cfg.total_ocean_volume_l = 1.0e6
	gs.setup(cfg)
	gs.has_shovel = true  # comme si on l'avait achetée
	gs._sync_toolbar()


func after_each() -> void:
	gs.free()


func _slots() -> Array:
	return Array(gs.toolbar.slots)


# --- Choisir une case ------------------------------------------------------------------------

func test_starts_with_the_bucket_and_five_empty_slots() -> void:
	gs.new_game()
	assert_eq(gs.current_tool(), "seau")
	assert_eq(_slots(), ["seau", "", "", "", "", ""], "0.1.11 : la pelle n'est plus donnée")
	assert_false(gs.owns_tool("pelle"))


func test_the_bought_shovel_takes_the_second_slot() -> void:
	gs.new_game()
	gs.stock = {"sel": 100}
	gs.open_crates(gs.order(["pelle"]))
	assert_true(gs.has_shovel)
	assert_eq(int(gs.stock.get("sel", 0)), 90, "10 sel")
	assert_eq(_slots(), ["seau", "pelle", "", "", "", ""])


func test_empty_slot_means_bare_hands() -> void:
	gs.select_tool(1)
	assert_eq(gs.current_tool(), "pelle")
	gs.select_tool(2)
	assert_eq(gs.toolbar.selected, 2)
	assert_eq(gs.current_tool(), "", "case vide = les mains")
	gs.select_tool(0)
	assert_eq(gs.current_tool(), "seau")
	gs.select_tool(99)
	gs.select_tool(-1)
	assert_eq(gs.current_tool(), "seau", "indices hors barre ignorés")


func test_wheel_goes_round_all_slots() -> void:
	gs.cycle_tool(-1)
	assert_eq(gs.toolbar.selected, 5)
	gs.cycle_tool(1)
	assert_eq(gs.toolbar.selected, 0)


func test_tool_changed_is_emitted_only_on_real_change() -> void:
	var n := [0]
	gs.tool_changed.connect(func(): n[0] += 1)
	gs.select_tool(0)
	assert_eq(n[0], 0, "déjà le seau")
	gs.select_tool(1)
	assert_eq(n[0], 1)


func test_changing_tool_cancels_a_fill_in_progress() -> void:
	gs.bucket.hold_fill(0.3)
	assert_true(gs.bucket.fill_progress_ratio() > 0.0)
	gs.select_tool(1)
	assert_almost(gs.bucket.fill_progress_ratio(), 0.0)


func test_bought_tools_take_the_first_free_slot() -> void:
	gs.stock = {"sel": 1000, "mineraux": 100}
	gs.unlocked_tier = 2
	gs.open_crates(gs.order(["rateau"]))
	assert_eq(_slots(), ["seau", "pelle", "rateau", "", "", ""])
	gs.open_crates(gs.order(["tuyau"]))
	assert_eq(_slots(), ["seau", "pelle", "rateau", "tuyaux", "", ""])


# --- Les matériaux portés --------------------------------------------------------------------

func test_each_carried_material_takes_one_slot() -> void:
	gs.add_carried({"sel": 3})
	assert_eq(_slots(), ["seau", "pelle", "sel", "", "", ""])
	gs.add_carried({"sel": 2, "mineraux": 1})
	assert_eq(_slots(), ["seau", "pelle", "sel", "mineraux", "", ""], "le sel garde sa case")
	assert_eq(int(gs.carried.sel), 5)


func test_no_free_slot_means_the_material_stays_behind() -> void:
	gs.carry_capacity = 100
	gs.add_carried({"sel": 1, "mineraux": 1, "mineraux_rares": 1, "coquillages": 1})
	assert_eq(gs.toolbar.first_free(), -1, "barre pleine")
	var left: Dictionary = gs.add_carried({"perles": 1, "sel": 2})
	assert_eq(int(left.get("perles", 0)), 1, "pas de case pour les perles")
	assert_false(left.has("sel"), "le sel a déjà sa case")
	assert_eq(int(gs.carried.sel), 3)
	assert_false(gs.can_carry("perles"))
	assert_true(gs.can_carry("sel"))


func test_slot_is_freed_when_the_material_is_dropped_at_the_pallet() -> void:
	gs.add_carried({"sel": 3, "mineraux": 1})
	gs.select_tool(2)
	assert_eq(gs.current_tool(), "sel")
	gs.unload_to_stock()
	assert_eq(_slots(), ["seau", "pelle", "", "", "", ""])
	assert_eq(gs.current_tool(), "", "la case tenue est vide : les mains")


func test_slot_is_freed_when_the_material_is_spent_on_an_order() -> void:
	gs.add_carried({"sel": 10})
	gs.stock = {"sel": 5}
	assert_eq(gs.order(["bache"]).size(), 1)  # 15 sel : ce qu'on porte d'abord, puis la palette
	assert_false(gs.carried.has("sel"))
	assert_eq(_slots(), ["seau", "pelle", "", "", "", ""])


func test_shell_needs_a_slot_to_be_picked_up() -> void:
	gs.carry_capacity = 100
	gs.add_carried({"sel": 1, "mineraux": 1, "mineraux_rares": 1, "perles": 1})
	var shell: Dictionary = gs.add_pickup("shell", Vector3(0.5, 0.5, 18.5))
	assert_false(gs.take_pickup(shell), "pas de case pour les coquillages")
	gs.unload_to_stock()
	assert_true(gs.take_pickup(shell))
	assert_true(gs.toolbar.index_of("coquillages") >= 0)


func test_tool_bought_while_bar_is_full_waits_for_a_free_slot() -> void:
	gs.carry_capacity = 100
	gs.add_carried({"sel": 1, "mineraux": 1, "mineraux_rares": 1, "coquillages": 1})
	gs.has_rake = true
	gs._sync_toolbar()
	assert_eq(gs.toolbar.index_of("rateau"), -1, "pas encore de place")
	gs.unload_to_stock()
	assert_true(gs.toolbar.index_of("rateau") >= 0, "le râteau prend la première case libérée")
	gs.add_carried({"sel": 1})
	assert_true(gs.toolbar.index_of("rateau") >= 0)


# --- Le menu pour réorganiser ----------------------------------------------------------------

func test_swap_slots_keeps_what_you_hold() -> void:
	gs.add_carried({"sel": 2})
	gs.select_tool(0)
	assert_true(gs.swap_slots(0, 3))
	assert_eq(_slots(), ["", "pelle", "sel", "seau", "", ""])
	assert_eq(gs.toolbar.selected, 3, "la sélection suit le seau")
	assert_eq(gs.current_tool(), "seau")
	assert_false(gs.swap_slots(0, 0))
	assert_false(gs.swap_slots(0, 7))


func test_new_material_goes_into_first_free_slot_after_a_swap() -> void:
	gs.swap_slots(0, 4)
	gs.add_carried({"sel": 1})
	assert_eq(_slots(), ["sel", "pelle", "", "", "seau", ""])


func test_toolbar_layout_is_saved() -> void:
	gs.has_rake = true
	gs._sync_toolbar()
	gs.add_carried({"sel": 4})
	gs.swap_slots(0, 4)
	gs.select_tool(gs.toolbar.index_of("rateau"))
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_eq(Array(other.toolbar.slots), _slots())
	assert_eq(other.current_tool(), "rateau")
	other.free()


func test_broken_or_old_saves_rebuild_the_bar() -> void:
	gs.add_carried({"sel": 4, "mineraux": 1})
	var data: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	data["upgrades"].erase("toolbar")  # sauvegarde d'avant cette version
	data["upgrades"]["tool"] = 42
	var other: Node = GameStateScript.new()
	other.setup(gs.config)
	other.load_dict(data)
	assert_true(other.toolbar.index_of("sel") >= 0)
	assert_true(other.toolbar.index_of("mineraux") >= 0)
	assert_eq(other.current_tool(), "seau")
	# Une case qui annonce un râteau qu'on n'a pas : on la vide.
	data["upgrades"]["toolbar"] = ["seau", "pelle", "rateau", "", "", ""]
	other.load_dict(data)
	assert_eq(other.toolbar.index_of("rateau"), -1)
	other.free()


func test_new_game_gives_back_the_bucket() -> void:
	gs.add_carried({"sel": 1})
	gs.select_tool(1)
	gs.new_game()
	assert_eq(gs.current_tool(), "seau")
	assert_eq(_slots(), ["seau", "", "", "", "", ""], "la pelle se rachète")


func test_toolbar_logic_alone() -> void:
	var tb := ToolbarLogic.new(PackedStringArray(["a", "", "b"]))
	var owned := func(t): return t == "a"
	assert_true(tb.cycle(1, owned))
	assert_eq(tb.selected, 1, "case vide utilisable")
	assert_true(tb.cycle(1, owned))
	assert_eq(tb.selected, 0, "« b » pas possédé : sauté")
	assert_eq(tb.put("c"), 1)
	assert_eq(tb.put("c"), 1, "déjà rangé")
	assert_eq(tb.put("d"), -1, "plus de place")
	tb.clear("c")
	assert_eq(tb.first_free(), 1)


# --- Récolter : un tas par matériau ----------------------------------------------------------

func test_hands_harvest_three_rake_harvests_the_whole_pile() -> void:
	var basin: Dictionary = gs.zones[0]
	basin.logic.deposit = {"sel": 9, "mineraux": 2}
	gs.has_rake = true
	gs._sync_toolbar()
	gs.select_tool(gs.toolbar.first_free())  # les mains nues
	gs.harvest(basin, "sel")
	assert_eq(gs.carried_count(), 3)
	gs.select_tool(gs.toolbar.index_of("rateau"))
	gs.harvest(basin, "sel")
	assert_eq(int(gs.carried.sel), 9, "le râteau prend tout le tas de sel")
	assert_false(gs.carried.has("mineraux"), "mais pas l'autre tas")
	assert_eq(int(basin.logic.deposit.mineraux), 2)


func test_harvest_without_a_slot_leaves_the_pile() -> void:
	gs.carry_capacity = 100
	gs.add_carried({"sel": 1, "mineraux": 1, "coquillages": 1, "perles": 1})
	var basin: Dictionary = gs.zones[0]
	basin.logic.deposit = {"mineraux_rares": 2}
	gs.harvest(basin, "mineraux_rares")
	assert_eq(int(basin.logic.deposit.mineraux_rares), 2)
	assert_false(gs.carried.has("mineraux_rares"))


func test_each_material_pile_has_its_own_cell_inside_the_zone() -> void:
	for kind in ["cuvette", "bache", "bassin_bois"]:
		var z := {"kind": kind}
		var cells := {}
		for res in gs.config.pile_slots:
			var off: Vector3 = gs.pile_offset(z, res)
			assert_true((gs.footprint_of(kind) as Rect2).encloses(Rect2(off.x - 0.5, off.z - 0.5, 1, 1)), "%s/%s déborde" % [kind, res])
			assert_almost(fposmod(off.x, 1.0), 0.0, 1e-6)
			assert_almost(fposmod(off.z, 1.0), 0.0, 1e-6)
			assert_false(cells.has(off), "%s : deux tas sur la même case" % kind)
			cells[off] = true
