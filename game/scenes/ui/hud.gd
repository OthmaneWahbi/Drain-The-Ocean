extends CanvasLayer
## HUD greybox : % d'océan restant et temps de partie (M-68 : petit et simple).

@onready var ocean_label: Label = $Margin/VBox/Ocean
@onready var time_label: Label = $Margin/VBox/Time
@onready var hint_label: Label = $Hint


func _ready() -> void:
	GameState.ocean_changed.connect(_refresh_ocean)
	_refresh_ocean()


func _process(_delta: float) -> void:
	time_label.text = "%s : %s" % [tr("HUD_PLAY_TIME"), format_time(GameState.play_time_s)]
	hint_label.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED


func _refresh_ocean() -> void:
	# Beaucoup de décimales : voir 99,99999999 % est drôle en soi (PRD §8.2).
	ocean_label.text = "%s : %.10f %%" % [tr("HUD_OCEAN_REMAINING"), GameState.ocean.remaining_ratio() * 100.0]


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
