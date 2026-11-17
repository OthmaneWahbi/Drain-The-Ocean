extends SceneTree
## Partie jouée par un robot, avec le vrai jeu (physique, interface, entrées clavier) :
##   godot --path game -s res://tests/scenarios/playtest.gd          (avec affichage)
##   PLAYTEST_SHOTS=/un/dossier … : une image toutes les 0,25 s, pour en faire une vidéo.
## Le robot ne triche que pour gagner du temps (accélérer le séchage, remplir le stock) ;
## chaque geste passe par les touches du joueur. Code de sortie 0 si tout passe, 1 sinon.

var _player: CharacterBody3D
var _gs: Node
var _main: Node
var _fails: Array[String] = []
var _shots := OS.get_environment("PLAYTEST_SHOTS")
var _frame := 0
var _shot_every := 0.25
var _shot_t := 0.0
var _step := "départ"


func _initialize() -> void:
	OS.set_environment("DTO_SKIP_MENU", "1")
	_main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(_main)
	process_frame.connect(_on_frame)
	_run.call_deferred()


func _on_frame() -> void:
	if _shots == "":
		return
	_shot_t += 1.0 / 60.0 if Engine.get_frames_per_second() <= 0 else 1.0 / maxf(Engine.get_frames_per_second(), 1.0)
	if _shot_t >= _shot_every:
		_shot_t = 0.0
		var img := root.get_texture().get_image()
		if img:
			img.save_jpg("%s/f_%05d.jpg" % [_shots, _frame], 0.8)
			_frame += 1


func _check(ok: bool, what: String) -> void:
	print(("  ok    " if ok else "  ÉCHEC ") + "[%s] %s" % [_step, what])
	if not ok:
		_fails.append("[%s] %s" % [_step, what])


