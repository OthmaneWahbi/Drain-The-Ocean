extends TestCase

const HudScript := preload("res://scenes/ui/hud.gd")


func test_time_format() -> void:
	assert_eq(HudScript.format_time(0.0), "00:00:00")
	assert_eq(HudScript.format_time(3725.9), "01:02:05")
