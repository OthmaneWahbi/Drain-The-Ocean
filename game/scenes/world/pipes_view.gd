extends Node3D
## Dessine les tuyaux posés (T2) : pour chaque pièce, un petit moyeu et un bras vers chaque
## voisin (pièce, pompe, zone en dessous). Les pièces où passe l'eau d'une pompe sont bleutées.
## Chaque pièce est un corps physique : on la vise pour poser à côté, ou pour la reprendre (E).
## Redessiné à chaque GameState.network_changed.

const DRY_COLOR := Color(0.32, 0.34, 0.38)
const WET_COLOR := Color(0.25, 0.5, 0.75)
const PIPE_RADIUS := 0.09


func _ready() -> void:
	GameState.network_changed.connect(rebuild)
	GameState.item_moved.connect(func(_it): rebuild())
	GameState.game_reset.connect(rebuild)
	rebuild()


func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	var cell_m: float = GameState.config.grid_cell_m
	var wet := GameState.wet_pipes()
	for cell: Vector3i in GameState.pipes:
		var piece := PipePiece.new()
		piece.cell = cell
		piece.position = PipeNetwork.cell_center(cell, cell_m, GameState.config.ground_y)
		add_child(piece)
		var color := WET_COLOR if wet.has(cell) else DRY_COLOR
		piece.add_child(Greybox.box(Vector3.ONE * PIPE_RADIUS * 2.6, color))
		for d in PipeNetwork.DIRS:
			if GameState.pipes.has(cell + d) or _touches_pump(cell, d):
				_arm(piece, Vector3(d) * cell_m * 0.5, color)
		# Une pièce au niveau 0 au-dessus d'une zone : un petit bec qui verse.
		for zone in GameState.zones:
			if PipeNetwork.feeds(cell, zone.position, GameState.inlet_radius(zone), cell_m):
				_arm(piece, Vector3(0, -0.2, 0), color)
				break
		piece.add_child(Greybox.box_collision(Vector3.ONE * 0.5))


func _touches_pump(cell: Vector3i, d: Vector3i) -> bool:
	for pump in GameState.pumps:
		if PipeNetwork.cell_of(pump.position, GameState.config.grid_cell_m) == cell + d:
			return true
	return false


## Un bras de tuyau du centre de la pièce vers `to` (position locale).
func _arm(piece: Node3D, to: Vector3, color: Color) -> void:
	var length := to.length()
	var arm := Greybox.cylinder(PIPE_RADIUS, length, color, to / 2.0, 8)
	arm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if absf(to.y) < 0.001:
		# Le cylindre est debout (axe Y) : on le couche dans la bonne direction.
		arm.rotation = Vector3(PI / 2.0, 0, 0) if absf(to.z) > absf(to.x) else Vector3(0, 0, PI / 2.0)
	piece.add_child(arm)


## Une pièce de tuyau : on la vise (E la reprend quand on tient les tuyaux).
class PipePiece extends StaticBody3D:
	var cell: Vector3i

	func get_prompt(_player: Node) -> String:
		if GameState.current_tool() == "tuyaux":
			return tr("PROMPT_PIPE_REMOVE")
		return tr("PIPE_NAME")

	func interact(_player: Node) -> void:
		if GameState.current_tool() == "tuyaux":
			GameState.remove_pipe(cell)
