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
## La carte des terres (0.1.13) : MASK_PX × MASK_PX pixels sur ±MASK_HALF_M mètres.
const MASK_PX := 256
const MASK_HALF_M := 72.0

var material: ShaderMaterial
var _near: MeshInstance3D
var _far: MeshInstance3D


func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = OceanShader
	# 0.1.13 : l'eau ne se montre jamais à l'intérieur de l'île (un trou creusé près du niveau de
	# la mer laissait passer le haut des vagues).
	material.set_shader_parameter("land_mask", land_mask(GameState.terrain, GameState.config.sea_level_y + GameState.config.land_mask_above_sea_m))
	material.set_shader_parameter("land_mask_half_m", MASK_HALF_M)
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


## La carte des terres : 1 là où le sol d'origine de l'île est plus haut que `above_y` (l'eau
## n'y monte jamais, même avec les vagues), 0 ailleurs. Le shader de l'océan n'y dessine rien :
## un trou creusé dans l'île ne montre pas la mer.
static func land_mask(t: TerrainLogic, above_y: float) -> ImageTexture:
	var img := Image.create(MASK_PX, MASK_PX, false, Image.FORMAT_R8)
	for y in MASK_PX:
		for x in MASK_PX:
			var wx := (float(x) + 0.5) / MASK_PX * 2.0 * MASK_HALF_M - MASK_HALF_M
			var wz := (float(y) + 0.5) / MASK_PX * 2.0 * MASK_HALF_M - MASK_HALF_M
			img.set_pixel(x, y, Color(1, 1, 1) if t.base_height(wx, wz) > above_y else Color(0, 0, 0))
	return ImageTexture.create_from_image(img)
