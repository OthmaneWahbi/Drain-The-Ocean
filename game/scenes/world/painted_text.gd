class_name PaintedText
extends MeshInstance3D
## Du texte peint DANS la matière d'un objet (tampon sur une caisse, enseigne de la cabine, nom
## sur une planchette…), à la place des Label3D qui avaient l'air collés par-dessus : un Label3D
## n'est pas éclairé (il brille la nuit et à l'ombre), il est net comme un écran, et il n'a ni
## usure ni coups de pinceau.
##
## Comment : la police dessine le texte une seule fois dans une petite SubViewport, l'image est
## relue (avec ses mipmaps, pour rester propre de loin) et gardée en cache ; puis un simple quad
## posé à plat sur la surface l'affiche avec le shader `painted_text.gdshader`, qui l'éclaire
## comme l'objet et lui donne l'aspect d'une peinture (voir le shader).
##
## Les textes qui ne bougent pas (`text` = clé de traduction) sont partagés par tous les objets ;
## ceux qui changent (compteurs, jauge) sont redessinés à chaque changement.

## Le style de peinture : chacun règle l'usure, les coups de pinceau, le tremblé et la couche.
enum Style {
	BRUSH,    ## peint au pinceau (enseignes, banderole, toboggan)
	STENCIL,  ## au pochoir, usé par le voyage (caisses, rations, avion)
	PRINT,    ## écrit proprement au marqueur sur une étiquette (planchettes, jauge)
}

const STYLE_PARAMS := {
	Style.BRUSH: {"wear": 0.18, "streaks": 0.45, "wobble": 0.02, "bleed": 0.4, "coverage": 0.92, "paint_roughness": 0.75},
	Style.STENCIL: {"wear": 0.3, "streaks": 0.25, "wobble": 0.004, "bleed": 0.55, "coverage": 0.86, "paint_roughness": 0.9},
	Style.PRINT: {"wear": 0.06, "streaks": 0.12, "wobble": 0.006, "bleed": 0.2, "coverage": 0.95, "paint_roughness": 0.85},
}

## Les lettres sont dessinées ce nombre de fois plus grandes que leur taille nominale (netteté).
const OVERSAMPLE := 2.0
## Marge autour du texte dessiné, en pixels (les bords qui bavent ne sont pas coupés).
const PAD := 6

static var _shader: Shader
static var _cache: Dictionary = {}  # clé -> ImageTexture

var text := "":
	set = set_text
var font: Font
var font_size := 32
## Mètres par pixel de police, comme Label3D.pixel_size.
var pixel_size := 0.004
var color := Color.BLACK:
	set = set_color
## Largeur maximale en mètres (0 = libre). Sans `wrap`, un texte trop long est rétréci pour tenir.
var max_width := 0.0
var wrap := false
var style := Style.BRUSH
## Texte qui change souvent (compteur) : pas de cache partagé.
var dynamic := false

var _mat: ShaderMaterial
var _viewport: SubViewport
var _built := false
var _shown := ""
var _last_key := ""


func _init(p_text := "", p_color := Color.BLACK, p_style := Style.BRUSH) -> void:
	text = p_text
	color = p_color
	style = p_style
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _shader == null:
		_shader = load("res://scenes/world/shaders/painted_text.gdshader") as Shader
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	material_override = _mat
	var q := QuadMesh.new()  # jamais nul : d'autres codes parcourent les maillages d'un modèle
	q.size = Vector2.ZERO  # sa vraie taille est calculée en entrant dans l'arbre
	mesh = q


func _enter_tree() -> void:
	_ensure_built()  # à la première entrée (sans attendre _ready : la taille sert tout de suite)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _built:
		_rebuild()


func set_text(value: String) -> void:
	if value == text and _shown != "":
		return
	text = value
	if _built:
		_rebuild()


func set_color(value: Color) -> void:
	color = value
	if _mat:
		_mat.set_shader_parameter("paint_color", value)


## Le texte tel qu'il est peint (traduit), pour les tests et les captures.
func shown_text() -> String:
	_ensure_built()
	return _shown


