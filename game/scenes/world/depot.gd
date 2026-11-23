extends StaticBody3D
## La palette de dépôt. On y pose ce qu'on porte : ça devient le stock qui sert à payer.
## Une grande palette avec un emplacement par ressource : chaque tas a sa couleur, sa hauteur
## et son compteur, pour voir d'un coup d'œil ce qu'on a (retour d'Othmane). Depuis 0.1.4, les
## tas ressemblent à ce qu'ils contiennent (Props.pile : sel, cailloux à cristaux, gemmes,
## coquillages, perles). 0.1.10 : deux palettes KayKit et un bac en bois par matériau.

const SIZE := Vector3(3.6, 0.15, 1.6)
## Hauteur des bacs posés sur la palette (0.1.10).
const BIN_H := 0.2
## Hauteur du modèle de tas (Props.pile) à l'échelle 1.
const PILE_MODEL_H := 0.45
## Largeur d'un tas à l'échelle 1 (diamètre du monticule).
const PILE_MODEL_W := 0.72

var _piles: Dictionary = {}  # ressource -> Node3D (Props.pile)
var _labels: Dictionary = {}  # ressource -> PaintedText (le compteur peint)


func _ready() -> void:
	# 0.1.10 (remarque 7) : deux palettes en bois de KayKit (Resource Bits, CC0) côte à côte, et
	# dessus un bac en bois par matériau, comme ceux des zones de séchage : le tas grossit DANS
	# son bac, son nom et son compteur sont peints sur une planchette clouée devant.
	for sx in [-1, 1]:
		var pal := Props.fit_model("kaykit_pallet_wood", Vector3(SIZE.x / 2.0 - 0.04, SIZE.y, SIZE.z))
		pal.position.x = sx * SIZE.x / 4.0
		add_child(pal)
	add_child(Greybox.box_collision(Vector3(SIZE.x, 0.5, SIZE.z), Vector3(0, 0.25, 0)))
	var n := Economy.RESOURCES.size()
	var slot := SIZE.x / n
	for i in n:
		var r: String = Economy.RESOURCES[i]
		var x := -SIZE.x / 2.0 + slot * (i + 0.5)
		var bin := Props.bin(slot * 0.92, BIN_H)
		bin.position = Vector3(x, SIZE.y, 0)
		add_child(bin)
		var pile := Props.pile(r, 40 + i)
		pile.position = Vector3(x, SIZE.y + 0.03, 0)
		add_child(pile)
		_piles[r] = pile
		# Le nom et le compteur, peints sur une planchette crème clouée devant le bac (avant, le
		# compteur flottait au-dessus du tas et avait l'air collé sur l'image).
		var sign_z := slot * 0.46 + 0.012
		var sign_y := SIZE.y + BIN_H * 0.5
		add_child(Props.box(Vector3(slot * 0.78, 0.19, 0.02), Props.CREAM, Vector3(x, sign_y, sign_z)))
		var name_label := PaintedText.new("RES_" + r.to_upper(), Color(0.12, 0.08, 0.04), PaintedText.Style.PRINT)
		name_label.font_size = 16
		name_label.position = Vector3(x, sign_y + 0.05, sign_z + 0.014)
		name_label.max_width = slot * 0.72
		add_child(name_label)
		var label := PaintedText.new("", UiTheme.INK, PaintedText.Style.PRINT)
		label.font = UiTheme.title_font()
		label.font_size = 30
		label.position = Vector3(x, sign_y - 0.03, sign_z + 0.014)
		label.max_width = slot * 0.72
		label.dynamic = true
		add_child(label)
		_labels[r] = label
	GameState.stock_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for r in _piles:
		var count := int(GameState.stock.get(r, 0))
		var pile: Node3D = _piles[r]
		pile.visible = count > 0
		var h := pile_height(count)
		pile.scale = pile_scale(h, SIZE.x / Economy.RESOURCES.size() * 0.86)  # dans son bac
		var label: PaintedText = _labels[r]
		label.text = str(count)
		label.color = Color(UiTheme.INK, 1.0 if count > 0 else 0.35)


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
