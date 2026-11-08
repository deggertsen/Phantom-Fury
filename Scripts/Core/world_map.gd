extends RefCounted
class_name WorldMap

## The war, as data. Two tears, two fronts, and cities whose state is their distance to the
## nearest front: consumed behind it, overrun on it, in danger near it, threatened farther out,
## safe beyond. The state is the tier. Picking a city opens one section of it, a short generated
## path of districts; three seals along a connected path are an operation, and operations are
## what liberate a city. See development/World_Map_Design.md.

const STATE_CONSUMED := "consumed"
const STATE_OVERRUN := "overrun"
const STATE_DANGER := "danger"
const STATE_THREATENED := "threatened"
const STATE_SAFE := "safe"

## Distances in projected map units (WorldCoastline's 1000 by 560 box). One degree of
## longitude is about 2.8 units.
const OVERRUN_UNITS := 16.0
const DANGER_UNITS := 48.0
const THREATENED_UNITS := 80.0

## District kinds. The ids stay in saved records (record_key), so the old four keep theirs.
## Each difficulty level has its own roster (ROSTERS, development/Difficulty_Matrix.md).
const KIND_SINGLE := "single"
const KIND_HOLD := "hold"
const KIND_FIRST_CHARGE := "first_charge"
const KIND_FLURRY := "flurry"
const KIND_DUAL := "dual"
const KIND_LOW_CEILING := "low_ceiling"
const KIND_CLOSE_SECTOR := "close_sector"
const KIND_STORM := "storm"
const KIND_UNDERTOW := "undertow"
const KIND_LAST_STAND := "last_stand"
const KIND_MAW := "maw"
const KINDS: Array[String] = [KIND_SINGLE, KIND_HOLD, KIND_FIRST_CHARGE, KIND_FLURRY, KIND_DUAL, KIND_LOW_CEILING, KIND_CLOSE_SECTOR, KIND_STORM, KIND_UNDERTOW, KIND_LAST_STAND, KIND_MAW]

## The three difficulty levels the cards show (EASY, MEDIUM, HARD), from the tier a city plays at.
const LEVEL_EASY := "easy"
const LEVEL_MEDIUM := "medium"
const LEVEL_HARD := "hard"
## Every level's missions (David, 2026-11-08): the first two columns of a section draw from
## "regular", and the third column is one district, the level's finale. Intensity rises at every
## level whatever the kind, and harder levels run longer.
const ROSTERS := {
	LEVEL_EASY: {"regular": [KIND_SINGLE, KIND_HOLD], "finale": KIND_FIRST_CHARGE},
	LEVEL_MEDIUM: {"regular": [KIND_FLURRY, KIND_DUAL, KIND_LOW_CEILING], "finale": KIND_CLOSE_SECTOR},
	LEVEL_HARD: {"regular": [KIND_FLURRY, KIND_STORM, KIND_UNDERTOW, KIND_LAST_STAND], "finale": KIND_MAW},
}
## How often Close the Sector is the Maw's lighter form instead of a harder Crossfire, decided per
## section so a card never changes under the player. The card does not say which.
const SECTOR_BOSS_ODDS := 0.4

## The ground each tear has taken, in longitude and latitude, as a fresh profile finds it: the
## seeded operations are already in these shapes. Nothing pushes them outward until the war has
## a heartbeat; the player's operations pull them back toward their tear (see zone_polygons).
const ZONES := {
	"jakarta": [[58, 36], [66, 30], [80, 26], [96, 27], [118, 28], [134, 31], [150, 34], [166, 10], [160, -42], [112, -46], [90, -40], [72, -30], [60, -8], [55, 10]],
	"chicago": [[-101, 50], [-90, 50], [-82, 46], [-78, 41], [-83, 33.5], [-92, 31.5], [-96, 36], [-100, 44]],
}
## How far a front recedes, as a fraction of its authored shape, once every one of its cities is
## liberated. Each completed operation inside a front shrinks it toward its tear by its share;
## the tear's own city is the last thing standing, and liberating it ends that front.
const RECESSION_MAX := 0.88

## ops is the resistance: operations to liberate. opsDone seeds a fresh profile's war so the map
## is not empty on day one; the player's own operations add to it.
const CITIES := [
	{"id": "portland", "name": "Portland", "lon": -122.7, "lat": 45.5, "ops": 8, "seed_ops": 2, "home": true, "blurb": "Your home city. Breach Night happened here. The northern front is a mountain range away and getting closer."},
	{"id": "vancouver", "name": "Vancouver", "lon": -123.1, "lat": 49.3, "ops": 6, "seed_ops": 1, "blurb": "Threatened. Behind the Rockies, for now."},
	{"id": "denver", "name": "Denver", "lon": -105.0, "lat": 39.7, "ops": 12, "seed_ops": 1, "blurb": "The northern front's western edge. Nobody is here."},
	{"id": "chicago", "name": "Chicago", "lon": -87.6, "lat": 41.9, "ops": 40, "seed_ops": 0, "origin": "SECOND TEAR", "blurb": "The Second Tear. The Overseer opened a second door here on day 31, and the Midwest went in a month."},
	{"id": "toronto", "name": "Toronto", "lon": -79.4, "lat": 43.7, "ops": 20, "seed_ops": 3, "blurb": "Overrun. A Maw rose on the lakefront."},
	{"id": "new_york", "name": "New York", "lon": -74.0, "lat": 40.7, "ops": 24, "seed_ops": 6, "blurb": "On the front. The most fought-over city in the north."},
	{"id": "atlanta", "name": "Atlanta", "lon": -84.4, "lat": 33.7, "ops": 16, "seed_ops": 1, "blurb": "Overrun as the front turned south."},
	{"id": "mexico_city", "name": "Mexico City", "lon": -99.1, "lat": 19.4, "ops": 8, "seed_ops": 4, "blurb": "Threatened. The front is a few days north of the border."},
	{"id": "bogota", "name": "Bogotá", "lon": -74.1, "lat": 4.7, "ops": 0, "seed_ops": 0, "blurb": "Safe. Nothing has crossed the isthmus."},
	{"id": "lima", "name": "Lima", "lon": -77.0, "lat": -12.0, "ops": 0, "seed_ops": 0, "blurb": "Safe. Quiet nights."},
	{"id": "sao_paulo", "name": "São Paulo", "lon": -46.6, "lat": -23.5, "ops": 0, "seed_ops": 0, "blurb": "Safe, and the largest city on Earth still whole."},
	{"id": "buenos_aires", "name": "Buenos Aires", "lon": -58.4, "lat": -34.6, "ops": 0, "seed_ops": 0, "blurb": "Safe."},
	{"id": "berlin", "name": "Berlin", "lon": 13.4, "lat": 52.5, "ops": 0, "seed_ops": 0, "blurb": "Safe. The RSF's European base; strikers deploy from here."},
	{"id": "cairo", "name": "Cairo", "lon": 31.2, "lat": 30.0, "ops": 6, "seed_ops": 3, "blurb": "Threatened. Two cities behind Tehran."},
	{"id": "lagos", "name": "Lagos", "lon": 3.4, "lat": 6.5, "ops": 0, "seed_ops": 0, "blurb": "Safe."},
	{"id": "johannesburg", "name": "Johannesburg", "lon": 28.0, "lat": -26.2, "ops": 0, "seed_ops": 0, "blurb": "Safe."},
	{"id": "nairobi", "name": "Nairobi", "lon": 36.8, "lat": -1.3, "ops": 6, "seed_ops": 2, "blurb": "Threatened. It watches the Indian Ocean."},
	{"id": "moscow", "name": "Moscow", "lon": 37.6, "lat": 55.8, "ops": 0, "seed_ops": 0, "blurb": "Safe, and cold for other reasons."},
	{"id": "tehran", "name": "Tehran", "lon": 51.4, "lat": 35.7, "ops": 12, "seed_ops": 2, "blurb": "In danger. The southern front's western edge is a week away."},
	{"id": "delhi", "name": "Delhi", "lon": 77.2, "lat": 28.6, "ops": 24, "seed_ops": 2, "blurb": "Overrun. On the front itself; the junction fell in the second week."},
	{"id": "beijing", "name": "Beijing", "lon": 116.4, "lat": 39.9, "ops": 14, "seed_ops": 3, "blurb": "In danger. The front is moving north through the plain."},
	{"id": "seoul", "name": "Seoul", "lon": 127.0, "lat": 37.6, "ops": 12, "seed_ops": 2, "blurb": "In danger."},
	{"id": "tokyo", "name": "Tokyo", "lon": 139.7, "lat": 35.7, "ops": 28, "seed_ops": 7, "blurb": "Overrun, and fought over every night. The front has stalled here for a month."},
	{"id": "mumbai", "name": "Mumbai", "lon": 72.9, "lat": 19.1, "ops": 30, "seed_ops": 0, "blurb": "Consumed in the third week."},
	{"id": "bangkok", "name": "Bangkok", "lon": 100.5, "lat": 13.8, "ops": 30, "seed_ops": 0, "blurb": "Consumed in the first week."},
	{"id": "jakarta", "name": "Jakarta", "lon": 106.8, "lat": -6.2, "ops": 60, "seed_ops": 0, "origin": "THE BREACH", "blurb": "The Breach. Day zero. The experiments were here."},
	{"id": "manila", "name": "Manila", "lon": 121.0, "lat": 14.6, "ops": 30, "seed_ops": 0, "blurb": "Consumed in the first week."},
	{"id": "perth", "name": "Perth", "lon": 115.9, "lat": -31.9, "ops": 20, "seed_ops": 0, "blurb": "Consumed."},
	{"id": "sydney", "name": "Sydney", "lon": 151.2, "lat": -33.9, "ops": 30, "seed_ops": 0, "blurb": "Consumed in the second week. The last broadcast came from here."},
]

