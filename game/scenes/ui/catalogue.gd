extends CanvasLayer
## Le Grand Catalogue de l'Agence (0.1.2), ouvert seulement depuis la cabine téléphonique :
## une double page de vieux catalogue de vente par correspondance. À gauche, les produits en
## vitrine (photo qui tourne, nom, slogan, prix sur une étiquette jaune, tampons « PROMO »,
## « BIENTÔT », « DÉJÀ À VOUS ») ; à droite, le bon de commande (ce qu'on a, le panier, le total).
## Panier (M-49), paiement avec ce qu'on porte puis la palette. Le jeu ne se met pas en pause (M-74).

const COLUMNS := 3

var _cart: Array[String] = []
var _root: Control
var _panel: PanelContainer
var _stock_label: Label
var _cart_label: Label
var _total_tag: PanelContainer
var _message: Label
var _order_button: Button
## id -> {card, add, price, was, desc, stamp_soon, stamp_promo, stamp_owned}
var _cards: Dictionary = {}


func _ready() -> void:
	add_to_group(&"catalogue")
	layer = 10
	_build()
	_root.visible = false
	_panel.visible = false


func open_catalogue() -> void:
	_cart.clear()
	_message.text = ""
	_root.visible = true
	_panel.visible = true
	GameState.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()


func close_catalogue() -> void:
	_root.visible = false
	_panel.visible = false
	GameState.ui_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_open() -> bool:
	return _panel.visible


func _unhandled_input(event: InputEvent) -> void:
	if _panel.visible and event.is_action_pressed(&"pause"):
		close_catalogue()
		get_viewport().set_input_as_handled()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiTheme.theme()
	add_child(_root)
	_root.add_child(MenuStyle.backdrop(0.55))
	var center := MenuStyle.centered()
	_root.add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(1560, 900)
	_panel.add_theme_stylebox_override("panel", UiTheme.paper(UiTheme.PAPER, UiTheme.INK, 18, 26))
	center.add_child(_panel)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	_panel.add_child(page)
	_build_header(page)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 22)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(body)
	# La vitrine : les produits sur trois colonnes, qui défilent (le catalogue grandit à chaque palier).
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)
	var tilt := 0
	for item in GameState.catalog.items:
		if item.hidden:
			continue
		grid.add_child(_build_card(item, tilt))
		tilt += 1
	body.add_child(_build_order_form())
	var footer := Label.new()
	footer.text = "CAT_FOOTER"
	footer.theme_type_variation = "Fine"
	footer.add_theme_font_size_override("font_size", 14)
	page.add_child(footer)


func _build_header(page: VBoxContainer) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	page.add_child(head)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(titles)
	var banner := UiTheme.banner("CAT_TITLE", 46)
	banner.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	titles.add_child(banner)
	var sub := Label.new()
	sub.text = "CAT_SUBTITLE"
	sub.add_theme_font_override("font", UiTheme.bold_font())
	sub.add_theme_color_override("font_color", UiTheme.TEAL)
	titles.add_child(sub)
	var season := UiTheme.stamp("CAT_SEASON", UiTheme.RED, 22, 6.0)
	season.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(season)


## Une vignette produit : photo, tampons, nom, slogan, description, prix, bouton.
func _build_card(item: CatalogItem, index: int) -> PanelContainer:
	var id := String(item.id)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(350, 0)
	card.add_theme_stylebox_override("panel", UiTheme.paper(Color(1, 1, 1), UiTheme.INK, 12, 12))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	# La photo, avec les tampons posés par-dessus.
	var photo_holder := Control.new()
	photo_holder.custom_minimum_size = Vector2(320, 170)
	box.add_child(photo_holder)
	var photo := ProductPhoto.new(id, Vector2i(320, 170))
	photo_holder.add_child(photo)
	var stamps := {}
	for s in [["soon", "CAT_SOON", UiTheme.INK], ["promo", "CAT_PROMO", UiTheme.RED], ["owned", "CAT_OWNED", UiTheme.GREEN]]:
		var st := UiTheme.stamp(s[1], s[2], 26, -10.0 if s[0] != "promo" else 9.0)
		st.position = Vector2(14, 12) if s[0] != "promo" else Vector2(200, 10)
		st.visible = false
		photo_holder.add_child(st)
		stamps[s[0]] = st
	var name_label := Label.new()
	name_label.text = item.name_key
	name_label.add_theme_font_override("font", UiTheme.title_font())
	name_label.add_theme_font_size_override("font_size", 26)
	box.add_child(name_label)
	var pitch := Label.new()
	pitch.text = item.name_key + "_PITCH"
	pitch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pitch.add_theme_font_override("font", UiTheme.bold_font())
	pitch.add_theme_color_override("font_color", UiTheme.RED)
	pitch.add_theme_font_size_override("font_size", 17)
	box.add_child(pitch)
	var desc := Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	desc.theme_type_variation = "Fine"
	desc.custom_minimum_size = Vector2(320, 0)
	box.add_child(desc)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var prices := VBoxContainer.new()
	prices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prices.add_theme_constant_override("separation", 0)
	row.add_child(prices)
	var tag := UiTheme.price_tag("", 21, -4.0 + (index % 3) * 2.5, 170.0)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	prices.add_child(tag)
	var was := Label.new()
	was.theme_type_variation = "Fine"
	was.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	was.add_theme_font_size_override("font_size", 13)
	prices.add_child(was)
	var add := Button.new()
	add.text = "CAT_ADD"
	add.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add.pressed.connect(_add_to_cart.bind(id))
	row.add_child(add)
	_cards[id] = {"card": card, "add": add, "price": tag.get_child(0), "was": was, "desc": desc, "stamps": stamps}
	return card


