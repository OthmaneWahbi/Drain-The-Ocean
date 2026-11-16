class_name MenuStyle
extends RefCounted
## Le style commun des menus (principal, pause, options) : un panneau sombre arrondi et des titres.


static func panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.12, 0.95)
	style.set_corner_radius_all(10)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		style.set_content_margin(side, 24)
	return style


## Un titre centré ; `key` est une clé de traduction (retraduite seule au changement de langue).
static func title(key: String, size: int) -> Label:
	var label := Label.new()
	label.text = key
	label.add_theme_font_size_override("font_size", size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


## Un fond plein écran qui assombrit le jeu et attrape les clics.
static func backdrop(alpha: float) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = Color(0.02, 0.04, 0.07, alpha)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	return rect


## Un conteneur plein écran qui centre son contenu.
static func centered() -> CenterContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	return center


## Un thème avec un texte plus gros que le HUD : les menus se lisent de loin.
static func theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 19
	return t
