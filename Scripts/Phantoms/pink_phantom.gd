extends Phantom
class_name SpearfinPhantom

# No floor marking: the bill and the straightening aim are the tell. The chevron lane on the floor
# was removed on 2026-11-07 as too strong a tell for a phantom that was already easy to dodge.

@export var telegraph_seconds: float = 1.15
@export var charge_speed: float = 7.0
@export var dodge_radius: float = 0.65

var _telegraph_remaining: float
var _charging: bool = false
var _previous_target_distance: float = INF
var _pink_bow: float = 1.2
var _hold_on_lock: bool = false

## How far past its target the charge runs (training reads the charge path from charge_line).
const CHARGE_OVERRUN := 1.5

func _ready() -> void:
	uses_attack_pattern = false
	variant_id = &"pink"
	phantom_color = Color(1.0, 0.15, 0.65, 0.9)
	base_score = 200
	rift_damage = 18
	super()
	_telegraph_remaining = telegraph_seconds
	_pink_bow = randf_range(0.45, 2.6) * (-1.0 if randf() < 0.5 else 1.0)
	_lock_pink_target()

## The Spearfin: a needle-billed fish built to charge.
func _creature_mesh() -> Mesh:
	return CreatureMesh.spearfin(_form)

func _tune_creature_material(material: ShaderMaterial) -> void:
	material.set_shader_parameter("sway_speed", 5.0)
	material.set_shader_parameter("flap_speed", 6.0)

func apply_pressure(speed_scale: float, telegraph_scale: float) -> void:
	super.apply_pressure(speed_scale, telegraph_scale)
	charge_speed *= speed_scale
	telegraph_seconds = maxf(telegraph_seconds * telegraph_scale, 0.45)
	_telegraph_remaining *= telegraph_scale

## A released escort tells and charges again from wherever it left the ring.
func release_from_escort() -> void:
	if not is_escorting():
		return
	super.release_from_escort()
	_telegraph_remaining = telegraph_seconds
	_charging = false
	_lock_pink_target()

## Training: pause the hologram the moment its aim locks, before the charge.
func hold_at_lane_lock() -> void:
	_hold_on_lock = true

## The charge runs down the line it locked, at full speed from where it was paused.
func release_hold() -> void:
	if not _held or _terminal:
		return
	_held = false
	_hold_on_lock = false
	_show_hold(false)
	velocity = (_locked_target - global_position).normalized() * charge_speed
	_previous_target_distance = global_position.distance_to(_locked_target)

## Where the charge will go: from the fish, through its locked target, and on past it.
func charge_line() -> PackedVector3Array:
	var through := _locked_target - global_position
	var past := _locked_target + (through.normalized() * CHARGE_OVERRUN if through.length_squared() > 0.0001 else Vector3.ZERO)
	return PackedVector3Array([global_position, past])

func _physics_process(delta: float) -> void:
	if _terminal or _escorting:
		super(delta)
		return
	if _held:
		velocity = Vector3.ZERO
		return
	if _try_possess_between(global_position, global_position):
		return
	var told := 1.0
	if _telegraph_remaining > 0.0:
		_telegraph_remaining = maxf(_telegraph_remaining - delta, 0.0)
		told = 1.0 - clampf(_telegraph_remaining / maxf(telegraph_seconds, 0.01), 0.0, 1.0)
	elif _hold_on_lock:
		_hold_on_lock = false
		_enter_hold()
		return
	var blend := told * told
	var aim := _locked_target
	if _player_camera:
		aim += _flat_right() * _pink_bow * (1.0 - blend)
	var direction := aim - global_position
	if direction.length_squared() < 0.0001:
		direction = Vector3.FORWARD
	else:
		direction = direction.normalized()
	var speed := lerpf(1.7, charge_speed, blend)
	velocity = velocity.lerp(direction * speed, clampf(acceleration * delta, 0.0, 1.0))
	_face_direction(velocity)
	var origin := global_position
	move_and_slide()
	_set_alert(lerpf(0.35, 1.0, blend))
	_charging = blend > 0.8
	if _try_possess_between(origin, global_position):
		return
	if blend < 0.8:
		_previous_target_distance = global_position.distance_to(_locked_target)
		return
	var distance := global_position.distance_to(_locked_target)
	var passed_target := distance > _previous_target_distance and _previous_target_distance < dodge_radius * 1.8
	_previous_target_distance = distance
	if passed_target:
		var result := _make_result(true, false, &"dodge", base_score, rift_damage)
		result["on_beat"] = true
		resolve_without_strike(result)

func _evaluate_strike(strike: Dictionary) -> Dictionary:
	return _make_result(false, false, &"dodge_only", 0, 0, strike)

func _lock_pink_target() -> void:
	if _player_camera:
		_locked_target = _player_camera.global_position
	else:
		_locked_target = Vector3(0.0, 1.5, 0.0)
	_previous_target_distance = global_position.distance_to(_locked_target)
