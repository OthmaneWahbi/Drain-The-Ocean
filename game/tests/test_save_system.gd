extends TestCase

const DIR := "user://test_saves"


func before_each() -> void:
	for slot in [1, 2, 3]:
		SaveSystem.delete(slot, DIR)


func after_each() -> void:
	before_each()


func test_empty_slot_reads_empty() -> void:
	assert_false(SaveSystem.exists(1, DIR))
	assert_true(SaveSystem.read(1, DIR).is_empty())


func test_write_then_read() -> void:
	var err := SaveSystem.write(2, {"play_time_s": 42.5, "stock": {"sel": 3}}, DIR)
	assert_eq(err, OK, "écriture :")
	var data := SaveSystem.read(2, DIR)
	assert_almost(float(data["play_time_s"]), 42.5)
	assert_eq(int(data["stock"]["sel"]), 3)
	assert_eq(int(data["save_version"]), SaveSystem.SAVE_VERSION)


func test_manual_save_replaces_previous() -> void:
	SaveSystem.write(1, {"play_time_s": 1.0}, DIR)
	SaveSystem.write(1, {"play_time_s": 2.0}, DIR)
	assert_almost(float(SaveSystem.read(1, DIR)["play_time_s"]), 2.0)


func test_corrupted_file_reads_empty() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var f := FileAccess.open(SaveSystem.slot_path(3, DIR), FileAccess.WRITE)
	f.store_string("{ pas du json")
	f.close()
	assert_true(SaveSystem.read(3, DIR).is_empty())


func test_old_save_is_migrated() -> void:
	var data := SaveSystem.migrate({"play_time_s": 5.0})
	assert_eq(int(data["save_version"]), SaveSystem.SAVE_VERSION)
