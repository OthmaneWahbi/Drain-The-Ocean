class_name Props
extends RefCounted
## Les modèles des objets du jeu (0.1.4) : tas de ressources, coquillages, caisse et parachute,
## avion, palette, zones de séchage, pompes, moulin, toboggan, miroir, seaux, râteau, stations…
## Rien de gratuit en ligne ne collait au style ou à l'objet (voir assets/CREDITS.md) : ils sont
## fabriqués ici en formes simples et facettes, aux couleurs du catalogue (UiTheme). Quand un
## modèle CC0 convient (cristaux, crabe, poisson, personnages), il vient de Models.load_model.
## Chaque fabrique rend un Node3D sans physique, posé sur (0, 0, 0) : les vues ajoutent les
## collisions, et les photos du catalogue (ProductModels) réutilisent les mêmes modèles.
## Les pièces animées portent un nom (« Lever », « Blades », « Water »…) pour que la vue les retrouve.

const WOOD := Color(0.66, 0.45, 0.26)
const WOOD_DARK := Color(0.46, 0.3, 0.17)
const WOOD_LIGHT := Color(0.82, 0.64, 0.42)
const IRON := Color(0.26, 0.32, 0.38)
const METAL := Color(0.68, 0.72, 0.76)
const ROPE := Color(0.78, 0.68, 0.48)
const CREAM := Color(1.0, 0.94, 0.8)
const RED := Color(0.88, 0.24, 0.17)
const TEAL := Color(0.12, 0.62, 0.6)
const YELLOW := Color(1.0, 0.79, 0.24)
const SALT := Color(0.97, 0.97, 0.95)
const TARP_BLUE := Color(0.22, 0.5, 0.82)
const WATER := Color(0.25, 0.62, 0.85, 0.82)
const SKIN := Color(0.96, 0.76, 0.6)
const BURLAP := Color(0.8, 0.68, 0.48)
const GLASS := Color(0.75, 0.93, 1.0, 0.35)
## La couleur du sable sous chaque tas (le « socle »), par ressource.
const PILE_BASE := {
	"sel": Color(0.93, 0.93, 0.9),
	"mineraux": Color(0.55, 0.53, 0.5),
	"mineraux_rares": Color(0.42, 0.36, 0.5),
	"coquillages": Color(0.95, 0.78, 0.7),  # sable rosé, pour que les coquilles ressortent (0.1.8)
	"perles": Color(0.36, 0.42, 0.72),  # un coussin bleu nuit : les perles blanches s'y voient (0.1.8)
}
const SHELL_COLORS := [Color(1.0, 0.62, 0.5), Color(0.98, 0.78, 0.45), Color(0.94, 0.5, 0.62), Color(0.8, 0.62, 0.92)]

static var _mats: Dictionary = {}


# --- Briques ----------------------------------------------------------------------------------

## Un matériau mat, partagé par couleur (transparent si alpha < 1).
static func mat(color: Color) -> StandardMaterial3D:
	if _mats.has(color):
		return _mats[color]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	m.metallic_specular = 0.2
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.15
		m.metallic_specular = 0.6
	_mats[color] = m
	return m


