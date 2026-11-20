extends SceneTree
## Captures d'écran pour les revues (pas lancé par la CI) :
##   SHOTS_DIR=/un/dossier SHOTS_PLAN=nom xvfb-run godot --path game -s res://tests/scenarios/shots.gd
## Chaque plan pose la caméra du joueur à un endroit et enregistre une image PNG.

var _main: Node
var _player: CharacterBody3D
var _dir := OS.get_environment("SHOTS_DIR")


func _initialize() -> void:
	OS.set_environment("DTO_SKIP_MENU", "1")
	_main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(_main)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Place le joueur en `at`, regarde `look`, 1re (ou 3e) personne, et enregistre `name`.
func shot(name: String, at: Vector3, look: Vector3, third := false) -> void:
	_player.global_position = at
	_player.velocity = Vector3.ZERO
	var flat := Vector3(look.x - at.x, 0, look.z - at.z)
	_player.rotation.y = atan2(-flat.x, -flat.z)
	var head: Node3D = _player.get_node("Head")
	var eye := at + Vector3(0, 1.6, 0)
	head.rotation.x = atan2(look.y - eye.y, flat.length())
	if _player.third_person != third:
		_player.third_person = third
		_player._apply_view()
	await _frames(20)
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [_dir, name])
	print("shot ", name)


func _run() -> void:
	await _frames(10)
	_player = _main.get_node("Player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var gs := root.get_node("GameState")
	gs.day.time_s = gs.day.day_length_s * 0.42  # vers 10 h : soleil haut, ombres nettes
	var plan := OS.get_environment("SHOTS_PLAN")
	var script_path := "res://tests/scenarios/shots_%s.gd" % plan
	if plan != "" and ResourceLoader.exists(script_path):
		var p: Object = (load(script_path) as GDScript).new()
		await p.run(self, gs)
	else:
		await shot("depart", Vector3(0, 0.6, 14), Vector3(0, 0.5, 0))
	quit(0)