func _wait(s: float) -> void:
	var end := Time.get_ticks_msec() + int(s * 1000.0)
	while Time.get_ticks_msec() < end:
		await process_frame


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Une touche tapée (pressée deux images, puis relâchée).
## Un appui bref, envoyé comme un vrai événement (les menus et le dialogue écoutent les
## événements, pas seulement l'état des touches).
func _tap(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(2)
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	await _frames(2)


func _hold(action: StringName, s: float) -> void:
	Input.action_press(action)
	await _wait(s)
	Input.action_release(action)
	await _frames(2)


## Tourne le joueur (et sa tête) vers un point.
func _face(pos: Vector3) -> void:
	var p := _player.global_position
	if Vector2(pos.x - p.x, pos.z - p.z).length() > 0.05:
		_player.look_at(Vector3(pos.x, p.y, pos.z), Vector3.UP)
	var head: Node3D = _player.head
	var from := head.global_position
	var flat := Vector2(pos.x - from.x, pos.z - from.z).length()
	head.rotation.x = clampf(atan2(pos.y - from.y, flat), deg_to_rad(-85), deg_to_rad(85))


## Marche (vraiment, avec les touches) jusqu'à `stop_d` m du point. Faux si on n'y arrive pas.
func _walk_to(pos: Vector3, stop_d: float = 1.5, timeout: float = 20.0) -> bool:
	var end := Time.get_ticks_msec() + int(timeout * 1000.0)
	Input.action_press(&"move_forward")
	var ok := false
	var last := _player.global_position
	var still := 0
	while Time.get_ticks_msec() < end:
		_face(Vector3(pos.x, _player.head.global_position.y, pos.z))
		await process_frame
		var p := _player.global_position
		if Vector2(pos.x - p.x, pos.z - p.z).length() <= stop_d:
			ok = true
			break
		# Bloqué contre quelque chose : on saute.
		still = still + 1 if p.distance_to(last) < 0.01 else 0
		last = p
		if still > 20:
			Input.action_press(&"jump")
			await _frames(2)
			Input.action_release(&"jump")
			still = 0
	Input.action_release(&"move_forward")
	await _frames(3)
	return ok


func _select_tool(tool: String) -> bool:
	for i in _gs.toolbar.slots.size():
		if _gs.toolbar.slots[i] == tool:
			_gs.select_tool(i)
			await _frames(2)
			return _gs.current_tool() == tool
	return false


func _shore_point() -> Vector3:
	# Tout droit vers +Z (la crique) jusqu'à avoir de l'eau aux genoux.
	var a := PI / 2.0
	var r: float = _gs.terrain.coast_at(a) + 2.5
	return Vector3(cos(a) * r, 0.0, sin(a) * r)


func _run() -> void:
	await _wait(1.0)
	_gs = root.get_node("GameState")
	_player = _main.get_node("Player")
	_gs.new_game()
	_gs.pickups.clear()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await _wait(0.5)
	var errors_before := 0

	# 1. Puiser à la mer.
	_step = "puiser"
	var sea := _shore_point()
	_check(await _walk_to(sea, 1.0, 25.0), "on arrive au bord de l'eau")
	_check(_player.is_in_water(), "les pieds dans l'eau")
	_face(sea + Vector3(0, -1, 3))
	await _hold(&"use_tool", 2.5)
	_check(_gs.bucket.water_l > 0.0, "le seau a de l'eau (%.1f L)" % _gs.bucket.water_l)

	# 2. Verser dans la cuvette.
	_step = "verser"
	var basin: Dictionary = _gs.zones[0]
	var bp: Vector3 = basin.position
	_check(await _walk_to(bp, 2.4, 25.0), "on arrive à la cuvette")
	_face(bp + Vector3(0, 0.1, 0))
	await _frames(3)
	_check(_player.target != null, "on vise la cuvette (cible : %s)" % [_player.target])
	var before: float = basin.logic.water_l
	await _tap(&"use_tool")
	_check(basin.logic.water_l > before, "l'eau est dans la cuvette (%.1f L)" % basin.logic.water_l)

	# 3. Faire sécher (accéléré), ramasser le sel.
	_step = "récolter"
	basin.logic.water_l = basin.logic.capacity_l
	_gs.advance_time(600.0, 5.0)
	await _frames(5)
	var sel: int = int(basin.logic.deposit.get("sel", 0))
	_check(sel > 0, "du sel s'est déposé (%d)" % sel)
	var pile_pos: Vector3 = bp + _gs.pile_offset(basin, "sel").rotated(Vector3.UP, deg_to_rad(_gs.item_rotation(basin)))
	_check(await _walk_to(pile_pos, 1.6, 10.0), "on arrive au tas")
	_face(pile_pos + Vector3(0, 0.15, 0))
	await _frames(3)
	await _tap(&"interact")
	await _tap(&"interact")
	_check(int(_gs.carried.get("sel", 0)) > 0, "on porte du sel (%d)" % int(_gs.carried.get("sel", 0)))

	# 4. Le porter à la palette.
	_step = "palette"
	var dp: Vector3 = _gs.depot.position
	_check(await _walk_to(dp, 2.2, 25.0), "on arrive à la palette")
	_face(dp + Vector3(0, 0.3, 0))
	await _frames(3)
	await _tap(&"interact")
	_check(int(_gs.stock.get("sel", 0)) > 0, "le sel est sur la palette (%d)" % int(_gs.stock.get("sel", 0)))

	# 5. Le téléphone (premier appel).
	_step = "téléphone"
	var phone: Node3D = _main.get_node("Phone")
	_check(await _walk_to(phone.global_position, 2.0, 25.0), "on arrive à la cabine")
	_face(phone.global_position + Vector3(0, 1.0, 0))
	await _frames(3)
	await _tap(&"interact")
	await _wait(1.0)
	print("  info  [téléphone] ui_open=%s, sonne=%s" % [_gs.ui_open, _gs.phone.ringing])
	# On passe la conversation (clics) jusqu'à ce que la main revienne.
	for i in 30:
		if not _gs.ui_open:
			break
		# Un clic avance la réplique ; une réponse se choisit avec sa touche (1, 2…).
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		Input.parse_input_event(click)
		await _frames(2)
		click = click.duplicate()
		click.pressed = false
		Input.parse_input_event(click)
		await _wait(0.3)
		await _tap(&"tool_1")
		await _wait(0.3)
	_check(not _gs.ui_open, "la conversation se termine")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# 6. Commander (stock rempli pour l'essai), l'avion, la caisse, la poser.
	_step = "livraison"
	_gs.stock = {"sel": 5000, "mineraux": 5000, "mineraux_rares": 500, "coquillages": 500, "perles": 20}
	_gs.unlocked_tier = 2
	_gs.stock_changed.emit()
	var crates: Array = _gs.order(["bache"])
	_check(crates.size() == 1, "une caisse commandée")
	await _wait(9.0)
	var crate: Dictionary = crates[0] if crates.size() > 0 else {}
	if not crate.is_empty():
		var cp: Vector3 = crate.position
		_check(await _walk_to(cp, 1.8, 25.0), "on arrive à la caisse")
		_face(cp + Vector3(0, 0.4, 0))
		await _frames(3)
		var zones_before: int = _gs.zones.size()
		await _tap(&"interact")
		await _wait(0.5)
		_check(_gs.zones.size() == zones_before + 1, "la bâche est sortie de la caisse")
		_check(_gs.placing, "mode déplacement tout seul")
		# On cherche une place libre en tournant la tête (comme un joueur), puis on clique.
		var pc: Node = _main.get_node("Placement")
		var forward: Vector3 = -_player.global_transform.basis.z
		for k in 12:
			var dir := forward.rotated(Vector3.UP, TAU * k / 12.0)
			_face(_player.global_position + dir * 3.5 + Vector3(0, -1.2, 0))
			await _wait(0.4)
			if pc._valid:
				break
			print("  info  [livraison] place refusée en %s : %s" % [pc._target_pos, _gs.placement_conflicts(pc.item, pc._target_pos, pc._rotation_deg)])
		await _tap(&"use_tool")
		await _wait(0.3)
		_check(not _gs.placing, "la bâche est posée")
		if _gs.placing:
			await _tap(&"move_object")

	# 7. Déplacer la cuvette (G), la tourner (R), la reposer.
	_step = "déplacer"
	bp = basin.position
	_check(await _walk_to(bp + Vector3(0, 0, 3.4), 0.6, 20.0), "on se place devant la cuvette")
	_face(bp + Vector3(0, 0.2, 1.3))  # le bord le plus proche
	await _frames(3)
	print("  info  [déplacer] cible visée : %s, joueur %s, cuvette %s, ui_open=%s placing=%s souris=%d" % [_player.target, _player.global_position, bp, _gs.ui_open, _gs.placing, Input.mouse_mode])
	await _tap(&"move_object")
	await _wait(0.4)
	_check(_gs.placing, "G : mode déplacement")
	await _tap(&"rotate_object")
	await _wait(0.4)
	await _tap(&"use_tool")
	await _wait(0.3)
	_check(not _gs.placing, "reposée")
	print("  info  [déplacer] cuvette en %s, %d°" % [basin.position, _gs.item_rotation(basin)])

	# 8. Les tuyaux : en poser trois devant soi.
	_step = "tuyaux"
	_check(_gs.order(["pompe_bras", "tuyau", "tuyau", "tuyau"]).size() > 0, "pompe et tuyaux commandés")
	await _wait(9.0)
	for c in _gs.crates.duplicate():
		_gs.open_crate(c)
	await _wait(0.3)
	if _gs.placing:
		await _tap(&"move_object")  # on laisse la pompe là où elle est apparue
	await _wait(0.3)
	_check(_gs.pipe_stock > 0, "des tuyaux en main (%d)" % _gs.pipe_stock)
	_check(await _select_tool("tuyaux"), "on prend les tuyaux")
	# Sur un coin de sable dégagé, loin de la cuvette et de la bâche.
	await _walk_to(Vector3(-3, 0.5, -9), 0.6, 25.0)
	_face(Vector3(-3, 0.5, -14))
	await _frames(3)
	var placed := 0
	for i in 3:
		var before_n: int = _gs.pipes.size()
		var ahead: Vector3 = _player.global_position + (-_player.global_transform.basis.z) * (1.5 + 0.5 * i)
		_face(Vector3(ahead.x, 0.5, ahead.z))
		await _frames(4)
		var pb: Node = _main.find_child("PipeBuilder", true, false)
		if pb and i == 0:
			print("  info  [tuyaux] joueur %s, cible %s" % [_player.global_position, _player.target])
		await _tap(&"use_tool")
		await _wait(0.2)
		if _gs.pipes.size() > before_n:
			placed += 1
	_check(placed >= 2, "pièces posées en visant le sol : %d/3" % placed)
	# On marche contre les tuyaux : ils sont solides, on ne passe pas au travers (on peut sauter).
	await _select_tool("seau")

	# 9. Pause et reprise.
	_step = "pause"
	await _tap(&"pause")
	await _wait(0.4)
	_check(paused, "Échap met en pause")
	var pm := _main.get_node("PauseMenu")
	if pm.has_method("close_menu"):
		pm.call("close_menu")
	await _wait(0.3)
	if paused:
		await _tap(&"pause")
		await _wait(0.3)
	_check(not paused, "on reprend")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# 10. Nager loin, s'épuiser, revenir sur la plage.
	_step = "nage"
	var far := _shore_point() * 1.6
	_gs.stamina.value = 0.0
	_gs.stamina.exhausted = true
	await _walk_to(far, 1.0, 12.0)
	await _wait(3.0)
	var home: Vector3 = _gs.config.respawn_position
	var d := Vector2(_player.global_position.x - home.x, _player.global_position.z - home.z).length()
	print("  info  [nage] à %.1f m du point de retour, dans l'eau : %s" % [d, _player.is_in_water()])

	# 11. Sauvegarde (F5) et rechargement.
	_step = "sauvegarde"
	_check(_gs.save_game() == OK, "sauvegarde")
	var zones_n: int = _gs.zones.size()
	var pipes_n: int = _gs.pipes.size()
	_check(_gs.load_game(_gs.current_slot), "rechargement")
	await _wait(0.5)
	_check(_gs.zones.size() == zones_n and _gs.pipes.size() == pipes_n, "même île après rechargement (%d zones, %d tuyaux)" % [_gs.zones.size(), _gs.pipes.size()])
	await _wait(1.0)

	print("%d échec(s)" % _fails.size())
	for f in _fails:
		printerr("ÉCHEC : " + f)
	quit(0 if _fails.is_empty() else 1)
