class_name TerrainView
extends StaticBody3D
## Le terrain low poly de l'île (0.1.1), construit au lancement à partir de TerrainLogic :
## une grille dont les sommets sont un peu décalés au hasard (graine fixe), découpée en triangles
## qui ont chacun leurs propres sommets (facettes nettes, style low poly), colorés selon la hauteur
## et la pente. La collision est le même maillage (on marche exactement sur ce qu'on voit).
##
## 0.1.10 : la grille vient de TerrainLogic et le terrain est découpé en morceaux de CHUNK cases.
## Quand on travaille le sable à la pelle, seuls les morceaux touchés sont reconstruits.
##
## 0.1.11 : la grille est deux fois plus fine (sommets tous les 50 cm) et le sable a son propre
## matériau (SAND_SHADER : grains, rides, lumière cartoon). Un coup de pelle est **animé** : la
## case travaillée (et la couronne de petites cases autour) est retirée de son morceau et dessinée
## à part, dans un petit maillage dont les sommets glissent de leur ancienne hauteur à la nouvelle
## (le sable descend quand on creuse, monte quand on remblaie). À la fin, le morceau est refait
## en entier. La collision, elle, prend tout de suite la forme finale.

## Taille d'un morceau, en petites cases du maillage (0.1.11 : 32 cases de 50 cm, 16 m).
const CHUNK := 32
## La collision d'un morceau est en blocs de COL_BLOCK petites cases (0.1.14 : un coup de pelle
## ne refait que la collision des blocs touchés ; refaire celle d'un morceau entier coûtait ~2 ms).
const COL_BLOCK := 16
## En dessous de ce déplacement (m), un sommet ne s'anime pas (0.1.14).
const ANIM_MIN_M := 0.005
## Le temps (µs) par image pour redessiner la queue d'un éboulement, et la taille d'une bande.
const PENDING_BUDGET_US := 2500
const PENDING_ROWS := 8
## 0.1.15 : le dégradé du sable mouillé dans un trou de l'île (hauteurs en m, couleur).
const WET_TOP_Y := 0.3
const WET_FULL_Y := -0.3
const WET_HOLE := Color(0.56, 0.45, 0.27)
const SAND_SHADER := preload("res://scenes/world/sand.gdshader")

var logic: TerrainLogic
## Vector2i (morceau) -> [MeshInstance3D, CollisionShape3D]
var _chunks: Dictionary = {}
var _material: Material
## Les coups de pelle en cours d'animation : {rect (petites cases), before, after, delays, t, end, mesh}.
var _anims: Array[Dictionary] = []
## Les sommets qui ont vraiment bougé au dernier coup de pelle (refaits tout de suite).
var _significant: Array = []
## Les bandes de cases à refaire dans les images qui suivent un coup de pelle (voir _enqueue).
var _queue: Array[Dictionary] = []
## Les animations finies dont le maillage attend que les morceaux soient refaits.
var _finishing: Array[Dictionary] = []
var _gesture_frame := -10


func _ready() -> void:
	logic = GameState.terrain
	_material = make_material()
	var n := TerrainLogic.GRID_HALF * 2 / CHUNK
	for cj in n:
		for ci in n:
			_build_chunk(Vector2i(ci, cj))
	# Pelle, nouvelle partie, chargement : GameState donne les sommets changés.
	GameState.terrain_changed.connect(_on_terrain_changed)
	GameState.sand_moved.connect(_on_sand_moved)
	GameState.game_reset.connect(_finish_all)


## Le matériau du sable (statique : les tests et les captures s'en servent aussi).
static func make_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SAND_SHADER
	if GameState.config:
		mat.set_shader_parameter(&"level_cell_m", GameState.config.grid_cell_m)  # les carreaux du sol aplani
	return mat


## Le maillage complet (fonction statique : testable sans scène).
static func build_mesh(t: TerrainLogic) -> ArrayMesh:
	var h := TerrainLogic.GRID_HALF
	return build_chunk_mesh(t, -h, -h, h * 2, null)


