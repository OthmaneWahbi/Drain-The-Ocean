extends CanvasLayer
## HUD petit et simple (M-68). Depuis 0.1.3, seulement l'essentiel : l'océan restant en haut,
## la barre d'outils en bas (le seau y montre son eau), et à côté d'elle la faim et la soif en
## jauges rondes animées (NeedGauge). Le stock, l'heure, ce qu'on porte… sont dans le menu pause.

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
var food_gauge: NeedGauge
var water_gauge: NeedGauge
var _toolbar_labels: Array[Label] = []


func _ready() -> void:
	_build_stamina_bar()
	survival_label = Label.new()
	survival_label.name = "Survival"
	survival_label.add_theme_font_size_override("font_size", 14)
	$Margin/VBox.add_child(survival_label)
	_apply_style()
	GameState.survival_changed.connect(_refresh_survival)
	GameState.ocean_changed.connect(_refresh_ocean)
	GameState.stock_changed.connect(_refresh_items)
	GameState.carried_changed.connect(_refresh_items)
	GameState.bucket_changed.connect(_refresh_items)
	_build_toolbar()
	GameState.tool_changed.connect(refresh_toolbar)
	GameState.bucket_changed.connect(refresh_toolbar)  # l'eau du seau, dans sa case
	GameState.carried_changed.connect(refresh_toolbar)  # les quantités portées dans les cases
	GameState.network_changed.connect(refresh_toolbar)  # les tuyaux en main (0.1.6)
	refresh_toolbar()
	_refresh_ocean()
	_refresh_items()


func _process(_delta: float) -> void:
	visible = GameState.ending == null  # la fin se joue sans HUD
	var h := GameState.day.hour()
	# Le chronomètre de partie est caché, sauf avec l'option « speedrun » (M-73).
	var clock := "%02d:%02d" % [int(h), int(fmod(h, 1.0) * 60.0)]
	time_label.text = "%s · %s : %s" % [clock, tr("HUD_PLAY_TIME"), format_precise(GameState.play_time_s)] if Settings.data.show_timer else clock
	time_label.visible = Settings.data.show_timer  # l'heure se lit dans le ciel ; le chrono, en option
	# En pause, le menu dit déjà tout : l'aide se cache (elle passait sous la barre d'outils, 0.1.4).
	hint_label.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not GameState.ui_open and not get_tree().paused
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
	if food_gauge:
		food_gauge.level = sv.food
		water_gauge.level = sv.water
	survival_label.text = "%s : %s · %s : %s" % [tr("HUD_FOOD"), gauge(sv.food), tr("HUD_WATER"), gauge(sv.water)]
	# Rouge quand un besoin est vide : l'endurance max baisse.
	survival_label.modulate = Color(1, 0.55, 0.45) if sv.food <= 0.0 or sv.water <= 0.0 else Color.WHITE


## Petite jauge en texte : « ▮▮▮▯▯ ».
static func gauge(ratio: float) -> String:
	var full := clampi(int(ceil(ratio * 5.0 - 0.001)), 0, 5)
	return "▮".repeat(full) + "▯".repeat(5 - full)


func _build_toolbar() -> void:
	var row := HBoxContainer.new()
	row.name = "Toolbar"
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_left = -330.0
	row.offset_right = 330.0
	row.offset_top = -94.0
	row.offset_bottom = -14.0
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	# La faim et la soif, juste à gauche des cases.
	food_gauge = NeedGauge.new(NeedGauge.Kind.FOOD)
	food_gauge.name = "Food"
	food_gauge.tooltip_text = tr("HUD_FOOD")
	row.add_child(food_gauge)
	water_gauge = NeedGauge.new(NeedGauge.Kind.WATER)
	water_gauge.name = "Water"
	water_gauge.tooltip_text = tr("HUD_WATER")
	row.add_child(water_gauge)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(10, 0)
	row.add_child(gap)
	for i in 5:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(96, 76)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", UiTheme.bold_font())
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", UiTheme.INK)
		slot.add_child(label)
		row.add_child(slot)
		toolbar_slots.append(slot)
		_toolbar_labels.append(label)


## Texte d'une case : l'outil, le matériau porté et sa quantité, ou « Mains » pour une case vide.
static func slot_text(entry: String) -> String:
	if entry == "":
		return TranslationServer.translate("TOOL_EMPTY")
	if Economy.RESOURCES.has(entry):
		return "%s\n%d/%d" % [TranslationServer.translate("RES_" + entry.to_upper()).capitalize(), int(GameState.carried.get(entry, 0)), GameState.carry_capacity]
	return TranslationServer.translate("TOOL_" + entry.to_upper())


