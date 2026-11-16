class_name MilestoneIcon
extends Control
## Le pictogramme d'un jalon, dessiné à la main (pas d'image, pas de texte, PRD §8) :
## baignoire, piscine gonflable, piscine, piscine olympique. `fill` (0-1) remplit l'eau.

var icon: String = "baignoire":
	set(v):
		icon = v
		queue_redraw()
var fill: float = 1.0:
	set(v):
		fill = clampf(v, 0.0, 1.0)
		queue_redraw()

const LINE := Color(1, 1, 1)
const WATER := Color(0.3, 0.7, 0.95)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var lw := maxf(2.0, w / 24.0)
	match icon:
		"baignoire":
			# Une baignoire sur pieds avec un robinet.
			var body := Rect2(w * 0.1, h * 0.4, w * 0.8, h * 0.35)
			_water(body)
			draw_rect(body, LINE, false, lw)
			draw_line(Vector2(w * 0.2, h * 0.75), Vector2(w * 0.17, h * 0.88), LINE, lw)
			draw_line(Vector2(w * 0.8, h * 0.75), Vector2(w * 0.83, h * 0.88), LINE, lw)
			draw_line(Vector2(w * 0.82, h * 0.4), Vector2(w * 0.82, h * 0.2), LINE, lw)
			draw_line(Vector2(w * 0.82, h * 0.2), Vector2(w * 0.7, h * 0.2), LINE, lw)
		"piscine_gonflable":
			# Un rond gonflé vu de côté : deux boudins empilés.
			var body := Rect2(w * 0.1, h * 0.35, w * 0.8, h * 0.45)
			_water(body)
			draw_rect(body, LINE, false, lw)
			draw_line(Vector2(w * 0.1, h * 0.57), Vector2(w * 0.9, h * 0.57), LINE, lw * 0.6)
			draw_circle(Vector2(w * 0.1, h * 0.46), h * 0.11, LINE, false, lw)
			draw_circle(Vector2(w * 0.9, h * 0.46), h * 0.11, LINE, false, lw)
			draw_circle(Vector2(w * 0.1, h * 0.69), h * 0.11, LINE, false, lw)
			draw_circle(Vector2(w * 0.9, h * 0.69), h * 0.11, LINE, false, lw)
		"piscine":
			# Un bassin rectangulaire avec une échelle.
			var body := Rect2(w * 0.08, h * 0.45, w * 0.84, h * 0.35)
			_water(body)
			draw_rect(body, LINE, false, lw)
			for x in [0.68, 0.8]:
				draw_line(Vector2(w * x, h * 0.25), Vector2(w * x, h * 0.6), LINE, lw)
			for y in [0.33, 0.45, 0.57]:
				draw_line(Vector2(w * 0.68, h * y), Vector2(w * 0.8, h * y), LINE, lw * 0.7)
		_:
			# Piscine olympique : un long bassin avec des lignes d'eau.
			var body := Rect2(w * 0.04, h * 0.35, w * 0.92, h * 0.45)
			_water(body)
			draw_rect(body, LINE, false, lw)
			for y in [0.5, 0.65]:
				draw_dashed_line(Vector2(w * 0.06, h * y), Vector2(w * 0.94, h * y), LINE, lw * 0.6, w * 0.06)


func _water(body: Rect2) -> void:
	var hgt := body.size.y * fill
	draw_rect(Rect2(body.position.x, body.end.y - hgt, body.size.x, hgt), WATER)
