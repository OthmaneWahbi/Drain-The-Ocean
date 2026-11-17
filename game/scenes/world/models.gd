class_name Models
extends RefCounted
## Les modèles du jeu (versions 0.1.X). D'abord des modèles CC0 téléchargés (`assets/models/cc0`,
## voir `assets/CREDITS.md`), retouchés au chargement : couleurs cartoon, faces visibles des deux
## côtés, posés au sol à la bonne taille. Quand rien de gratuit ne convenait (noix de coco,
## cabine téléphonique), le modèle est fabriqué ici, en facettes, dans le même style.

const DIR := "res://assets/models/cc0/"
## Couleurs cartoon qui remplacent celles des modèles téléchargés (nom du matériau -> couleur).
const RECOLOR := {
	"leafsGreen": Color(0.33, 0.62, 0.18),
	"leafsDark": Color(0.22, 0.48, 0.16),
	"woodBark": Color(0.52, 0.34, 0.2),
	"woodInner": Color(0.82, 0.64, 0.4),
	"dirt": Color(0.6, 0.52, 0.42),
	"stone": Color(0.62, 0.6, 0.56),
	"grass": Color(0.38, 0.6, 0.2),
	# Le rocher à cristaux (Space Kit) : roche grise de l'île au lieu de la roche de Mars.
	"rock": Color(0.56, 0.54, 0.52),
	"rockTrack": Color(0.48, 0.46, 0.45),
	"crystal": Color(0.3, 0.85, 0.8),
	# Le crabe (Quaternius) : rouge cartoon, plus clair que l'original.
	"Main": Color(0.9, 0.3, 0.18),
	"Main_Dark": Color(0.62, 0.16, 0.1),
	"White": Color(0.97, 0.95, 0.9),
	"Black": Color(0.08, 0.06, 0.1),
	"colorRed": Color(0.93, 0.3, 0.36),
}
const COCONUT := Color(0.42, 0.27, 0.14)

static var _scenes: Dictionary = {}
static var _materials: Dictionary = {}


## Une copie d'un modèle téléchargé, recolorée.
static func load_model(model_name: String) -> Node3D:
	var scene: PackedScene = _scenes.get(model_name)
	if scene == null:
		scene = load(DIR + model_name + ".glb")
		_scenes[model_name] = scene
	var node := scene.instantiate() as Node3D
	for mi: MeshInstance3D in meshes_of(node):
		for i in mi.mesh.get_surface_count():
			mi.set_surface_override_material(i, restyled(mi.mesh.surface_get_material(i)))
	return node


## Le matériau cartoon qui remplace `original` (partagé entre tous les modèles).
static func restyled(original: Material) -> StandardMaterial3D:
	var key := original.resource_name if original else ""
	# Deux packs peuvent nommer pareil des matériaux à textures différentes (« Atlas ») : la
	# texture fait partie de la clé.
	if original is BaseMaterial3D and (original as BaseMaterial3D).albedo_texture:
		key += "#%d" % (original as BaseMaterial3D).albedo_texture.get_instance_id()
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.resource_name = original.resource_name if original else ""
	var base := (original as BaseMaterial3D).albedo_color if original is BaseMaterial3D else Color.WHITE
	m.albedo_color = RECOLOR.get(key, base)
	if original is BaseMaterial3D and (original as BaseMaterial3D).albedo_texture:
		m.albedo_texture = (original as BaseMaterial3D).albedo_texture
	m.roughness = 1.0
	m.metallic_specular = 0.15
	m.cull_mode = BaseMaterial3D.CULL_DISABLED  # les feuilles des packs n'ont qu'une face
	_materials[key] = m
	return m


static func meshes_of(node: Node) -> Array:
	var out := []
	if node is MeshInstance3D:
		out.append(node)
	out.append_array(node.find_children("*", "MeshInstance3D", true, false))
	return out


