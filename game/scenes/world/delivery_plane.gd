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
var _t := 0.0


func _ready() -> void:
	add_child(Greybox.box(Vector3(0.9, 0.9, 4.0), Color(0.9, 0.9, 0.9)))
	add_child(Greybox.box(Vector3(6.0, 0.12, 1.0), Color(0.8, 0.1, 0.1), Vector3(0, 0.1, 0.2)))
	add_child(Greybox.box(Vector3(2.0, 0.1, 0.6), Color(0.8, 0.1, 0.1), Vector3(0, 0.2, -1.8)))
	add_child(Greybox.box(Vector3(0.1, 0.8, 0.6), Color(0.8, 0.1, 0.1), Vector3(0, 0.6, -1.8)))
	# Le pilote dans sa cabine, qui agite le bras.
	add_child(Greybox.box(Vector3(0.5, 0.35, 0.6), Color(0.6, 0.85, 0.95, 0.6), Vector3(0, 0.55, 1.0)))
	add_child(Greybox.box(Vector3(0.22, 0.22, 0.22), Color(0.9, 0.75, 0.6), Vector3(0, 0.6, 1.0)))
	_arm = Node3D.new()
	_arm.position = Vector3(0.18, 0.55, 1.0)
	_arm.add_child(Greybox.box(Vector3(0.06, 0.3, 0.06), Color(0.9, 0.75, 0.6), Vector3(0, 0.15, 0)))
	add_child(_arm)
	# Le crochet qui pend sous l'avion.
	_hook = Node3D.new()
	_hook.add_child(Greybox.box(Vector3(0.04, ROPE_M, 0.04), Color(0.3, 0.25, 0.2), Vector3(0, -ROPE_M / 2.0, 0)))
	_hook.add_child(Greybox.box(Vector3(0.35, 0.08, 0.08), Color(0.4, 0.4, 0.45), Vector3(0, -ROPE_M, 0)))
	_hook.add_child(Greybox.box(Vector3(0.08, 0.25, 0.08), Color(0.4, 0.4, 0.45), Vector3(0.15, -ROPE_M + 0.1, 0)))
	add_child(_hook)


func _process(delta: float) -> void:
	_t += delta
	_arm.rotation.z = sin(_t * 10.0) * 0.6
	# La corde reste verticale quel que soit le cap de l'avion.
	_hook.global_rotation = Vector3.ZERO


## Le paiement arraché pend au crochet et part avec l'avion.
func carry_bundle(colors: Array) -> void:
	for i in colors.size():
		_hook.add_child(Greybox.box(Vector3(0.45, 0.3, 0.45), colors[i], Vector3(0, -ROPE_M - 0.25 - i * 0.3, 0)))


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
