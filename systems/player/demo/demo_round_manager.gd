class_name DemoRoundManager
extends "res://systems/store/round_manager.gd"
## FALLBACK DEMO ONLY (docs/features/player/03-demo-bots/FEATURE.md): stands in for Store's
## RoundManager while demo_round.tscn runs, so John's bots can see the pickups and the checkout.
## demo_round.gd swaps this script onto the RoundManager autoload on ready and puts Anthony's stub
## back on exit. Anthony's real RoundManager replaces it in main.tscn.

## The node whose child Pickups are "on the floor" (the demo root: aisle pickups and spills).
var demo_pickup_parent: Node
## Where bots drive to bank (the demo's checkout pad).
var demo_checkout_position := Vector3.ZERO


## Untaken pickups: a taken TestPickup hides until it respawns.
func get_pickups() -> Array[Pickup]:
	var pickups: Array[Pickup] = []
	if not is_instance_valid(demo_pickup_parent):
		return pickups
	for child: Node in demo_pickup_parent.get_children():
		var pickup := child as Pickup
		if pickup != null and pickup.visible and pickup.item != null:
			pickups.append(pickup)
	return pickups


func get_checkout_position() -> Vector3:
	return demo_checkout_position
