class_name FlowerFlakes
extends Node3D
## La fleur de sel d'une zone (0.1.22, PRD §19.29) : de fines paillettes blanches qui brillent,
## posées à la surface (on la cueille avec la lousse, en visant la zone). Pas de tas à part :
## c'est à la surface de l'eau que la fleur de sel se forme, comme dans les vrais marais.
## Aucune règle ici : la vue lit le dépôt `fleur_de_sel` de la zone.

const MAX_FLAKES := 14

var _flakes: Array[Node3D] = []
var _t := 0.0


## `radius` : la moitié de la largeur de la zone ; les paillettes restent dedans.
func build(radius: float, seed_value := 3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in MAX_FLAKES:
		var holder := Props.pile_piece("fleur_de_sel", rng, i)
		var a := i * 2.39996
		var r := radius * 0.8 * sqrt((float(i) + 0.5) / MAX_FLAKES)
		holder.position = Vector3(cos(a) * r, 0.0, sin(a) * r)
		holder.rotation.x = 0.0
		holder.rotation.z = 0.0
		holder.scale = Vector3.ONE * (0.7 + 0.25 * (i % 3))
		holder.visible = false
		add_child(holder)
		_flakes.append(holder)


## Combien de paillettes montrer pour `count` fleurs de sel (une par fleur, au plus MAX_FLAKES).
static func visible_flakes(count: int) -> int:
	return clampi(count, 0, MAX_FLAKES)


func show_count(count: int, surface_y: float) -> void:
	position.y = surface_y
	var n := visible_flakes(count)
	for i in _flakes.size():
		_flakes[i].visible = i < n


func _process(delta: float) -> void:
	_t += delta
	# Elles dérivent un tout petit peu à la surface.
	for i in _flakes.size():
		if _flakes[i].visible:
			_flakes[i].rotation.y += delta * (0.2 + 0.05 * (i % 3))
