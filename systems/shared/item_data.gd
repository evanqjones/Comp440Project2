class_name ItemData
extends Resource
## One grocery item (docs/CONTRACTS.md §1.3).
## Every spawned item is its own instance (ItemData.new() or duplicate()); the same
## instance moves between cart, floor, and checkout so its identity is preserved.

## Unique for the whole match; assigned by Store at spawn. -1 means unassigned.
@export var item_id: int = -1
@export var category: GameTypes.Category = GameTypes.Category.PRODUCE
## Dollars.
@export var value: int = 0
@export var is_deal: bool = false
## Optional; null means "use the category's default look".
@export var mesh: Mesh
