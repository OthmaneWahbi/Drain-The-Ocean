extends StaticBody3D
## La palette de dépôt. On y pose ce qu'on porte : ça devient le stock qui sert à payer.

var _pile: MeshInstance3D


func _ready() -> void:
	add_child(Greybox.box(Vector3(1.2, 0.15, 1.2), Greybox.WOOD, Vector3(0, 0.075, 0)))
	add_child(Greybox.box_collision(Vector3(1.2, 0.4, 1.2), Vector3(0, 0.2, 0)))
	_pile = Greybox.box(Vector3(1.0, 1.0, 1.0), Greybox.SALT)
	add_child(_pile)
	GameState.stock_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	# Le tas grandit avec le stock (affichage par paliers, PRD §16.3).
	var n := Economy.count(GameState.stock)
	_pile.visible = n > 0
	var h := clampf(0.1 + n * 0.01, 0.1, 1.2)
	_pile.scale = Vector3(1, h, 1)
	_pile.position.y = 0.15 + h * 0.5


func get_prompt(_player: Node) -> String:
	var n := GameState.carried_count()
	if n > 0:
		return tr("PROMPT_DEPOT") % n
	return tr("DEPOT_STATE") % Economy.count(GameState.stock)


func interact(_player: Node) -> void:
	GameState.unload_to_stock()