## The world map zooms to a region before a city is picked: one region per continent, each an
## authored box in longitude and latitude ([west, south, east, north]) rather than one grown from
## its cities, so no box crosses into another continent (David, 2026-10-26: Asia was taking part
## of Australia). Asia stops at Australia's north coast; Europe and Africa split along the
## Mediterranean; Europe and Africa meet Asia at 45 east. Boxes may share an edge but never
## overlap; every city is in exactly one and inside its box. label is where the region's name
## sits on the world view, in longitude and latitude.
const REGIONS := [
	{"id": "north_america", "name": "North America", "box": [-170, 10, -50, 84], "label": [-100, 62], "cities": ["portland", "vancouver", "denver", "chicago", "toronto", "new_york", "atlanta", "mexico_city"]},
	{"id": "south_america", "name": "South America", "box": [-82, -57, -33, 10], "label": [-62, -12], "cities": ["bogota", "lima", "sao_paulo", "buenos_aires"]},
	{"id": "europe", "name": "Europe", "box": [-25, 36, 45, 72], "label": [8, 64], "cities": ["berlin", "moscow"]},
	{"id": "africa", "name": "Africa", "box": [-20, -36, 45, 36], "label": [20, 16], "cities": ["cairo", "lagos", "nairobi", "johannesburg"]},
	# Asia is two boxes: the mainland north of Hong Kong's latitude, and a South Asian pocket for
	# India and Arabia. Oceania takes Southeast Asia and Indonesia with Australia (David,
	# 2026-11-01), up to Hong Kong's latitude.
	{"id": "asia", "name": "Asia", "boxes": [[45, 23, 180, 78], [45, 5, 95, 23]], "label": [100, 52], "cities": ["tehran", "delhi", "mumbai", "beijing", "seoul", "tokyo"]},
	{"id": "oceania", "name": "Oceania", "box": [95, -50, 180, 23], "label": [134, -22], "cities": ["bangkok", "manila", "jakarta", "perth", "sydney"]},
]
## The side of the box the map closes in on when a city opens.
const CITY_ZOOM_UNITS := 44.0

## Generic district names; a city's sections draw from these. No in-world place names.
const DISTRICT_NAMES: Array[String] = ["Harbor", "Rail Yards", "Junction", "Stadium", "Reservoir", "Old Town", "Civic Ring", "Foundry", "Airport", "Docks", "University", "Bluffs", "Quarry", "Northgate", "Eastbank", "Riverside"]
## A district's breach-site id is its name as a key ("Rail Yards" is rail_yards). BreachSites
## decides which environment each one plays in; anything it does not know falls back to this.
const DEFAULT_SITE := "dead_city"

## Where a section's three columns sit on an 820 by 500 map, and how rows spread in a column.
const COLUMN_X: Array[float] = [140.0, 410.0, 680.0]
const ROW_STEP := 150.0
const MAP_SIZE := Vector2(820, 500)

# --- Geometry -------------------------------------------------------------------------------

## Longitude and latitude into WorldCoastline's box.
static func project(lon: float, lat: float) -> Vector2:
	return Vector2(
		(lon + 180.0) / 360.0 * WorldCoastline.WIDTH,
		(WorldCoastline.LAT_TOP - lat) / (WorldCoastline.LAT_TOP - WorldCoastline.LAT_BOTTOM) * WorldCoastline.HEIGHT
	)

## The authored fronts as projected polygons, keyed by the tear that opened them.
static func base_zone_polygons() -> Dictionary:
	var out := {}
	for key in ZONES:
		var polygon := PackedVector2Array()
		for point in ZONES[key]:
			polygon.append(project(float(point[0]), float(point[1])))
		out[key] = polygon
	return out

## The fronts as the player's war has left them: each authored shape scaled toward its tear by
## that front's recession. A front whose tear has been liberated is gone. With no settings, the
## fronts are the authored shapes.
static func zone_polygons(settings: Object = null) -> Dictionary:
	return _zones_for(recession(settings), settings)

static func _zones_for(pulled: Dictionary, settings: Object) -> Dictionary:
	var out := {}
	var base := base_zone_polygons()
	for key in base:
		if _origin_liberated(settings, key):
			continue
		var scale := 1.0 - RECESSION_MAX * float(pulled.get(key, 0.0))
		var origin := _raw_city(key)
		var center := project(float(origin.get("lon", 0.0)), float(origin.get("lat", 0.0)))
		var polygon := PackedVector2Array()
		for point in base[key]:
			polygon.append(center + (point - center) * scale)
		out[key] = polygon
	return out

## The tear a city's fight counts toward: the nearest authored front. "" for a city with no
## operations to fight.
static func zone_of(city_id: String) -> String:
	var raw := _raw_city(city_id)
	if raw.is_empty() or int(raw.get("ops", 0)) <= 0:
		return ""
	var point := project(float(raw["lon"]), float(raw["lat"]))
	var best_key := ""
	var best := INF
	var base := base_zone_polygons()
	for key in base:
		var polygon: PackedVector2Array = base[key]
		var distance := 0.0 if Geometry2D.is_point_in_polygon(point, polygon) else distance_to_polygon(point, polygon)
		if distance < best:
			best = distance
			best_key = key
	return best_key

