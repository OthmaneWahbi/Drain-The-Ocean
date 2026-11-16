class_name UnderwaterOverlay
extends CanvasLayer
## Sous l'eau : un filtre plein écran bleu-vert qui ondule (shaders/underwater.gdshader) et un
## brouillard bleu épais qui remplace celui du ciel. On remet le brouillard d'origine en sortant.
## Rien d'autre : la règle « la caméra est sous la surface » est dans `is_camera_under()`.

const UnderwaterShader := preload("res://scenes/ui/shaders/underwater.gdshader")

const FOG_COLOR := Color(0.05, 0.3, 0.4)
const FOG_DENSITY := 0.09

## L'environnement dont on change le brouillard (fourni par main.gd).
var environment: Environment
var under: bool = false
var _rect: ColorRect
var _saved_fog_color: Color
var _saved_fog_density: float
var _saved_fog_sky_affect: float


func _ready() -> void:
	layer = -1  # sous le HUD
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = UnderwaterShader
	_rect.material = mat
	_rect.visible = false
	add_child(_rect)


## Vrai si les yeux sont sous la surface (avec une petite marge pour les vagues).
static func is_camera_under(camera_y: float, water_y: float, margin: float = 0.05) -> bool:
	return camera_y < water_y - margin


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	set_under(is_camera_under(cam.global_position.y, GameState.water_level_y()))


func set_under(value: bool) -> void:
	if value == under:
		return
	under = value
	_rect.visible = value
	if environment == null:
		return
	if value:
		_saved_fog_color = environment.fog_light_color
		_saved_fog_density = environment.fog_density
		_saved_fog_sky_affect = environment.fog_sky_affect
		environment.fog_light_color = FOG_COLOR
		environment.fog_density = FOG_DENSITY
		environment.fog_sky_affect = 1.0
	else:
		environment.fog_light_color = _saved_fog_color
		environment.fog_density = _saved_fog_density
		environment.fog_sky_affect = _saved_fog_sky_affect
