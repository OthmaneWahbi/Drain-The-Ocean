extends StaticBody3D
## La cabine téléphonique de l'Agence (0.1.2). Quand le téléphone sonne, la cabine tremble et
## « Driiing ! » s'affiche au-dessus. Face à la cabine, E décroche et ouvre une conversation
## (DialogueBox) :
##  - premier appel : Ginette se présente, puis musique d'attente, puis la caisse du catalogue ;
##  - appel d'offre : l'article du jour, avec « Montrez-moi ça ! » qui ouvre le catalogue ;
##  - sinon on appelle l'Agence : commander (catalogue), poser une question, raccrocher.
## Le catalogue ne s'ouvre QUE d'ici : il est enchaîné dans la cabine, pas posé au sol.
## 0.1.10 : on entre dans la cabine, et le combiné vient à l'oreille pendant l'appel.

const BOOTH_HALF := 0.66

var _booth: Node3D
var _shake: Node3D
var _catalogue: Node3D
var _ring_label: Label3D
var _t := 0.0
## Temps restant de musique d'attente (premier appel), pour l'invite.
var _hold_left := 0.0
## La conversation en cours (on ne redécroche pas tant qu'elle dure ; la sonnerie se tait).
var _in_call := false
var _call_ended_at := -10.0
## Le combiné : il vient jusqu'à l'oreille du joueur pendant l'appel (0.1.10, remarque 10).
var _handset: Node3D
var _handset_rest: Transform3D
## 0 = raccroché, 1 = à l'oreille.
var _handset_t := 0.0
var _cord: MeshInstance3D
const HANDSET_TIME_S := 0.35


## Les murs de la cabine (taille, centre), dans le repère de la cabine (ouverture vers +Z).
static func booth_walls() -> Array:
	var h := BOOTH_HALF
	return [
		[Vector3(h * 2, 2.6, 0.08), Vector3(0, 1.3, -h + 0.04)],  # le fond
		[Vector3(0.08, 2.6, h * 2), Vector3(-h + 0.04, 1.3, 0)],  # côté gauche
		[Vector3(0.08, 2.6, h * 2), Vector3(h - 0.04, 1.3, 0)],  # côté droit
		[Vector3(h * 2, 0.3, h * 2), Vector3(0, 2.75, 0)],  # le toit
	]


func _ready() -> void:
	add_to_group(&"phone_booth")
	_booth = Models.phone_booth()
	add_child(_booth)
	_shake = _booth.get_node("Shake")
	_catalogue = _shake.get_node("Catalogue")
	# L'ouverture de la cabine regarde le centre de l'île.
	var to_center := Vector3(-global_position.x, 0.0, -global_position.z) if is_inside_tree() else Vector3.BACK
	if to_center.length() > 0.1:
		_booth.rotation.y = atan2(to_center.x, to_center.z)
	# 0.1.10 (remarque 10) : on entre dans la cabine. Trois murs fins (le fond et les côtés), le
	# toit, et le côté ouvert qui regarde le centre de l'île. La marche du sol est basse : on y monte.
	for wall in booth_walls():
		var col := Greybox.box_collision(wall[0], wall[1])
		col.position = Basis(Vector3.UP, _booth.rotation.y) * col.position
		col.rotation.y = _booth.rotation.y
		add_child(col)
	_handset = _shake.get_node("Phone/Handset")
	_handset_rest = _handset.transform
	_cord = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.008
	cyl.bottom_radius = 0.008
	cyl.height = 1.0
	cyl.radial_segments = 5
	cyl.rings = 1
	_cord.mesh = cyl
	_cord.material_override = Models.flat_material(Color(0.12, 0.12, 0.14))
	_cord.visible = false
	add_child(_cord)
	_ring_label = Label3D.new()
	_ring_label.text = "PHONE_RING"
	_ring_label.font = UiTheme.title_font()
	_ring_label.font_size = 72
	_ring_label.pixel_size = 0.006
	_ring_label.outline_size = 16
	_ring_label.outline_modulate = UiTheme.INK
	_ring_label.modulate = UiTheme.YELLOW
	_ring_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_ring_label.position = Vector3(0, 3.4, 0)
	add_child(_ring_label)
	GameState.phone_answered.connect(_on_answered)


func _process(delta: float) -> void:
	_t += delta
	_hold_left = maxf(_hold_left - delta, 0.0)
	_catalogue.visible = GameState.catalogue_delivered
	var ringing := GameState.phone.is_ringing() and not _in_call
	var burst := ringing and fmod(_t, 1.2) < 0.8
	_ring_label.visible = burst
	# « Driiing ! » saute un peu, et la cabine tremble par à-coups, comme un vieux téléphone.
	_ring_label.position.y = 3.4 + (absf(sin(_t * 18.0)) * 0.12 if burst else 0.0)
	_shake.rotation.z = sin(_t * 60.0) * 0.025 if burst else 0.0
	_update_handset(delta, burst)


