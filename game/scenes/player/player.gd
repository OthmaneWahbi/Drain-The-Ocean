extends CharacterBody3D
## Joueur greybox : marcher, courir, sauter, regarder à la souris,
## vue à la 1re personne avec bascule en 3e personne (Q-13, M-19, M-20).
## M2 : le seau (puiser, verser, vider), la visée des objets et l'interaction (E).
## Nage et endurance (M-24, N-04, N-05) : on flotte, on nage, on se hisse sur le rivage ;
## l'endurance ne remonte jamais dans l'eau, et à zéro on se noie (retour sur la plage, sans perte).

## Portée de la main, en mètres (comptée depuis la caméra à la 1re personne).
@export var reach: float = 3.0

@export var jump_velocity: float = 4.2
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
var _bucket_node: Node3D
var _rake_node: Node3D
var _shovel_node: Node3D
## Le coup de pelle en cours (0..1, -1 sans coup) et son sens (creuser ou remblayer).
var _swing_t := -1.0
var _swing_dig := true
## 0.1.11 : la pelle tenue à mi-manche, la lame devant soi, un peu relevée. Avant, la lame
## était à 1,9 m devant l'œil et passait sous le sable dès qu'on regardait par terre.
const SHOVEL_REST := Vector3(0.41, -0.61, 0.01)
const SHOVEL_REST_ROT := Vector3(11, 12.3, 0)
const SWING_S := 0.32
## Le matériau porté, montré en main : un petit bac avec son tas (0.1.10, remarque 4).
var _carry_node: Node3D
var _carry_kind := ""
var _second_bucket: Node3D
## Le personnage vu en 3e personne (Kenney, Mini Characters), animé (0.1.4).
var _body: Node3D
## Le niveau d'eau affiché dans les seaux (rejoint le vrai en douceur) et l'horloge des gouttes.
var _shown_fill := 0.0
var _drip_t := 0.0
var _big_bucket := false
## Vrai quand le personnage nage (pieds assez loin sous la surface).
var swimming: bool = false
var _drowning: bool = false
var _fade: ColorRect
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
## Balancement de la tête (M-21) : hauteur de repos de la tête et horloge de marche.
var _head_rest_y: float = 0.0
var _walk_time: float = 0.0
## Anti-blocage : détecte qu'on est coincé et cherche une place libre.
var _unstuck: UnstuckLogic
var _last_position: Vector3


func _ready() -> void:
	add_to_group(&"player")
	_head_rest_y = head.position.y
	# On ne se cogne qu'aux objets solides ; tas, tuyaux et coquillages se traversent.
	collision_layer = PhysicsLayers.SOLID
	collision_mask = PhysicsLayers.SOLID
	_unstuck = UnstuckLogic.new(GameState.config.unstuck_check_after_s)
	_last_position = global_position
	_build_bucket()
	_build_fade()
	_apply_view()
	GameState.terrain_changed.connect(_on_terrain_changed)
	GameState.shovel_changed.connect(_on_shovel_changed)
	_on_shovel_changed()


## Le matériau tenu (sel, minéraux…) : un petit bac porté à deux mains, avec un tas qui grossit
## avec la quantité portée. Reconstruit quand on change de matériau.
func _update_carry(tool: String) -> void:
	var kind := tool if Economy.RESOURCES.has(tool) else ""
	if kind != _carry_kind:
		_carry_kind = kind
		if _carry_node:
			_carry_node.queue_free()
			_carry_node = null
		if kind != "":
			_carry_node = Node3D.new()
			_carry_node.position = Vector3(0.0, -0.36, -0.58)
			_carry_node.rotation_degrees = Vector3(38, 0, 0)
			_carry_node.add_child(Props.bin(0.36, 0.12))
			var pile := Props.pile(kind, 90)
			pile.name = "Pile"
			pile.position.y = 0.02
			_carry_node.add_child(pile)
			head.add_child(_carry_node)
	if _carry_node:
		var ratio := float(GameState.carried.get(kind, 0)) / maxf(GameState.carry_capacity, 1.0)
		var k := lerpf(0.32, 0.48, clampf(ratio, 0.0, 1.0))
		(_carry_node.get_node("Pile") as Node3D).scale = Vector3(k, k, k)


