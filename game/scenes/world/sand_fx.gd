class_name SandFx
extends Node3D
## L'animation d'un coup de pelle (0.1.11), à chaque GameState.sand_moved :
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


func _on_sand_moved(cell: Vector2i, before: Dictionary, to_y: float, scoops: int) -> void:
	var c := GameState.config.grid_cell_m
	var from_y := 0.0
	for v in before:
		from_y += float(before[v])
	from_y /= maxf(before.size(), 1)
	var ground := Vector3((cell.x + 0.5) * c, maxf(from_y, to_y), (cell.y + 0.5) * c)
	var player := get_tree().get_first_node_in_group(&"player")
	var tip := ground + Vector3(0, 1.0, 0)
	if player and player.has_method(&"swing_shovel"):
		player.swing_shovel(scoops >= 0)
		tip = player.shovel_tip()
	if scoops > 0:
		_burst(Vector3(ground.x, from_y, ground.z), 1.0)
		_fly(Vector3(ground.x, from_y + 0.05, ground.z), tip, DIG_FLIGHT_S, scoops, false)
	elif scoops < 0:
		_fly(tip, Vector3(ground.x, to_y + 0.05, ground.z), FILL_FLIGHT_S, -scoops, true)
	else:
		_burst(Vector3(ground.x, to_y, ground.z), 0.6)  # on lisse sans prendre ni poser


func _fly(from: Vector3, to: Vector3, duration: float, scoops: int, burst_at_end: bool) -> void:
	var clump := Props.sand_clump(0.11 * pow(float(scoops), 0.33), _flights.size() + 5)
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
