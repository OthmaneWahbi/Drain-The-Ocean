class_name IslandLife
extends RefCounted
## Les modèles de la vie sur l'île (0.1.21+) : hamac, vitrine, masque… faits en facettes comme le
## reste (Props). Utilisés par les vues (DecorView) et les photos du catalogue (ProductModels).

const WOOD := Color(0.55, 0.38, 0.22)
const WOOD_DARK := Color(0.4, 0.27, 0.15)
const CLOTH := Color(0.93, 0.55, 0.3)
const CLOTH_STRIPE := Color(0.98, 0.9, 0.72)
const ROPE := Color(0.82, 0.72, 0.5)
const SILHOUETTE := Color(0.12, 0.13, 0.16)
const MASK_BLUE := Color(0.16, 0.55, 0.85)
const GLASS := Color(0.75, 0.95, 1.0, 0.45)

## Hauteur des cases de la vitrine (m) et largeur d'une case.
const SHELF_ROW_H := 0.42
const SHELF_SLOT_W := 0.36


## Un hamac entre deux piquets, le long de X (3 m), toile rayée qui pend en arc.
static func hammock() -> Node3D:
	var root := Node3D.new()
	for side in [-1.0, 1.0]:
		var post := Props.cyl(0.07, 0.09, 1.5, WOOD_DARK, Vector3(side * 1.35, 0.75, 0), 7)
		post.rotation.z = side * -0.08
		root.add_child(post)
		root.add_child(Props.cyl(0.11, 0.11, 0.06, WOOD, Vector3(side * 1.38, 1.47, 0), 7))
	var segs := 10
	for k in segs:
		var t0 := float(k) / segs
		var t1 := float(k + 1) / segs
		var a := _sag(t0)
		var b := _sag(t1)
		var piece := Props.box(Vector3(a.distance_to(b) + 0.01, 0.03, 0.75), CLOTH if k % 2 == 0 else CLOTH_STRIPE, (a + b) / 2.0)
		piece.rotation.z = atan2(b.y - a.y, b.x - a.x)
		root.add_child(piece)
	for side in [-1.0, 1.0]:  # les cordes jusqu'aux piquets
		root.add_child(Props.beam(Vector3(side * 0.95, _sag(0.0 if side < 0 else 1.0).y, 0), Vector3(side * 1.33, 1.35, 0), 0.025, ROPE))
	return root


## Un point de la toile (t de 0 à 1 le long du hamac) : un arc qui pend à 55 cm du sol au milieu.
static func _sag(t: float) -> Vector3:
	var x := lerpf(-0.95, 0.95, t)
	var y := 0.55 + 0.4 * pow(2.0 * t - 1.0, 2.0)
	return Vector3(x, y, 0)


## La vitrine : une étagère en bois flotté à 3 rangées (le long de X, 2 m), fond bleu nuit.
## `rows` cases par rangée (la plus longue rangée de la collection).
static func shelf(cols: int, rows: int) -> Node3D:
	var root := Node3D.new()
	var w := cols * SHELF_SLOT_W + 0.12
	var h := rows * SHELF_ROW_H + 0.1
	root.add_child(Props.box(Vector3(w, h, 0.04), Color(0.16, 0.22, 0.3), Vector3(0, h / 2.0 + 0.1, -0.2)))
	for side in [-1.0, 1.0]:
		root.add_child(Props.box(Vector3(0.06, h + 0.1, 0.45), WOOD, Vector3(side * w / 2.0, (h + 0.1) / 2.0, 0)))
	for r in rows + 1:
		root.add_child(Props.box(Vector3(w, 0.04, 0.45), WOOD if r % 2 == 0 else WOOD_DARK, Vector3(0, 0.1 + r * SHELF_ROW_H, 0)))
	return root


## Où va la case (col, rang) de la vitrine, au-dessus de son étagère (rang 0 en haut).
static func shelf_slot(col: int, row: int, cols: int, rows: int) -> Vector3:
	var w := cols * SHELF_SLOT_W
	return Vector3(-w / 2.0 + SHELF_SLOT_W * (col + 0.5), 0.1 + (rows - 1 - row) * SHELF_ROW_H + 0.03, 0.0)


## Peint tout un modèle d'une seule couleur sombre : la silhouette d'une trouvaille qui manque.
static func silhouette(node: Node) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = SILHOUETTE
	m.roughness = 1.0
	for mi in node.find_children("*", "GeometryInstance3D", true, false):
		(mi as GeometryInstance3D).material_override = m
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).material_override = m


## Le masque et son tuba.
static func mask() -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.box(Vector3(0.42, 0.22, 0.08), MASK_BLUE, Vector3(0, 0.25, 0)))
	var glass := Props.box(Vector3(0.36, 0.17, 0.02), GLASS, Vector3(0, 0.25, 0.05))
	root.add_child(glass)
	root.add_child(Props.torus(0.18, 0.2, Color(0.1, 0.1, 0.12), Vector3(0, 0.25, -0.1)))
	var tube := Props.cyl(0.03, 0.03, 0.55, Color(0.98, 0.78, 0.2), Vector3(0.25, 0.45, 0), 8)
	root.add_child(tube)
	root.add_child(Props.cyl(0.04, 0.04, 0.05, Color(0.1, 0.1, 0.12), Vector3(0.25, 0.74, 0), 8))
	return root
