extends ResonanceSweep
class_name SweepCreature

## A phantom that moves the Striker's body: it flies out of its rift, lines up on them, and passes
## straight through where they stand. The pass is judged exactly as ResonanceSweep judges its
## blade (a duck or squat under it, a jump over a low one), but nothing of the rift is drawn: no
## rails and no blade. The creature is the tell. David, 2026-11-07: the rift itself attacking felt
## wrong, so movement comes from phantoms (the Ray and the Eel) instead.
##
## It cannot be punched: it is answered with the body. It arrives through a rift's extras layer
## (RiftManager, "extras"), so it never takes one of the rift's phantom slots, and like every sweep
## it waits for any other sweep in flight before it starts its run.

const CREATURE_MATERIAL := preload("res://Resources/Materials/creature.tres")

## Speed out of the rift until it lines up, before any pressure scaling.
@export var approach_speed: float = 4.2
## How far out (flat distance to the head) it stops approaching and starts its run.
@export var line_up_distance: float = 7.5
@export var creature_color: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var creature_scale: float = 1.6

var _body: MeshInstance3D
var _body_material: ShaderMaterial
var _approaching: bool = true
var _body_position: Vector3
var _line_up_from: Vector3
var _heading: Vector3 = Vector3.BACK
var _bob_time: float = 0.0

func _ready() -> void:
	super()
	blade_visible = false
	rails_visible = false
	_body_position = _source
	_heading = (_head_position() - _source).normalized() if _head_position().distance_squared_to(_source) > 0.01 else Vector3.BACK
	_build_body()
	_place_body(0.0)

## The creature's mesh. Subclasses return their species.
func _creature_mesh() -> Mesh:
	return CreatureMesh.drifter()

## The height the body flies at while it approaches.
func _cruise_height() -> float:
	return sweep_height + 0.6

## The height of the body's middle during its run, so its underside (or top) sits on the line.
func _run_height() -> float:
	return sweep_height

## The body's orientation for a heading: +Z of the mesh along it, unless a species turns it.
func _body_basis(direction: Vector3) -> Basis:
	var forward := Vector3(direction.x, 0.0, direction.z)
	if forward.length_squared() < 0.0001:
		forward = Vector3.BACK
	forward = forward.normalized()
	return Basis(Vector3.UP.cross(forward), Vector3.UP, forward)

func _tune_body(_material: ShaderMaterial) -> void:
	pass

## How far the nose lifts, in radians, so a flat body is not seen edge-on. Visual only.
func _tilt() -> float:
	return 0.0

func apply_pressure(speed_scale: float, telegraph_scale: float) -> void:
	super.apply_pressure(speed_scale, telegraph_scale)
	approach_speed *= speed_scale

## True while it is still flying in from its rift, before its run starts.
func is_approaching() -> bool:
	return _approaching

## Where the body is now, in world space.
func body_position() -> Vector3:
	return _body.global_position if _body else _body_position

func advance(delta: float) -> void:
	if _finished or not _interactions_enabled or delta <= 0.0:
		return
	if _approaching:
		_alive_time += delta
		if _alive_time > 22.0:
			force_cleanup()
			return
		var head := _head_position()
		var flat := Vector3(head.x - _body_position.x, 0.0, head.z - _body_position.z)
		if flat.length() <= line_up_distance:
			# The run lines up from here: the base sweep aims from _source toward the head.
			_approaching = false
			_source = _body_position
			_line_up_from = _body_position
		else:
			_heading = flat.normalized()
			_body_position += _heading * approach_speed * delta
			_body_position.y = move_toward(_body_position.y, _cruise_height(), 2.5 * delta)
			return
	super.advance(delta)

func _process(delta: float) -> void:
	super(delta)
	_bob_time += delta
	_place_body(delta)

func _place_body(delta: float) -> void:
	if _body == null:
		return
	var at := _body_position
	var heading := _heading
	if not _approaching:
		var start := Vector3(_center.x, _run_height(), _center.z) - _direction * start_distance
		heading = _direction
		if _rest_remaining != 0.0:
			# Waiting for another sweep: it holds where it lined up, bobbing.
			at = _line_up_from + Vector3.UP * sin(_bob_time * 2.4) * 0.08
			heading = _head_position() - _line_up_from
		elif _telegraph_remaining > 0.0:
			at = _line_up_from.lerp(start, smoothstep(0.0, 1.0, telegraph_progress()))
		elif _finished and not _broken:
			# It runs on past the player while it fades.
			_body_position += _direction * blade_speed * delta
			at = _body_position
		else:
			at = blade_position()
			at.y = _run_height()
			_body_position = at
	var basis := _body_basis(heading)
	var tilt := _tilt()
	if not is_zero_approx(tilt):
		basis = Basis(basis.x.normalized(), -tilt) * basis
	_body.global_transform = Transform3D(basis.scaled(Vector3.ONE * creature_scale), at)
	_body_material.set_shader_parameter("dissolve_amount", 1.0 - _fade)
	_body_material.set_shader_parameter("alert", telegraph_progress() if not _approaching else 0.0)

func _build_body() -> void:
	_body = MeshInstance3D.new()
	_body.name = "Creature"
	_body.top_level = true
	_body.mesh = _creature_mesh()
	_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body_material = CREATURE_MATERIAL.duplicate() as ShaderMaterial
	_body_material.set_shader_parameter("dissolve_amount", 0.0)
	_body_material.set_shader_parameter("dissolve_direction", Vector3.UP)
	_body_material.set_shader_parameter("base_color", creature_color)
	_body_material.set_shader_parameter("edge_color", creature_color.lightened(0.35))
	_body_material.set_shader_parameter("alert", 0.0)
	_body_material.set_shader_parameter("phase_offset", randf() * 20.0)
	_tune_body(_body_material)
	_body.material_override = _body_material
	add_child(_body)
	var glow := GlowSprite.create(creature_color, 1.4, 0.35)
	glow.name = "CreatureGlow"
	_body.add_child(glow)
