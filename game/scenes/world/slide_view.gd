extends StaticBody3D
## Le toboggan à sacs (T2, N-09) : une tour en bois avec une goulotte qui descend. Quand il
## envoie quelque chose à la palette (GameState.slide_sent), des sacs glissent le long de la
## goulotte puis disparaissent (on ne dessine pas tout le trajet jusqu'à la palette).
## E : jeter ce qu'on porte dedans. Les règles sont dans GameState (slide_unload, _run_slides).

var slide: Dictionary
var _ring: MeshInstance3D


func setup(p_slide: Dictionary) -> void:
	slide = p_slide
	position = slide.position
	# La tour et son entonnoir.
	for x in [-0.35, 0.35]:
		for z in [-0.35, 0.35]:
			add_child(Greybox.box(Vector3(0.1, 2.0, 0.1), Greybox.WOOD, Vector3(x, 1.0, z)))
	add_child(Greybox.box(Vector3(0.9, 0.08, 0.9), Greybox.WOOD, Vector3(0, 2.0, 0)))
	add_child(Greybox.box(Vector3(0.9, 0.35, 0.08), Color(0.55, 0.4, 0.25), Vector3(0, 2.2, -0.42)))
	add_child(Greybox.box(Vector3(0.08, 0.35, 0.9), Color(0.55, 0.4, 0.25), Vector3(-0.42, 2.2, 0)))
	add_child(Greybox.box(Vector3(0.08, 0.35, 0.9), Color(0.55, 0.4, 0.25), Vector3(0.42, 2.2, 0)))
	# La goulotte, en pente vers +Z (elle tourne avec l'objet).
	var chute := Greybox.box(Vector3(0.6, 0.06, 2.6), Color(0.75, 0.6, 0.4), Vector3(0, 1.15, 1.4))
	chute.rotation.x = deg_to_rad(38)
	add_child(chute)
	add_child(Greybox.box_collision(Vector3(1.0, 2.4, 1.0), Vector3(0, 1.2, 0)))
	# Le cercle de portée, à peine visible au sol.
	_ring = Greybox.cylinder(GameState.config.slide_reach_m + 1.0, 0.01, Color(0.6, 0.45, 0.25, 0.12), Vector3(0, 0.02, 0), 32)
	add_child(_ring)
	GameState.slide_sent.connect(_on_sent)


func _on_sent(p_slide: Dictionary, items: Dictionary) -> void:
	if p_slide != slide:
		return
	var n := clampi(Economy.count(items) / 5 + 1, 1, 4)
	for i in n:
		var bag := Greybox.box(Vector3(0.3, 0.25, 0.4), Color(0.9, 0.88, 0.8), Vector3(0, 2.2, 0.2))
		add_child(bag)
		var t := create_tween()
		t.tween_interval(i * 0.35)
		t.tween_property(bag, "position", Vector3(0, 0.25, 2.5), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(bag, "scale", Vector3.ONE * 0.01, 0.4)
		t.tween_callback(bag.queue_free)


func get_prompt(_player: Node) -> String:
	var n := GameState.carried_count()
	if n > 0:
		return tr("PROMPT_SLIDE") % n
	return tr("SLIDE_STATE") % GameState.zones_for_slide(slide).size()


func interact(_player: Node) -> void:
	GameState.slide_unload(slide)


func get_movable() -> Dictionary:
	return slide
