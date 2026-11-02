extends RefCounted

## The difficulty audit: comparable pressure numbers for every Breach Night operation and every
## world district kind at every tier, read from the wave tables alone. The validation runner
## writes it to reports/difficulty_audit.md on every run and fails on the checks at the bottom.
## Nothing here is measured; timed runs from user://run_log.csv (RunLog) are what replace it.
## See development/Difficulty_Tuning.md.

## Each species' tell at telegraph_scale 1, in seconds, and the floor a scaled tell never goes
## under (Phantom.apply_pressure, PinkPhantom.apply_pressure). The runner checks these against
## the phantom scenes, so a retuned species shows up here.
const BASE_TELL := {"yellow": 0.85, "blue": 0.8, "green": 0.72, "pink": 1.15}
const TELL_FLOOR := {"yellow": 0.35, "blue": 0.35, "green": 0.35, "pink": 0.45}
## The four species' mean tell: a mission whose tells average this reads as 1.0 in pressure.
const REFERENCE_TELL := 0.88

## Assist and Operator run within this share of Standard's time; Full Resonance runs longer by
## FULL_RESONANCE_LONGER, give or take TIER_BAND (Known_Issues.md, difficulty numbers).
const TIER_BAND := 0.05
const FULL_RESONANCE_LONGER := 0.10
## A district kind's pressure per minute stays within this share of its sibling operation's.
const SIBLING_BAND := 0.15

## Which operation each district kind is weighed against, and why.
const SIBLINGS := {
	WorldMap.KIND_SINGLE: ["widen_the_ring", "four species at a 3 to 4 s feed, one rift at a time"],
	WorldMap.KIND_DUAL: ["double_breach", "pairs of rifts in one view"],
	WorldMap.KIND_HOLD: ["widen_the_ring", "one rift of all four species at Standard speed and tells"],
	WorldMap.KIND_MAW: ["the_maw", "The Maw's own rift"],
}

## Every mission the audit reads, at Standard: {key, label, kind, mission}.
static func entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for mission in MissionCatalog.all_missions():
		out.append({"key": String(mission["id"]), "label": "%s %s" % [mission.get("codename", ""), mission.get("title", "")], "kind": "operation", "mission": mission})
	var city := {"id": "audit", "name": "Audit"}
	for kind in WorldMap.KINDS:
		var node := {"id": "s0n1", "name": "Harbor", "kind": kind, "site": "harbor"}
		var mission := WorldMap.build_mission(city, 0, node, DifficultyTier.STANDARD)
		out.append({"key": "world:%s" % kind, "label": "District: %s" % WorldMap.kind_label(kind), "kind": kind, "mission": mission})
	return out

## One mission at one tier. For a mission with The Maw's boss the row is a Maw that breaks, and
## "hold_minutes" is one that holds.
static func row(entry: Dictionary, tier: String) -> Dictionary:
	var mission := DifficultyTier.apply_mission(entry["mission"], tier)
	var rifts: Array = mission.get("rifts", [])
	var concurrent := maxi(int(mission.get("max_concurrent", 1)), 1)
	var has_boss := mission.has("boss")
	var seconds := WorldMap.run_seconds(mission)
	var health := 0
	var peak := 0
	var tell_sum := 0.0
	var speed_sum := 0.0
	for wave in rifts:
		health += int(wave.get("health", 0))
		tell_sum += effective_tell(wave)
		speed_sum += float(wave.get("speed_scale", 1.0))
	var feed_weighted := 0.0
	var feed_time := 0.0
	var index := 0
	while index < rifts.size():
		var group: Array = rifts.slice(index, index + concurrent)
		var live := 0
		var feed := 0.0
		for wave in group:
			live += int(wave.get("max_live", 0))
			feed += 60.0 / maxf(float(wave.get("interval", 3.0)), 0.1)
		peak = maxi(peak, live)
		var group_seconds := WorldMap.estimate_seconds(group, concurrent)
		feed_weighted += feed * group_seconds
		feed_time += group_seconds
		index += concurrent
	var kills := _kills(mission, WorldMap.KILL_DAMAGE)
	var tell := tell_sum / maxf(rifts.size(), 1)
	var speed := speed_sum / maxf(rifts.size(), 1)
	var answers := kills / maxf(seconds / 60.0, 0.01)
	var out := {
		"key": entry["key"],
		"label": entry["label"],
		"kind": entry["kind"],
		"tier": tier,
		"rifts": rifts.size(),
		"health": health,
		"phantoms": kills,
		"phantoms_hard": _kills(mission, WorldMap.KILL_DAMAGE * WorldMap.HARD_POWER),
		"phantoms_soft": _kills(mission, WorldMap.KILL_DAMAGE * 0.85),
		"peak_live": peak,
		"spawns_per_minute": feed_weighted / maxf(feed_time, 0.01),
		"tell": tell,
		"speed": speed,
		"minutes": seconds / 60.0,
		"hard_minutes": WorldMap.run_seconds(mission, WorldMap.KILL_DAMAGE * WorldMap.HARD_POWER) / 60.0,
		"soft_minutes": WorldMap.run_seconds(mission, WorldMap.KILL_DAMAGE * 0.85) / 60.0,
		"card": mission.get("expected_minutes", []),
		"formula": WorldMap.expected_minutes(mission),
		"answers_per_minute": answers,
		# Phantoms answered a minute, harder the faster they fly and the shorter they tell.
		"pressure": answers * speed * REFERENCE_TELL / maxf(tell, 0.01),
		"boss": has_boss,
	}
	if has_boss:
		out["hold_minutes"] = WorldMap.run_seconds(mission, WorldMap.KILL_DAMAGE, 1.0, false) / 60.0
	return out

