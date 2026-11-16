class_name OceanView
extends Node3D
## La surface de l'océan, à sa hauteur honnête (GameState.water_level_y, M1).
## Deux maillages avec le même shader de vagues (shaders/ocean.gdshader) :
##  - un carré finement découpé autour de la caméra, où les vagues bougent vraiment ;
##  - un très grand plan, 2 cm plus bas, jusqu'à l'horizon (les vagues y sont éteintes).
## Les deux suivent la caméra à l'horizontale, alignés sur une grille pour que les vagues,
## calculées en coordonnées du monde, ne « glissent » pas.

const OceanShader := preload("res://scenes/world/shaders/ocean.gdshader")

## Taille du carré de vagues (m) et nombre de subdivisions.
const NEAR_SIZE := 160.0
const NEAR_SUBDIV := 159
const FAR_SIZE := 12000.0

var material: ShaderMaterial
var _near: MeshInstance3D
var _far: MeshInstance3D


func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = OceanShader
	var near_mesh := PlaneMesh.new()
	near_mesh.size = Vector2(NEAR_SIZE, NEAR_SIZE)
	near_mesh.subdivide_width = NEAR_SUBDIV
	near_mesh.subdivide_depth = NEAR_SUBDIV
	near_mesh.material = material
	_near = MeshInstance3D.new()
	_near.name = "Near"
	_near.mesh = near_mesh
	_near.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Les sommets bougent : on agrandit la boîte englobante pour ne pas être coupé à tort.
	_near.extra_cull_margin = 2.0
	add_child(_near)
	var far_mesh := PlaneMesh.new()
	far_mesh.size = Vector2(FAR_SIZE, FAR_SIZE)
	far_mesh.material = material
	_far = MeshInstance3D.new()
	_far.name = "Far"
	_far.mesh = far_mesh
	_far.position.y = -0.02
	_far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_far)


func _process(_delta: float) -> void:
	position.y = GameState.water_level_y()
	var cam := get_viewport().get_camera_3d()
	if cam:
		_near.position.x = snappedf(cam.global_position.x, 1.0)
		_near.position.z = snappedf(cam.global_position.z, 1.0)
		_far.position.x = snappedf(cam.global_position.x, 100.0)
		_far.position.z = snappedf(cam.global_position.z, 100.0)
