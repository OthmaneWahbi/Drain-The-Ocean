class_name PetCrab
extends StaticBody3D
## Pinçon, le crabe de compagnie (0.1.19, PRD §19.25). Il remplace le crabe de décor : un crabe
## articulé fait ici, en facettes (8 pattes à deux segments, 2 pinces à doigt mobile, 2 yeux au
## bout de tiges avec paupières, bouche, joues), animé par CrabPose. Il se promène au bord de la
## plage, vient saluer le joueur, le suit quand il l'aime bien, dort la nuit. E : une croquette
## s'il a faim, sinon une caresse. Ses règles (faim, affection, accessoires) sont dans
## GameState.pet (CrabPetLogic) : cette vue ne fait qu'afficher et demander.

const RED := Color(0.93, 0.33, 0.2)
const RED_DARK := Color(0.72, 0.2, 0.12)
const BELLY := Color(0.98, 0.72, 0.5)
const WHITE := Color(0.98, 0.97, 0.94)
const BLACK := Color(0.07, 0.05, 0.08)
const BLUSH := Color(1.0, 0.52, 0.6)
const STRAW := Color(0.93, 0.8, 0.45)
const HEART := Color(1.0, 0.36, 0.52)
const TREAT := Color(0.62, 0.4, 0.2)
## Hauteur du centre du corps au repos.
const BODY_H := 0.15
## Durée des réactions (s).
const REACTION_S := {CrabPose.Anim.EAT: 2.4, CrabPose.Anim.HAPPY: 1.8, CrabPose.Anim.REFUSE: 1.3, CrabPose.Anim.WAVE: 1.8}

## L'animation en cours (lue par les tests et les captures).
var anim: CrabPose.Anim = CrabPose.Anim.IDLE

var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _target: Vector3
var _rest := 0.0
var _reaction: CrabPose.Anim = CrabPose.Anim.IDLE
var _reaction_left := 0.0
var _greeted := false
var _fx_cooldown := 0.0

var _body: Node3D
var _legs: Array[Node3D] = []
var _knees: Array[Node3D] = []
var _shoulders: Array[Node3D] = []
var _fingers: Array[Node3D] = []
var _stalks: Array[Node3D] = []
var _pupils: Array[Node3D] = []
var _lids: Array[Node3D] = []
var _lower_lids: Array[Node3D] = []
var _mouth: Node3D
var _cheeks: Array[Node3D] = []
var _hat: Node3D
var _glasses: Array[Node3D] = []
var _treat: Node3D
var _zzz: Array[Label3D] = []
var _fx_root: Node3D


func _init(seed_value := 99) -> void:
	_rng.seed = seed_value


func _ready() -> void:
	name = "PetCrab"
	PhysicsLayers.make_walk_through(self)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.55, 0.35, 0.45)
	shape.shape = box
	shape.position.y = 0.17
	add_child(shape)
	_build()
	position = AmbientMotion.ring_point(_rng, _cfg().pet_wander_min_r, _cfg().pet_wander_max_r, 0.0)
	position.y = _ground(position)
	_target = position
	GameState.pet_changed.connect(_refresh_accessories)
	GameState.pet_reacted.connect(react)
	_refresh_accessories()
	apply_pose(CrabPose.pose(anim, 0.0))


func _cfg() -> GameConfig:
	return GameState.config


func _ground(p: Vector3) -> float:
	return GameState.terrain.height(p.x, p.z)


# --- Le modèle articulé --------------------------------------------------------------------

