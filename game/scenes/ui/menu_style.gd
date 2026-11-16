class_name MenuStyle
extends RefCounted
## Le style commun des menus (principal, pause, options) : la page de catalogue de UiTheme.


static func panel() -> StyleBoxFlat:
	return UiTheme.paper()


## Un titre centré ; `key` est une clé de traduction (retraduite seule au changement de langue).
static func title(key: String, size: int) -> Label:
	var label := Label.new()
	label.text = key
	label.theme_type_variation = "Title"
	label.add_theme_font_size_override("font_size", size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


## Un fond plein écran qui assombrit le jeu et attrape les clics.
static func backdrop(alpha: float) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = Color(UiTheme.INK, alpha)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	return rect


## Un conteneur plein écran qui centre son contenu.
static func centered() -> CenterContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	return center


## Le thème de toute l'interface (UiTheme).
static func theme() -> Theme:
	return UiTheme.theme()
