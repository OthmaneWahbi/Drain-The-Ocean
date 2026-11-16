extends TestCase
## Settings (classe statique) : set_value applique, prévient et ne touche pas au disque en test.


func test_set_value_updates_data_and_notifies() -> void:
	Settings.persist = false
	var before := Settings.data.to_dict()
	var n := [0]
	var cb := func(): n[0] += 1
	Settings.events.changed.connect(cb)
	Settings.set_value("fov", 95.0)
	assert_almost(Settings.data.fov, 95.0)
	assert_eq(n[0], 1)
	Settings.set_value("fov", 999.0)
	assert_almost(Settings.data.fov, 110.0, 1e-6, "borné")
	Settings.events.changed.disconnect(cb)
	Settings.data.load_dict(before)
	Settings.apply()
	Settings.persist = true
