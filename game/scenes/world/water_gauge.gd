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
	# Un poteau en bois planté dans un tas de pierres, un cadran crème cerclé de laiton, une
	# aiguille rouge et une plaque (0.1.4 : style du catalogue).
	# 0.1.10 (remarque 11) : le poteau passe DERRIÈRE le cadran et la plaque (avant, il les
	# traversait et ses faces se battaient avec elles : le bois clignotait à travers le cadran).
	add_child(Props.box(Vector3(0.14, 1.85, 0.12), Props.WOOD_DARK, Vector3(0, 0.92, -0.08)))
	add_child(Props.box(Vector3(0.5, 0.5, 0.03), Props.WOOD_DARK, Vector3(0, 1.75, -0.025)))  # la planche qui tient le cadran
	for i in 5:
		var a := TAU * i / 5.0
		add_child(Props.ball(0.13, Color(0.6, 0.58, 0.55), Vector3(cos(a) * 0.18, 0.04, sin(a) * 0.18), 60 + i, 0.2, Vector3(1, 0.6, 1)))
	var bezel := Props.torus(0.44, 0.52, Color(0.85, 0.66, 0.25), Vector3(0, 1.75, 0.06), 24)
	bezel.rotation_degrees = Vector3(90, 0, 0)
	add_child(bezel)
	add_child(Props.cyl(0.07, 0.11, 0.2, Props.RED, Vector3(0, 2.28, 0.0), 8))
	var dial := Greybox.cylinder(0.45, 0.06, UiTheme.PAPER, Vector3.ZERO, 24)
	dial.rotation_degrees = Vector3(90, 0, 0)
	dial.position = Vector3(0, 1.75, 0.04)
	add_child(dial)
	# Graduations : un trait par puissance de 10.
	for i in int(LOG_MAX - LOG_MIN) + 1:
		var tick := Node3D.new()
		tick.position = Vector3(0, 1.75, 0.08)
		tick.rotation_degrees.z = _angle_for_ratio(float(i) / (LOG_MAX - LOG_MIN))
		tick.add_child(Greybox.box(Vector3(0.02, 0.07 if i % 4 == 0 else 0.045, 0.01), UiTheme.INK, Vector3(0, 0.36, 0)))
		add_child(tick)
	_needle_pivot = Node3D.new()
	_needle_pivot.position = Vector3(0, 1.75, 0.1)
	_needle_pivot.add_child(Greybox.box(Vector3(0.03, 0.36, 0.01), UiTheme.RED, Vector3(0, 0.16, 0)))
	_needle_pivot.add_child(Props.cyl(0.04, 0.04, 0.02, UiTheme.INK, Vector3.ZERO, 8))
	_needle_pivot.get_child(-1).rotation.x = PI / 2
	add_child(_needle_pivot)
	add_child(Props.box(Vector3(1.0, 0.3, 0.04), Props.YELLOW, Vector3(0, 1.12, 0.07)))
	_label = Label3D.new()
	_label.position = Vector3(0, 1.12, 0.1)
	_label.font_size = 28
	_label.pixel_size = 0.004
	_label.modulate = UiTheme.INK
	_label.font = UiTheme.bold_font()
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
