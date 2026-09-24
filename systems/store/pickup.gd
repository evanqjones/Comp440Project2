class_name Pickup
extends Area3D
## A grocery item lying on the store floor (docs/CONTRACTS.md §3.1).
##
## STUB from integration/00-foundation. Anthony implements the pickup flow in
## store/03-spawns-checkout: when a Cart enters during gameplay, call cart.try_add_item(item);
## if it returns true, mark this pickup taken, ignore every later body, and free it.

var item: ItemData


func _init() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true) # pickups
	set_collision_mask_value(2, true) # carts
