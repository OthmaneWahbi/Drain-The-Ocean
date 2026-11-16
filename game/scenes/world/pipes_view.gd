extends Node3D
## Dessine les tuyaux (T2) : un cylindre couché de la pompe au bord de chaque zone reliée.
## Redessiné à chaque GameState.network_changed (objet déplacé, tuyaux achetés…).

const PIPE_COLOR := Color(0.3, 0.32, 0.35)
const PIPE_RADIUS := 0.06


func _ready() -> void:
	GameState.network_changed.connect(rebuild)
	GameState.item_moved.connect(func(_it): rebuild())
	rebuild()


func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	for link in GameState.pipe_links():
		var from: Vector3 = link.from
		var to: Vector3 = link.to
		var y := maxf(from.y, to.y) + 0.08
		var a := Vector3(from.x, y, from.z)
		var b := Vector3(to.x, y, to.z)
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var pipe := Greybox.cylinder(PIPE_RADIUS, length, PIPE_COLOR, Vector3.ZERO, 8)
		pipe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(pipe)
		# Le cylindre est debout (axe Y) : on le couche dans la direction a → b.
		pipe.global_position = (a + b) / 2.0
		pipe.look_at(b, Vector3.UP)
		pipe.rotate_object_local(Vector3.RIGHT, PI / 2.0)
