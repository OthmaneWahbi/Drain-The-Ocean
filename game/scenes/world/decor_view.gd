extends StaticBody3D
## Objets décoratifs (gags). Le « bateau » commandé arrive… en bouteille (Q-12, M-53).
## C'est un corps physique pour qu'on puisse le viser et le déplacer (G).

var decor: Dictionary


func setup(p_decor: Dictionary) -> void:
	decor = p_decor
	position = decor.position
	# Les mêmes modèles que les photos du catalogue (ProductModels), à la taille réelle.
	match decor.kind:
		"bateau_en_bouteille":
			var boat := ProductModels.build("bateau")
			boat.scale = Vector3.ONE * 0.5
			add_child(boat)
		"flamant":
			# Le flamant rose gonflable payé en perle : un gag qui ne sert à rien.
			var bird := ProductModels.build("flamant")
			bird.scale = Vector3.ONE * 0.8
			add_child(bird)
		"parasol", "flamant_sel", "saliere", "bouee_canard", "nain_coquillages", "longue_vue", "feu_de_camp", "dalle", "cloture", "lampion", "tapis", "coquillage_geant":
			add_child(model(decor.kind))
		"hamac":
			add_child(IslandLife.hammock())
		"vitrine":
			_build_shelf()
		"catalogue_papier":
			# Le catalogue papier du premier appel : un gros livret rouge et blanc.
			add_child(Greybox.box(Vector3(0.42, 0.06, 0.3), Color(0.95, 0.95, 0.9), Vector3(0, 0.03, 0)))
			add_child(Greybox.box(Vector3(0.43, 0.012, 0.31), Greybox.PHONE_RED, Vector3(0, 0.066, 0)))
	match decor.kind:
		"hamac":
			add_child(Greybox.box_collision(Vector3(2.0, 0.6, 0.8), Vector3(0, 0.6, 0)))
		"vitrine":
			var h := GameState.collection_rows.size() * IslandLife.SHELF_ROW_H + 0.2
			add_child(Greybox.box_collision(Vector3(1.9, h, 0.5), Vector3(0, h / 2.0, 0)))
		"longue_vue", "lampion":
			add_child(Greybox.box_collision(Vector3(0.5, 1.3, 0.5), Vector3(0, 0.65, 0)))
		"feu_de_camp", "coquillage_geant":
			add_child(Greybox.box_collision(Vector3(0.8, 0.5, 0.8), Vector3(0, 0.25, 0)))
		"cloture":
			add_child(Greybox.box_collision(Vector3(1.0, 0.7, 0.2), Vector3(0, 0.35, 0)))
		"dalle", "tapis":
			# On marche dessus (on les vise quand même, pour les déplacer).
			add_child(Greybox.box_collision(Vector3(0.9 if decor.kind == "dalle" else 1.9, 0.06, 0.9 if decor.kind == "dalle" else 0.8), Vector3(0, 0.03, 0)))
			PhysicsLayers.make_walk_through(self)
		"parasol":
			add_child(Greybox.cylinder_collision(0.15, 2.1, Vector3(0, 1.05, 0)))
		"flamant_sel", "saliere", "nain_coquillages":
			add_child(Greybox.box_collision(Vector3(0.6, 1.0, 0.6), Vector3(0, 0.5, 0)))
		"bouee_canard":
			add_child(Greybox.box_collision(Vector3(0.8, 0.3, 0.8), Vector3(0, 0.15, 0)))
		_:
			add_child(Greybox.box_collision(Vector3(0.6, 0.3, 0.3), Vector3(0, 0.12, 0)))


## 0.1.22 : les décors « chic » et les surprises de l'agence (SaltGoods).
static func model(kind: String) -> Node3D:
	match kind:
		"parasol":
			return SaltGoods.parasol()
		"flamant_sel":
			return SaltGoods.salt_flamingo()
		"saliere":
			return SaltGoods.salt_shaker()
		"bouee_canard":
			return SaltGoods.duck_buoy()
		"nain_coquillages":
			return SaltGoods.shell_gnome()
		"longue_vue":
			return IslandGoods.spyglass()
		"feu_de_camp":
			return IslandGoods.campfire()
		"dalle":
			return IslandGoods.path_tile()
		"cloture":
			return IslandGoods.fence()
		"lampion":
			return IslandGoods.lantern()
		"tapis":
			return IslandGoods.mat()
		"coquillage_geant":
			return IslandGoods.giant_shell()
	return Node3D.new()


