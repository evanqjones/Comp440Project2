# 02-inventory: Plan

> **For agentic workers:** execute one task at a time, test first (`AGENTS.md` Rules 4–5). Tick the matching line in [03-todo.md](03-todo.md) as you finish each task.

| | |
|---|---|
| System / Owner | Cart / Rickey |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |

**Goal:** carts carry up to 24 items (slowing 1.2% each), show them as colored cubes, and hand them to Store at checkout.

**Architecture:** a pure `CartInventory` helper holds the items oldest first. `CartItemStack` shows them as a pool of 24 cubes. `cart.gd` adds the round-phase check and the signals.

**Tech:** Godot 4.7.2, GDScript (static typing, tabs), GUT 9.7.1.

## Global Constraints

- Contract signatures unchanged (`CONTRACTS.md` §2); `tests/shared/test_contracts.gd` must keep passing.
- Edit only `systems/cart/`, `tests/cart/`, `docs/features/cart/`, Rickey's PROGRESS sections, and a `DECISIONS.md` append.
- Suite: `godot --headless --path . --import`, then `godot --headless --path . -s addons/gut/gut_cmdln.gd`. Any `SCRIPT ERROR`, or a `Scripts` count lower than the number of `test_*.gd` files, is a failure. **Keep helpers that reference a later task's code out of earlier tasks' test blocks** (lesson from `cart/01`).

## 1. Blueprint

1. `CartInventory` + `CartTuning.item_cap`
2. `CartItemStack` (cube pool, palette colors)
3. `Cart` uses both: real `try_add_item` / `take_all_items`, signals, weight
4. Test pickups + checkout pad in the cart test scene
5. Docs: D-018, PROGRESS handoffs

## 2. Tasks

### Task 1: CartInventory

**Files:** create `systems/cart/cart_inventory.gd`; modify `systems/cart/cart_tuning.gd`; test `tests/cart/test_cart_inventory.gd`.
**Produces:** `CartInventory.new(capacity: int = 24)`, `try_add(item: ItemData) -> bool`, `take_all() -> Array[ItemData]`, `items() -> Array[ItemData]`, `count() -> int`, `value() -> int`, `is_full() -> bool`, `has(item: ItemData) -> bool`, `var capacity: int`; `CartTuning.item_cap: int = 24`.

- [ ] **Step 1: failing tests** (`tests/cart/test_cart_inventory.gd`)

```gdscript
extends GutTest
## Cart inventory (docs/features/cart/02-inventory/01-spec.md §3, §7).

var _next_id := 1


func _item(category: GameTypes.Category, value: int) -> ItemData:
	var item := ItemData.new()
	item.item_id = _next_id
	_next_id += 1
	item.category = category
	item.value = value
	item.is_deal = category == GameTypes.Category.DEAL
	return item


func test_inventory_holds_24_then_refuses() -> void:
	var inventory := CartInventory.new(24)
	for i: int in 24:
		assert_true(inventory.try_add(_item(GameTypes.Category.PRODUCE, 5)), "item %d fits" % (i + 1))
	assert_true(inventory.is_full())
	assert_false(inventory.try_add(_item(GameTypes.Category.PRODUCE, 5)), "the 25th is refused")
	assert_eq(inventory.count(), 24)


func test_inventory_refuses_null_and_duplicates() -> void:
	var inventory := CartInventory.new(24)
	var item := _item(GameTypes.Category.DAIRY, 10)
	assert_false(inventory.try_add(null), "null refused")
	assert_true(inventory.try_add(item))
	assert_false(inventory.try_add(item), "the same item twice is refused")
	assert_eq(inventory.count(), 1)


func test_inventory_take_all_is_oldest_first_and_empties() -> void:
	var inventory := CartInventory.new(24)
	var first := _item(GameTypes.Category.PRODUCE, 5)
	var second := _item(GameTypes.Category.SNACKS, 15)
	var third := _item(GameTypes.Category.DEAL, 100)
	for item: ItemData in [first, second, third]:
		inventory.try_add(item)
	var taken := inventory.take_all()
	assert_eq(taken.size(), 3)
	assert_same(taken[0], first, "oldest first")
	assert_same(taken[2], third)
	assert_eq(inventory.count(), 0, "emptied")
	assert_eq(inventory.take_all().size(), 0, "taking from an empty cart is fine")


func test_inventory_value_and_count() -> void:
	var inventory := CartInventory.new(24)
	inventory.try_add(_item(GameTypes.Category.PRODUCE, 5))
	inventory.try_add(_item(GameTypes.Category.ELECTRONICS, 40))
	inventory.try_add(_item(GameTypes.Category.DEAL, 100))
	assert_eq(inventory.count(), 3)
	assert_eq(inventory.value(), 145)
	var copy := inventory.items()
	copy.clear()
	assert_eq(inventory.count(), 3, "items() is a copy")


func test_tuning_item_cap_is_24() -> void:
	assert_eq((load("res://systems/cart/cart_tuning.tres") as CartTuning).item_cap, 24)
```

