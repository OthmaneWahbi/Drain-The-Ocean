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
	# La tour, l'échelle, la trémie et la goulotte jaune (Props.slide).
	add_child(Props.slide())
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
		var bag := Props.sack(0.35, Props.RED, i)
		bag.visible = false  # 0.1.17 : avant, tous les sacs attendaient, empilés, en haut
		add_child(bag)
		var t := create_tween()
		t.tween_interval(i * 0.35)
		t.tween_callback(func(): bag.visible = true)
		# Il glisse SUR la goulotte, penché comme elle, en accélérant…
		t.tween_method(_slide_bag.bind(bag), 0.0, 1.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# …puis saute du bout de la goulotte, roule un peu et disparaît dans le sable.
		t.tween_method(_hop_bag.bind(bag), 0.0, 1.0, 0.35)
		t.tween_property(bag, "scale", Vector3.ONE * 0.01, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_callback(bag.queue_free)


## Le haut et le bas de la goulotte (Props.slide : centre (0, 1.15, 1.4), pente de 38°, 2,7 m),
## et sa normale ; le sac glisse 3 cm au-dessus de la planche.
const CHUTE_TOP := Vector3(0, 1.98, 0.34)
const CHUTE_BOTTOM := Vector3(0, 0.32, 2.46)
const CHUTE_NORMAL := Vector3(0, 0.788, 0.616)
const CHUTE_TILT := 0.663  # 38° en radians


func _slide_bag(k: float, bag: Node3D) -> void:
	bag.position = CHUTE_TOP.lerp(CHUTE_BOTTOM, k) + CHUTE_NORMAL * 0.07
	bag.rotation = Vector3(CHUTE_TILT, 0.0, 0.0)


func _hop_bag(k: float, bag: Node3D) -> void:
	var from := CHUTE_BOTTOM + CHUTE_NORMAL * 0.07
	var to := Vector3(0, 0.02, 3.2)
	var p := from.lerp(to, k)
	p.y += sin(PI * k) * 0.18
	bag.position = p
	bag.rotation = Vector3(lerpf(CHUTE_TILT, CHUTE_TILT + PI * 0.9, k), 0.0, 0.0)
