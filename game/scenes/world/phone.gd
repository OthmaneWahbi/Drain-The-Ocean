extends StaticBody3D
## Le téléphone rouge. Quand il sonne, il tremble et affiche « Dring ! » ; E décroche
## (GameState.answer_phone). Le premier appel est un tutoriel muet : musique d'attente, puis une
## caisse tombe avec le catalogue papier. Une offre ouvre le catalogue avec l'article du jour.
## Sinon, E ouvre simplement le catalogue.

var _body: Node3D
var _ring_label: Label3D
var _t := 0.0
## Temps restant de musique d'attente (premier appel), pour l'invite.
var _hold_left := 0.0


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	_body.add_child(Greybox.box(Vector3(0.9, 2.2, 0.9), Greybox.PHONE_RED, Vector3(0, 1.1, 0)))
	_body.add_child(Greybox.box(Vector3(0.35, 0.12, 0.12), Color(0.1, 0.1, 0.1), Vector3(0, 1.4, 0.5)))
	add_child(Greybox.box_collision(Vector3(0.9, 2.2, 0.9), Vector3(0, 1.1, 0)))
	_ring_label = Label3D.new()
	_ring_label.text = tr("PHONE_RING")
	_ring_label.font_size = 64
	_ring_label.pixel_size = 0.006
	_ring_label.outline_size = 12
	_ring_label.modulate = Color(1.0, 0.9, 0.3)
	_ring_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_ring_label.position = Vector3(0, 2.9, 0)
	add_child(_ring_label)
	GameState.phone_answered.connect(_on_answered)


func _process(delta: float) -> void:
	_t += delta
	_hold_left = maxf(_hold_left - delta, 0.0)
	var ringing := GameState.phone.is_ringing()
	_ring_label.visible = ringing and fmod(_t, 1.2) < 0.8
	# Il tremble par à-coups, comme un vieux téléphone qui sonne.
	_body.rotation.z = sin(_t * 60.0) * 0.04 if ringing and fmod(_t, 1.2) < 0.8 else 0.0


func get_prompt(_player: Node) -> String:
	if _hold_left > 0.0:
		return tr("PHONE_HOLD_MUSIC")
	match GameState.phone.ringing:
		PhoneLogic.Ring.TUTORIAL, PhoneLogic.Ring.OFFER:
			return tr("PROMPT_PHONE_ANSWER")
	return tr("PROMPT_PHONE")


func interact(_player: Node) -> void:
	if _hold_left > 0.0:
		return
	if GameState.phone.is_ringing():
		GameState.answer_phone()
		return
	get_tree().call_group(&"catalogue", &"open_catalogue")


func _on_answered(reason: int) -> void:
	match reason:
		PhoneLogic.Ring.TUTORIAL:
			_hold_left = GameState.config.hold_music_s
		PhoneLogic.Ring.OFFER:
			get_tree().call_group(&"catalogue", &"open_catalogue")
