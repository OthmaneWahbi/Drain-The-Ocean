class_name TerrainView
extends StaticBody3D
## Le terrain low poly de l'île (0.1.1), construit au lancement à partir de TerrainLogic :
## une grille dont les sommets sont un peu décalés au hasard (graine fixe), découpée en triangles
## qui ont chacun leurs propres sommets (facettes nettes, style low poly), colorés selon la hauteur
## et la pente. La collision est le même maillage (on marche exactement sur ce qu'on voit).
##
## 0.1.10 : la grille vient de TerrainLogic et le terrain est découpé en morceaux de CHUNK cases.
## Quand on travaille le sable à la pelle, seuls les morceaux touchés sont reconstruits.
##
## 0.1.11 : la grille est deux fois plus fine (sommets tous les 50 cm) et le sable a son propre
## matériau (SAND_SHADER : grains, rides, lumière cartoon). Un coup de pelle est **animé** : la
## case travaillée (et la couronne de petites cases autour) est retirée de son morceau et dessinée
## à part, dans un petit maillage dont les sommets glissent de leur ancienne hauteur à la nouvelle
## (le sable descend quand on creuse, monte quand on remblaie). À la fin, le morceau est refait
## en entier. La collision, elle, prend tout de suite la forme finale.

## Taille d'un morceau, en petites cases du maillage (0.1.11 : 32 cases de 50 cm, 16 m).
const CHUNK := 32
const SAND_SHADER := preload("res://scenes/world/sand.gdshader")

var logic: TerrainLogic
## Vector2i (morceau) -> [MeshInstance3D, CollisionShape3D]
var _chunks: Dictionary = {}
var _material: Material
## Les coups de pelle en cours d'animation : {cell, rect (petites cases), before, to, t, delay, mesh}.
var _anims: Array[Dictionary] = []


func _ready() -> void:
	logic = GameState.terrain
	_material = make_material()
	var n := TerrainLogic.GRID_HALF * 2 / CHUNK
	for cj in n:
		for ci in n:
			_build_chunk(Vector2i(ci, cj))
	# Pelle, nouvelle partie, chargement : GameState donne les sommets changés.
	GameState.terrain_changed.connect(_on_terrain_changed)
	GameState.sand_moved.connect(_on_sand_moved)
	GameState.game_reset.connect(_finish_all)


## Le matériau du sable (statique : les tests et les captures s'en servent aussi).
static func make_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SAND_SHADER
	return mat


## Le maillage complet (fonction statique : testable sans scène).
static func build_mesh(t: TerrainLogic) -> ArrayMesh:
	var h := TerrainLogic.GRID_HALF
	return build_chunk_mesh(t, -h, -h, h * 2, null)


## Le maillage des petites cases [i0, i0 + size[ × [j0, j0 + size[ (indices de sommet du coin bas).
## `skip` : des rectangles de petites cases à ne pas dessiner (animés à part).
## `heights` : des hauteurs à la place de celles de la logique, pour des sommets travaillés.
static func build_chunk_mesh(t: TerrainLogic, i0: int, j0: int, size: int, material: Material, skip: Array = [], heights: Dictionary = {}) -> ArrayMesh:
	return build_rect_mesh(t, Rect2i(i0, j0, size, size), material, skip, heights)


static func build_rect_mesh(t: TerrainLogic, rect: Rect2i, material: Material, skip: Array = [], heights: Dictionary = {}) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(rect.position.y, rect.end.y):
		for i in range(rect.position.x, rect.end.x):
			var hidden := false
			for r: Rect2i in skip:
				if r.has_point(Vector2i(i, j)):
					hidden = true
					break
			if hidden:
				continue
			var tri := t.cell_triangles(i, j)
			var ids := TerrainLogic.cell_triangle_ids(i, j)
			# Près du sable travaillé, des facettes nettes : les normales lissées y dessineraient
			# des dents de scie sur les pentes d'une case creusée ou remontée.
			var near_work := t.edits.has(Vector2i(i, j)) or t.edits.has(Vector2i(i + 1, j)) \
				or t.edits.has(Vector2i(i, j + 1)) or t.edits.has(Vector2i(i + 1, j + 1))
			var normals: Array[Vector3] = []
			if not near_work:
				for k in 6:
					normals.append(t.vertex_normal(ids[k].x, ids[k].y))
			if not heights.is_empty():
				for k in 6:
					tri[k] = _with_height(tri[k], heights)
			# Sable travaillé : les 4 coins de la petite case (pas les pentes autour d'une case creusée).
			var worked := t.edits.has(Vector2i(i, j)) and t.edits.has(Vector2i(i + 1, j)) \
				and t.edits.has(Vector2i(i, j + 1)) and t.edits.has(Vector2i(i + 1, j + 1))
			_tri(st, t, tri, ids, normals, 0, TerrainLogic.hash01(i, j, 5) * 2.0 - 1.0, worked)
			_tri(st, t, tri, ids, normals, 3, TerrainLogic.hash01(i, j, 6) * 2.0 - 1.0, worked)
	st.set_material(material if material else make_material())
	return st.commit()


