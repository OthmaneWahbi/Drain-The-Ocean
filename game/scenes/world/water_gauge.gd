class_name WaterGauge
extends StaticBody3D
## Le repère de niveau d'eau planté près de la plage (M-62, N-10).
##
## Le chiffre affiché est honnête : la vraie baisse du niveau, en millimètres.
## L'aiguille, elle, suit une échelle LOGARITHMIQUE : chaque cran est ×10. Le tout premier seau
## (~10⁻¹³ mm) la fait déjà bouger, et elle n'arrive en butée qu'à 1 m de baisse.

## Plage de l'aiguille, en puissances de 10 de mètres : de 10⁻¹⁶ m à 1 m.
const LOG_MIN := -16.0
const LOG_MAX := 0.0
const SWEEP_DEG := 270.0

var _needle_pivot: Node3D
var _label: Label3D


func _ready() -> void:
	add_child(Greybox.cylinder(0.06, 1.6, Greybox.WOOD, Vector3(0, 0.8, 0), 8))
	var dial := Greybox.cylinder(0.45, 0.06, Color(0.92, 0.9, 0.84), Vector3.ZERO, 24)
	dial.rotation_degrees = Vector3(90, 0, 0)
	dial.position = Vector3(0, 1.75, 0.04)
	add_child(dial)
	# Graduations : un trait par puissance de 10.
	for i in int(LOG_MAX - LOG_MIN) + 1:
		var tick := Node3D.new()
		tick.position = Vector3(0, 1.75, 0.08)
		tick.rotation_degrees.z = _angle_for_ratio(float(i) / (LOG_MAX - LOG_MIN))
		tick.add_child(Greybox.box(Vector3(0.015, 0.06, 0.01), Color(0.15, 0.15, 0.15), Vector3(0, 0.36, 0)))
		add_child(tick)
	_needle_pivot = Node3D.new()
	_needle_pivot.position = Vector3(0, 1.75, 0.1)
	_needle_pivot.add_child(Greybox.box(Vector3(0.025, 0.36, 0.01), Greybox.PHONE_RED, Vector3(0, 0.16, 0)))
	add_child(_needle_pivot)
	add_child(Greybox.box(Vector3(0.95, 0.26, 0.03), Color(0.92, 0.9, 0.84), Vector3(0, 1.12, 0.07)))
	_label = Label3D.new()
	_label.position = Vector3(0, 1.12, 0.1)
	_label.font_size = 28
	_label.pixel_size = 0.004
	_label.modulate = Color(0.1, 0.1, 0.1)
	_label.outline_size = 0
	add_child(_label)
	add_child(Greybox.box_collision(Vector3(1.0, 2.3, 0.3), Vector3(0, 1.15, 0)))
	GameState.ocean_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var drop := GameState.ocean.level_drop_m(GameState.config.ocean_surface_m2)
	_needle_pivot.rotation_degrees.z = _angle_for_ratio(needle_ratio(drop))
	_label.text = "%s\n%s" % [tr("GAUGE_TITLE"), format_drop_mm(drop)]


func get_prompt(_player: Node) -> String:
	return "%s : %s" % [tr("GAUGE_TITLE"), format_drop_mm(GameState.ocean.level_drop_m(GameState.config.ocean_surface_m2))]


## 0 = aiguille à gauche (rien retiré), 1 = en butée à droite (1 m de baisse).
static func needle_ratio(drop_m: float) -> float:
	if drop_m <= 0.0:
		return 0.0
	return clampf((log(drop_m) / log(10.0) - LOG_MIN) / (LOG_MAX - LOG_MIN), 0.0, 1.0)


## Baisse honnête en millimètres, en notation scientifique lisible : « −3,5 × 10⁻¹³ mm ».
static func format_drop_mm(drop_m: float) -> String:
	var mm := drop_m * 1000.0
	if mm <= 0.0:
		return "0 mm"
	if mm >= 0.1:
		return "−%s mm" % String.num(mm, 1).replace(".", ",")
	var exponent := int(floor(log(mm) / log(10.0)))
	var mantissa := mm / pow(10.0, exponent)
	if mantissa >= 9.95:
		mantissa /= 10.0
		exponent += 1
	return "−%s × 10%s mm" % [String.num(mantissa, 1).replace(".", ","), _superscript(exponent)]


static func _superscript(n: int) -> String:
	const DIGITS := ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"]
	var out := "⁻" if n < 0 else ""
	for c in str(absi(n)):
		out += DIGITS[int(c)]
	return out


func _angle_for_ratio(ratio: float) -> float:
	# Rotation autour de l'axe Z (cadran face à +Z) : de +135° (gauche) à −135° (droite).
	return SWEEP_DEG / 2.0 - ratio * SWEEP_DEG
