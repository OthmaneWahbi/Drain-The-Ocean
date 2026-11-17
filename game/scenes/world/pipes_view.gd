extends Node3D
## Dessine les tuyaux posés (T2) : pour chaque pièce, un petit moyeu et un bras vers chaque
## voisin (pièce, pompe, zone en dessous). Les pièces où passe l'eau d'une pompe sont bleutées.
## Chaque pièce est un corps physique : on la vise pour poser à côté, ou pour la reprendre (E).
## Redessiné à chaque GameState.network_changed.

const DRY_COLOR := Color(0.32, 0.34, 0.38)
const WET_COLOR := Color(0.25, 0.5, 0.75)
## 0.1.8 : un peu plus gros, avec un manchon à chaque raccord entre deux pièces et un pied sous
## les pièces en l'air, pour qu'on lise le réseau comme une vraie tuyauterie (et qu'on compte les
## pièces).
const PIPE_RADIUS := 0.11
const COLLAR_COLOR := Color(0.22, 0.24, 0.28)


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
		var links := 0
		var straight := true
		for d in PipeNetwork.DIRS:
			if GameState.pipes.has(cell + d) or _touches_pump(cell, d):
				links += 1
				straight = straight and (GameState.pipes.has(cell - d) or _touches_pump(cell, -d))
		# Le cœur de la pièce : rien sur un tuyau droit (il passe tout droit), une boule de
		# jonction sur un coude, un T, une croix ou une pièce seule.
		if links != 2 or not straight:
			piece.add_child(Props.ball(PIPE_RADIUS * 1.35, color, Vector3.ZERO, 3))
		for d in PipeNetwork.DIRS:
			if GameState.pipes.has(cell + d):
				_arm(piece, Vector3(d) * cell_m * 0.5, color)
				if d.x + d.y + d.z > 0:  # un manchon par raccord (dessiné par une seule des deux pièces)
					var collar := Props.cyl(PIPE_RADIUS * 1.3, PIPE_RADIUS * 1.3, 0.1, COLLAR_COLOR, Vector3(d) * cell_m * 0.5, 10)
					_lay(collar, Vector3(d))
					piece.add_child(collar)
				# Solide jusqu'au bord de la case : une rangée de tuyaux se traverse en sautant dessus.
				var half := Vector3(d).abs() * cell_m * 0.25 + (Vector3.ONE - Vector3(d).abs()) * 0.15
				piece.add_child(Greybox.box_collision(half * 2.0, Vector3(d) * cell_m * 0.25))
			elif _touches_pump(cell, d):
				# Jusqu'au corps de la pompe, avec une bride : on voit d'où vient l'eau.
				_arm(piece, Vector3(d) * cell_m * 0.85, color)
				var flange := Props.cyl(PIPE_RADIUS * 1.7, PIPE_RADIUS * 1.7, 0.06, Props.IRON, Vector3(d) * cell_m * 0.6, 10)
				_lay(flange, Vector3(d))
				piece.add_child(flange)
		# Une pièce au-dessus d'une zone : un coude, une descente et un bec évasé jusqu'au bord du
		# bac ; quand l'eau passe, un filet d'eau tombe dedans (0.1.4 : on voit où ça verse).
		for zone in GameState.zones:
			if GameState.pipe_feeds(cell, zone):
				_spout(piece, color, wet.has(cell), (zone.position as Vector3).y + 0.45 - piece.position.y)
				break
		# Une pièce en l'air (rien dessous) : un piquet en bois la porte jusqu'au sol, avec un
		# collier en haut et une semelle en bas. Pas au-dessus d'une zone ni d'une pompe.
		if _needs_stand(cell):
			var ground := GameState.terrain.height(piece.position.x, piece.position.z) - piece.position.y
			if ground < -0.25:
				var post_h := -ground - PIPE_RADIUS
				piece.add_child(Props.box(Vector3(0.08, post_h, 0.08), Props.WOOD_DARK, Vector3(0, ground + post_h / 2.0, 0)))
				piece.add_child(Props.box(Vector3(0.22, 0.04, 0.22), Props.WOOD_DARK.darkened(0.2), Vector3(0, ground + 0.02, 0)))
				piece.add_child(_clamp_for(cell))
		# 0.1.6 (Othmane : « plus fun ») : les tuyaux sont solides, on peut marcher dessus. Le joueur
		# ne peut pas s'y enfermer pour de bon : l'anti-blocage (player.gd) le pose sur une place libre.
		piece.add_child(Greybox.box_collision(Vector3.ONE * 0.4))


