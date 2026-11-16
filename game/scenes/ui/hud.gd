extends CanvasLayer
## HUD greybox, petit et simple (M-68) : océan, temps, heure, stock, bras, seau, aide contextuelle.

@onready var ocean_label: Label = $Margin/VBox/Ocean
@onready var time_label: Label = $Margin/VBox/Time
@onready var stock_label: Label = $Margin/VBox/Stock
@onready var carried_label: Label = $Margin/VBox/Carried
@onready var bucket_label: Label = $Margin/VBox/Bucket
@onready var hint_label: Label = $Hint
@onready var prompt_label: Label = $Prompt
@onready var fill_bar: ProgressBar = $FillBar
var stamina_bar: ProgressBar
var survival_label: Label
## Les 5 cases de la barre d'outils (M-27), en bas au centre.
var toolbar_slots: Array[PanelContainer] = []
var _toolbar_labels: Array[Label] = []


func _ready() -> void:
	_build_stamina_bar()
	survival_label = Label.new()
	survival_label.name = "Survival"
	survival_label.add_theme_font_size_override("font_size", 14)
	$Margin/VBox.add_child(survival_label)
	GameState.survival_changed.connect(_refresh_survival)
	GameState.ocean_changed.connect(_refresh_ocean)
	GameState.stock_changed.connect(_refresh_items)
	GameState.carried_changed.connect(_refresh_items)
	GameState.bucket_changed.connect(_refresh_items)
	_build_toolbar()
	GameState.tool_changed.connect(refresh_toolbar)
	refresh_toolbar()
	_refresh_ocean()
	_refresh_items()


func _process(_delta: float) -> void:
	var h := GameState.day.hour()
	time_label.text = "%s : %s · %02d:%02d" % [tr("HUD_PLAY_TIME"), format_time(GameState.play_time_s), int(h), int(fmod(h, 1.0) * 60.0)]
	hint_label.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not GameState.ui_open
	var player := get_tree().get_first_node_in_group(&"player")
	prompt_label.text = player.prompt if player else ""
	var progress := GameState.bucket.fill_progress_ratio()
	fill_bar.visible = progress > 0.0
	fill_bar.value = progress * 100.0
	_refresh_survival()
	# Endurance : visible seulement quand elle n'est pas pleine (comme dans BotW).
	var stamina := GameState.stamina
	stamina_bar.visible = not stamina.is_full()
	stamina_bar.value = stamina.value * 100.0
	stamina_bar.modulate = Color(1, 0.35, 0.3) if stamina.exhausted or stamina.value < 0.25 else Color(0.55, 0.9, 0.4)


func _refresh_survival() -> void:
	var sv := GameState.survival
	survival_label.text = "%s : %s · %s : %s" % [tr("HUD_FOOD"), gauge(sv.food), tr("HUD_WATER"), gauge(sv.water)]
	# Rouge quand un besoin est vide : l'endurance max baisse.
	survival_label.modulate = Color(1, 0.45, 0.4) if sv.food <= 0.0 or sv.water <= 0.0 else Color.WHITE


## Petite jauge en texte : « ▮▮▮▯▯ ».
static func gauge(ratio: float) -> String:
	var full := clampi(int(ceil(ratio * 5.0 - 0.001)), 0, 5)
	return "▮".repeat(full) + "▯".repeat(5 - full)


func _build_toolbar() -> void:
	var row := HBoxContainer.new()
	row.name = "Toolbar"
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_left = -190.0
	row.offset_right = 190.0
	row.offset_top = -74.0
	row.offset_bottom = -14.0
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	for i in 5:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(70, 56)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		slot.add_child(label)
		row.add_child(slot)
		toolbar_slots.append(slot)
		_toolbar_labels.append(label)


## Case choisie encadrée en jaune, cases vides ou pas encore achetées en grisé.
func refresh_toolbar() -> void:
	var tb := GameState.toolbar
	for i in toolbar_slots.size():
		var tool: String = tb.slots[i] if i < tb.slots.size() else ""
		var available := tb.is_available(i, GameState.owns_tool) if i < tb.slots.size() else false
		_toolbar_labels[i].text = "%d\n%s" % [i + 1, tr("TOOL_" + tool.to_upper()) if tool != "" else ""]
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.45)
		style.set_corner_radius_all(6)
		style.set_border_width_all(3 if i == tb.selected else 1)
		style.border_color = Color(1.0, 0.85, 0.3) if i == tb.selected else Color(1, 1, 1, 0.25)
		toolbar_slots[i].add_theme_stylebox_override("panel", style)
		toolbar_slots[i].modulate = Color.WHITE if available else Color(1, 1, 1, 0.35)


func _build_stamina_bar() -> void:
	stamina_bar = ProgressBar.new()
	stamina_bar.name = "StaminaBar"
	stamina_bar.show_percentage = false
	stamina_bar.tooltip_text = tr("HUD_STAMINA")
	stamina_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	stamina_bar.offset_left = -120.0
	stamina_bar.offset_right = 120.0
	stamina_bar.offset_top = -100.0
	stamina_bar.offset_bottom = -86.0
	stamina_bar.visible = false
	add_child(stamina_bar)


func _refresh_ocean() -> void:
	# Beaucoup de décimales : voir 100,0000000000 % est drôle en soi (PRD §8.2).
	# Les litres retirés, eux, bougent dès le premier seau.
	ocean_label.text = "%s : %.10f %% · %s : %s L" % [tr("HUD_OCEAN_REMAINING"), GameState.ocean.remaining_ratio() * 100.0, tr("HUD_REMOVED"), format_liters(GameState.ocean.removed_l)]


func _refresh_items() -> void:
	stock_label.text = "%s : %s" % [tr("HUD_STOCK"), CatalogueFormat.format_items(GameState.stock, true)]
	carried_label.text = "%s (%d/%d) : %s" % [tr("HUD_CARRIED"), GameState.carried_count(), GameState.carry_capacity, CatalogueFormat.format_items(GameState.carried)]
	bucket_label.text = tr("HUD_BUCKET") % [GameState.bucket.water_l, GameState.bucket.capacity_l]


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]


## 1 234 567 → « 1,23 M » ; reste lisible jusqu'aux nombres astronomiques.
static func format_liters(liters: float) -> String:
	var units := ["", " k", " M", " Md", " T"]
	var i := 0
	var v := liters
	while v >= 1000.0 and i < units.size() - 1:
		v /= 1000.0
		i += 1
	if i == 0:
		return "%d" % int(v)
	return "%.2f%s" % [v, units[i]]