func _build() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	_body.position.y = BODY_H
	add_child(_body)
	# Carapace bombée (un peu plus large que longue), ventre clair, quelques taches.
	_body.add_child(Props.ball(0.17, RED, Vector3(0, 0.01, 0.01), 3, 0.0, Vector3(1.3, 0.62, 1.0)))
	_body.add_child(Props.ball(0.16, BELLY, Vector3(0, -0.035, 0), 4, 0.0, Vector3(1.2, 0.42, 0.95)))
	for s in [Vector3(-0.08, 0.09, 0.04), Vector3(0.09, 0.085, 0.06), Vector3(0.0, 0.1, 0.09)]:
		_body.add_child(Props.ball(0.022, RED_DARK, s, 5, 0.0, Vector3(1, 0.4, 1)))
	# Bouche (qui s'ouvre en mangeant) et joues roses.
	_mouth = Props.ball(0.022, BLACK, Vector3(0, -0.005, -0.16), 6, 0.0, Vector3(1.4, 0.5, 0.6))
	_body.add_child(_mouth)
	for side in [-1.0, 1.0]:
		var cheek := Props.ball(0.022, BLUSH, Vector3(side * 0.085, 0.015, -0.145), 7, 0.0, Vector3(1.2, 0.6, 0.4))
		_body.add_child(cheek)
		_cheeks.append(cheek)
	for side in [-1.0, 1.0]:
		_build_eye(side)
		_build_claw(side)
		for k in CrabPose.LEGS_PER_SIDE:
			_build_leg(side, k)
	# Les accessoires (cachés tant qu'ils ne sont pas achetés).
	_hat = make_hat()
	_hat.position = Vector3(0.0, 0.1, 0.07)
	_hat.scale = Vector3.ONE * 1.2
	_hat.rotation = Vector3(0.12, 0.0, -0.15)
	_body.add_child(_hat)
	# La croquette tenue en mangeant, dans la pince gauche.
	_treat = Props.ball(0.025, TREAT, Vector3(0, 0.0, -0.06), 9)
	_treat.visible = false
	_fingers[0].get_parent().add_child(_treat)
	# Trois « z » qui montent l'un après l'autre quand il dort.
	for k in 3:
		var z := Label3D.new()
		z.text = "Z" if k == 1 else "z"
		z.font = UiTheme.title_font()
		z.font_size = 64
		z.pixel_size = 0.003
		z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		z.no_depth_test = true
		z.modulate = Color(0.95, 0.97, 1.0)
		z.outline_modulate = Color(0.2, 0.25, 0.45)
		z.outline_size = 12
		z.visible = false
		add_child(z)
		_zzz.append(z)
	_fx_root = Node3D.new()
	_fx_root.top_level = true
	add_child(_fx_root)
	for mi: MeshInstance3D in Models.meshes_of(self):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if mi.mesh.get_aabb().size.length() < 0.06 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## Un œil : une tige qui pivote à sa base, un gros œil blanc, une pupille qui regarde, un reflet,
## une paupière du haut (clignement, sommeil) et une du bas (yeux plissés de bonheur).
func _build_eye(side: float) -> void:
	var stalk := Node3D.new()
	stalk.name = "Stalk%d" % (0 if side < 0 else 1)
	stalk.position = Vector3(side * 0.055, 0.06, -0.1)
	stalk.rotation.z = -side * 0.18
	_body.add_child(stalk)
	_stalks.append(stalk)
	stalk.add_child(Props.cyl(0.014, 0.018, 0.12, RED, Vector3(0, 0.06, 0), 6))
	var eye := Node3D.new()
	eye.position.y = 0.15
	stalk.add_child(eye)
	eye.add_child(Props.ball(0.058, WHITE, Vector3.ZERO, 11))
	var pupil := Node3D.new()
	eye.add_child(pupil)
	pupil.add_child(Props.ball(0.032, BLACK, Vector3(0, 0, -0.037), 12, 0.0, Vector3(1, 1.15, 0.7)))
	pupil.add_child(Props.ball(0.011, WHITE, Vector3(0.012, 0.016, -0.062), 13))
	_pupils.append(pupil)
	_lids.append(_lid(eye, RED))
	_lower_lids.append(_lid(eye, RED))
	var glasses := _make_glasses_lens()
	glasses.position = Vector3(0, 0, -0.066)
	eye.add_child(glasses)
	_glasses.append(glasses)


func _lid(eye: Node3D, color: Color) -> Node3D:
	var pivot := Node3D.new()
	eye.add_child(pivot)
	var mi := MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radius = 0.062
	dome.height = 0.062
	dome.is_hemisphere = true
	dome.radial_segments = 10
	dome.rings = 3
	mi.mesh = dome
	mi.material_override = Props.mat(color)
	pivot.add_child(mi)
	return pivot


