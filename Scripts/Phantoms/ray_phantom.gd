extends SweepCreature
class_name RayPhantom

## The Ray: a wide manta that glides in at head height, too wide to step around, so the Striker
## goes under it. Medium and Hard only. Below Full Resonance it flies at duck depth
## (DifficultyTier caps a wave's squat_depth); at Full Resonance it flies low enough for a squat.
## Approved by David on 2026-11-08.

func _ready() -> void:
	variant_id = &"ray"
	creature_color = Color(1.0, 0.45, 0.08, 0.9)
	creature_scale = 1.6
	low = false
	blade_speed = 6.0
	super()

func _creature_mesh() -> Mesh:
	return CreatureMesh.ray()

func _tune_body(material: ShaderMaterial) -> void:
	material.set_shader_parameter("flap_speed", 3.2)
	material.set_shader_parameter("sway_speed", 2.0)

## Its underside rides the line, so a head under the line passes under the body.
func _run_height() -> float:
	return sweep_height + 0.09

## Seen from the front at head height a manta is a thin line, so it lifts its nose and shows the
## Striker its belly: steepest while it lines up, flatter as it passes overhead.
func _tilt() -> float:
	if _approaching or _rest_remaining != 0.0 or _telegraph_remaining > 0.0:
		return 0.55
	return 0.3
