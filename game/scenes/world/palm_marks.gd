class_name PalmMarks
extends Node3D
## Les traits gravés sur le palmier (M-84) : un trait par réveil après une noyade, comme un
## calendrier de prisonnier. Posé contre le tronc d'un palmier (côté plage) ; la disposition vient
## de EndingLogic.tally_marks(). Purement visuel : aucune règle ici.

const MARK_COLOR := Color(0.2, 0.12, 0.07)

var _marks: Node3D


func _ready() -> void:
	_marks = Node3D.new()
	add_child(_marks)
	GameState.wakeups_changed.connect(refresh)
	refresh()


func refresh() -> void:
	for c in _marks.get_children():
		c.free()
	var layout := EndingLogic.tally_marks(GameState.wakeups)
	if layout.is_empty():
		return
	# On centre la première rangée sur l'écorce.
	var width := 0.0
	for m in layout:
		width = maxf(width, float(m.x))
	for m in layout:
		var mark := Greybox.box(Vector3(0.01, 0.11, 0.01), MARK_COLOR, Vector3(float(m.x) - width / 2.0, float(m.y), 0))
		mark.rotation_degrees.z = float(m.angle)
		mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_marks.add_child(mark)


func mark_count() -> int:
	return _marks.get_child_count()