## Une pince : épaule (lever, écarter), bras, gros « poing » et doigt mobile qui s'ouvre.
func _build_claw(side: float) -> void:
	var shoulder := Node3D.new()
	shoulder.name = "Claw%d" % (0 if side < 0 else 1)
	shoulder.position = Vector3(side * 0.16, -0.01, -0.09)
	_body.add_child(shoulder)
	_shoulders.append(shoulder)
	var arm_end := Vector3(side * 0.07, 0.02, -0.08)
	shoulder.add_child(Props.beam(Vector3.ZERO, arm_end, 0.035, RED, true))
	var hand := Node3D.new()
	hand.position = arm_end
	hand.rotation.y = -side * 0.35
	shoulder.add_child(hand)
	hand.add_child(Props.ball(0.065, RED, Vector3(0, 0.0, -0.04), 14, 0.0, Vector3(0.9, 0.8, 1.25)))
	# Doigt fixe (en bas) et doigt mobile (en haut), en cônes un peu courbés.
	var fixed := Props.cyl(0.0, 0.026, 0.1, RED_DARK, Vector3(0, -0.015, -0.12), 6)
	fixed.rotation.x = -PI / 2 + 0.15
	hand.add_child(fixed)
	var finger := Node3D.new()
	finger.position = Vector3(0, 0.022, -0.085)
	hand.add_child(finger)
	var upper := Props.cyl(0.0, 0.024, 0.09, RED_DARK, Vector3(0, 0.0, -0.042), 6)
	upper.rotation.x = -PI / 2 - 0.15
	finger.add_child(upper)
	_fingers.append(finger)


## Une patte : hanche (lever, balancer) puis genou ; deux segments fuselés, pointe sombre.
func _build_leg(side: float, k: int) -> void:
	var hip := Node3D.new()
	hip.position = Vector3(side * 0.17, -0.02, -0.06 + k * 0.05)
	# Les pattes s'ouvrent en éventail : celles de devant vers l'avant, celles de derrière vers l'arrière.
	hip.set_meta("splay", side * (0.45 - k * 0.3))
	hip.set_meta("side", side)
	_body.add_child(hip)
	_legs.append(hip)
	var upper_end := Vector3(side * 0.1, 0.0, 0.0)
	hip.add_child(Props.beam(Vector3.ZERO, upper_end, 0.026, RED, true))
	var knee := Node3D.new()
	knee.position = upper_end
	knee.set_meta("side", side)
	hip.add_child(knee)
	_knees.append(knee)
	knee.add_child(Props.beam(Vector3.ZERO, Vector3(side * 0.11, 0.0, 0.0), 0.02, RED, true))
	knee.add_child(Props.cyl(0.0, 0.01, 0.03, RED_DARK, Vector3(side * 0.12, 0.0, 0.0), 5))
	(knee.get_child(1) as Node3D).rotation.z = -side * PI / 2


static func make_hat() -> Node3D:
	var hat := Node3D.new()
	hat.name = "Hat"
	hat.add_child(Props.cyl(0.13, 0.13, 0.012, STRAW, Vector3.ZERO, 14))
	hat.add_child(Props.cyl(0.065, 0.075, 0.065, STRAW, Vector3(0, 0.035, 0), 12))
	hat.add_child(Props.cyl(0.077, 0.077, 0.018, HEART, Vector3(0, 0.014, 0), 12))
	hat.add_child(Props.ball(0.018, Color(1.0, 0.85, 0.2), Vector3(0.07, 0.03, -0.02), 15))
	return hat


const LENS := Color(0.95, 0.2, 0.45)


func _make_glasses_lens() -> Node3D:
	var lens := heart(0.04, LENS)
	lens.rotation.x = PI / 2
	lens.name = "Glasses"
	return lens


## Un petit cœur en volume (deux boules et une pointe), dans le plan XZ, pointe vers +Z.
static func heart(size: float, color: Color) -> Node3D:
	var h := Node3D.new()
	for side in [-1.0, 1.0]:
		h.add_child(Props.ball(size * 0.55, color, Vector3(side * size * 0.42, 0, -size * 0.2), 16, 0.0, Vector3(1, 0.55, 1)))
	var tip := Props.cyl(0.0, size * 0.62, size * 1.05, color, Vector3(0, 0, size * 0.48), 8)
	tip.rotation.x = PI / 2
	tip.scale = Vector3(1, 1, 0.55)
	h.add_child(tip)
	return h


# --- Animation -----------------------------------------------------------------------------

