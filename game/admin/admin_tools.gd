extends CanvasLayer
## OUTILS ADMIN (triche pour tester). Tout est dans ce seul fichier.
##
## POUR LES RETIRER : supprimer le dossier `game/admin/` et la ligne `Admin=...` de la section
## [autoload] de `game/project.godot`. Rien d'autre dans le jeu n'en dépend.
## Ils sont aussi coupés automatiquement dans une version exportée « release ».
##
## F1  afficher / cacher cette liste      F4  jouer la vraie fin (M-04)
## F6  avancer de 3 heures
## F7  (maintenu) vider l'océan très vite F8  (maintenu) temps ×10
## F9  nouvelle partie                    F10 +50 sel, +5 minéraux
## F11 +10 000 de chaque ressource        F12 ouvrir toutes les caisses tout de suite

const HELP := "ADMIN  ·  F1 aide  ·  F4 vraie fin  ·  F6 +3 h  ·  F7 vider l'océan  ·  F8 temps ×10\nF9 nouvelle partie  ·  F10 +50 sel  ·  F11 +10 000 de tout  ·  F12 ouvrir les caisses"

var _label: Label


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.text = HELP
	_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_label.offset_left = 12.0
	_label.offset_top = -52.0
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_label.visible = false
	add_child(_label)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_F1:
			_label.visible = not _label.visible
		KEY_F4:
			# La vraie fin n'est accessible que par cette touche pour le MVP (M-04).
			GameState.start_ending()
		KEY_F6:
			# Fait vivre le monde 3 h d'un coup (faim, soif, séchage, matin…), pas seulement l'horloge.
			GameState.advance_time(GameState.day.day_length_s / 8.0)
		KEY_F9:
			GameState.new_game()
		KEY_F10:
			_give({"sel": 50, "mineraux": 5})
		KEY_F11:
			var all := {}
			for r in Economy.RESOURCES:
				all[r] = 10000
			_give(all)
		KEY_F12:
			for crate in GameState.crates.duplicate():
				GameState.open_crate(crate)


func _physics_process(delta: float) -> void:
	Engine.time_scale = 10.0 if Input.is_physical_key_pressed(KEY_F8) else 1.0
	if Input.is_physical_key_pressed(KEY_F7):
		var ocean := GameState.ocean
		ocean.remove_water(ocean.total_volume_l * GameState.config.debug_drain_ratio_per_s * delta)
		GameState.ocean_changed.emit()


func _give(items: Dictionary) -> void:
	Economy.add(GameState.stock, items)
	GameState.stock_changed.emit()
