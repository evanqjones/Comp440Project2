class_name CardBackdrop
extends Control
## The store behind a paper card, blurred and dimmed like the artifact's screen overlay
## (docs/features/player/12-artifact-screens/FEATURE.md). One snapshot of the screen is halved a few
## times (each bilinear halving averages 2 x 2 pixels) and shown stretched, so it's a real blur that
## costs a few milliseconds once instead of a full-screen shader every frame. A per-frame blur
## shader ran the Compatibility renderer at about 7 fps, and a mipmapped one stopped it drawing.

## The snapshot is shrunk until it's at most this wide before it's stretched back up.
const BLUR_WIDTH := 144

var _blur: TextureRect
var _dim: ColorRect


func _init() -> void:
	name = "Backdrop"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blur = TextureRect.new()
	_blur.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blur.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_blur.stretch_mode = TextureRect.STRETCH_SCALE
	_blur.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_blur)
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = CardUi.SCREEN_DIM
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)


## Blur what the screen shows right now (call before this backdrop and its card become visible).
func capture() -> void:
	if DisplayServer.get_name() == "headless" or get_viewport() == null:
		_blur.texture = null # nothing is drawn headless (tests): the dim alone
		return
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_blur.texture = null # nothing drawn yet: the dim alone
		return
	image.convert(Image.FORMAT_RGBA8)
	while image.get_width() > BLUR_WIDTH:
		image.resize(maxi(1, image.get_width() / 2), maxi(1, image.get_height() / 2), Image.INTERPOLATE_BILINEAR)
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_BILINEAR) # smoother when stretched
	_blur.texture = ImageTexture.create_from_image(image)


## For a card that appears before anything is on screen (the title): hide, let one frame of the
## store draw, then blur it and show.
func capture_after_next_frame() -> void:
	if DisplayServer.get_name() == "headless":
		capture()
		return
	visible = false
	await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return
	capture()
	visible = true


func has_snapshot() -> bool:
	return _blur.texture != null
