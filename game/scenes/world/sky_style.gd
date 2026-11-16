class_name SkyStyle
extends RefCounted
## Le ciel cartoon (0.1.1) et la couleur du soleil selon l'heure. Le ciel est un shader
## (shaders/sky.gdshader) qui lit la lumière du soleil : il suffit de l'installer une fois.

const SkyShader := preload("res://scenes/world/shaders/sky.gdshader")


## Remplace le ciel de l'environnement par le ciel cartoon.
static func install(env: Environment) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = SkyShader
	if env.sky == null:
		env.sky = Sky.new()
	env.sky.sky_material = mat
	env.sky.radiance_size = Sky.RADIANCE_SIZE_64


## Couleur de la lumière du soleil : orangée au lever et au coucher, blanc chaud à midi.
static func sun_color(elevation_deg: float) -> Color:
	var t := clampf(elevation_deg / 35.0, 0.0, 1.0)
	return Color(1.0, 0.62, 0.38).lerp(Color(1.0, 0.96, 0.86), t)