## Each front's push-back, 0 to 1: the operations the player has completed in its cities, over
## the operations those cities still took when the profile began. The tear's own city does not
## count; it opens when the rest are done. A city the receding front has left safe counts as
## done too, since there is nothing left to fight there, so the push-back settles at a fixed
## point: more recession leaves more cities safe, never fewer.
static func recession(settings: Object) -> Dictionary:
	var remaining := {}
	var fights: Array[Dictionary] = []
	for key in ZONES:
		remaining[key] = 0
	for raw in CITIES:
		if raw.has("origin") or int(raw.get("ops", 0)) <= 0:
			continue
		var key := zone_of(String(raw["id"]))
		if key == "":
			continue
		var left := int(raw["ops"]) - int(raw.get("seed_ops", 0))
		var player_ops := clampi(int(progress_for(settings, String(raw["id"]))["ops_done"]) - int(raw.get("seed_ops", 0)), 0, left)
		remaining[key] += left
		fights.append({"key": key, "left": left, "done": player_ops, "point": project(float(raw["lon"]), float(raw["lat"]))})
	var out := {}
	for key in ZONES:
		out[key] = 0.0
	for _pass in 8:
		var zones := _zones_for(out, settings)
		var done := {}
		for key in ZONES:
			done[key] = 0
		for fight in fights:
			var counted: int = fight["done"]
			if counted < int(fight["left"]) and not zones.has(fight["key"]):
				counted = fight["left"]
			elif counted < int(fight["left"]) and state_in(fight["point"], zones)["state"] == STATE_SAFE:
				counted = fight["left"]
			done[fight["key"]] += counted
		var changed := false
		for key in ZONES:
			var next := clampf(float(done[key]) / maxf(float(remaining[key]), 1.0), 0.0, 1.0)
			if not is_equal_approx(next, float(out[key])):
				changed = true
			out[key] = next
		if not changed:
			break
	return out

static func _raw_city(city_id: String) -> Dictionary:
	for raw in CITIES:
		if raw.get("id", "") == city_id:
			return raw
	return {}

static func _is_liberated(settings: Object, raw: Dictionary) -> bool:
	var ops := int(raw.get("ops", 0))
	return ops > 0 and int(progress_for(settings, String(raw.get("id", "")))["ops_done"]) >= ops

static func _origin_liberated(settings: Object, zone_key: String) -> bool:
	var raw := _raw_city(zone_key)
	return not raw.is_empty() and _is_liberated(settings, raw)

## The whole projected map.
static func world_box() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(WorldCoastline.WIDTH, WorldCoastline.HEIGHT))

## Every region with its projected label point and box.
## Each region with its label point, its projected boxes (one button each), and "box", the
## rectangle around them that the map zooms to.
static func regions() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for raw in REGIONS:
		var region_data: Dictionary = (raw as Dictionary).duplicate()
		region_data["label_point"] = project(float(raw["label"][0]), float(raw["label"][1]))
		var boxes: Array[Rect2] = []
		for degrees in region_boxes(raw):
			boxes.append(_degrees_box(degrees))
		region_data["boxes"] = boxes
		region_data["box"] = region_box(raw)
		out.append(region_data)
	return out

## A region's authored boxes ([west, south, east, north] in degrees): "boxes", or the one "box".
static func region_boxes(raw: Dictionary) -> Array:
	if raw.has("boxes"):
		return raw["boxes"]
	return [raw["box"]]

## The projected rectangle around all of a region's boxes.
static func region_box(raw: Dictionary) -> Rect2:
	var rect := Rect2()
	var first := true
	for degrees in region_boxes(raw):
		var box := _degrees_box(degrees)
		rect = box if first else rect.merge(box)
		first = false
	return rect

static func _degrees_box(degrees: Array) -> Rect2:
	var top_left := project(float(degrees[0]), float(degrees[3]))
	var bottom_right := project(float(degrees[2]), float(degrees[1]))
	return Rect2(top_left, bottom_right - top_left)

## Whether a point in degrees is inside one of a region's authored boxes, edges included.
static func region_has(raw: Dictionary, lon: float, lat: float) -> bool:
	for box in region_boxes(raw):
		if lon >= float(box[0]) and lon <= float(box[2]) and lat >= float(box[1]) and lat <= float(box[3]):
			return true
	return false

static func region(region_id: String) -> Dictionary:
	for candidate in regions():
		if candidate["id"] == region_id:
			return candidate
	return {}

## The region a city is in, or "".
static func region_of(city_id: String) -> String:
	for raw in REGIONS:
		if city_id in raw["cities"]:
			return String(raw["id"])
	return ""

## The box the map closes in on when a city opens.
static func city_box(point: Vector2) -> Rect2:
	return Rect2(point - Vector2.ONE * CITY_ZOOM_UNITS * 0.5, Vector2.ONE * CITY_ZOOM_UNITS)

static func distance_to_polygon(point: Vector2, polygon: PackedVector2Array) -> float:
	var best := INF
	for index in polygon.size():
		var a := polygon[index]
		var b := polygon[(index + 1) % polygon.size()]
		# https://docs.godotengine.org/en/stable/classes/class_geometry2d.html#class-geometry2d-method-get-closest-point-to-segment
		best = minf(best, point.distance_to(Geometry2D.get_closest_point_to_segment(point, a, b)))
	return best

## The state a point on the map is in, and its distance to the nearest front, as the player's
## war has left the fronts.
static func state_at(point: Vector2, settings: Object = null) -> Dictionary:
	return state_in(point, zone_polygons(settings))

## The same, against the given fronts (zone_polygons).
static func state_in(point: Vector2, polygons: Dictionary) -> Dictionary:
	var distance := INF
	for key in polygons:
		var polygon: PackedVector2Array = polygons[key]
		if Geometry2D.is_point_in_polygon(point, polygon):
			return {"state": STATE_CONSUMED, "distance": 0.0}
		distance = minf(distance, distance_to_polygon(point, polygon))
	var state := STATE_SAFE
	if distance <= OVERRUN_UNITS:
		state = STATE_OVERRUN
	elif distance <= DANGER_UNITS:
		state = STATE_DANGER
	elif distance <= THREATENED_UNITS:
		state = STATE_THREATENED
	return {"state": state, "distance": distance}

## Roughly how far a projected distance is in kilometers, for the city card.
static func kilometers(distance: float) -> int:
	return roundi(distance / (WorldCoastline.WIDTH / 360.0) * 111.0 / 100.0) * 100

# --- States and tiers -----------------------------------------------------------------------

static func state_label(state: String) -> String:
	match state:
		STATE_CONSUMED: return "CONSUMED"
		STATE_OVERRUN: return "OVERRUN"
		STATE_DANGER: return "IN DANGER"
		STATE_THREATENED: return "THREATENED"
		_: return "SAFE"

## The difficulty word the world map filters by: easy, medium, hard, or "" where there is nothing.
static func difficulty_of(state: String) -> String:
	match state:
		STATE_OVERRUN: return "hard"
		STATE_DANGER: return "medium"
		STATE_THREATENED: return "easy"
		_: return ""

static func difficulty_label(state: String) -> String:
	match state:
		STATE_OVERRUN: return "HARD"
		STATE_DANGER: return "MEDIUM"
		STATE_THREATENED: return "EASY"
		STATE_CONSUMED: return "OUT OF REACH"
		_: return "NO THREAT DETECTED"

## The DifficultyTier a city plays at. A threatened city plays Standard, or Assist when the
## session asks for it; nothing else has a choice. "" means no missions.
static func tier_for(state: String, assist: bool = false) -> String:
	match state:
		STATE_OVERRUN: return DifficultyTier.FULL_RESONANCE
		STATE_DANGER: return DifficultyTier.OPERATOR
		STATE_THREATENED: return DifficultyTier.ASSIST if assist else DifficultyTier.STANDARD
		_: return ""

static func has_missions(state: String) -> bool:
	return tier_for(state) != ""

static func asks(state: String) -> String:
	match state:
		STATE_CONSUMED: return "Behind the front, out of reach. Nothing can be done here until the front is pushed back to it. No city is ever permanently lost."
		STATE_OVERRUN: return "A phantom every second or two. Squats, jumps, side-steps, and push-ups. Clear room to jump."
		STATE_DANGER: return "Shorter tells, faster lunges. Hold the line while Chen's team seals from the pylons. Every hold here keeps the front off the next city."
		STATE_THREATENED: return "Hands, block, dodge. Seal rifts and keep the front far away. Easy on the body; Assist is a session toggle."
		_: return "No threat detected. There is nothing to fight here tonight; the front is far away."

