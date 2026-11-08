extends RefCounted

## The difficulty audit: comparable numbers for every world mission at the level it is played,
## read from the wave tables alone. The validation runner writes it to reports/difficulty_audit.md
## on every run and fails on the checks at the bottom. Nothing here is measured; timed runs from
## user://run_log.csv (RunLog) are what replace it. See development/Difficulty_Tuning.md and
## development/Difficulty_Matrix.md.
##
## Since the 2026-11-08 difficulty pass each level (EASY, MEDIUM, HARD) has its own missions, and
## the audit holds the design David set: intensity rises at every level whatever the mission, so
## every Medium mission is more pressure than every Easy one and every Hard one more than every
## Medium one; harder levels may run longer; yellow and blue are always the most frequent and green
## always the least; Eels (jumps) only at Hard; and every Hard mission asks for squats and jumps.
## The six Breach Night operations are debug-only and not audited.

## Each species' tell at telegraph_scale 1, in seconds, and the floor a scaled tell never goes
## under (Phantom.apply_pressure, PinkPhantom.apply_pressure). The runner checks these against
## the phantom scenes, so a retuned species shows up here.
const BASE_TELL := {"yellow": 0.85, "blue": 0.8, "green": 0.72, "pink": 1.15}
const TELL_FLOOR := {"yellow": 0.35, "blue": 0.35, "green": 0.35, "pink": 0.45}
## The feed's mean tell: a mission whose tells average this reads as 1.0 in pressure.
const REFERENCE_TELL := 0.88
## Assist runs within this share of Standard's time.
const ASSIST_BAND := 0.05
## Estimated minutes (an average puncher's clean run) each level's missions should sit in.
const LEVEL_MINUTES := {
	WorldMap.LEVEL_EASY: [3.0, 4.5],
	WorldMap.LEVEL_MEDIUM: [4.5, 6.5],
	WorldMap.LEVEL_HARD: [4.5, 7.5],
}
const LEVEL_ORDER: Array[String] = [WorldMap.LEVEL_EASY, WorldMap.LEVEL_MEDIUM, WorldMap.LEVEL_HARD]
## The species the feed may draw from. Pinks, Rays, and Eels come only from the extras layer.
const FEED_SPECIES: Array[String] = ["yellow", "blue", "green"]

## Every mission the audit reads: {key, label, kind, level, tier, mission}. Each level's roster at
## its tier, both forms of Close the Sector, and the Easy missions at Assist too.
static func entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var city := {"id": "audit", "name": "Audit"}
	for level in LEVEL_ORDER:
		var tier := WorldMap.tier_of_level(level)
		var tiers: Array[String] = [tier]
		if level == WorldMap.LEVEL_EASY:
			tiers = [DifficultyTier.ASSIST, tier]
		for kind in WorldMap.kinds_for(tier):
			var forms: Array = [{"suffix": "", "node": {"id": "s0n1", "name": "Harbor", "kind": kind, "site": "harbor"}}]
			if kind == WorldMap.KIND_CLOSE_SECTOR:
				forms = [
					{"suffix": " (pairs)", "node": {"id": "s0n1", "name": "Harbor", "kind": kind, "site": "harbor", "boss": false}},
					{"suffix": " (boss)", "node": {"id": "s0n1", "name": "Harbor", "kind": kind, "site": "harbor", "boss": true}},
				]
			for form in forms:
				for played in tiers:
					var mission := WorldMap.build_mission(city, 0, form["node"], played)
					out.append({
						"key": "%s:%s%s" % [level, kind, String(form["suffix"]).strip_edges()],
						"label": "%s%s" % [WorldMap.kind_label(kind), form["suffix"]],
						"kind": kind,
						"level": level,
						"tier": played,
						"mission": mission,
					})
	return out

