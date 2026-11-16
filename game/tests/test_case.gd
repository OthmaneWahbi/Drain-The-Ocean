class_name TestCase
extends RefCounted
## Base minimale des tests. Chaque méthode « test_* » d'un fichier tests/test_*.gd est exécutée.

var failures: Array[String] = []
var _current: String = ""


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func fail(message: String) -> void:
	failures.append("%s : %s" % [_current, message])


func assert_true(value: bool, message: String = "attendu vrai") -> void:
	if not value:
		fail(message)


func assert_false(value: bool, message: String = "attendu faux") -> void:
	if value:
		fail(message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		fail("%s attendu %s, obtenu %s" % [message, str(expected), str(actual)])


func assert_almost(actual: float, expected: float, tolerance: float = 1e-6, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		fail("%s attendu ≈%s, obtenu %s" % [message, str(expected), str(actual)])
