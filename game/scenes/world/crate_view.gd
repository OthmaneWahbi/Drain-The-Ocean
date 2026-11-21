extends StaticBody3D
## Une caisse livrée. Elle tombe en parachute, puis on l'ouvre avec E. Modèles : Props.crate
## (caisse de largage en planches, cadre, sangles, tampon de l'Agence) et Props.parachute.
##
## La chute (0.1.17, FlightPath) : la caisse quitte l'avion, tombe en chute libre une fraction
## de seconde (voile encore pliée), la voile s'ouvre d'un coup avec un petit rebond, puis la
## caisse descend à VITESSE CONSTANTE en se balançant sous la voile (un pendule accroché à la
## confluence des suspentes). Au sol, elle s'écrase un peu, et la voile s'affaisse sur le côté
## puis se replie, au lieu de disparaître d'un coup.

const CRATE_SIZE := 0.9
const CONFLUENCE := 1.0
## Durées de l'atterrissage : tassement de la caisse, affaissement puis repli de la voile.
const SQUASH_S := 0.28
const COLLAPSE_S := 0.7
const FOLD_S := 0.5

var crate: Dictionary
var landed: bool = false
## Le pendule : pivot à la confluence, la caisse et le parachute dedans.
var _swing: Node3D
var _body: Node3D
var _chute: Node3D
var _canopy: Node3D
var _slings: Node3D
var _falling := false
var _fall_t := 0.0
var _start_y := 0.0
var _rest := Vector3.ZERO


func setup(p_crate: Dictionary) -> void:
	crate = p_crate
	_swing = Node3D.new()
	_swing.position.y = CRATE_SIZE + CONFLUENCE
	add_child(_swing)
	_body = Node3D.new()
	_body.position.y = -(CRATE_SIZE + CONFLUENCE)
	_swing.add_child(_body)
	var model := Props.crate(CRATE_SIZE)
	_body.add_child(model)
	add_child(Greybox.box_collision(Vector3(CRATE_SIZE, CRATE_SIZE, CRATE_SIZE), Vector3(0, CRATE_SIZE / 2.0, 0)))
	_chute = Props.parachute(1.3, CRATE_SIZE, CONFLUENCE)
	_chute.position.y = CRATE_SIZE
	_body.add_child(_chute)
	_canopy = _chute.get_node("Canopy")
	_slings = _chute.get_node("Slings")
	# Chaque caisse arrive un peu de travers (la caisse et son parachute ensemble).
	rotation.y = float(hash(str(crate.get("id", ""))) % 628) / 100.0
	set_process(false)


## Place la caisse au sol tout de suite (chargement d'une sauvegarde).
func land_now() -> void:
	position = crate.position
	landed = true
	_chute.visible = false
	set_process(false)
	# Au chargement, le monde physique n'est pas encore prêt : on vérifie l'appui juste après.
	call_deferred(&"_settle")


## Largage : la caisse part de la hauteur `start_y` (sous l'avion), tombe et se pose SUR ce qu'il
## y a dessous (un tuyau en hauteur, un objet…), jamais dedans.
func drop_from_y(start_y: float) -> void:
	_rest = rest_position()
	_start_y = maxf(start_y, _rest.y + 2.0)
	position = Vector3(_rest.x, _start_y, _rest.z)
	_fall_t = 0.0
	_falling = true
	_apply_canopy(0.0)
	set_process(true)


func _process(delta: float) -> void:
	if not _falling:
		return
	_fall_t += delta
	var cfg := GameState.config
	var fallen := FlightPath.fall_distance(_fall_t, cfg.chute_freefall_s, cfg.chute_descent_m_s)
	var y := _start_y - fallen
	_apply_canopy(FlightPath.canopy_open(_fall_t, cfg.chute_freefall_s))
	# Le pendule : il s'amortit, et revient droit dans les derniers 60 cm (la caisse se pose à plat).
	var flat := clampf((y - _rest.y) / 0.6, 0.0, 1.0)
	_swing.rotation.x = FlightPath.swing(_fall_t, cfg.chute_freefall_s) * flat
	_swing.rotation.z = FlightPath.swing(_fall_t + 0.7, cfg.chute_freefall_s, 0.09, 2.9) * flat
	if y <= _rest.y:
		position = _rest
		_falling = false
		set_process(false)
		_land()
		return
	position = Vector3(_rest.x, y, _rest.z)


## La voile : pliée (un petit paquet au-dessus de la caisse) → gonflée. Les élingues suivent.
func _apply_canopy(k: float) -> void:
	var packed := 0.12
	var w := lerpf(packed, 1.0, k)
	var hgt := lerpf(packed, 1.0, clampf(k, 0.0, 1.2))
	_canopy.scale = Vector3(w, hgt, w)
	_canopy.position.y = lerpf(0.15, CONFLUENCE, clampf(k, 0.0, 1.0))
	_slings.visible = k > 0.05


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


## L'atterrissage : la caisse se tasse et rebondit à peine ; la voile, qui ne porte plus rien,
## bascule sur le côté en s'aplatissant, puis se replie et disparaît.
func _land() -> void:
	landed = true
	_swing.rotation = Vector3.ZERO
	var t := create_tween()
	t.tween_property(_body, "scale", Vector3(1.06, 0.9, 1.06), SQUASH_S * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "scale", Vector3.ONE, SQUASH_S * 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var c := create_tween()
	c.tween_property(_canopy, "rotation:z", 1.35, COLLAPSE_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	c.parallel().tween_property(_canopy, "scale:y", 0.25, COLLAPSE_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	c.parallel().tween_property(_canopy, "position:y", 0.3, COLLAPSE_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	c.tween_callback(func(): _slings.visible = false)
	c.tween_property(_canopy, "scale", Vector3(0.01, 0.01, 0.01), FOLD_S).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	c.tween_callback(func(): _chute.visible = false)


func get_prompt(_player: Node) -> String:
	return tr("PROMPT_CRATE") if landed else ""


func interact(_player: Node) -> void:
	if landed:
		GameState.open_crate(crate)
