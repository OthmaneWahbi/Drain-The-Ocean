extends SceneTree
## Le « singe » : des entrées au hasard pendant un moment, avec le vrai jeu, pour faire sortir les
## erreurs que personne n'aurait pensé à tester (0.1.8).
##   xvfb-run godot --path game --rendering-driver opengl3 -s res://tests/scenarios/monkey.gd
##   MONKEY_SEED=7 MONKEY_S=90 : graine et durée (secondes).
## Il ne vérifie rien lui-même : on lit le journal (SCRIPT ERROR, ERROR). Il remplit le stock et
## commande au hasard pour que les objets posables, les caisses et les tuyaux soient touchés aussi.

const ACTIONS := [&"move_forward", &"move_back", &"move_left", &"move_right", &"jump", &"sprint",
	&"interact", &"toggle_view", &"move_object", &"rotate_object", &"use_tool", &"tool_next",
	&"tool_prev", &"tool_1", &"tool_2", &"tool_3", &"tool_4", &"tool_5", &"tool_6", &"pause", &"toolbar_menu",
	&"use_tool_alt"]  # 0.1.11 : le clic droit (creuser à la pelle, reprendre un tuyau)

var _gs: Node
var _main: Node
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	OS.set_environment("DTO_SKIP_MENU", "1")
	_main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(_main)
	_rng.seed = int(OS.get_environment("MONKEY_SEED")) if OS.get_environment("MONKEY_SEED") != "" else 1
	_run.call_deferred()


func _tap(action: StringName, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _run() -> void:
	await create_timer(1.0).timeout
	_gs = root.get_node("GameState")
	var duration := float(OS.get_environment("MONKEY_S")) if OS.get_environment("MONKEY_S") != "" else 60.0
	var catalog_ids: Array = []
	for item in _gs.catalog.items:
		catalog_ids.append(String(item.id))
	var end := Time.get_ticks_msec() + int(duration * 1000.0)
	var held := {}
	var n := 0
	while Time.get_ticks_msec() < end:
		n += 1
		# Les touches : on en presse et relâche au hasard.
		var a: StringName = ACTIONS[_rng.randi() % ACTIONS.size()]
		if a == &"pause" and _rng.randf() < 0.7:
			a = &"move_forward"
		var down: bool = not held.get(a, false)
		_tap(a, down)
		held[a] = down
		# La souris : on tourne la tête, on clique.
		var mm := InputEventMouseMotion.new()
		mm.relative = Vector2(_rng.randf_range(-60, 60), _rng.randf_range(-30, 30))
		Input.parse_input_event(mm)
		if _rng.randf() < 0.15:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			Input.parse_input_event(click)
		# Parfois : on remet la souris (les menus la libèrent), on commande, on ouvre une caisse.
		if _rng.randf() < 0.1:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if _rng.randf() < 0.02:
			_gs.stock = {"sel": 9000, "mineraux": 9000, "mineraux_rares": 900, "coquillages": 900, "perles": 90}
			_gs.unlocked_tier = 2
			_gs.stock_changed.emit()
			_gs.order([catalog_ids[_rng.randi() % catalog_ids.size()]])
		if _rng.randf() < 0.03 and not _gs.crates.is_empty():
			_gs.open_crate(_gs.crates[_rng.randi() % _gs.crates.size()])
		if _rng.randf() < 0.01:
			_gs.advance_time(_rng.randf_range(10.0, 600.0))
		if _rng.randf() < 0.005:
			_gs.save_game()
			_gs.load_game(_gs.current_slot)
		await create_timer(_rng.randf_range(0.03, 0.25)).timeout
	print("singe : %d gestes, fini" % n)
	quit(0)
