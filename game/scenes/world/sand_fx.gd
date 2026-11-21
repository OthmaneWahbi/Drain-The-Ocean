class_name SandFx
extends Node3D
## L'animation d'un coup de pelle (0.1.11 ; 0.1.12 : et la poussière du sable qui s'éboule),
## à chaque GameState.sand_moved :
##  - la pelle du joueur plonge (creuser) ou bascule (remblayer) : Player.swing_shovel ;
##  - une motte de sable vole en arc entre la case et la lame (du sol vers la pelle quand on
##    creuse, de la pelle vers le sol quand on remblaie), plus grosse s'il y a plusieurs pelletées ;
##  - un petit nuage de grains de sable gicle de la case (quand la pelle entre dans le sable, ou
##    quand la motte retombe).
## Le sable lui-même glisse vers son nouveau niveau dans TerrainView. Rien ici ne change les règles.

const DIG_FLIGHT_S := 0.24
## Le même temps que l'attente de TerrainView avant que le sable remblayé monte.
const FILL_FLIGHT_S := 0.16
const ARC_M := 0.45

## Les mottes en vol : {node, from, to, t, duration, burst_at_end, cell_pos}.
var _flights: Array[Dictionary] = []


func _ready() -> void:
	GameState.sand_moved.connect(_on_sand_moved)
	GameState.game_reset.connect(_clear)


func _on_sand_moved(center: Vector3, before: Dictionary, after: Dictionary, scoops: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	var tip := center + Vector3(0, 1.0, 0)
	if player and player.has_method(&"swing_shovel"):
		player.swing_shovel(scoops >= 0.0)
		tip = player.shovel_tip()
	var c := Vector2(center.x, center.z)
	var top := _height_near(c, after)
	if GameState.sand_gesture == GameState.Gesture.LEVEL:
		# 0.1.15 : aplanir racle le sol : un peu de poussière, et une motte seulement si la pelle
		# prend ou rend vraiment du sable (sinon une motte volait à chaque case survolée).
		_burst(Vector3(center.x, top, center.z), 0.35)
		if absf(scoops) >= 0.5:
			if scoops > 0.0:
				_fly(Vector3(center.x, top + 0.05, center.z), tip, DIG_FLIGHT_S, scoops, false)
			else:
				_fly(tip, Vector3(center.x, top + 0.05, center.z), FILL_FLIGHT_S, -scoops, true)
		return
	if scoops > 0.0:
		_burst(Vector3(center.x, center.y, center.z), 1.0)
		_fly(Vector3(center.x, top + 0.05, center.z), tip, DIG_FLIGHT_S, scoops, false)
	elif scoops < 0.0:
		_fly(tip, Vector3(center.x, top + 0.05, center.z), FILL_FLIGHT_S, -scoops, true)
	else:
		_burst(Vector3(center.x, top, center.z), 0.6)  # on lisse sans prendre ni poser
	# Le sable qui s'éboule plus loin fait un peu de poussière là où il glisse le plus.
	var slide := slide_spot(c, before, after, GameState.config.sand_slide_fx_min_m)
	if not slide.is_empty():
		var delay: float = TerrainView.anim_delays(center, {}, {slide.v: 0.0}, 0.0)[slide.v]
		get_tree().create_timer(float(delay) + 0.1).timeout.connect(_burst.bind(slide.pos, 0.5))


## La hauteur d'arrivée du sommet le plus proche du point visé.
static func _height_near(c: Vector2, after: Dictionary) -> float:
	var best := INF
	var y := 0.0
	for v: Vector2i in after:
		var d := TerrainLogic.vertex_xz(v).distance_squared_to(c)
		if d < best:
			best = d
			y = float(after[v])
	return y


## Là où le sable s'éboule le plus, loin de la pelletée : {v, pos}, ou {} s'il n'y a pas
## d'éboulement d'au moins `min_m`.
static func slide_spot(c: Vector2, before: Dictionary, after: Dictionary, min_m: float) -> Dictionary:
	var best := min_m
	var out := {}
	for v: Vector2i in after:
		var p := TerrainLogic.vertex_xz(v)
		if p.distance_to(c) < 1.3:
			continue
		var d := absf(float(after[v]) - float(before.get(v, after[v])))
		if d >= best:
			best = d
			out = {"v": v, "pos": Vector3(p.x, float(after[v]), p.y)}
	return out


func _fly(from: Vector3, to: Vector3, duration: float, scoops: float, burst_at_end: bool) -> void:
	var clump := Props.sand_clump(0.11 * pow(maxf(scoops, 0.2), 0.33), _flights.size() + 5)
	clump.name = "SandClump"
	clump.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(clump)
	clump.global_position = from
	_flights.append({"node": clump, "from": from, "to": to, "t": 0.0, "duration": duration, "burst_at_end": burst_at_end})


func _process(delta: float) -> void:
	for f in _flights.duplicate():
		f.t += delta / f.duration
		var t := minf(f.t, 1.0)
		var node: Node3D = f.node
		node.global_position = arc_point(f.from, f.to, t, ARC_M)
		node.rotation.y += delta * 9.0
		if f.burst_at_end:
			# La motte s'écrase un peu en arrivant.
			var squash := smoothstep(0.75, 1.0, t)
			node.scale = Vector3(1.0 + squash * 0.5, 1.0 - squash * 0.5, 1.0 + squash * 0.5)
		if f.t >= 1.0:
			_flights.erase(f)
			node.queue_free()
			if f.burst_at_end:
				_burst(f.to, 1.0)


## Un point de l'arc entre `from` et `to` (une parabole de `height` m au-dessus de la ligne droite).
static func arc_point(from: Vector3, to: Vector3, t: float, height: float) -> Vector3:
	return from.lerp(to, t) + Vector3(0, 4.0 * height * t * (1.0 - t), 0)


## Un nuage de grains de sable qui retombe (une seule fois, puis le nœud disparaît).
func _burst(pos: Vector3, strength: float) -> void:
	var p := CPUParticles3D.new()
	p.name = "SandBurst"
	p.one_shot = true
	p.emitting = false
	p.amount = int(16 * strength)
	p.lifetime = 0.55
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 55.0
	p.initial_velocity_min = 1.0 * strength
	p.initial_velocity_max = 2.2 * strength
	p.gravity = Vector3(0, -9.0, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.35, 0.02, 0.35)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	var grain := BoxMesh.new()
	grain.size = Vector3(0.05, 0.05, 0.05)
	grain.material = Props.mat(Props.SAND.lightened(0.08))
	p.mesh = grain
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	p.global_position = pos + Vector3(0, 0.05, 0)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _clear() -> void:
	for f in _flights:
		(f.node as Node3D).queue_free()
	_flights.clear()


## Vrai pendant qu'une motte vole (pour les tests).
func is_busy() -> bool:
	return not _flights.is_empty()
