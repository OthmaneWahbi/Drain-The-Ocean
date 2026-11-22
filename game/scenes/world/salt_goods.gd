class_name SaltGoods
extends RefCounted
## Les modèles de la 0.1.22 (PRD §19.29), en facettes comme le reste (Props) : la lousse des
## paludiers, les objets « chic » (parasol rayé, flamant en sel rose, salière géante), les
## surprises de l'agence (bouée canard, nain en coquillages, caisse cadeau), l'affiche des
## commandes et le baromètre de la cabine. Utilisés par les vues et les photos du catalogue.

const WOOD := Color(0.62, 0.43, 0.25)
const WOOD_DARK := Color(0.42, 0.28, 0.16)
const STRIPE_A := Color(0.93, 0.27, 0.3)
const STRIPE_B := Color(0.99, 0.96, 0.9)
const ROSE := Color(0.97, 0.7, 0.76)
const ROSE_DARK := Color(0.86, 0.5, 0.6)
const DUCK := Color(1.0, 0.84, 0.2)
const BEAK := Color(1.0, 0.55, 0.15)
const GIFT := Color(0.9, 0.25, 0.35)
const RIBBON := Color(1.0, 0.85, 0.3)
const PAPER := Color(0.98, 0.95, 0.86)
const INK := Color(0.16, 0.12, 0.1)
const BRASS := Color(0.85, 0.66, 0.3)


## La lousse : un long manche et une planchette au bout, pour pousser la fleur de sel.
static func lousse() -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.beam(Vector3(0, 0.05, -0.9), Vector3(0, 0.05, 0.75), 0.04, WOOD, true))
	root.add_child(Props.box(Vector3(0.42, 0.12, 0.03), WOOD_DARK, Vector3(0, 0.08, -0.92)))
	root.add_child(Props.box(Vector3(0.38, 0.02, 0.05), Color(0.95, 0.95, 0.92), Vector3(0, 0.02, -0.93)))
	return root


## Un parasol rayé planté dans le sable (2 m de large).
static func parasol() -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.cyl(0.03, 0.03, 2.1, Color(0.9, 0.9, 0.88), Vector3(0, 1.05, 0), 8))
	var panels := 8
	for i in panels:
		var a0 := TAU * i / panels
		var a1 := TAU * (i + 1) / panels
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var top := Vector3(0, 2.15, 0)
		var p0 := Vector3(cos(a0) * 0.98, 1.75, sin(a0) * 0.98)
		var p1 := Vector3(cos(a1) * 0.98, 1.75, sin(a1) * 0.98)
		st.set_normal((p1 - top).cross(p0 - top).normalized())
		st.add_vertex(top)
		st.add_vertex(p1)
		st.add_vertex(p0)
		var mi := Props._mesh(st.commit(), STRIPE_A if i % 2 == 0 else STRIPE_B, true)
		root.add_child(mi)
	root.add_child(Props.ball(0.05, Color(0.9, 0.9, 0.88), Vector3(0, 2.18, 0), 3))
	return root


## Un flamant en sel rose : un bloc de sel taillé en flamant, sur un socle.
static func salt_flamingo() -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.box(Vector3(0.6, 0.12, 0.45), ROSE_DARK, Vector3(0, 0.06, 0)))
	for side in [-0.06, 0.06]:
		root.add_child(Props.cyl(0.025, 0.025, 0.55, ROSE_DARK, Vector3(side, 0.4, 0), 6))
	root.add_child(Props.ball(0.2, ROSE, Vector3(0, 0.78, 0), 4, 0.05, Vector3(1.3, 0.85, 0.9)))
	root.add_child(Props.beam(Vector3(0.18, 0.82, 0), Vector3(0.24, 1.2, 0), 0.06, ROSE, true))
	root.add_child(Props.ball(0.08, ROSE, Vector3(0.24, 1.24, 0), 5))
	root.add_child(Props.beam(Vector3(0.3, 1.24, 0), Vector3(0.4, 1.16, 0), 0.04, INK, true))
	return root


## Une salière géante (1 m), pleine de fleur de sel et de sel rose.
static func salt_shaker() -> Node3D:
	var root := Node3D.new()
	var glass := Props.cyl(0.28, 0.32, 0.8, Color(0.85, 0.95, 1.0, 0.45), Vector3(0, 0.4, 0), 12)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.85, 0.95, 1.0, 0.4)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.material_override = gm
	root.add_child(glass)
	root.add_child(Props.cyl(0.26, 0.29, 0.35, STRIPE_B, Vector3(0, 0.18, 0), 12))
	root.add_child(Props.cyl(0.25, 0.26, 0.2, ROSE, Vector3(0, 0.45, 0), 12))
	root.add_child(Props.cyl(0.22, 0.3, 0.22, Props.METAL, Vector3(0, 0.91, 0), 12))
	root.add_child(Props.ball(0.12, Props.METAL, Vector3(0, 1.02, 0), 5, 0.0, Vector3(1.8, 0.6, 1.8)))
	for i in 5:
		var a := TAU * i / 5
		root.add_child(Props.cyl(0.02, 0.02, 0.02, INK, Vector3(cos(a) * 0.1, 1.07, sin(a) * 0.1), 5))
	return root


