extends Control
class_name MedalBadge

## A medal drawn, not textured: a ribbon's two tails over a disc in the medal's color with a dark
## ring inside, so it reads as a medal at panel distance on the Quest and the three metals differ
## in brightness as well as hue. Panels place it as a control; CityMap draws it with draw_medal.

const COLORS := {
	MissionMedals.GOLD: Color("ffd04a"),
	MissionMedals.SILVER: Color("d6e2f2"),
	MissionMedals.BRONZE: Color("d98a4f"),
}
const RIBBON := Color("4a63b8")

var medal: String = ""

static func color(medal_id: String) -> Color:
	return COLORS.get(medal_id, Color("8da4bd"))

## A badge `diameter` pixels across, for a medal from MissionMedals ("" draws nothing).
static func create(medal_id: String, diameter: float) -> MedalBadge:
	var badge := MedalBadge.new()
	badge.medal = medal_id
	badge.custom_minimum_size = Vector2(diameter, diameter * 1.25)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return badge

func _draw() -> void:
	var radius := minf(size.x, size.y / 1.25) * 0.5
	draw_medal(self, Vector2(size.x * 0.5, size.y - radius), radius, medal)

## The ribbon's tails rise above the disc to a little past its top, `radius` being the disc's.
static func draw_medal(canvas: CanvasItem, center: Vector2, radius: float, medal_id: String) -> void:
	if medal_id == "":
		return
	var fill := color(medal_id)
	var top := center.y - radius * 1.5
	for side: float in [-1.0, 1.0]:
		var x := center.x + side * radius * 0.35
		var inner := center.x + side * radius * 0.1
		var outer := center.x + side * radius * 0.6
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(x - radius * 0.32, top), Vector2(x + radius * 0.32, top),
			Vector2(maxf(inner, outer), center.y), Vector2(minf(inner, outer), center.y),
		]), RIBBON)
	canvas.draw_circle(center, radius, fill)
	canvas.draw_arc(center, radius * 0.66, 0.0, TAU, 32, fill.darkened(0.45), maxf(radius * 0.14, 1.5), true)
	canvas.draw_arc(center, radius, 0.0, TAU, 32, fill.darkened(0.6), maxf(radius * 0.08, 1.0), true)
