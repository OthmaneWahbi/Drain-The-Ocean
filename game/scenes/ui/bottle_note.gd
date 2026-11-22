class_name BottleNote
extends CanvasLayer
## Le message d'une bouteille à la mer (0.1.23, PRD §19.30) : un dessin SANS TEXTE sur un papier
## crème, plein écran ; un clic (ou E, ou Échap) le ferme. Quatre dessins : la carte de l'île
## avec sa croix, quelqu'un qui tire une chaîne au fond de la mer, l'avion qui emmène quelqu'un,
## un crabe à chapeau. Tout est dessiné au trait (_draw), comme au crayon.

var drawing := ""
var _paper: Control


func _ready() -> void:
	layer = 12
	_paper = Sketch.new()
	_paper.set_anchors_preset(Control.PRESET_FULL_RECT)
	_paper.mouse_filter = Control.MOUSE_FILTER_STOP
	_paper.gui_input.connect(_on_input)
	add_child(_paper)
	visible = false
	GameState.bottle_opened.connect(open)


func open(d: String) -> void:
	drawing = d
	(_paper as Sketch).drawing = d
	visible = true
	GameState.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_paper.queue_redraw()


func close() -> void:
	if not visible:
		return
	visible = false
	GameState.ui_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(&"interact") or event.is_action_pressed(&"pause")):
		close()
		get_viewport().set_input_as_handled()


