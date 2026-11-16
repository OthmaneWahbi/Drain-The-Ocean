extends CharacterBody3D
## Joueur greybox : marcher, courir, sauter, regarder à la souris,
## vue à la 1re personne avec bascule en 3e personne (Q-13, M-19, M-20).
## M2 : le seau (puiser, verser, vider), la visée des objets et l'interaction (E).
## Endurance, faim, soif et nage arrivent au jalon suivant.

## Portée de la main, en mètres (comptée depuis la caméra à la 1re personne).
@export var reach: float = 3.0

@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.0
@export var jump_velocity: float = 4.2
@export var mouse_sensitivity: float = 0.0025
@export var acceleration: float = 12.0

@onready var head: Node3D = $Head
@onready var fp_camera: Camera3D = $Head/FirstPersonCamera
@onready var tp_camera: Camera3D = $Head/SpringArm/ThirdPersonCamera
@onready var body_mesh: MeshInstance3D = $BodyMesh

var third_person: bool = false
## Objet visé (zone de séchage, téléphone, palette, caisse…), ou null.
var target: Node = null
## Texte d'aide affiché par le HUD (« [Clic] Verser », etc.).
var prompt: String = ""
var _bucket_water: MeshInstance3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _ready() -> void:
	add_to_group(&"player")
	_build_bucket()
	_apply_view()


func _build_bucket() -> void:
	# Le seau tenu en main : visible en 1re comme en 3e personne.
	var bucket := Node3D.new()
	bucket.position = Vector3(0.38, -0.42, -0.65)
	head.add_child(bucket)
	bucket.add_child(Greybox.cylinder(0.14, 0.26, Greybox.ROCK, Vector3.ZERO, 12))
	_bucket_water = Greybox.cylinder(0.12, 0.02, Greybox.WATER, Vector3(0, 0.11, 0), 12)
	bucket.add_child(_bucket_water)


func _unhandled_input(event: InputEvent) -> void:
	if GameState.ui_open:
		return
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed(&"toggle_view"):
		third_person = not third_person
		_apply_view()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * mouse_sensitivity, deg_to_rad(-85.0), deg_to_rad(85.0))


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed(&"jump") and not GameState.ui_open:
		velocity.y = jump_velocity

	var input := Vector2.ZERO
	if not GameState.ui_open:
		input = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed(&"sprint") else walk_speed  # M-31 : le seau ne ralentit pas
	var target := direction * speed
	var weight := clampf(acceleration * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, target.x, weight)
	velocity.z = lerpf(velocity.z, target.z, weight)
	move_and_slide()


func _apply_view() -> void:
	fp_camera.current = not third_person
	tp_camera.current = third_person
	# En 1re personne, on cache le corps pour ne pas voir l'intérieur de la capsule.
	body_mesh.visible = third_person


func _process(delta: float) -> void:
	_bucket_water.visible = not GameState.bucket.is_empty()
	if GameState.ui_open or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		GameState.bucket.cancel_fill()
		prompt = ""
		return
	target = _find_target()
	prompt = target.get_prompt(self) if target else ""
	_handle_tool(delta)
	if Input.is_action_just_pressed(&"interact") and target and target.has_method(&"interact"):
		target.interact(self)


## Logique du seau. Priorité : l'objet visé (zone de séchage), puis la mer, puis vider le seau.
func _handle_tool(delta: float) -> void:
	var bucket := GameState.bucket
	if target and target.has_method(&"use"):
		bucket.cancel_fill()
		if Input.is_action_just_pressed(&"use_tool"):
			target.use(self)
		return
	if is_in_water() and not bucket.is_full():
		prompt = tr("PROMPT_FILL")
		if Input.is_action_pressed(&"use_tool"):
			if bucket.hold_fill(delta):
				GameState.fill_bucket()
		else:
			bucket.cancel_fill()
		return
	bucket.cancel_fill()
	if not bucket.is_empty() and prompt == "":
		prompt = tr("PROMPT_POUR_OUT")
		if Input.is_action_just_pressed(&"use_tool"):
			GameState.pour_bucket_out()


## Les pieds sont sous le niveau de la mer : on peut puiser.
func is_in_water() -> bool:
	return global_position.y < GameState.config.sea_level_y - 0.05


## Rayon tiré depuis le centre de l'écran pour trouver ce que le joueur vise.
func _find_target() -> Node:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return null
	var length := reach + (spring_length() if third_person else 0.0)
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * length
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var collider: Node = hit.collider
	return collider if collider.has_method(&"get_prompt") else null


func spring_length() -> float:
	return ($Head/SpringArm as SpringArm3D).spring_length
