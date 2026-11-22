class_name UiTheme
extends RefCounted
## La direction artistique de toute l'interface (version 0.1.2) : celle du catalogue de l'Agence.
## Un vieux catalogue de vente par correspondance : papier crème, encre violet-nuit, bandeaux
## rouges, étiquettes de prix jaunes écrites au feutre.
## Les polices (2026-11-21, PRD §19.23, voir assets/CREDITS.md), toutes rondes et chaleureuses :
##  - DynaPuff pour les titres (lettres gonflées, cartoon) ;
##  - Nunito pour le texte (arrondie et très lisible), en gras pour les boutons et le HUD ;
##  - Gochi Hand pour les prix et les tampons, « écrits à la main ».
## Chaque police est une ressource `assets/fonts/police_*.tres` (graisse choisie dans la police
## variable, symboles ♪ ▮ ★ pris dans une petite police de secours). La police du texte est aussi
## la police par défaut du projet : tout texte sans police choisie (Label3D, outils admin) la prend.
## Tous les écrans prennent leurs couleurs et leurs polices ici, jamais en dur ailleurs.

const PAPER := Color(1.0, 0.953, 0.84)
const PAPER_DARK := Color(0.95, 0.87, 0.69)
const INK := Color(0.17, 0.14, 0.25)
const INK_SOFT := Color(0.17, 0.14, 0.25, 0.7)
const RED := Color(0.886, 0.255, 0.184)
const RED_DARK := Color(0.66, 0.15, 0.1)
const YELLOW := Color(1.0, 0.79, 0.24)
const YELLOW_DARK := Color(0.85, 0.6, 0.1)
const TEAL := Color(0.12, 0.65, 0.63)
const GREEN := Color(0.25, 0.64, 0.3)
const WHITE := Color(1.0, 1.0, 1.0)

const FONT_DIR := "res://assets/fonts/"
## Gochi Hand dessine ses lettres plus petites que les autres polices : les textes « au feutre »
## sont agrandis d'autant pour garder la même place à l'écran.
const MARKER_SCALE := 1.3

static var _theme: Theme
static var _fonts: Dictionary = {}


static func _font(file: String) -> Font:
	if not _fonts.has(file):
		_fonts[file] = load(FONT_DIR + file) as Font
	return _fonts[file]


static func title_font() -> Font:
	return _font("police_titre.tres")


static func body_font() -> Font:
	return _font("police_texte.tres")


static func bold_font() -> Font:
	return _font("police_gras.tres")


static func marker_font() -> Font:
	return _font("police_feutre.tres")


## La taille à donner à un texte « au feutre » pour qu'il ait l'air de faire `size`.
static func marker_size(size: int) -> int:
	return roundi(size * MARKER_SCALE)


## Un panneau « page de catalogue » : papier crème, bord d'encre épais, ombre décalée.
static func paper(bg := PAPER, border := INK, radius := 14, margin := 22) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(4)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(INK, 0.45)
	s.shadow_size = 1
	s.shadow_offset = Vector2(6, 6)
	s.set_content_margin_all(margin)
	return s


