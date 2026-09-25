class_name CartShopperAnimator
extends Node
## Plays Evan's man-pushing-cart clips from the cart's motion, so bots animate as well as the
## player (docs/features/cart/05-evan-shopper/FEATURE.md). Adapted from Evan's
## assets/test/fbx_cart_preview.gd, which picks clips from keyboard input instead.
## Also tints the shirt and push handle with the driver's profile color, and keeps the item
## cubes in the animated basket (the turn clip swings the cart part sideways). Visual only.
## Place it as a child of the Cart.

const BLEND_SECONDS := 0.2
## Evan's pacing: every clip plays at twice its authored rate.
const SPEED_MULTIPLIER := 2.0
const HIT_SPEED := 3.0
const MOVING_SPEED := 0.2
const TURNING_YAW_RATE := 0.8
const LOOPING_CLIPS: Array[String] = ["idle", "walk", "turn", "backwards", "boost"]
const TINTED_MATERIALS: Array[String] = ["Petrol blue cotton", "Handle orange"]
const SQUASH_AMOUNT := 0.045
const BOUNCE_LIFT := 0.035
## The rig bone Evan's basket is skinned to.
const BASKET_BONE := "CART"

## Evan's model inside the cart's Visual.
@export var model_path: NodePath = NodePath("../Visual/ShopperModel")
## The cart's item cubes, which ride in the basket.
@export var stack_path: NodePath = NodePath("../ItemStackDisplay")

## Tinted copies of Evan's materials, keyed "material name|color", shared by all carts.
static var _tints: Dictionary = {}

var _cart: Cart
var _model: Node3D
var _player: AnimationPlayer
var _stack: Node3D
var _skeleton: Skeleton3D
var _basket_bone: int = -1
## The stack's transform relative to the basket bone, taken at ready.
var _stack_offset: Transform3D
## Clip name ("walk") → the full animation name in the FBX ("RIG • Man pushing cart|walk").
var _clips: Dictionary[String, StringName] = {}
var _current: String = ""
var _tinted_for: ShopperProfile
var _last_yaw: float = 0.0
var _base_position: Vector3
var _base_scale: Vector3
var _bounce_phase: float = 0.0
var _bounce_intensity: float = 0.0


## The clip for the cart's motion. yaw_rate is rad/s (negative = turning right).
## Priority (as in Evan's preview): stunned > backwards > boost > turn > walk > idle.
static func pick_clip(forward_speed: float, yaw_rate: float, stunned: bool, boosting: bool = false) -> String:
	if stunned:
		return "stunned"
	if forward_speed < -MOVING_SPEED:
		return "backwards"
	if boosting and forward_speed > MOVING_SPEED:
		return "boost"
	if absf(forward_speed) > MOVING_SPEED and absf(yaw_rate) > TURNING_YAW_RATE:
		return "turn"
	if absf(forward_speed) > MOVING_SPEED:
		return "walk"
	return "idle"


func _ready() -> void:
	_cart = get_parent() as Cart
	_model = get_node_or_null(model_path) as Node3D
	if _cart == null or _model == null:
		return
	_base_position = _model.position
	_base_scale = _model.scale
	_last_yaw = _cart.rotation.y
	var players := _model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_player = players[0] as AnimationPlayer
		for full_name: StringName in _player.get_animation_list():
			var clip := String(full_name).get_slice("|", 1).to_lower()
			_clips[clip] = full_name
			if clip in LOOPING_CLIPS:
				_player.get_animation(full_name).loop_mode = Animation.LOOP_LINEAR
	_stack = get_node_or_null(stack_path) as Node3D
	var skeletons := _model.find_children("*", "Skeleton3D", true, false)
	if _stack != null and not skeletons.is_empty():
		_skeleton = skeletons[0] as Skeleton3D
		_basket_bone = _skeleton.find_bone(BASKET_BONE)
		if _basket_bone >= 0:
			_stack_offset = _basket_pose().affine_inverse() * _stack.transform
	_apply_tint()


