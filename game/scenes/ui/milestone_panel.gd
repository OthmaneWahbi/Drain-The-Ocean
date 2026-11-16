extends CanvasLayer
## Les jalons à l'écran (M-70) : en haut à droite, le pictogramme du prochain jalon qui se remplit
## à mesure qu'on vide l'océan ; quand on le franchit, un grand pictogramme plein apparaît au
## centre avec la récompense, puis s'efface. Toute la règle est dans MilestoneLogic.

var _next_icon: MilestoneIcon
var _next_box: PanelContainer
var _toast: VBoxContainer
var _toast_icon: MilestoneIcon
var _toast_reward: Label
var _queue: Array = []
var _showing := false


func _ready() -> void:
	layer = 5
	_next_box = PanelContainer.new()
	_next_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_next_box.offset_left = -150.0
	_next_box.offset_right = -14.0
	_next_box.offset_top = 12.0
	_next_box.offset_bottom = 100.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.35)
	style.set_corner_radius_all(6)
	_next_box.add_theme_stylebox_override("panel", style)
	add_child(_next_box)
	_next_icon = MilestoneIcon.new()
	_next_icon.custom_minimum_size = Vector2(130, 84)
	_next_box.add_child(_next_icon)
	_toast = VBoxContainer.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -120.0
	_toast.offset_right = 120.0
	_toast.offset_top = 110.0
	_toast.offset_bottom = 330.0
	_toast.alignment = BoxContainer.ALIGNMENT_CENTER
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.visible = false
	add_child(_toast)
	_toast_icon = MilestoneIcon.new()
	_toast_icon.custom_minimum_size = Vector2(240, 160)
	_toast.add_child(_toast_icon)
	_toast_reward = Label.new()
	_toast_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_reward.add_theme_font_size_override("font_size", 22)
	_toast_reward.add_theme_constant_override("outline_size", 8)
	_toast_reward.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_toast.add_child(_toast_reward)
	GameState.milestone_reached.connect(func(m): _queue.append(m))
	GameState.game_reset.connect(func(): _queue.clear())


func _process(_delta: float) -> void:
	visible = GameState.ending == null  # la fin se joue sans HUD
	var next := GameState.milestones.next()
	_next_box.visible = not next.is_empty()
	if not next.is_empty():
		_next_icon.icon = String(next.get("icon", "piscine"))
		_next_icon.fill = GameState.milestones.progress(GameState.ocean.removed_l)
	if not _showing and not _queue.is_empty():
		_show(_queue.pop_front())


func _show(m: Dictionary) -> void:
	_showing = true
	_toast_icon.icon = String(m.get("icon", "piscine"))
	_toast_icon.fill = 1.0
	_toast_reward.text = "✓  + " + CatalogueFormat.format_items(m.get("reward", {}))
	_toast.visible = true
	_toast.modulate = Color(1, 1, 1, 0)
	_toast.scale = Vector2(0.6, 0.6)
	_toast.pivot_offset = Vector2(120, 110)
	var t := create_tween()
	t.tween_property(_toast, "modulate:a", 1.0, 0.3)
	t.parallel().tween_property(_toast, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(3.5)
	t.tween_property(_toast, "modulate:a", 0.0, 0.6)
	t.tween_callback(func():
		_toast.visible = false
		_showing = false)
