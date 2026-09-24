class_name CartState
extends RefCounted
## Read-only snapshot of one cart, returned by Cart.get_state() (docs/CONTRACTS.md §1.4).
## It's a copy: changing it changes nothing on the cart. Get a fresh one for current values.

var cart_id: int = 0
var display_name: String = ""
var color: Color = Color()
var position: Vector3 = Vector3.ZERO
## m/s, horizontal.
var speed: float = 0.0
## A copy of the cart's items.
var items: Array[ItemData] = []
## Sum of the items' values, in dollars.
var value: int = 0
## 0.0 empty to 1.0 full.
var boost_meter: float = 0.0
var is_stunned: bool = false
var is_immune: bool = false
