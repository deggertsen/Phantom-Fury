extends Node
class_name RunLog

## One CSV line per finished round, so card times and tiers can be tuned from real runs instead
## of the wave tables (development/Difficulty_Tuning.md). RoundController owns one. On in every
## build. The file stays on the headset: no network, no account, no device identifier, only what
## the round itself knew (Privacy_Policy.md). An abandoned round (abort from pause) writes
## nothing, and neither does training.
##
## The file is user://run_log.csv, the app's private storage, which `adb shell run-as` reads on a
## debug build. Android also gets a copy in the app's external files directory,
## Android/data/<package>/files/run_log.csv, which `adb pull` reads on any build, release included.
## tools/pull_run_log.ps1 pulls either and prints actual against expected minutes.

const HEADER := "date,mission_id,kind,tier,outcome,elapsed_seconds,score,phantoms_resolved,misses,rejections,rifts_sealed,rifts_total,rift_health,expected_min,expected_max,boss,version_code"
const FILE_NAME := "run_log.csv"
const PACKAGE := "com.phantomfury.resonancerising"

## Where lines go. Validation points it somewhere else so its own rounds stay out of the real log.
static var log_path: String = "user://%s" % FILE_NAME
## Where the copy goes, or "" for none. Android only; resolved on first write.
static var copy_path: String = ""
static var _copy_resolved: bool = false

var _round: RoundController
var _director: RiftDirector
var _mission: Dictionary = {}
var _resolved: int = 0
var _misses: int = 0
var _rejections: int = 0
var _sealed: int = 0

## Listens to `round_controller` and its director for the rest of the session.
func attach(round_controller: RoundController, director: RiftDirector) -> void:
	_round = round_controller
	_director = director
	_round.countdown_started.connect(_on_countdown_started)
	_round.round_finished.connect(_on_round_finished)
	_director.phantom_resolved.connect(_on_phantom_resolved)
	_director.player_damaged.connect(_on_player_damaged)
	_director.strike_rejected.connect(_on_strike_rejected)
	_director.rift_closed.connect(_on_rift_closed)

func _on_countdown_started(mission: Dictionary) -> void:
	_mission = mission
	_resolved = 0
	_misses = 0
	_rejections = 0
	_sealed = 0

func _counting() -> bool:
	return _round != null and _round.is_round_active()

func _on_phantom_resolved(_result: Dictionary) -> void:
	if _counting():
		_resolved += 1

func _on_player_damaged(_amount: float) -> void:
	if _counting():
		_misses += 1

func _on_strike_rejected(_reason: StringName) -> void:
	if _counting():
		_rejections += 1

func _on_rift_closed(_rift_id: int, closed: int, _total: int) -> void:
	_sealed = maxi(_sealed, closed)

func _on_round_finished(outcome: StringName, score: int) -> void:
	if _mission.is_empty() or bool(_mission.get("tutorial", false)):
		return
	append(line_for(_mission, outcome, _round.elapsed_seconds, score, {
		"resolved": _resolved,
		"misses": _misses,
		"rejections": _rejections,
		"sealed": _sealed,
		"total": (_mission.get("rifts", []) as Array).size(),
		"boss": _boss_state(),
	}))

## "breaks" or "holds" for a mission with The Maw's boss, "" for anything else.
func _boss_state() -> String:
	if not _mission.has("boss"):
		return ""
	var boss := get_tree().get_first_node_in_group("MawBoss")
	if boss == null:
		return ""
	return "breaks" if bool(boss.get("breaks")) else "holds"

## One CSV line for a finished round. `stats` carries resolved, misses, rejections, sealed,
## total, and boss.
static func line_for(mission: Dictionary, outcome: StringName, elapsed: float, score: int, stats: Dictionary) -> String:
	var mission_id := String(mission.get("id", ""))
	var world: Dictionary = mission.get("world", {})
	var kind := String(world.get("kind", "operation")) if WorldMap.is_world_mission(mission_id) else "operation"
	var expected: Array = mission.get("expected_minutes", [])
	var fields := [
		Time.get_datetime_string_from_system(false, true),
		mission_id,
		kind,
		String(mission.get("tier", DifficultyTier.STANDARD)),
		String(outcome),
		"%.1f" % elapsed,
		str(score),
		str(int(stats.get("resolved", 0))),
		str(int(stats.get("misses", 0))),
		str(int(stats.get("rejections", 0))),
		str(int(stats.get("sealed", 0))),
		str(int(stats.get("total", 0))),
		str(rift_health(mission)),
		str(int(expected[0])) if expected.size() == 2 else "",
		str(int(expected[1])) if expected.size() == 2 else "",
		String(stats.get("boss", "")),
		str(version_code()),
	]
	var cells := PackedStringArray()
	for field in fields:
		cells.append(_cell(String(field)))
	return ",".join(cells)

## The rift health the mission's waves carry at its tier, for damage per kill (RunLog lines).
static func rift_health(mission: Dictionary) -> int:
	var total := 0
	for wave in mission.get("rifts", []):
		total += int(wave.get("health", 0))
	return total

## The Android version code, kept in project.godot beside export_presets.cfg by deploy_quest.ps1.
static func version_code() -> int:
	return int(ProjectSettings.get_setting("application/config/version_code", 0))

static func _cell(value: String) -> String:
	if value.contains(",") or value.contains("\"") or value.contains("\n"):
		return "\"%s\"" % value.replace("\"", "\"\"")
	return value

## Appends a line, writing the header first if the file is new, then refreshes the copy.
static func append(line: String) -> bool:
	var exists := FileAccess.file_exists(log_path)
	var file := FileAccess.open(log_path, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
	if file == null:
		push_warning("RunLog: cannot open %s (%s)" % [log_path, error_string(FileAccess.get_open_error())])
		return false
	if exists:
		file.seek_end()
	else:
		file.store_line(HEADER)
	file.store_line(line)
	file.close()
	_refresh_copy()
	return true

## The external copy's path on Android: the app's external files directory, beside the private
## one. Derived from the private path, so a renamed package follows.
static func external_copy_path() -> String:
	if OS.get_name() != "Android":
		return ""
	var package := PACKAGE
	var private_dir := OS.get_user_data_dir()
	var parts := private_dir.split("/", false)
	if parts.size() >= 2 and parts[parts.size() - 1] == "files":
		package = parts[parts.size() - 2]
	return "/storage/emulated/0/Android/data/%s/files/%s" % [package, FILE_NAME]

static func _refresh_copy() -> void:
	if not _copy_resolved:
		_copy_resolved = true
		if copy_path == "":
			copy_path = external_copy_path()
	if copy_path == "":
		return
	var source := FileAccess.get_file_as_string(log_path)
	DirAccess.make_dir_recursive_absolute(copy_path.get_base_dir())
	var copy := FileAccess.open(copy_path, FileAccess.WRITE)
	if copy == null:
		# Keep the private log; a debug build can still read it with run-as.
		push_warning("RunLog: no external copy at %s (%s)" % [copy_path, error_string(FileAccess.get_open_error())])
		return
	copy.store_string(source)
	copy.close()