## 0.1.23 : le feu de camp et le lampion s'allument la nuit ; les flammes dansent.
var _t := 0.0
var _lit := false


func _process(delta: float) -> void:
	if decor.kind != "feu_de_camp" and decor.kind != "lampion":
		set_process(false)
		return
	_t += delta
	var night := not GameState.day.is_day()
	for fire in find_children("Fire", "", true, false):
		fire.visible = night
		for i in 3:
			var f: Node3D = fire.get_node_or_null("Flame%d" % i)
			if f:
				f.scale = Vector3(1.0, 1.0 + 0.25 * sin(_t * (9.0 + i * 3.0) + i), 1.0)
		var light: OmniLight3D = fire.get_node_or_null("Light")
		if light:
			light.light_energy = 2.0 + 0.5 * sin(_t * 13.0) + 0.3 * sin(_t * 7.3)
	for n in find_children("Light", "OmniLight3D", true, false):
		if n.get_parent().name != "Fire":
			n.visible = night
	if night != _lit:
		_lit = night
		for g in find_children("Glow", "", true, false):
			var mi := g as MeshInstance3D
			if mi == null:
				continue
			if night:
				IslandGoods._glow(mi, IslandGoods.LANTERN)
			else:
				mi.material_override = Props.mat(IslandGoods.LANTERN)


func get_prompt(_player: Node) -> String:
	match decor.kind:
		"hamac":
			return tr("PROMPT_SLEEP") if not GameState.day.is_day() else tr("PROMPT_NOT_SLEEPY")
		"vitrine":
			return tr("PROMPT_SHELF") % [GameState.collection_found_count(), GameState.collection_slots().size()]
		"longue_vue":
			return tr("PROMPT_SPYGLASS")
		"feu_de_camp":
			return tr("PROMPT_CAMPFIRE")
	return ""  # le joueur ajoute « [G] Déplacer » tout seul


## E sur le hamac, la nuit : fondu au noir, la nuit passe, on se réveille au matin (0.1.21).
func interact(player: Node) -> void:
	if decor.kind == "longue_vue":
		if player and player.has_method(&"enter_spyglass"):
			player.enter_spyglass(global_position + Vector3(0, 1.15, 0))
		return
	if decor.kind != "hamac" or GameState.day.is_day():
		return
	if player and player.has_method(&"sleep_fade"):
		player.sleep_fade(func(): GameState.sleep(decor.position))
	else:
		GameState.sleep(decor.position)


# --- La vitrine (0.1.21) -------------------------------------------------------------------

var _slots: Node3D
var _shown := {}


## L'étagère et une case par trouvaille : en couleur si trouvée, sinon sa silhouette sombre.
func _build_shelf() -> void:
	var rows := GameState.collection_rows
	var cols := 1
	for row in rows:
		cols = maxi(cols, (row.get("items", []) as Array).size())
	add_child(IslandLife.shelf(cols, rows.size()))
	_slots = Node3D.new()
	add_child(_slots)
	GameState.collection_changed.connect(_refresh_shelf)
	_refresh_shelf()


func _refresh_shelf() -> void:
	if _slots == null:
		return
	var rows := GameState.collection_rows
	var cols := 1
	for row in rows:
		cols = maxi(cols, (row.get("items", []) as Array).size())
	for r in rows.size():
		var items: Array = rows[r].get("items", [])
		for c in items.size():
			var id := String(items[c])
			var found := GameState.has_found(id)
			if _shown.get(id, null) == found:
				continue
			var old := _slots.get_node_or_null(id)
			if old:
				old.free()
			var m := Finds.model(id)
			m.name = id
			var size := Models.bounds(Models.vertices(m)).size
			var k := minf(1.0, 0.3 / maxf(maxf(size.x, size.z), 0.01))
			m.scale = Vector3.ONE * k
			m.position = IslandLife.shelf_slot(c, r, cols, rows.size())
			if not found:
				IslandLife.silhouette(m)
			_slots.add_child(m)
			_shown[id] = found


func get_movable() -> Dictionary:
	return decor
