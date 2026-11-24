extends GutTest


func test_real_constants() -> void:
	assert_eq(Units.EARTH_RADIUS_KM, 6371.0)
	assert_eq(Units.MOON_RADIUS_KM, 1737.4)
	assert_eq(Units.EARTH_MOON_DISTANCE_KM, 384_400.0)


func test_one_unit_is_one_km() -> void:
	assert_eq(Units.KM, 1.0)
	assert_almost_eq(Units.m_to_km(1000.0), 1.0, 1e-12)
	assert_almost_eq(Units.km_to_m(1.0), 1000.0, 1e-9)


func test_round_trip_is_exact_at_lunar_distance() -> void:
	var km: float = Units.EARTH_MOON_DISTANCE_KM + 0.001
	assert_almost_eq(Units.m_to_km(Units.km_to_m(km)), km, 1e-9)


func test_speed_conversions() -> void:
	assert_almost_eq(Units.mps_to_kmps(7800.0), 7.8, 1e-12)
	assert_almost_eq(Units.kmps_to_kmh(1.0), 3600.0, 1e-9)


func test_gdscript_float_is_64_bit() -> void:
	# The floating-origin design relies on this: 1 mm at lunar distance.
	var a: float = 384_400.0
	var b: float = a + 0.000001
	assert_ne(a, b, "float must keep sub-metre precision at 384,400 km")


func test_format_distance() -> void:
	assert_eq(Units.format_distance(0.25), "250 m")
	assert_eq(Units.format_distance(12.345), "12.35 km")
	assert_eq(Units.format_distance(384_400.0), "384,400 km")
	assert_eq(Units.format_distance(-1_234_567.0), "-1,234,567 km")


func test_format_mission_time() -> void:
	assert_eq(Units.format_mission_time(0.0), "T+00:00:00")
	assert_eq(Units.format_mission_time(3723.9), "T+01:02:03")
	assert_eq(Units.format_mission_time(-10.0), "T-00:00:10")


func test_camera_planes() -> void:
	assert_eq(Units.CAMERA_NEAR_KM, 0.001, "near plane is 1 m")
	assert_eq(Units.CAMERA_FAR_KM, 10_000.0)


func test_camera_depth_ratios_stay_inside_godot_limit() -> void:
	assert_true(Units.CAMERA_FAR_KM / Units.CAMERA_NEAR_KM <= Units.MAX_CAMERA_DEPTH_RATIO)
	assert_true(Units.FAR_LAYER_FAR_KM / Units.FAR_LAYER_NEAR_KM <= Units.MAX_CAMERA_DEPTH_RATIO)