- [ ] **Step 2: run; expect `Identifier "CartInventory" not declared`.**
- [ ] **Step 3: implement.** Add to `cart_tuning.gd` (after `slowdown_per_item`):

```gdscript
## Most items a cart can carry.
@export var item_cap: int = 24
```

`systems/cart/cart_inventory.gd`:

```gdscript
class_name CartInventory
extends RefCounted
## The items one cart carries, in the order they were picked up
## (docs/features/cart/02-inventory/01-spec.md §3). Pure data with no nodes, so the rules are
## unit-testable. Only Cart writes to it (CONTRACTS.md §8, invariant 5).

var capacity: int

var _items: Array[ItemData] = []


func _init(cap: int = 24) -> void:
	capacity = cap


## Adds the item unless it's null, the cart is full, or this exact item is already here.
func try_add(item: ItemData) -> bool:
	if item == null or is_full() or has(item):
		return false
	_items.append(item)
	return true


## Empties the cart and returns everything, oldest first.
func take_all() -> Array[ItemData]:
	var taken: Array[ItemData] = _items.duplicate()
	_items.clear()
	return taken


## A copy, oldest first.
func items() -> Array[ItemData]:
	return _items.duplicate()


func count() -> int:
	return _items.size()


## Total dollars.
func value() -> int:
	var total := 0
	for item: ItemData in _items:
		total += item.value
	return total


func is_full() -> bool:
	return _items.size() >= capacity


## True if this exact item (same instance) is in the cart.
func has(item: ItemData) -> bool:
	return _items.has(item)
```

- [ ] **Step 4: run; all passing.** **Step 5: commit** `cart: add CartInventory and item cap`

### Task 2: CartItemStack

**Files:** create `systems/cart/cart_item_stack.gd`; test: append to `tests/cart/test_cart_inventory.gd`.
**Produces:** `class_name CartItemStack extends Node3D`, `show_items(items: Array[ItemData]) -> void`, `visible_count() -> int`, `static color_for(item: ItemData) -> Color`, `const MAX_CUBES := 24`.

- [ ] **Step 1: failing tests** (append)

```gdscript
func test_stack_shows_one_cube_per_item_in_palette_colors() -> void:
	var stack := CartItemStack.new()
	add_child_autofree(stack)
	var items: Array[ItemData] = [_item(GameTypes.Category.PRODUCE, 5), _item(GameTypes.Category.DEAL, 100)]
	stack.show_items(items)
	assert_eq(stack.visible_count(), 2)
	assert_eq(CartItemStack.color_for(items[0]), Color("#4CAF50"), "produce is green")
	assert_eq(CartItemStack.color_for(items[1]), Color("#E6B422"), "a Deal is gold")
	var none: Array[ItemData] = []
	stack.show_items(none)
	assert_eq(stack.visible_count(), 0)
```

- [ ] **Step 2: run; expect failure.** **Step 3: implement** `systems/cart/cart_item_stack.gd`:

```gdscript
class_name CartItemStack
extends Node3D
## Shows a cart's items as small colored cubes stacked in the basket
## (docs/features/cart/02-inventory/01-spec.md §3). A pool of 24 cubes is built once and
## shown or hidden, so pickups don't allocate. Colors come from ASSETS.md §3. Evan's item
## models can replace the cubes later.
## Place it as a child of the Cart. On ready it moves to the `anchor` marker (the basket's
## ItemStack) if one exists.

const MAX_CUBES := 24
const CUBE_SIZE := 0.22
const SPACING := 0.24
const COLORS := {
	GameTypes.Category.PRODUCE: Color("#4CAF50"),
	GameTypes.Category.BAKERY: Color("#FF9800"),
	GameTypes.Category.DAIRY: Color("#F5F5F5"),
	GameTypes.Category.SNACKS: Color("#E53935"),
	GameTypes.Category.FROZEN: Color("#1E88E5"),
	GameTypes.Category.ELECTRONICS: Color("#8E24AA"),
	GameTypes.Category.DEAL: Color("#E6B422"),
}

## The basket's ItemStack marker (inside Visual). Empty or missing = stay where placed.
@export var anchor: NodePath = NodePath("../Visual/ItemStack")

static var _materials: Dictionary = {}

var _cubes: Array[MeshInstance3D] = []


func _ready() -> void:
	var marker := get_node_or_null(anchor) as Node3D
	if marker != null:
		global_transform = marker.global_transform
	_ensure_cubes()


## Shows the first MAX_CUBES items, oldest at the bottom.
func show_items(items: Array[ItemData]) -> void:
	_ensure_cubes()
	for i: int in _cubes.size():
		var cube := _cubes[i]
		cube.visible = i < items.size()
		if cube.visible:
			cube.material_override = _material_for(items[i])


func visible_count() -> int:
	var shown := 0
	for cube: MeshInstance3D in _cubes:
		if cube.visible:
			shown += 1
	return shown


## Palette color for an item; a Deal of the Day is always gold.
static func color_for(item: ItemData) -> Color:
	var category := GameTypes.Category.DEAL if item.is_deal else item.category
	return COLORS[category]


static func _material_for(item: ItemData) -> StandardMaterial3D:
	var color := color_for(item)
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		_materials[color] = material
	return _materials[color]


## 3 across (x) × 2 deep (z) × 4 high (y), filled bottom layer first.
func _ensure_cubes() -> void:
	if not _cubes.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * CUBE_SIZE
	for i: int in MAX_CUBES:
		var layer := floori(i / 6.0)
		var slot := i % 6
		var column := slot % 3
		var row := floori(slot / 3.0)
		var cube := MeshInstance3D.new()
		cube.mesh = mesh
		cube.position = Vector3((column - 1) * SPACING, CUBE_SIZE / 2.0 + layer * SPACING, (row - 0.5) * SPACING)
		cube.visible = false
		add_child(cube)
		_cubes.append(cube)
```

- [ ] **Step 4: run; all passing.** **Step 5: commit** `cart: add CartItemStack cube display`

### Task 3: Cart carries items

**Files:** modify `systems/cart/cart.gd`, `systems/cart/cart.tscn`; test: append to `tests/cart/test_cart_inventory.gd`.
**Consumes:** Tasks 1–2. **Produces:** the contract behavior in spec §3.

- [ ] **Step 1: failing tests** (append)