## Le maillage des petites cases [i0, i0 + size[ × [j0, j0 + size[ (indices de sommet du coin bas).
## `skip` : des rectangles de petites cases à ne pas dessiner (animés à part).
## `heights` : des hauteurs à la place de celles de la logique, pour des sommets travaillés.
static func build_chunk_mesh(t: TerrainLogic, i0: int, j0: int, size: int, material: Material, skip: Array = [], heights: Dictionary = {}) -> ArrayMesh:
	return build_rect_mesh(t, Rect2i(i0, j0, size, size), material, skip, heights)


static func build_rect_mesh(t: TerrainLogic, rect: Rect2i, material: Material, skip: Array = [], heights: Dictionary = {}) -> ArrayMesh:
	return build_rect(t, rect, material, skip, heights, false).mesh


## Le maillage d'un rectangle de petites cases, et (`with_faces`) les triangles de sa collision.
## Renvoie {"mesh": ArrayMesh, "faces": PackedVector3Array}.
static func build_rect(t: TerrainLogic, rect: Rect2i, material: Material, skip: Array = [], heights: Dictionary = {}, with_faces: bool = false) -> Dictionary:
	var data := new_arrays(rect, with_faces)
	fill(t, rect, rect, skip, heights, data)
	var faces := PackedVector3Array()
	for f: PackedVector3Array in data.faces:
		faces.append_array(f)
	return {"mesh": make_mesh(data, material), "faces": faces}


## Les tableaux d'un rectangle : 6 sommets par petite case, à une place fixe (case (i, j) du
## rectangle → indices 6 × (j × largeur + i)). 0.1.14 : on peut ainsi ne refaire que les cases
## qu'un coup de pelle a touchées (`fill` sur un sous-rectangle), au lieu du morceau entier.
static func new_arrays(rect: Rect2i, with_faces: bool) -> Dictionary:
	var n := rect.size.x * rect.size.y * 6
	var verts := PackedVector3Array()
	verts.resize(n)
	var norms := PackedVector3Array()
	norms.resize(n)
	var cols := PackedColorArray()
	cols.resize(n)
	var faces := []  # un tableau de triangles par bloc de collision (COL_BLOCK × COL_BLOCK cases)
	if with_faces:
		var bx := ceili(float(rect.size.x) / COL_BLOCK)
		var by := ceili(float(rect.size.y) / COL_BLOCK)
		for q in bx * by:
			var f := PackedVector3Array()
			f.resize(COL_BLOCK * COL_BLOCK * 6)
			faces.append(f)
	return {"verts": verts, "norms": norms, "cols": cols, "faces": faces}


## Le maillage de ces tableaux (les cases cachées y sont des triangles plats, invisibles).
static func make_mesh(data: Dictionary, material: Material) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if (data.verts as PackedVector3Array).is_empty():
		return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = data.verts
	arrays[Mesh.ARRAY_NORMAL] = data.norms
	arrays[Mesh.ARRAY_COLOR] = data.cols
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material if material else make_material())
	return mesh


