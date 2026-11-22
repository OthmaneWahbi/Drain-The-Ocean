class_name NightLife
extends Node3D
## La nuit vivante (0.1.21, PRD §19.28), purement visuelle : le plancton qui brille autour du
## joueur dans l'eau, des lucioles autour des palmiers, une étoile filante de temps en temps.
## Rien n'y est une règle : tout lit l'heure et la position du joueur dans GameState.

const GLOW := Color(0.35, 1.0, 0.85)
const FIREFLY := Color(1.0, 0.92, 0.4)
const PLANKTON_N := 48
const PLANKTON_LIFE_S := 1.5
const FIREFLIES_PER_PALM := 4

var _plankton: Array[MeshInstance3D] = []
var _plankton_age: Array[float] = []
var _next := 0
var _spawn_acc := 0.0
var _flies: Array[MeshInstance3D] = []
var _fly_home: Array[Vector3] = []
var _star: MeshInstance3D
var _star_t := -1.0
var _star_from := Vector3.ZERO
var _star_to := Vector3.ZERO
var _star_wait := 10.0
var _rng := RandomNumberGenerator.new()
var _t := 0.0


static func glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _ready() -> void:
	_rng.seed = 21
	var dot := SphereMesh.new()
	dot.radius = 0.03
	dot.height = 0.06
	dot.radial_segments = 6
	dot.rings = 3
	for i in PLANKTON_N:
		var m := MeshInstance3D.new()
		m.mesh = dot
		m.material_override = glow_material(GLOW, 3.0)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.visible = false
		add_child(m)
		_plankton.append(m)
		_plankton_age.append(99.0)
	var fly := SphereMesh.new()
	fly.radius = 0.035
	fly.height = 0.07
	fly.radial_segments = 6
	fly.rings = 3
	for p: Vector3 in GameState.config.palms:
		for k in FIREFLIES_PER_PALM:
			var m := MeshInstance3D.new()
			m.mesh = fly
			m.material_override = glow_material(FIREFLY, 4.0)
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(m)
			_flies.append(m)
			var x := p.x + _rng.randf_range(-1.5, 1.5)
			var z := p.y + _rng.randf_range(-1.5, 1.5)
			_fly_home.append(Vector3(x, GameState.terrain.height(x, z) + _rng.randf_range(0.6, 1.8), z))
	var streak := BoxMesh.new()
	streak.size = Vector3(0.6, 0.6, 30.0)
	_star = MeshInstance3D.new()
	_star.mesh = streak
	_star.material_override = glow_material(Color(1, 1, 0.95), 6.0)
	_star.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_star.visible = false
	add_child(_star)


## La nuit, avec un fondu d'une heure autour du coucher et du lever : 0 (jour) à 1 (nuit noire).
static func night_amount(hour: float) -> float:
	if hour >= 21.0 or hour < 5.0:
		return 1.0
	if hour >= 20.0:
		return hour - 20.0
	if hour < 6.0:
		return 6.0 - hour
	return 0.0


func _process(delta: float) -> void:
	_t += delta
	var night := night_amount(GameState.day.hour())
	_update_plankton(delta, night)
	_update_flies(night)
	_update_star(delta, night)


func _update_plankton(delta: float, night: float) -> void:
	var p := GameState.player_position
	var water := GameState.water_level_y()
	var in_water := p.is_finite() and p.y < water - 0.05 and GameState.sea_at(p.x, p.z)
	var speed := Vector2(p.x - _last_p.x, p.z - _last_p.z).length() / maxf(delta, 0.001) if _last_p.is_finite() else 0.0
	_last_p = p
	if night > 0.2 and in_water and speed > 0.3:
		_spawn_acc += delta * clampf(speed, 0.0, 5.0) * 10.0
		while _spawn_acc >= 1.0:
			_spawn_acc -= 1.0
			var m := _plankton[_next]
			var a := _rng.randf_range(0.0, TAU)
			var r := _rng.randf_range(0.2, 1.2)
			m.position = Vector3(p.x + cos(a) * r, water - _rng.randf_range(0.0, 0.25), p.z + sin(a) * r)
			_plankton_age[_next] = 0.0
			m.visible = true
			_next = (_next + 1) % _plankton.size()
	for i in _plankton.size():
		if not _plankton[i].visible:
			continue
		_plankton_age[i] += delta
		var k := _plankton_age[i] / PLANKTON_LIFE_S
		if k >= 1.0:
			_plankton[i].visible = false
			continue
		(_plankton[i].material_override as StandardMaterial3D).albedo_color.a = sin(k * PI) * night


var _last_p := Vector3(INF, INF, INF)


func _update_flies(night: float) -> void:
	for i in _flies.size():
		var m := _flies[i]
		m.visible = night > 0.3
		if not m.visible:
			continue
		var h := _fly_home[i]
		var ph := i * 1.7
		m.position = h + Vector3(sin(_t * 0.6 + ph) * 0.6, sin(_t * 1.3 + ph * 2.0) * 0.25, cos(_t * 0.5 + ph) * 0.6)
		var blink := 0.5 + 0.5 * sin(_t * 3.0 + ph * 3.0)
		(m.material_override as StandardMaterial3D).albedo_color.a = night * blink


func _update_star(delta: float, night: float) -> void:
	if _star_t < 0.0:
		_star.visible = false
		if night < 0.8:
			return
		_star_wait -= delta
		if _star_wait > 0.0:
			return
		_star_wait = _rng.randf_range(0.5, 1.5) * GameState.config.shooting_star_every_s
		var cam := get_viewport().get_camera_3d()
		var c := cam.global_position if cam else Vector3.ZERO
		var a := _rng.randf_range(0.0, TAU)
		_star_from = c + Vector3(cos(a) * 600.0, _rng.randf_range(260.0, 380.0), sin(a) * 600.0)
		var b := a + _rng.randf_range(0.4, 0.8)
		_star_to = c + Vector3(cos(b) * 600.0, _star_from.y - _rng.randf_range(80.0, 140.0), sin(b) * 600.0)
		_star_t = 0.0
	_star_t += delta
	var k := _star_t / 1.1
	if k >= 1.0:
		_star_t = -1.0
		return
	_star.visible = true
	_star.position = _star_from.lerp(_star_to, k)
	_star.look_at(_star_to, Vector3.UP)
	(_star.material_override as StandardMaterial3D).albedo_color.a = sin(k * PI)