## Le combiné : il saute sur son crochet quand ça sonne ; pendant un appel il vient à l'oreille
## (devant la caméra, à droite), relié au téléphone par son fil, puis il revient se raccrocher.
func _update_handset(delta: float, burst: bool) -> void:
	var want := 1.0 if _in_call or _hold_left > 0.0 else 0.0
	_handset_t = move_toward(_handset_t, want, delta / HANDSET_TIME_S)
	var rest: Transform3D = (_handset.get_parent() as Node3D).global_transform * _handset_rest
	if burst and _handset_t <= 0.0:
		rest.origin.y += absf(sin(_t * 45.0)) * 0.03
	# L'oreille : devant la caméra 1re personne du joueur (en 3e personne aussi : c'est sa tête).
	var player := get_tree().get_first_node_in_group(&"player") if is_inside_tree() else null
	var cam: Node3D = player.get_node_or_null("Head/FirstPersonCamera") if player else null
	if _handset_t <= 0.0 or cam == null:
		_handset.global_transform = rest
		_cord.visible = false
		return
	var ear := cam.global_transform * Transform3D(Basis.from_euler(Vector3(0.0, 0.0, -0.5)), Vector3(0.2, -0.1, -0.32))
	var k := smoothstep(0.0, 1.0, _handset_t)
	_handset.global_transform = rest.interpolate_with(ear, k)
	# Le fil : du téléphone au bas du combiné.
	var from := (_handset.get_parent() as Node3D).global_position + Vector3(0, -0.15, 0)
	var to := _handset.global_transform * Vector3(0, -0.17, 0)
	var mid := (from + to) / 2.0
	var length_m := from.distance_to(to)
	_cord.visible = length_m > 0.05
	if _cord.visible:
		var up := (to - from) / length_m
		var side := up.cross(Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD).normalized()
		_cord.global_transform = Transform3D(Basis(side, up, side.cross(up)).scaled_local(Vector3(1, length_m, 1)), mid)


func is_in_call() -> bool:
	return _in_call


func get_prompt(_player: Node) -> String:
	if _hold_left > 0.0:
		return tr("PHONE_HOLD_MUSIC")
	match GameState.phone.ringing:
		PhoneLogic.Ring.TUTORIAL, PhoneLogic.Ring.OFFER:
			return tr("PROMPT_PHONE_ANSWER")
	return tr("PROMPT_PHONE")


func interact(_player: Node) -> void:
	if _hold_left > 0.0 or _in_call:
		return
	# La touche qui a fermé la conversation ne doit pas la rouvrir aussitôt.
	if Time.get_ticks_msec() / 1000.0 - _call_ended_at < 0.4:
		return
	match GameState.phone.ringing:
		PhoneLogic.Ring.TUTORIAL:
			# On décroche vraiment (et la caisse part) à la fin de la conversation.
			_talk("tutorial", [], func(): GameState.answer_phone())
		PhoneLogic.Ring.OFFER:
			GameState.answer_phone()  # l'offre est valable dès qu'on décroche
			var item := GameState.catalog.find(StringName(GameState.phone.offer_item))
			_talk("offer", [tr(item.name_key) if item else "?"])
		_:
			_talk("call" if GameState.catalogue_delivered else "no_catalogue")


func _talk(conv: String, args: Array = [], on_end: Callable = Callable()) -> void:
	var box: DialogueBox = get_tree().get_first_node_in_group(&"dialogue")
	if box == null:
		# Pas d'écran de dialogue (tests, vieille scène) : on va droit au but.
		if on_end.is_valid():
			on_end.call()
		if conv != "tutorial" and GameState.catalogue_delivered:
			open_catalogue()
		return
	_in_call = true
	var ended := func():
		_in_call = false
		_call_ended_at = Time.get_ticks_msec() / 1000.0
		if on_end.is_valid():
			on_end.call()
	box.finished.connect(ended, CONNECT_ONE_SHOT)
	if not box.start(conv, args, _on_action):
		box.finished.disconnect(ended)
		ended.call()


func _on_action(action: String) -> void:
	match action:
		"open_catalogue":
			open_catalogue()


func open_catalogue() -> void:
	get_tree().call_group(&"catalogue", &"open_catalogue")


func _on_answered(reason: int) -> void:
	if reason == PhoneLogic.Ring.TUTORIAL:
		_hold_left = GameState.config.hold_music_s
