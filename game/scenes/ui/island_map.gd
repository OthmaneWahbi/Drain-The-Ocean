class_name IslandMap
extends CanvasLayer
## La carte de l'île (0.1.25, PRD §19.32) : M (Select à la manette) l'ouvre, M, E, Échap ou un clic
## la ferment. Dessinée à la main : papier crème, traits au feutre, vue de dessus (le nord, −Z, en
## haut). Le sol (mer, sable, terre) est peint dans une image refaite à chaque ouverture ; par-dessus,
## des pictos pour ce qui est posé, les palmiers et rochers, le joueur (une flèche) et Pinçon.
## Aucune règle ici : tout est lu dans GameState.

const PX := 160  # la résolution de l'image du sol

var _paper: Sketch


func _ready() -> void:
	layer = 12
	_paper = Sketch.new()
	_paper.set_anchors_preset(Control.PRESET_FULL_RECT)
	_paper.mouse_filter = Control.MOUSE_FILTER_STOP
	_paper.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			close())
	add_child(_paper)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed(&"map") or event.is_action_pressed(&"interact") or event.is_action_pressed(&"pause"):
			close()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"map") and can_open():
		open()
		get_viewport().set_input_as_handled()


func can_open() -> bool:
	if GameState.ui_open or GameState.placing or get_tree().paused or GameState.ending != null:
		return false
	var player := get_tree().get_first_node_in_group(&"player")
	return player != null and not bool(player.get("spying"))


func open() -> void:
	_paper.ground = ImageTexture.create_from_image(ground_image(PX))
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	_paper.player_pos = player.global_position if player else GameState.player_position
	_paper.player_dir = -player.global_basis.z if player else Vector3.FORWARD
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


## Le sol vu de dessus, `px` × `px` pixels : la mer en bleu pâle, le sable, la terre, l'herbe ; les
## bords (côte, terre retournée) repassés au feutre.
static func ground_image(px: int) -> Image:
	var gs := GameState
	var r := gs.config.map_radius_m
	var sea := gs.water_level_y()
	var kinds := PackedByteArray()
	kinds.resize(px * px)
	for j in px:
		for i in px:
			var p := pixel_to_world(Vector2(i + 0.5, j + 0.5), px, r)
			var k := 0
			if gs.terrain.height(p.x, p.y) > sea:
				k = 1
				if gs.terrain.is_grass(p.x, p.y):
					k = 3
				elif gs.terrain.soil(TerrainLogic.nearest_vertex(p.x, p.y)) == TerrainLogic.Soil.EARTH:
					k = 2
			kinds[j * px + i] = k
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var colors := [Sketch.SEA, Sketch.SAND, Sketch.EARTH, Sketch.GRASS]
	for j in px:
		for i in px:
			var k := kinds[j * px + i]
			var c: Color = colors[k]
			# Le feutre : un trait sur la côte (la mer touche la terre).
			var edge := false
			for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var ni: int = i + d.x
				var nj: int = j + d.y
				if ni >= 0 and nj >= 0 and ni < px and nj < px and (kinds[nj * px + ni] == 0) != (k == 0):
					edge = true
			if edge:
				c = Sketch.INK
			elif k == 0 and (i + j * 3) % 11 == 0:
				c = c.darkened(0.12)  # quelques hachures dans la mer
			img.set_pixel(i, j, c)
	return img


## Le point du monde (x, z) sous le pixel `p` d'une image de `px` pixels qui couvre ±`radius` m.
static func pixel_to_world(p: Vector2, px: int, radius: float) -> Vector2:
	return (p / px * 2.0 - Vector2.ONE) * radius


## Le point de la carte (0..1, 0..1) d'un point du monde ; le nord (−Z) en haut.
static func world_to_map(pos: Vector3, radius: float) -> Vector2:
	return Vector2(pos.x, pos.z) / (radius * 2.0) + Vector2(0.5, 0.5)