# --- Cities ---------------------------------------------------------------------------------

## Every city with its projected point, state, distance, and difficulty, against the fronts as
## the player's war has left them. A tear's city is overrun, not consumed, once every other city
## of its front is liberated: the last fight of that front.
static func cities(settings: Object = null) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var pulled := recession(settings)
	var zones := _zones_for(pulled, settings)
	for raw in CITIES:
		var city: Dictionary = (raw as Dictionary).duplicate()
		var point := project(float(city["lon"]), float(city["lat"]))
		var where := state_in(point, zones)
		if raw.has("origin") and where["state"] == STATE_CONSUMED and float(pulled.get(raw["id"], 0.0)) >= 1.0:
			where = {"state": STATE_OVERRUN, "distance": 0.0}
		city["point"] = point
		city["state"] = where["state"]
		city["distance"] = where["distance"]
		city["difficulty"] = difficulty_of(String(where["state"]))
		city["state_label"] = state_label(String(where["state"]))
		city["difficulty_label"] = difficulty_label(String(where["state"]))
		city["playable"] = has_missions(String(where["state"]))
		out.append(city)
	return out

static func city(city_id: String, settings: Object = null) -> Dictionary:
	for candidate in cities(settings):
		if candidate.get("id", "") == city_id:
			return candidate
	return {}

static func home_city_id() -> String:
	for raw in CITIES:
		if raw.get("home", false):
			return String(raw["id"])
	return String(CITIES[0]["id"])

## Cities with the player's progress folded in: ops_done, liberation, section index, sealed nodes.
## A liberated city (every operation done) has no missions, whatever the front near it is doing.
static func city_entries(settings: Object) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in cities(settings):
		var progress := progress_for(settings, String(entry["id"]))
		var ops := int(entry.get("ops", 0))
		var liberated := ops > 0 and int(progress["ops_done"]) >= ops
		entry["ops_done"] = progress["ops_done"]
		entry["section"] = progress["section"]
		entry["sealed"] = progress["sealed"]
		entry["liberation"] = 100 if liberated else liberation(entry, int(progress["ops_done"]))
		entry["resistance"] = resistance_label(ops)
		entry["liberated"] = liberated
		if liberated:
			entry["playable"] = false
			entry["difficulty"] = ""
			entry["state_label"] = "LIBERATED"
			entry["difficulty_label"] = "LIBERATED"
		out.append(entry)
	return out

static func city_entry(settings: Object, city_id: String) -> Dictionary:
	for entry in city_entries(settings):
		if entry.get("id", "") == city_id:
			return entry
	return {}

static func liberation(city_data: Dictionary, ops_done: int) -> int:
	var state := String(city_data.get("state", STATE_SAFE))
	if state == STATE_SAFE:
		return 100
	if state == STATE_CONSUMED:
		return 0
	var ops := int(city_data.get("ops", 0))
	if ops <= 0:
		return 100
	return clampi(roundi(100.0 * ops_done / ops), 0, 100)

static func world_liberation(settings: Object) -> int:
	var entries := city_entries(settings)
	if entries.is_empty():
		return 0
	var total := 0
	for entry in entries:
		total += int(entry["liberation"])
	return roundi(float(total) / entries.size())

static func resistance_label(ops: int) -> String:
	if ops <= 0:
		return "NONE"
	if ops >= 20:
		return "HEAVY"
	if ops >= 10:
		return "MODERATE"
	return "LIGHT"

# --- Sections -------------------------------------------------------------------------------

