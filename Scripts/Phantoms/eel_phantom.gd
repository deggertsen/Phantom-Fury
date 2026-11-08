extends SweepCreature
class_name EelPhantom

## The Eel: a long eel that drops out of its rift to the floor and sweeps broadside through the
## Striker's feet, like a skipping rope. Jump it. Full Resonance only, since it asks for a jump
## (DifficultyTier strips it from a wave at any tier without jumps). Approved by David on 2026-11-08.

func _ready() -> void:
	variant_id = &"eel"
	creature_color = Color(0.85, 0.92, 1.0, 0.9)
	creature_scale = 1.3
	low = true
	blade_speed = 7.0
	super()

func _creature_mesh() -> Mesh:
	return CreatureMesh.eel()

func _tune_body(material: ShaderMaterial) -> void:
	material.set_shader_parameter("sway_speed", 7.0)

## It slithers along the floor from the moment it leaves the rift's lower edge.
func _cruise_height() -> float:
	return _floor_height() + 0.12

func _run_height() -> float:
	return _floor_height() + 0.12

## Broadside: the body lies across its heading, so its ripple runs along the way it travels.
func _body_basis(direction: Vector3) -> Basis:
	var forward := Vector3(direction.x, 0.0, direction.z)
	if forward.length_squared() < 0.0001:
		forward = Vector3.BACK
	forward = forward.normalized()
	var across := Vector3.UP.cross(forward)
	return Basis(forward, Vector3.UP, forward.cross(Vector3.UP)) if across.length_squared() > 0.0001 else Basis.IDENTITY