## Le sable a bougé (pelle) : si le sol monte sous nos pieds, on remonte avec lui.
## Le sable porté sur la lame de la pelle (0.1.11).
func _on_shovel_changed() -> void:
	Props.set_shovel_load(_shovel_node, float(GameState.shovel_sand) / maxf(GameState.config.shovel_capacity_scoops, 1), GameState.shovel_soil == TerrainLogic.Soil.EARTH)


## Un coup de pelle (0.1.11, appelé par SandFx) : la pelle plonge vers le sable puis remonte
## (creuser), ou se lève puis bascule vers l'avant (remblayer).
func swing_shovel(dig: bool) -> void:
	_swing_t = 0.0
	_swing_dig = dig


## Le bout de la lame, dans le monde (là où part et arrive la motte de sable).
func shovel_tip() -> Vector3:
	return _shovel_node.to_global(Vector3(0, 0.03, -1.0))


func _animate_shovel(delta: float) -> void:
	if _swing_t < 0.0:
		return
	_swing_t += delta / SWING_S
	var t := minf(_swing_t, 1.0)
	# Une bosse : 0 → 1 → 0, plus rapide à l'aller.
	var k := sin(PI * pow(t, 0.7))
	if _swing_dig:
		_shovel_node.position = SHOVEL_REST + Vector3(-0.02, -0.08, -0.18) * k
		_shovel_node.rotation_degrees = SHOVEL_REST_ROT + Vector3(-16.0, 0.0, 4.0) * k
	else:
		_shovel_node.position = SHOVEL_REST + Vector3(-0.02, 0.07, -0.1) * k
		_shovel_node.rotation_degrees = SHOVEL_REST_ROT + Vector3(-6.0, 0.0, -22.0) * k
	if _swing_t >= 1.0:
		_swing_t = -1.0
		_shovel_node.position = SHOVEL_REST
		_shovel_node.rotation_degrees = SHOVEL_REST_ROT


func _on_terrain_changed(_corners: Array) -> void:
	var ground := GameState.terrain.height(global_position.x, global_position.z)
	if global_position.y < ground + 0.02:
		global_position.y = ground + 0.05


func _build_bucket() -> void:
	# Le seau tenu en main (Props.bucket : seau en bois KayKit rafistolé, ou teinté jaune pour le grand seau), visible en
	# 1re comme en 3e personne ; son eau monte avec le remplissage (PRD §15 : un plan qui monte).
	_bucket_node = Node3D.new()
	_bucket_node.position = Vector3(0.38, -0.55, -0.65)
	head.add_child(_bucket_node)
	# Le second seau de la palanche, à gauche.
	_second_bucket = Node3D.new()
	_second_bucket.position = Vector3(-0.38, -0.55, -0.65)
	head.add_child(_second_bucket)
	_rebuild_buckets()
	# Le râteau, tenu quand on le choisit dans la barre d'outils (M-27).
	_rake_node = Props.rake()
	_rake_node.position = Vector3(0.35, -0.35, -0.4)
	_rake_node.rotation_degrees = Vector3(-30, 0, 0)
	head.add_child(_rake_node)
	# La pelle (0.1.10), tenue lame en avant, un peu baissée.
	_shovel_node = Props.shovel()
	_shovel_node.position = SHOVEL_REST
	_shovel_node.rotation_degrees = SHOVEL_REST_ROT
	head.add_child(_shovel_node)
	# Le corps en 3e personne : un petit personnage CC0 qui marche, court, saute (PRD §13).
	body_mesh.visible = false
	_body = Props.character("mini_male_a", 1.75, "idle")
	_body.rotation.y = PI  # les personnages regardent +Z, le joueur avance vers −Z
	add_child(_body)


## Le seau change de modèle quand on reçoit le grand seau.
func _rebuild_buckets() -> void:
	_big_bucket = GameState.bucket_unit_l > GameState.config.starting_bucket_capacity_l
	for holder: Node3D in [_bucket_node, _second_bucket]:
		for c in holder.get_children():
			c.queue_free()
		holder.add_child(Props.bucket(_big_bucket, 0.3 if _big_bucket else 0.26))


