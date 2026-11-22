class_name AgencyBoard
extends Node3D
## Sur la cabine (0.1.22, PRD §19.29) : l'affiche de la commande de l'agence, en pictogrammes
## (un petit tas par ressource demandée, son nombre, une flèche, une caisse cadeau ; « MERCI ! »
## une fois envoyée), et le baromètre à aiguille qui montre le temps du jour.
## Aucune règle : tout se lit dans GameState (agency_order, weather).

const POSTER_W := 1.0
const POSTER_H := 0.8

var _poster: Node3D
var _content: Node3D
var _needle: Node3D
var _needle_angle := 0.0


## Hauteur du centre de l'affiche (le nœud est au pied du poteau).
const POSTER_Y := 1.75


func _ready() -> void:
	# Le poteau, planté dans le sable, et un petit toit de planches au-dessus de l'affiche.
	add_child(Props.cyl(0.05, 0.06, POSTER_Y + POSTER_H / 2.0 + 0.1, SaltGoods.WOOD_DARK, Vector3(0, (POSTER_Y + POSTER_H / 2.0 + 0.1) / 2.0, -0.05), 7))
	add_child(Props.box(Vector3(POSTER_W + 0.16, 0.04, 0.2), SaltGoods.WOOD, Vector3(0, POSTER_Y + POSTER_H / 2.0 + 0.08, 0.02), Vector3(0.25, 0, 0)))
	_poster = Node3D.new()
	_poster.position.y = POSTER_Y
	add_child(_poster)
	_poster.add_child(Props.box(Vector3(POSTER_W, POSTER_H, 0.02), SaltGoods.PAPER, Vector3.ZERO))
	_poster.add_child(Props.box(Vector3(POSTER_W, 0.14, 0.022), Props.RED, Vector3(0, POSTER_H / 2.0 - 0.07, 0.001)))
	var title := _label("POSTER_TITLE", 30, Color(1, 1, 1))
	title.position = Vector3(0, POSTER_H / 2.0 - 0.07, 0.02)
	_poster.add_child(title)
	_content = Node3D.new()
	_poster.add_child(_content)
	var baro := SaltGoods.barometer()
	baro.name = "Barometer"
	baro.position = Vector3(0, POSTER_Y - POSTER_H / 2.0 - 0.26, 0.0)
	add_child(baro)
	_needle = baro.get_node("Needle")
	GameState.agency_order_changed.connect(_rebuild)
	GameState.weather_changed.connect(_on_weather)
	GameState.resources_discovered.connect(_rebuild)
	_rebuild()
	_on_weather()
	_needle.rotation.z = -_needle_angle


func _label(key: String, size: int, color: Color) -> Label3D:
	var l := Label3D.new()
	l.text = key
	l.font = UiTheme.title_font()
	l.font_size = size
	l.pixel_size = 0.004
	l.modulate = color
	l.outline_size = 0
	return l


func _rebuild() -> void:
	for c in _content.get_children():
		c.queue_free()
	var o: Dictionary = GameState.agency_order
	if o.is_empty():
		return
	if o.get("sent", false):
		var thanks := _label("POSTER_THANKS", 64, Props.RED)
		thanks.rotation.z = 0.15
		thanks.position = Vector3(0, -0.05, 0.02)
		_content.add_child(thanks)
		return
	var price: Dictionary = GameState.agency_order_price()
	var keys: Array = []
	for r in Economy.RESOURCES:
		if price.has(r):
			keys.append(r)
	var n := keys.size()
	for i in n:
		var r: String = keys[i]
		var y := 0.15 - (0.42 / maxf(n, 1)) * i - (0.0 if n > 1 else 0.1)
		var pile := Props.pile(r, 11 + i)
		pile.scale = Vector3.ONE * (0.32 if n > 1 else 0.42)
		pile.rotation.x = 0.45  # le tas un peu penché vers nous, devant l'affiche
		pile.position = Vector3(-0.32, y - 0.07, 0.09)
		# Un rond bleu nuit derrière chaque tas : le sel blanc se voit sur l'affiche crème.
		var disc := Props.cyl(0.11, 0.11, 0.01, Color(0.2, 0.28, 0.42), Vector3(-0.32, y, 0.015), 14)
		disc.rotation.x = PI / 2
		_content.add_child(disc)
		_content.add_child(pile)
		var count := _label("", 40, SaltGoods.INK)
		count.text = "%d" % int(price[r])
		count.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		count.position = Vector3(-0.1, y, 0.02)
		_content.add_child(count)
	# La flèche, puis la caisse cadeau.
	_content.add_child(Props.box(Vector3(0.14, 0.03, 0.01), SaltGoods.INK, Vector3(0.08, -0.05, 0.02)))
	var head := Props.cyl(0.0, 0.04, 0.07, SaltGoods.INK, Vector3(0.17, -0.05, 0.02), 3)
	head.rotation.z = -PI / 2
	_content.add_child(head)
	var gift := SaltGoods.gift_box(0.2)
	gift.position = Vector3(0.33, -0.13, 0.08)
	gift.rotation.y = 0.5
	_content.add_child(gift)


func _on_weather() -> void:
	var order: PackedStringArray = GameState.config.weather_order
	var i := order.find(GameState.weather)
	_needle_angle = SaltGoods.barometer_angle(maxi(i, 0), order.size())


func _process(delta: float) -> void:
	# L'aiguille va doucement vers le temps du jour, et tremble un peu (un vrai baromètre).
	var target := -_needle_angle + sin(Time.get_ticks_msec() * 0.003) * 0.02
	_needle.rotation.z = lerp_angle(_needle.rotation.z, target, clampf(delta * 2.0, 0.0, 1.0))