```gdscript
const CART_SCENE := "res://systems/cart/cart.tscn"


func _make_cart() -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	return cart


func _with_phase(phase: GameTypes.Phase) -> GameTypes.Phase:
	var saved: GameTypes.Phase = RoundManager.phase
	RoundManager.phase = phase
	return saved


func test_cart_refuses_when_round_not_active() -> void:
	var saved := _with_phase(GameTypes.Phase.COUNTDOWN)
	var cart := _make_cart()
	watch_signals(cart)
	assert_false(cart.try_add_item(_item(GameTypes.Category.PRODUCE, 5)))
	assert_eq(cart.get_state().items.size(), 0)
	assert_signal_not_emitted(cart, "item_collected")
	RoundManager.phase = saved


func test_cart_collects_while_stunned() -> void:
	var saved := _with_phase(GameTypes.Phase.RUSH)
	var cart := _make_cart()
	cart._is_stunned = true
	assert_true(cart.try_add_item(_item(GameTypes.Category.PRODUCE, 5)), "GAME_SPEC §5.5: stun blocks driving, not collecting")
	RoundManager.phase = saved


func test_item_collected_emitted_with_cart_and_item() -> void:
	var saved := _with_phase(GameTypes.Phase.RUSH)
	var cart := _make_cart()
	watch_signals(cart)
	var item := _item(GameTypes.Category.BAKERY, 10)
	assert_true(cart.try_add_item(item))
	assert_signal_emitted_with_parameters(cart, "item_collected", [cart, item])
	RoundManager.phase = saved


func test_cart_full_emitted_once_at_24_and_again_after_refill() -> void:
	var saved := _with_phase(GameTypes.Phase.FINAL_CALL)
	var cart := _make_cart()
	watch_signals(cart)
	for _i: int in 26:
		cart.try_add_item(_item(GameTypes.Category.PRODUCE, 5))
	assert_signal_emit_count(cart, "cart_full", 1, "once on reaching 24, not on refused extras")
	cart.take_all_items()
	for _i: int in 24:
		cart.try_add_item(_item(GameTypes.Category.PRODUCE, 5))
	assert_signal_emit_count(cart, "cart_full", 2, "again after emptying and refilling")
	RoundManager.phase = saved


func test_take_all_items_returns_same_instances_and_empties() -> void:
	var saved := _with_phase(GameTypes.Phase.RUSH)
	var cart := _make_cart()
	var a := _item(GameTypes.Category.FROZEN, 20)
	var b := _item(GameTypes.Category.DEAL, 100)
	cart.try_add_item(a)
	cart.try_add_item(b)
	RoundManager.phase = GameTypes.Phase.CLOSED
	var taken := cart.take_all_items()
	assert_eq(taken.size(), 2, "works after close (Store's deferred checkout)")
	assert_same(taken[0], a, "same instances, oldest first")
	assert_same(taken[1], b)
	assert_eq(cart.get_state().items.size(), 0)
	RoundManager.phase = saved


func test_state_items_copy_and_value() -> void:
	var saved := _with_phase(GameTypes.Phase.RUSH)
	var cart := _make_cart()
	cart.try_add_item(_item(GameTypes.Category.SNACKS, 15))
	cart.try_add_item(_item(GameTypes.Category.ELECTRONICS, 40))
	var state := cart.get_state()
	assert_eq(state.value, 55)
	state.items.clear()
	assert_eq(cart.get_state().items.size(), 2, "snapshot is a copy")
	RoundManager.phase = saved


func test_reset_for_round_empties() -> void:
	var saved := _with_phase(GameTypes.Phase.RUSH)
	var cart := _make_cart()
	cart.try_add_item(_item(GameTypes.Category.PRODUCE, 5))
	cart.reset_for_round(Transform3D.IDENTITY)
	assert_eq(cart.get_state().items.size(), 0)
	RoundManager.phase = saved


func test_cart_shows_one_cube_per_item() -> void:
	var saved := _with_phase(GameTypes.Phase.RUSH)
	var cart := _make_cart()
	var stack := cart.get_node("ItemStackDisplay") as CartItemStack
	for _i: int in 5:
		cart.try_add_item(_item(GameTypes.Category.DAIRY, 10))
	assert_eq(stack.visible_count(), 5)
	cart.take_all_items()
	assert_eq(stack.visible_count(), 0)
	RoundManager.phase = saved


func test_full_cart_tops_out_near_10_7() -> void:
	var saved := _with_phase(GameTypes.Phase.RUSH)
	var ground := StaticBody3D.new()
	ground.position = Vector3(0.0, -0.5, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	var cart := _make_cart()
	for _i: int in 24:
		cart.try_add_item(_item(GameTypes.Category.PRODUCE, 5))
	var cmd := DriveCommand.new()
	cmd.throttle = 1.0
	for _i: int in 150:
		cart.apply_command(cmd)
		await wait_physics_frames(1)
	assert_almost_eq(cart.get_state().speed, 10.68, 0.5, "full cart is ~29% slower than 15 m/s")
	RoundManager.phase = saved
```