## Le niveau d'eau des seaux : la vraie quantité, plus la montée pendant qu'on puise.
func _update_bucket_water(delta: float) -> void:
	if (GameState.bucket_unit_l > GameState.config.starting_bucket_capacity_l) != _big_bucket:
		_rebuild_buckets()
	var b := GameState.bucket
	var ratio := b.water_l / maxf(b.capacity_l, 0.001)
	ratio += (1.0 - ratio) * b.fill_progress_ratio()  # pendant qu'on puise, l'eau monte déjà
	_shown_fill = lerpf(_shown_fill, ratio, clampf(delta * 8.0, 0.0, 1.0))
	for holder: Node3D in [_bucket_node, _second_bucket]:
		if holder.get_child_count() > 0:
			Props.set_bucket_fill(holder.get_child(-1), _shown_fill)
	# Quelques gouttes tombent quand on marche avec un seau plein (M-32 : purement visuelles).
	_drip_t -= delta
	var walking := Vector2(velocity.x, velocity.z).length() > 0.5
	if _bucket_node.visible and _shown_fill > 0.3 and walking and _drip_t <= 0.0:
		_drip_t = randf_range(0.25, 0.6)
		_drip(_bucket_node.global_position + Vector3(randf_range(-0.1, 0.1), 0.25, randf_range(-0.1, 0.1)))


func _drip(from: Vector3) -> void:
	var world := get_parent()
	if world == null:
		return
	var drop := Props.droplet(0.025)
	world.add_child(drop)
	drop.global_position = from
	var t := drop.create_tween()
	t.tween_property(drop, "global_position:y", from.y - 1.2, 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(drop.queue_free)


## L'animation du corps (3e personne) selon ce que fait le joueur.
func _animate_body() -> void:
	if not _body.visible:
		return
	var flat := Vector2(velocity.x, velocity.z).length()
	if swimming:
		Props.play(_body, "walk", 0.6)
	elif not is_on_floor():
		Props.play(_body, "jump" if velocity.y > 0.0 else "fall")
	elif flat > GameState.config.walk_speed * 1.2:
		Props.play(_body, "sprint", clampf(flat / GameState.config.sprint_speed, 0.8, 1.5))
	elif flat > 0.4:
		# 0.1.17 : les pas suivent la vitesse (tongs, démarrage, arrêt) : les pieds ne glissent plus.
		Props.play(_body, "walk", clampf(1.3 * flat / GameState.config.walk_speed, 0.5, 1.8))
	else:
		Props.play(_body, "idle")


func _build_fade() -> void:
	# Écran noir de la noyade (N-04).
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


func _unhandled_input(event: InputEvent) -> void:
	if GameState.ui_open:
		return
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return
	if not GameState.placing and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and _handle_toolbar_input(event):
		return
	# Échap ouvre le menu pause (PauseMenu), qui libère la souris.
	if event.is_action_pressed(&"toggle_view"):
		third_person = not third_person
		_apply_view()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := Settings.data.mouse_sensitivity  # option du joueur (M-21)
		rotate_y(-event.relative.x * sens)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * sens, deg_to_rad(-85.0), deg_to_rad(85.0))


