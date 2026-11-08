extends RefCounted
class_name DifficultyTier

## The four difficulties. On the world map a city's state picks one (WorldMap.tier_for): a threatened
## city plays Standard (EASY, or Assist when the session asks), a city in danger Operator (MEDIUM),
## an overrun city Full Resonance (HARD).
##
## Since the 2026-11-08 difficulty pass each level has its own missions, authored at that level's
## pace in WorldMap.build_mission (development/Difficulty_Matrix.md), so Standard, Operator, and Full
## Resonance no longer scale speed, tells, health, or the feed: a tier here sets what the level asks
## of the body (a duck at most below Full Resonance; squats and jumps at it), which phantoms may
## come (no Eel without jumps), which boss may come through (the full Maw at Full Resonance, its
## lighter form at Operator), and Chen's countdown line. Assist is the one scaling tier: the
## accessibility setting for threatened cities, slower and softer at about the same length.
## The six Breach Night operations are authored once at Standard and are debug-only.
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
		"blurb": "A steady feed of phantoms to punch.",
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
		"blurb": "Faster phantoms, pinks between punches, and rays to duck under.",
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
		# The Maw's lighter form may close a sector here: duck-depth sweeps, its jump pair, and the
		# volley; no slams (Hard's, always push-ups). David, 2026-11-08.
		"light_bosses": true,
		"deploy_event": "deploy_medium",
	},
	# The movement difficulty. Every mission at it asks for squats (Rays) and jumps (Eels); push-ups
	# stay with the Maw's tentacles (David, 2026-11-08: getting down for a quick push-up in VR is
	# awkward). Assumes the player can jump.
	FULL_RESONANCE: {
		"label": "FULL RESONANCE",
		"blurb": "The heaviest fights: rays to squat under, eels to jump, and push-ups on the Maw. Clear room to jump.",
		"speed": 1.0,
		"telegraph": 1.0,
		"health": 1.0,
		"interval": 1.0,
		"contact": 1.0,
		"duck_only": false,
		"squats": true,
		"jumps": true,
		"push_ups": true,
		"bosses": true,
		# Chen's line in the countdown.
		"deploy_event": "deploy_hard_moves",
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

## The Maw's lighter form (no slam, so no push-ups) may come through at this tier.
static func allows_light_bosses(tier_id: String) -> bool:
	return allows_bosses(tier_id) or bool(info(tier_id).get("light_bosses", false))

static func allows_jumps(tier_id: String) -> bool:
	return bool(info(tier_id).get("jumps", false))

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
## "tier_boss" block becomes its "boss" only where the tier allows it (a block marked "light" also
## at Operator), and then replaces the glimpse; anywhere else it is dropped and the mission ends as
## authored. The result carries "tier", and applying again returns it unchanged.
static func apply_mission(mission: Dictionary, tier_id: String) -> Dictionary:
	if mission.has("tier"):
		return mission
	var tier := resolve(tier_id)
	var tiered := mission.duplicate(true)
	tiered["tier"] = tier
	var waves: Array = []
	for wave in mission.get("rifts", []):
		waves.append(apply_wave(wave, tier))
	if mission.has("rifts"):
		tiered["rifts"] = waves
	var boss: Dictionary = tiered.get("tier_boss", {})
	tiered.erase("tier_boss")
	var allowed := allows_light_bosses(tier) if bool(boss.get("light", false)) else allows_bosses(tier)
	if not boss.is_empty() and allowed:
		tiered.erase("glimpse")
		tiered["boss"] = boss
		if boss.has("expected_minutes"):
			tiered["expected_minutes"] = boss["expected_minutes"]
	return tiered

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
	if wave.has("extras"):
		out["extras"] = _extras_at(wave["extras"], tier)
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

## A wave's extras layer at this tier: each timer scaled as the feed is, and an Eel dropped where the
## tier asks for no jumps, so no rift wave makes a player jump below Full Resonance (the lighter
## Maw's jump pair is the one exception, by David's choice on 2026-11-08).
static func _extras_at(extras: Array, tier: Dictionary) -> Array:
	var out: Array = []
	for entry in extras:
		if String(entry.get("id", "")) == "eel" and not bool(tier.get("jumps", false)):
			continue
		var copy: Dictionary = (entry as Dictionary).duplicate()
		copy["every"] = float(entry.get("every", 0.0)) * float(tier["interval"])
		out.append(copy)
	return out
