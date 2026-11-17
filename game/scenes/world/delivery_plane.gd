extends Node3D
## L'avion de l'agence. Il passe en rase-mottes au-dessus de la palette et arrache le paiement
## avec un crochet au bout d'une corde (M-50, gag récurrent), largue la caisse, et repart sans
## jamais s'arrêter (PRD §9). Le pilote fait coucou par la vitre.

signal hooked
signal dropped

## Longueur de la corde du crochet (m) : l'avion passe 5 m au-dessus de la palette.
const ROPE_M := 4.4

var _hook: Node3D
var _arm: Node3D
var _propeller: Node3D
var _t := 0.0


func _ready() -> void:
	# Le biplan de l'Agence (Props.plane) et son pilote en costume (Kenney, Mini Characters),
	# assis dans le cockpit ; une main sort par le côté pour faire coucou.
	var model := Props.plane()
	add_child(model)
	_propeller = model.get_node("Propeller")
	var cockpit: Node3D = model.get_node("Cockpit")
	var pilot := Props.character("mini_male_d", 1.0, "drive")
	pilot.rotation.y = PI  # les personnages regardent +Z ; l'avion vole vers −Z
	pilot.position.y = -0.35
	cockpit.add_child(pilot)
	_arm = Node3D.new()
	_arm.position = Vector3(0.3, 0.25, 0.0)
	_arm.add_child(Props.beam(Vector3.ZERO, Vector3(0.0, 0.4, 0.0), 0.08, Props.SKIN))
	_arm.add_child(Props.ball(0.07, Color.WHITE, Vector3(0, 0.44, 0), 2))
	cockpit.add_child(_arm)
	# Le crochet qui pend sous l'avion : une corde, un crochet de fer.
	_hook = Node3D.new()
	_hook.add_child(Props.beam(Vector3.ZERO, Vector3(0, -ROPE_M, 0), 0.035, Props.ROPE, true))
	_hook.add_child(Props.torus(0.1, 0.14, Props.IRON, Vector3(0, -ROPE_M - 0.1, 0), 10))
	_hook.get_child(-1).rotation.x = PI / 2
	add_child(_hook)


func _process(delta: float) -> void:
	_t += delta
	_arm.rotation.z = -0.5 + sin(_t * 10.0) * 0.6
	_propeller.rotation.z += delta * 30.0
	# La corde reste verticale quel que soit le cap de l'avion.
	_hook.global_rotation = Vector3.ZERO


## Sans crochet (l'avion publicitaire de la fin).
func hide_hook() -> void:
	_hook.visible = false


## Le paiement arraché pend au crochet et part avec l'avion.
func carry_bundle(colors: Array) -> void:
	for i in colors.size():
		var bag := Props.sack(0.5, colors[i], 7 + i)
		bag.position = Vector3(0, -ROPE_M - 0.6 - i * 0.45, 0)
		_hook.add_child(bag)


## Trajet : arrivée de loin → palette (bas) → point de largage → départ au loin.
## `drop_at_s` : moment du largage depuis le début du trajet.
func fly(pallet: Vector3, drop: Vector3, drop_at_s: float) -> void:
	var dir := (drop - pallet).normalized()
	if dir.length() < 0.1:
		dir = Vector3.FORWARD
	var start := pallet - dir * 120.0 + Vector3(0, 25, 0)
	var low_pass := pallet + Vector3(0, 5, 0)
	var over_drop := drop + Vector3(0, 18, 0)
	var leave := drop + dir * 200.0 + Vector3(0, 40, 0)
	position = start
	look_at_from_position(start, low_pass)
	var t := create_tween()
	t.tween_property(self, "position", low_pass, drop_at_s * 0.6)
	t.tween_callback(func(): hooked.emit())
	t.tween_callback(func(): look_at(over_drop))
	t.tween_property(self, "position", over_drop, drop_at_s * 0.4)
	t.tween_callback(func(): dropped.emit())
	t.tween_callback(func(): look_at(leave))
	t.tween_property(self, "position", leave, 3.0)
	t.tween_callback(queue_free)
