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
		add_child(Seagull.new(_rng.randf_range(18.0, 44.0), _rng.randf_range(11.0, 22.0), _rng.randf_range(0.0, TAU), _rng.randf_range(0.18, 0.32) * (1.0 if i % 2 == 0 else -1.0)))
	for school in 3:
		var radius := _rng.randf_range(46.0, 70.0)
		var start := _rng.randf_range(0.0, TAU)
		var speed := _rng.randf_range(0.05, 0.09) * (1.0 if school % 2 == 0 else -1.0)
		for i in 6:
			add_child(Fish.new(radius + _rng.randf_range(-2.0, 2.0), start + i * 0.06, speed, _rng.randf_range(-2.2, -0.8)))
	add_child(Crab.new(_rng))


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
		# Une mouette en facettes : corps blanc fuselé, bec jaune, ailes grises à bouts noirs.
		add_child(Props.ball(0.16, Color(0.97, 0.97, 0.97), Vector3.ZERO, 5, 0.0, Vector3(0.9, 0.85, 2.0)))
		add_child(Props.ball(0.11, Color(0.97, 0.97, 0.97), Vector3(0, 0.08, -0.3), 6))
		var beak := Props.cyl(0.0, 0.035, 0.14, Color(0.98, 0.72, 0.18), Vector3(0, 0.06, -0.45), 5)
		beak.rotation.x = -PI / 2
		add_child(beak)
		add_child(Props.cyl(0.02, 0.09, 0.22, Color(0.85, 0.85, 0.88), Vector3(0, 0, 0.36), 4))
		add_child(Props.cyl(0.02, 0.09, 0.22, Color(0.85, 0.85, 0.88), Vector3(0, 0, 0.36), 4))
		get_child(-1).rotation.x = PI / 2
		get_child(-2).rotation.x = PI / 2
		_left = _wing(-1.0)
		add_child(_left)
		_right = _wing(1.0)
		add_child(_right)

	func _wing(side: float) -> Node3D:
		var w := Node3D.new()
		w.add_child(Props.box(Vector3(0.4, 0.03, 0.26), Color(0.82, 0.83, 0.87), Vector3(side * 0.22, 0, 0)))
		var tip := Props.box(Vector3(0.36, 0.025, 0.18), Color(0.82, 0.83, 0.87), Vector3(side * 0.58, 0.04, 0.03))
		tip.rotation.z = side * 0.25
		w.add_child(tip)
		w.add_child(Props.box(Vector3(0.12, 0.026, 0.16), Color(0.12, 0.12, 0.14), Vector3(side * 0.74, 0.08, 0.04)))
		for part: MeshInstance3D in w.get_children():
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		return w

	func _process(delta: float) -> void:
		_t += delta
		angle += speed * delta
		var p := AmbientMotion.orbit(Vector3(0, height + sin(_t * 0.4) * 1.5, 0), radius, angle)
		position = p
		var heading := AmbientMotion.orbit_heading(angle, speed)
		look_at(p + heading, Vector3.UP)
		# 0.1.17 : une mouette penche dans son virage (vers le centre du cercle), et plane la
		# plupart du temps, ailes un peu relevées, avec de courtes séries de battements (avant :
		# elle battait sans arrêt au même rythme, à plat).
		rotate_object_local(Vector3.FORWARD, signf(speed) * AmbientMotion.bank_angle(radius, absf(speed) * radius))
		var f := AmbientMotion.glide_flap(_t + radius, 9.0, 0.6)
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
		# Le poisson du Food Kit de Kenney (CC0), tête vers −Z (le sens de look_at).
		var fish := Models.load_model("fish")
		Models.fit_on_ground(fish, 0.22)
		var holder := Node3D.new()
		holder.add_child(fish)
		holder.position.y = -0.11
		var span := Models.bounds(Models.vertices(fish))
		if span.size.x > span.size.z:
			holder.rotation.y = PI / 2  # le modèle est allongé sur X : on le remet sur Z
		add_child(holder)
		for mi: MeshInstance3D in Models.meshes_of(fish):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

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
	var _model: Node3D

	func _init(rng: RandomNumberGenerator) -> void:
		_rng = rng

	func _ready() -> void:
		# Le crabe animé de Quaternius (CC0) : il marche (« Walk ») et attend (« Idle »).
		_model = Props.character("crab", 0.25, "MonsterArmature|Idle")
		add_child(_model)
		position = AmbientMotion.ring_point(_rng, 21.5, 23.7, 0.5)
		position.y = GameState.terrain.height(position.x, position.z)
		_target = position

	func _process(delta: float) -> void:
		_t += delta
		if _rest > 0.0:
			_rest -= delta
			Props.play(_model, "MonsterArmature|Idle")
			return
		Props.play(_model, "MonsterArmature|Walk", 1.6)
		var to := _target - position
		if to.length() < 0.1:
			_target = AmbientMotion.ring_point(_rng, 21.5, 23.7, 0.5)
			# Pas trop loin d'un coup : un crabe, ça trottine.
			_target = position + (_target - position).limit_length(4.0)
			_rest = _rng.randf_range(1.0, 4.0)
			return
		position += to.normalized() * minf(SPEED * delta, to.length())
		# 0.1.17 : il suit le sable (avant, il restait à 0,5 m de haut, dans l'air ou dans le sol)…
		position.y = GameState.terrain.height(position.x, position.z)
		# …et tourne en douceur vers sa cible au lieu de pivoter d'un coup. Il marche de côté :
		# son flanc (axe X) regarde où il va.
		rotation.y = lerp_angle(rotation.y, atan2(-to.z, to.x), clampf(delta * 6.0, 0.0, 1.0))