## Un sommet travaillé est exactement sur la grille : on retrouve son indice pour lui donner la
## hauteur animée.
static func _with_height(v: Vector3, heights: Dictionary) -> Vector3:
	var step := TerrainLogic.VERTEX_STEP
	var key := Vector2i(roundi(v.x / step), roundi(v.z / step))
	if heights.has(key) and absf(v.x - key.x * step) < 1e-4 and absf(v.z - key.y * step) < 1e-4:
		v.y = heights[key]
	return v


## Un triangle (les sommets k, k+1, k+2 de `tri`) : la couleur de sa catégorie (sable sec,
## mouillé, herbe… selon sa hauteur et sa pente), nuancée un peu à chaque sommet (en douceur d'une
## facette à l'autre), et les normales lissées de ses sommets (le matériau garde une part de
## facette, voir sand.gdshader) ; `normals` vide : la normale de la facette (sable travaillé).
static func _tri(st: SurfaceTool, t: TerrainLogic, tri: Array, ids: Array[Vector2i], normals: Array[Vector3], k: int, jitter: float, worked: bool) -> void:
	var order := [k, k + 1, k + 2]
	var a: Vector3 = tri[k]
	var b: Vector3 = tri[k + 1]
	var c: Vector3 = tri[k + 2]
	if (b - a).cross(c - a).y > 0.0:
		# Toutes les facettes dans le même sens (sens horaire vu d'en haut, la face avant pour Godot).
		order = [k, k + 2, k + 1]
		var tmp := b
		b = c
		c = tmp
	var normal := (c - a).cross(b - a).normalized()
	if normal.y < 0.0:
		normal = -normal
	var y := (a.y + b.y + c.y) / 3.0
	var col := t.color(y, 1.0 - normal.y, jitter, 0.0, false)
	# Le canal alpha dit au matériau si le sable a été travaillé (1) ou non (0) : il y dessine
	# des traces de pelle au lieu des rides du vent.
	col.a = 1.0 if worked and y > t.ground_y - 1.0 else 0.0
	for idx: int in order:
		var id := ids[idx]
		var shade := 1.0 + (TerrainLogic.hash01(id.x, id.y, 5) * 2.0 - 1.0) * 0.05
		st.set_color(Color(col.r * shade, col.g * shade, col.b * shade, col.a))
		st.set_normal(normals[idx] if not normals.is_empty() else normal)
		st.add_vertex(tri[idx])


func _chunk_origin(chunk: Vector2i) -> Vector2i:
	return Vector2i(-TerrainLogic.GRID_HALF + chunk.x * CHUNK, -TerrainLogic.GRID_HALF + chunk.y * CHUNK)


func _chunk_rect(chunk: Vector2i) -> Rect2i:
	return Rect2i(_chunk_origin(chunk), Vector2i(CHUNK, CHUNK))


func _build_chunk(chunk: Vector2i, with_collision: bool = true) -> void:
	var rect := _chunk_rect(chunk)
	var skip := []
	for a in _anims:
		if rect.intersects(a.rect):
			skip.append(a.rect)
	var mesh := build_rect_mesh(logic, rect, _material, skip)
	var parts: Array = _chunks.get(chunk, [])
	if parts.is_empty():
		var mi := MeshInstance3D.new()
		mi.name = "Chunk_%d_%d" % [chunk.x, chunk.y]
		add_child(mi)
		var shape := CollisionShape3D.new()
		add_child(shape)
		parts = [mi, shape]
		_chunks[chunk] = parts
	(parts[0] as MeshInstance3D).mesh = mesh
	if not with_collision:
		return
	# La collision suit la forme finale, sans les trous des animations.
	var full := mesh if skip.is_empty() else build_rect_mesh(logic, rect, _material)
	var concave := full.create_trimesh_shape()
	concave.backface_collision = true  # on ne passe jamais à travers, quel que soit le sens d'une facette
	(parts[1] as CollisionShape3D).shape = concave