## Remplit les cases `sub` (dans `rect`) des tableaux `data` (voir `new_arrays`).
## 0.1.14 : refait pour la vitesse (un geste de pelle refaisait un morceau de 16 m en ~27 ms,
## deux fois : une saccade à chaque pelletée). Les sommets (et une bordure pour les normales) sont
## lus une seule fois dans une grille, leurs normales calculées une fois, et tout est écrit dans
## des tableaux. Les cases de `skip` (animées à part) sont des triangles plats ; la collision
## (`data.faces`, si elle existe) les garde.
## `keep_colors` : seulement les positions et les normales (les couleurs d'avant restent) ; pour
## l'animation, refaite à chaque image (0.1.14).
static func fill(t: TerrainLogic, rect: Rect2i, sub: Rect2i, skip: Array, heights: Dictionary, data: Dictionary, keep_colors: bool = false) -> void:
	sub = sub.intersection(rect)
	if sub.size.x <= 0 or sub.size.y <= 0:
		return
	# La grille des sommets lus : ceux des cases, plus une bordure de B sommets (les normales
	# regardent à 1 sommet, le « nivelé » d'un sommet regarde ses cases de 1 m, à 2 sommets).
	const B := 3
	var x0 := sub.position.x - B
	var y0 := sub.position.y - B
	var w := sub.size.x + 1 + 2 * B
	var hgt := sub.size.y + 1 + 2 * B
	var pos := PackedVector3Array()
	pos.resize(w * hgt)
	var edited := PackedByteArray()
	edited.resize(w * hgt)
	var edits := t.edits
	for jj in hgt:
		for ii in w:
			var key := Vector2i(x0 + ii, y0 + jj)
			var hv: Variant = edits.get(key)
			if hv != null:
				edited[jj * w + ii] = 1
				var y := float(heights[key]) if heights.has(key) else float(hv)
				pos[jj * w + ii] = Vector3(key.x * TerrainLogic.VERTEX_STEP, y, key.y * TerrainLogic.VERTEX_STEP)
			else:
				pos[jj * w + ii] = t.vertex(key.x, key.y)
	# Par sommet des cases, une fois : la normale, le sable sec selon la pente, la nuance, le
	# « nivelé » (traces de pelle : toutes ses cases de 1 m sont nivelées, voir _vertex_leveled).
	var nor := PackedVector3Array()
	nor.resize(w * hgt)
	var dry_col := PackedColorArray()
	dry_col.resize(w * hgt)
	var shade := PackedFloat32Array()
	shade.resize(w * hgt)
	var lev := PackedFloat32Array()
	lev.resize(w * hgt)
	var leveled := {}  # case de 1 m -> nivelée ?
	for jj in range(B, hgt - B):
		for ii in range(B, w - B):
			var k := jj * w + ii
			var dx := pos[k + 1] - pos[k - 1]
			var dz := pos[k + w] - pos[k - w]
			var n := dz.cross(dx).normalized()
			if n.y < 0.0:
				n = -n
			nor[k] = n
			if keep_colors:
				continue
			dry_col[k] = TerrainLogic.dry_sand_color(1.0 - n.y)
			shade[k] = 1.0 + (TerrainLogic.hash01(x0 + ii, y0 + jj, 5) * 2.0 - 1.0) * 0.05
			if edited[k] == 1:
				var all := 1.0
				var gx := x0 + ii
				var gy := y0 + jj
				for dd in 4:
					var cell := Vector2i(floori(float(gx - (dd & 1)) / TerrainLogic.SUB), floori(float(gy - (dd >> 1)) / TerrainLogic.SUB))
					var ok: Variant = leveled.get(cell)
					if ok == null:
						ok = _cell_flat(pos, edited, w, cell.x * TerrainLogic.SUB - x0, cell.y * TerrainLogic.SUB - y0)
						leveled[cell] = ok
					if not ok:
						all = 0.0
						break
				lev[k] = all
	var hidden := PackedByteArray()
	hidden.resize(sub.size.x * sub.size.y)
	for r: Rect2i in skip:
		var c := r.intersection(sub)
		for j in range(c.position.y, c.end.y):
			for i in range(c.position.x, c.end.x):
				hidden[(j - sub.position.y) * sub.size.x + (i - sub.position.x)] = 1
	var verts: PackedVector3Array = data.verts
	var norms: PackedVector3Array = data.norms
	var cols: PackedColorArray = data.cols
	data.verts = PackedVector3Array()  # (une seule référence : on écrit sans copie)
	data.norms = PackedVector3Array()
	data.cols = PackedColorArray()
	var blocks: Array = data.faces
	var with_faces := not blocks.is_empty()
	var bx := ceili(float(rect.size.x) / COL_BLOCK)
	var faces := PackedVector3Array()
	var cur_block := -1
	var ground_y := t.ground_y
	var ids := PackedInt32Array()
	ids.resize(6)
	for j in range(sub.position.y, sub.end.y):
		for i in range(sub.position.x, sub.end.x):
			var base := ((j - rect.position.y) * rect.size.x + (i - rect.position.x)) * 6
			var a := (j - y0) * w + (i - x0)  # le sommet (i, j) dans la grille
			var b := a + 1
			var c := a + w
			var d := a + w + 1
			if posmod(i + j, 2) == 0:
				ids[0] = a; ids[1] = c; ids[2] = b; ids[3] = b; ids[4] = c; ids[5] = d
			else:
				ids[0] = a; ids[1] = c; ids[2] = d; ids[3] = a; ids[4] = d; ids[5] = b
			if with_faces:
				var li := i - rect.position.x
				var lj := j - rect.position.y
				var blk := (lj / COL_BLOCK) * bx + li / COL_BLOCK
				if blk != cur_block:
					if cur_block >= 0:
						blocks[cur_block] = faces
					faces = blocks[blk]
					blocks[blk] = PackedVector3Array()
					cur_block = blk
				var fb := ((lj % COL_BLOCK) * COL_BLOCK + li % COL_BLOCK) * 6
				for q in 6:
					faces[fb + q] = pos[ids[q]]
			if hidden[(j - sub.position.y) * sub.size.x + (i - sub.position.x)] == 1:
				for q in 6:
					verts[base + q] = pos[a]
				continue
			var nv := base
			for tri in 2:
				var ka := ids[tri * 3]
				var kb := ids[tri * 3 + 1]
				var kc := ids[tri * 3 + 2]
				var pa := pos[ka]
				var pb := pos[kb]
				var pc := pos[kc]
				if (pb - pa).cross(pc - pa).y > 0.0:
					# Toutes les facettes dans le même sens (sens horaire vu d'en haut).
					var tk := kb
					kb = kc
					kc = tk
					var tp := pb
					pb = pc
					pc = tp
				if keep_colors:
					for k: int in [ka, kb, kc]:
						norms[nv] = nor[k]
						verts[nv] = pos[k]
						nv += 1
					continue
				var jitter := TerrainLogic.hash01(i, j, 5 + tri) * 2.0 - 1.0
				var fn := (pc - pa).cross(pb - pa).normalized()
				if fn.y < 0.0:
					fn = -fn
				var y := (pa.y + pb.y + pc.y) / 3.0
				var kind := t.ground_kind(y, 1.0 - fn.y, jitter)
				var blend := false
				# 0.1.14 : du sable travaillé n'est jamais de l'herbe (un tas posé haut devenait vert).
				if edited[ka] == 1 or edited[kb] == 1 or edited[kc] == 1:
					if kind <= TerrainLogic.Ground.DRY_GRASS:
						kind = TerrainLogic.Ground.DRY_SAND
					elif kind > TerrainLogic.Ground.WET_SAND and t.inland(pa.x, pa.z):
						# 0.1.14 : un trou profond dans l'île : du sable humide, pas le fond de la mer.
						kind = TerrainLogic.Ground.WET_SAND
					# 0.1.15 : dans un trou de l'île, le sable mouillé vient en dégradé, sommet par
					# sommet : choisi par facette, il découpait une étoile de triangles autour du fond.
					blend = (kind == TerrainLogic.Ground.DRY_SAND or kind == TerrainLogic.Ground.WET_SAND) and t.inland(pa.x, pa.z)
				var dry := kind == TerrainLogic.Ground.DRY_SAND
				var col := Color() if dry else TerrainLogic.kind_color(kind, 1.0 - fn.y)
				var low := y <= ground_y - 1.0
				for k: int in [ka, kb, kc]:
					var cv := dry_col[k] if dry else col
					if blend:
						cv = dry_col[k].lerp(WET_HOLE, smoothstep(WET_TOP_Y, WET_FULL_Y, pos[k].y))
					var sh := shade[k]
					# Le canal alpha dit au matériau si le sable a été nivelé à la pelle (traces).
					cols[nv] = Color(cv.r * sh, cv.g * sh, cv.b * sh, 0.0 if low else lev[k])
					norms[nv] = nor[k]
					verts[nv] = pos[k]
					nv += 1
	data.verts = verts
	data.norms = norms
	data.cols = cols
	if cur_block >= 0:
		blocks[cur_block] = faces