## Applique une pose de CrabPose aux articulations.
func apply_pose(p: Dictionary) -> void:
	_body.position.y = BODY_H + float(p.body_y)
	_body.rotation = Vector3(float(p.body_pitch), float(p.body_yaw), float(p.body_roll))
	_body.scale = Vector3(1.0 / sqrt(float(p.squash)), float(p.squash), 1.0 / sqrt(float(p.squash)))
	for i in _legs.size():
		var hip := _legs[i]
		var side: float = hip.get_meta("side")
		hip.rotation = Vector3(0.0, float(hip.get_meta("splay")) + float(p.leg_swing[i]) * side, side * (0.55 + float(p.leg_lift[i])))
		_knees[i].rotation.z = -side * (1.45 + float(p.knee[i]) - float(p.leg_lift[i]) * 0.4)
	for c in 2:
		var side := -1.0 if c == 0 else 1.0
		_shoulders[c].rotation = Vector3(float(p.claw_raise[c]), -side * float(p.claw_spread[c]), 0.0)
		_fingers[c].rotation.x = float(p.claw_open[c])
		_stalks[c].rotation.x = float(p.stalk_tilt[c])
		var pupil: Vector2 = p.pupil
		_pupils[c].position = Vector3(pupil.x * 0.014, pupil.y * 0.012, 0.0)
		# Yeux plissés de bonheur : les deux paupières se rapprochent et laissent une fente.
		var closed := clampf(maxf(float(p.blink), float(p.happy_eyes) * 0.42), 0.0, 1.0)
		_lids[c].rotation.x = PI / 2 - closed * PI
		_lower_lids[c].rotation.x = PI / 2 + float(p.happy_eyes) * 0.45 * PI
	_mouth.scale = Vector3(1.0, 0.6 + float(p.mouth) * 1.6, 1.0)
	for cheek in _cheeks:
		cheek.scale = Vector3.ONE * (0.8 + float(p.happy_eyes) * 0.5)


func _process(delta: float) -> void:
	_t += delta
	_fx_cooldown = maxf(_fx_cooldown - delta, 0.0)
	anim = _choose_anim(delta)
	apply_pose(CrabPose.pose(anim, _t))
	_treat.visible = anim == CrabPose.Anim.EAT and _reaction_left > 0.8
	for i in _zzz.size():
		var z := _zzz[i]
		z.visible = anim == CrabPose.Anim.SLEEP
		if z.visible:
			var k := fmod(_t * 0.4 + i / 3.0, 1.0)
			z.position = Vector3(0.1 + k * 0.12 + sin(k * TAU) * 0.03, 0.35 + k * 0.35, 0.0)
			z.font_size = int(36 + k * 44)
			z.modulate.a = sin(k * PI)
	_update_fx(delta)
	GameState.pet_position = global_position if is_inside_tree() else position


## Ce que fait le crabe cette image : réaction en cours, sommeil, salut, marche ou repos.
func _choose_anim(delta: float) -> CrabPose.Anim:
	var player := GameState.player_position
	var to_player := Vector3(player.x - position.x, 0.0, player.z - position.z)
	var near := player.is_finite() and to_player.length() < _cfg().pet_greet_distance_m
	if _reaction_left > 0.0:
		_reaction_left -= delta
		_face(to_player, delta, false)
		return _reaction
	var mood := GameState.pet.mood(not GameState.day.is_day())
	if mood == CrabPetLogic.Mood.SLEEPY:
		return CrabPose.Anim.SLEEP
	# Il vient dire bonjour quand on s'approche (une fois par visite).
	if near and not _greeted:
		_greeted = true
		react(CrabPose.Anim.WAVE)
		return CrabPose.Anim.WAVE
	if not near and to_player.length() > _cfg().pet_greet_distance_m * 1.5:
		_greeted = false
	if near:
		_face(to_player, delta, false)
		return CrabPose.Anim.HUNGRY if mood == CrabPetLogic.Mood.HUNGRY else CrabPose.Anim.IDLE
	if _rest > 0.0:
		_rest -= delta
		return CrabPose.Anim.HUNGRY if mood == CrabPetLogic.Mood.HUNGRY else CrabPose.Anim.IDLE
	var to := _target - position
	to.y = 0.0
	if to.length() < 0.1:
		_pick_target(player)
		_rest = _rng.randf_range(1.5, 4.5)
		return CrabPose.Anim.IDLE
	var step := to.normalized() * minf(_cfg().pet_speed * delta, to.length())
	var next := position + step
	# Jamais dans la mer : il s'arrête au bord.
	if _ground(next) < GameState.water_level_y() + 0.05:
		_target = position
		return CrabPose.Anim.IDLE
	position = next
	position.y = _ground(position)
	_face(to, delta, true)
	return CrabPose.Anim.WALK