## Case choisie encadrée en jaune ; une case vide (les mains) en plus pâle.
func refresh_toolbar() -> void:
	var tb := GameState.toolbar
	for i in toolbar_slots.size():
		var tool: String = tb.slots[i] if i < tb.slots.size() else ""
		var available := tb.is_available(i, GameState.owns_tool) if i < tb.slots.size() else false
		_toolbar_labels[i].text = "%d\n%s" % [i + 1, slot_text(tool)]
		if tool == "seau":
			_toolbar_labels[i].text += "\n%d / %d L" % [int(GameState.bucket.water_l), int(GameState.bucket.capacity_l)]
		elif tool == "tuyaux":
			_toolbar_labels[i].text += "\n" + tr("HUD_PIPES_IN_HAND") % GameState.pipe_stock
		var picked := i == tb.selected
		var style := UiTheme.paper(UiTheme.YELLOW if picked else Color(UiTheme.PAPER, 0.88), UiTheme.RED if picked else UiTheme.INK, 10, 4)
		style.set_border_width_all(4 if picked else 2)
		style.shadow_offset = Vector2(3, 3)
		toolbar_slots[i].add_theme_stylebox_override("panel", style)
		toolbar_slots[i].modulate = Color.WHITE if available and tool != "" else Color(1, 1, 1, 0.55)


## Le style du catalogue (UiTheme) : textes blancs cernés d'encre, en Fredoka ; l'océan restant
## en gros, avec la police des titres.
func _apply_style() -> void:
	for child in get_children():
		if child is Control:
			(child as Control).theme = UiTheme.theme()
	for label: Label in find_children("*", "Label", true, false):
		if label.get_parent() is PanelContainer:
			continue  # les cases de la barre : texte d'encre sur papier
		label.remove_theme_color_override("font_outline_color")
		label.remove_theme_constant_override("outline_size")
		label.theme_type_variation = "Hud"
	ocean_label.add_theme_font_override("font", UiTheme.title_font())
	ocean_label.add_theme_font_size_override("font_size", 28)
	for small: Label in [time_label, stock_label, carried_label, bucket_label, survival_label]:
		small.add_theme_font_size_override("font_size", 18)
	ocean_label.add_theme_color_override("font_color", UiTheme.YELLOW)
	prompt_label.add_theme_font_size_override("font_size", 22)
	# Les détails (palette, bras, seau, faim en texte) vont au menu pause : le HUD reste léger.
	for extra: Label in [stock_label, carried_label, bucket_label, survival_label]:
		extra.visible = false
	# L'aide « cliquer pour jouer » passe au-dessus de la barre d'outils, plus grande qu'avant.
	hint_label.offset_top = -164.0
	hint_label.offset_bottom = -128.0


func _build_stamina_bar() -> void:
	stamina_bar = ProgressBar.new()
	stamina_bar.name = "StaminaBar"
	stamina_bar.show_percentage = false
	stamina_bar.tooltip_text = tr("HUD_STAMINA")
	stamina_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	stamina_bar.offset_left = -120.0
	stamina_bar.offset_right = 120.0
	# Au-dessus de la barre d'outils (et des jauges qui battent), jamais dessous.
	stamina_bar.offset_top = -122.0
	stamina_bar.offset_bottom = -108.0
	stamina_bar.visible = false
	add_child(stamina_bar)


func _refresh_ocean() -> void:
	# Beaucoup de décimales : voir 100,0000000000 % est drôle en soi (PRD §8.2).
	# Les litres retirés, eux, bougent dès le premier seau.
	ocean_label.text = "%s : %.10f %% · %s : %s L" % [tr("HUD_OCEAN_REMAINING"), GameState.ocean.remaining_ratio() * 100.0, tr("HUD_REMOVED"), format_liters(GameState.ocean.removed_l)]


func _refresh_items() -> void:
	stock_label.text = "%s : %s" % [tr("HUD_STOCK"), CatalogueFormat.format_items(GameState.stock, true)]
	carried_label.text = "%s (%s) : %s" % [tr("HUD_CARRIED"), tr("HUD_PER_SLOT") % GameState.carry_capacity, CatalogueFormat.format_items(GameState.carried)]
	bucket_label.text = tr("HUD_BUCKET") % [GameState.bucket.water_l, GameState.bucket.capacity_l]


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]


## Chronomètre précis (option speedrun) : « 01:02:05.90 ».
static func format_precise(seconds: float) -> String:
	var cs := int(round(maxf(seconds, 0.0) * 100.0))
	return "%02d:%02d:%02d.%02d" % [cs / 360000, (cs / 6000) % 60, (cs / 100) % 60, cs % 100]


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