## One section of a city: two columns of one to three districts and a third of one, the level's
## finale, every district linked to at least one in the next column. The layout comes from the city
## id and section index, so the same ground comes back until it is sealed. What each district asks
## comes from the level the city plays at (ROSTERS), seeded per level, so the same city in danger
## always shows the same missions and the finale is always last.
static func section(city_id: String, index: int, tier_id: String = DifficultyTier.STANDARD) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d" % [city_id, index])
	var names := DISTRICT_NAMES.duplicate()
	for i in range(names.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: String = names[i]
		names[i] = names[j]
		names[j] = swap
	var columns: Array = []
	var nodes: Array[Dictionary] = []
	var used := 0
	for column in 3:
		var count := rng.randi_range(1, 3)
		# The third column is the series finale: one district.
		if column == 2:
			count = 1
		var members: Array[Dictionary] = []
		for row in count:
			# The draw that picked a kind before kinds came from the level; kept so the layout's
			# remaining draws stay where they were.
			rng.randi_range(0, 3)
			var district: String = names[used % names.size()]
			used += 1
			members.append({
				"id": "s%dn%d" % [index, used],
				"column": column,
				"row": row,
				"name": district,
				"kind": "",
				"site": site_for(district),
				"point": Vector2(COLUMN_X[column], MAP_SIZE.y * 0.5 + (row - (count - 1) * 0.5) * ROW_STEP),
			})
		columns.append(members)
		nodes.append_array(members)
	var edges: Array = []
	for column in 2:
		var next: Array = columns[column + 1]
		for member in columns[column]:
			var linked := 0
			for target in next:
				if rng.randf() < 0.6:
					edges.append([member["id"], target["id"]])
					linked += 1
			if linked == 0:
				edges.append([member["id"], next[rng.randi_range(0, next.size() - 1)]["id"]])
		for target in next:
			var reached := false
			for edge in edges:
				if edge[1] == target["id"]:
					reached = true
			if not reached:
				var from: Dictionary = columns[column][rng.randi_range(0, columns[column].size() - 1)]
				edges.append([from["id"], target["id"]])
	var starts: Array[String] = []
	for member in columns[0]:
		starts.append(String(member["id"]))
	var level := _assign_kinds(nodes, city_id, index, tier_id)
	return {"city_id": city_id, "index": index, "level": level, "nodes": nodes, "edges": edges, "starts": starts}

## Gives each district its kind from the level's roster: the regular kinds dealt from a shuffled
## bag, so a section mixes them, and the finale in the last column. Close the Sector carries
## "boss" when this section's finale is the Maw's lighter form. Returns the level.
static func _assign_kinds(nodes: Array[Dictionary], city_id: String, index: int, tier_id: String) -> String:
	var level := level_for(tier_id)
	var roster: Dictionary = ROSTERS[level]
	var picker := RandomNumberGenerator.new()
	picker.seed = hash("%s:%d:%s" % [city_id, index, level])
	var sector_boss := picker.randf() < SECTOR_BOSS_ODDS
	var bag: Array = []
	for node in nodes:
		if int(node["column"]) == 2:
			node["kind"] = String(roster["finale"])
			if node["kind"] == KIND_CLOSE_SECTOR:
				node["boss"] = sector_boss
			continue
		if bag.is_empty():
			bag = (roster["regular"] as Array).duplicate()
			for i in range(bag.size() - 1, 0, -1):
				var j := picker.randi_range(0, i)
				var swap: Variant = bag[i]
				bag[i] = bag[j]
				bag[j] = swap
		node["kind"] = String(bag.pop_back())
	return level

static func node_in(section_data: Dictionary, node_id: String) -> Dictionary:
	for node in section_data.get("nodes", []):
		if node.get("id", "") == node_id:
			return node
	return {}

## Districts a Striker may deploy to now: the first column with nothing sealed, otherwise the
## districts linked from the last seal. Nothing once three are sealed.
static func available_nodes(section_data: Dictionary, sealed: Array) -> Array[String]:
	var out: Array[String] = []
	if sealed.size() >= 3:
		return out
	if sealed.is_empty():
		for start in section_data.get("starts", []):
			out.append(String(start))
		return out
	var last := String(sealed[sealed.size() - 1])
	for edge in section_data.get("edges", []):
		if edge[0] == last:
			out.append(String(edge[1]))
	return out

static func node_status(section_data: Dictionary, sealed: Array, node_id: String) -> String:
	if node_id in sealed:
		return "sealed"
	if node_id in available_nodes(section_data, sealed):
		return "open"
	return "locked"

## The breach-site id for a district name, passed straight to ArenaPresentation.apply_site.
static func site_for(district: String) -> String:
	return district.to_lower().replace(" ", "_")

## What the Striker does in a district, named like an operation. The kind ids stay in saved
## records (record_key); only these words change. What may come through a Maw stays a surprise.
static func kind_label(kind: String) -> String:
	match kind:
		KIND_SINGLE: return "CLEAN SEAL"
		KIND_HOLD: return "COVER THE TEAM"
		KIND_FIRST_CHARGE: return "FIRST CHARGE"
		KIND_FLURRY: return "FLURRY"
		KIND_DUAL: return "CROSSFIRE"
		KIND_LOW_CEILING: return "LOW CEILING"
		KIND_CLOSE_SECTOR: return "CLOSE THE SECTOR"
		KIND_STORM: return "STORM"
		KIND_UNDERTOW: return "UNDERTOW"
		KIND_LAST_STAND: return "LAST STAND"
		KIND_MAW: return "SHUT THE MAW"
		_: return kind.to_upper()

static func kind_summary(kind: String) -> String:
	match kind:
		KIND_SINGLE: return "Four rifts in turn, each a little faster. Punch everything that comes through and shut the door."
		KIND_HOLD: return "Chen's team seals from the pylons. Keep the phantoms off you until they finish."
		KIND_FIRST_CHARGE: return "Four rifts, and pinks join the fight. Punch the feed, step aside from the charges, and finish the series."
		KIND_FLURRY: return "A fast, steady stream of yellow and blue. Keep your hands moving and block or dodge the odd one."
		KIND_DUAL: return "Two pairs of rifts, out of step in one view, with pinks charging between them."
		KIND_LOW_CEILING: return "Rays glide in at head height between the phantoms. Punch, then get under them."
		KIND_CLOSE_SECTOR: return "The last district in this sector. It will not go quietly."
		KIND_STORM: return "Pinks charge from everywhere while rays sweep low and eels skim the floor. Keep moving."
		KIND_UNDERTOW: return "A hard, fast feed with rays to squat under and eels to jump. Punch between the moves."
		KIND_LAST_STAND: return "Three rifts open across your front while the team seals them. Hold every side."
		KIND_MAW: return "One vast rift, a heavy flood, and something holding it open. It takes a long chew to shut."
		_: return ""

## The level a tier's cards show: EASY for Assist and Standard, MEDIUM for Operator, HARD for Full Resonance.
static func level_for(tier_id: String) -> String:
	match DifficultyTier.resolve(tier_id):
		DifficultyTier.OPERATOR: return LEVEL_MEDIUM
		DifficultyTier.FULL_RESONANCE: return LEVEL_HARD
		_: return LEVEL_EASY

## Every kind a tier can offer, regular ones first and the finale last.
static func kinds_for(tier_id: String) -> Array[String]:
	var roster: Dictionary = ROSTERS[level_for(tier_id)]
	var out: Array[String] = []
	for kind in roster["regular"]:
		out.append(String(kind))
	out.append(String(roster["finale"]))
	return out

## The tier a level is built at, for the audit and medals: Standard, Operator, Full Resonance.
static func tier_of_level(level: String) -> String:
	match level:
		LEVEL_MEDIUM: return DifficultyTier.OPERATOR
		LEVEL_HARD: return DifficultyTier.FULL_RESONANCE
		_: return DifficultyTier.STANDARD

# --- Missions -------------------------------------------------------------------------------

## The mission id for a district, carrying everything results need to credit the seal.
static func mission_id(city_id: String, section_index: int, node_id: String) -> String:
	return "world:%s:%d:%s" % [city_id, section_index, node_id]

static func is_world_mission(mission_id_value: String) -> bool:
	return mission_id_value.begins_with("world:")

## {"city_id", "section", "node_id"} from a world mission id, or {} for anything else.
static func parse_mission_id(mission_id_value: String) -> Dictionary:
	var parts := mission_id_value.split(":")
	if parts.size() != 4 or parts[0] != "world":
		return {}
	return {"city_id": parts[1], "section": int(parts[2]), "node_id": parts[3]}

## Best scores and times are kept per city, district kind, and tier.
static func record_key(city_id: String, kind: String, tier_id: String) -> String:
	return DifficultyTier.record_key(record_id(city_id, kind), tier_id)

## The mission id GameSettings keeps a district's records under: one per city and kind.
static func record_id(city_id: String, kind: String) -> String:
	return "world:%s:%s" % [city_id, kind]

## The id a mission's records live under: a district's city and kind, or an operation's own id.
static func record_id_for(mission: Dictionary) -> String:
	var world: Dictionary = mission.get("world", {})
	if world.is_empty():
		return String(mission.get("id", ""))
	return record_id(String(world.get("city_id", "")), String(world.get("kind", KIND_SINGLE)))

## The estimate behind expected_minutes, made the way the catalog's were (see the note above
## MissionCatalog._first_light and Known_Issues.md): a kill takes about this much rift health at
## average punch power, one kill per spawn interval but never faster than a player's cadence, and
## every rift costs
## its opening. Rifts that open together feed the player at once, so a pair is capped by the
## cadence rather than summed; a hold rift's own drain adds to the player's.
const KILL_DAMAGE := 13.0
const KILL_CADENCE_SECONDS := 2.0
const RIFT_OPENING_SECONDS := 6.0
## Cover the Team: Chen's team seals the rift on its own over this long (RiftManager drains it);
## the player's kills shorten it.
const HOLD_SECONDS := 300.0
const HOLD_HEALTH := 2600
## The feed every mission draws from: yellow and blue always the most frequent, green always the
## least (David, 2026-11-08). Pinks, Rays, and Eels never come from the feed: they ride a wave's
## extras layer (RiftManager), so they arrive between the feed's phantoms instead of replacing them.
const POOL: Array = ["yellow", "yellow", "yellow", "yellow", "yellow", "blue", "blue", "blue", "blue", "blue", "green"]
## Flurry's feed: the punching workout, with a green only now and then.
const FLURRY_POOL: Array = ["yellow", "yellow", "yellow", "yellow", "yellow", "yellow", "blue", "blue", "blue", "blue", "blue", "blue", "green"]
## Rift damage an extra does when the Striker answers it (MissionMedals.VARIANTS has the scores).
const EXTRA_DAMAGE := {"pink": 18, "ray": 14, "eel": 14}
## Each level's pace: phantom speed and tell length on every wave of its missions.
const LEVEL_PACE := {
	LEVEL_EASY: {"speed": 0.92, "tell": 1.12},
	LEVEL_MEDIUM: {"speed": 1.1, "tell": 0.9},
	LEVEL_HARD: {"speed": 1.2, "tell": 0.85},
}

## A playable mission for a district at a tier, in MissionCatalog's vocabulary. Each kind is
## authored at its level's pace (development/Difficulty_Matrix.md); the round still passes it
## through DifficultyTier.apply_mission, which leaves Standard, Operator, and Full Resonance as
## authored apart from what they ask of the body, and eases Assist. Lengths rise with the level:
## Easy about three and a half minutes, Medium five to six, Hard six to seven.
static func build_mission(city_data: Dictionary, section_index: int, node: Dictionary, tier_id: String) -> Dictionary:
	var kind := String(node.get("kind", KIND_SINGLE))
	var level := level_for(tier_id)
	var district := String(node.get("name", "District"))
	var city_name := String(city_data.get("name", "the city"))
	var mission := {
		"id": mission_id(String(city_data.get("id", "")), section_index, String(node.get("id", ""))),
		"codename": "%s • %s" % [city_name.to_upper(), district.to_upper()],
		"title": kind_label(kind),
		"summary": kind_summary(kind),
		"objective": "SEAL FOUR RIFTS",
		"site": node.get("site", DEFAULT_SITE),
		"world": {"city_id": city_data.get("id", ""), "section": section_index, "node_id": node.get("id", ""), "kind": kind},
		"start_line": "CHEN: %s. PUSH THE LINE." % district.to_upper(),
		"pressure_labels": ["CONTACT", "ADAPTING", "SECOND PASS", "LAST DOOR"],
		"open_barks": ["", "THEY ADJUST — FASTER LUNGES", "TWO MORE. SAME DISTRICT.", "LAST ONE. SHUT THE DOOR."],
		"seal_lines": ["FIRST SEAL. THREE LEFT.", "HALF DONE. TWO MORE ARE OPENING.", "ONE LEFT. FINISH THE DISTRICT."],
		"victory_line": "Chen: %s is shut. Pick the next district when you are ready." % district,
		"defeat_line": "Chen: The failsafe fired. %s held. Rest, then go back in." % district,
	}
	var pace: Dictionary = LEVEL_PACE[level]
	var speed := float(pace["speed"])
	var tell := float(pace["tell"])
	match kind:
		KIND_HOLD:
			mission["objective"] = "COVER THE TEAM"
			mission["start_line"] = "CHEN: %s. MY TEAM IS ON THE SEAL. KEEP THEM OFF YOU." % district.to_upper()
			_one_rift_lines(mission, "TEAM ON THE SEAL")
			var hold := _wave(HOLD_HEALTH, 3.0, 3, speed, tell, POOL)
			hold["hold_seconds"] = HOLD_SECONDS
			mission["rifts"] = [hold]
		KIND_FIRST_CHARGE:
			mission["intro_event"] = "intro_pinks_join"
			mission["start_line"] = "CHEN: %s. PINKS ARE IN THIS ONE. STEP ASIDE AND KEEP PUNCHING." % district.to_upper()
			mission["rifts"] = [
				_with_extras(_wave(320, 3.0, 3, 0.96, 1.06, POOL), [_extra("pink", 9.0)]),
				_with_extras(_wave(330, 2.9, 3, 0.96, 1.06, POOL), [_extra("pink", 9.0)]),
				_with_extras(_wave(340, 2.8, 3, 0.98, 1.04, POOL), [_extra("pink", 9.0)]),
				_with_extras(_wave(350, 2.7, 3, 0.98, 1.04, POOL), [_extra("pink", 9.0)]),
			]
		KIND_FLURRY:
			mission["intro_event"] = "intro_barrage"
			mission["objective"] = "SEAL THREE RIFTS"
			mission["start_line"] = "CHEN: %s. THEY ARE POURING IN. KEEP YOUR HANDS MOVING." % district.to_upper()
			mission["pressure_labels"] = ["FLURRY", "FASTER", "LAST DOOR"]
			mission["open_barks"] = ["", "SECOND RIFT. FASTER.", "LAST ONE. EMPTY IT."]
			mission["seal_lines"] = ["FIRST SEAL. TWO LEFT.", "ONE LEFT. FINISH IT."]
			if level == LEVEL_HARD:
				var moves := [_extra("pink", 7.0, 2), _extra("ray", 20.0), _extra("eel", 24.0)]
				mission["rifts"] = [
					_moving(_wave(1250, 1.3, 6, speed, tell, FLURRY_POOL), moves),
					_moving(_wave(1280, 1.25, 6, speed, tell, FLURRY_POOL), moves),
					_moving(_wave(1310, 1.2, 6, speed, tell, FLURRY_POOL), moves),
				]
			else:
				mission["rifts"] = [
					_with_extras(_wave(800, 1.8, 4, speed, tell, FLURRY_POOL), [_extra("pink", 12.0)]),
					_with_extras(_wave(820, 1.7, 4, speed, tell, FLURRY_POOL), [_extra("pink", 12.0)]),
					_with_extras(_wave(840, 1.6, 5, speed, tell, FLURRY_POOL), [_extra("pink", 12.0)]),
				]
		KIND_DUAL:
			_pair_lines(mission, district, "TWO DOORS, SAME VIEW. THEY WILL NOT SYNC.")
			# Each rift of a pair carries half the pinks, so a pair sends one about every ten seconds.
			var pinks := [_extra("pink", 20.0)]
			mission["rifts"] = [
				_with_extras(_wave(600, 3.2, 3, speed, tell, POOL), pinks),
				_with_extras(_wave(600, 3.6, 3, speed, tell, POOL), pinks),
				_with_extras(_wave(640, 3.0, 3, speed * 1.04, tell * 0.96, POOL), pinks),
				_with_extras(_wave(640, 3.4, 3, speed * 1.04, tell * 0.96, POOL), pinks),
			]
		KIND_LOW_CEILING:
			mission["intro_event"] = "intro_rays"
			mission["start_line"] = "CHEN: %s. RAYS IN THE AIR. GET UNDER THEM." % district.to_upper()
			var rays := [_extra("ray", 11.0), _extra("pink", 16.0)]
			mission["rifts"] = [
				_moving(_wave(560, 2.4, 4, speed, tell, POOL), rays),
				_moving(_wave(580, 2.3, 4, speed, tell, POOL), rays),
				_moving(_wave(600, 2.2, 4, speed, tell, POOL), rays),
				_moving(_wave(620, 2.1, 4, speed, tell, POOL), rays),
			]
		KIND_CLOSE_SECTOR:
			var as_boss := _close_the_sector(mission.duplicate(true), district, true)
			var as_pairs := _close_the_sector(mission.duplicate(true), district, false)
			# One card for both forms, so it never says which this is.
			var boss_card := expected_minutes(_with_boss(as_boss))
			var pairs_card := expected_minutes(as_pairs)
			mission = as_boss if bool(node.get("boss", false)) else as_pairs
			mission["intro_event"] = "intro_finale"
			mission["expected_minutes"] = [mini(int(boss_card[0]), int(pairs_card[0])), maxi(int(boss_card[1]), int(pairs_card[1]))]
		KIND_STORM:
			mission["intro_event"] = "intro_storm"
			mission["objective"] = "SEAL THREE RIFTS"
			mission["start_line"] = "CHEN: %s. EVERYTHING IS MOVING. SO ARE YOU." % district.to_upper()
			mission["pressure_labels"] = ["STORM", "STRONGER", "LAST DOOR"]
			mission["open_barks"] = ["", "SECOND RIFT. STAY LIGHT.", "LAST ONE. KEEP MOVING."]
			mission["seal_lines"] = ["FIRST SEAL. TWO LEFT.", "ONE LEFT. FINISH IT."]
			var storm := [_extra("pink", 3.0, 3), _extra("ray", 10.0), _extra("eel", 12.0)]
			mission["rifts"] = [
				_moving(_wave(1600, 2.6, 4, speed, tell, POOL), storm),
				_moving(_wave(1650, 2.5, 4, speed, tell, POOL), storm),
				_moving(_wave(1700, 2.4, 4, speed, tell, POOL), storm),
			]
		KIND_UNDERTOW:
			mission["intro_event"] = "intro_movers"
			mission["start_line"] = "CHEN: %s. RAYS AND EELS. LOW, THEN HIGH." % district.to_upper()
			var under := [_extra("ray", 11.0), _extra("eel", 13.0), _extra("pink", 10.0)]
			mission["rifts"] = [
				_moving(_wave(900, 1.7, 5, speed, tell, POOL), under),
				_moving(_wave(930, 1.6, 5, speed, tell, POOL), under),
				_moving(_wave(960, 1.6, 5, speed, tell, POOL), under),
				_moving(_wave(990, 1.5, 5, speed, tell, POOL), under),
			]
		KIND_LAST_STAND:
			mission["intro_event"] = "intro_last_stand"
			mission["objective"] = "HOLD ALL THREE"
			mission["start_line"] = "CHEN: %s. THREE DOORS. MY TEAM TAKES THEM. YOU HOLD." % district.to_upper()
			mission["pressure_labels"] = ["THREE DOORS", "TWO DOORS", "LAST DOOR"]
			mission["open_barks"] = ["", "", ""]
			mission["seal_lines"] = ["ONE DOOR SHUT. TWO TO GO.", "LAST DOOR. HOLD IT."]
			mission["max_concurrent"] = 3
			# Across the front, not all the way round: a wide arc first (David, 2026-11-08).
			mission["spread_rifts"] = [-60.0, 0.0, 60.0]
			var stand := [_extra("pink", 15.0), _extra("ray", 36.0), _extra("eel", 42.0)]
			var doors: Array = []
			for i in 3:
				var door := _moving(_wave(3000, 2.6, 2, speed, tell, POOL), stand)
				door["hold_seconds"] = 660.0
				doors.append(door)
			mission["rifts"] = doors
		KIND_MAW:
			mission["objective"] = "SEAL THE MAW"
			mission["arc_rifts"] = true
			mission["start_line"] = "CHEN: A MAW IN %s. IT DOES NOT STOP FEEDING." % district.to_upper()
			_one_rift_lines(mission, "THE MAW")
			mission["glimpse"] = true
			var boss: Dictionary = MissionCatalog.get_mission("the_maw").get("tier_boss", {})
			if not boss.is_empty():
				boss = boss.duplicate(true)
				boss["anchor"] = 1100
				boss["anchor_seconds"] = 260.0
				boss.erase("expected_minutes")
				mission["tier_boss"] = boss
			mission["rifts"] = [_moving(_wave(2700, 0.65, 10, speed, tell, POOL, 2.0), [_extra("pink", 10.0, 2), _extra("ray", 18.0), _extra("eel", 22.0)])]
			# One card for a Maw that breaks and one that holds.
			var breaks_card := expected_minutes(_with_boss(mission))
			var holds_card := expected_minutes(mission)
			mission["expected_minutes"] = [mini(int(breaks_card[0]), int(holds_card[0])), maxi(int(breaks_card[1]), int(holds_card[1]))]
		_:
			# Clean Seal: four rifts in sequence, each a little faster.
			mission["rifts"] = [
				_wave(200, 3.2, 3, speed, tell, POOL),
				_wave(210, 3.0, 3, speed, tell, POOL),
				_wave(210, 3.0, 3, speed, tell, POOL),
				_wave(220, 2.8, 3, speed, tell, POOL),
			]
	if not mission.has("expected_minutes"):
		mission["expected_minutes"] = expected_minutes(mission)
	return mission

## Close the Sector, the Medium finale: the Maw's lighter form (boss) or a harder Crossfire.
static func _close_the_sector(mission: Dictionary, district: String, boss: bool) -> Dictionary:
	var pace: Dictionary = LEVEL_PACE[LEVEL_MEDIUM]
	var speed := float(pace["speed"])
	var tell := float(pace["tell"])
	if boss:
		mission["objective"] = "CLOSE THE SECTOR"
		mission["arc_rifts"] = true
		mission["start_line"] = "CHEN: %s. LAST DISTRICT IN THE SECTOR. SOMETHING IS HOLDING IT OPEN." % district.to_upper()
		_one_rift_lines(mission, "LAST DISTRICT")
		mission["glimpse"] = true
		mission["world"]["boss"] = true
		# The lighter form: duck-depth sweeps, a slam that pulls straight back, no jumps, no
		# push-ups (MawBoss, "light"). It always comes through when this form is dealt.
		mission["tier_boss"] = {
			"name": "THE MAW",
			"light": true,
			"phase_one_scale": 0.7,
			"anchor": 800,
			"anchor_seconds": 180.0,
			"squat_depth": DifficultyTier.DUCK_DEPTH,
		}
		mission["rifts"] = [_with_extras(_wave(1800, 1.1, 6, speed, tell, POOL, 2.0), [_extra("pink", 14.0)])]
		return mission
	_pair_lines(mission, district, "LAST DISTRICT IN THE SECTOR. TWO DOORS. FINISH IT.")
	mission["objective"] = "CLOSE THE SECTOR"
	var extras := [_extra("pink", 22.0), _extra("ray", 30.0)]
	mission["rifts"] = [
		_moving(_wave(770, 3.0, 3, speed * 1.05, tell * 0.95, POOL), extras),
		_moving(_wave(770, 3.3, 3, speed * 1.05, tell * 0.95, POOL), extras),
		_moving(_wave(810, 2.8, 3, speed * 1.08, tell * 0.92, POOL), extras),
		_moving(_wave(810, 3.1, 3, speed * 1.08, tell * 0.92, POOL), extras),
	]
	return mission

## The mission as its boss tier would play it, for estimating the card.
static func _with_boss(mission: Dictionary) -> Dictionary:
	var copy := mission.duplicate(true)
	if copy.has("tier_boss"):
		copy["boss"] = copy["tier_boss"]
	return copy

static func _pair_lines(mission: Dictionary, district: String, line: String) -> void:
	mission["objective"] = "SEAL TWO PAIRS"
	mission["max_concurrent"] = 2
	mission["cluster_rifts"] = true
	mission["start_line"] = "CHEN: %s. %s" % [district.to_upper(), line]
	mission["pressure_labels"] = ["PAIR LIVE", "PARTNER", "SECOND PAIR", "LAST DOOR"]
	mission["open_barks"] = ["", "THE OTHER ONE IS ALREADY OPEN.", "SECOND PAIR. KEEP THEM IN FRONT.", "BOTH DOORS LIVE. STAY IN FRONT."]
	mission["seal_lines"] = ["ONE DOWN. ITS PARTNER IS STILL FEEDING.", "PAIR SEALED. THE NEXT TWO ARE OPENING.", "THREE DOWN. ONE PARTNER LEFT."]

static func _one_rift_lines(mission: Dictionary, label: String) -> void:
	mission["pressure_labels"] = [label]
	mission["open_barks"] = [""]
	mission["seal_lines"] = []

static func _extra(id: String, every: float, most: int = 1) -> Dictionary:
	return {"id": id, "every": every, "max": most}

static func _with_extras(wave: Dictionary, extras: Array) -> Dictionary:
	wave["extras"] = extras.duplicate(true)
	return wave

## Extras that include a Ray: the wave says a duck, and Full Resonance deepens it to a squat.
static func _moving(wave: Dictionary, extras: Array) -> Dictionary:
	wave["squat_depth"] = DifficultyTier.DUCK_DEPTH
	return _with_extras(wave, extras)

## [low, high] minutes for a mission's card, from its waves as given (the tier already applied, or
## Standard): the low end is a clean run by a hard puncher (Phantom.POWER_MAX of KILL_DAMAGE per
## kill), the high end an average puncher's clean run with half again for misses and dodges,
## never past the time a hold ends on its own. An average clean run (run_seconds) sits between.
## The developer's 2026-10-24 runs finished under the old low ends, which were the average clean
## run; punch power (2026-10-13) is why. Timed runs replace this: development/Difficulty_Tuning.md.
static func expected_minutes(mission: Dictionary) -> Array:
	var low_seconds := run_seconds(mission, KILL_DAMAGE * HARD_POWER)
	var high_seconds := run_seconds(mission, KILL_DAMAGE, MISS_ALLOWANCE)
	if mission.has("boss"):
		# The card does not say whether the Maw will break, so it covers both.
		low_seconds = minf(low_seconds, run_seconds(mission, KILL_DAMAGE * HARD_POWER, 1.0, false))
		high_seconds = maxf(high_seconds, run_seconds(mission, KILL_DAMAGE, MISS_ALLOWANCE, false))
	var low := maxi(roundi(low_seconds / 60.0), 1)
	var high := roundi(high_seconds / 60.0)
	return [low, maxi(high, low + 1)]

## Rift damage a hard punch does against an average one (Phantom.POWER_MAX).
const HARD_POWER := 1.3
## Half again for misses, dodges, and possessions on the card's high end.
const MISS_ALLOWANCE := 1.5
## The Maw's boss fight (MawBoss): one resolve's worth of work on the anchor this often, on top of
## its own drain. The cycle of sweeps, slams, volleys, and push-ups leaves about this much room.
const BOSS_WORK_SECONDS := 4.0
const BOSS_RETREAT_SECONDS := 2.2

## Seconds a run of the mission takes at `kill_damage` rift damage per kill, with the fighting
## stretched by `slack` (1 for a clean run). Covers sequences, pairs (max_concurrent), holds that
## drain on their own, and a mission carrying The Maw's "boss" (Full Resonance), which runs as a
## Maw that breaks unless `boss_breaks` is false.
static func run_seconds(mission: Dictionary, kill_damage: float = KILL_DAMAGE, slack: float = 1.0, boss_breaks: bool = true) -> float:
	var rifts: Array = mission.get("rifts", [])
	var concurrent := int(mission.get("max_concurrent", 1))
	if mission.has("boss") and boss_breaks:
		return boss_seconds(mission, kill_damage, slack)
	return _capped(rifts, estimate_seconds(rifts, concurrent, kill_damage, slack))

## A Maw that breaks: phase one on its share of the rift's health, the turn, then the anchor,
## which drains on its own in anchor_seconds and faster with work, but never slower.
static func boss_seconds(mission: Dictionary, kill_damage: float = KILL_DAMAGE, slack: float = 1.0) -> float:
	var boss: Dictionary = mission.get("boss", {})
	var share := clampf(float(boss.get("phase_one_scale", 1.0)), 0.1, 1.0)
	var phase_one: Array = []
	for wave in mission.get("rifts", []):
		var copy: Dictionary = (wave as Dictionary).duplicate()
		copy["health"] = maxi(int(round(float(copy.get("health", 0)) * share)), 1)
		phase_one.append(copy)
	var anchor := float(boss.get("anchor", 840))
	var anchor_seconds := float(boss.get("anchor_seconds", 210.0))
	var fight := minf(anchor / (anchor / anchor_seconds + kill_damage / BOSS_WORK_SECONDS) * slack, anchor_seconds)
	return estimate_seconds(phase_one, int(mission.get("max_concurrent", 1)), kill_damage, slack) + MawBoss.TURN_SECONDS + fight + BOSS_RETREAT_SECONDS

## A mission whose every rift drains on its own never runs past the drain.
static func _capped(rifts: Array, seconds: float) -> float:
	var ceiling := 0.0
	for wave in rifts:
		if float(wave.get("hold_seconds", 0.0)) <= 0.0:
			return seconds
		ceiling += float(wave.get("hold_seconds", 0.0)) + RIFT_OPENING_SECONDS
	return minf(seconds, ceiling)

## Seconds a run of these waves takes, estimated as the catalog's times were (see KILL_DAMAGE),
## at `kill_damage` per kill, with the fighting stretched by `slack`. Rifts open max_concurrent at
## a time, in order. The director refills a pair's slot as each rift seals rather than waiting
## for both, but a pair's feed already outruns the kill cadence, so the two come out the same.
static func estimate_seconds(rifts: Array, max_concurrent: int = 1, kill_damage: float = KILL_DAMAGE, slack: float = 1.0) -> float:
	var seconds := 0.0
	var index := 0
	var group_size := maxi(max_concurrent, 1)
	while index < rifts.size():
		var group: Array = rifts.slice(index, index + group_size)
		var health := 0.0
		var spawn_rate := 0.0
		var team_rate := 0.0
		var extras_rate := 0.0
		for wave in group:
			var wave_health := float(wave.get("health", 0))
			health += wave_health
			spawn_rate += 1.0 / maxf(float(wave.get("interval", 3.0)), 0.1)
			var hold := float(wave.get("hold_seconds", 0.0))
			if hold > 0.0:
				team_rate += wave_health / hold
			extras_rate += extras_damage_rate(wave)
		var kill_interval := maxf(1.0 / spawn_rate, KILL_CADENCE_SECONDS) if spawn_rate > 0.0 else KILL_CADENCE_SECONDS
		# The extras (pinks, Rays, Eels) come on their own timers, on top of the feed's kills.
		var player_rate := (kill_damage / kill_interval + extras_rate) / maxf(slack, 1.0)
		seconds += health / (player_rate + team_rate) + RIFT_OPENING_SECONDS * group.size()
		index += group_size
	return seconds

## Rift damage a second the wave's extras do when every one is answered: each arrives about once
## in its "every". An Eel only where the tier left it in (DifficultyTier drops it without jumps).
static func extras_damage_rate(wave: Dictionary) -> float:
	var rate := 0.0
	for entry in wave.get("extras", []):
		var every := float(entry.get("every", 0.0))
		if every > 0.0:
			rate += float(EXTRA_DAMAGE.get(String(entry.get("id", "")), 0)) / every
	return rate

## Extras of one id a minute from a wave, or of every id when `id` is "".
static func extras_per_minute(wave: Dictionary, id: String = "") -> float:
	var count := 0.0
	for entry in wave.get("extras", []):
		var every := float(entry.get("every", 0.0))
		if every > 0.0 and (id == "" or String(entry.get("id", "")) == id):
			count += 60.0 / every
	return count

static func _wave(health: int, interval: float, max_live: int, speed_scale: float, telegraph_scale: float, pool: Array, scale: float = 1.0) -> Dictionary:
	return {"health": health, "interval": interval, "max_live": max_live, "speed_scale": speed_scale, "telegraph_scale": telegraph_scale, "pool": pool, "scale": scale}

## The waves in order, run `times` times over; each copy is its own dictionary.
static func _repeat(waves: Array, times: int) -> Array:
	var run: Array = []
	for _pass in times:
		for wave in waves:
			run.append((wave as Dictionary).duplicate(true))
	return run

# --- Progress -------------------------------------------------------------------------------

## {"ops_done", "section", "sealed"} for a city, from GameSettings.world_progress plus the seed.
static func progress_for(settings: Object, city_id: String) -> Dictionary:
	var seed_ops := 0
	for raw in CITIES:
		if raw.get("id", "") == city_id:
			seed_ops = int(raw.get("seed_ops", 0))
	var stored: Dictionary = {}
	if settings != null:
		var all: Variant = settings.get("world_progress")
		if all is Dictionary and (all as Dictionary).has(city_id):
			stored = (all as Dictionary)[city_id]
	return {
		"ops_done": seed_ops + int(stored.get("ops_done", 0)),
		"section": int(stored.get("section", 0)),
		"sealed": Array(stored.get("sealed", [])),
	}

## Credits a sealed district. Returns what happened: whether the operation completed and the
## city's new counts. Three seals finish the operation, advance the section, and clear the path.
static func seal_node(settings: Object, city_id: String, node_id: String) -> Dictionary:
	var progress := progress_for(settings, city_id)
	var sealed: Array = progress["sealed"]
	if node_id in sealed:
		return {"operation_complete": false, "ops_done": progress["ops_done"], "section": progress["section"], "sealed": sealed}
	sealed.append(node_id)
	var completed := sealed.size() >= 3
	var stored := {"ops_done": int(progress["ops_done"]) - _seed_ops(city_id), "section": int(progress["section"]), "sealed": sealed}
	if completed:
		stored["ops_done"] += 1
		stored["section"] += 1
		stored["sealed"] = []
	if settings != null and settings.has_method("store_world_progress"):
		settings.call("store_world_progress", city_id, stored)
	return {"operation_complete": completed, "ops_done": stored["ops_done"] + _seed_ops(city_id), "section": stored["section"], "sealed": stored["sealed"]}

static func _seed_ops(city_id: String) -> int:
	for raw in CITIES:
		if raw.get("id", "") == city_id:
			return int(raw.get("seed_ops", 0))
	return 0
