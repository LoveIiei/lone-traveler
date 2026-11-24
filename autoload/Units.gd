extends Node
## Units and real-world constants. 1 Godot unit = 1 km; time is in seconds.
## Autoloaded as `Units`. Every function here is static, so scripts can also
## use it through preload() without the autoload (e.g. in tools or tests).

const KM: float = 1.0
const M: float = 0.001

const EARTH_RADIUS_KM: float = 6371.0
const MOON_RADIUS_KM: float = 1737.4
const EARTH_MOON_DISTANCE_KM: float = 384_400.0
const AU_KM: float = 149_597_870.7

## Near camera: 1 m to 10,000 km. Godot's light culler fails to build the
## frustum ("create_frustum_points" errors every frame) once far/near reaches
## ~1e8 (measured on 4.7.2: 1e7 is clean), so one camera can't span 1 m to
## 2,000,000 km. Distant bodies go in a far-camera layer (M1).
const CAMERA_NEAR_KM: float = 0.001
const CAMERA_FAR_KM: float = 10_000.0
const MAX_CAMERA_DEPTH_RATIO: float = 1.0e7
## Far layer target range (M1): covers the Moon from Earth and beyond.
const FAR_LAYER_NEAR_KM: float = 1.0
const FAR_LAYER_FAR_KM: float = 2_000_000.0


static func m_to_km(meters: float) -> float:
	return meters * M


static func km_to_m(km: float) -> float:
	return km / M


## Speed in m/s to km/s (the sim's speed unit).
static func mps_to_kmps(mps: float) -> float:
	return mps * M


static func kmps_to_kmh(kmps: float) -> float:
	return kmps * 3600.0


## Human-readable distance: metres below 1 km, km with thousands separators above.
static func format_distance(km: float) -> String:
	var a: float = absf(km)
	if a < 1.0:
		return "%d m" % roundi(km_to_m(km))
	if a < 100.0:
		return "%.2f km" % km
	return "%s km" % _group_thousands(roundi(km))


## Mission-clock style time: "T+01:02:03" or "T-00:00:10".
static func format_mission_time(seconds: float) -> String:
	var sign_str: String = "-" if seconds < 0.0 else "+"
	var total: int = floori(absf(seconds))
	var h: int = total / 3600
	var m: int = (total % 3600) / 60
	var s: int = total % 60
	return "T%s%02d:%02d:%02d" % [sign_str, h, m, s]


static func _group_thousands(n: int) -> String:
	var digits: String = str(absi(n))
	var out: String = ""
	var count: int = 0
	for i: int in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" + out) if n < 0 else out