## The rifts in the groups they open in: [{waves, seconds}]. On a boss row, phase one only, on its
## share of the rift's health.
static func _groups(mission: Dictionary) -> Array:
	var rifts: Array = mission.get("rifts", [])
	var concurrent := maxi(int(mission.get("max_concurrent", 1)), 1)
	var share := 1.0
	if mission.has("boss"):
		share = clampf(float((mission["boss"] as Dictionary).get("phase_one_scale", 1.0)), 0.1, 1.0)
	var out: Array = []
	var index := 0
	while index < rifts.size():
		var group: Array = []
		for wave in rifts.slice(index, index + concurrent):
			var copy: Dictionary = (wave as Dictionary).duplicate()
			copy["health"] = maxi(int(round(float(copy.get("health", 0)) * share)), 1)
			group.append(copy)
		out.append({"waves": group, "seconds": WorldMap.estimate_seconds(group, concurrent)})
		index += concurrent
	return out

## One mission at the tier it is played. A boss row is the boss arc, and "hold_minutes" a Maw
## that holds; its pressure is the feed's, before the boss.
static func row(entry: Dictionary) -> Dictionary:
	var tier := String(entry["tier"])
	var mission := DifficultyTier.apply_mission(entry["mission"], tier)
	var rifts: Array = mission.get("rifts", [])
	var has_boss := mission.has("boss")
	var seconds := WorldMap.run_seconds(mission)
	var health := 0
	var tell_sum := 0.0
	var speed_sum := 0.0
	for wave in rifts:
		health += int(wave.get("health", 0))
		tell_sum += effective_tell(wave)
		speed_sum += float(wave.get("speed_scale", 1.0))
	var peak := 0
	var feed_weighted := 0.0
	var feed_seconds := 0.0
	var extras := {"pink": 0.0, "ray": 0.0, "eel": 0.0}
	for group in _groups(mission):
		var live := 0
		var feed := 0.0
		for wave in group["waves"]:
			live += int(wave.get("max_live", 0))
			feed += 60.0 / maxf(float(wave.get("interval", 3.0)), 0.1)
			for id in extras:
				extras[id] += WorldMap.extras_per_minute(wave, id) * float(group["seconds"]) / 60.0
		peak = maxi(peak, live)
		feed_weighted += feed * float(group["seconds"])
		feed_seconds += float(group["seconds"])
	var feed_minutes := maxf(feed_seconds / 60.0, 0.01)
	var kills := _kills(mission, WorldMap.KILL_DAMAGE)
	var feed_kills := _feed_kills(mission, WorldMap.KILL_DAMAGE)
	var extras_total := float(extras["pink"]) + float(extras["ray"]) + float(extras["eel"])
	var tell := tell_sum / maxf(rifts.size(), 1)
	var speed := speed_sum / maxf(rifts.size(), 1)
	var answers := (feed_kills + extras_total) / feed_minutes
	var out := {
		"key": entry["key"],
		"label": entry["label"],
		"kind": entry["kind"],
		"level": entry["level"],
		"tier": tier,
		"rifts": rifts.size(),
		"health": health,
		"phantoms": kills,
		"peak_live": peak,
		"phantom_every": 60.0 / maxf(feed_weighted / maxf(feed_seconds, 0.01), 0.01),
		"pinks_per_minute": float(extras["pink"]) / feed_minutes,
		"rays_per_minute": float(extras["ray"]) / feed_minutes,
		"eels_per_minute": float(extras["eel"]) / feed_minutes,
		"tell": tell,
		"speed": speed,
		"minutes": seconds / 60.0,
		"hard_minutes": WorldMap.run_seconds(mission, WorldMap.KILL_DAMAGE * WorldMap.HARD_POWER) / 60.0,
		"card": mission.get("expected_minutes", []),
		"formula": WorldMap.expected_minutes(mission),
		# Phantoms and extras answered a minute while the feed runs, harder the faster they fly
		# and the shorter they tell.
		"pressure": answers * speed * REFERENCE_TELL / maxf(tell, 0.01),
		"boss": has_boss,
		"mission": mission,
	}
	# The lighter form always comes through when it is dealt, so only the full Maw can hold.
	if has_boss and not bool((mission["boss"] as Dictionary).get("light", false)):
		out["hold_minutes"] = WorldMap.run_seconds(mission, WorldMap.KILL_DAMAGE, 1.0, false) / 60.0
	return out