## La bouée canard (surprise de l'agence).
static func duck_buoy() -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.torus(0.18, 0.4, DUCK, Vector3(0, 0.12, 0), 14))
	root.add_child(Props.beam(Vector3(0.3, 0.15, 0), Vector3(0.34, 0.45, 0), 0.12, DUCK, true))
	root.add_child(Props.ball(0.14, DUCK, Vector3(0.36, 0.52, 0), 6))
	root.add_child(Props.box(Vector3(0.14, 0.04, 0.1), BEAK, Vector3(0.52, 0.5, 0)))
	for side in [-1.0, 1.0]:
		root.add_child(Props.ball(0.025, INK, Vector3(0.45, 0.58, side * 0.07), 2))
	return root


## Le nain de jardin en coquillages (surprise de l'agence).
static func shell_gnome() -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.cyl(0.18, 0.22, 0.3, Color(0.3, 0.45, 0.75), Vector3(0, 0.15, 0), 10))
	root.add_child(Props.ball(0.13, Props.SKIN, Vector3(0, 0.4, 0), 7))
	root.add_child(Props.cyl(0.0, 0.15, 0.32, STRIPE_A, Vector3(0, 0.62, 0), 10))
	root.add_child(Props.ball(0.12, STRIPE_B, Vector3(0, 0.3, 0.07), 8, 0.0, Vector3(1.0, 1.2, 0.6)))
	for i in 6:
		var a := TAU * i / 6
		var sh := Props.shell(i, 0.09)
		sh.position = Vector3(cos(a) * 0.21, 0.08 + 0.1 * (i % 2), sin(a) * 0.21)
		sh.rotation.y = -a
		root.add_child(sh)
	return root


## Une caisse cadeau (l'affiche des commandes, la caisse surprise).
static func gift_box(size := 0.4) -> Node3D:
	var root := Node3D.new()
	root.add_child(Props.box(Vector3(size, size * 0.8, size), GIFT, Vector3(0, size * 0.4, 0)))
	root.add_child(Props.box(Vector3(size * 1.02, size * 0.82, size * 0.16), RIBBON, Vector3(0, size * 0.41, 0)))
	root.add_child(Props.box(Vector3(size * 0.16, size * 0.82, size * 1.02), RIBBON, Vector3(0, size * 0.41, 0)))
	for side in [-1.0, 1.0]:
		var bow := Props.ball(size * 0.15, RIBBON, Vector3(side * size * 0.14, size * 0.86, 0), 3, 0.0, Vector3(1.4, 0.7, 0.8))
		root.add_child(bow)
	return root


## Le baromètre de la cabine : un cadran en laiton, cinq cases de couleur (du beau au mauvais) et
## une aiguille (nœud « Needle ») qui pointe le temps du jour. Face vers +Z.
static func barometer() -> Node3D:
	var root := Node3D.new()
	var rim := Props.cyl(0.2, 0.2, 0.05, BRASS, Vector3.ZERO, 16)
	rim.rotation.x = PI / 2
	root.add_child(rim)
	var face := Props.cyl(0.17, 0.17, 0.02, PAPER, Vector3(0, 0, 0.02), 16)
	face.rotation.x = PI / 2
	root.add_child(face)
	var colors := [Color(1.0, 0.55, 0.2), Color(1.0, 0.85, 0.3), Color(0.55, 0.8, 0.95), Color(0.65, 0.68, 0.72), Color(0.35, 0.45, 0.65)]
	for i in colors.size():
		var a := barometer_angle(i, colors.size())
		var dot := Props.ball(0.025, colors[i], Vector3(sin(a) * 0.13, cos(a) * 0.13, 0.035), 2)
		root.add_child(dot)
	var needle := Node3D.new()
	needle.name = "Needle"
	needle.position.z = 0.04
	needle.add_child(Props.box(Vector3(0.012, 0.12, 0.01), INK, Vector3(0, 0.055, 0)))
	needle.add_child(Props.ball(0.018, BRASS, Vector3.ZERO, 2))
	root.add_child(needle)
	return root


## L'angle (radians, 0 = en haut, sens des aiguilles) de la case `i` sur `n` du baromètre.
static func barometer_angle(i: int, n: int) -> float:
	var span := deg_to_rad(200.0)
	return -span / 2.0 + span * (float(i) + 0.5) / float(maxi(n, 1))
