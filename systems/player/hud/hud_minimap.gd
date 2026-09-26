class_name HudMinimap
extends Control
## Top-down store map for the HUD's %Minimap slot (docs/features/player/07-minimap/FEATURE.md).
## Reads the level itself: standing static boxes on the world layer (walls, shelves) form the
## outline, so any store works without wiring. North-up: the store's back (-Z) is at the top.

const MARGIN := 3.0
const BACKGROUND := Color(0.0, 0.0, 0.0, 0.45)
const OBSTACLE := Color(0.86, 0.85, 0.8, 0.9)
const CHECKOUT := Color("#2E7D32")


## One cart's dot on the map.
class Marker:
	var position: Vector2
	var color: Color
	var is_player: bool
	## Map-space direction the cart faces.
	var facing: Vector2


## The human's cart (bigger dot with a facing tick).
var player: Cart

var _obstacles: Array[Rect2] = []
var _world := Rect2()
var _panel := StyleBoxFlat.new()


## A world point (x, z) on a map of `map_size`, fitting `world` with its aspect kept, centered.
static func world_to_map(point: Vector3, world: Rect2, map_size: Vector2) -> Vector2:
	var fit := minf(map_size.x / world.size.x, map_size.y / world.size.y)
	var offset := (map_size - world.size * fit) / 2.0
	return offset + (Vector2(point.x, point.z) - world.position) * fit


## Top-down rectangles (x, z) of every box-shaped static body on layer 1 that stands above the
## floor (crosses y = 0.5). The floor slab and non-box shapes are skipped.
static func scan_obstacles(root: Node) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for node: Node in root.find_children("*", "StaticBody3D", true, false):
		var body := node as StaticBody3D
		if not body.get_collision_layer_value(1):
			continue
		for child: Node in body.get_children():
			var shape := child as CollisionShape3D
			if shape == null or not shape.shape is BoxShape3D:
				continue
			var size := (shape.shape as BoxShape3D).size
			var box := shape.global_transform * AABB(-size / 2.0, size)
			if box.position.y < 0.5 and box.end.y > 0.5:
				rects.append(Rect2(box.position.x, box.position.z, box.size.x, box.size.z))
	return rects


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.bg_color = BACKGROUND
	_panel.set_corner_radius_all(8)


func _process(_delta: float) -> void:
	if not _world.has_area():
		_build_world()
	queue_redraw()


## Dots for `carts`, in map space.
func markers(carts: Array[Cart]) -> Array[Marker]:
	if not _world.has_area():
		_build_world()
	var result: Array[Marker] = []
	for cart: Cart in carts:
		var marker := Marker.new()
		marker.position = world_to_map(cart.global_position, _world, size)
		marker.color = cart.profile.color if cart.profile != null else Color.WHITE
		marker.is_player = cart == player
		var forward := -cart.global_basis.z
		marker.facing = Vector2(forward.x, forward.z).normalized()
		result.append(marker)
	return result


func _build_world() -> void:
	_obstacles = scan_obstacles(get_tree().root)
	var points: Array[Vector3] = [RoundManager.get_checkout_position()]
	for cart: Cart in RoundManager.get_carts():
		points.append(cart.global_position)
	if player != null:
		points.append(player.global_position)
	var rect := Rect2(Vector2(points[0].x, points[0].z), Vector2.ZERO)
	for obstacle: Rect2 in _obstacles:
		rect = rect.merge(obstacle)
	for point: Vector3 in points:
		rect = rect.expand(Vector2(point.x, point.z))
	_world = rect.grow(MARGIN)


func _draw() -> void:
	draw_style_box(_panel, Rect2(Vector2.ZERO, size))
	if not _world.has_area():
		return
	for obstacle: Rect2 in _obstacles:
		var corner := world_to_map(Vector3(obstacle.position.x, 0.0, obstacle.position.y), _world, size)
		var far := world_to_map(Vector3(obstacle.end.x, 0.0, obstacle.end.y), _world, size)
		draw_rect(Rect2(corner, far - corner), OBSTACLE)
	var checkout := world_to_map(RoundManager.get_checkout_position(), _world, size)
	draw_rect(Rect2(checkout - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), CHECKOUT)
	var carts := RoundManager.get_carts()
	if player != null and not carts.has(player):
		carts.append(player)
	for marker: Marker in markers(carts):
		if marker.is_player:
			draw_circle(marker.position, 7.5, Color.WHITE)
			draw_circle(marker.position, 5.5, marker.color)
			draw_line(marker.position, marker.position + marker.facing * 12.0, Color.WHITE, 2.0)
		else:
			draw_circle(marker.position, 4.5, marker.color)
