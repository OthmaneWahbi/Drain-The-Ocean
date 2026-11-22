class_name WeatherView
extends Node3D
## Ce qu'on voit du temps qu'il fait (0.1.22, PRD §19.29). Aucune règle : tout lit
## GameState.weather_value(...). Venteux : les palmiers ploient et les vagues grossissent.
## Couvert : ciel gris, soleil plus doux. Canicule : lumière plus chaude. Averse au loin : un
## nuage sombre et un rideau de pluie à l'horizon (il ne pleut jamais sur l'île : Q-09).
## Les changements se font en douceur (quelques secondes), jamais d'un coup.

const RAIN_DISTANCE := 170.0
const GREY_TOP := Color(0.5, 0.56, 0.64)
const GREY_HORIZON := Color(0.72, 0.75, 0.79)
const HOT_SUN := Color(1.0, 0.82, 0.6)
## Les valeurs par défaut de sky.gdshader et ocean.gdshader (quand le matériau ne les règle pas).
const SKY_TOP := Color(0.22, 0.52, 0.92)
const SKY_HORIZON := Color(0.62, 0.84, 0.98)
const WAVES := {"wave_a": Vector4(1.0, 0.3, 0.07, 14.0), "wave_b": Vector4(-0.4, 1.0, 0.05, 9.0), "wave_c": Vector4(0.7, -0.8, 0.04, 5.0)}

var sun: DirectionalLight3D
var env: Environment
var ocean_material: ShaderMaterial
var palms: Array[Node3D] = []

var _wind := 0.0
var _overcast := 0.0
var _heat := 0.0
var _rain := 0.0
var _t := 0.0
var _sky: ShaderMaterial
var _sky_top: Color
var _sky_horizon: Color
var _waves: Dictionary = {}
var _palm_base: Array[Vector3] = []
var _storm: Node3D
var _rain_mat: ShaderMaterial


func setup(p_sun: DirectionalLight3D, p_env: Environment, p_ocean: ShaderMaterial, p_palms: Array[Node3D]) -> void:
	sun = p_sun
	env = p_env
	ocean_material = p_ocean
	palms = p_palms


func _ready() -> void:
	if env and env.sky and env.sky.sky_material is ShaderMaterial:
		_sky = env.sky.sky_material
		# Un paramètre jamais réglé vaut null : on prend alors la valeur par défaut du shader.
		var top = _sky.get_shader_parameter("day_top")
		var hor = _sky.get_shader_parameter("day_horizon")
		_sky_top = top if top is Color else SKY_TOP
		_sky_horizon = hor if hor is Color else SKY_HORIZON
	if ocean_material:
		for w in WAVES:
			var v = ocean_material.get_shader_parameter(w)
			_waves[w] = v if v is Vector4 else WAVES[w]
	for p in palms:
		var m: Node3D = p.get_meta("model") if p.has_meta("model") else p
		_palm_base.append(m.rotation)
	_build_storm()
	# Au chargement, le temps est déjà là (pas de transition depuis « calme »).
	_wind = GameState.weather_value("wind")
	_overcast = GameState.weather_value("overcast")
	_heat = GameState.weather_value("heat")
	_rain = GameState.weather_value("rain")


## Le nuage sombre et le rideau de pluie, loin au large.
func _build_storm() -> void:
	_storm = Node3D.new()
	_storm.name = "DistantShower"
	add_child(_storm)
	var a := deg_to_rad(250.0)
	_storm.position = Vector3(cos(a) * RAIN_DISTANCE, 0.0, sin(a) * RAIN_DISTANCE)
	var cloud_color := Color(0.42, 0.45, 0.52)
	for i in 9:
		var b := Props.ball(14.0 + (i % 3) * 4.0, cloud_color, Vector3((i - 4) * 11.0, 46.0 + (i % 2) * 5.0, (i % 3 - 1) * 7.0), i, 0.15, Vector3(1.3, 0.55, 1.0))
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_storm.add_child(b)
	var shader := Shader.new()
	shader.code = RAIN_SHADER
	_rain_mat = ShaderMaterial.new()
	_rain_mat.shader = shader
	for i in 7:
		var q := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(20.0, 48.0)
		q.mesh = quad
		q.material_override = _rain_mat
		q.position = Vector3((i - 3) * 13.0, 21.0, (i % 2) * 5.0 - 2.5)
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_storm.add_child(q)


const RAIN_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float amount = 1.0;
void vertex() {
	// Toujours face à la caméra autour de l'axe vertical.
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 center = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 to_cam = normalize(vec3(cam.x - center.x, 0.0, cam.z - center.z));
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), to_cam));
	vec3 world = center + right * VERTEX.x + vec3(0.0, VERTEX.y, 0.0);
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;
}
void fragment() {
	float col = floor(UV.x * 60.0);
	float speed = 1.6 + fract(sin(col * 12.9898) * 43758.5453) * 0.8;
	float y = fract(UV.y * 3.0 - TIME * speed + fract(sin(col * 78.233) * 9631.7));
	float streak = step(0.55, y) * step(fract(UV.x * 60.0), 0.35);
	float fade = smoothstep(0.0, 0.15, UV.x) * smoothstep(1.0, 0.85, UV.x) * smoothstep(1.0, 0.7, UV.y);
	ALBEDO = vec3(0.45, 0.5, 0.6);
	ALPHA = (0.3 + 0.4 * streak) * fade * amount;
}
"""


func _process(delta: float) -> void:
	_t += delta
	var k := clampf(delta * 0.3, 0.0, 1.0)  # quelques secondes pour passer d'un temps à l'autre
	_wind = lerpf(_wind, GameState.weather_value("wind"), k)
	_overcast = lerpf(_overcast, GameState.weather_value("overcast"), k)
	_heat = lerpf(_heat, GameState.weather_value("heat"), k)
	_rain = lerpf(_rain, GameState.weather_value("rain"), k)
	_apply()


## Les palmiers ploient avec le vent (en plus de leur penchant naturel).
static func palm_bend(wind: float, t: float, index: int) -> float:
	return -wind * (0.09 + 0.06 * sin(t * 1.4 + index * 0.9))


## Le coefficient des vagues selon le vent (1 par temps calme).
static func wave_factor(wind: float) -> float:
	return 1.0 + 0.9 * wind


func _apply() -> void:
	for i in palms.size():
		var p := palms[i]
		if not is_instance_valid(p):
			continue
		var m: Node3D = p.get_meta("model") if p.has_meta("model") else p
		m.rotation = _palm_base[i] + Vector3(0, 0, palm_bend(_wind, _t, i))
	if ocean_material:
		var f := wave_factor(_wind)
		for w in _waves:
			var v: Vector4 = _waves[w]
			ocean_material.set_shader_parameter(w, Vector4(v.x, v.y, v.z * f, v.w))
	if _sky:
		_sky.set_shader_parameter("day_top", _sky_top.lerp(GREY_TOP, _overcast * 0.85))
		_sky.set_shader_parameter("day_horizon", _sky_horizon.lerp(GREY_HORIZON, _overcast * 0.85))
	if sun:
		# La lumière du soleil est déjà réglée pour l'heure (main.gd) : on la nuance.
		sun.light_energy *= 1.0 - 0.45 * _overcast
		sun.light_color = sun.light_color.lerp(HOT_SUN, 0.35 * _heat)
	if env:
		env.ambient_light_energy *= 1.0 + 0.25 * _overcast
	_storm.visible = _rain > 0.02
	_rain_mat.set_shader_parameter("amount", _rain)
