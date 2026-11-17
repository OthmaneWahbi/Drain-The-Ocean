extends StaticBody3D
## La palette de dépôt. On y pose ce qu'on porte : ça devient le stock qui sert à payer.
## Une grande palette avec un emplacement par ressource : chaque tas a sa couleur, sa hauteur
## et son compteur, pour voir d'un coup d'œil ce qu'on a (retour d'Othmane). Depuis 0.1.4, les
## tas ressemblent à ce qu'ils contiennent (Props.pile : sel, cailloux à cristaux, gemmes,
## coquillages, perles).

const SIZE := Vector3(3.6, 0.15, 1.6)
## Hauteur du modèle de tas (Props.pile) à l'échelle 1.
const PILE_MODEL_H := 0.45
## Largeur d'un tas à l'échelle 1 (diamètre du monticule).
const PILE_MODEL_W := 0.72

var _piles: Dictionary = {}  # ressource -> Node3D (Props.pile)
var _labels: Dictionary = {}  # ressource -> Label3D


func _ready() -> void:
	add_child(Props.pallet(SIZE))
	add_child(Greybox.box_collision(Vector3(SIZE.x, 0.5, SIZE.z), Vector3(0, 0.25, 0)))
	var n := Economy.RESOURCES.size()
	var slot := SIZE.x / n
	# 0.1.8 : des cloisons basses entre les emplacements, comme un étal : chaque tas a sa case.
	for i in range(1, n):
		var x := -SIZE.x / 2.0 + slot * i
		add_child(Props.box(Vector3(0.05, 0.16, SIZE.z * 0.92), Props.WOOD_DARK, Vector3(x, SIZE.y + 0.08, 0)))
	for i in n:
		var r: String = Economy.RESOURCES[i]
		var x := -SIZE.x / 2.0 + slot * (i + 0.5)
		var pile := Props.pile(r, 40 + i)
		pile.position = Vector3(x, SIZE.y, 0)
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
		# Le nom, peint sur une petite planche crème clouée devant (plus lisible que sur le bois).
		add_child(Props.box(Vector3(slot * 0.8, 0.13, 0.03), Props.CREAM, Vector3(x, SIZE.y / 2.0, SIZE.z / 2.0 + 0.015)))
		var name_label := Label3D.new()
		name_label.text = tr("RES_" + r.to_upper())
		name_label.position = Vector3(x, SIZE.y / 2.0, SIZE.z / 2.0 + 0.035)
		name_label.font_size = 18
		name_label.pixel_size = 0.004
		name_label.modulate = Color(0.12, 0.08, 0.04)
		name_label.outline_size = 0
		name_label.width = slot * 0.8 / 0.004
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(name_label)
	GameState.stock_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for r in _piles:
		var count := int(GameState.stock.get(r, 0))
		var pile: Node3D = _piles[r]
		pile.visible = count > 0
		var h := pile_height(count)
		pile.scale = pile_scale(h, SIZE.x / Economy.RESOURCES.size() * 0.88)  # entre les cloisons
		var label: Label3D = _labels[r]
		label.text = str(count)
		label.position.y = SIZE.y + pile.scale.y * PILE_MODEL_H + 0.25  # juste au-dessus du vrai tas
		label.modulate = Color(1, 1, 1, 1.0 if count > 0 else 0.4)


## Hauteur d'un tas : grandit vite au début puis ralentit (logarithme), plafonnée à 1,5 m.
static func pile_height(count: int) -> float:
	if count <= 0:
		return 0.0
	return clampf(0.08 + log(1.0 + count) / log(10.0) * 0.35, 0.08, 1.5)


## Un tas ne s'étire jamais plus que ça en hauteur par rapport à sa largeur (0.1.6 : au-delà,
## les morceaux posés dessus paraissaient déformés).
const PILE_MAX_STRETCH := 1.15


## L'échelle d'un tas de hauteur `h` : il grandit d'un bloc jusqu'à remplir sa place sur la
## palette (`max_width`), puis à peine en hauteur (le compteur dit le reste). Jamais étiré.
static func pile_scale(h: float, max_width: float) -> Vector3:
	var k := h / PILE_MODEL_H
	var kw := minf(k, max_width / PILE_MODEL_W)
	return Vector3(kw, minf(k, kw * PILE_MAX_STRETCH), kw)


func get_prompt(_player: Node) -> String:
	var n := GameState.carried_count()
	if n > 0:
		return tr("PROMPT_DEPOT") % n
	return tr("DEPOT_STATE") % Economy.count(GameState.stock)


func interact(_player: Node) -> void:
	GameState.unload_to_stock()


## La palette se déplace comme les autres objets (G) ; son état vit dans GameState.depot.
func get_movable() -> Dictionary:
	return GameState.depot