## Un bouton bombé : couleur pleine, bord bas plus foncé (effet relief).
static func button_box(bg: Color, edge: Color, pressed := false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(2)
	s.border_width_bottom = 2 if pressed else 5
	s.set_corner_radius_all(10)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 7 + (3 if pressed else 0)
	s.content_margin_bottom = 7
	return s


## Le thème commun. Variantes : « Title » (titre rouge), « Price » (feutre), « Hud » (texte blanc
## cerné d'encre, lisible sur le monde), « Fine » (petit texte doux), « Tag » (bouton jaune).
static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 19
	# Textes.
	t.set_color("font_color", "Label", INK)
	t.set_type_variation("Title", "Label")
	t.set_font("font", "Title", title_font())
	t.set_color("font_color", "Title", RED)
	t.set_type_variation("Price", "Label")
	t.set_font("font", "Price", marker_font())
	t.set_font_size("font_size", "Price", marker_size(22))
	t.set_color("font_color", "Price", RED_DARK)
	t.set_type_variation("Fine", "Label")
	t.set_color("font_color", "Fine", INK_SOFT)
	t.set_font_size("font_size", "Fine", 15)
	t.set_type_variation("Hud", "Label")
	t.set_font("font", "Hud", bold_font())
	t.set_color("font_color", "Hud", WHITE)
	t.set_color("font_outline_color", "Hud", INK)
	t.set_constant("outline_size", "Hud", 7)
	# Boutons : rouges, jaunes au survol.
	for type in ["Button", "OptionButton"]:
		t.set_font("font", type, bold_font())
		t.set_stylebox("normal", type, button_box(RED, RED_DARK))
		t.set_stylebox("hover", type, button_box(YELLOW, YELLOW_DARK))
		t.set_stylebox("pressed", type, button_box(RED_DARK, RED_DARK, true))
		t.set_stylebox("hover_pressed", type, button_box(YELLOW_DARK, YELLOW_DARK, true))
		t.set_stylebox("disabled", type, button_box(PAPER_DARK, Color(INK, 0.25)))
		t.set_stylebox("focus", type, StyleBoxEmpty.new())
		t.set_color("font_color", type, WHITE)
		t.set_color("font_hover_color", type, INK)
		t.set_color("font_pressed_color", type, WHITE)
		t.set_color("font_hover_pressed_color", type, INK)
		t.set_color("font_focus_color", type, WHITE)
		t.set_color("font_disabled_color", type, Color(INK, 0.4))
	t.set_type_variation("Tag", "Button")
	t.set_stylebox("normal", "Tag", button_box(YELLOW, YELLOW_DARK))
	t.set_stylebox("hover", "Tag", button_box(RED, RED_DARK))
	t.set_color("font_color", "Tag", INK)
	t.set_color("font_hover_color", "Tag", WHITE)
	t.set_color("font_focus_color", "Tag", INK)
	# Cases à cocher, glissières, listes.
	t.set_color("font_color", "CheckBox", INK)
	t.set_color("font_hover_color", "CheckBox", RED)
	t.set_color("font_pressed_color", "CheckBox", INK)
	t.set_color("font_hover_pressed_color", "CheckBox", RED)
	t.set_color("font_focus_color", "CheckBox", INK)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		t.set_stylebox(state, "CheckBox", StyleBoxEmpty.new())
	var track := StyleBoxFlat.new()
	track.bg_color = PAPER_DARK
	track.border_color = INK
	track.set_border_width_all(2)
	track.set_corner_radius_all(6)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", track)
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = RED
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_stylebox("panel", "PanelContainer", paper())
	t.set_stylebox("panel", "PopupMenu", paper(PAPER, INK, 8, 8))
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", RED)
	t.set_font("font", "PopupMenu", bold_font())
	var sep := StyleBoxLine.new()
	sep.color = Color(INK, 0.35)
	sep.thickness = 2
	t.set_stylebox("separator", "HSeparator", sep)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(INK, 0.6)
	bar_bg.set_corner_radius_all(6)
	bar_bg.border_color = INK
	bar_bg.set_border_width_all(2)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = YELLOW
	bar_fill.set_corner_radius_all(6)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	_theme = t
	return t


## Une étiquette de prix inclinée, comme collée sur la page (fond jaune, feutre rouge).
static func price_tag(text: String, size := 22, tilt_deg := -4.0, max_width := 0.0) -> PanelContainer:
	var tag := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = YELLOW
	box.border_color = INK
	box.set_border_width_all(3)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(6)
	box.content_margin_left = 12
	box.content_margin_right = 12
	tag.add_theme_stylebox_override("panel", box)
	var label := Label.new()
	label.theme_type_variation = "Price"
	label.text = text
	label.add_theme_font_size_override("font_size", marker_size(size))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	if max_width > 0.0:
		# Un prix en plusieurs ressources passe à la ligne au lieu d'élargir la page.
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(max_width, 0)
	tag.add_child(label)
	tag.rotation_degrees = tilt_deg
	tag.resized.connect(func(): tag.pivot_offset = tag.size / 2)
	return tag


## Un tampon (« BIENTÔT », « PROMO ») : texte au feutre, cadre de la même couleur, penché.
static func stamp(key: String, color: Color, size := 24, tilt_deg := -12.0) -> PanelContainer:
	var p := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(color, 0.08)
	box.border_color = color
	box.set_border_width_all(4)
	box.set_corner_radius_all(4)
	box.set_content_margin_all(4)
	box.content_margin_left = 10
	box.content_margin_right = 10
	p.add_theme_stylebox_override("panel", box)
	var label := Label.new()
	label.text = key
	label.add_theme_font_override("font", marker_font())
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", marker_size(size))
	p.add_child(label)
	p.rotation_degrees = tilt_deg
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.resized.connect(func(): p.pivot_offset = p.size / 2)
	return p


## Un bandeau rouge avec un titre crème : l'en-tête des pages.
static func banner(key: String, size := 34) -> PanelContainer:
	var p := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = RED
	box.border_color = INK
	box.set_border_width_all(3)
	box.set_corner_radius_all(10)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 4
	box.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", box)
	var label := Label.new()
	label.text = key
	label.add_theme_font_override("font", title_font())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", PAPER)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(label)
	return p