## Une case de 1 m dont les 9 sommets (à partir de l'indice local (ci, cj) de la grille) sont
## travaillés et à la même hauteur : nivelée (comme cell_worked et cell_level non NAN).
static func _cell_flat(pos: PackedVector3Array, edited: PackedByteArray, w: int, ci: int, cj: int) -> bool:
	var lo := INF
	var hi := -INF
	for b in TerrainLogic.SUB + 1:
		for a in TerrainLogic.SUB + 1:
			var k := (cj + b) * w + ci + a
			if edited[k] == 0:
				return false
			lo = minf(lo, pos[k].y)
			hi = maxf(hi, pos[k].y)
	return hi - lo <= TerrainLogic.FLAT_TOLERANCE


## 1 si toutes les cases de 1 m qui touchent ce sommet sont nivelées à la pelle, sinon 0
## (0.1.13 : les traces de pelle s'effacent en douceur au bord d'une zone nivelée).
static func _vertex_leveled(t: TerrainLogic, v: Vector2i, cache: Dictionary) -> float:
	if not t.edits.has(v):
		return 0.0
	for c in TerrainLogic.cells_of_vertex(v):
		if not cache.has(c):
			cache[c] = t.cell_worked(c) and not is_nan(t.cell_level(c))
		if not cache[c]:
			return 0.0
	return 1.0


