extends Node3D
## L'avion de l'agence. Il passe en rase-mottes au-dessus de la palette (il « arrache » le paiement),
## largue la caisse, et repart sans jamais s'arrêter (PRD §9).

signal dropped


func _ready() -> void:
	add_child(Greybox.box(Vector3(0.9, 0.9, 4.0), Color(0.9, 0.9, 0.9)))
	add_child(Greybox.box(Vector3(6.0, 0.12, 1.0), Color(0.8, 0.1, 0.1), Vector3(0, 0.1, 0.2)))
	add_child(Greybox.box(Vector3(2.0, 0.1, 0.6), Color(0.8, 0.1, 0.1), Vector3(0, 0.2, -1.8)))
	add_child(Greybox.box(Vector3(0.1, 0.8, 0.6), Color(0.8, 0.1, 0.1), Vector3(0, 0.6, -1.8)))


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
	t.tween_callback(func(): look_at(over_drop))
	t.tween_property(self, "position", over_drop, drop_at_s * 0.4)
	t.tween_callback(func(): dropped.emit())
	t.tween_callback(func(): look_at(leave))
	t.tween_property(self, "position", leave, 3.0)
	t.tween_callback(queue_free)