## Rien sous cette pièce (ni tuyau, ni pompe, ni zone de séchage) : elle a besoin d'un pied.
func _needs_stand(cell: Vector3i) -> bool:
	if GameState.pipes.has(cell + Vector3i.DOWN) or _touches_pump(cell, Vector3i.DOWN):
		return false
	var cell_m: float = GameState.config.grid_cell_m
	var c := Vector3((cell.x + 0.5) * cell_m, 0.0, (cell.z + 0.5) * cell_m)
	for zone in GameState.zones:
		if PlacementGrid.distance_to(PlacementGrid.rect_shape(GameState.item_rect(zone)), c) < 0.01:
			return false
	for pump in GameState.pumps:
		if PlacementGrid.distance_to(PlacementGrid.rect_shape(GameState.item_rect(pump)), c) < 0.01:
			return false
	return true


## Le collier qui tient le tuyau en haut du piquet (en travers du tuyau).
func _clamp_for(cell: Vector3i) -> Node3D:
	var along_x := GameState.pipes.has(cell + Vector3i.RIGHT) or GameState.pipes.has(cell + Vector3i.LEFT)
	var size := Vector3(0.06, PIPE_RADIUS * 2.5, PIPE_RADIUS * 2.5) if along_x else Vector3(PIPE_RADIUS * 2.5, PIPE_RADIUS * 2.5, 0.06)
	return Props.box(size, COLLAR_COLOR, Vector3(0, -PIPE_RADIUS * 0.3, 0))


## Les filets d'eau ne coulent que pendant qu'une pompe débite (à l'instant).
func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	var flowing := false
	for pump in GameState.pumps:
		if now - int(pump.get("last_run_ms", -100000)) < 300:
			flowing = true
			break
	for piece in get_children():
		var stream := piece.get_node_or_null("Stream") as Node3D
		if stream:
			stream.visible = flowing
			stream.scale = Vector3(1.0 + sin(now * 0.03) * 0.15, 1.0, 1.0 + cos(now * 0.03) * 0.15)


## La case voisine (dans la direction `d`) est la pompe : son emprise au sol, ou la pompe juste
## en dessous (une pièce posée sur elle).
func _touches_pump(cell: Vector3i, d: Vector3i) -> bool:
	if not GameState.pump_at_cell(cell + d).is_empty():
		return true
	for pump in GameState.pumps:
		if PipeNetwork.cell_of(pump.position, GameState.config.grid_cell_m) == cell + d:
			return true
	return false


## Un bras de tuyau du centre de la pièce vers `to` (position locale).
## Couche un cylindre (debout sur Y) dans la direction `d`.
func _lay(mi: Node3D, d: Vector3) -> void:
	if absf(d.y) < 0.001:
		mi.rotation = Vector3(PI / 2.0, 0, 0) if absf(d.z) > absf(d.x) else Vector3(0, 0, PI / 2.0)


## La descente vers la zone : tuyau vertical jusqu'à `bottom` (repère de la pièce), bec évasé, et
## le filet d'eau quand la pièce est mouillée.
func _spout(piece: Node3D, color: Color, wet: bool, bottom: float) -> void:
	bottom = minf(bottom, -0.25)
	var down := Props.cyl(PIPE_RADIUS, PIPE_RADIUS, -bottom, color, Vector3(0, bottom / 2.0, 0), 8)
	piece.add_child(down)
	piece.add_child(Props.cyl(PIPE_RADIUS * 1.2, PIPE_RADIUS * 2.2, 0.14, Props.IRON, Vector3(0, bottom - 0.05, 0), 10))
	if wet:
		var stream := Props.cyl(0.04, 0.06, 0.35, Color(0.5, 0.8, 1.0, 0.6), Vector3(0, bottom - 0.3, 0), 8)
		stream.name = "Stream"
		stream.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		piece.add_child(stream)


func _arm(piece: Node3D, to: Vector3, color: Color) -> void:
	var length := to.length()
	var arm := Greybox.cylinder(PIPE_RADIUS, length, color, to / 2.0, 8)
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
