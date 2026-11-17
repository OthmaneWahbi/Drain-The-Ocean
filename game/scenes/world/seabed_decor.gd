class_name SeabedDecor
extends Node3D
## Le fond marin, seulement autour de l'île (PRD §19.1) : des rochers et des algues posés au
## hasard (graine fixe, donc toujours au même endroit) sur le sable du fond, à y = -3.
## On le découvre en plongeant, puis à l'air libre quand l'océan baisse.

const SEABED_Y := -3.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	# Rochers CC0, algues qui ondulent, coraux en branches, étoiles de mer et coquillages (0.1.4).
	var weed_colors := [Color(0.15, 0.5, 0.25), Color(0.25, 0.58, 0.2), Color(0.1, 0.42, 0.32)]
	var coral_colors := [Color(1.0, 0.5, 0.5), Color(1.0, 0.62, 0.3), Color(0.75, 0.45, 0.9), Color(1.0, 0.8, 0.4)]
	for i in 90:
		var p := AmbientMotion.ring_point(rng, 46.0, 120.0, SEABED_Y)
		p.y = GameState.terrain.height(p.x, p.z)  # posé sur le vrai fond (il descend en pente près de l'île)
		var item: Node3D
		match rng.randi_range(0, 4):
			0:
				var w := rng.randf_range(0.8, 3.0)
				item = Models.rock("rock_large" if rng.randf() < 0.5 else "rock_tall", Vector3(w, w * rng.randf_range(0.4, 0.9), w * rng.randf_range(0.7, 1.1)))
				p.y -= 0.2
			1:
				item = _seaweed(rng, weed_colors[rng.randi() % weed_colors.size()])
			2:
				item = _coral(rng, coral_colors[rng.randi() % coral_colors.size()])
			3:
				item = Props.starfish(rng.randf_range(0.25, 0.45), [Color(1.0, 0.45, 0.3), Color(0.95, 0.75, 0.3), Color(0.85, 0.35, 0.6)][rng.randi() % 3])
			_:
				item = Props.shell(rng.randi(), rng.randf_range(0.25, 0.4))
		item.position = p
		item.rotation.y = rng.randf() * TAU
		add_child(item)


## Une algue : trois ou quatre rubans faits de segments, chacun un peu penché.
static func _seaweed(rng: RandomNumberGenerator, color: Color) -> Node3D:
	var root := Node3D.new()
	for k in rng.randi_range(3, 4):
		var at := Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
		var lean := Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15))
		for seg in rng.randi_range(3, 5):
			var next := at + Vector3(0, 0.35, 0) + lean * (seg + 1) * 0.4
			root.add_child(Props.beam(at, next, 0.07, color))
			at = next
	return root


## Un corail : un tronc et des branches qui se divisent, bouts arrondis.
static func _coral(rng: RandomNumberGenerator, color: Color) -> Node3D:
	var root := Node3D.new()
	var tips := [Vector3.ZERO]
	for level in 3:
		var next := []
		for base: Vector3 in tips:
			for b in (1 if level == 0 else 2):
				var a := rng.randf() * TAU
				var tip := base + Vector3(cos(a) * 0.15 * level, rng.randf_range(0.2, 0.32), sin(a) * 0.15 * level)
				root.add_child(Props.beam(base, tip, 0.09 - level * 0.02, color, true))
				next.append(tip)
		tips = next
	for tip: Vector3 in tips:
		root.add_child(Props.ball(0.05, color.lightened(0.2), tip, 1))
	return root
