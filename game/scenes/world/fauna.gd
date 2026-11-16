class_name Fauna
extends Node3D
## Les animaux de décor (PRD §19.1) : des mouettes qui tournent au-dessus de l'île, des bancs de
## poissons sous l'eau (ils descendent avec l'océan et disparaissent quand il n'y a plus assez
## d'eau) et un crabe qui se promène de côté au bord de la plage. Purement visuels : aucune
## collision, aucune règle de jeu. Les calculs sont dans AmbientMotion.

const SEABED_Y := -3.0
const FISH_MARGIN := 0.35

var _rng := RandomNumberGenerator.new()
var _t := 0.0


func _ready() -> void:
	_rng.seed = 99
	for i in 5:
		add_child(Seagull.new(_rng.randf_range(14.0, 32.0), _rng.randf_range(11.0, 20.0), _rng.randf_range(0.0, TAU), _rng.randf_range(0.18, 0.32) * (1.0 if i % 2 == 0 else -1.0)))
	for school in 3:
		var radius := _rng.randf_range(30.0, 55.0)
		var start := _rng.randf_range(0.0, TAU)
		var speed := _rng.randf_range(0.05, 0.09) * (1.0 if school % 2 == 0 else -1.0)
		for i in 6:
			add_child(Fish.new(radius + _rng.randf_range(-2.0, 2.0), start + i * 0.06, speed, _rng.randf_range(-2.2, -0.8)))
	add_child(Crab.new(_rng))


static func _part(size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	b.material = mat
	m.mesh = b
	m.position = pos
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


## Une mouette : un corps et deux ailes qui battent, sur un grand cercle.
class Seagull extends Node3D:
	var radius: float
	var height: float
	var angle: float
	var speed: float
	var _left: Node3D
	var _right: Node3D
	var _t := 0.0

	func _init(p_radius: float, p_height: float, p_angle: float, p_speed: float) -> void:
		radius = p_radius
		height = p_height
		angle = p_angle
		speed = p_speed

	func _ready() -> void:
		add_child(Fauna._part(Vector3(0.18, 0.16, 0.6), Color(0.95, 0.95, 0.95), Vector3.ZERO))
		add_child(Fauna._part(Vector3(0.08, 0.08, 0.14), Color(0.95, 0.7, 0.2), Vector3(0, 0, -0.36)))
		_left = Node3D.new()
		_left.add_child(Fauna._part(Vector3(0.7, 0.03, 0.22), Color(0.85, 0.85, 0.88), Vector3(-0.35, 0, 0)))
		add_child(_left)
		_right = Node3D.new()
		_right.add_child(Fauna._part(Vector3(0.7, 0.03, 0.22), Color(0.85, 0.85, 0.88), Vector3(0.35, 0, 0)))
		add_child(_right)

	func _process(delta: float) -> void:
		_t += delta
		angle += speed * delta
		var p := AmbientMotion.orbit(Vector3(0, height + sin(_t * 0.4) * 1.5, 0), radius, angle)
		position = p
		var heading := AmbientMotion.orbit_heading(angle, speed)
		look_at(p + heading, Vector3.UP)
		var f := AmbientMotion.flap(_t, 9.0, 0.6)
		_left.rotation.z = f
		_right.rotation.z = -f


## Un poisson : il nage en banc sur un cercle, toujours entre le fond et la surface.
class Fish extends Node3D:
	var radius: float
	var angle: float
	var speed: float
	var depth: float
	var _t := 0.0

	func _init(p_radius: float, p_angle: float, p_speed: float, p_depth: float) -> void:
		radius = p_radius
		angle = p_angle
		speed = p_speed
		depth = p_depth

	func _ready() -> void:
		add_child(Fauna._part(Vector3(0.12, 0.2, 0.45), Color(0.95, 0.55, 0.2), Vector3.ZERO))
		add_child(Fauna._part(Vector3(0.04, 0.18, 0.15), Color(0.9, 0.45, 0.15), Vector3(0, 0, 0.28)))

	func _process(delta: float) -> void:
		_t += delta
		angle += speed * delta
		var water_y := GameState.water_level_y()
		visible = AmbientMotion.has_room_for_fish(water_y, Fauna.SEABED_Y, Fauna.FISH_MARGIN)
		var y := AmbientMotion.clamp_fish_y(water_y + depth + sin(_t + radius) * 0.2, water_y, Fauna.SEABED_Y, Fauna.FISH_MARGIN)
		var p := AmbientMotion.orbit(Vector3(0, y, 0), radius, angle)
		position = p
		look_at(p + AmbientMotion.orbit_heading(angle, speed), Vector3.UP)


## Le crabe : il choisit un point au bord de la plage et y va de côté, puis se repose un peu.
class Crab extends Node3D:
	const SPEED := 0.8
	var _rng: RandomNumberGenerator
	var _target: Vector3
	var _rest := 0.0
	var _t := 0.0
	var _legs: Array[Node3D] = []

	func _init(rng: RandomNumberGenerator) -> void:
		_rng = rng

	func _ready() -> void:
		add_child(Fauna._part(Vector3(0.36, 0.12, 0.26), Color(0.85, 0.25, 0.15), Vector3(0, 0.1, 0)))
		for side in [-1.0, 1.0]:
			add_child(Fauna._part(Vector3(0.1, 0.08, 0.1), Color(0.9, 0.3, 0.18), Vector3(0.24 * side, 0.12, -0.14)))
			for i in 3:
				var leg := Fauna._part(Vector3(0.14, 0.03, 0.03), Color(0.75, 0.2, 0.12), Vector3(0.22 * side, 0.05, -0.08 + i * 0.08))
				add_child(leg)
				_legs.append(leg)
		position = AmbientMotion.ring_point(_rng, 17.0, 19.2, 0.5)
		_target = position

	func _process(delta: float) -> void:
		_t += delta
		if _rest > 0.0:
			_rest -= delta
			return
		var to := _target - position
		if to.length() < 0.1:
			_target = AmbientMotion.ring_point(_rng, 17.0, 19.2, 0.5)
			# Pas trop loin d'un coup : un crabe, ça trottine.
			_target = position + (_target - position).limit_length(4.0)
			_rest = _rng.randf_range(1.0, 4.0)
			return
		position += to.normalized() * minf(SPEED * delta, to.length())
		# Il marche de côté : son flanc (axe X) regarde où il va.
		rotation.y = atan2(-to.z, to.x)
		for i in _legs.size():
			_legs[i].rotation.z = sin(_t * 18.0 + i) * 0.4
