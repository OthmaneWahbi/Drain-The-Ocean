class_name TerrainView
extends StaticBody3D
## Le terrain low poly de l'île (0.1.1), construit au lancement à partir de TerrainLogic :
## une grille dont les sommets sont un peu décalés au hasard (graine fixe), découpée en triangles
## qui ont chacun leurs propres sommets (facettes nettes, style low poly), colorés selon la hauteur
## et la pente. La collision est le même maillage (on marche exactement sur ce qu'on voit).
##
## 0.1.10 : la grille vient de TerrainLogic (un sommet par coin de case de 1 m) et le terrain est
## découpé en morceaux de CHUNK cases. Quand on travaille le sable à la pelle, seuls les morceaux
## touchés sont reconstruits (maillage et collision).

## Taille d'un morceau, en cases.
const CHUNK := 16

var logic: TerrainLogic
## Vector2i (morceau) -> [MeshInstance3D, CollisionShape3D]
var _chunks: Dictionary = {}
var _material: StandardMaterial3D


func _ready() -> void:
	logic = GameState.terrain
	_material = StandardMaterial3D.new()
	_material.vertex_color_use_as_albedo = true
	_material.vertex_color_is_srgb = true  # couleurs choisies à l'œil (sRGB)
	_material.roughness = 1.0
	_material.metallic_specular = 0.15
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var n := TerrainLogic.GRID_HALF * 2 / CHUNK
	for cj in n:
		for ci in n:
			_build_chunk(Vector2i(ci, cj))
	# Pelle, nouvelle partie, chargement : GameState donne les coins changés.
	GameState.terrain_changed.connect(_on_terrain_changed)


## Le maillage complet (fonction statique : testable sans scène).
static func build_mesh(t: TerrainLogic) -> ArrayMesh:
	var h := TerrainLogic.GRID_HALF
	return build_chunk_mesh(t, -h, -h, h * 2, null)


## Le maillage des cases [i0, i0 + size[ × [j0, j0 + size[ (indices de coin bas des cases).
static func build_chunk_mesh(t: TerrainLogic, i0: int, j0: int, size: int, material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(j0, j0 + size):
		for i in range(i0, i0 + size):
			var tri := t.cell_triangles(i, j)
			var worked := t.cell_worked(Vector2i(i, j))
			_tri(st, t, tri[0], tri[1], tri[2], TerrainLogic.hash01(i, j, 5) * 2.0 - 1.0, worked, i, j)
			_tri(st, t, tri[3], tri[4], tri[5], TerrainLogic.hash01(i, j, 6) * 2.0 - 1.0, worked, i, j)
	if material == null:
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.vertex_color_is_srgb = true
		mat.roughness = 1.0
		mat.metallic_specular = 0.15
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		material = mat
	st.set_material(material)
	return st.commit()


static func _tri(st: SurfaceTool, t: TerrainLogic, a: Vector3, b: Vector3, c: Vector3, jitter: float, worked: bool, i: int, j: int) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.y > 0.0:
		# Toutes les facettes dans le même sens (sens horaire vu d'en haut, la face avant pour Godot).
		var tmp := b
		b = c
		c = tmp
	normal = (c - a).cross(b - a).normalized()
	var y := (a.y + b.y + c.y) / 3.0
	var col := t.color(y, 1.0 - normal.y, jitter)
	if worked and y > t.ground_y - 1.0:
		# Le sable travaillé : un ton plus clair (ratissé), en damier très léger pour lire les cases.
		var k := 1.06 if posmod(i + j, 2) == 0 else 1.0
		col = Color(0.7 * k, 0.6 * k, 0.4 * k) if 1.0 - normal.y < 0.05 else col.lightened(0.04)
	for v in [a, b, c]:
		st.set_color(col)
		st.set_normal(normal)
		st.add_vertex(v)


func _chunk_origin(chunk: Vector2i) -> Vector2i:
	return Vector2i(-TerrainLogic.GRID_HALF + chunk.x * CHUNK, -TerrainLogic.GRID_HALF + chunk.y * CHUNK)


func _build_chunk(chunk: Vector2i) -> void:
	var o := _chunk_origin(chunk)
	var mesh := build_chunk_mesh(logic, o.x, o.y, CHUNK, _material)
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
	var concave := mesh.create_trimesh_shape()
	concave.backface_collision = true  # on ne passe jamais à travers, quel que soit le sens d'une facette
	(parts[1] as CollisionShape3D).shape = concave


## Les morceaux qui contiennent une case touchant un de ces coins.
func _chunks_of_corners(corners: Array) -> Dictionary:
	var out := {}
	var n := TerrainLogic.GRID_HALF * 2 / CHUNK
	for c: Vector2i in corners:
		for d in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
			var cell: Vector2i = c + d
			var ch := Vector2i(floori(float(cell.x + TerrainLogic.GRID_HALF) / CHUNK), floori(float(cell.y + TerrainLogic.GRID_HALF) / CHUNK))
			if ch.x >= 0 and ch.y >= 0 and ch.x < n and ch.y < n:
				out[ch] = true
	return out


func _on_terrain_changed(corners: Array) -> void:
	for ch in _chunks_of_corners(corners):
		_build_chunk(ch)


## La hauteur du sol ici (pour les vues qui posent des choses).
func height_at(x: float, z: float) -> float:
	return logic.height(x, z)
