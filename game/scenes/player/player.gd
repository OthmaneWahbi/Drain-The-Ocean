extends CharacterBody3D
## Joueur greybox : marcher, courir, sauter, regarder à la souris,
## vue à la 1re personne avec bascule en 3e personne (Q-13, M-19, M-20).
## Endurance, nage et outils arriveront au jalon M2.

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
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _ready() -> void:
	_apply_view()


func _unhandled_input(event: InputEvent) -> void:
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
	elif Input.is_action_just_pressed(&"jump"):
		velocity.y = jump_velocity

	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed(&"sprint") else walk_speed
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
