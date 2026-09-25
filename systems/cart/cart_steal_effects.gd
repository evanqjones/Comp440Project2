class_name CartStealEffects
extends RefCounted
## Visual-only steal effects (docs/features/cart/04-ram-steal/01-spec.md §3): the robbed cart
## tipping onto its side, and inherited items flying into the winner's basket. The data has
## already moved when these start; they never touch inventories.

## Bottom-left edge of the 0.8 m-wide cart: the tip-over pivots here.
const TIP_EDGE := Vector3(-0.4, 0.0, 0.0)


## Rolls the cart's Visual 90° onto its side over tip_time, holds, and pops back upright,
## so it's upright again at stun_time.
static func tip_over(cart: Cart) -> void:
	var visual := cart.get_node_or_null("Visual") as Node3D
	if visual == null:
		return
	_kill_tip(cart)
	var t := cart.tuning
	var set_tip := func(amount: float) -> void: _apply_tip(visual, amount)
	var tween := cart.create_tween()
	cart.set_meta("tip_tween", tween)
	tween.tween_method(set_tip, 0.0, 1.0, t.tip_time)
	tween.tween_interval(maxf(0.0, t.stun_time - 2.0 * t.tip_time))
	tween.tween_method(set_tip, 1.0, 0.0, t.tip_time)


## Upright immediately, with any tip-over stopped (round reset).
static func reset(cart: Cart) -> void:
	_kill_tip(cart)
	var visual := cart.get_node_or_null("Visual") as Node3D
	if visual != null:
		_apply_tip(visual, 0.0)


## Each item flies as its colored cube from the loser's stack to the winner's in an arc,
## staggered; the winner's stack reveals one cube per landing. Cubes are children of the winner
## (positioned in world space), so they and their tweens are freed with it.
static func fly_items(winner: Cart, loser: Cart, items: Array[ItemData]) -> void:
	if items.is_empty() or not winner.is_inside_tree():
		return
	var t := winner.tuning
	var start := loser.item_stack_position()
	winner.hold_back_newest(items.size())
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * CartItemStack.CUBE_SIZE
	for i: int in items.size():
		var cube := MeshInstance3D.new()
		cube.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = CartItemStack.color_for(items[i])
		cube.material_override = material
		cube.visible = false
		winner.add_child(cube)
		cube.global_position = start
		var fly := func(progress: float) -> void:
			cube.global_position = _arc(start, winner.item_stack_position(), t.flight_height, progress)
		var land := func() -> void:
			winner.reveal_one_held()
			cube.queue_free()
		var tween := cube.create_tween()
		tween.tween_interval(i * t.flight_stagger)
		tween.tween_callback(cube.show)
		tween.tween_method(fly, 0.0, 1.0, t.flight_time)
		tween.tween_callback(land)


static func _arc(from: Vector3, to: Vector3, height: float, progress: float) -> Vector3:
	return from.lerp(to, progress) + Vector3.UP * (4.0 * height * progress * (1.0 - progress))


## amount 0 = upright, 1 = on its side: a roll about the forward axis around TIP_EDGE.
static func _apply_tip(visual: Node3D, amount: float) -> void:
	var basis := Basis(Vector3(0.0, 0.0, 1.0), deg_to_rad(90.0) * amount)
	visual.transform = Transform3D(basis, TIP_EDGE - basis * TIP_EDGE)


static func _kill_tip(cart: Cart) -> void:
	if cart.has_meta("tip_tween"):
		var old := cart.get_meta("tip_tween") as Tween
		if old != null and old.is_valid():
			old.kill()