## Phantoms the player resolves in a clean run at `kill_damage` per kill: the rift health the
## player takes (a hold's team takes the rest), and on a boss phase one plus the anchor's work.
static func _kills(mission: Dictionary, kill_damage: float) -> float:
	var rifts: Array = mission.get("rifts", [])
	if mission.has("boss"):
		var boss: Dictionary = mission["boss"]
		var share := clampf(float(boss.get("phase_one_scale", 1.0)), 0.1, 1.0)
		var phase_one := 0.0
		for wave in rifts:
			phase_one += float(wave.get("health", 0)) * share
		var anchor := float(boss.get("anchor", 840))
		var anchor_seconds := float(boss.get("anchor_seconds", 210.0))
		var fight := minf(anchor / (anchor / anchor_seconds + kill_damage / WorldMap.BOSS_WORK_SECONDS), anchor_seconds)
		return phase_one / kill_damage + fight / WorldMap.BOSS_WORK_SECONDS
	var kills := 0.0
	for wave in rifts:
		var health := float(wave.get("health", 0))
		var hold := float(wave.get("hold_seconds", 0.0))
		if hold <= 0.0:
			kills += health / kill_damage
			continue
		var player_rate := kill_damage / maxf(float(wave.get("interval", 3.0)), WorldMap.KILL_CADENCE_SECONDS)
		var team_rate := health / hold
		kills += health * player_rate / (player_rate + team_rate) / kill_damage
	return kills

## The wave's mean tell over its pool, in seconds: each species' base tell times the wave's
## telegraph_scale, never under the species' floor. Hazards (the sweep) are not counted.
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
		for tier in DifficultyTier.ORDER:
			rows.append(row(entry, tier))
	return rows

static func _find(rows: Array[Dictionary], key: String, tier: String) -> Dictionary:
	for candidate in rows:
		if candidate["key"] == key and candidate["tier"] == tier:
			return candidate
	return {}

## The length a row is compared across tiers by: a Maw that holds, for the boss row, because the
## boss arc is its own length and the card covers it separately.
static func _comparable_minutes(r: Dictionary) -> float:
	return float(r.get("hold_minutes", r["minutes"]))

static func on_card(r: Dictionary) -> bool:
	var card: Array = r["card"]
	if card.size() != 2:
		return false
	for minutes in [float(r["minutes"]), float(r.get("hold_minutes", r["minutes"]))]:
		var whole := roundi(minutes)
		if whole < int(card[0]) or whole > int(card[1]):
			return false
	return true

