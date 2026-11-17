extends StaticBody3D
## Une caisse livrée. Elle tombe en parachute, puis on l'ouvre avec E. Modèles : Props.crate
## (planches, tampon de l'Agence) et Props.parachute (coupole rouge et crème, suspentes).

var crate: Dictionary
var landed: bool = false
var _chute: Node3D
var _t := 0.0


func setup(p_crate: Dictionary) -> void:
	crate = p_crate
	var model := Props.crate(0.9)
	model.rotation.y = float(hash(str(crate.get("id", ""))) % 628) / 100.0  # chaque caisse un peu de travers
	add_child(model)
	add_child(Greybox.box_collision(Vector3(0.9, 0.9, 0.9), Vector3(0, 0.45, 0)))
	_chute = Props.parachute(1.3, 2.4, 0.42)
	_chute.position.y = 0.9
	_chute.rotation.y = model.rotation.y
	add_child(_chute)


## Le parachute se balance doucement pendant la descente.
func _process(delta: float) -> void:
	if landed:
		return
	_t += delta
	_chute.rotation.z = sin(_t * 2.2) * 0.08
	_chute.rotation.x = cos(_t * 1.7) * 0.06


## Place la caisse au sol tout de suite (chargement d'une sauvegarde).
func land_now() -> void:
	position = crate.position
	_land()
	# Au chargement, le monde physique n'est pas encore prêt : on vérifie l'appui juste après.
	call_deferred(&"_settle")


## Largage : la caisse descend depuis `height` mètres en `duration` secondes, et s'arrête
## SUR ce qu'il y a dessous (un tuyau en hauteur, un objet…), jamais dedans.
func drop_from(height: float, duration: float) -> void:
	position = crate.position + Vector3(0, height, 0)
	var t := create_tween()
	t.tween_property(self, "position", rest_position(), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_callback(_land)


## Où la caisse repose : le point le plus haut sous elle (rayons aux 4 coins et au centre),
## ou le sable si rien n'est dessous.
func rest_position() -> Vector3:
	var base: Vector3 = crate.position
	if not is_inside_tree():
		return base
	var space := get_world_3d().direct_space_state
	var top := base.y
	for off in [Vector3.ZERO, Vector3(0.4, 0, 0.4), Vector3(-0.4, 0, 0.4), Vector3(0.4, 0, -0.4), Vector3(-0.4, 0, -0.4)]:
		var q := PhysicsRayQueryParameters3D.create(base + off + Vector3(0, 30, 0), base + off + Vector3(0, -0.5, 0))
		q.exclude = [get_rid()]
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			top = maxf(top, (hit.position as Vector3).y)
	return Vector3(base.x, top, base.z)


func _settle() -> void:
	if is_inside_tree():
		position = rest_position()


func _land() -> void:
	landed = true
	_chute.visible = false
	set_process(false)


func get_prompt(_player: Node) -> String:
	return tr("PROMPT_CRATE") if landed else ""


func interact(_player: Node) -> void:
	if landed:
		GameState.open_crate(crate)
