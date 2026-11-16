class_name ProductPhoto
extends SubViewportContainer
## La « photo » d'un produit du catalogue : un mini studio 3D (son propre monde) avec le modèle
## de ProductModels sur un plateau tournant. Il ne se dessine que quand on le voit.

const TURN_SPEED := 0.6

var item_id := ""
var _spin: Node3D
var _viewport: SubViewport


func _init(p_id: String = "", photo_size := Vector2i(190, 130)) -> void:
	item_id = p_id
	stretch = true
	custom_minimum_size = Vector2(photo_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.size = photo_size
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_viewport)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1.0, 0.96, 0.88)
	env.environment.ambient_light_energy = 0.55
	_viewport.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, 35, 0)
	key.light_energy = 1.1
	_viewport.add_child(key)
	# Le plateau tournant (un disque crème cerclé d'encre) et le produit dessus.
	_spin = Node3D.new()
	_viewport.add_child(_spin)
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.95
	cyl.bottom_radius = 1.0
	cyl.height = 0.08
	cyl.radial_segments = 24
	disc.mesh = cyl
	var m := StandardMaterial3D.new()
	m.albedo_color = UiTheme.PAPER_DARK
	disc.material_override = m
	disc.position = Vector3(0, -0.04, 0)
	_spin.add_child(disc)
	var model := ProductModels.build(item_id)
	_spin.add_child(model)
	_fit(model)
	_spin.rotation.y = -0.6
	var cam := Camera3D.new()
	cam.fov = 32
	_viewport.add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.55, 3.4), Vector3(0, 0.42, 0))


## Met le produit à la taille du plateau (environ 1,6 m de large, 1,1 m de haut).
func _fit(model: Node3D) -> void:
	var box := Models.bounds(Models.vertices(model))
	var k := minf(1.6 / maxf(maxf(box.size.x, box.size.z), 0.01), 1.1 / maxf(box.size.y, 0.01))
	model.scale = Vector3.ONE * k
	model.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * k


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_spin.rotation.y += delta * TURN_SPEED