func _process(delta: float) -> void:
	if _cart == null or _model == null or delta <= 0.0:
		return
	if _cart.profile != _tinted_for:
		_apply_tint()
	var forward_speed := _cart.velocity.dot(-_cart.global_basis.z)
	var yaw_rate := wrapf(_cart.rotation.y - _last_yaw, -PI, PI) / delta
	_last_yaw = _cart.rotation.y
	var clip := pick_clip(forward_speed, yaw_rate, _cart.get_state().is_stunned, _cart.is_boosting())
	_play(clip, forward_speed)
	_bounce(delta, clip == "turn" and yaw_rate > 0.0)
	_follow_basket()


func _play(clip: String, forward_speed: float) -> void:
	if _player == null:
		return
	if clip != _current:
		if clip == "stunned" and _clips.has("hit"):
			_player.play(_clips["hit"], BLEND_SECONDS)
			if _clips.has("stunned"):
				_player.queue(_clips["stunned"])
		elif _clips.has(clip):
			_player.play(_clips[clip], BLEND_SECONDS)
		_current = clip
	if clip == "stunned":
		var in_hit := _clips.has("hit") and _player.current_animation == _clips["hit"]
		_player.speed_scale = HIT_SPEED if in_hit else SPEED_MULTIPLIER
	elif clip == "idle":
		_player.speed_scale = SPEED_MULTIPLIER
	else:
		_player.speed_scale = clampf(absf(forward_speed) / 3.0, 0.55, 1.5) * SPEED_MULTIPLIER


## Evan's speed-scaled squash and bob; a left turn mirrors the (right) turn clip.
func _bounce(delta: float, mirror: bool) -> void:
	var speed := Vector2(_cart.velocity.x, _cart.velocity.z).length()
	var target := clampf(speed / 4.0, 0.0, 1.0)
	_bounce_intensity = move_toward(_bounce_intensity, target, delta * 3.0)
	_bounce_phase = fmod(_bounce_phase + delta * TAU * lerpf(1.5, 3.0, target), TAU * 2.0)
	var pulse := sin(_bounce_phase) * SQUASH_AMOUNT * _bounce_intensity
	var side := 1.0 - pulse * 0.5
	_model.scale = Vector3(absf(_base_scale.x) * side * (-1.0 if mirror else 1.0), _base_scale.y * (1.0 + pulse), _base_scale.z * side)
	_model.position = _base_position + Vector3.UP * sin(_bounce_phase * 0.5) * BOUNCE_LIFT * _bounce_intensity


## Puts the item cubes back in the basket after this frame's animation, mirror and tip-over.
func _follow_basket() -> void:
	if _basket_bone >= 0:
		_stack.transform = _basket_pose() * _stack_offset


## The basket bone in the cart's space.
func _basket_pose() -> Transform3D:
	return _cart.global_transform.affine_inverse() * _skeleton.global_transform * _skeleton.get_bone_global_pose(_basket_bone)


## Shirt and handle in the profile color; no profile keeps Evan's colors.
func _apply_tint() -> void:
	_tinted_for = _cart.profile
	for node: Node in _model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		for surface: int in mesh.mesh.get_surface_count():
			var original := mesh.mesh.surface_get_material(surface) as BaseMaterial3D
			if original == null or not original.resource_name in TINTED_MATERIALS:
				continue
			mesh.set_surface_override_material(surface, null if _tinted_for == null else _tint(original, _tinted_for.color))


static func _tint(original: BaseMaterial3D, color: Color) -> BaseMaterial3D:
	var key := "%s|%s" % [original.resource_name, color.to_html()]
	if not _tints.has(key):
		var tinted := original.duplicate() as BaseMaterial3D
		tinted.albedo_color = color
		_tints[key] = tinted
	return _tints[key]