class Sketch extends Control:
	var drawing := ""
	const PAPER := Color(0.98, 0.94, 0.82)
	const INK := Color(0.25, 0.18, 0.12)
	const SEA := Color(0.35, 0.6, 0.8)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
		var w := minf(size.x * 0.6, size.y * 0.78 * 1.3)
		var h := w / 1.3
		var r := Rect2((size - Vector2(w, h)) / 2.0, Vector2(w, h))
		draw_rect(r, PAPER)
		draw_rect(r, INK.lightened(0.3), false, 4.0)
		var c := r.get_center()
		var u := h / 10.0
		# « Clic pour fermer », sous la feuille (le seul texte : le dessin, lui, n'en a pas).
		var font := ThemeDB.fallback_font
		var hint := tr("BOTTLE_CLOSE")
		var fs := 22
		var tw := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(c.x - tw / 2.0, r.end.y + 34.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.9))
		match drawing:
			"carte":
				_island(c, u * 3.2)
				var x := c + Vector2(-u * 1.4, u * 1.0)
				draw_line(x - Vector2(u, u) * 0.4, x + Vector2(u, u) * 0.4, Color(0.8, 0.15, 0.1), 6.0)
				draw_line(x + Vector2(-u, u) * 0.4, x + Vector2(u, -u) * 0.4, Color(0.8, 0.15, 0.1), 6.0)
				_dashes(c + Vector2(u * 2.0, -u * 1.0), x)
			"chaine":
				draw_rect(Rect2(r.position + Vector2(0, h * 0.25), Vector2(w, h * 0.75)), SEA.lightened(0.5))
				draw_line(r.position + Vector2(0, h * 0.25), r.position + Vector2(w, h * 0.25), SEA, 3.0)
				# Le fond, la bonde, la chaîne qui monte, et quelqu'un qui tire.
				draw_line(Vector2(r.position.x, r.end.y - u), Vector2(r.end.x, r.end.y - u), INK, 3.0)
				draw_circle(Vector2(c.x + u * 2, r.end.y - u), u * 0.5, INK)
				for i in 8:
					var p := Vector2(c.x + u * 2 - i * u * 0.35, r.end.y - u * 1.3 - i * u * 0.45)
					draw_arc(p, u * 0.18, 0, TAU, 10, INK, 3.0)
				_person(Vector2(c.x - u * 1.0, r.end.y - u * 4.6), u, -0.6)
			"avion":
				draw_line(Vector2(r.position.x, c.y + u * 3), Vector2(r.end.x, c.y + u * 3), SEA, 3.0)
				_plane(c + Vector2(u, -u * 1.5), u * 1.6)
				draw_line(c + Vector2(u, -u * 1.2), c + Vector2(u * 0.8, u * 1.2), INK, 2.0)
				_person(c + Vector2(u * 0.8, u * 1.6), u * 0.7, 0.0)
				_island(c + Vector2(-u * 3.5, u * 3.2), u * 1.2)
			"crabe":
				draw_circle(c + Vector2(0, u), u * 1.6, Color(0.9, 0.35, 0.2))
				for s in [-1.0, 1.0]:
					draw_circle(c + Vector2(s * u * 2.3, -u * 0.2), u * 0.6, Color(0.9, 0.35, 0.2))
					draw_line(c + Vector2(s * u * 1.4, u * 0.6), c + Vector2(s * u * 2.1, 0), INK, 4.0)
					for k in 3:
						draw_line(c + Vector2(s * u * 1.3, u * (1.2 + k * 0.4)), c + Vector2(s * u * 2.4, u * (1.8 + k * 0.5)), INK, 4.0)
					draw_circle(c + Vector2(s * u * 0.5, -u * 0.4), u * 0.22, Color.WHITE)
					draw_circle(c + Vector2(s * u * 0.5, -u * 0.4), u * 0.1, INK)
				# Le chapeau posé sur le haut de la carapace (qui monte à -0,6 u).
				draw_rect(Rect2(c + Vector2(-u * 1.0, -u * 0.85), Vector2(u * 2.0, u * 0.25)), INK)
				draw_rect(Rect2(c + Vector2(-u * 0.6, -u * 1.85), Vector2(u * 1.2, u * 1.0)), INK)

	func _island(c: Vector2, rad: float) -> void:
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			var k := 1.0 + 0.12 * sin(a * 3.0) + 0.06 * cos(a * 5.0)
			pts.append(c + Vector2(cos(a) * rad * 1.2 * k, sin(a) * rad * 0.8 * k))
		draw_colored_polygon(pts, Color(0.95, 0.82, 0.5))
		pts.append(pts[0])
		draw_polyline(pts, INK, 3.0)
		draw_line(c + Vector2(rad * 0.4, 0), c + Vector2(rad * 0.5, -rad * 0.6), Color(0.45, 0.3, 0.15), 4.0)
		for k in 3:
			var a := -0.4 + k * 0.6
			draw_line(c + Vector2(rad * 0.5, -rad * 0.6), c + Vector2(rad * 0.5, -rad * 0.6) + Vector2(cos(a + PI * 1.2), sin(a + PI * 1.2)) * rad * 0.35, Color(0.25, 0.55, 0.25), 4.0)

	func _dashes(from: Vector2, to: Vector2) -> void:
		var n := 10
		for i in n:
			if i % 2 == 0:
				draw_line(from.lerp(to, float(i) / n), from.lerp(to, float(i + 1) / n), INK, 3.0)

	func _person(p: Vector2, u: float, lean: float) -> void:
		draw_circle(p, u * 0.3, INK)
		var hip := p + Vector2(lean * u, u * 1.2)
		draw_line(p + Vector2(0, u * 0.3), hip, INK, 4.0)
		draw_line(hip, hip + Vector2(-u * 0.4, u * 0.9), INK, 4.0)
		draw_line(hip, hip + Vector2(u * 0.4, u * 0.9), INK, 4.0)
		draw_line(p + Vector2(lean * u * 0.4, u * 0.6), p + Vector2(u * 0.9, u * 0.2), INK, 4.0)

	func _plane(c: Vector2, u: float) -> void:
		draw_rect(Rect2(c - Vector2(u * 1.2, u * 0.2), Vector2(u * 2.4, u * 0.4)), Color(0.85, 0.25, 0.2))
		draw_rect(Rect2(c - Vector2(u * 0.3, u * 0.7), Vector2(u * 0.6, u * 1.4)), Color(0.95, 0.85, 0.3))
		draw_line(c + Vector2(u * 1.2, -u * 0.5), c + Vector2(u * 1.2, u * 0.5), INK, 3.0)