func _chunk_origin(chunk: Vector2i) -> Vector2i:
	return Vector2i(-TerrainLogic.GRID_HALF + chunk.x * CHUNK, -TerrainLogic.GRID_HALF + chunk.y * CHUNK)


func _chunk_rect(chunk: Vector2i) -> Rect2i:
	return Rect2i(_chunk_origin(chunk), Vector2i(CHUNK, CHUNK))


## Refait un morceau : en entier, ou seulement les cases de `sub` (0.1.14 : un coup de pelle ne
## refait que les cases qu'il touche ; le maillage et la collision sont renvoyés tels quels).
func _build_chunk(chunk: Vector2i, with_collision: bool = true, sub := Rect2i()) -> void:
	var rect := _chunk_rect(chunk)
	var skip := []
	for a in _anims:
		if rect.intersects(a.rect):
			skip.append(a.rect)
	var parts: Dictionary = _chunks.get(chunk, {})
	if parts.is_empty():
		var mi := MeshInstance3D.new()
		mi.name = "Chunk_%d_%d" % [chunk.x, chunk.y]
		add_child(mi)
		var shapes := []
		var data := new_arrays(rect, true)
		for q in (data.faces as Array).size():
			var shape := CollisionShape3D.new()
			add_child(shape)
			shapes.append(shape)
		parts = {"mi": mi, "shapes": shapes, "data": data}
		_chunks[chunk] = parts
		sub = rect
	elif sub.size == Vector2i.ZERO:
		sub = rect
	sub = sub.intersection(rect)
	fill(logic, rect, sub, skip, {}, parts.data)
	(parts.mi as MeshInstance3D).mesh = make_mesh(parts.data, _material)
	if not with_collision:
		return
	# La collision suit la forme finale, sans les trous des animations : seuls les blocs touchés.
	var bx := ceili(float(CHUNK) / COL_BLOCK)
	var lo := (sub.position - rect.position) / COL_BLOCK
	var hi := (sub.end - Vector2i.ONE - rect.position) / COL_BLOCK
	for qj in range(lo.y, hi.y + 1):
		for qi in range(lo.x, hi.x + 1):
			var q := qj * bx + qi
			var concave := ConcavePolygonShape3D.new()
			concave.backface_collision = true  # on ne passe jamais à travers, quel que soit le sens d'une facette
			concave.set_faces(parts.data.faces[q])
			(parts.shapes[q] as CollisionShape3D).shape = concave


