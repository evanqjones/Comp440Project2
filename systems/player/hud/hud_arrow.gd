class_name HudArrow
extends Control
## The checkout arrow (player/10-hud-polish): a chunky yellow arrow drawn pointing up, turned by
## PlayerHud toward the checkout (0 = straight ahead, + = to the right), with a "CHECK OUT" tag.

const FILL := Color("#FFE135")
const EDGE := Color("#1B1B1B")
const SIZE := Vector2(72.0, 96.0)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = SIZE * 0.5


func _draw() -> void:
	var w := SIZE.x
	var h := SIZE.y
	var points := PackedVector2Array([
		Vector2(w * 0.5, 0.0), # tip
		Vector2(w, h * 0.45),
		Vector2(w * 0.68, h * 0.45),
		Vector2(w * 0.68, h * 0.78),
		Vector2(w * 0.32, h * 0.78),
		Vector2(w * 0.32, h * 0.45),
		Vector2(0.0, h * 0.45),
	])
	draw_colored_polygon(points, FILL)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, EDGE, 4.0, true)