## Phantoms the player resolves in a clean run at `kill_damage` per kill: the rift health the
## player takes (a hold's team takes the rest, the extras some), and on a boss the anchor's work.
static func _kills(mission: Dictionary, kill_damage: float) -> float:
	var kills := _feed_kills(mission, kill_damage)
	if mission.has("boss"):
		var boss: Dictionary = mission["boss"]
		var anchor := float(boss.get("anchor", 840))
		var anchor_seconds := float(boss.get("anchor_seconds", 210.0))
		var fight := minf(anchor / (anchor / anchor_seconds + kill_damage / WorldMap.BOSS_WORK_SECONDS), anchor_seconds)
		kills += fight / WorldMap.BOSS_WORK_SECONDS
	return kills

## The feed's kills alone, before any boss: each group's health less what its team and extras take.
static func _feed_kills(mission: Dictionary, kill_damage: float) -> float:
	var kills := 0.0
	for group in _groups(mission):
		var health := 0.0
		var spawn_rate := 0.0
		var team_rate := 0.0
		var extras_rate := 0.0
		for wave in group["waves"]:
			health += float(wave.get("health", 0))
			spawn_rate += 1.0 / maxf(float(wave.get("interval", 3.0)), 0.1)
			var hold := float(wave.get("hold_seconds", 0.0))
			if hold > 0.0:
				team_rate += float(wave.get("health", 0)) / hold
			extras_rate += WorldMap.extras_damage_rate(wave)
		var player_rate := kill_damage / maxf(1.0 / maxf(spawn_rate, 0.001), WorldMap.KILL_CADENCE_SECONDS)
		kills += health * player_rate / (player_rate + team_rate + extras_rate) / kill_damage
	return kills

## The wave's mean tell over its pool, in seconds: each species' base tell times the wave's
## telegraph_scale, never under the species' floor.
static func effective_tell(wave: Dictionary) -> float:
	var total := 0.0
	var count := 0
	for variant in wave.get("pool", []):
		var id := String(variant)
		if not BASE_TELL.has(id):
			continue
		total += maxf(float(BASE_TELL[id]) * float(wave.get("telegraph_scale", 1.0)), float(TELL_FLOOR[id]))
		count += 1
	return total / count if count > 0 else REFERENCE_TELL

static func all_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for entry in entries():
		rows.append(row(entry))
	return rows

static func _find(rows: Array[Dictionary], key: String, tier: String) -> Dictionary:
	for candidate in rows:
		if candidate["key"] == key and candidate["tier"] == tier:
			return candidate
	return {}

static func on_card(r: Dictionary) -> bool:
	var card: Array = r["card"]
	if card.size() != 2:
		return false
	for minutes in [float(r["minutes"]), float(r.get("hold_minutes", r["minutes"]))]:
		var whole := roundi(minutes)
		if whole < int(card[0]) or whole > int(card[1]):
			return false
	return true

