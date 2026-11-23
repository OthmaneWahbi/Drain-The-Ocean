class_name WeatherIcon
extends Control
## Le temps du jour en pictogramme (0.1.22, PRD §19.29), à côté des jauges de faim et de soif :
## soleil, soleil brûlant, vent, nuage, nuage qui pleut. Aucun texte (une info-bulle donne le nom).

const SIZE := 64.0
const PAPER := Color(1.0, 0.96, 0.86)
const INK := Color(0.16, 0.12, 0.1)
const SUN := Color(1.0, 0.8, 0.22)
const HOT := Color(1.0, 0.45, 0.15)
const CLOUD := Color(0.78, 0.8, 0.84)
const RAIN := Color(0.3, 0.55, 0.95)
const WIND := Color(0.35, 0.62, 0.8)

var weather := "calme"
var _t := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func set_weather(id: String) -> void:
	weather = id
	tooltip_text = TranslationServer.translate("WEATHER_" + id.to_upper())


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 2.0
	draw_circle(c, r, PAPER)
	draw_arc(c, r, 0, TAU, 32, INK, 3.0, true)
	match weather:
		"calme":
			_sun(c, r * 0.32, SUN, _t * 0.4)
		"canicule":
			_sun(c, r * 0.36, HOT, _t * 1.2, 1.0 + 0.1 * sin(_t * 5.0))
		"venteux":
			for i in 3:
				var y := c.y - r * 0.35 + i * r * 0.35
				var x0 := c.x - r * 0.55 + sin(_t * 3.0 + i) * 3.0
				var pts := PackedVector2Array()
				for k in 9:
					var x := x0 + k * r * 0.13
					pts.append(Vector2(x, y + sin(k * 0.8 + _t * 4.0 + i) * 2.0))
				draw_polyline(pts, WIND, 4.0, true)
		"couvert":
			_cloud(c + Vector2(0, 2), r * 0.5, CLOUD)
		"averse":
			_cloud(c - Vector2(0, r * 0.18), r * 0.45, CLOUD.darkened(0.15))
			for i in 4:
				var x := c.x - r * 0.36 + i * r * 0.24
				var y := c.y + r * 0.15 + fmod(_t * 30.0 + i * 7.0, r * 0.35)
				draw_line(Vector2(x, y), Vector2(x - 3, y + 8), RAIN, 3.0, true)
		"orage":  # 0.1.25 : un nuage noir et un éclair qui clignote
			_cloud(c - Vector2(0, r * 0.2), r * 0.45, CLOUD.darkened(0.45))
			if fmod(_t, 1.6) < 1.1:
				var bolt := PackedVector2Array([c + Vector2(r * 0.05, -r * 0.05), c + Vector2(-r * 0.15, r * 0.3), c + Vector2(r * 0.02, r * 0.28), c + Vector2(-r * 0.12, r * 0.62)])
				draw_polyline(bolt, SUN, 4.0, true)


func _sun(c: Vector2, radius: float, color: Color, spin: float, pulse := 1.0) -> void:
	for i in 8:
		var a := spin + TAU * i / 8.0
		var d := Vector2(cos(a), sin(a))
		draw_line(c + d * radius * 1.3, c + d * radius * 1.8 * pulse, color, 4.0, true)
	draw_circle(c, radius, color)
	draw_arc(c, radius, 0, TAU, 24, INK, 2.0, true)


func _cloud(c: Vector2, w: float, color: Color) -> void:
	for p in [Vector2(-0.45, 0.15), Vector2(0.0, -0.1), Vector2(0.45, 0.15), Vector2(0.0, 0.2)]:
		draw_circle(c + p * w, w * 0.45, color)
