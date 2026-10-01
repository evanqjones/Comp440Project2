extends Node
## Integrates Anthony's Store and Rickey's human-player systems for Run Project.

const CAMERA_SCENE: PackedScene = preload("res://systems/player/chase_camera.tscn")
const CART_SCENE: PackedScene = preload("res://systems/cart/cart.tscn")
const BOT_AGENT_RADIUS: float = 0.75
const STATIC_BATCH_CELL_SIZE: float = 10.0

@onready var _store: Store = $Store
@onready var _carts: Node3D = $Carts
@onready var _player: Cart = $Carts/PlayerCart


func _ready() -> void:
	_batch_static_store_meshes()
	_combine_static_store_surfaces()
	_disable_static_store_shadows()
	_configure_web_rendering()
	var starts := _store.get_start_transforms()
	if not starts.is_empty():
		_player.global_transform = starts[0]
	RoundManager.register_cart(_player)
	var controller := PlayerController.new()
	controller.name = "PlayerController"
	_player.add_child(controller)
	_spawn_rival("CarlCart", 1, "carl", 12, 0.8, 0.4, starts)
	_spawn_rival("BevCart", 2, "bev", 6, 0.2, 0.2, starts)
	_spawn_rival("RitaCart", 3, "rita", 20, 0.4, 0.9, starts)

	var camera := CAMERA_SCENE.instantiate() as ChaseCamera
	camera.target = _player
	add_child(camera)

	var feedback := PlayerFeedback.new()
	feedback.cart = _player
	feedback.camera = camera
	add_child(feedback)

	var hud := PlayerHud.new()
	hud.name = "PlayerHud"
	hud.cart = _player
	add_child(hud)

	var receipt := RoundReceipt.new()
	receipt.name = "RoundReceipt"
	receipt.cart = _player
	add_child(receipt)
	var pause_menu := PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)


## Web targets lower-powered integrated GPUs, so skip the live shadow-map pass there.
## Desktop builds keep the authored directional-light shadows.
func _configure_web_rendering() -> void:
	if OS.has_feature("web"):
		var sun := get_node_or_null("Sun") as DirectionalLight3D
		if sun != null:
			sun.shadow_enabled = false


## Static store dressing stays lit but does not add hundreds of shadow casters.
func _disable_static_store_shadows() -> void:
	var visuals := _store.get_node_or_null("ProductionStoreVisuals")
	if visuals == null:
		return
	for node: Node in visuals.find_children("*", "GeometryInstance3D", true, false):
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Merge repeated static meshes into spatially bounded draw batches at startup.
func _batch_static_store_meshes() -> void:
	var visuals := _store.get_node_or_null("ProductionStoreVisuals") as Node3D
	if visuals == null:
		return
	var groups: Dictionary[String, Dictionary] = {}
	var root_inverse := visuals.global_transform.affine_inverse()
	for node: Node in visuals.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		if instance.mesh == null or not instance.is_visible_in_tree():
			continue
		# Keep unusual per-instance visibility/transparency behavior on its original node.
		if instance.transparency > 0.0 or instance.visibility_range_begin > 0.0 or instance.visibility_range_end > 0.0:
			continue
		var cell_x := floori(instance.global_position.x / STATIC_BATCH_CELL_SIZE)
		var cell_z := floori(instance.global_position.z / STATIC_BATCH_CELL_SIZE)
		var override_id := instance.material_override.get_instance_id() if instance.material_override != null else 0
		var overlay_id := instance.material_overlay.get_instance_id() if instance.material_overlay != null else 0
		var key := "%d:%d:%d:%d:%d:%d" % [instance.mesh.get_instance_id(), override_id, overlay_id, instance.layers, cell_x, cell_z]
		var group: Dictionary = groups.get(key, {})
		var sources: Array[MeshInstance3D]
		var transforms: Array[Transform3D]
		if group.is_empty():
			sources = []
			transforms = []
			group = {
				"mesh": instance.mesh,
				"material_override": instance.material_override,
				"material_overlay": instance.material_overlay,
				"layers": instance.layers,
				"sources": sources,
				"transforms": transforms,
			}
		else:
			sources = group["sources"]
			transforms = group["transforms"]
		sources.append(instance)
		transforms.append(root_inverse * instance.global_transform)
		group["sources"] = sources
		group["transforms"] = transforms
		groups[key] = group
	var batch_index := 0
	for group_value: Dictionary in groups.values():
		var sources: Array[MeshInstance3D] = group_value["sources"]
		if sources.size() < 2:
			continue
		var transforms: Array[Transform3D] = group_value["transforms"]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = group_value["mesh"] as Mesh
		multimesh.instance_count = transforms.size()
		multimesh.visible_instance_count = transforms.size()
		for index: int in transforms.size():
			multimesh.set_instance_transform(index, transforms[index])
		var batch := MultiMeshInstance3D.new()
		batch.name = "StaticMeshBatch_%d" % batch_index
		batch.multimesh = multimesh
		batch.material_override = group_value["material_override"] as Material
		batch.material_overlay = group_value["material_overlay"] as Material
		batch.layers = group_value["layers"]
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		visuals.add_child(batch)
		for source: MeshInstance3D in sources:
			source.visible = false
			source.queue_free()
		batch_index += 1