## The rows a level's bands are judged on: its own tier (Assist is the accessibility setting).
static func _level_rows(rows: Array[Dictionary], level: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in rows:
		if r["level"] == level and r["tier"] == WorldMap.tier_of_level(level):
			out.append(r)
	return out

## [least, most] pressure among a level's missions.
static func pressure_range(rows: Array[Dictionary], level: String) -> Array[float]:
	var least := INF
	var most := 0.0
	for r in _level_rows(rows, level):
		least = minf(least, float(r["pressure"]))
		most = maxf(most, float(r["pressure"]))
	return [least, most]

## What the audit finds wrong, as validation failures. Empty when the tables hold the design.
static func failures(rows: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for r in rows:
		var name := "%s at %s" % [r["label"], tier_short(r["tier"])]
		if not on_card(r):
			out.append("%s: the estimate (%.1f min%s) is not on its card %s" % [name, r["minutes"], ", %.1f if it holds" % r["hold_minutes"] if r.has("hold_minutes") else "", r["card"]])
		var band: Array = LEVEL_MINUTES[r["level"]]
		for minutes in [float(r["minutes"]), float(r.get("hold_minutes", r["minutes"]))]:
			if minutes < float(band[0]) or minutes > float(band[1]):
				out.append("%s runs %.1f min, outside %s's %.1f to %.1f" % [name, minutes, String(r["level"]).to_upper(), band[0], band[1]])
				break
		if r["tier"] == DifficultyTier.ASSIST:
			var standard := _find(rows, String(r["key"]), DifficultyTier.STANDARD)
			var drift := float(r["minutes"]) / maxf(float(standard["minutes"]), 0.01) - 1.0
			if absf(drift) > ASSIST_BAND:
				out.append("%s runs %+.0f%% against Standard, outside %.0f%%" % [name, drift * 100.0, ASSIST_BAND * 100.0])
			if float(r["pressure"]) >= float(standard["pressure"]):
				out.append("%s is no gentler than Standard" % name)
		out.append_array(_rule_failures(r, name))
	# Intensity rises at every level whatever the mission.
	for i in LEVEL_ORDER.size() - 1:
		var lower := pressure_range(rows, LEVEL_ORDER[i])
		var upper := pressure_range(rows, LEVEL_ORDER[i + 1])
		if lower[1] >= upper[0]:
			out.append("%s's most intense mission (%.1f) is not below %s's least (%.1f)" % [LEVEL_ORDER[i].to_upper(), lower[1], LEVEL_ORDER[i + 1].to_upper(), upper[0]])
	return out

## David's rules on what each wave of a mission may hold (2026-11-08).
static func _rule_failures(r: Dictionary, name: String) -> Array[String]:
	var out: Array[String] = []
	var hard: bool = r["level"] == WorldMap.LEVEL_HARD
	var rays := false
	var eels := false
	for wave in (r["mission"] as Dictionary).get("rifts", []):
		var counts := {}
		for variant in wave.get("pool", []):
			counts[String(variant)] = int(counts.get(String(variant), 0)) + 1
		for variant in counts:
			if not String(variant) in FEED_SPECIES:
				out.append("%s draws %s from its feed; only %s may come from the feed" % [name, variant, FEED_SPECIES])
		var yellow := int(counts.get("yellow", 0))
		var blue := int(counts.get("blue", 0))
		var green := int(counts.get("green", 0))
		if green >= yellow or green >= blue:
			out.append("%s has green as frequent as yellow or blue (%d, %d, %d)" % [name, yellow, blue, green])
		for entry in wave.get("extras", []):
			match String(entry.get("id", "")):
				"ray": rays = true
				"eel": eels = true
		var depth := float(wave.get("squat_depth", -1.0))
		if depth >= 0.0 and not is_equal_approx(depth, DifficultyTier.SQUAT_DEPTH if hard else DifficultyTier.DUCK_DEPTH):
			out.append("%s asks for a %.2f dip; %s asks for %s" % [name, depth, String(r["level"]).to_upper(), "a squat" if hard else "a duck at most"])
	if eels and not hard:
		out.append("%s sends Eels below HARD" % name)
	if (rays or eels) and r["level"] == WorldMap.LEVEL_EASY:
		out.append("%s sends Rays or Eels at EASY" % name)
	if hard and not r["boss"] and not (rays and eels):
		out.append("%s does not ask for both a squat (Rays) and a jump (Eels)" % name)
	return out

static func tier_short(tier: String) -> String:
	match tier:
		DifficultyTier.ASSIST: return "Assist"
		DifficultyTier.OPERATOR: return "Medium"
		DifficultyTier.FULL_RESONANCE: return "Hard"
		_: return "Easy"

static func _range(card: Array) -> String:
	return "%d–%d" % [int(card[0]), int(card[1])] if card.size() == 2 else "none"

## The mission table as Markdown.
static func mission_table(rows: Array[Dictionary]) -> String:
	var lines: PackedStringArray = [
		"| Mission | Played at | Rifts | Rift health | Phantoms | A phantom every | Most live | Pinks/min | Rays/min | Eels/min | Tell s | Speed | Est. min (hard) | Card | On card | Pressure/min |",
		"|---|---|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|---|---|---|---:|",
	]
	for r in rows:
		var minutes := "%.1f (%.1f)" % [r["minutes"], r["hard_minutes"]]
		if r.has("hold_minutes"):
			minutes += "; holds %.1f" % r["hold_minutes"]
		lines.append("| %s | %s | %d | %d | %.0f | %.1f s | %d | %.1f | %.1f | %.1f | %.2f | %.2f | %s | %s | %s | %.1f |" % [
			r["label"], tier_short(r["tier"]), r["rifts"], r["health"], r["phantoms"], r["phantom_every"], r["peak_live"],
			r["pinks_per_minute"], r["rays_per_minute"], r["eels_per_minute"], r["tell"], r["speed"], minutes,
			_range(r["card"]), "yes" if on_card(r) else "**NO**", r["pressure"],
		])
	return "\n".join(lines)

static func level_table(rows: Array[Dictionary]) -> String:
	var lines: PackedStringArray = [
		"| Level | Least pressure | Most pressure | Minutes |",
		"|---|---:|---:|---|",
	]
	for level in LEVEL_ORDER:
		var spread := pressure_range(rows, level)
		var band: Array = LEVEL_MINUTES[level]
		lines.append("| %s | %.1f | %.1f | %.1f to %.1f |" % [level.to_upper(), spread[0], spread[1], band[0], band[1]])
	return "\n".join(lines)

## The whole report.
static func markdown(rows: Array[Dictionary]) -> String:
	var found := failures(rows)
	var text := PackedStringArray([
		"# Difficulty audit",
		"",
		"Generated by `Tests/validation_runner.gd` from the wave tables (`Tests/difficulty_audit.gd`). Do not edit by hand; run validation to regenerate. Nothing here is a timed run: `user://run_log.csv` holds those (see `development/Difficulty_Tuning.md`). The design it holds is in `development/Difficulty_Matrix.md`.",
		"",
		"How to read it:",
		"",
		"- **Played at** is the level the mission is played at: Easy (a threatened city, or Assist when the session asks), Medium (a city in danger), Hard (an overrun city).",
		"- **Phantoms** are the feed's kills in a clean run at %d rift damage per kill (`WorldMap.KILL_DAMAGE`); a hold's team and the extras take the rest. A boss row adds the anchor's work." % int(WorldMap.KILL_DAMAGE),
		"- **A phantom every** is the feed's spawn interval across the open rifts. **Most live** is the feed's cap; the extras (pinks, Rays, Eels) come on top of it, on their own timers.",
		"- **Pinks, Rays, Eels a minute** are the extras layer while the feed runs: a pink is a side-step, a Ray a duck (a squat at Hard), an Eel a jump.",
		"- **Est. min** is `WorldMap.run_seconds`: one kill per spawn interval but no faster than one per %.0f s, plus what the extras and a hold's team take, %.0f s per rift opening. The bracket is a hard puncher (%.1fx). For a boss row it is the boss arc, and \"holds\" is a Maw that does not break." % [WorldMap.KILL_CADENCE_SECONDS, WorldMap.RIFT_OPENING_SECONDS, WorldMap.HARD_POWER],
		"- **Pressure/min** is phantoms and extras answered a minute while the feed runs, times speed, times %.2f s over the tell. A boss row's is its feed before the boss." % REFERENCE_TELL,
		"",
		"## Levels",
		"",
		"Every level's least intense mission must be more pressure than the level below's most intense, and every mission must run inside its level's minutes.",
		"",
		level_table(rows),
		"",
		"## Missions",
		"",
		mission_table(rows),
		"",
		"## Findings",
		"",
	])
	if found.is_empty():
		text.append("None. Every estimate is on its card, every level is more intense than the one below, every mission runs inside its level's minutes, and every wave keeps the species rules.")
	else:
		for line in found:
			text.append("- %s" % line)
	text.append("")
	return "\n".join(text)

## Writes the report and returns its failures.
static func write_report(path: String = "res://reports/difficulty_audit.md") -> Array[String]:
	var rows := all_rows()
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	if file:
		file.store_string(markdown(rows))
		file.close()
	print(level_table(rows))
	print(mission_table(rows))
	var found := failures(rows)
	for line in found:
		print("AUDIT: ", line)
	return found
