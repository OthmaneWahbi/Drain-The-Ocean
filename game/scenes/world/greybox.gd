class_name Greybox
extends RefCounted
## Petites fabriques de formes greybox (aucun asset, M-06). Partagées par toutes les vues.

const SAND := Color(0.74, 0.66, 0.48)
const ROCK := Color(0.5, 0.5, 0.52)
const WOOD := Color(0.45, 0.33, 0.22)
const WATER := Color(0.1, 0.45, 0.7, 0.8)
const SALT := Color(0.95, 0.95, 0.92)
const TARP := Color(0.3, 0.45, 0.6)
const PHONE_RED := Color(0.8, 0.08, 0.08)


static func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	m.metallic_specular = 0.1
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.1
		m.metallic_specular = 0.6
	return m


static func box(size: Vector3, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material(color)
	mi.mesh = mesh
	mi.position = pos
	return mi


static func cylinder(radius: float, height: float, color: Color, pos := Vector3.ZERO, sides := 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	mesh.material = material(color)
	mi.mesh = mesh
	mi.position = pos
	return mi


static func box_collision(size: Vector3, pos := Vector3.ZERO) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = pos
	return cs


static func cylinder_collision(radius: float, height: float, pos := Vector3.ZERO) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	cs.shape = shape
	cs.position = pos
	return cs