## Les cases à refaire autour de sommets changés : leurs cases, et une de plus (normales, traces).
static func dirty_rect(corners: Array) -> Rect2i:
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := -lo
	for v: Vector2i in corners:
		lo = Vector2i(mini(lo.x, v.x), mini(lo.y, v.y))
		hi = Vector2i(maxi(hi.x, v.x), maxi(hi.y, v.y))
	if hi.x < lo.x:
		return Rect2i()
	return Rect2i(lo - Vector2i(3, 3), hi - lo + Vector2i(6, 6))


## Les morceaux qui contiennent une petite case touchant un de ces sommets.
func _chunks_of_corners(corners: Array) -> Dictionary:
	var out := {}
	for c: Vector2i in corners:
		for d in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
			var ch := _chunk_of_small_cell(c + d)
			if ch.x >= 0:
				out[ch] = true
	return out


func _chunks_of_rect(rect: Rect2i) -> Dictionary:
	var out := {}
	var a := _chunk_of_small_cell_clamped(rect.position)
	var b := _chunk_of_small_cell_clamped(rect.end - Vector2i.ONE)
	for cj in range(a.y, b.y + 1):
		for ci in range(a.x, b.x + 1):
			out[Vector2i(ci, cj)] = true
	return out


func _chunk_of_small_cell_clamped(cell: Vector2i) -> Vector2i:
	var n := TerrainLogic.GRID_HALF * 2 / CHUNK
	var h := TerrainLogic.GRID_HALF
	return Vector2i(clampi(floori(float(cell.x + h) / CHUNK), 0, n - 1), clampi(floori(float(cell.y + h) / CHUNK), 0, n - 1))


func _chunk_of_small_cell(cell: Vector2i) -> Vector2i:
	var n := TerrainLogic.GRID_HALF * 2 / CHUNK
	var ch := Vector2i(floori(float(cell.x + TerrainLogic.GRID_HALF) / CHUNK), floori(float(cell.y + TerrainLogic.GRID_HALF) / CHUNK))
	if ch.x < 0 or ch.y < 0 or ch.x >= n or ch.y >= n:
		return Vector2i(-1, -1)
	return ch


## 0.1.14 : après un coup de pelle, les morceaux ne sont plus refaits dans l'image du geste (une
## saccade) mais juste après, par bandes de quelques rangées, dans un budget de temps par image
## (`_queue`) : d'abord ce qui a vraiment bougé (plus que ANIM_MIN_M ; l'animation le montre
## déjà), puis la queue de l'éboulement (quelques millimètres). La collision suit avec eux (une
## ou deux images de retard, au millimètre). Sans coup de pelle (nouvelle partie, chargement),
## tout est refait tout de suite.
func _on_terrain_changed(corners: Array) -> void:
	var dirty := dirty_rect(corners)
	if _significant.is_empty():
		for ch in _chunks_of_corners(corners):
			_build_chunk(ch, true, dirty)
		return
	var now := dirty_rect(_significant)
	_significant = []
	for ch in _chunks_of_rect(now):
		_enqueue(ch, now.intersection(_chunk_rect(ch)), true, true, {})
	for ch in _chunks_of_corners(corners):
		var r := dirty.intersection(_chunk_rect(ch))
		if not now.encloses(r):
			_enqueue(ch, r, false, true, {})


## Une bande à refaire : le morceau, ses cases, en premier ou non, avec la collision ou non, et
## l'animation qui attend la fin pour disparaître (vide si aucune).
func _enqueue(ch: Vector2i, r: Rect2i, urgent: bool, with_collision: bool, anim: Dictionary) -> void:
	if r.size.x <= 0 or r.size.y <= 0:
		if not anim.is_empty():
			_anim_part_done(anim)
		return
	var e := {"ch": ch, "rect": r, "col": with_collision, "anim": anim}
	if urgent:
		_queue.push_front(e)
	else:
		_queue.append(e)


