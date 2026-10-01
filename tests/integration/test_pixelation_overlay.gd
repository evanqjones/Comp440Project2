extends GutTest
## World-only pixelation experiment wiring for the main game.

const MAIN_SCENE: PackedScene = preload("res://systems/core/main.tscn")


func test_main_pixelates_world_before_drawn_ui_layers() -> void:
	var main := MAIN_SCENE.instantiate() as Node3D
	add_child_autofree(main)
	await wait_process_frames(1)

	var overlay := main.get_node_or_null("PixelationOverlay") as CanvasLayer
	assert_not_null(overlay, "main instances the final-frame pixelation overlay")
	if overlay == null:
		return
	var lowest_ui_layer: int = 100
	for node: Node in main.find_children("*", "CanvasLayer", true, false):
		var layer := node as CanvasLayer
		if layer != overlay:
			lowest_ui_layer = mini(lowest_ui_layer, layer.layer)
	assert_lt(overlay.layer, lowest_ui_layer, "world filter draws below crisp title and HUD layers")
	var rect := overlay.get_node_or_null("Effect") as ColorRect
	assert_not_null(rect, "the overlay has a full-screen ColorRect")
	if rect != null:
		assert_eq(rect.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the effect does not block input")
		assert_eq(rect.anchor_left, 0.0)
		assert_eq(rect.anchor_top, 0.0)
		assert_eq(rect.anchor_right, 1.0)
		assert_eq(rect.anchor_bottom, 1.0)


func test_pixel_block_default_and_unfiltered_baseline() -> void:
	var overlay_scene := load("res://systems/core/pixelation_overlay.tscn") as PackedScene
	assert_not_null(overlay_scene, "pixelation overlay scene exists")
	if overlay_scene == null:
		return
	var overlay := overlay_scene.instantiate() as CanvasLayer
	add_child_autofree(overlay)
	var rect := overlay.get_node_or_null("Effect") as ColorRect
	assert_not_null(rect)
	if rect == null:
		return
	var material := rect.material as ShaderMaterial
	assert_not_null(material, "the ColorRect uses the screen-sampling shader")
	if material == null:
		return
	assert_eq(material.get_shader_parameter("pixel_block_size"), 3.0, "default subtle block size is 3 output pixels")
	material.set_shader_parameter("pixel_block_size", 1.0)
	assert_eq(material.get_shader_parameter("pixel_block_size"), 1.0, "1-pixel blocks are the unfiltered comparison setting")