## Les morceaux qui contiennent une petite case touchant un de ces sommets.
func _chunks_of_corners(corners: Array) -> Dictionary:
	var out := {}
	for c: Vector2i in corners:
		for d in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
			var ch := _chunk_of_small_cell(c + d)
			if ch.x >= 0:
				out[ch] = true
	return out


func _chunks_of_rect(rect: Rect2i) -> Dictionary:
	var out := {}
	for p in [rect.position, Vector2i(rect.end.x - 1, rect.position.y), Vector2i(rect.position.x, rect.end.y - 1), rect.end - Vector2i.ONE]:
		var ch := _chunk_of_small_cell(p)
		if ch.x >= 0:
			out[ch] = true
	return out


func _chunk_of_small_cell(cell: Vector2i) -> Vector2i:
	var n := TerrainLogic.GRID_HALF * 2 / CHUNK
	var ch := Vector2i(floori(float(cell.x + TerrainLogic.GRID_HALF) / CHUNK), floori(float(cell.y + TerrainLogic.GRID_HALF) / CHUNK))
	if ch.x < 0 or ch.y < 0 or ch.x >= n or ch.y >= n:
		return Vector2i(-1, -1)
	return ch


func _on_terrain_changed(corners: Array) -> void:
	for ch in _chunks_of_corners(corners):
		_build_chunk(ch)


# --- L'animation d'un coup de pelle (0.1.11) ---------------------------------------------------

## Les petites cases redessinées pendant l'animation : la case de 1 m et une couronne autour
## (les pentes qui la bordent bougent avec elle).
static func anim_rect(cell: Vector2i) -> Rect2i:
	var sub := TerrainLogic.SUB
	return Rect2i(cell * sub - Vector2i.ONE, Vector2i(sub + 2, sub + 2))


func _on_sand_moved(cell: Vector2i, before: Dictionary, to_y: float, scoops: int) -> void:
	var rect := anim_rect(cell)
	# Un coup sur une case déjà en mouvement (ou à côté) : on termine d'abord l'ancien.
	for a in _anims.duplicate():
		if a.rect.intersects(rect):
			_finish(a)
	var mi := MeshInstance3D.new()
	mi.name = "SandAnim"
	add_child(mi)
	# On remblaie : le sable monte quand la pelletée arrive (le temps qu'elle vole).
	var delay := 0.16 if scoops < 0 else 0.0
	var a := {"cell": cell, "rect": rect, "before": before, "to": to_y, "t": 0.0, "delay": delay, "mesh": mi}
	_anims.append(a)
	_draw_anim(a)
	# terrain_changed suit : les morceaux seront refaits avec le trou de l'animation.


func _process(delta: float) -> void:
	if _anims.is_empty():
		return
	var duration := maxf(GameState.config.dig_anim_s, 0.01)
	for a in _anims.duplicate():
		if a.delay > 0.0:
			a.delay -= delta
			continue
		a.t += delta / duration
		if a.t >= 1.0:
			_finish(a)
		else:
			_draw_anim(a)


## Les hauteurs animées : de l'ancienne à la nouvelle, avec un petit rebond à la fin.
static func anim_heights(before: Dictionary, to_y: float, t: float) -> Dictionary:
	var k := ease_out_back(clampf(t, 0.0, 1.0))
	var out := {}
	for v: Vector2i in before:
		out[v] = lerpf(float(before[v]), to_y, k)
	return out


static func ease_out_back(t: float) -> float:
	var c := 1.4
	return 1.0 + (c + 1.0) * pow(t - 1.0, 3.0) + c * pow(t - 1.0, 2.0)


func _draw_anim(a: Dictionary) -> void:
	var heights := anim_heights(a.before, a.to, a.t)
	(a.mesh as MeshInstance3D).mesh = build_rect_mesh(logic, a.rect, _material, [], heights)


func _finish(a: Dictionary) -> void:
	_anims.erase(a)
	(a.mesh as MeshInstance3D).queue_free()
	for ch in _chunks_of_rect(a.rect):
		_build_chunk(ch, false)  # la collision est déjà à jour


func _finish_all() -> void:
	for a in _anims.duplicate():
		_finish(a)


## Vrai pendant qu'un coup de pelle s'anime (pour les tests).
func is_animating() -> bool:
	return not _anims.is_empty()


## La hauteur du sol ici (pour les vues qui posent des choses).
func height_at(x: float, z: float) -> float:
	return logic.height(x, z)