func _physics_process(delta: float) -> void:
	GameState.player_position = global_position
	var cfg := GameState.config
	var water_y := GameState.water_level_y()
	# 0.1.14 : au fond d'un trou à l'intérieur de l'île, il n'y a pas de mer (on ne nage pas).
	swimming = global_position.y < water_y - cfg.swim_depth_m and GameState.sea_at(global_position.x, global_position.z)

	var input := Vector2.ZERO
	if not GameState.ui_open and not _drowning:
		input = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var stamina := GameState.stamina
	var wants_sprint := Input.is_action_pressed(&"sprint") and input != Vector2.ZERO and not swimming
	var running := wants_sprint and stamina.can_run()

	var speed: float
	if swimming:
		speed = cfg.swim_speed
		_swim_vertical(delta, water_y, input)
	else:
		speed = (cfg.sprint_speed if running else cfg.walk_speed) * GameState.speed_multiplier  # M-31 : le seau ne ralentit pas
		if not is_on_floor():
			velocity.y -= _gravity * delta
			# Fin de l'escalade du rivage : on continue de se hisser tant que les pieds sont dans l'eau.
			if is_on_wall() and input.y < 0.0 and global_position.y < water_y:
				velocity.y = cfg.swim_climb_velocity
		elif Input.is_action_just_pressed(&"jump") and not GameState.ui_open and not _drowning:
			velocity.y = jump_velocity

	var target_velocity := direction * speed
	var weight := clampf(acceleration * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, target_velocity.x, weight)
	velocity.z = lerpf(velocity.z, target_velocity.z, weight)
	move_and_slide()
	_update_head_bob(delta, speed)
	var moved := Vector2(global_position.x - _last_position.x, global_position.z - _last_position.z).length()
	_last_position = global_position
	if _unstuck.update(delta, input != Vector2.ZERO and not swimming and not _drowning, moved) and is_trapped():
		free_from_trap()

	# Endurance (N-05) : elle ne remonte qu'à l'arrêt sur la terre ferme.
	var activity := StaminaLogic.Activity.WALK_ON_LAND
	if swimming:
		activity = StaminaLogic.Activity.SWIM
	elif running:
		activity = StaminaLogic.Activity.RUN
	elif input == Vector2.ZERO and is_on_floor():
		activity = StaminaLogic.Activity.REST_ON_LAND
	stamina.step(delta, activity)
	if swimming and stamina.is_empty() and not _drowning:
		_drown()


## Flottaison : on remonte doucement jusqu'à avoir la tête hors de l'eau. Espace pousse vers le haut.
## Contre un bord (rivage), avancer fait se hisser hors de l'eau.
func _swim_vertical(delta: float, water_y: float, input: Vector2) -> void:
	var cfg := GameState.config
	var float_y := water_y - cfg.float_depth_m
	var target_vy := clampf((float_y - global_position.y) * 3.0, -2.0, 2.0)
	if Input.is_action_pressed(&"jump") and not _drowning:
		target_vy = maxf(target_vy, 1.5)
	# 0.1.21 : avec le masque, Ctrl fait plonger (sans masque, on remonte toujours).
	elif GameState.has_gear("masque") and InputMap.has_action(&"dive") and Input.is_action_pressed(&"dive") and not _drowning:
		target_vy = -cfg.dive_speed
	if is_on_wall() and input.y < 0.0:
		target_vy = cfg.swim_climb_velocity
	velocity.y = lerpf(velocity.y, target_vy, clampf(6.0 * delta, 0.0, 1.0))


## 0.1.21 : s'endormir dans le hamac : fondu au noir, `on_dark` (la nuit passe), fondu retour.
func sleep_fade(on_dark: Callable) -> void:
	if _drowning:
		return
	_drowning = true  # plus de contrôle pendant le fondu
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 1.0)
	tween.tween_callback(on_dark)
	tween.tween_interval(0.8)
	tween.tween_property(_fade, "color:a", 0.0, 1.0)
	tween.tween_callback(func(): _drowning = false)


## Noyade (N-04) : écran noir, retour sur la plage, rien n'est perdu.
func _drown() -> void:
	_drowning = true
	var cfg := GameState.config
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, cfg.drown_fade_s)
	tween.tween_callback(func():
		rescue()  # sur la plage, à côté si quelque chose bloque le point de retour
		GameState.stamina.refill()
		GameState.register_wakeup())  # un trait de plus sur le palmier
	tween.tween_interval(0.6)
	tween.tween_property(_fade, "color:a", 0.0, cfg.drown_fade_s)
	tween.tween_callback(func(): _drowning = false)


## Coincé : aucune des 8 directions ne laisse avancer de `UnstuckLogic.ESCAPE_M` (plus que la
## largeur du personnage). Contre un simple mur, on peut toujours partir de côté ou en arrière.
func is_trapped() -> bool:
	return _trapped_at(global_transform)


