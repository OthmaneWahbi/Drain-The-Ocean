class_name TerrainView
extends StaticBody3D
## Le terrain low poly de l'île (0.1.1), construit au lancement à partir de TerrainLogic :
## une grille dont les sommets sont un peu décalés au hasard (graine fixe), découpée en triangles
## qui ont chacun leurs propres sommets (facettes nettes, style low poly), colorés selon la hauteur
## et la pente. La collision est le même maillage (on marche exactement sur ce qu'on voit).

## Demi-largeur du terrain (m) et taille d'une case (m).
const HALF := 72.0
const CELL := 1.25

var logic: TerrainLogic
var mesh_instance: MeshInstance3D


func _ready() -> void:
	logic = GameState.terrain
	var mesh := build_mesh(logic)
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	var shape := CollisionShape3D.new()
	var concave := mesh.create_trimesh_shape()
	concave.backface_collision = true  # on ne passe jamais à travers, quel que soit le sens d'une facette
	shape.shape = concave
	add_child(shape)


## Le maillage complet (fonction statique : testable sans scène).
static func build_mesh(t: TerrainLogic) -> ArrayMesh:
	var n := int(HALF * 2.0 / CELL)
	var pts := PackedVector3Array()
	pts.resize((n + 1) * (n + 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for j in n + 1:
		for i in n + 1:
			var x := -HALF + i * CELL
			var z := -HALF + j * CELL
			# Décalage des sommets intérieurs : des triangles irréguliers, pas une grille.
			if i > 0 and i < n and j > 0 and j < n:
				x += rng.randf_range(-0.35, 0.35) * CELL
				z += rng.randf_range(-0.35, 0.35) * CELL
			pts[j * (n + 1) + i] = Vector3(x, t.height(x, z), z)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in n:
		for i in n:
			var a := pts[j * (n + 1) + i]
			var b := pts[j * (n + 1) + i + 1]
			var c := pts[(j + 1) * (n + 1) + i]
			var d := pts[(j + 1) * (n + 1) + i + 1]
			# On alterne la diagonale : moins de lignes droites visibles.
			if (i + j) % 2 == 0:
				_tri(st, t, a, c, b, rng)
				_tri(st, t, b, c, d, rng)
			else:
				_tri(st, t, a, c, d, rng)
				_tri(st, t, a, d, b, rng)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true  # couleurs choisies à l'œil (sRGB)
	mat.roughness = 1.0
	mat.metallic_specular = 0.15
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(mat)
	return st.commit()


static func _tri(st: SurfaceTool, t: TerrainLogic, a: Vector3, b: Vector3, c: Vector3, rng: RandomNumberGenerator) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.y > 0.0:
		# Toutes les facettes dans le même sens (sens horaire vu d'en haut, la face avant pour Godot).
		var tmp := b
		b = c
		c = tmp
	normal = (c - a).cross(b - a).normalized()
	var y := (a.y + b.y + c.y) / 3.0
	var col := t.color(y, 1.0 - normal.y, rng.randf_range(-1.0, 1.0))
	st.set_color(col)
	st.set_normal(normal)
	st.add_vertex(a)
	st.set_color(col)
	st.set_normal(normal)
	st.add_vertex(b)
	st.set_color(col)
	st.set_normal(normal)
	st.add_vertex(c)