## Taille du texte posé, en mètres (largeur, hauteur).
func painted_size() -> Vector2:
	_ensure_built()
	return (mesh as QuadMesh).size


## Hors de l'arbre (tests), la mise en page se fait à la première question.
func _ensure_built() -> void:
	if not _built:
		_built = true
		_rebuild()


func _rebuild() -> void:
	_shown = tr(text)
	if _shown.strip_edges().is_empty():
		(mesh as QuadMesh).size = Vector2.ZERO
		return
	var f: Font = font if font else UiTheme.marker_font()
	var px := int(round(font_size * OVERSAMPLE))
	var wrap_px := max_width / pixel_size * OVERSAMPLE if wrap and max_width > 0.0 else -1.0
	var size_px: Vector2
	if wrap_px > 0.0:
		size_px = f.get_multiline_string_size(_shown, HORIZONTAL_ALIGNMENT_CENTER, wrap_px, px, -1, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND)
		size_px.x = wrap_px
	else:
		size_px = f.get_multiline_string_size(_shown, HORIZONTAL_ALIGNMENT_CENTER, -1, px)
	var tex_size := Vector2i(ceili(size_px.x) + PAD * 2, ceili(size_px.y) + PAD * 2)
	var m := pixel_size / OVERSAMPLE
	var quad := Vector2(tex_size) * m
	# Trop long pour sa place : on le peint plus petit (jamais de lettres qui débordent).
	var fit_w := max_width + PAD * 2 * m
	if max_width > 0.0 and quad.x > fit_w:
		quad *= fit_w / quad.x
	(mesh as QuadMesh).size = quad
	var params: Dictionary = STYLE_PARAMS[style]
	for k in params:
		_mat.set_shader_parameter(k, params[k])
	_mat.set_shader_parameter("paint_color", color)
	_mat.set_shader_parameter("quad_size", quad)
	_mat.set_shader_parameter("seed", float(hash(_shown) % 997) / 97.0 + position.x * 3.1 + position.z * 1.7)
	_last_key = "%s|%s|%d|%d" % [_shown, f.resource_path, px, int(wrap_px)]
	var key := _last_key
	if _cache.has(key):
		_mat.set_shader_parameter("text_tex", _cache[key])
		return
	if DisplayServer.get_name() == "headless":
		return  # pas de rendu : rien à dessiner (tests)
	# Différé : le parent peut être en train de préparer ses enfants (add_child refusé).
	_draw_text.call_deferred(f, px, wrap_px, tex_size, key)


func _key() -> String:
	return _last_key


## Dessine le texte dans une SubViewport (une seule image), puis la relit en ImageTexture.
func _draw_text(f: Font, px: int, wrap_px: float, tex_size: Vector2i, key: String) -> void:
	if not is_inside_tree() or key != _key():
		return  # retiré, ou le texte a encore changé entre-temps
	if _viewport:
		_viewport.queue_free()
	var vp := SubViewport.new()
	vp.size = tex_size
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var label := Label.new()
	label.text = _shown
	label.add_theme_font_override(&"font", f)
	label.add_theme_font_size_override(&"font_size", px)
	label.add_theme_color_override(&"font_color", Color.WHITE)
	label.add_theme_constant_override(&"outline_size", 0)
	label.add_theme_constant_override(&"shadow_outline_size", 0)
	label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if wrap_px > 0.0:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.position = Vector2(PAD, PAD)
	label.size = Vector2(tex_size - Vector2i(PAD * 2, PAD * 2))
	vp.add_child(label)
	add_child(vp)
	_viewport = vp
	_mat.set_shader_parameter("text_tex", vp.get_texture())
	await RenderingServer.frame_post_draw
	if not is_instance_valid(vp) or vp != _viewport:
		return
	var img := vp.get_texture().get_image()
	if img and not img.is_empty():
		img.convert(Image.FORMAT_RGBA8)
		img.generate_mipmaps()
		var tex := ImageTexture.create_from_image(img)
		if not dynamic:
			_cache[key] = tex
		_mat.set_shader_parameter("text_tex", tex)
	_viewport = null
	vp.queue_free()
