extends RefCounted
class_name DifficultyTier

## The four difficulties. A mission is authored once, at Standard, in MissionCatalog; a tier is a
## transform applied to a copy of it when the round begins (RoundController.begin_round), so the
## catalog stays the only source of base numbers and Standard plays exactly as authored.
##
## Each tier multiplies the wave fields (speed_scale, telegraph_scale, health, interval) and sets
## contact_scale, which RiftManager applies to every phantom's and hazard's contact damage. Flags
## say what the tier asks of the body: sweeps at duck depth only, or squats, jumps, and push-ups,
## and whether a boss can come through. Only Full Resonance has bosses (decision 17), and at
## Full Resonance the boss carries the movements.
##
## A tier changes how hard a mission is, not how long: Assist and Operator run within a few
## percent of Standard's time and Full Resonance about a tenth longer. Where the player's own
## kill cadence sets the pace (pairs, The Maw) only health changes the length; where the feed
## does (one rift at a time) health times interval does. Both stay near 1 for Assist and
## Operator, so both kinds of mission hold their length. The 2026-11-01 audit found the first
## guesses (Assist 0.8 health and 1.15 interval, Operator 1.15 and 0.9) moved paired missions and
## The Maw by 12 to 20 percent. Tests/difficulty_audit.gd checks it on every validation run.
## The war map will take the choice over from the Operations screen; nothing here assumes a menu.
## See development/Exercise_Mechanics_Exploration.md, section 4.

const ASSIST := "assist"
const STANDARD := "standard"
const OPERATOR := "operator"
const FULL_RESONANCE := "full_resonance"
const ORDER: Array[String] = [ASSIST, STANDARD, OPERATOR, FULL_RESONANCE]
const DEFAULT := STANDARD
## A sweep's head drop as a share of standing height: a duck, which a bend also clears, or a squat.
const DUCK_DEPTH := 0.12
const SQUAT_DEPTH := 0.20

const TIERS := {
	ASSIST: {
		"label": "ASSIST",
		"blurb": "Slower phantoms, longer tells, softer hits.",
		"speed": 0.85,
		"telegraph": 1.25,
		"health": 0.96,
		"interval": 1.04,
		"contact": 0.6,
		"duck_only": true,
		"squats": false,
		"jumps": false,
		"push_ups": false,
		"bosses": false,
	},
	STANDARD: {
		"label": "STANDARD",
		"blurb": "The operations as Dr. Chen tuned them.",
		"speed": 1.0,
		"telegraph": 1.0,
		"health": 1.0,
		"interval": 1.0,
		"contact": 1.0,
		"duck_only": true,
		"squats": false,
		"jumps": false,
		"push_ups": false,
		"bosses": false,
	},
	OPERATOR: {
		"label": "OPERATOR",
		"blurb": "Faster lunges, shorter tells, harder hits.",
		"speed": 1.12,
		"telegraph": 0.85,
		"health": 1.04,
		"interval": 0.96,
		"contact": 1.25,
		"duck_only": true,
		"squats": false,
		"jumps": false,
		"push_ups": false,
		"bosses": false,
	},
	# The movement difficulty: an intensity, not a harder Operator. Speed and tells stay at
	# Standard so the extra work is the body, not reaction time. Assumes the player can jump.
	# The movements come from bosses ("bosses carry the movements"); ordinary rifts have no sweep,
	# because nothing in the fiction would be swinging it.
	FULL_RESONANCE: {
		"label": "FULL RESONANCE",
		"blurb": "The heaviest fights: a phantom every second or two, squats, jumps, and push-ups. Clear room to jump.",
		"speed": 1.0,
		"telegraph": 1.0,
		# The feed doubles and two more phantoms may be live at once (David, 2026-11-01: a phantom
		# reaching the player every one to two seconds). Health is 1.1x and then, per rift group,
		# as much more as the faster feed lets the player kill faster (pace_health; see
		# apply_mission), so a mission stays about a tenth longer than Standard: the extra work is
		# pace, not length. Where the player's own cadence already set the pace (pairs, The Maw)
		# the feed changes nothing and health stays at 1.1x.
		"health": 1.1,
		"interval": 0.5,
		"max_live_bonus": 2,
		"pace_health": true,
		"contact": 1.0,
		"duck_only": false,
		"squats": true,
		"jumps": true,
		"push_ups": true,
		"bosses": true,
		# Chen's line in the countdown.
		"deploy_event": "deploy_full_resonance",
	},
}

static func is_valid(tier_id: String) -> bool:
	return TIERS.has(tier_id)

## A known tier id, or Standard.
static func resolve(tier_id: String) -> String:
	return tier_id if is_valid(tier_id) else DEFAULT

static func info(tier_id: String) -> Dictionary:
	return TIERS[resolve(tier_id)]

static func label(tier_id: String) -> String:
	return String(info(tier_id).get("label", "STANDARD"))

static func blurb(tier_id: String) -> String:
	return String(info(tier_id).get("blurb", ""))

static func allows_bosses(tier_id: String) -> bool:
	return bool(info(tier_id).get("bosses", false))

