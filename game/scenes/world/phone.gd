extends StaticBody3D
## La cabine téléphonique de l'Agence (0.1.2). Quand le téléphone sonne, la cabine tremble et
## « Driiing ! » s'affiche au-dessus. Face à la cabine, E décroche et ouvre une conversation
## (DialogueBox) :
##  - premier appel : Ginette se présente, puis musique d'attente, puis la caisse du catalogue ;
##  - appel d'offre : l'article du jour, avec « Montrez-moi ça ! » qui ouvre le catalogue ;
##  - sinon on appelle l'Agence : commander (catalogue), poser une question, raccrocher.
## Le catalogue ne s'ouvre QUE d'ici : il est enchaîné dans la cabine, pas posé au sol.

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
	# La cabine est pleine (on n'entre pas dedans : pas de piège possible).
	var col := Greybox.box_collision(Vector3(BOOTH_HALF * 2, 2.6, BOOTH_HALF * 2), Vector3(0, 1.3, 0))
	col.rotation.y = _booth.rotation.y
	add_child(col)
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
	_shake.get_node("Phone/Handset").position.y = absf(sin(_t * 45.0)) * 0.03 if burst else 0.0


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