## Transformation de `node` vue depuis `root` (sans passer par l'arbre de scène).
static func relative_transform(node: Node3D, root: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != root:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


## Tous les sommets de `root` (dans son repère), éventuellement d'un seul matériau.
static func vertices(root: Node3D, material_name := "") -> PackedVector3Array:
	var out := PackedVector3Array()
	for mi: MeshInstance3D in meshes_of(root):
		var t := relative_transform(mi, root)
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if material_name != "" and (mat == null or mat.resource_name != material_name):
				continue
			var arrays := mi.mesh.surface_get_arrays(i)
			var skel := mi.get_node_or_null(mi.skeleton) as Skeleton3D if mi.skin else null
			if skel and arrays[Mesh.ARRAY_BONES] != null and arrays[Mesh.ARRAY_WEIGHTS] != null:
				out.append_array(_skinned(mi, skel, arrays, relative_transform(skel, root)))
				continue
			for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				out.append(t * v)
	return out


## Les sommets d'un maillage animé (personnages, crabe) dans la pose de repos : chaque sommet
## suit ses os (poids), sinon la taille lue serait celle du maillage brut, souvent sans rapport.
static func _skinned(mi: MeshInstance3D, skel: Skeleton3D, arrays: Array, skel_t: Transform3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	var skin := mi.skin
	var mats: Array[Transform3D] = []
	for b in skin.get_bind_count():
		var bone := skin.get_bind_bone(b)
		if bone < 0:
			bone = skel.find_bone(skin.get_bind_name(b))
		mats.append(skel.get_bone_global_rest(maxi(bone, 0)) * skin.get_bind_pose(b))
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var per := bones.size() / maxi(verts.size(), 1)
	for k in verts.size():
		var p := Vector3.ZERO
		var total := 0.0
		for j in per:
			var w := weights[k * per + j]
			if w <= 0.0:
				continue
			p += (mats[bones[k * per + j]] * verts[k]) * w
			total += w
		if total > 0.0:  # un sommet sans os ne s'affiche pas tel quel : on l'ignore
			out.append(skel_t * (p / total))
	return out


static func bounds(points: PackedVector3Array) -> AABB:
	if points.is_empty():
		return AABB()
	var box := AABB(points[0], Vector3.ZERO)
	for p in points:
		box = box.expand(p)
	return box


## Met `model` à la hauteur voulue, le pied (le bas du modèle) en (0, 0, 0).
static func fit_on_ground(model: Node3D, height: float) -> void:
	var pts := vertices(model)
	var box := bounds(pts)
	var k := height / maxf(box.size.y, 0.001)
	# Le pied : le centre des sommets tout en bas (le tronc d'un palmier penché, par exemple).
	var foot := Vector3.ZERO
	var n := 0
	for p in pts:
		if p.y < box.position.y + box.size.y * 0.04:
			foot += p
			n += 1
	foot = foot / maxf(n, 1)
	model.scale *= k
	model.position = -Vector3(foot.x, box.position.y, foot.z) * k


# --- Palmiers et noix de coco ---------------------------------------------------------------

## Un palmier : le modèle CC0 du pack, avec une couronne plus fournie (une deuxième copie des
## palmes, tournée) et des noix de coco accrochées dessous. Le pied du tronc est en (0, 0, 0)
## et le palmier penche vers +X. La méta `trunk` donne le centre et le rayon du tronc par hauteur.
static func palm(height: float, rng_seed: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Palm"
	var model := load_model("tree_palm")
	root.add_child(model)
	fit_on_ground(model, height)
	# Penché vers +X : on tourne le modèle pour que le ventre du tronc courbé parte de ce côté.
	var bulge := Vector3.ZERO
	for sample: Array in trunk_profile(root):
		var c: Vector3 = sample[1]
		if Vector2(c.x, c.z).length() > Vector2(bulge.x, bulge.z).length():
			bulge = c
	model.rotation.y = -atan2(-bulge.z, bulge.x)
	model.position = model.position.rotated(Vector3.UP, model.rotation.y)
	var crown := _center(vertices(root, "leafsGreen"))
	var crown_box := bounds(vertices(root, "leafsGreen"))
	# Couronne plus fournie : les palmes une deuxième fois, tournées et un peu plus petites.
	for mi: MeshInstance3D in meshes_of(model):
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if mat == null or mat.resource_name != "leafsGreen":
				continue
			var only := ArrayMesh.new()
			only.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mi.mesh.surface_get_arrays(i))
			var extra := MeshInstance3D.new()
			extra.mesh = only
			var dark := restyled(mat).duplicate() as StandardMaterial3D
			dark.albedo_color = RECOLOR.leafsDark
			extra.material_override = dark
			var pivot := Node3D.new()
			pivot.position = Vector3(crown.x, crown_box.position.y, crown.z)
			pivot.rotation.y = deg_to_rad(36.0)
			pivot.scale = Vector3(0.85, 0.9, 0.85)
			root.add_child(pivot)
			pivot.add_child(extra)
			extra.transform = Transform3D(Basis.IDENTITY, -pivot.position) * relative_transform(mi, root)
	# Les noix de coco, en grappe sous les palmes.
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var nuts := rng.randi_range(3, 4)
	for i in nuts:
		var a := TAU * i / nuts + rng.randf_range(-0.3, 0.3)
		var nut := coconut(0.16, rng.randi())
		nut.position = Vector3(crown.x, crown_box.position.y + 0.05, crown.z) + Vector3(cos(a), 0, sin(a)) * 0.2 + Vector3(0, -rng.randf_range(0.05, 0.2), 0)
		root.add_child(nut)
	root.set_meta("trunk", trunk_profile(root))
	return root


## Le centre et le rayon du tronc tous les 25 cm : [[y, Vector3 centre, rayon], ...].
static func trunk_profile(palm_root: Node3D) -> Array:
	var pts := vertices(palm_root, "woodBark")
	var box := bounds(pts)
	var out := []
	var y := 0.0
	while y <= box.end.y:
		var c := Vector3.ZERO
		var n := 0
		for p in pts:
			if absf(p.y - y) < 0.2:
				c += p
				n += 1
		if n > 0:
			c /= n
			var r := 0.0
			for p in pts:
				if absf(p.y - y) < 0.2:
					r += Vector2(p.x - c.x, p.z - c.z).length()
			out.append([y, Vector3(c.x, y, c.z), r / n])
		y += 0.25
	return out


## Centre et rayon du tronc à la hauteur `y` (le point du profil le plus proche).
static func trunk_at(palm_root: Node3D, y: float) -> Array:
	var best: Array = [INF, Vector3(0, y, 0), 0.2]
	for s: Array in palm_root.get_meta("trunk", []):
		if absf(s[0] - y) < absf(best[0] - y):
			best = s
	return [best[1], best[2]]


static func _center(points: PackedVector3Array) -> Vector3:
	var c := Vector3.ZERO
	for p in points:
		c += p
	return c / maxf(points.size(), 1)


## Une noix de coco : une petite boule à facettes, un peu bosselée, avec ses trois « yeux ».
static func coconut(radius: float, rng_seed: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = facet_sphere(radius, 7, 5, rng_seed, Vector3(1.0, 1.08, 1.0), 0.12)
	mi.material_override = flat_material(COCONUT)
	var eyes := MeshInstance3D.new()
	var eye := SphereMesh.new()
	eye.radius = radius * 0.13
	eye.height = radius * 0.2
	eye.radial_segments = 5
	eye.rings = 2
	eye.material = flat_material(Color(0.2, 0.12, 0.06))
	for i in 3:
		var e := MeshInstance3D.new()
		e.mesh = eye
		var a := TAU * i / 3.0
		e.position = Vector3(cos(a) * radius * 0.28, radius * 1.0, sin(a) * radius * 0.28)
		mi.add_child(e)
	return mi


## Une boule à facettes (normales plates), déformée au hasard de `wobble` (part du rayon).
static func facet_sphere(radius: float, segments: int, rings: int, rng_seed: int, stretch := Vector3.ONE, wobble := 0.0) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var grid := []
	for r in rings + 1:
		var row := []
		var phi := PI * r / rings
		for s in segments:
			var theta := TAU * s / segments + (0.5 * TAU / segments if r % 2 == 1 else 0.0)
			var p := Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))
			if r > 0 and r < rings:
				p *= 1.0 + rng.randf_range(-wobble, wobble)
			row.append(p * radius * stretch)
		grid.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in rings:
		for s in segments:
			var a: Vector3 = grid[r][s]
			var b: Vector3 = grid[r][(s + 1) % segments]
			var c: Vector3 = grid[r + 1][s]
			var d: Vector3 = grid[r + 1][(s + 1) % segments]
			_tri(st, a, b, c)
			_tri(st, b, d, c)
	return st.commit()


## Un triangle à facette plate, tourné vers l'extérieur (le centre de l'objet est l'origine).
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-12:
		return
	if n.dot(a + b + c) < 0.0:
		var t := b
		b = c
		c = t
		n = -n
	st.set_normal(n.normalized())
	# Godot voit de face les triangles dans le sens des aiguilles d'une montre : a, c, b.
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(b)


static func flat_material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	m.metallic_specular = 0.15
	return m


## Un rocher du pack, posé au sol et mis à la taille `size` (largeur, hauteur, profondeur).
static func rock(model_name: String, size: Vector3) -> Node3D:
	var root := Node3D.new()
	var model := load_model(model_name)
	root.add_child(model)
	var box := bounds(vertices(model))
	model.scale = Vector3(size.x / maxf(box.size.x, 0.01), size.y / maxf(box.size.y, 0.01), size.z / maxf(box.size.z, 0.01))
	model.position = -Vector3(box.get_center().x * model.scale.x, box.position.y * model.scale.y, box.get_center().z * model.scale.z)
	return root


## Une forme de collision convexe par maillage de `root` (pour les rochers).
static func convex_collisions(root: Node3D) -> Array[CollisionShape3D]:
	var out: Array[CollisionShape3D] = []
	for mi: MeshInstance3D in meshes_of(root):
		var col := CollisionShape3D.new()
		col.shape = mi.mesh.create_convex_shape(true, true)
		col.transform = relative_transform(mi, root)
		out.append(col)
	return out


# --- La cabine téléphonique ------------------------------------------------------------------

const BOOTH_RED := Color(0.86, 0.2, 0.15)
const BOOTH_DARK := Color(0.55, 0.1, 0.08)
const BOOTH_CREAM := Color(1.0, 0.94, 0.8)
const BOOTH_GLASS := Color(0.7, 0.92, 1.0, 0.35)

## La cabine de l'Agence : un poteau rouge à chaque coin, des vitres sur trois côtés, le côté
## ouvert vers +Z. Dedans : le téléphone mural et, sur sa tablette, le catalogue enchaîné
## (nœud « Catalogue », caché tant qu'il n'est pas livré). Le pied est en (0, 0, 0).
## Le nœud « Shake » regroupe ce qui tremble quand ça sonne.
static func phone_booth() -> Node3D:
	var root := Node3D.new()
	root.name = "Booth"
	var shake := Node3D.new()
	shake.name = "Shake"
	root.add_child(shake)
	var w := 1.15
	var h := 2.45
	shake.add_child(Greybox.box(Vector3(w + 0.14, 0.12, w + 0.14), BOOTH_DARK, Vector3(0, 0.06, 0)))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			shake.add_child(Greybox.box(Vector3(0.13, h, 0.13), BOOTH_RED, Vector3(sx * w / 2, 0.12 + h / 2, sz * w / 2)))
	# Le toit : une dalle, puis une petite pyramide à quatre pans.
	shake.add_child(Greybox.box(Vector3(w + 0.22, 0.14, w + 0.22), BOOTH_RED, Vector3(0, h + 0.19, 0)))
	var roof := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.08
	cone.bottom_radius = (w + 0.16) * 0.72
	cone.height = 0.3
	cone.radial_segments = 4
	cone.rings = 1
	roof.mesh = cone
	roof.material_override = flat_material(BOOTH_RED)
	roof.rotation.y = PI / 4
	roof.position = Vector3(0, h + 0.41, 0)
	shake.add_child(roof)
	shake.add_child(coconut(0.09, 3))  # un pompon en haut : une petite boule rouge
	shake.get_child(-1).position = Vector3(0, h + 0.6, 0)
	(shake.get_child(-1) as MeshInstance3D).material_override = flat_material(BOOTH_RED)
	# Les bandeaux « TÉLÉPHONE » sous le toit, sur les quatre côtés.
	for i in 4:
		var side := Node3D.new()
		side.rotation.y = i * PI / 2
		shake.add_child(side)
		side.add_child(Greybox.box(Vector3(w - 0.1, 0.22, 0.04), BOOTH_CREAM, Vector3(0, h - 0.05, w / 2 + 0.02)))
		var sign := Label3D.new()
		sign.text = "BOOTH_SIGN"
		sign.font = UiTheme.title_font()
		sign.font_size = 46
		sign.pixel_size = 0.004
		sign.modulate = BOOTH_RED
		sign.outline_size = 0
		sign.double_sided = false
		sign.position = Vector3(0, h - 0.05, w / 2 + 0.045)
		side.add_child(sign)
	# Les vitres (derrière, gauche, droite), avec des petits carreaux rouges.
	var glass := flat_material(BOOTH_GLASS)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.1
	glass.metallic_specular = 0.7
	for i in 3:
		var side := Node3D.new()
		side.rotation.y = PI + (i - 1) * PI / 2  # derrière, puis les deux côtés
		shake.add_child(side)
		var pane := Greybox.box(Vector3(w - 0.13, h - 0.45, 0.03), Color.WHITE, Vector3(0, 0.12 + (h - 0.45) / 2 + 0.1, w / 2))
		pane.material_override = glass
		side.add_child(pane)
		for k in 4:
			side.add_child(Greybox.box(Vector3(w - 0.13, 0.05, 0.05), BOOTH_RED, Vector3(0, 0.3 + k * 0.62, w / 2)))
		side.add_child(Greybox.box(Vector3(0.05, h - 0.45, 0.05), BOOTH_RED, Vector3(0, 0.12 + (h - 0.45) / 2 + 0.1, w / 2)))
	# Le téléphone mural, au fond, face à l'ouverture.
	var phone := Node3D.new()
	phone.name = "Phone"
	phone.position = Vector3(0, 1.45, -w / 2 + 0.1)
	shake.add_child(phone)
	phone.add_child(Greybox.box(Vector3(0.3, 0.4, 0.12), Color(0.12, 0.12, 0.14), Vector3.ZERO))
	phone.add_child(Greybox.box(Vector3(0.18, 0.12, 0.02), Color(0.85, 0.8, 0.7), Vector3(0, 0.02, 0.07)))
	var handset := Node3D.new()
	handset.name = "Handset"
	handset.position = Vector3(-0.2, 0.0, 0.05)
	phone.add_child(handset)
	handset.add_child(Greybox.box(Vector3(0.07, 0.34, 0.08), Color(0.12, 0.12, 0.14), Vector3.ZERO))
	handset.add_child(Greybox.box(Vector3(0.1, 0.08, 0.1), Color(0.12, 0.12, 0.14), Vector3(0, 0.17, 0.02)))
	handset.add_child(Greybox.box(Vector3(0.1, 0.08, 0.1), Color(0.12, 0.12, 0.14), Vector3(0, -0.17, 0.02)))
	# La tablette et le catalogue enchaîné (rouge et crème, comme l'interface).
	shake.add_child(Greybox.box(Vector3(0.6, 0.04, 0.3), Greybox.WOOD, Vector3(0, 0.98, -w / 2 + 0.2)))
	var catalogue := Node3D.new()
	catalogue.name = "Catalogue"
	catalogue.position = Vector3(0.05, 1.0, -w / 2 + 0.2)
	catalogue.rotation.y = 0.15
	shake.add_child(catalogue)
	catalogue.add_child(Greybox.box(Vector3(0.36, 0.05, 0.26), BOOTH_CREAM, Vector3(0, 0.025, 0)))
	catalogue.add_child(Greybox.box(Vector3(0.37, 0.012, 0.27), BOOTH_RED, Vector3(0, 0.056, 0)))
	catalogue.add_child(Greybox.box(Vector3(0.2, 0.004, 0.06), Color(1.0, 0.8, 0.25), Vector3(0, 0.064, -0.05)))
	for k in 5:  # la chaîne, jusqu'au téléphone
		catalogue.add_child(Greybox.box(Vector3(0.025, 0.025, 0.05), Color(0.6, 0.6, 0.62), Vector3(-0.2 - k * 0.012, 0.06 + k * 0.08, -0.05)))
	return root