class Sketch extends Control:
	const PAPER := Color(0.98, 0.94, 0.82)
	const INK := Color(0.25, 0.18, 0.12)
	const SEA := Color(0.72, 0.84, 0.88)
	const SAND := Color(0.96, 0.87, 0.62)
	const EARTH := Color(0.78, 0.62, 0.42)
	const GRASS := Color(0.68, 0.8, 0.5)
	const RED := Color(0.82, 0.2, 0.15)

	var ground: Texture2D
	var player_pos := Vector3.ZERO
	var player_dir := Vector3.FORWARD
	var _rect := Rect2()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
		var side := minf(size.x * 0.8, size.y * 0.84)
		var sheet := Rect2((size - Vector2(side, side)) / 2.0 - Vector2(0, 12), Vector2(side, side))
		draw_rect(sheet.grow(14.0), PAPER)
		draw_rect(sheet.grow(14.0), INK.lightened(0.3), false, 4.0)
		_rect = sheet
		if ground:
			draw_texture_rect(ground, sheet, false, Color(1, 1, 1, 0.95))
		var gs := GameState
		var u := side / 60.0
		# Les palmiers et les rochers de l'île.
		for p in gs.config.rocks:
			draw_circle(_at(Vector3(p.x, 0, p.y)), maxf(p.z * side / (gs.config.map_radius_m * 2.0), u * 0.4), Color(0.6, 0.58, 0.55))
		var palms: Array = []
		for p in gs.config.palms:
			palms.append(Vector3(p.x, 0, p.y))
		for p in gs.config.outer_palms:
			if gs.terrain.height(p.x, p.y) > gs.water_level_y():
				palms.append(Vector3(p.x, 0, p.y))
		for pl in gs.planted:
			palms.append(pl.position)
		for p in palms:
			_palm(_at(p), u)
		# Ce qui est posé : les zones (leur emprise, l'eau dedans), puis les pictos.
		for z in gs.zones:
			_rect_outline(gs.item_rect(z), Color(0.4, 0.65, 0.9, 0.85))
		for st in gs.stations:
			_square(_at(st.position), u * 0.8, Color(0.95, 0.7, 0.3))
		for m in gs.mirrors:
			_square(_at(m.position), u * 0.7, Color(0.85, 0.9, 0.95))
		for pu in gs.pumps:
			_windmill(_at(pu.position), u)
		for sl in gs.slides:
			_square(_at(sl.position), u * 0.8, Color(0.7, 0.5, 0.3))
		for d in gs.decor:
			draw_circle(_at(d.position), u * 0.35, INK.lightened(0.25))
		for c in gs.crates:
			_square(_at(c.position), u * 0.7, Props.WOOD)
		for w in gs.wrecks:
			if w.landed:
				_square(_at(w.position), u * 0.6, Props.WOOD_DARK)
		for c in gs.castles:
			var q := _at(c.position)
			draw_colored_polygon(PackedVector2Array([q + Vector2(-u * 0.4, u * 0.3), q + Vector2(u * 0.4, u * 0.3), q + Vector2(0, -u * 0.5)]), SAND.darkened(0.25))
		_square(_at(gs.depot.position), u * 1.2, Color(0.75, 0.55, 0.35))
		_square(_at(Vector3(5, 0, 1.5)), u * 0.8, RED)  # la cabine du téléphone
		var tr_rect := gs.trophy_stand_rect()
		_square(_at(Vector3(tr_rect.get_center().x, 0, tr_rect.get_center().y)), u * 0.7, LaterGoods.GOLD)
		# Pinçon (un rond rouge) et le joueur (une flèche).
		if gs.pet_position.is_finite() and absf(gs.pet_position.x) < 1000.0:
			draw_circle(_at(gs.pet_position), u * 0.55, Color(0.92, 0.35, 0.2))
			draw_arc(_at(gs.pet_position), u * 0.55, 0, TAU, 12, INK, 2.0, true)
		var pp := _at(player_pos)
		var f := Vector2(player_dir.x, player_dir.z).normalized()
		if f == Vector2.ZERO:
			f = Vector2(0, -1)
		var side_v := Vector2(-f.y, f.x)
		var arrow := PackedVector2Array([pp + f * u * 1.4, pp - f * u * 0.8 + side_v * u * 0.8, pp - f * u * 0.3, pp - f * u * 0.8 - side_v * u * 0.8])
		draw_colored_polygon(arrow, RED)
		arrow.append(arrow[0])
		draw_polyline(arrow, INK, 2.0, true)
		# La rose des vents et l'aide pour fermer.
		var n := sheet.position + Vector2(side - u * 3.0, u * 3.5)
		draw_line(n + Vector2(0, u * 1.6), n - Vector2(0, u * 1.6), INK, 3.0)
		draw_colored_polygon(PackedVector2Array([n - Vector2(0, u * 2.0), n + Vector2(-u * 0.6, -u * 0.6), n + Vector2(u * 0.6, -u * 0.6)]), INK)
		var font := ThemeDB.fallback_font
		draw_string(font, n + Vector2(-u * 0.5, u * 3.4), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, int(u * 1.6), INK)
		var hint := tr("MAP_CLOSE")
		var tw := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		draw_string(font, Vector2(sheet.get_center().x - tw / 2.0, sheet.end.y + 44.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.9))

	func _at(pos: Vector3) -> Vector2:
		return _rect.position + IslandMap.world_to_map(pos, GameState.config.map_radius_m) * _rect.size

	func _square(c: Vector2, h: float, color: Color) -> void:
		var r := Rect2(c - Vector2(h, h), Vector2(h, h) * 2.0)
		draw_rect(r, color)
		draw_rect(r, INK, false, 2.0)

	func _rect_outline(r: Rect2, fill: Color) -> void:
		var a := _at(Vector3(r.position.x, 0, r.position.y))
		var b := _at(Vector3(r.end.x, 0, r.end.y))
		var rr := Rect2(a, b - a)
		draw_rect(rr, fill)
		draw_rect(rr, INK, false, 2.0)

	func _palm(c: Vector2, u: float) -> void:
		for k in 5:
			var a := TAU * k / 5.0 - PI / 2.0
			draw_line(c, c + Vector2(cos(a), sin(a)) * u * 0.9, Color(0.25, 0.5, 0.25), 3.0, true)
		draw_circle(c, u * 0.22, Props.WOOD_DARK)

	func _windmill(c: Vector2, u: float) -> void:
		draw_circle(c, u * 0.5, Color(0.9, 0.88, 0.8))
		for k in 4:
			var a := TAU * k / 4.0 + PI / 4.0
			draw_line(c, c + Vector2(cos(a), sin(a)) * u * 1.1, INK, 2.5, true)