func _build_order_form() -> PanelContainer:
	var form := PanelContainer.new()
	form.custom_minimum_size = Vector2(400, 0)
	form.add_theme_stylebox_override("panel", UiTheme.paper(UiTheme.PAPER_DARK, UiTheme.INK, 12, 18))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	form.add_child(box)
	var title := Label.new()
	title.text = "CAT_ORDER_FORM"
	title.add_theme_font_override("font", UiTheme.marker_font())
	title.add_theme_font_size_override("font_size", UiTheme.marker_size(32))
	title.add_theme_color_override("font_color", UiTheme.RED_DARK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(HSeparator.new())
	_stock_label = Label.new()
	_stock_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_stock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stock_label.custom_minimum_size = Vector2(360, 0)
	_stock_label.add_theme_font_size_override("font_size", 17)
	box.add_child(_stock_label)
	box.add_child(HSeparator.new())
	_cart_label = Label.new()
	_cart_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_cart_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cart_label.custom_minimum_size = Vector2(360, 0)
	_cart_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_cart_label)
	_total_tag = UiTheme.price_tag("", 24, -3.0, 320.0)
	_total_tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_total_tag)
	_message = Label.new()
	_message.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size = Vector2(360, 0)
	_message.add_theme_color_override("font_color", UiTheme.RED)
	_message.add_theme_font_override("font", UiTheme.bold_font())
	box.add_child(_message)
	_order_button = Button.new()
	_order_button.text = "CAT_ORDER"
	_order_button.add_theme_font_override("font", UiTheme.title_font())
	_order_button.add_theme_font_size_override("font_size", 30)
	_order_button.pressed.connect(_order)
	box.add_child(_order_button)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var clear := Button.new()
	clear.text = "CAT_CLEAR"
	clear.theme_type_variation = "Tag"
	clear.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear.pressed.connect(func(): _cart.clear(); _refresh())
	row.add_child(clear)
	var hang_up := Button.new()
	hang_up.text = "CAT_HANG_UP"
	hang_up.theme_type_variation = "Tag"
	hang_up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hang_up.pressed.connect(close_catalogue)
	row.add_child(hang_up)
	return form


func _add_to_cart(id: String) -> void:
	var item := GameState.catalog.find(StringName(id))
	if item.unique and _cart.has(id):
		return
	_cart.append(id)
	_message.text = ""
	_refresh()


func _order() -> void:
	var crates := GameState.order(_cart)
	if crates.is_empty():
		_message.text = tr("CAT_NOT_ENOUGH")
		return
	_cart.clear()
	close_catalogue()


func _refresh() -> void:
	_stock_label.text = "%s :\n%s : %s\n%s : %s" % [tr("CAT_WALLET"), tr("CAT_ON_PALLET"), format_items(GameState.stock, true), tr("HUD_CARRIED"), format_items(GameState.carried)]
	for id in _cards:
		var c: Dictionary = _cards[id]
		var item := GameState.catalog.find(StringName(id))
		var unlocked := GameState.is_unlocked(item)
		var owned := item.unique and GameState.owned.has(id)
		c.add.disabled = not GameState.can_buy(item) or (item.unique and _cart.has(id))
		# Palier pas encore débloqué : grisé, avec le tampon « BIENTÔT » (envie de la suite, PRD §7).
		c.card.modulate = Color(1, 1, 1, 1.0 if unlocked else 0.6)
		c.desc.text = tr(item.desc_key) if unlocked else tr("CAT_LOCKED")
		# L'offre du jour (décrochée au téléphone) : nouveau prix sur l'étiquette, l'ancien dessous.
		var offer := GameState.phone.has_offer(id, GameState.day.day_index)
		c.price.text = format_items(GameState.price_of(item))
		c.was.text = tr("CAT_INSTEAD") % format_items(item.price) if offer else ""
		c.stamps.soon.visible = not unlocked
		c.stamps.promo.visible = offer and unlocked
		c.stamps.owned.visible = owned
	if _cart.is_empty():
		_cart_label.text = "%s :\n%s" % [tr("CAT_CART"), tr("CAT_EMPTY_CART")]
		_total_tag.visible = false
		_order_button.disabled = true
		return
	var names := CatalogueFormat.format_cart(_cart, func(i): return tr(GameState.catalog.find(StringName(i)).name_key))
	var total := GameState.cart_price(_cart)
	_cart_label.text = "%s :\n%s" % [tr("CAT_CART"), names]
	_total_tag.visible = true
	(_total_tag.get_child(0) as Label).text = "%s : %s" % [tr("CAT_TOTAL"), format_items(total)]
	_order_button.disabled = not Economy.can_afford(GameState.available_resources(), total)


static func format_items(items: Dictionary, show_zero := false) -> String:
	return CatalogueFormat.format_items(items, show_zero)
