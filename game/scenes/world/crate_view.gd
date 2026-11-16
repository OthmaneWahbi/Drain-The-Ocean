extends StaticBody3D
## Une caisse livrée. Elle tombe en parachute, puis on l'ouvre avec E.

var crate: Dictionary
var landed: bool = false
var _chute: MeshInstance3D


func setup(p_crate: Dictionary) -> void:
	crate = p_crate
	add_child(Greybox.box(Vector3(0.9, 0.9, 0.9), Greybox.WOOD, Vector3(0, 0.45, 0)))
	add_child(Greybox.box_collision(Vector3(0.9, 0.9, 0.9), Vector3(0, 0.45, 0)))
	_chute = Greybox.cylinder(1.2, 0.5, Color(0.95, 0.95, 0.95), Vector3(0, 3.0, 0), 10)
	add_child(_chute)


## Place la caisse au sol tout de suite (chargement d'une sauvegarde).
func land_now() -> void:
	position = crate.position
	_land()


## Largage : la caisse descend depuis `height` mètres en `duration` secondes.
func drop_from(height: float, duration: float) -> void:
	position = crate.position + Vector3(0, height, 0)
	var t := create_tween()
	t.tween_property(self, "position", crate.position, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_callback(_land)


func _land() -> void:
	landed = true
	_chute.visible = false


func get_prompt(_player: Node) -> String:
	return tr("PROMPT_CRATE") if landed else ""


func interact(_player: Node) -> void:
	if landed:
		GameState.open_crate(crate)