## Refait ce qui attend, bande par bande, tant que le budget de l'image le permet (au moins une).
func _flush_pending(budget_us: int) -> void:
	var t0 := Time.get_ticks_usec()
	while not _queue.is_empty():
		var e: Dictionary = _queue[0]
		var r: Rect2i = e.rect
		var band := r
		if r.size.y > PENDING_ROWS:
			band.size.y = PENDING_ROWS
			e.rect = Rect2i(r.position.x, r.position.y + PENDING_ROWS, r.size.x, r.size.y - PENDING_ROWS)
		else:
			_queue.pop_front()
		_build_chunk(e.ch, e.col, band)
		if band == r and not (e.anim as Dictionary).is_empty():
			_anim_part_done(e.anim)
		if Time.get_ticks_usec() - t0 >= budget_us:
			break


func _anim_part_done(a: Dictionary) -> void:
	a.waiting = int(a.waiting) - 1
	if int(a.waiting) > 0:
		return
	_finishing.erase(a)
	if is_instance_valid(a.mesh):
		(a.mesh as MeshInstance3D).queue_free()


## Vrai s'il reste du sable à redessiner (pour les tests).
func has_pending() -> bool:
	return not _queue.is_empty()


# --- L'animation d'un coup de pelle (0.1.11, 0.1.12 : le sable s'éboule) ----------------------

## Les petites cases redessinées pendant l'animation : toutes celles qui touchent un sommet qui
## bouge (la pelletée et le sable qui s'éboule autour), et une couronne de plus.
static func anim_rect(vertices: Array) -> Rect2i:
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := -lo
	for v: Vector2i in vertices:
		lo = Vector2i(mini(lo.x, v.x), mini(lo.y, v.y))
		hi = Vector2i(maxi(hi.x, v.x), maxi(hi.y, v.y))
	if hi.x < lo.x:
		return Rect2i()
	return Rect2i(lo - Vector2i(2, 2), hi - lo + Vector2i(4, 4))


## Le retard de chaque sommet (s) : la pelletée bouge tout de suite, le sable qui s'éboule suit,
## de proche en proche depuis le point visé (on le voit glisser).
static func anim_delays(center: Vector3, before: Dictionary, after: Dictionary, start: float) -> Dictionary:
	var out := {}
	var c := Vector2(center.x, center.z)
	for v: Vector2i in after:
		var d := TerrainLogic.vertex_xz(v).distance_to(c)
		out[v] = start + maxf(d - 0.9, 0.0) * 0.12
	return out


func _on_sand_moved(center: Vector3, before: Dictionary, after: Dictionary, scoops: float) -> void:
	# 0.1.14 : seuls les sommets qui bougent vraiment s'animent (la queue de l'éboulement, au
	# millimètre, prend sa place tout de suite) : l'animation et ce qu'on refait restent petits.
	var b := {}
	var af := {}
	for v: Vector2i in after:
		if absf(float(after[v]) - float(before.get(v, after[v]))) > ANIM_MIN_M:
			b[v] = before[v]
			af[v] = after[v]
	if af.is_empty():
		return
	_significant = af.keys()
	_gesture_frame = Engine.get_process_frames()
	# On pose : le sable monte quand la pelletée arrive (le temps qu'elle vole).
	var start := SandFx.FILL_FLIGHT_S if scoops < 0.0 else 0.0
	# 0.1.15 : aplanir s'anime d'un seul mouvement, court et doux (tout le carré ensemble).
	var level := GameState.sand_gesture == GameState.Gesture.LEVEL
	var duration := GameState.config.level_anim_s if level else GameState.config.dig_anim_s
	var delays := {}
	if level:
		for v: Vector2i in af:
			delays[v] = 0.0
	else:
		delays = anim_delays(center, b, af, start)
	var rect := anim_rect(af.keys())
	# 0.1.14 : un coup sur du sable encore en mouvement reprend l'ancienne animation là où elle
	# en est (au lieu de la finir d'un coup et de refaire ses cases dans le morceau, deux fois).
	for a in _anims.duplicate() + _finishing.duplicate():
		if not a.rect.intersects(rect.grow(1)):
			continue
		var cur := anim_heights(a.before, a.after, a.delays, a.t, a.duration, a.smooth)
		for v: Vector2i in a.after:
			if af.has(v):
				b[v] = cur[v]  # on repart de ce qu'on voit
			else:
				b[v] = cur[v]
				af[v] = a.after[v]
				delays[v] = maxf(float(a.delays.get(v, 0.0)) - a.t, 0.0)
		rect = rect.merge(a.rect)
		_anims.erase(a)
		_finishing.erase(a)
		if is_instance_valid(a.mesh):
			(a.mesh as MeshInstance3D).queue_free()
	var mi := MeshInstance3D.new()
	mi.name = "SandAnim"
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
	var a := {"rect": rect, "before": b, "after": af, "delays": delays, "t": 0.0, "mesh": mi, "duration": duration, "smooth": level}
	a.end = 0.0
	for v in delays:
		a.end = maxf(a.end, float(delays[v]))
	a.end += maxf(duration, 0.01)
	_anims.append(a)
	_draw_anim(a)
	# terrain_changed suit : les morceaux seront refaits avec le trou de l'animation.