static func asks_for_movement(tier_id: String) -> bool:
	var tier := info(tier_id)
	return bool(tier.get("squats", false)) or bool(tier.get("jumps", false)) or bool(tier.get("push_ups", false))

## The event Chen says in the countdown at this tier, or "" for none.
static func deploy_event(tier_id: String) -> String:
	return String(info(tier_id).get("deploy_event", ""))

## Where best scores and best times are kept. Standard keeps the bare mission id, so records
## saved before tiers existed (all at Standard) stay where they were.
static func record_key(mission_id: String, tier_id: String) -> String:
	var tier := resolve(tier_id)
	return mission_id if tier == STANDARD else "%s@%s" % [mission_id, tier]

## A copy of the mission at this tier. Every wave goes through apply_wave. A mission's
## "tier_boss" block becomes its "boss" only where the tier allows bosses, and then replaces the
## glimpse; anywhere else it is dropped and the mission ends as authored. The result carries
## "tier", and applying again returns it unchanged.
static func apply_mission(mission: Dictionary, tier_id: String) -> Dictionary:
	if mission.has("tier"):
		return mission
	var tier := resolve(tier_id)
	var tiered := mission.duplicate(true)
	tiered["tier"] = tier
	var waves: Array = []
	for wave in mission.get("rifts", []):
		waves.append(apply_wave(wave, tier))
	if bool(info(tier).get("pace_health", false)):
		_scale_health_with_pace(mission.get("rifts", []), waves, maxi(int(mission.get("max_concurrent", 1)), 1), tier)
	if mission.has("rifts"):
		tiered["rifts"] = waves
	var boss: Dictionary = tiered.get("tier_boss", {})
	tiered.erase("tier_boss")
	if not boss.is_empty() and allows_bosses(tier):
		tiered.erase("glimpse")
		tiered["boss"] = boss
		if boss.has("expected_minutes"):
			tiered["expected_minutes"] = boss["expected_minutes"]
	return tiered

## A pace tier: for each group of rifts open together, the kill rate the feed allows (the group's
## spawns a second, never above the player's cadence, WorldMap.KILL_CADENCE_SECONDS) at this
## tier over the same at Standard, and the group's health scaled by that. A hold's team time is
## left alone: the team seals as much faster as the player kills faster.
static func _scale_health_with_pace(standard_waves: Array, tiered_waves: Array, concurrent: int, tier_id: String) -> void:
	var cadence := 1.0 / WorldMap.KILL_CADENCE_SECONDS
	var index := 0
	while index < standard_waves.size():
		var feed_standard := 0.0
		var feed_tier := 0.0
		for offset in range(index, mini(index + concurrent, standard_waves.size())):
			var standard: Dictionary = standard_waves[offset]
			var tiered: Dictionary = tiered_waves[offset]
			feed_standard += 1.0 / maxf(float(standard.get("interval", 3.0)), 0.1)
			feed_tier += 1.0 / maxf(float(tiered.get("interval", 3.0)), 0.1)
		var ratio := minf(feed_tier, cadence) / maxf(minf(feed_standard, cadence), 0.001)
		for offset in range(index, mini(index + concurrent, standard_waves.size())):
			var tiered: Dictionary = tiered_waves[offset]
			if tiered.has("health"):
				tiered["health"] = maxi(int(round(float(tiered["health"]) * ratio)), 1)
		index += concurrent
	if tier_id == "":
		return

## One wave at this tier. Standard returns an identical copy. Fields a wave does not have stay
## absent unless the tier changes them, so a Standard wave compares equal to the catalog's.
static func apply_wave(wave: Dictionary, tier_id: String) -> Dictionary:
	var tier := info(tier_id)
	var out := wave.duplicate(true)
	out["speed_scale"] = float(wave.get("speed_scale", 1.0)) * float(tier["speed"])
	out["telegraph_scale"] = float(wave.get("telegraph_scale", 1.0)) * float(tier["telegraph"])
	if wave.has("health"):
		out["health"] = maxi(int(round(float(wave["health"]) * float(tier["health"]))), 1)
	if wave.has("interval"):
		out["interval"] = float(wave["interval"]) * float(tier["interval"])
	if wave.has("max_live"):
		out["max_live"] = int(wave["max_live"]) + int(tier.get("max_live_bonus", 0))
	# Cover the Team: the team's seal takes as much longer as the rift has more health, so the
	# hold drains at Standard's pace and the tier's length holds there too.
	if float(wave.get("hold_seconds", 0.0)) > 0.0:
		out["hold_seconds"] = float(wave["hold_seconds"]) * float(tier["health"])
	if not is_equal_approx(float(tier["contact"]), 1.0):
		out["contact_scale"] = float(wave.get("contact_scale", 1.0)) * float(tier["contact"])
	if bool(tier["duck_only"]):
		# Decision 2: below the movement difficulty, a sweep never asks for more than a duck.
		if wave.has("squat_depth"):
			out["squat_depth"] = minf(float(wave["squat_depth"]), DUCK_DEPTH)
	elif wave.has("squat_depth"):
		out["squat_depth"] = maxf(float(wave["squat_depth"]), SQUAT_DEPTH)
	return out
