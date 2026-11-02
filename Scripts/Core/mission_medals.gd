extends RefCounted
class_name MissionMedals

## Bronze, silver, and gold for a victory, from the score, measured against the mission's own
## par rather than one number for every mission. Par is what a reference round scores on the
## mission's waves at the tier played (DifficultyTier.apply_mission, so tiers have their own):
## every phantom resolved cleanly, every gold and blue Angler struck on its lure, and the chain
## held through each rift unless the rift feeds slower than the combo timeout. Kills come one per
## spawn interval but no faster than a player's cadence, at a firm punch (REFERENCE_POWER).
##   bronze: any victory (a best score exists only for a victory)
##   silver: SILVER_SHARE of par; a clean run without crits gets there, a broken chain does not
##   gold:   par; it takes lure crits and long chains
## The best medal is the medal of the best score, so it needs no storage of its own.
## See development/Workout_Stats.md.

const BRONZE := "bronze"
const SILVER := "silver"
const GOLD := "gold"
const ORDER: Array[String] = [BRONZE, SILVER, GOLD]
const SILVER_SHARE := 0.7
const GOLD_SHARE := 1.0
## The reference punch: Phantom.strike_power's damage factor for about 4.7 m/s. A harder punch
## takes a rift down in fewer phantoms, so it scores less; see Workout_Stats.md.
const REFERENCE_POWER := 1.15
## Each phantom's numbers as its script and scene set them (base score, rift damage, and the lure
## crit's); validation checks them against the instantiated phantoms. Pink carries on_beat.
const VARIANTS := {
	"yellow": {"base": 100, "damage": 10, "crit_base": 200, "crit_damage": 20},
	"blue": {"base": 100, "damage": 10, "crit_base": 220, "crit_damage": 20},
	"green": {"base": 180, "damage": 16},
	"pink": {"base": 200, "damage": 18, "on_beat": true},
	"sweep": {"base": 150, "damage": 14},
}
## A reference round never resolves more than this many phantoms in one wave.
const WAVE_LIMIT := 2000

## Par for a mission already at its tier: the reference round with crits and an unbroken chain.
static func par_score(mission: Dictionary) -> int:
	return reference_score(mission, true)

## The reference round's score. `crits` strikes every lure; `break_every` > 0 breaks the chain
## after that many resolves (a hit taken or a wrong hand), 0 never.
static func reference_score(mission: Dictionary, crits: bool, break_every: int = 0) -> int:
	var score := 0.0
	for wave in mission.get("rifts", []):
		var health := float(wave.get("health", 0))
		var cadence := maxf(float(wave.get("interval", 3.0)), WorldMap.KILL_CADENCE_SECONDS)
		var hold := float(wave.get("hold_seconds", 0.0))
		# Cover the Team: the team drains the rift alongside the Striker's kills.
		var team_drain := health / hold * cadence if hold > 0.0 else 0.0
		var pool: Array = wave.get("pool", WorldMap.POOL)
		var multiplier := 1.0
		var chain := 0
		var resolves := 0
		while health > 0.0 and resolves < WAVE_LIMIT:
			var numbers: Dictionary = VARIANTS.get(String(pool[resolves % pool.size()]), VARIANTS["yellow"])
			var crit := crits and numbers.has("crit_base")
			var gain := RoundController.CHAIN_GAIN
			if crit:
				gain += RoundController.CRIT_GAIN
			if numbers.get("on_beat", false):
				gain += RoundController.ON_BEAT_GAIN
			if cadence > RoundController.COMBO_TIMEOUT or (break_every > 0 and chain >= break_every):
				multiplier = 1.0
				chain = 0
			multiplier = minf(multiplier + gain, RoundController.MAXIMUM_MULTIPLIER)
			chain += 1
			score += roundi(float(numbers["crit_base" if crit else "base"]) * multiplier)
			health -= roundi(float(numbers["crit_damage" if crit else "damage"]) * REFERENCE_POWER) + team_drain
			resolves += 1
	return int(score)

## {"bronze", "silver", "gold"}: the least score that earns each, for a mission at its tier.
static func thresholds(mission: Dictionary) -> Dictionary:
	var par := par_score(mission)
	return {BRONZE: 1, SILVER: ceili(par * SILVER_SHARE), GOLD: ceili(par * GOLD_SHARE)}

## A Breach Night operation's thresholds at a tier, or {} for an unknown one.
static func operation_thresholds(mission_id: String, tier_id: String) -> Dictionary:
	var mission := MissionCatalog.get_mission(mission_id)
	if mission.is_empty():
		return {}
	return thresholds(DifficultyTier.apply_mission(mission, tier_id))

## A district kind's thresholds at a tier. Every city builds a kind on the same waves.
static func world_thresholds(kind: String, tier_id: String) -> Dictionary:
	var mission := WorldMap.build_mission({}, 0, {"kind": kind}, tier_id)
	return thresholds(DifficultyTier.apply_mission(mission, tier_id))

## The medal a victory with this score earns, or "" for none (no score, or no thresholds).
static func medal_for(score: int, medal_thresholds: Dictionary) -> String:
	if score <= 0 or medal_thresholds.is_empty():
		return ""
	var earned := ""
	for medal in ORDER:
		if score >= int(medal_thresholds.get(medal, 0)):
			earned = medal
	return earned

static func label(medal: String) -> String:
	return medal.to_upper()