## Coincé si le joueur était à cette place (sert aussi à ne pas le reposer dans la même prison).
func _trapped_at(xform: Transform3D) -> bool:
	var free: Array = []
	# On teste un peu au-dessus du sol : les petites bosses du terrain ne comptent pas comme des murs.
	var raised := xform.translated(Vector3(0, UnstuckLogic.STEP_M, 0))
	for dir in UnstuckLogic.probe_directions(UnstuckLogic.ESCAPE_M):
		free.append(not test_move(raised, dir))
	return UnstuckLogic.is_trapped(free)


## Se pose sur la place libre la plus proche (avec du sol dessous), sinon retour sur la plage.
func free_from_trap() -> void:
	var spot: Variant = find_free_spot(global_position, false)
	if spot == null:
		rescue()
	else:
		_teleport(spot)


## Retour sur la plage (bouton « Me débloquer » du menu pause, ou si rien d'autre ne marche).
## Si un objet a été posé sur le point de retour, on se met à côté.
func rescue() -> void:
	var home := GameState.config.respawn_position
	var spot: Variant = find_free_spot(home, true)
	_teleport(spot if spot != null else home)


## Place libre la plus proche de `origin` pour la capsule du joueur, avec du sol dessous.
## Renvoie null s'il n'y en a pas dans le rayon de recherche.
func find_free_spot(origin: Vector3, include_origin: bool) -> Variant:
	var cfg := GameState.config
	var col := $Collision as CollisionShape3D
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = col.shape
	query.collision_mask = PhysicsLayers.SOLID
	query.exclude = [get_rid()]
	var spots: Array[Vector3] = []
	if include_origin:
		spots.append(origin)
	spots.append_array(UnstuckLogic.candidates(origin, cfg.unstuck_step_m, cfg.unstuck_search_m))
	for spot in spots:
		# D'abord le sol sous la place (le terrain n'est pas plat partout), puis la capsule posée dessus.
		var down := PhysicsRayQueryParameters3D.create(spot + Vector3(0, 1.0, 0), spot + Vector3(0, -3.0, 0), PhysicsLayers.SOLID, [get_rid()])
		var ground := space.intersect_ray(down)
		if ground.is_empty():
			continue  # pas de sol : on ne se jette pas à l'eau
		var feet: Vector3 = ground.position
		if feet.y < GameState.water_level_y() - 0.3 and GameState.sea_at(feet.x, feet.z):
			continue  # sous l'eau : pas une place de secours
		query.transform = Transform3D(Basis.IDENTITY, feet + col.position + Vector3(0, UnstuckLogic.STEP_M, 0))
		if not space.intersect_shape(query, 1).is_empty():
			continue
		# Une place libre mais fermée (au milieu d'un enclos de tuyaux, 0.1.6) n'en est pas une.
		if _trapped_at(Transform3D(global_transform.basis, feet + Vector3(0, 0.05, 0))):
			continue
		return feet
	return null


func _teleport(spot: Vector3) -> void:
	global_position = spot + Vector3(0, 0.05, 0)
	velocity = Vector3.ZERO
	_last_position = global_position


## Balancement de la tête en marchant sur la terre ferme (M-21, désactivable dans les options).
## Le champ de vision des options est appliqué ici aussi.
func _update_head_bob(delta: float, speed: float) -> void:
	fp_camera.fov = Settings.data.fov
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	var ratio := ground_speed / maxf(speed, 0.01) if is_on_floor() and not swimming else 0.0
	if ratio > 0.1:
		_walk_time += delta * (1.0 + ratio * 0.4)
	else:
		_walk_time = 0.0
	var target_y := _head_rest_y + SettingsLogic.bob_offset(_walk_time, ratio, Settings.data.head_bob)
	head.position.y = lerpf(head.position.y, target_y, clampf(delta * 12.0, 0.0, 1.0))


func _apply_view() -> void:
	fp_camera.current = not third_person
	tp_camera.current = third_person
	# En 1re personne, le corps ne se dessine pas (on verrait l'intérieur de la tête), mais il
	# garde son ombre au sol (0.1.10, remarque 9 : le joueur a une ombre).
	_body.visible = true
	var mode := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if third_person else GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	for mi in _body.find_children("*", "GeometryInstance3D", true, false):
		(mi as GeometryInstance3D).cast_shadow = mode


