extends Area3D
## TEST-ONLY checkout pad for systems/cart/test/ (Store's real checkout replaces it in the game).
## Empties any Cart that drives onto it and adds the value to `banked`.

var banked: int = 0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(5, true) # zones
	set_collision_mask_value(2, true) # carts
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 1.0, 4.0)
	shape.shape = box
	shape.position = Vector3(0.0, 0.5, 0.0)
	add_child(shape)
	var mesh := MeshInstance3D.new()
	var plate := BoxMesh.new()
	plate.size = Vector3(4.0, 0.05, 4.0)
	mesh.mesh = plate
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#2E7D32")
	mesh.material_override = material
	mesh.position = Vector3(0.0, 0.03, 0.0)
	add_child(mesh)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Cart:
		for taken: ItemData in (body as Cart).take_all_items():
			banked += taken.value
