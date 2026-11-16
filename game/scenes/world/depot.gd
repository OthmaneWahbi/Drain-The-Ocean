extends StaticBody3D
## La palette de dépôt. On y pose ce qu'on porte : ça devient le stock qui sert à payer.
## Une grande palette avec un emplacement par ressource : chaque tas a sa couleur, sa hauteur
## et son compteur, pour voir d'un coup d'œil ce qu'on a (retour d'Othmane).

const SIZE := Vector3(3.6, 0.15, 1.6)
const COLORS := {
	"sel": Color(0.95, 0.95, 0.92),
	"mineraux": Color(0.62, 0.62, 0.66),
	"mineraux_rares": Color(0.6, 0.3, 0.85),
	"coquillages": Color(0.95, 0.75, 0.7),
	"perles": Color(0.85, 0.95, 1.0),
}

var _piles: Dictionary = {}  # ressource -> MeshInstance3D
var _labels: Dictionary = {}  # ressource -> Label3D


func _ready() -> void:
	add_child(Greybox.box(SIZE, Greybox.WOOD, Vector3(0, SIZE.y / 2.0, 0)))
	add_child(Greybox.box_collision(Vector3(SIZE.x, 0.5, SIZE.z), Vector3(0, 0.25, 0)))
	var n := Economy.RESOURCES.size()
	var slot := SIZE.x / n
	for i in n:
		var r: String = Economy.RESOURCES[i]
		var x := -SIZE.x / 2.0 + slot * (i + 0.5)
		var pile := Greybox.box(Vector3(slot * 0.8, 1.0, SIZE.z * 0.6), COLORS[r], Vector3(x, 0, 0))
		add_child(pile)
		_piles[r] = pile
		# Le nombre au-dessus du tas (toujours face au joueur), le nom peint sur le devant de la palette.
		var label := Label3D.new()
		label.position = Vector3(x, 0.3, 0)
		label.font_size = 40
		label.pixel_size = 0.004
		label.outline_size = 8
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
		_labels[r] = label
		var name_label := Label3D.new()
		name_label.text = tr("RES_" + r.to_upper())
		name_label.position = Vector3(x, SIZE.y / 2.0, SIZE.z / 2.0 + 0.01)
		name_label.font_size = 18
		name_label.pixel_size = 0.004
		name_label.modulate = Color(0.12, 0.08, 0.04)
		name_label.outline_size = 0
		name_label.width = slot / 0.004
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(name_label)
	GameState.stock_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for r in _piles:
		var count := int(GameState.stock.get(r, 0))
		var pile: MeshInstance3D = _piles[r]
		pile.visible = count > 0
		var h := pile_height(count)
		pile.scale = Vector3(1, h, 1)
		pile.position.y = SIZE.y + h / 2.0
		var label: Label3D = _labels[r]
		label.text = str(count)
		label.position.y = SIZE.y + h + 0.25
		label.modulate = Color(1, 1, 1, 1.0 if count > 0 else 0.4)


## Hauteur d'un tas : grandit vite au début puis ralentit (logarithme), plafonnée à 1,5 m.
static func pile_height(count: int) -> float:
	if count <= 0:
		return 0.0
	return clampf(0.08 + log(1.0 + count) / log(10.0) * 0.35, 0.08, 1.5)


func get_prompt(_player: Node) -> String:
	var n := GameState.carried_count()
	if n > 0:
		return tr("PROMPT_DEPOT") % n
	return tr("DEPOT_STATE") % Economy.count(GameState.stock)


func interact(_player: Node) -> void:
	GameState.unload_to_stock()