## Barre d'outils : 1-6 choisit une case, la molette passe à la suivante (M-18, M-27).
func _handle_toolbar_input(event: InputEvent) -> bool:
	for i in GameState.toolbar.slots.size():
		if InputMap.has_action(StringName("tool_%d" % (i + 1))) and event.is_action_pressed(StringName("tool_%d" % (i + 1))):
			GameState.select_tool(i)
			return true
	if event.is_action_pressed(&"tool_next"):
		GameState.cycle_tool(1)
		return true
	if event.is_action_pressed(&"tool_prev"):
		GameState.cycle_tool(-1)
		return true
	return false


## 0.1.20 : le point visé (sable compris), pour verser dans un trou.
var aim_point := Vector3.ZERO
var aim_on_terrain := false


func _process(delta: float) -> void:
	var tool := GameState.current_tool()
	_bucket_node.visible = tool == "seau"
	_rake_node.visible = tool == "rateau"
	_shovel_node.visible = tool == "pelle"
	_animate_shovel(delta)
	_update_carry(tool)
	_second_bucket.visible = tool == "seau" and GameState.bucket_count > 1
	_update_bucket_water(delta)
	_animate_body()
	if GameState.placing:
		target = null  # 0.1.8 : jamais une cible périmée (l'objet a pu disparaître entre-temps)
		return  # le mode déplacement (PlacementController) gère la souris et le texte d'aide
	if GameState.ui_open or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		target = null
		GameState.bucket.cancel_fill()
		prompt = ""
		return
	target = _find_target()
	prompt = target.get_prompt(self) if target else ""
	if target and target.has_method(&"get_movable"):
		prompt = tr("PROMPT_MOVE") if prompt == "" else "%s · %s" % [prompt, tr("PROMPT_MOVE")]
	_handle_tool(delta)
	if Input.is_action_just_pressed(&"interact") and target and target.has_method(&"interact"):
		target.interact(self)


## Logique du seau. Priorité : l'objet visé (zone de séchage), puis la mer, puis vider le seau.
func _handle_tool(delta: float) -> void:
	var bucket := GameState.bucket
	# Clic MAINTENU sur un objet qui le gère (la pompe à bras) : appelé à chaque image.
	if target and target.has_method(&"hold_use"):
		bucket.cancel_fill()
		if Input.is_action_pressed(&"use_tool"):
			target.hold_use(self, delta)
		return
	if target and target.has_method(&"use"):
		bucket.cancel_fill()
		if Input.is_action_just_pressed(&"use_tool"):
			target.use(self)
		return
	# Puiser et vider : seulement avec le seau en main.
	if GameState.current_tool() != "seau":
		bucket.cancel_fill()
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
	# 0.1.20 : verser dans un trou creusé à la pelle en fait un marais salant.
	if not bucket.is_empty() and prompt == "" and aim_on_terrain and not GameState.hole_region_at(aim_point).is_empty():
		prompt = tr("PROMPT_POUR_HOLE")
		if Input.is_action_just_pressed(&"use_tool"):
			GameState.pour_bucket_into_hole(aim_point)
		return
	if not bucket.is_empty() and prompt == "":
		prompt = tr("PROMPT_POUR_OUT")
		if Input.is_action_just_pressed(&"use_tool"):
			GameState.pour_bucket_out()


## Les pieds sont sous la surface de l'océan : on peut puiser (en marchant ou en nageant).
func is_in_water() -> bool:
	return global_position.y < GameState.water_level_y() - 0.05 and GameState.sea_at(global_position.x, global_position.z)


## Rayon tiré depuis le centre de l'écran pour trouver ce que le joueur vise.
func _find_target() -> Node:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return null
	var length := reach + (spring_length() if third_person else 0.0)
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * length
	var query := PhysicsRayQueryParameters3D.create(from, to, PhysicsLayers.AIM)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	aim_on_terrain = false
	if hit.is_empty():
		return null
	var collider: Node = hit.collider
	aim_point = hit.position
	aim_on_terrain = collider is TerrainView
	return collider if collider.has_method(&"get_prompt") else null


func spring_length() -> float:
	return ($Head/SpringArm as SpringArm3D).spring_length