## Sibling comparisons: {kind, sibling, tier, district, operation, ratio, length_ratio, in_band}.
static func sibling_rows(rows: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for kind in WorldMap.KINDS:
		var sibling := String(SIBLINGS[kind][0])
		for tier in DifficultyTier.ORDER:
			var district := _find(rows, "world:%s" % kind, tier)
			var operation := _find(rows, sibling, tier)
			var ratio := float(district["pressure"]) / maxf(float(operation["pressure"]), 0.01)
			out.append({
				"kind": kind,
				"sibling": sibling,
				"tier": tier,
				"district": district["pressure"],
				"operation": operation["pressure"],
				"ratio": ratio,
				"length_ratio": _comparable_minutes(district) / maxf(_comparable_minutes(operation), 0.01),
				"in_band": absf(ratio - 1.0) <= SIBLING_BAND,
			})
	return out

## What the audit finds wrong, as validation failures. Empty when the tables are consistent.
static func failures(rows: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for r in rows:
		if not on_card(r):
			out.append("%s at %s: the estimate (%.1f min%s) is not on its card %s" % [r["label"], r["tier"], r["minutes"], ", %.1f if it holds" % r["hold_minutes"] if r.has("hold_minutes") else "", r["card"]])
		var standard := _find(rows, String(r["key"]), DifficultyTier.STANDARD)
		var drift := _comparable_minutes(r) / maxf(_comparable_minutes(standard), 0.01) - 1.0
		var target := FULL_RESONANCE_LONGER if r["tier"] == DifficultyTier.FULL_RESONANCE else 0.0
		if absf(drift - target) > TIER_BAND:
			out.append("%s at %s runs %+.0f%% against Standard, not %+.0f%% give or take %.0f%%" % [r["label"], r["tier"], drift * 100.0, target * 100.0, TIER_BAND * 100.0])
	for s in sibling_rows(rows):
		if not s["in_band"]:
			out.append("%s at %s carries %.0f%% of %s's pressure, outside %.0f%%" % [WorldMap.kind_label(s["kind"]), s["tier"], float(s["ratio"]) * 100.0, s["sibling"], SIBLING_BAND * 100.0])
	return out

static func tier_short(tier: String) -> String:
	match tier:
		DifficultyTier.ASSIST: return "Assist"
		DifficultyTier.OPERATOR: return "Operator"
		DifficultyTier.FULL_RESONANCE: return "Full Res"
		_: return "Standard"

static func _range(card: Array) -> String:
	return "%d–%d" % [int(card[0]), int(card[1])] if card.size() == 2 else "none"

## The mission table as Markdown.
static func mission_table(rows: Array[Dictionary]) -> String:
	var lines: PackedStringArray = [
		"| Mission | Tier | Rifts | Rift health | Phantoms (hard–soft) | Peak live | Spawns/min | Tell s | Speed | Est. min (hard–soft) | vs Std | Card | Formula | On card | Pressure/min |",
		"|---|---|---:|---:|---|---:|---:|---:|---:|---|---:|---|---|---|---:|",
	]
	for r in rows:
		var standard := _find(rows, String(r["key"]), DifficultyTier.STANDARD)
		var drift := _comparable_minutes(r) / maxf(_comparable_minutes(standard), 0.01) - 1.0
		var minutes := "%.1f (%.1f–%.1f)" % [r["minutes"], r["hard_minutes"], r["soft_minutes"]]
		if r.has("hold_minutes"):
			minutes += "; holds %.1f" % r["hold_minutes"]
		lines.append("| %s | %s | %d | %d | %.0f (%.0f–%.0f) | %d | %.1f | %.2f | %.2f | %s | %+.0f%% | %s | %s | %s | %.1f |" % [
			r["label"], tier_short(r["tier"]), r["rifts"], r["health"], r["phantoms"], r["phantoms_hard"], r["phantoms_soft"],
			r["peak_live"], r["spawns_per_minute"], r["tell"], r["speed"], minutes, drift * 100.0,
			_range(r["card"]), _range(r["formula"]), "yes" if on_card(r) else "**NO**", r["pressure"],
		])
	return "\n".join(lines)

static func sibling_table(rows: Array[Dictionary]) -> String:
	var lines: PackedStringArray = [
		"| District kind | Sibling operation | Tier | District pressure | Operation pressure | Ratio | Length ratio | In band |",
		"|---|---|---|---:|---:|---:|---:|---|",
	]
	for s in sibling_rows(rows):
		lines.append("| %s | %s | %s | %.1f | %.1f | %.2f | %.2f | %s |" % [
			WorldMap.kind_label(s["kind"]), s["sibling"], tier_short(s["tier"]), s["district"], s["operation"],
			s["ratio"], s["length_ratio"], "yes" if s["in_band"] else "**NO**",
		])
	return "\n".join(lines)

## The whole report.
static func markdown(rows: Array[Dictionary]) -> String:
	var found := failures(rows)
	var text := PackedStringArray([
		"# Difficulty audit",
		"",
		"Generated by `Tests/validation_runner.gd` from the wave tables (`Tests/difficulty_audit.gd`). Do not edit by hand; run validation to regenerate. Nothing here is a timed run: `user://run_log.csv` holds those (see `development/Difficulty_Tuning.md`).",
		"",
		"How to read it:",
		"",
		"- **Phantoms** are the kills a clean run takes at %d rift damage per kill (`WorldMap.KILL_DAMAGE`); the range is a hard puncher (%.2fx) to a soft one (0.85x). A hold's team takes the rest of its rift; a boss row adds the anchor's work." % [int(WorldMap.KILL_DAMAGE), WorldMap.HARD_POWER],
		"- **Peak live** is the most phantoms the open rifts may have out at once. **Spawns/min** is the open rifts' feed, weighted by how long each is open.",
		"- **Tell s** is the mean tell over each wave's pool (species base tell times `telegraph_scale`, never under its floor). **Speed** is the mean `speed_scale`.",
		"- **Est. min** is `WorldMap.run_seconds`: one kill per spawn interval but no faster than one per %.0f s, %.0f s per rift opening, pairs capped by the cadence, a hold's drain added. Hard and soft are the same run at 1.3x and 0.85x punch power. For The Maw at Full Resonance the row is a Maw that breaks, and \"holds\" is one that does not." % [WorldMap.KILL_CADENCE_SECONDS, WorldMap.RIFT_OPENING_SECONDS],
		"- **vs Std** is the length against the same mission at Standard (a Maw that holds, for the boss row). Assist and Operator should sit within %.0f%%, Full Resonance at +%.0f%% give or take %.0f%%." % [TIER_BAND * 100.0, FULL_RESONANCE_LONGER * 100.0, TIER_BAND * 100.0],
		"- **Card** is the range the card shows at that tier; **Formula** is `WorldMap.expected_minutes` (hard puncher's clean run to an average one with half again for misses). **On card** means the estimate, rounded to a whole minute, is inside the card.",
		"- **Pressure/min** is phantoms answered per minute times speed times %.2f s over the tell: more, faster, shorter-telling phantoms are more pressure. Contact damage is not in it." % REFERENCE_TELL,
		"",
		"## Missions",
		"",
		mission_table(rows),
		"",
		"## District kinds against their sibling operations",
		"",
		"A district kind's pressure per minute should sit within %.0f%% of its sibling's at the same tier. Districts are shorter than operations by design (four rifts, or one hold), so the length ratio is shown but not held to a band." % [SIBLING_BAND * 100.0],
		"",
		sibling_table(rows),
		"",
		"## Findings",
		"",
	])
	if found.is_empty():
		text.append("None. Every estimate is on its card, every tier runs its intended length, and every district kind is within its band.")
	else:
		for line in found:
			text.append("- %s" % line)
	text.append_array(PackedStringArray([
		"",
		"## Notes, not checks",
		"",
		"The roadmap asks for %d to %d minutes of play per mission from OP-02 on, with OP-01 short by design, and districts are meant to run about as long as an operation. On paper these fall short of %d minutes at Standard for an average puncher; timed runs decide whether to lengthen them:" % [TARGET_MINUTES[0], TARGET_MINUTES[1], TARGET_MINUTES[0]],
		"",
	]))
	var short := 0
	for r in rows:
		if r["tier"] != DifficultyTier.STANDARD or r["key"] == "first_light" or float(r["minutes"]) >= float(TARGET_MINUTES[0]):
			continue
		short += 1
		text.append("- %s: %.1f min (a hard puncher %.1f)." % [r["label"], r["minutes"], r["hard_minutes"]])
	if short == 0:
		text.append("- None.")
	text.append("")
	return "\n".join(text)

## Production_Roadmap.md, Phase 6: minutes of play per mission from OP-02 on.
const TARGET_MINUTES := [5, 10]

## Writes the report and returns its failures.
static func write_report(path: String = "res://reports/difficulty_audit.md") -> Array[String]:
	var rows := all_rows()
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	if file:
		file.store_string(markdown(rows))
		file.close()
	print(mission_table(rows))
	print(sibling_table(rows))
	var found := failures(rows)
	for line in found:
		print("AUDIT: ", line)
	return found
