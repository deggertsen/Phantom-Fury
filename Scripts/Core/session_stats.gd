extends RefCounted
class_name SessionStats

## What one round asked of the body, counted from what already flows through RoundController:
## every strike a glove delivers (CombatHandController reports it, landed or rejected), every
## resolve, every hit taken, the chain, the seals, and the live clock. Results show it; nothing
## persists. See development/Workout_Stats.md.

## The calorie estimate. Standing boxing-type exertion is about 6 to 8 METs (Compendium of
## Physical Activities: boxing, punching bag 5.5; sparring 7.8). With the common conversion
## kcal per minute = MET x 3.5 x body kg / 200 and an assumed 75 kg Striker:
##   MET_FLOOR 6.1 -> 8.0 kcal per active minute (a round with almost no punching)
##   MET_CEILING 7.6 -> 10.0 kcal per active minute (PUNCH_RATE_CEILING punches a minute or more)
## and the punch rate moves the MET in a straight line between them. Active minutes are the
## round's live clock: the countdown and pause never count. It is an estimate, and is labeled so.
const BODY_KG := 75.0
const MET_FLOOR := 6.1
const MET_CEILING := 7.6
const PUNCH_RATE_CEILING := 30.0

## Strikes a glove delivered to a phantom, landed or not, and the ones that did not resolve.
var punches: int = 0
var rejected: int = 0
var wrong_hand: int = 0
## Resolves, by the phantom's variant and by how it resolved.
var by_variant: Dictionary = {}
var by_kind: Dictionary = {}
## Lure crits: a gold or blue Angler struck on its lure.
var crits: int = 0
## Phantoms and hazards that reached the Striker.
var misses: int = 0
var longest_chain: int = 0
var rifts_sealed: int = 0
## Seconds of live round time.
var active_seconds: float = 0.0

func reset() -> void:
	punches = 0
	rejected = 0
	wrong_hand = 0
	by_variant = {}
	by_kind = {}
	crits = 0
	misses = 0
	longest_chain = 0
	rifts_sealed = 0
	active_seconds = 0.0

## A strike a glove delivered: Phantom.receive_strike's result.
func record_strike(result: Dictionary) -> void:
	punches += 1
	if result.get("valid", false):
		return
	rejected += 1
	if result.get("resolution_kind", &"") == &"wrong_hand":
		wrong_hand += 1

## A resolve, as RiftDirector.phantom_resolved carries it.
func record_resolve(result: Dictionary) -> void:
	var variant := String(result.get("variant_id", ""))
	var kind := String(result.get("resolution_kind", ""))
	if variant != "":
		by_variant[variant] = int(by_variant.get(variant, 0)) + 1
	if kind != "":
		by_kind[kind] = int(by_kind.get(kind, 0)) + 1
	if result.get("sweet_spot", false):
		crits += 1

func record_miss() -> void:
	misses += 1

func record_chain(streak: int) -> void:
	longest_chain = maxi(longest_chain, streak)

func record_seal() -> void:
	rifts_sealed += 1

## Gold and blue Anglers punched out, crit or not.
func gold_punched() -> int:
	return int(by_variant.get("yellow", 0))

func blue_punched() -> int:
	return int(by_variant.get("blue", 0))

## Green Carapaces stopped with both gloves.
func blocks() -> int:
	return int(by_kind.get("two_hand_block", 0))

## Pink charges and boss slams side-stepped.
func dodges() -> int:
	return int(by_kind.get("dodge", 0))

func active_minutes() -> float:
	return active_seconds / 60.0

## The calorie estimate in kcal; see MET_FLOOR.
func calories() -> float:
	return estimate_calories(active_seconds, punches)

static func estimate_calories(seconds: float, punch_count: int) -> float:
	var minutes := maxf(seconds, 0.0) / 60.0
	if minutes <= 0.0:
		return 0.0
	return minutes * kcal_per_minute(punch_count / minutes)

## kcal per active minute at this punch rate: 8.0 at rest, 10.0 at PUNCH_RATE_CEILING and up.
static func kcal_per_minute(punches_per_minute: float) -> float:
	var met := lerpf(MET_FLOOR, MET_CEILING, clampf(punches_per_minute / PUNCH_RATE_CEILING, 0.0, 1.0))
	return met * 3.5 * BODY_KG / 200.0

## The shape results read (report["stats"]).
func to_report() -> Dictionary:
	return {
		"punches": punches,
		"rejected": rejected,
		"wrong_hand": wrong_hand,
		"gold": gold_punched(),
		"blue": blue_punched(),
		"crits": crits,
		"blocks": blocks(),
		"dodges": dodges(),
		"misses": misses,
		"longest_chain": longest_chain,
		"rifts_sealed": rifts_sealed,
		"active_seconds": active_seconds,
		"calories": calories(),
	}