## Combine static opaque surfaces by material and nearby cells to reduce draw calls.
func _combine_static_store_surfaces() -> void:
	var visuals := _store.get_node_or_null("ProductionStoreVisuals") as Node3D
	if visuals == null:
		return
	var groups: Dictionary[String, Dictionary] = {}
	var root_inverse := visuals.global_transform.affine_inverse()
	for node: Node in visuals.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		if instance.mesh == null or instance.mesh.get_surface_count() != 1 or not instance.is_visible_in_tree():
			continue
		if instance.material_overlay != null or instance.transparency > 0.0 or instance.visibility_range_begin > 0.0 or instance.visibility_range_end > 0.0:
			continue
		var surface := 0
		if instance.mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var material := instance.get_active_material(surface)
		var cell_x := floori(instance.global_position.x / STATIC_BATCH_CELL_SIZE)
		var cell_z := floori(instance.global_position.z / STATIC_BATCH_CELL_SIZE)
		var material_id := material.get_instance_id() if material != null else 0
		var format: int = instance.mesh.surface_get_format(surface)
		var key := "%d:%d:%d:%d:%d" % [material_id, instance.layers, format, cell_x, cell_z]
		var group: Dictionary = groups.get(key, {})
		var tool: SurfaceTool
		var sources: Array[MeshInstance3D]
		if group.is_empty():
			tool = SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			sources = []
			group = {"tool": tool, "material": material, "layers": instance.layers, "sources": sources}
		else:
			tool = group["tool"]
			sources = group["sources"]
		tool.append_from(instance.mesh, surface, root_inverse * instance.global_transform)
		sources.append(instance)
		group["sources"] = sources
		groups[key] = group
	var batch_index := 0
	for group_value: Dictionary in groups.values():
		var sources: Array[MeshInstance3D] = group_value["sources"]
		if sources.size() < 2:
			continue
		var combined_mesh := (group_value["tool"] as SurfaceTool).commit()
		if combined_mesh == null:
			continue
		combined_mesh.surface_set_material(0, group_value["material"] as Material)
		var batch := MeshInstance3D.new()
		batch.name = "StaticSurfaceBatch_%d" % batch_index
		batch.mesh = combined_mesh
		batch.layers = group_value["layers"]
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		visuals.add_child(batch)
		for source: MeshInstance3D in sources:
			source.visible = false
			source.queue_free()
		batch_index += 1


func _spawn_rival(cart_name: String, cart_id: int, profile_name: String, greed: int, aggression: float, boost_habit: float, starts: Array[Transform3D]) -> void:
	if cart_id >= starts.size():
		push_error("Store is missing start transform for %s" % cart_name)
		return
	var cart := CART_SCENE.instantiate() as Cart
	cart.name = cart_name
	cart.cart_id = cart_id
	cart.profile = load("res://systems/shared/profiles/%s.tres" % profile_name) as ShopperProfile
	cart.global_transform = starts[cart_id]
	var agent := NavigationAgent3D.new()
	agent.name = "NavigationAgent3D"
	agent.radius = BOT_AGENT_RADIUS
	agent.path_desired_distance = 1.0
	agent.target_desired_distance = 1.0
	cart.add_child(agent)
	var personality := BotPersonality.new()
	personality.greed = greed
	personality.base_aggression = aggression
	personality.boost_habit = boost_habit
	var controller := BotController.new()
	controller.name = "BotController"
	controller.personality = personality
	controller.cart = cart
	controller.nav_agent = agent
	cart.add_child(controller)
	RoundManager.register_cart(cart)
	_carts.add_child(cart)