func _process(delta: float) -> void:
	if not _queue.is_empty():
		# L'image d'un coup de pelle a déjà son geste à calculer : on en fait moins.
		var busy := Engine.get_process_frames() - _gesture_frame <= 1
		_flush_pending(PENDING_BUDGET_US / 3 if busy else PENDING_BUDGET_US)
	if _anims.is_empty():
		return
	for a in _anims.duplicate():
		a.t += delta
		if a.t >= a.end:
			_finish(a)
		else:
			_draw_anim(a)


## Les hauteurs animées au temps `t` (s) : chaque sommet glisse de l'ancienne hauteur à la
## nouvelle après son retard, en `duration` s, avec un petit rebond à la fin.
## 0.1.15 : `smooth` (aplanir) : une courbe douce sans rebond (le sol se lisse, il ne saute pas).
static func anim_heights(before: Dictionary, after: Dictionary, delays: Dictionary, t: float, duration: float, smooth := false) -> Dictionary:
	var out := {}
	for v: Vector2i in after:
		var k := clampf((t - float(delays.get(v, 0.0))) / maxf(duration, 0.01), 0.0, 1.0)
		var e := smoothstep(0.0, 1.0, k) if smooth else ease_out_back(k)
		out[v] = lerpf(float(before.get(v, after[v])), float(after[v]), e)
	return out


static func ease_out_back(t: float) -> float:
	var c := 1.4
	return 1.0 + (c + 1.0) * pow(t - 1.0, 3.0) + c * pow(t - 1.0, 2.0)


func _draw_anim(a: Dictionary) -> void:
	var heights := anim_heights(a.before, a.after, a.delays, a.t, a.duration, a.smooth)
	if not a.has("data"):
		a.data = new_arrays(a.rect, false)
		a.frame = 0
	# Les couleurs (sable sec, mouillé…) suivent la hauteur toutes les 4 images, et à la fin.
	a.frame = int(a.frame) + 1
	fill(logic, a.rect, a.rect, [], heights, a.data, int(a.frame) % 4 != 1 and a.t < a.end)
	(a.mesh as MeshInstance3D).mesh = make_mesh(a.data, _material)


func _finish(a: Dictionary) -> void:
	_anims.erase(a)
	_finishing.append(a)
	a.t = a.end
	_draw_anim(a)
	# Le maillage animé reste (à sa forme finale) jusqu'à ce que ses cases soient refaites dans
	# les morceaux (la collision y est déjà à jour).
	var chunks := _chunks_of_rect(a.rect)
	a.waiting = chunks.size()
	for ch in chunks:
		_enqueue(ch, a.rect.intersection(_chunk_rect(ch)), true, false, a)


func _finish_all() -> void:
	for a in _anims.duplicate():
		_finish(a)
	while not _queue.is_empty():
		_flush_pending(1 << 30)


## Vrai pendant qu'un coup de pelle s'anime (pour les tests).
func is_animating() -> bool:
	return not _anims.is_empty() or not _queue.is_empty() or not _finishing.is_empty()


## La hauteur du sol ici (pour les vues qui posent des choses).
func height_at(x: float, z: float) -> float:
	return logic.height(x, z)