- [ ] **Step 2: run; expect failures** (the stub refuses everything; `ItemStackDisplay` is missing).
- [ ] **Step 3: implement.** In `cart.gd`:
  - Replace `var _items: Array[ItemData] = []` with `var _inventory := CartInventory.new()` and `@onready var _stack := get_node_or_null("ItemStackDisplay") as CartItemStack`.
  - In `_ready()`, after the tuning fallback: `_inventory.capacity = tuning.item_cap`.
  - Top speed uses `_inventory.count()`.
  - Replace the bodies:

```gdscript
## False if the round isn't active, the cart is full, the item is null, or it's already here.
## A stunned cart still collects (GAME_SPEC.md §5.5).
func try_add_item(item: ItemData) -> bool:
	if not RoundManager.is_gameplay_active():
		return false
	if not _inventory.try_add(item):
		return false
	_refresh_stack()
	item_collected.emit(self, item)
	if _inventory.is_full():
		cart_full.emit(self)
	return true


## Empties the cart and returns what it held, oldest first. Store's checkout calls this.
## Works in any phase (the deferred checkout can land just after close).
func take_all_items() -> Array[ItemData]:
	var taken := _inventory.take_all()
	_refresh_stack()
	return taken


func _refresh_stack() -> void:
	if _stack != null:
		_stack.show_items(_inventory.items())
```

  - `reset_for_round`: `_inventory.take_all()` then `_refresh_stack()` (instead of `_items.clear()`).
  - `get_state`: `state.items = _inventory.items()`, `state.value = _inventory.value()`.
  - `cart.tscn`: add `Visual/ItemStack` (Marker3D at y = 1.0) and `ItemStackDisplay` (Node3D, script `cart_item_stack.gd`) as the last child of `Cart`.

- [ ] **Step 4: run; all passing** (including `test_contracts.gd`). **Step 5: commit** `cart: carry items (cap, signals, cubes, weight)`

### Task 4: test pickups and checkout pad

**Files:** create `systems/cart/test/test_pickup.gd`, `systems/cart/test/test_checkout_pad.gd`; modify `systems/cart/test/cart_drive_test.gd`.

- [ ] **Step 1:** `test_pickup.gd`: an `Area3D` (layer 3, mask 2) with a 0.6 m sphere and a 0.35 m cube in the item's color (`CartItemStack.color_for`). It picks a weighted category (30/25/25/12/6/2 → $5/10/10/15/20/40) and a unique `item_id`. On a `Cart` entering, while visible: if `try_add_item` succeeds, it hides, stops monitoring, and after 3 s respawns with a new item.
- [ ] **Step 2:** `test_checkout_pad.gd`: an `Area3D` (layer 5, mask 2) with a 4 × 1 × 4 m box and a flat green 4 × 0.05 × 4 m mesh. On a `Cart` entering, it adds the value of `take_all_items()` to `banked`.
- [ ] **Step 3:** `cart_drive_test.gd`: spawn 30 pickups at fixed seeded positions in x, z ∈ [−25, 25] (RandomNumberGenerator seed 440), and the pad at (0, 0, 20). The readout adds `items n/24`, `value $`, top speed from `CartMotion.top_speed(tuning, count, false)`, and `banked $`.
- [ ] **Step 4:** the scene runs headless for 120 frames with no errors, and a rendered frame shows pickups and the pad. Full suite green. **Step 5: commit** `cart: test pickups and checkout pad`. Rickey's hand check.

### Task 5: docs and handoffs

- [ ] D-018 in `DECISIONS.md`; Cart section of `PROGRESS.md` (Done, handoffs for Anthony and John). Suite; commit `cart: docs and handoffs for 02-inventory`.

## 3. Prompts

```text
Context: Cart feature 02-inventory. Read AGENTS.md, docs/features/cart/02-inventory/01-spec.md and 02-plan.md.
Task: execute Task <N> exactly: failing test first (run the suite and see it fail), then the code shown,
then the full GUT suite headless (no SCRIPT ERROR; Scripts count = number of test files). Tick Task <N> in
03-todo.md, commit with the message in the task, stop and report the test summary.
```

## 4. Improvements and bugs

1. Plan self-review: renamed a test variable `floor` (it hides the built-in `floor()`), and used `floori()` instead of integer division in the cube layout (avoids a GDScript warning).