## Où aller ensuite : près du joueur s'il l'aime bien (2 cœurs et plus) et que le joueur n'est
## pas loin ; sinon un point au bord de la plage, à quelques pas.
func _pick_target(player: Vector3) -> void:
	if player.is_finite() and GameState.pet.hearts() >= 2 and Vector2(player.x - position.x, player.z - position.z).length() < 12.0:
		var a := _rng.randf_range(0.0, TAU)
		_target = player + Vector3(cos(a), 0.0, sin(a)) * 1.6
	else:
		_target = AmbientMotion.ring_point(_rng, _cfg().pet_wander_min_r, _cfg().pet_wander_max_r, 0.0)
		_target = position + (_target - position).limit_length(4.0)
	_target.y = position.y


## Tourne en douceur : de face (vers `dir`) ou de côté pour marcher, comme un vrai crabe.
func _face(dir: Vector3, delta: float, sideways: bool) -> void:
	if dir.length() < 0.01:
		return
	var want := atan2(-dir.z, dir.x) if sideways else atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, want, clampf(delta * 6.0, 0.0, 1.0))


## Joue une réaction (mange, refuse, content, salut) quelques instants.
func react(which: int) -> void:
	_reaction = which as CrabPose.Anim
	_reaction_left = REACTION_S.get(which, 1.5)
	_rest = maxf(_rest, 1.0)
	if which == CrabPose.Anim.HAPPY or which == CrabPose.Anim.EAT:
		_burst_hearts(3 if which == CrabPose.Anim.HAPPY else 2)


func _refresh_accessories() -> void:
	_hat.visible = GameState.pet.has_accessory("chapeau")
	for g in _glasses:
		g.visible = GameState.pet.has_accessory("lunettes")


# --- Petits effets : cœurs qui montent, miettes --------------------------------------------

func _burst_hearts(n: int) -> void:
	if _fx_root == null:
		return
	for i in n:
		var h := heart(0.05, HEART)
		h.rotation = Vector3(-PI / 2, 0.0, 0.0)
		h.set_meta("age", -i * 0.25)
		h.set_meta("drift", Vector3(_rng.randf_range(-0.15, 0.15), 0.0, _rng.randf_range(-0.15, 0.15)))
		h.position = global_position + Vector3(0, 0.45, 0) if is_inside_tree() else position + Vector3(0, 0.45, 0)
		h.visible = false
		_fx_root.add_child(h)


func _update_fx(delta: float) -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	for h: Node3D in _fx_root.get_children():
		var age: float = h.get_meta("age") + delta
		h.set_meta("age", age)
		if age < 0.0:
			continue
		if age > 1.4:
			h.queue_free()
			continue
		h.visible = true
		h.position += (Vector3(0, 0.45, 0) + h.get_meta("drift")) * delta
		h.scale = Vector3.ONE * (minf(age * 6.0, 1.0) * (1.0 - maxf(age - 1.0, 0.0) * 2.0) + 0.01)
		if cam:
			# Le cœur se tourne vers la caméra (pointe en bas).
			h.look_at(cam.global_position, Vector3.UP, true)
			h.rotate_object_local(Vector3.RIGHT, -PI / 2)


# --- Interaction (E) -----------------------------------------------------------------------

func get_prompt(_player: Node) -> String:
	var pet := GameState.pet
	var pet_name := tr("PET_NAME")
	var action: String
	if pet.wants_food() and pet.treats > 0:
		action = tr("PROMPT_PET_FEED") % [pet_name, pet.treats]
	elif pet.mood(false) == CrabPetLogic.Mood.HUNGRY:
		action = tr("PROMPT_PET_NO_TREATS") % pet_name
	else:
		action = tr("PROMPT_PET_PET") % pet_name
	var mood_key: String = ["PET_MOOD_HAPPY", "PET_MOOD_CONTENT", "PET_MOOD_HUNGRY", "PET_MOOD_SLEEPY"][pet.mood(not GameState.day.is_day())]
	return "%s · %s · %s" % [action, hearts_text(pet.hearts(), pet.hearts_count), tr(mood_key)]


static func hearts_text(full: int, total: int) -> String:
	return "♥".repeat(full) + "♡".repeat(maxi(total - full, 0))


func interact(_player: Node) -> void:
	GameState.interact_pet()
