extends Node3D
## L'avion de l'agence (0.1.17). Il traverse le ciel en LIGNE DROITE, à altitude et vitesse
## constantes (FlightPath), sans jamais s'arrêter (PRD §9) : en passant au-dessus de la palette,
## il descend son crochet au treuil et arrache le paiement (M-50, gag récurrent), puis remonte la
## corde ; à la verticale du point de livraison, il largue la caisse. Le pilote fait coucou.
## Avant (≤ 0.1.16), trois tweens de durées fixes sur des distances très différentes le faisaient
## arriver à 55 m/s, freiner à 10 m/s en remontant, puis repartir à 65 m/s en grimpant.

signal hooked
signal dropped

var path: FlightPath
var _model: Node3D
var _hook: Node3D
var _rope: Node3D
var _tip: Node3D
var _arm: Node3D
var _propeller: Node3D
var _engine: AudioStreamPlayer3D
var _t := 0.0
var _flying := false
var _hooked := false
var _dropped := false
## Pour l'avion publicitaire de la fin : une ligne droite simple, sans palette.
var _line_from: Vector3
var _line_to: Vector3
var _line_s := 0.0
var _line_duration := 1.0
var _line_free := true


func _ready() -> void:
	# Le biplan de l'Agence (Props.plane) et son pilote en costume (Kenney, Mini Characters),
	# assis dans le cockpit ; une main sort par le côté pour faire coucou.
	_model = Props.plane()
	add_child(_model)
	_propeller = _model.get_node("Propeller")
	var cockpit: Node3D = _model.get_node("Cockpit")
	var pilot := Props.character("mini_male_d", 1.0, "drive")
	pilot.rotation.y = PI  # les personnages regardent +Z ; l'avion vole vers −Z
	pilot.position.y = -0.35
	cockpit.add_child(pilot)
	_arm = Node3D.new()
	_arm.position = Vector3(0.3, 0.25, 0.0)
	_arm.add_child(Props.beam(Vector3.ZERO, Vector3(0.0, 0.4, 0.0), 0.08, Props.SKIN))
	_arm.add_child(Props.ball(0.07, Color.WHITE, Vector3(0, 0.44, 0), 2))
	cockpit.add_child(_arm)
	# Le crochet : une corde d'un mètre (étirée à la bonne longueur par le treuil) et, au bout,
	# un crochet de fer. La corde traîne un peu derrière l'avion (le vent de la vitesse).
	_hook = Node3D.new()
	_hook.position = Vector3(0, -0.4, 0.4)
	add_child(_hook)
	_rope = Node3D.new()
	_rope.add_child(Props.beam(Vector3.ZERO, Vector3(0, -1.0, 0), 0.035, Props.ROPE, true))
	_hook.add_child(_rope)
	_tip = Node3D.new()
	_hook.add_child(_tip)
	var iron := Props.torus(0.1, 0.14, Props.IRON, Vector3(0, -0.1, 0), 10)
	iron.rotation.x = PI / 2
	_tip.add_child(iron)
	_set_rope(1.2)
	# Le bruit du moteur, posé sur l'avion : il arrive, passe au-dessus et s'éloigne (effet Doppler).
	_engine = AudioStreamPlayer3D.new()
	_engine.stream = SoundSynth.stream("engine")
	_engine.volume_db = -4.0
	_engine.unit_size = 18.0
	_engine.max_distance = 260.0
	_engine.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_IDLE_STEP
	add_child(_engine)


func _process(delta: float) -> void:
	_t += delta
	_arm.rotation.z = -0.5 + sin(_t * 10.0) * 0.6
	_propeller.rotation.z += delta * 40.0
	# Un vieux biplan n'est jamais parfaitement immobile : il tangue et roule très peu (le
	# modèle seulement : la ligne de vol, elle, reste droite).
	_model.position.y = sin(_t * 1.3) * 0.12
	_model.rotation.z = sin(_t * 0.9) * 0.04
	_model.rotation.x = sin(_t * 1.1 + 1.0) * 0.015
	if path:
		_follow_path()
	elif _flying:
		_line_s += delta
		var k := clampf(_line_s / maxf(_line_duration, 0.01), 0.0, 1.0)
		position = _line_from.lerp(_line_to, k)
		if k >= 1.0:
			_flying = false
			if _engine.playing:
				_engine.stop()
			if _line_free:
				queue_free()


func _follow_path() -> void:
	position = path.position(_t)
	_set_rope(path.rope_length(_t))
	# La corde traîne derrière, et balance un peu au bout du treuil.
	_hook.rotation.x = -path.rope_trail + sin(_t * 2.3) * 0.03
	_hook.rotation.z = sin(_t * 1.7) * 0.04
	if not _hooked and _t >= path.hook_time():
		_hooked = true
		hooked.emit()
	if not _dropped and _t >= path.drop_time():
		_dropped = true
		dropped.emit()
	if _t >= path.duration():
		queue_free()


func _set_rope(length_m: float) -> void:
	_rope.scale = Vector3(1.0, length_m, 1.0)
	_tip.position = Vector3(0, -length_m, 0)


## Sans crochet (l'avion publicitaire de la fin).
func hide_hook() -> void:
	_hook.visible = false


## Le paiement arraché pend au crochet et part avec l'avion (il remonte avec la corde).
func carry_bundle(colors: Array) -> void:
	for i in colors.size():
		var bag := Props.sack(0.5, colors[i], 7 + i)
		bag.position = Vector3(0, -0.6 - i * 0.45, 0)
		_tip.add_child(bag)


## Le passage de livraison : la ligne droite de FlightPath, du loin au loin.
func fly(p_path: FlightPath) -> void:
	path = p_path
	_t = 0.0
	# Le cap ne change plus de tout le passage : nez (−Z) dans le sens de la ligne.
	transform = Transform3D(Basis.looking_at(path.dir), path.position(0.0))
	if is_inside_tree():
		_engine.play()


## Une simple ligne droite à vitesse constante (l'avion publicitaire de la fin).
## `free_at_end` faux : l'avion reste au bout de la ligne (la caméra de la fin le regarde encore).
func fly_line(from: Vector3, to: Vector3, duration_s: float, free_at_end := true) -> void:
	_line_free = free_at_end
	_line_from = from
	_line_to = to
	_line_duration = duration_s
	_line_s = 0.0
	_flying = true
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	transform = Transform3D(Basis.looking_at(flat if flat.length() > 0.01 else Vector3.FORWARD), from)
	if is_inside_tree():
		_engine.play()