static func box(size: Vector3, color: Color, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat(color)
	mi.position = pos
	mi.rotation = rot
	return mi


## Un cylindre (ou un cône si les rayons diffèrent), debout sur l'axe Y, centré sur `pos`.
static func cyl(top: float, bottom: float, height: float, color: Color, pos := Vector3.ZERO, sides := 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = sides
	c.rings = 1
	mi.mesh = c
	mi.material_override = mat(color)
	mi.position = pos
	return mi


## Une barre de `a` à `b` (une planche, un pied, une corde).
static func beam(a: Vector3, b: Vector3, thickness: float, color: Color, round := false) -> MeshInstance3D:
	var length := a.distance_to(b)
	var mi := cyl(thickness / 2, thickness / 2, length, color, Vector3.ZERO, 6) if round else box(Vector3(thickness, length, thickness), color)
	mi.position = (a + b) / 2
	var dir := (b - a).normalized()
	if absf(dir.dot(Vector3.UP)) < 0.999:
		mi.basis = Basis(Quaternion(Vector3.UP, dir))
	elif dir.y < 0:
		mi.rotation.x = PI
	return mi


static func torus(inner: float, outer: float, color: Color, pos := Vector3.ZERO, rings := 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = rings
	t.ring_segments = 6
	mi.mesh = t
	mi.material_override = mat(color)
	mi.position = pos
	return mi


static func ball(radius: float, color: Color, pos := Vector3.ZERO, rng_seed := 1, wobble := 0.0, stretch := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Models.facet_sphere(radius, 7, 5, rng_seed, stretch, wobble)
	mi.material_override = mat(color)
	mi.position = pos
	return mi


## Un texte peint (tampon de l'Agence sur une caisse, un sac…). `key` est traduit.
static func painted(key: String, color: Color, size: int, pos: Vector3, rot_y := 0.0) -> Label3D:
	var l := Label3D.new()
	l.text = key
	l.font = UiTheme.marker_font()
	l.font_size = size
	l.pixel_size = 0.004
	l.modulate = color
	l.outline_size = 0
	l.double_sided = false
	l.position = pos
	l.rotation.y = rot_y
	return l


## Un dôme à facettes (le haut d'une boule), base en y = 0. Pour les tas.
static func dome(radius: float, height: float, segments: int, rings: int, rng_seed: int, wobble: float) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var grid := []
	for r in rings + 1:
		var row := []
		var phi := PI / 2 * r / rings
		for s in segments:
			var theta := TAU * s / segments + (0.5 * TAU / segments if r % 2 == 1 else 0.0)
			var k := 1.0 + (rng.randf_range(-wobble, wobble) if r > 0 and r < rings else 0.0)
			row.append(Vector3(sin(phi) * cos(theta) * radius * k, cos(phi) * height * k, sin(phi) * sin(theta) * radius * k))
		grid.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var below := Vector3(0, -height, 0)
	for r in rings:
		for s in segments:
			var a: Vector3 = grid[r][s]
			var b: Vector3 = grid[r][(s + 1) % segments]
			var c: Vector3 = grid[r + 1][s]
			var d: Vector3 = grid[r + 1][(s + 1) % segments]
			tri_from(st, a, b, c, below)
			tri_from(st, b, d, c, below)
	return st.commit()


## Un triangle à facette plate dont la face regarde à l'opposé de `inside`.
static func tri_from(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-12:
		return
	if n.dot((a + b + c) / 3.0 - inside) < 0.0:
		var t := b
		b = c
		c = t
		n = -n
	st.set_normal(n.normalized())
	# Godot voit de face les triangles dans le sens des aiguilles d'une montre : a, c, b.
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(b)


static func _mesh(m: Mesh, color: Color, two_sided := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	var material := mat(color)
	if two_sided:
		material = material.duplicate() as StandardMaterial3D
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = material
	return mi


# --- Ressources : tas, coquillages, perles -----------------------------------------------------

## Le tas d'une ressource (0.1.10 : retravaillé, remarques 3 et 9). Rayon ~0,36 m, haut ~0,3 à
## 0,45 m : la vue le met à l'échelle selon la quantité.
##  - sel : un tas de neige de Kenney (Holiday Kit, CC0) teint en blanc crème, et des cristaux ;
##  - minéraux : des pierres de Kenney (Survival Kit, CC0) en gris, sur un monticule de gravier ;
##  - minéraux rares : le tas de gemmes de KayKit (Resource Bits, CC0), avec ses couleurs ;
##  - coquillages : uniquement des coquillages (moules de Kenney, coquilles et conques par code),
##    empilés en couronnes, sans monticule coloré visible ;
##  - perles : des perles nacrées sur un coussin bleu nuit (inchangé).
static func pile(resource: String, rng_seed := 7) -> Node3D:
	var root := Node3D.new()
	root.name = "Pile_" + resource
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	match resource:
		"sel":
			var snow := fit_model("kenney_snow_pile", Vector3(0.74, 0.3, 0.74))
			Models.flat_colored(snow, Color(0.96, 0.95, 0.9))
			root.add_child(snow)
			for i in 9:
				var a := i * 2.39996 + rng.randf_range(-0.2, 0.2)
				var r := 0.26 * sqrt(1.0 - (float(i) + 0.5) / 9.0)
				var piece := pile_piece(resource, rng, i)
				piece.position = Vector3(cos(a) * r, 0.3 * sqrt(maxf(1.0 - pow(r / 0.37, 2.0), 0.0)) - 0.03, sin(a) * r)
				root.add_child(piece)
		"mineraux_rares":
			root.add_child(fit_model("kaykit_gems_pile_small", Vector3(0.74, 0.42, 0.74)))
			for i in 4:  # quelques cristaux qui dépassent
				var a := i * 2.39996
				var piece := pile_piece(resource, rng, i)
				piece.position = Vector3(cos(a) * 0.2, 0.12 + 0.05 * (i % 2), sin(a) * 0.2)
				root.add_child(piece)
		"coquillages":
			root.add_child(_shell_heap(rng))
		_:
			var mound := _mesh(dome(0.36, 0.3, 9, 3, rng_seed, 0.1), PILE_BASE.get(resource, SALT))
			mound.name = "Mound"
			root.add_child(mound)
			var count := 12 if resource != "mineraux" else 9
			for i in count:
				var t := (float(i) + 0.5) / count
				var r := 0.3 * sqrt(1.0 - t)  # les premiers en bas, au bord ; les derniers au sommet
				var a := i * 2.39996 + rng.randf_range(-0.2, 0.2)
				var y := 0.3 * sqrt(maxf(1.0 - pow(r / 0.36, 2.0), 0.0))
				var piece := pile_piece(resource, rng, i)
				piece.position = Vector3(cos(a) * r, y - 0.02, sin(a) * r)
				root.add_child(piece)
	return root


## Un modèle CC0 mis à la taille `size` (largeur, hauteur, profondeur), centré, posé en y = 0.
static func fit_model(model_name: String, size: Vector3) -> Node3D:
	var holder := Node3D.new()
	var m := Models.load_model(model_name)
	var bb := Models.bounds(Models.vertices(m))
	var k := Vector3(size.x / maxf(bb.size.x, 0.001), size.y / maxf(bb.size.y, 0.001), size.z / maxf(bb.size.z, 0.001))
	m.scale = k
	var c := bb.get_center()
	m.position = Vector3(-c.x * k.x, -bb.position.y * k.y, -c.z * k.z)
	holder.add_child(m)
	return holder


## Un tas fait seulement de coquillages : trois couronnes de plus en plus petites et une coquille
## au sommet. Un petit cœur rose foncé dessous bouche les trous entre les coquilles.
static func _shell_heap(rng: RandomNumberGenerator) -> Node3D:
	var heap := Node3D.new()
	heap.add_child(_mesh(dome(0.27, 0.2, 8, 2, 5, 0.1), Color(0.78, 0.55, 0.48)))
	var colors := SHELL_COLORS + [Color(0.98, 0.93, 0.85), Color(0.95, 0.85, 0.72)]
	var rings := [[10, 0.29, 0.03], [7, 0.19, 0.12], [4, 0.1, 0.2], [1, 0.0, 0.27]]
	var n := 0
	for ring in rings:
		for q in int(ring[0]):
			var a := TAU * q / float(ring[0]) + rng.randf_range(-0.2, 0.2) + float(ring[1]) * 3.0
			var holder := Node3D.new()
			holder.position = Vector3(cos(a) * float(ring[1]), float(ring[2]), sin(a) * float(ring[1]))
			# Couché vers l'extérieur, comme glissé sur la pente du tas.
			holder.rotation = Vector3(rng.randf_range(-0.25, 0.25), -a + PI / 2 + rng.randf_range(-0.6, 0.6), -0.45 if ring[1] > 0.0 else 0.0)
			var color: Color = colors[(n * 3 + q) % colors.size()]
			match n % 4:
				0, 2:
					var mussel := fit_model("kenney_mussel_open" if n % 4 == 0 else "kenney_mussel", Vector3(0.1, 0.06, 0.17))
					Models.flat_colored(mussel, color)
					holder.add_child(mussel)
				1:
					holder.add_child(scallop(0.13, color))
				3:
					holder.add_child(conch(0.15, color))
			heap.add_child(holder)
			n += 1
	return heap


## Le bac en bois où tombe ce qui sèche (0.1.10, remarque 9 : les tas sont dans de petits
## contenants) : un fond et quatre planches basses, coins renforcés. Aussi en main (remarque 4).
static func bin(size := 0.8, height := 0.2) -> Node3D:
	var root := Node3D.new()
	root.name = "Bin"
	var t := size * 0.06
	root.add_child(box(Vector3(size, 0.03, size), WOOD_DARK, Vector3(0, 0.015, 0)))
	for i in 4:
		var side := Node3D.new()
		side.rotation.y = i * PI / 2
		root.add_child(side)
		side.add_child(box(Vector3(size, height * 0.5, t), WOOD if i % 2 == 0 else WOOD_LIGHT, Vector3(0, height * 0.25, size / 2 - t / 2)))
		side.add_child(box(Vector3(size, height * 0.5, t), WOOD_LIGHT if i % 2 == 0 else WOOD, Vector3(0, height * 0.75, size / 2 - t / 2)))
		side.add_child(box(Vector3(t * 1.3, height * 1.05, t * 1.3), WOOD_DARK, Vector3(size / 2 - t / 2, height * 0.52, size / 2 - t / 2)))
	return root


## Un morceau du dessus d'un tas.
static func pile_piece(resource: String, rng: RandomNumberGenerator, i: int) -> Node3D:
	var holder := Node3D.new()
	holder.rotation = Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.4, 0.4))
	match resource:
		"sel":
			# Des cristaux cubiques, blancs bleutés, de tailles différentes.
			var s := rng.randf_range(0.05, 0.08)
			holder.add_child(box(Vector3(s, s, s), SALT if i % 3 else Color(0.88, 0.95, 1.0), Vector3(0, s * 0.3, 0)))
		"mineraux":
			if i % 3 == 0:
				var stone := fit_model("kenney_resource_stone_large", Vector3(0.2, 0.09, 0.18))
				Models.flat_colored(stone, [Color(0.55, 0.53, 0.5), Color(0.62, 0.6, 0.56)][i % 2])
				holder.add_child(stone)
			elif i % 3 == 1:
				var rock := Models.load_model("crystal_rock")
				Models.fit_on_ground(rock, 0.15)
				holder.add_child(rock)
			else:
				holder.add_child(ball(rng.randf_range(0.05, 0.08), [Color(0.5, 0.48, 0.46), Color(0.62, 0.58, 0.52), Color(0.42, 0.42, 0.44)][i % 3], Vector3(0, 0.03, 0), i, 0.25, Vector3(1, 0.7, 1)))
		"mineraux_rares":
			var gem := Models.load_model("crystal" if i % 2 == 0 else "gem_pink")
			Models.fit_on_ground(gem, 0.2 if i % 2 == 0 else 0.13)
			holder.add_child(gem)
		"coquillages":
			holder.add_child(shell(i, 0.14))
			holder.rotation.x = rng.randf_range(-0.3, 0.3)
		"perles":
			holder.add_child(pearl(0.045, Vector3(0, 0.04, 0)))
			if i % 4 == 0:
				holder.add_child(shell(1, 0.15))  # une coquille entrouverte au milieu des perles
	return holder


## Une perle : petite, ronde, nacrée.
static func pearl(radius: float, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2
	s.radial_segments = 10
	s.rings = 6
	mi.mesh = s
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.98, 0.96, 1.0)
	m.metallic = 0.25
	m.roughness = 0.12
	m.rim_enabled = true
	m.rim = 0.6
	m.rim_tint = 0.3
	mi.material_override = m
	mi.position = pos
	return mi


## Un coquillage : coquille Saint-Jacques (pair) ou conque en spirale (impair).
static func shell(variant: int, size := 0.22) -> Node3D:
	if variant % 2 == 0:
		return scallop(size, SHELL_COLORS[(variant / 2) % SHELL_COLORS.size()])
	return conch(size, SHELL_COLORS[(variant / 2 + 1) % SHELL_COLORS.size()])


## Une coquille Saint-Jacques : un éventail bombé à côtes, et ses deux « oreilles » à la
## charnière. Charnière en (0, 0, -size/2), éventail vers +Z.
## 0.1.8 : coquille fermée dessous (on ne voit plus à travers quand elle est sur le sable), côtes
## en deux tons (une claire, une foncée) pour qu'on lise sa forme de loin, et un petit rebord.
static func scallop(size: float, color: Color) -> Node3D:
	var root := Node3D.new()
	var light := SurfaceTool.new()
	var dark := SurfaceTool.new()
	var under := SurfaceTool.new()
	for st: SurfaceTool in [light, dark, under]:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hinge := Vector3(0, size * 0.05, -size * 0.5)
	var ribs := 12
	var spread := deg_to_rad(150.0)
	var rim := []
	var mid := []
	var low := []
	for k in ribs + 1:
		var a := -spread / 2 + spread * k / ribs
		var dir := Vector3(sin(a), 0, cos(a))
		var ridge := k % 2 == 0
		var rr := size * (1.0 if ridge else 0.95)
		rim.append(hinge + dir * rr + Vector3(0, size * (0.07 if ridge else 0.03), 0))
		mid.append(hinge + dir * rr * 0.55 + Vector3(0, size * (0.32 if ridge else 0.26), 0))
		low.append(Vector3(rim[k].x, 0.0, rim[k].z))
	var inside := hinge + Vector3(0, -size, size * 0.4)
	for k in ribs:
		var st: SurfaceTool = light if k % 2 == 0 else dark
		tri_from(st, hinge, mid[k], mid[k + 1], inside)
		tri_from(st, mid[k], rim[k], rim[k + 1], inside)
		tri_from(st, mid[k], rim[k + 1], mid[k + 1], inside)
		# Le rebord jusqu'au sol, puis le dessous plat.
		var c := Vector3(0, size * 0.1, -size * 0.1)
		tri_from(under, rim[k], low[k], low[k + 1], c)
		tri_from(under, rim[k], low[k + 1], rim[k + 1], c)
		tri_from(under, Vector3(hinge.x, 0.0, hinge.z), low[k + 1], low[k], Vector3(0, size, 0))
	root.add_child(_mesh(light.commit(), color.lightened(0.04)))
	root.add_child(_mesh(dark.commit(), color.darkened(0.16)))
	root.add_child(_mesh(under.commit(), color.darkened(0.25)))
	for side in [-1.0, 1.0]:  # les oreilles
		var ear := box(Vector3(size * 0.22, size * 0.06, size * 0.16), color.darkened(0.08), hinge + Vector3(side * size * 0.13, 0.0, size * 0.02))
		root.add_child(ear)
	return root


## Une conque : un cône bombé couché sur le sable, sa spire en pointe, deux bourrelets qui
## marquent les tours, le canal à l'autre bout et une ouverture rose tournée vers le ciel.
## Pointe vers +X (0.1.8 : avant, des boules empilées qui ressemblaient à une pomme de terre).
static func conch(size: float, color: Color) -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.rotation.z = -PI / 2  # couchée : l'axe Y du coquillage devient +X, son -X le haut
	body.position.y = size * 0.29
	root.add_child(body)
	body.add_child(cyl(size * 0.06, size * 0.3, size * 0.55, color, Vector3.ZERO, 9))
	body.add_child(cyl(0.0, size * 0.17, size * 0.36, color.darkened(0.15), Vector3(0, size * 0.45, 0), 9))
	body.add_child(torus(size * 0.2, size * 0.28, color.darkened(0.08), Vector3(0, -size * 0.04, 0), 10))
	body.add_child(torus(size * 0.12, size * 0.18, color.darkened(0.12), Vector3(0, size * 0.2, 0), 10))
	body.add_child(cyl(size * 0.09, size * 0.03, size * 0.22, color.darkened(0.1), Vector3(0, -size * 0.38, 0), 7))
	var lip := ball(size * 0.2, Color(1.0, 0.7, 0.68), Vector3(-size * 0.22, -size * 0.1, 0), 41, 0.0, Vector3(0.35, 1.3, 0.85))
	body.add_child(lip)
	return root


## Pose un petit objet (coquillage, étoile de mer) SUR le sable en `pos` (monde) : penché comme
## la pente, et assez haut pour qu'aucun bord ne s'enfonce. On mesure le sable à `radius` autour
## (0.1.8 : posés au centre seulement, ils disparaissaient à moitié dans les pentes).
## Renvoie la transformée à donner au nœud.
static func on_sand(terrain: TerrainLogic, pos: Vector3, radius: float, yaw: float) -> Transform3D:
	if terrain == null:  # pas d'île (tests) : posé droit
		return Transform3D(Basis(Vector3.UP, yaw), pos)
	var hx := terrain.height(pos.x + radius, pos.z) - terrain.height(pos.x - radius, pos.z)
	var hz := terrain.height(pos.x, pos.z + radius) - terrain.height(pos.x, pos.z - radius)
	var up := Vector3(-hx, 2.0 * radius, -hz).normalized()
	if up.angle_to(Vector3.UP) > deg_to_rad(25.0):  # pas couché sur le flanc d'une marche de dune
		up = Vector3.UP.slerp(up, deg_to_rad(25.0) / up.angle_to(Vector3.UP))
	var y := terrain.height(pos.x, pos.z)
	for k in 8:
		var a := TAU * k / 8.0
		var p := pos + Vector3(cos(a), 0, sin(a)) * radius
		# Le sable sous ce bord, moins la hauteur que la pente donne déjà à ce bord.
		var tilt_rise := -(up.x * (p.x - pos.x) + up.z * (p.z - pos.z)) / maxf(up.y, 0.1)
		y = maxf(y, terrain.height(p.x, p.z) - tilt_rise)
	var basis := Basis(Quaternion(Vector3.UP, up)) * Basis(Vector3.UP, yaw)
	return Transform3D(basis, Vector3(pos.x, y - 0.01, pos.z))


## Une étoile de mer à cinq bras (fonds marins, plages).
static func starfish(size: float, color: Color) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0, size * 0.12, 0)
	var pts := []
	for k in 10:
		var a := TAU * k / 10.0
		var r := size * (0.5 if k % 2 == 0 else 0.18)
		pts.append(Vector3(cos(a) * r, 0.0, sin(a) * r))
	for k in 10:
		tri_from(st, top, pts[k], pts[(k + 1) % 10], Vector3(0, -size, 0))
	return _mesh(st.commit(), color, true)


# --- Livraison : caisse, parachute, palette, sacs, avion ---------------------------------------

## La caisse de l'Agence (0.1.10, remarque 12) : la caisse en planches du Pirate Kit de Kenney
## (CC0), mise en cube de `size`, au lieu de la caisse faite par code. Le tampon « AGENCE » et
## « Fragile » sont peints À PLAT sur le panneau du milieu de chaque face ±Z (avant, ils
## flottaient devant la caisse et dépassaient de ses bords).
static func crate(size := 0.9) -> Node3D:
	var root := Node3D.new()
	var model := Models.load_model("kenney_pirate_crate")
	var pts := Models.vertices(model)
	var bb := Models.bounds(pts)
	var k := Vector3(size / bb.size.x, size / bb.size.y, size / bb.size.z)
	model.scale = k
	var c := bb.get_center()
	model.position = Vector3(-c.x * k.x, -bb.position.y * k.y, -c.z * k.z)
	root.add_child(model)
	# La caisse du kit est ouverte en haut : on la ferme avec un couvercle cloué (trois planches
	# et deux traverses), puisqu'elle arrive pleine.
	for k2 in 3:
		root.add_child(box(Vector3(size * 0.97, 0.04, size * 0.31), WOOD if k2 != 1 else WOOD_LIGHT, Vector3(0, size - 0.02, (k2 - 1) * size * 0.32)))
	for sx in [-1, 1]:
		root.add_child(box(Vector3(size * 0.1, 0.03, size * 0.97), WOOD_DARK, Vector3(sx * size * 0.33, size + 0.015, 0)))
	# Le panneau : le plus en avant des sommets du milieu de la face (hors cadre).
	var panel := 0.0
	for p in pts:
		if absf(p.x - c.x) < bb.size.x * 0.2 and absf(p.y - c.y) < bb.size.y * 0.2:
			panel = maxf(panel, absf(p.z - c.z) * k.z)
	if panel <= 0.0:
		panel = size / 2.0
	var h := size / 2.0
	for side in [-1.0, 1.0]:
		var stamp := painted("CRATE_STAMP", RED, 40, Vector3(0, h + size * 0.06, side * (panel + 0.004)), 0.0 if side > 0 else PI)
		stamp.width = size * 0.8 / stamp.pixel_size
		stamp.autowrap_mode = TextServer.AUTOWRAP_OFF
		root.add_child(stamp)
		var fragile := painted("CRATE_FRAGILE", IRON, 18, Vector3(0, h - size * 0.16, side * (panel + 0.004)), 0.0 if side > 0 else PI)
		fragile.width = size * 0.8 / fragile.pixel_size
		fragile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(fragile)
	return root


## Le parachute : une coupole à bandes rouges et crème, et ses suspentes jusqu'aux coins de la
## caisse (en `crate_top`, sous la coupole).
static func parachute(radius := 1.3, drop := 2.4, crate_half := 0.42) -> Node3D:
	var root := Node3D.new()
	root.name = "Parachute"
	var gores := 10
	var surfaces := [SurfaceTool.new(), SurfaceTool.new()]
	for st: SurfaceTool in surfaces:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 3
	for g in gores:
		var st: SurfaceTool = surfaces[g % 2]
		for r in rings:
			var p := []
			for corner in [[r, g], [r, g + 1], [r + 1, g], [r + 1, g + 1]]:
				var phi := PI / 2 * 0.95 * float(corner[0]) / rings
				var theta := TAU * float(corner[1]) / gores
				# Les bords entre deux panneaux rentrent un peu : la coupole se gonfle en « pétales ».
				var bulge := 1.0
				p.append(Vector3(sin(phi) * cos(theta) * radius * bulge, cos(phi) * radius * 0.55 + drop, sin(phi) * sin(theta) * radius * bulge))
			var center := Vector3(0, drop - radius, 0)
			tri_from(st, p[0], p[1], p[2], center)
			tri_from(st, p[1], p[3], p[2], center)
	for i in 2:
		var mi := _mesh((surfaces[i] as SurfaceTool).commit(), [RED, CREAM][i], true)
		root.add_child(mi)
	# Les suspentes : du bord de la coupole aux quatre coins du dessus de la caisse.
	var rim_y := cos(PI / 2 * 0.95) * radius * 0.55 + drop
	for k in 8:
		var a := TAU * k / 8.0
		var top := Vector3(cos(a) * radius * 0.98, rim_y, sin(a) * radius * 0.98)
		var corner := Vector3(signf(cos(a)) * crate_half, 0.0, signf(sin(a)) * crate_half)
		root.add_child(beam(top, corner, 0.015, Color(0.95, 0.95, 0.92), true))
	return root


## La palette de dépôt : des planches posées sur trois traverses. Dessus en y = size.y.
static func pallet(size: Vector3) -> Node3D:
	# 0.1.9 : des palettes KayKit (Medieval Hexagon, CC0) mises côte à côte en damier, chacune
	# presque à l'échelle (une palette KayKit est carrée, 30 cm de côté : on la grossit environ 3
	# fois) pour que l'ensemble fasse `size` sans étirer les planches.
	var root := Node3D.new()
	var nx := maxi(1, roundi(size.x / 0.9))
	var nz := maxi(1, roundi(size.z / 0.8))
	var w := size.x / nx
	var d := size.z / nz
	for i in nx:
		for k in nz:
			var p := Models.load_model("kaykit_pallet")
			var box_ := Models.bounds(Models.vertices(p))
			# Une sur deux tournée d'un quart de tour : les planches se croisent.
			var turned := (i + k) % 2 == 1
			var sx := (d if turned else w) / box_.size.x
			var sz := (w if turned else d) / box_.size.z
			var holder := Node3D.new()
			p.scale = Vector3(sx, size.y / box_.size.y, sz)
			var c := box_.get_center()
			p.position = Vector3(-c.x * sx, -box_.position.y * p.scale.y, -c.z * sz)
			holder.add_child(p)
			holder.rotation.y = PI / 2.0 if turned else 0.0
			holder.position = Vector3(-size.x / 2.0 + w * (i + 0.5), 0, -size.z / 2.0 + d * (k + 0.5))
			root.add_child(holder)
	return root


## Un sac de toile ficelé (le paiement emporté par l'avion, les sacs du toboggan).
static func sack(size: float, band: Color, rng_seed := 3) -> Node3D:
	var root := Node3D.new()
	root.add_child(ball(size * 0.5, BURLAP, Vector3(0, size * 0.42, 0), rng_seed, 0.08, Vector3(1.0, 0.85, 0.9)))
	root.add_child(cyl(size * 0.12, size * 0.2, size * 0.2, BURLAP.darkened(0.08), Vector3(0, size * 0.86, 0), 7))
	root.add_child(cyl(size * 0.13, size * 0.13, size * 0.05, band, Vector3(0, size * 0.8, 0), 7))
	return root


## L'avion de l'Agence : un biplan cartoon rouge et crème, nez vers −Z (le sens de look_at).
## Nœuds nommés : « Propeller » (tourne autour de Z), « Cockpit » (où s'assoit le pilote).
static func plane() -> Node3D:
	var root := Node3D.new()
	# Le fuselage : un cône allongé couché, gros à l'avant.
	var body := cyl(0.24, 0.5, 3.6, CREAM, Vector3(0, 0, 0.3), 8)
	body.rotation.x = PI / 2  # le bas du cône (gros) part vers −Z
	root.add_child(body)
	var stripe := cyl(0.36, 0.44, 0.5, RED, Vector3(0, 0, -0.8), 8)
	stripe.rotation.x = PI / 2
	root.add_child(stripe)
	var cowl := cyl(0.5, 0.42, 0.4, RED, Vector3(0, 0, -1.6), 8)
	cowl.rotation.x = PI / 2
	root.add_child(cowl)
	var hub := cyl(0.02, 0.14, 0.3, METAL, Vector3(0, 0, -1.93), 8)
	hub.rotation.x = -PI / 2
	root.add_child(hub)
	var prop := Node3D.new()
	prop.name = "Propeller"
	prop.position = Vector3(0, 0, -1.9)
	prop.add_child(box(Vector3(0.12, 1.5, 0.04), WOOD_DARK))
	prop.add_child(box(Vector3(0.13, 0.18, 0.05), RED, Vector3(0, 0.66, 0)))
	prop.add_child(box(Vector3(0.13, 0.18, 0.05), RED, Vector3(0, -0.66, 0)))
	root.add_child(prop)
	# Deux ailes (biplan), rouges à bouts crème, et leurs mâts.
	for y in [-0.32, 0.62]:
		root.add_child(box(Vector3(5.4, 0.08, 0.95), RED, Vector3(0, y, -0.7)))
		for sx in [-1, 1]:
			root.add_child(box(Vector3(0.5, 0.085, 0.96), CREAM, Vector3(sx * 2.5, y, -0.7)))
	for sx in [-1.8, -0.6, 0.6, 1.8]:
		root.add_child(box(Vector3(0.05, 0.94, 0.05), WOOD_DARK, Vector3(sx, 0.15, -0.7)))
	# La queue : empennage, dérive avec le « A » de l'Agence.
	root.add_child(box(Vector3(1.8, 0.06, 0.55), RED, Vector3(0, 0.05, 1.9)))
	var fin := box(Vector3(0.06, 0.8, 0.6), RED, Vector3(0, 0.45, 1.95))
	root.add_child(fin)
	for side in [-1.0, 1.0]:
		var a := painted("PLANE_LETTER", CREAM, 90, Vector3(side * 0.035, 0.45, 1.95), side * PI / 2)
		a.font = UiTheme.title_font()
		root.add_child(a)
	# Le train : deux roues sous le nez.
	for sx in [-0.5, 0.5]:
		root.add_child(beam(Vector3(sx * 0.4, -0.3, -0.9), Vector3(sx, -0.85, -0.9), 0.06, WOOD_DARK))
		var wheel := cyl(0.2, 0.2, 0.1, IRON, Vector3(sx, -0.85, -0.9), 10)
		wheel.rotation.z = PI / 2
		root.add_child(wheel)
	# Le cockpit ouvert et son pare-brise.
	var cockpit := Node3D.new()
	cockpit.name = "Cockpit"
	cockpit.position = Vector3(0, 0.2, 0.15)
	root.add_child(cockpit)
	root.add_child(box(Vector3(0.44, 0.24, 0.04), GLASS, Vector3(0, 0.5, -0.25), Vector3(-0.4, 0, 0)))
	return root


# --- Zones de séchage ---------------------------------------------------------------------------

## Une zone de séchage. Le nœud « Water » est le plan d'eau, que la vue fait monter et descendre.
## Les hauteurs min/max de l'eau sont dans les métadonnées « water_min » / « water_max ».
static func drying_zone(kind: String) -> Node3D:
	var root := Node3D.new()
	match kind:
		"cuvette":
			# 0.1.10 (remarque 9) : une vraie cuvette qui tient l'eau. Un bourrelet de sable tout
			# autour (plus haut que l'eau), une paroi qui descend vers un fond de sable mouillé plus
			# sombre, et quelques galets posés sur le bourrelet.
			root.add_child(basin_mesh(18, 11))
			var rng := RandomNumberGenerator.new()
			rng.seed = 11
			for i in 8:
				var a := TAU * i / 8.0 + rng.randf_range(-0.15, 0.15)
				var s := rng.randf_range(0.28, 0.42)
				var rock := Models.rock("rock_small", Vector3(s, s * 0.55, s * 0.8))
				rock.position = Vector3(cos(a) * 1.36, 0.16, sin(a) * 1.36)
				rock.rotation.y = -a + rng.randf_range(-0.4, 0.4)
				root.add_child(rock)
			_add_water(root, Vector3(2.24, 0.02, 2.24), 0.06, 0.22, true)
		"bache":
			# Une bâche bleue posée sur quatre rondins qui en relèvent les bords, piquets aux coins.
			root.add_child(box(Vector3(2.3, 0.03, 2.3), TARP_BLUE, Vector3(0, 0.02, 0)))
			for i in 4:
				var side := Node3D.new()
				side.rotation.y = i * PI / 2
				root.add_child(side)
				var log := cyl(0.09, 0.09, 2.4, WOOD, Vector3(0, 0.09, 1.2), 7)
				log.rotation.z = PI / 2
				side.add_child(log)
				side.add_child(box(Vector3(2.4, 0.03, 0.3), TARP_BLUE.darkened(0.06), Vector3(0, 0.12, 1.08), Vector3(-0.55, 0, 0)))
				side.add_child(cyl(0.025, 0.03, 0.4, WOOD_DARK, Vector3(1.32, 0.15, 1.32), 5))
				side.add_child(beam(Vector3(1.32, 0.3, 1.32), Vector3(1.15, 0.16, 1.15), 0.015, ROPE, true))
			_add_water(root, Vector3(2.2, 0.02, 2.2), 0.05, 0.18, false)
		"bassin_bois":
			# Un bac en planches (deux rangs, teintes alternées), poteaux d'angle et cerclage.
			var size := Vector2(4.0, 3.0)
			root.add_child(box(Vector3(size.x, 0.06, size.y), WOOD_DARK, Vector3(0, 0.03, 0)))
			for row in 2:
				var y := 0.1 + row * 0.18
				var shade := WOOD if row == 0 else WOOD_LIGHT
				for z in [size.y / 2, -size.y / 2]:
					root.add_child(box(Vector3(size.x, 0.17, 0.08), shade, Vector3(0, y, z)))
				for x in [size.x / 2, -size.x / 2]:
					root.add_child(box(Vector3(0.08, 0.17, size.y), shade, Vector3(x, y, 0)))
			for sx in [-1, 1]:
				for sz in [-1, 1]:
					root.add_child(box(Vector3(0.16, 0.48, 0.16), WOOD_DARK, Vector3(sx * size.x / 2, 0.24, sz * size.y / 2)))
			for z in [size.y / 2 + 0.045, -size.y / 2 - 0.045]:
				root.add_child(box(Vector3(size.x + 0.02, 0.04, 0.01), IRON, Vector3(0, 0.3, z)))
			_add_water(root, Vector3(size.x - 0.16, 0.02, size.y - 0.16), 0.07, 0.36, false)
	return root


## Le profil de la cuvette : (rayon, hauteur) du centre vers l'extérieur, et la couleur de
## chaque anneau (fond mouillé, paroi, haut du bourrelet, pente extérieure).
const BASIN_PROFILE := [Vector2(0.0, 0.02), Vector2(0.9, 0.03), Vector2(1.14, 0.24), Vector2(1.32, 0.29), Vector2(1.55, 0.02)]
const BASIN_COLORS := [Color(0.48, 0.4, 0.27), Color(0.58, 0.48, 0.32), Color(0.72, 0.62, 0.44), Color(0.68, 0.58, 0.4)]


## Le sable de la cuvette : le profil BASIN_PROFILE tourné autour de l'axe, à facettes.
static func basin_mesh(segments: int, rng_seed: int) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var rings := []
	for p: Vector2 in BASIN_PROFILE:
		var row := []
		for sg in segments:
			var a := TAU * sg / segments
			var wob := 1.0 + (rng.randf_range(-0.04, 0.04) if p.x > 0.0 else 0.0)
			row.append(Vector3(cos(a) * p.x * wob, p.y + (rng.randf_range(-0.015, 0.015) if p.x > 0.0 else 0.0), sin(a) * p.x * wob))
		rings.append(row)
	var root := Node3D.new()
	root.name = "Basin"
	for k in BASIN_PROFILE.size() - 1:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for sg in segments:
			var a: Vector3 = rings[k][sg]
			var b: Vector3 = rings[k][(sg + 1) % segments]
			var c: Vector3 = rings[k + 1][sg]
			var d: Vector3 = rings[k + 1][(sg + 1) % segments]
			_flat_tri(st, a, c, b)
			_flat_tri(st, b, c, d)
		root.add_child(_mesh(st.commit(), BASIN_COLORS[k]))
	return root


## Un triangle à normale plate, face vers le haut.
static func _flat_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	if n.y < 0.0:
		var tmp := b
		b = c
		c = tmp
		n = -n
	for v in [a, b, c]:
		st.set_normal(n)
		st.add_vertex(v)


static func _add_water(root: Node3D, size: Vector3, min_y: float, max_y: float, round: bool) -> void:
	var water: MeshInstance3D
	if round:
		water = cyl(size.x / 2, size.x / 2, size.y, WATER, Vector3.ZERO, 16)
	else:
		water = box(size, WATER)
	water.name = "Water"
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.position.y = min_y
	root.add_child(water)
	root.set_meta("water_min", min_y)
	root.set_meta("water_max", max_y)


# --- Pompes, moulin, toboggan, miroir ------------------------------------------------------------

## La pompe à bras : un corps de fonte turquoise cerclé, un bec, et le levier (« Lever », pivot
## en haut, levier vers +Z, poignée rouge), sur une dalle de planches.
static func hand_pump() -> Node3D:
	var root := Node3D.new()
	root.add_child(box(Vector3(0.8, 0.1, 0.8), WOOD, Vector3(0, 0.05, 0)))
	for k in 3:
		root.add_child(box(Vector3(0.81, 0.012, 0.02), WOOD_DARK, Vector3(0, 0.1, -0.27 + k * 0.27)))
	root.add_child(cyl(0.13, 0.17, 0.9, TEAL, Vector3(0, 0.55, 0), 10))
	for y in [0.18, 0.62, 0.98]:
		root.add_child(cyl(0.16, 0.16, 0.05, TEAL.darkened(0.3), Vector3(0, y, 0), 10))
	root.add_child(ball(0.15, TEAL, Vector3(0, 1.02, 0), 5, 0.0, Vector3(1, 0.6, 1)))
	root.add_child(cyl(0.03, 0.03, 0.12, TEAL.darkened(0.3), Vector3(0, 1.14, 0), 6))
	# Le bec (vers −Z) et sa goutte.
	var spout := cyl(0.05, 0.06, 0.4, TEAL, Vector3(0, 0.9, -0.25), 8)
	spout.rotation.x = PI / 2 - 0.25
	root.add_child(spout)
	root.add_child(cyl(0.06, 0.06, 0.05, TEAL.darkened(0.3), Vector3(0, 0.85, -0.44), 8))
	var lever := Node3D.new()
	lever.name = "Lever"
	lever.position = Vector3(0, 1.12, 0.05)
	lever.add_child(box(Vector3(0.05, 0.05, 0.75), IRON, Vector3(0, 0, 0.37)))
	lever.add_child(cyl(0.04, 0.04, 0.18, RED, Vector3(0, 0, 0.78), 6))
	lever.get_child(-1).rotation.x = PI / 2
	root.add_child(lever)
	return root


## Demi-écart des pilotis sous la pompe à bras et sous le moulin (la plateforme déborde de 0,15 m).
const PUMP_STILTS := 0.35
const WINDMILL_STILTS := 0.85


## Les pilotis d'une pompe posée dans l'eau : quatre pieux, des entretoises et une plateforme,
## de hauteur 1 (la vue les met à l'échelle de la profondeur, pieds sur le fond). Nœud « Stilts ».
static func stilts(half: float) -> Node3D:
	var s := Node3D.new()
	s.name = "Stilts"
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			s.add_child(box(Vector3(0.14, 1.0, 0.14), WOOD_DARK, Vector3(sx * half, 0.5, sz * half)))
		s.add_child(box(Vector3(0.06, 0.06, half * 2), WOOD, Vector3(sx * half, 0.6, 0)))
	s.add_child(box(Vector3(half * 2 + 0.3, 0.08, half * 2 + 0.3), WOOD, Vector3(0, 0.96, 0)))
	return s


## Le moulin-pompe (0.1.10) : l'éolienne de ferme de Quaternius (Farm Buildings, CC0), à la place
## de celle faite par code. Ses pales sont un nœud à part, recentré sur l'axe pour tourner :
## « Blades », qui tourne autour de Z comme avant. Hauteur totale : `WINDMILL_HEIGHT`.
const WINDMILL_HEIGHT := 5.0

static func windmill() -> Node3D:
	var root := Node3D.new()
	var model := Models.load_model("quaternius_farm_windmill")
	var bb := Models.bounds(Models.vertices(model))
	var k := WINDMILL_HEIGHT / maxf(bb.size.y, 0.001)
	model.scale = Vector3.ONE * k
	# Centré sur son emprise (les pales débordent du même côté que la queue, c'est l'ensemble
	# qu'on centre), posé au sol.
	var c := bb.get_center()
	model.position = Vector3(-c.x * k, -bb.position.y * k, -c.z * k)
	root.add_child(model)
	# Le pivot des pales, sur le moyeu, enfant direct de la racine (« Blades ») : on y déplace le
	# maillage des pales, qui tourne alors autour de son axe.
	var blades_mesh := model.get_node("Windmill_Blades") as MeshInstance3D
	var hub := (blades_mesh.transform * blades_mesh.mesh.get_aabb()).get_center()
	var pivot := Node3D.new()
	pivot.name = "Blades"
	pivot.position = model.position + hub * k
	pivot.scale = Vector3.ONE * k
	root.add_child(pivot)
	var local := blades_mesh.transform
	blades_mesh.owner = null  # il change de parent : il n'appartient plus à la scène du modèle
	model.remove_child(blades_mesh)
	pivot.add_child(blades_mesh)
	blades_mesh.transform = Transform3D(local.basis, local.origin - hub)
	return root


## Le toboggan : une tour en bois avec échelle (derrière, −Z) et trémie en haut, et une goulotte
## jaune à rebords rouges qui descend vers +Z.
static func slide() -> Node3D:
	var root := Node3D.new()
	for x in [-0.38, 0.38]:
		for z in [-0.38, 0.38]:
			root.add_child(box(Vector3(0.11, 2.05, 0.11), WOOD_DARK, Vector3(x, 1.02, z)))
	root.add_child(box(Vector3(0.95, 0.08, 0.95), WOOD, Vector3(0, 2.0, 0)))
	for k in 6:  # l'échelle
		root.add_child(box(Vector3(0.7, 0.05, 0.05), WOOD_LIGHT, Vector3(0, 0.3 + k * 0.3, -0.42)))
	# La trémie : un entonnoir de planches.
	var hopper := cyl(0.55, 0.3, 0.4, WOOD, Vector3(0, 2.25, 0), 4)
	hopper.rotation.y = PI / 4
	root.add_child(hopper)
	root.add_child(painted("SLIDE_SIGN", RED, 56, Vector3(0, 2.25, 0.33)))
	# La goulotte, en pente, et ses deux pieds.
	var chute := Node3D.new()
	chute.position = Vector3(0, 1.15, 1.4)
	chute.rotation.x = deg_to_rad(38)
	root.add_child(chute)
	chute.add_child(box(Vector3(0.6, 0.05, 2.7), YELLOW))
	for sx in [-1, 1]:
		chute.add_child(box(Vector3(0.05, 0.16, 2.7), RED, Vector3(sx * 0.3, 0.08, 0)))
	root.add_child(box(Vector3(0.08, 0.5, 0.08), WOOD_DARK, Vector3(0, 0.25, 2.3)))
	return root


## Le miroir : un chevalet en bois et un grand cadre jaune incliné (« Panel », 35°).
static func mirror() -> Node3D:
	var root := Node3D.new()
	root.add_child(beam(Vector3(-0.35, 0, 0.25), Vector3(0, 1.05, 0), 0.06, WOOD_DARK))
	root.add_child(beam(Vector3(0.35, 0, 0.25), Vector3(0, 1.05, 0), 0.06, WOOD_DARK))
	root.add_child(beam(Vector3(0, 0, -0.45), Vector3(0, 1.05, 0), 0.06, WOOD_DARK))
	var panel := Node3D.new()
	panel.name = "Panel"
	panel.position = Vector3(0, 1.05, 0)
	panel.rotation_degrees = Vector3(35, 0, 0)
	root.add_child(panel)
	panel.add_child(box(Vector3(1.3, 0.06, 1.0), YELLOW))
	var glass := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(1.15, 0.02, 0.85)
	glass.mesh = b
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.85, 0.94, 1.0)
	m.metallic = 1.0
	m.roughness = 0.05
	glass.material_override = m
	glass.position.y = 0.035
	panel.add_child(glass)
	panel.add_child(box(Vector3(0.12, 0.022, 0.5), Color(1, 1, 1, 0.6), Vector3(-0.35, 0.047, 0), Vector3(0, 0.6, 0)))
	return root


# --- Ce que le joueur tient : seaux, râteau ------------------------------------------------------

## Un seau : en zinc (le seau de départ, cabossé et rafistolé) ou jaune (le grand seau). L'eau est
## le nœud « Water » ; `set_bucket_fill` la fait monter. Fond en (0, 0, 0).
static func bucket(big := false, height := 0.26) -> Node3D:
	var root := Node3D.new()
	var color := YELLOW if big else METAL
	var r := height * (0.62 if big else 0.56)
	# 0.1.9 : le seau en bois de KayKit (Medieval Hexagon, CC0), ouvert en haut : on voit l'eau
	# dedans. Le grand seau est teinté en jaune pour qu'on les distingue.
	var model := Models.load_model("kaykit_bucket_empty")
	Models.fit_on_ground(model, height)
	if big:
		for mi: MeshInstance3D in Models.meshes_of(model):
			for i in mi.mesh.get_surface_count():
				var tinted := (mi.get_surface_override_material(i) as StandardMaterial3D).duplicate() as StandardMaterial3D
				tinted.albedo_color = color
				mi.set_surface_override_material(i, tinted)
	root.add_child(model)
	if not big:
		# La rustine du seau de départ (PRD §12 : il s'abîme et se rapièce).
		var patch := box(Vector3(height * 0.28, height * 0.24, 0.01), Color(0.78, 0.5, 0.32), Vector3(r * 0.2, height * 0.55, r * 0.88), Vector3(0, 0.2, 0.15))
		root.add_child(patch)
	var water := cyl(r * 0.84, r * 0.74, 0.02, WATER, Vector3(0, height * 0.9, 0), 12)
	water.name = "Water"
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(water)
	root.set_meta("height", height)
	root.set_meta("radius", r)
	set_bucket_fill(root, 0.0)
	return root


## Le niveau d'eau d'un seau (0..1) : la surface monte et s'élargit avec la paroi évasée.
static func set_bucket_fill(b: Node3D, ratio: float) -> void:
	var water := b.get_node_or_null("Water") as MeshInstance3D
	if water == null:
		return
	var h: float = b.get_meta("height", 0.26)
	ratio = clampf(ratio, 0.0, 1.0)
	water.visible = ratio > 0.01
	water.position.y = lerpf(h * 0.1, h * 0.9, ratio)
	var k := lerpf(0.8, 1.0, ratio)
	water.scale = Vector3(k, 1, k)


## Le râteau à sel : manche en bois, tête de métal à dents. Le manche suit −Z depuis l'origine.
static func rake() -> Node3D:
	var root := Node3D.new()
	root.add_child(box(Vector3(0.04, 0.04, 1.2), WOOD, Vector3(0, 0, -0.3)))
	root.add_child(cyl(0.03, 0.03, 0.14, RED, Vector3(0, 0, 0.28), 6))
	root.get_child(-1).rotation.x = PI / 2
	root.add_child(box(Vector3(0.55, 0.05, 0.06), METAL, Vector3(0, -0.02, -0.9)))
	for k in 8:
		root.add_child(box(Vector3(0.025, 0.1, 0.025), METAL.darkened(0.15), Vector3(-0.24 + k * 0.0685, -0.08, -0.9)))
	return root


## La pelle (0.1.10) : un manche en bois avec une poignée en T et une lame en métal un peu creuse.
## Tenue en main, la lame vers l'avant (−Z).
static func shovel() -> Node3D:
	var root := Node3D.new()
	root.add_child(box(Vector3(0.045, 0.045, 1.1), WOOD, Vector3(0, 0, -0.25)))
	root.add_child(box(Vector3(0.2, 0.04, 0.04), WOOD_DARK, Vector3(0, 0, 0.3)))
	root.add_child(cyl(0.035, 0.03, 0.12, METAL.darkened(0.2), Vector3(0, 0, -0.82), 6))
	root.get_child(-1).rotation.x = PI / 2
	var blade := box(Vector3(0.26, 0.025, 0.3), METAL, Vector3(0, -0.01, -1.0))
	root.add_child(blade)
	for sx in [-1, 1]:
		root.add_child(box(Vector3(0.025, 0.06, 0.28), METAL.darkened(0.1), Vector3(sx * 0.125, 0.015, -1.0)))
	root.add_child(box(Vector3(0.2, 0.026, 0.06), METAL.lightened(0.15), Vector3(0, -0.012, -1.17)))
	return root


## La palanche : un bâton sur l'épaule et un seau à chaque bout (pour la photo du catalogue).
static func yoke() -> Node3D:
	var root := Node3D.new()
	root.add_child(box(Vector3(1.5, 0.07, 0.07), WOOD, Vector3(0, 0.95, 0)))
	for sx in [-1, 1]:
		root.add_child(beam(Vector3(sx * 0.65, 0.95, 0), Vector3(sx * 0.65, 0.4, 0), 0.015, ROPE, true))
		var b := bucket(false, 0.4)
		b.position = Vector3(sx * 0.65, 0.0, 0)
		set_bucket_fill(b, 0.8)
		root.add_child(b)
	return root


# --- Stations ------------------------------------------------------------------------------------

## Le condenseur : une toile tendue sur quatre piquets, un cercle de pierres et
## une gamelle où tombent les gouttes (les gouttes, la vue les ajoute).
static func condenser() -> Node3D:
	var root := Node3D.new()
	for x in [-0.8, 0.8]:
		for z in [-0.6, 0.6]:
			root.add_child(cyl(0.035, 0.045, 0.95 + z * 0.15, WOOD_DARK, Vector3(x, (0.95 + z * 0.15) / 2, z), 6))
	# 0.1.10 : la toile tendue du Survival Kit de Kenney (CC0) sur les piquets, à la place de la
	# plaque transparente.
	var canvas := fit_model("kenney_tent_canvas", Vector3(1.75, 0.55, 1.35))
	canvas.position.y = 0.62
	root.add_child(canvas)
	for i in 8:
		var a := TAU * i / 8.0
		root.add_child(ball(0.1, Color(0.55, 0.53, 0.5), Vector3(cos(a) * 0.5, 0.05, 0.45 + sin(a) * 0.3), 20 + i, 0.2, Vector3(1, 0.6, 1)))
	root.add_child(cyl(0.3, 0.25, 0.16, METAL, Vector3(0, 0.08, 0.45), 12))
	return root


## La caisse de rations : une caisse kaki au pochoir, couvercle entrouvert, des boîtes dedans.
static func rations() -> Node3D:
	var root := Node3D.new()
	var khaki := Color(0.45, 0.52, 0.3)
	root.add_child(box(Vector3(0.7, 0.42, 0.5), khaki, Vector3(0, 0.21, 0)))
	for x in [-0.33, 0.33]:
		root.add_child(box(Vector3(0.05, 0.44, 0.52), khaki.darkened(0.25), Vector3(x, 0.22, 0)))
	var lid := box(Vector3(0.72, 0.05, 0.52), khaki.darkened(0.1), Vector3(0, 0.52, -0.2), Vector3(-0.6, 0, 0))
	root.add_child(lid)
	for i in 4:
		var c := cyl(0.07, 0.07, 0.14, METAL, Vector3(-0.21 + i * 0.14, 0.46, 0.05), 8)
		root.add_child(c)
		root.add_child(cyl(0.072, 0.072, 0.07, [RED, TEAL, YELLOW, RED][i], Vector3(-0.21 + i * 0.14, 0.46, 0.05), 8))
	root.add_child(painted("RATIONS_STAMP", CREAM, 40, Vector3(0, 0.22, 0.255)))
	return root


## Une goutte d'eau (le condenseur, les gouttes qui tombent du seau).
static func droplet(size: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = size
	s.height = size * 2.6
	s.radial_segments = 8
	s.rings = 4
	mi.mesh = s
	mi.material_override = mat(Color(0.4, 0.72, 0.95, 0.85))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# --- Personnages (Kenney, Mini Characters, CC0) --------------------------------------------------

## Un petit personnage animé, mis à `height` mètres. Son AnimationPlayer joue `anim` en boucle.
## Les modèles regardent vers +Z ; ils ont « idle », « walk », « sprint », « drive », « pick-up »…
static func character(model_name: String, height: float, anim := "idle") -> Node3D:
	var root := Node3D.new()
	var model := Models.load_model(model_name)
	model.name = "Model"
	root.add_child(model)
	Models.fit_on_ground(model, height)
	play(root, anim)
	return root


## Fait jouer une animation (en boucle) au personnage `root`, si elle n'est pas déjà en cours.
static func play(root: Node, anim: String, speed := 1.0) -> void:
	var players := root.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var ap := players[0] as AnimationPlayer
	if not ap.has_animation(anim):
		return
	var a := ap.get_animation(anim)
	a.loop_mode = Animation.LOOP_LINEAR
	if ap.current_animation != anim:
		ap.play(anim, 0.2)
	ap.speed_scale = speed
