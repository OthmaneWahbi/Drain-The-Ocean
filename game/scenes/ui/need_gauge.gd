class_name NeedGauge
extends Control
## Une jauge ronde de la faim ou de la soif (0.1.3), à côté de la barre d'outils : un médaillon
## de papier dont le liquide (soupe ou eau) monte et descend, avec une petite vague qui bouge.
## Sous 25 %, la jauge bat comme un cœur et rougit. Le dessin suit `level` en douceur.

enum Kind { FOOD, WATER }

const SIZE := 80.0

var kind: Kind = Kind.FOOD
## Le niveau voulu (0..1) et le niveau affiché, qui le rejoint doucement.
var level := 1.0
var shown := 1.0
var _t := 0.0


func _init(p_kind: Kind = Kind.FOOD) -> void:
	kind = p_kind
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	shown = lerpf(shown, level, clampf(delta * 4.0, 0.0, 1.0))
	# Le battement quand c'est presque vide.
	var low := shown < 0.25
	var beat := 1.0 + (0.08 * maxf(sin(_t * 7.0), 0.0) if low else 0.0)
	pivot_offset = size / 2
	scale = Vector2(beat, beat)
	queue_redraw()


func liquid_color() -> Color:
	return Color(0.95, 0.62, 0.22) if kind == Kind.FOOD else Color(0.3, 0.72, 0.95)


func _draw() -> void:
	var c := size / 2
	var r := minf(size.x, size.y) / 2 - 4.0
	var low := shown < 0.25
	# Le médaillon : papier, liquide, bord d'encre (rouge si c'est presque vide).
	draw_circle(c + Vector2(3, 3), r + 3.0, Color(UiTheme.INK, 0.4))
	draw_circle(c, r + 3.0, UiTheme.RED if low else UiTheme.INK)
	draw_circle(c, r, UiTheme.PAPER)
	var surface := c.y + r - 2.0 * r * clampf(shown, 0.0, 1.0)
	var pts := PackedVector2Array()
	var steps := 24
	# La vague : de gauche à droite à la surface, puis le bas du cercle de droite à gauche.
	for i in steps + 1:
		var x := c.x - r + 2.0 * r * i / steps
		var wave := sin(_t * 3.0 + i * 0.7) * 2.2
		var dy := sqrt(maxf(r * r - pow(x - c.x, 2.0), 0.0))
		pts.append(Vector2(x, clampf(surface + wave, c.y - dy, c.y + dy)))
	for i in steps + 1:
		var a := PI * i / steps  # de 0 (droite) à PI (gauche), par le bas
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	if shown > 0.01 and pts.size() >= 3:
		draw_colored_polygon(pts, liquid_color())
	draw_arc(c, r, 0, TAU, 40, UiTheme.INK, 2.0, true)
	_draw_icon(c, r * 0.55)


## Le pictogramme au milieu : un pilon pour la faim, une goutte pour la soif.
func _draw_icon(c: Vector2, s: float) -> void:
	var ink := UiTheme.INK
	if kind == Kind.FOOD:
		var meat := c + Vector2(-s * 0.18, -s * 0.18)
		draw_circle(meat, s * 0.62, ink)
		draw_circle(meat, s * 0.5, Color(0.72, 0.38, 0.2))
		var a := c + Vector2(s * 0.2, s * 0.2)
		var b := c + Vector2(s * 0.75, s * 0.75)
		draw_line(a, b, ink, s * 0.36)
		draw_line(a, b, Color.WHITE, s * 0.2)
		for o in [Vector2(s * 0.15, -s * 0.08), Vector2(-s * 0.08, s * 0.15)]:
			draw_circle(b + o, s * 0.17, ink)
			draw_circle(b + o, s * 0.11, Color.WHITE)
	else:
		var drop := PackedVector2Array()
		for i in 20:
			var a := PI * 2.0 * i / 20.0
			var p := Vector2(cos(a), sin(a)) * s * 0.55 + Vector2(0, s * 0.2)
			if i == 15:
				p = Vector2(0, -s * 0.85)  # la pointe, en haut
			elif p.y < s * 0.05:
				p.x *= (p.y + s * 0.6) / (s * 0.65)  # le haut se resserre en pointe
			drop.append(c + p)
		var outline := drop.duplicate()
		outline.append(drop[0])
		draw_colored_polygon(drop, Color.WHITE)
		draw_polyline(outline, ink, 2.5, true)
