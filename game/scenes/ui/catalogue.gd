extends CanvasLayer
## Le catalogue de l'agence, ouvert en décrochant le téléphone (M-47 : on décroche en 3D,
## puis un menu illustré). Panier (M-49), paiement avec le stock de la palette.
## Le jeu ne se met pas en pause pendant les courses (M-74).

var _cart: Array[String] = []
var _panel: PanelContainer
var _stock_label: Label
var _cart_label: Label
var _message: Label
var _order_button: Button
var _item_buttons: Dictionary = {}


func _ready() -> void:
	add_to_group(&"catalogue")
	layer = 10
	_build()
	_panel.visible = false


func open_catalogue() -> void:
	_cart.clear()
	_message.text = ""
	_panel.visible = true
	GameState.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()


func close_catalogue() -> void:
	_panel.visible = false
	GameState.ui_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if _panel.visible and event.is_action_pressed(&"pause"):
		close_catalogue()
		get_viewport().set_input_as_handled()


func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = tr("CAT_TITLE")
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	_stock_label = Label.new()
	box.add_child(_stock_label)
	box.add_child(HSeparator.new())

	for item in GameState.catalog.items:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label := Label.new()
		name_label.text = tr(item.name_key)
		name_label.add_theme_font_size_override("font_size", 20)
		var desc := Label.new()
		desc.text = tr(item.desc_key)
		desc.modulate = Color(1, 1, 1, 0.7)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(name_label)
		text.add_child(desc)
		row.add_child(text)
		var price := Label.new()
		price.text = format_items(item.price)
		row.add_child(price)
		var add := Button.new()
		add.text = tr("CAT_ADD")
		add.pressed.connect(_add_to_cart.bind(String(item.id)))
		row.add_child(add)
		_item_buttons[String(item.id)] = add
		box.add_child(row)

	box.add_child(HSeparator.new())
	_cart_label = Label.new()
	_cart_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_cart_label)
	_message = Label.new()
	_message.modulate = Color(1, 0.8, 0.4)
	box.add_child(_message)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	_order_button = Button.new()
	_order_button.text = tr("CAT_ORDER")
	_order_button.pressed.connect(_order)
	var clear := Button.new()
	clear.text = tr("CAT_CLEAR")
	clear.pressed.connect(func(): _cart.clear(); _refresh())
	var hang_up := Button.new()
	hang_up.text = tr("CAT_HANG_UP")
	hang_up.pressed.connect(close_catalogue)
	buttons.add_child(_order_button)
	buttons.add_child(clear)
	buttons.add_child(hang_up)
	box.add_child(buttons)


func _add_to_cart(id: String) -> void:
	var item := GameState.catalog.find(StringName(id))
	if item.unique and _cart.has(id):
		return
	_cart.append(id)
	_message.text = ""
	_refresh()


func _order() -> void:
	var crate := GameState.order(_cart)
	if crate.is_empty():
		_message.text = tr("CAT_NOT_ENOUGH")
		return
	_cart.clear()
	close_catalogue()


func _refresh() -> void:
	_stock_label.text = "%s : %s" % [tr("CAT_ON_PALLET"), format_items(GameState.stock, true)]
	for id in _item_buttons:
		var item := GameState.catalog.find(StringName(id))
		_item_buttons[id].disabled = not GameState.can_buy(item) or (item.unique and _cart.has(id))
	if _cart.is_empty():
		_cart_label.text = tr("CAT_EMPTY_CART")
		_order_button.disabled = true
		return
	var names := _cart.map(func(i): return tr(GameState.catalog.find(StringName(i)).name_key))
	var total := GameState.cart_price(_cart)
	_cart_label.text = "%s : %s\n%s : %s" % [tr("CAT_CART"), ", ".join(names), tr("CAT_TOTAL"), format_items(total)]
	_order_button.disabled = not Economy.can_afford(GameState.stock, total)



static func format_items(items: Dictionary, show_zero := false) -> String:
	return CatalogueFormat.format_items(items, show_zero)
