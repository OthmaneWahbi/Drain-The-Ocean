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


func _ready() -> void:
	GameState.ocean_changed.connect(_refresh_ocean)
	GameState.stock_changed.connect(_refresh_items)
	GameState.carried_changed.connect(_refresh_items)
	GameState.bucket_changed.connect(_refresh_items)
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


func _refresh_ocean() -> void:
	# Beaucoup de décimales : voir 100,0000000000 % est drôle en soi (PRD §8.2).
	# Les litres retirés, eux, bougent dès le premier seau.
	ocean_label.text = "%s : %.10f %% · %s : %s L" % [tr("HUD_OCEAN_REMAINING"), GameState.ocean.remaining_ratio() * 100.0, tr("HUD_REMOVED"), format_liters(GameState.ocean.removed_l)]


func _refresh_items() -> void:
	stock_label.text = "%s : %s" % [tr("HUD_STOCK"), CatalogueFormat.format_items(GameState.stock, true)]
	carried_label.text = "%s (%d/%d) : %s" % [tr("HUD_CARRIED"), GameState.carried_count(), GameState.config.hand_carry_capacity, CatalogueFormat.format_items(GameState.carried)]
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
