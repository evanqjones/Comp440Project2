extends GutTest
## HUD minimap (docs/features/player/07-minimap/FEATURE.md).

const CART_SCENE := "res://systems/cart/cart.tscn"


func _box(center: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = center
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)
	return body


func test_world_to_map_is_north_up_and_keeps_aspect() -> void:
	var world := Rect2(-10.0, -5.0, 20.0, 10.0) # x -10..10, z -5..5 (2:1)
	var size := Vector2(100.0, 100.0)
	var top_left := HudMinimap.world_to_map(Vector3(-10.0, 0.0, -5.0), world, size)
	var bottom_right := HudMinimap.world_to_map(Vector3(10.0, 0.0, 5.0), world, size)
	var center := HudMinimap.world_to_map(Vector3.ZERO, world, size)
	assert_almost_eq(center, Vector2(50.0, 50.0), Vector2(0.01, 0.01), "world center = map center")
	assert_almost_eq(top_left, Vector2(0.0, 25.0), Vector2(0.01, 0.01), "back-left corner (-Z) is up and left")
	assert_almost_eq(bottom_right, Vector2(100.0, 75.0), Vector2(0.01, 0.01), "2:1 world fits the width, centered vertically")


func test_scan_finds_standing_boxes_but_not_the_floor() -> void:
	_box(Vector3(0.0, -0.5, 0.0), Vector3(60.0, 1.0, 60.0))   # floor slab
	_box(Vector3(7.5, 1.0, -9.0), Vector3(1.0, 2.0, 14.0))    # a shelf
	var rects := HudMinimap.scan_obstacles(self)
	assert_has(rects, Rect2(7.0, -16.0, 1.0, 14.0), "the shelf, seen from above")
	for rect: Rect2 in rects:
		assert_lt(rect.size.x, 50.0, "the floor slab isn't an obstacle")


func test_hud_puts_a_minimap_in_its_slot() -> void:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	var hud := PlayerHud.new()
	hud.cart = cart
	add_child_autofree(hud)
	var slot := hud.layout.get_node("%Minimap") as Control
	var maps := slot.get_children().filter(func(n: Node) -> bool: return n is HudMinimap)
	assert_eq(maps.size(), 1, "one HudMinimap in %Minimap")


func test_one_marker_per_cart_with_the_player_highlighted() -> void:
	var player := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	player.cart_id = 0
	player.profile = load("res://systems/shared/profiles/player.tres")
	add_child_autofree(player)
	var carl := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	carl.cart_id = 1
	carl.profile = load("res://systems/shared/profiles/carl.tres")
	carl.position = Vector3(6.0, 0.0, 0.0)
	add_child_autofree(carl)
	var map := HudMinimap.new()
	map.player = player
	map.size = Vector2(180.0, 180.0)
	add_child_autofree(map)
	var markers := map.markers([player, carl])
	assert_eq(markers.size(), 2)
	assert_true(markers[0].is_player, "the player's marker is flagged")
	assert_false(markers[1].is_player)
	assert_eq(markers[1].color, carl.profile.color, "Carl's dot is teal")
