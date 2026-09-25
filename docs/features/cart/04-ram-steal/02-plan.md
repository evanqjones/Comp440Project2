# 04-ram-steal: Plan

> **For agentic workers:** execute one task at a time, test first (`AGENTS.md` Rules 4–5). Tick the matching line in [03-todo.md](03-todo.md) as you finish each task.

| | |
|---|---|
| System / Owner | Cart / Rickey |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |

**Goal:** ram-steal per GAME_SPEC §5, resolved exactly once, item-conserving, with tip-over and flying-item visuals.

**Architecture:** `CartSteal` holds the pure rules. `cart.gd` detects slide collisions with other carts and resolves each pair once (0.2 s pair lock, counted in physics frames). The winner moves the data instantly, then the loser emits `cart_robbed`. `CartStealEffects` plays the visuals only.

**Tech:** Godot 4.7.2, GDScript, GUT 9.7.1.

## Global Constraints

- Contract signatures unchanged; `tests/shared/test_contracts.gd` stays green.
- Edit only `systems/cart/`, `tests/cart/`, `docs/features/cart/`, Rickey's PROGRESS sections, GAME_SPEC §12 rows, and a DECISIONS append.
- Suite: `godot --headless --path . --import`, then `godot --headless --path . -s addons/gut/gut_cmdln.gd`. Any `SCRIPT ERROR`, or `Scripts` < number of test files, is a failure. Test helpers must only reference code from the same or earlier tasks.
- Invariants (CONTRACTS §8): each item in exactly one place; one steal per contact; `cart_robbed` after both inventories update; nothing after close.

## 1. Blueprint

1. `CartTuning` steal fields + `CartSteal` (outcome, split), pure tests
2. `cart.gd`: timers, contact detection, pair lock, steal/bounce application, `cart_robbed` from the loser; GDD §11.2 tests
3. `CartStealEffects`: tip-over + item flight; `CartItemStack` hold-back; visual tests
4. Test scene: targets, rammer, R reset
5. Docs: D-019, GAME_SPEC §12, PROGRESS handoffs

## 2. Tasks

### Task 1: steal rules

**Files:** modify `systems/cart/cart_tuning.gd`; create `systems/cart/cart_steal.gd`; test `tests/cart/test_cart_steal.gd`.
**Produces:** `CartSteal.Outcome { NONE, BOUNCE, A_WINS, B_WINS }`, `CartSteal.outcome(t: CartTuning, a: CartState, b: CartState) -> CartSteal.Outcome`, `CartSteal.split(loser_items: Array[ItemData], winner_free_slots: int) -> Array` (`[transferred, spilled]`); tuning fields `steal_min_speed, steal_margin, stun_time, immune_time, winner_keep, knockback_speed, stun_grip, bounce_speed, bounce_keep, pair_cooldown, tip_time, flight_time, flight_stagger, flight_height`.

- [ ] **Step 1: failing tests** (`tests/cart/test_cart_steal.gd`)

```gdscript
extends GutTest
## Ram-steal (docs/features/cart/04-ram-steal/01-spec.md §3, §7; GAME_SPEC.md §5, §11.2).

var t: CartTuning
var _next_id := 1


func before_each() -> void:
	t = CartTuning.new()


func _item(value: int) -> ItemData:
	var item := ItemData.new()
	item.item_id = _next_id
	_next_id += 1
	item.value = value
	return item


func _state(speed: float, item_count: int, stunned := false, immune := false) -> CartState:
	var s := CartState.new()
	s.speed = speed
	for _i: int in item_count:
		s.items.append(_item(10))
	s.is_stunned = stunned
	s.is_immune = immune
	return s


func test_outcome_steal_when_fast_enough_and_margin() -> void:
	assert_eq(CartSteal.outcome(t, _state(14.0, 20), _state(6.0, 8)), CartSteal.Outcome.A_WINS)
	assert_eq(CartSteal.outcome(t, _state(6.0, 8), _state(14.0, 20)), CartSteal.Outcome.B_WINS)


func test_outcome_thresholds_inclusive() -> void:
	assert_eq(CartSteal.outcome(t, _state(5.0, 0), _state(3.5, 3)), CartSteal.Outcome.A_WINS, "exactly 5 and exactly 1.5 faster")
	assert_eq(CartSteal.outcome(t, _state(4.99, 0), _state(0.0, 3)), CartSteal.Outcome.BOUNCE, "under 5 m/s")
	assert_eq(CartSteal.outcome(t, _state(6.0, 0), _state(4.6, 3)), CartSteal.Outcome.BOUNCE, "only 1.4 faster")


func test_outcome_bounce_on_tie_stunned_immune_or_empty() -> void:
	assert_eq(CartSteal.outcome(t, _state(10.0, 3), _state(10.0, 3)), CartSteal.Outcome.BOUNCE, "tie")
	assert_eq(CartSteal.outcome(t, _state(14.0, 0, true), _state(0.0, 3)), CartSteal.Outcome.BOUNCE, "stunned can't win")
	assert_eq(CartSteal.outcome(t, _state(14.0, 0), _state(0.0, 3, false, true)), CartSteal.Outcome.BOUNCE, "immune can't be robbed")
	assert_eq(CartSteal.outcome(t, _state(14.0, 0), _state(0.0, 0)), CartSteal.Outcome.BOUNCE, "empty can't be robbed")
	assert_eq(CartSteal.outcome(t, _state(14.0, 0, false, true), _state(0.0, 3)), CartSteal.Outcome.A_WINS, "immune carts can still rob")


func test_split_oldest_first() -> void:
	var loot: Array[ItemData] = []
	for v: int in [10, 10, 15, 15, 15, 15, 15, 15]:
		loot.append(_item(v))
	var parts := CartSteal.split(loot, 4)
	var transferred: Array[ItemData] = parts[0]
	var spilled: Array[ItemData] = parts[1]
	assert_eq(transferred.size(), 4)
	assert_same(transferred[0], loot[0], "oldest transfers first")
	assert_eq(spilled.size(), 4)
	assert_same(spilled[0], loot[4])
	assert_eq((CartSteal.split(loot, 0)[1] as Array).size(), 8, "winner full: all spill")
	assert_eq((CartSteal.split(loot, 24)[0] as Array).size(), 8, "plenty of room: all transfer")
	assert_eq((CartSteal.split(loot, -3)[1] as Array).size(), 8, "negative room is treated as 0")
```

- [ ] **Step 2: run; expect `Identifier "CartSteal" not declared`.**
- [ ] **Step 3: implement.** Append to `cart_tuning.gd`:

```gdscript
## Steal rule (GAME_SPEC.md §5.1): the faster cart needs at least this speed (m/s)...
@export var steal_min_speed: float = 5.0
## ...and at least this much more speed than the other cart (m/s).
@export var steal_margin: float = 1.5
## Seconds the robbed cart has no control.
@export var stun_time: float = 0.7
## Seconds the robbed cart can't be robbed again (from the moment of the steal).
@export var immune_time: float = 1.6
## Fraction of speed the winner keeps after a steal (GDD example: 14 → 10.5 m/s).
@export var winner_keep: float = 0.75
## m/s the loser is shoved away. Keep below steal_min_speed so it can't chain-steal.
@export var knockback_speed: float = 4.0
## Grip while stunned (low, so the knocked-back cart slides).
@export var stun_grip: float = 1.0
## Non-steal bump: m/s each cart is pushed apart, and the fraction of speed kept.
@export var bounce_speed: float = 2.0
@export var bounce_keep: float = 0.7
## Seconds before the same pair of carts can resolve another contact.
@export var pair_cooldown: float = 0.2
## Tip-over: seconds to fall onto the side (and again to pop back up).
@export var tip_time: float = 0.15
## Inherited-item flight: seconds per cube, delay between cubes, arc height (m).
@export var flight_time: float = 0.4
@export var flight_stagger: float = 0.03
@export var flight_height: float = 1.0
```

`systems/cart/cart_steal.gd`:

```gdscript
class_name CartSteal
extends RefCounted
## Pure ram-steal rules (docs/features/cart/04-ram-steal/01-spec.md §3, GAME_SPEC.md §5).
## `speed` in each CartState must be the planar speed just before the contact.

enum Outcome { NONE, BOUNCE, A_WINS, B_WINS }


## Who inherits: the faster cart needs >= steal_min_speed and >= steal_margin more speed,
## must not be stunned, and the slower cart must not be immune and must have items.
static func outcome(t: CartTuning, a: CartState, b: CartState) -> Outcome:
	if is_equal_approx(a.speed, b.speed):
		return Outcome.BOUNCE
	var a_faster := a.speed > b.speed
	var fast := a if a_faster else b
	var slow := b if a_faster else a
	var qualifies := fast.speed >= t.steal_min_speed \
		and fast.speed - slow.speed >= t.steal_margin \
		and not fast.is_stunned \
		and not slow.is_immune \
		and slow.items.size() > 0
	if not qualifies:
		return Outcome.BOUNCE
	return Outcome.A_WINS if a_faster else Outcome.B_WINS


## The first winner_free_slots items (oldest first) transfer; the rest spill.
## Returns [transferred: Array[ItemData], spilled: Array[ItemData]].
static func split(loser_items: Array[ItemData], winner_free_slots: int) -> Array:
	var free := clampi(winner_free_slots, 0, loser_items.size())
	var transferred: Array[ItemData] = []
	transferred.assign(loser_items.slice(0, free))
	var spilled: Array[ItemData] = []
	spilled.assign(loser_items.slice(free))
	return [transferred, spilled]
```

- [ ] **Step 4: run; all passing.** **Step 5: commit** `cart: add steal rules and tuning`

### Task 2: resolving contacts

**Files:** modify `systems/cart/cart.gd`, `systems/cart/cart_motion.gd` (optional grip override); test: append to `tests/cart/test_cart_steal.gd`.
**Consumes:** Task 1, `CartInventory`, `CartItemStack`. **Produces:** in `Cart`: `_resolve_contact(other: Cart) -> void`, `_steal_from(loser: Cart) -> void`, `_knock_down(away: Vector3) -> void`, `_push(direction: Vector3) -> void`, timers `_stun_left`, `_immune_left`; `CartMotion.fade_sideways(t, sideways, dt, grip_override := -1.0)`.

- [ ] **Step 1: failing tests** (append)

```gdscript
const CART_SCENE := "res://systems/cart/cart.tscn"
var _saved_phase: GameTypes.Phase


func before_all() -> void:
	_saved_phase = RoundManager.phase


func after_each() -> void:
	RoundManager.phase = _saved_phase


func _cart_at(position: Vector3) -> Cart:
	var cart := (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(cart)
	cart.global_position = position
	return cart


func _fill(cart: Cart, values: Array) -> Array[ItemData]:
	var added: Array[ItemData] = []
	for v: int in values:
		var item := _item(v)
		assert_true(cart.try_add_item(item), "filled item $%d" % v)
		added.append(item)
	return added


func _sum(items: Array) -> int:
	var total := 0
	for item: ItemData in items:
		total += item.value
	return total


func _ids(items: Array) -> Array:
	var ids := []
	for item: ItemData in items:
		ids.append(item.item_id)
	ids.sort()
	return ids


func test_gdd_20_into_8_conserves_items_and_value() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	var rita_items := _fill(rita, [13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13])
	var you_items := _fill(you, [10, 10, 15, 15, 15, 15, 15, 15])
	rita._speed_before_move = 14.0
	you._speed_before_move = 6.0
	rita.velocity = Vector3(0.0, 0.0, -14.0)
	watch_signals(you)
	watch_signals(rita)
	rita._resolve_contact(you)
	assert_eq(rita.get_state().items.size(), 24, "winner full at 24")
	assert_eq(you.get_state().items.size(), 0, "loser empty")
	assert_signal_emit_count(you, "cart_robbed", 1, "loser emits once")
	assert_signal_not_emitted(rita, "cart_robbed")
	var params: Array = get_signal_parameters(you, "cart_robbed")
	assert_same(params[0], rita, "winner")
	assert_same(params[1], you, "loser")
	var transferred: Array = params[2]
	var spilled: Array = params[3]
	assert_eq(transferred.size(), 4)
	assert_eq(spilled.size(), 4)
	assert_eq(_sum(transferred), 50, "oldest four ($50) transfer")
	assert_eq(_sum(spilled), 60, "newest four ($60) spill")
	var before := _ids(rita_items + you_items)
	var after := _ids(rita.get_state().items + spilled)
	assert_eq(after, before, "all 28 item IDs accounted for")
	assert_eq(rita.get_state().value + _sum(spilled), 370, "$370 conserved")
	assert_signal_emitted(rita, "cart_full", "steal filled the winner")


func test_winner_keeps_75_percent_and_loser_knocked_away() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	_fill(you, [10])
	rita._speed_before_move = 14.0
	rita.velocity = Vector3(0.0, 0.0, -14.0)
	rita._resolve_contact(you)
	assert_almost_eq(rita.velocity.length(), 10.5, 0.01, "GDD: 14 → 10.5")
	assert_almost_eq(you.velocity.x, 0.0, 0.01)
	assert_almost_eq(you.velocity.z, -4.0, 0.01, "shoved 4 m/s away from the winner")


func test_repeat_contact_during_immunity_does_nothing() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	_fill(you, [10, 10])
	rita._speed_before_move = 14.0
	watch_signals(you)
	rita._resolve_contact(you)
	_fill(you, [15, 15])
	await wait_physics_frames(15)
	rita._speed_before_move = 14.0
	you._speed_before_move = 0.0
	rita._resolve_contact(you)
	assert_signal_emit_count(you, "cart_robbed", 1, "no second steal while immune")
	assert_eq(you.get_state().items.size(), 2, "the loser keeps what it picked up after")


func test_same_frame_double_detection_resolves_once() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	_fill(you, [10, 10])
	rita._speed_before_move = 14.0
	watch_signals(you)
	rita._resolve_contact(you)
	you._resolve_contact(rita)
	assert_signal_emit_count(you, "cart_robbed", 1, "pair lock: both carts detecting the same crash resolve it once")


func test_stun_and_immunity_timers() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	_fill(you, [10])
	rita._speed_before_move = 14.0
	rita._resolve_contact(you)
	assert_true(you.get_state().is_stunned)
	assert_true(you.get_state().is_immune)
	await wait_seconds(0.9)
	assert_false(you.get_state().is_stunned, "stun over after 0.7 s")
	assert_true(you.get_state().is_immune, "still immune until 1.6 s")
	await wait_seconds(0.9)
	assert_false(you.get_state().is_immune, "immunity over after 1.6 s")


func test_bounce_pushes_apart_without_items_or_signal() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var a := _cart_at(Vector3.ZERO)
	var b := _cart_at(Vector3(0.0, 0.0, -1.5))
	_fill(b, [10, 10])
	a._speed_before_move = 6.0
	b._speed_before_move = 5.0
	watch_signals(b)
	a._resolve_contact(b)
	assert_eq(b.get_state().items.size(), 2, "nothing changes hands")
	assert_signal_not_emitted(b, "cart_robbed")
	assert_almost_eq(a.velocity.z, 2.0, 0.01, "a pushed back (+Z, away from b)")
	assert_almost_eq(b.velocity.z, -2.0, 0.01, "b pushed forward (-Z, away from a)")


func test_no_steal_when_round_not_active() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	_fill(you, [10])
	RoundManager.phase = GameTypes.Phase.CLOSED
	rita._speed_before_move = 14.0
	watch_signals(you)
	rita._resolve_contact(you)
	assert_signal_not_emitted(you, "cart_robbed")
	assert_eq(you.get_state().items.size(), 1)


func test_winner_full_everything_spills() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	var full: Array = []
	full.resize(24)
	full.fill(5)
	_fill(rita, full)
	_fill(you, [10, 10, 10])
	rita._speed_before_move = 14.0
	watch_signals(you)
	rita._resolve_contact(you)
	var params: Array = get_signal_parameters(you, "cart_robbed")
	assert_eq((params[2] as Array).size(), 0, "nothing fits")
	assert_eq((params[3] as Array).size(), 3, "all three spill")
	assert_eq(you.get_state().items.size(), 0)


func test_real_ram_steals_once() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var ground := StaticBody3D.new()
	ground.position = Vector3(0.0, -0.5, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	var driver := _cart_at(Vector3.ZERO)
	var parked := _cart_at(Vector3(0.0, 0.0, -10.0))
	_fill(parked, [10, 10, 10, 10, 10, 10, 10, 10])
	watch_signals(parked)
	var cmd := DriveCommand.new()
	cmd.throttle = 1.0
	for _i: int in 120:
		driver.apply_command(cmd)
		await wait_physics_frames(1)
	assert_signal_emit_count(parked, "cart_robbed", 1, "one real ram, one steal")
	assert_eq(driver.get_state().items.size(), 8, "driver inherited the haul")
```

- [ ] **Step 2: run; expect failures (`_resolve_contact` not found).**
- [ ] **Step 3: implement.** In `cart_motion.gd`, `fade_sideways` gains `grip_override: float = -1.0` (use it when ≥ 0). In `cart.gd`:

```gdscript
# (new vars)
var _stun_left: float = 0.0
var _immune_left: float = 0.0
## Last physics frame each pair of carts resolved a contact (key "idA:idB", lower id first).
static var _pair_frames: Dictionary = {}
```

In `_physics_process`, first line: `_tick_timers(delta)`. Use `CartMotion.fade_sideways(tuning, sideways, delta, tuning.stun_grip if _is_stunned else -1.0)`. After `move_and_slide()`: `_check_cart_contacts()`. In `reset_for_round`: `_stun_left = 0.0`, `_immune_left = 0.0`. New methods:

```gdscript
func _tick_timers(delta: float) -> void:
	_stun_left = maxf(0.0, _stun_left - delta)
	_immune_left = maxf(0.0, _immune_left - delta)
	_is_stunned = _stun_left > 0.0
	_is_immune = _immune_left > 0.0


func _check_cart_contacts() -> void:
	for i: int in get_slide_collision_count():
		var other := get_slide_collision(i).get_collider() as Cart
		if other != null and other != self:
			_resolve_contact(other)


## Resolves one cart-to-cart contact, at most once per pair per pair_cooldown. Whichever cart
## detects the contact calls this (a parked cart can't detect being hit).
func _resolve_contact(other: Cart) -> void:
	if not RoundManager.is_gameplay_active():
		return
	var key := _pair_key(other)
	var frame := Engine.get_physics_frames()
	var cooldown_frames := ceili(tuning.pair_cooldown * Engine.physics_ticks_per_second)
	if _pair_frames.has(key) and frame - int(_pair_frames[key]) < cooldown_frames:
		return
	_pair_frames[key] = frame
	match CartSteal.outcome(tuning, _contact_state(), other._contact_state()):
		CartSteal.Outcome.A_WINS:
			_steal_from(other)
		CartSteal.Outcome.B_WINS:
			other._steal_from(self)
		_:
			var away := _flat_direction(global_position - other.global_position)
			_push(away)
			other._push(-away)


## This cart inherits from `loser`: both inventories update, then the loser emits cart_robbed.
func _steal_from(loser: Cart) -> void:
	var parts := CartSteal.split(loser._inventory.take_all(), _inventory.capacity - _inventory.count())
	var transferred: Array[ItemData] = parts[0]
	var spilled: Array[ItemData] = parts[1]
	for item: ItemData in transferred:
		_inventory.try_add(item)
	velocity.x *= tuning.winner_keep
	velocity.z *= tuning.winner_keep
	loser._knock_down(_flat_direction(loser.global_position - global_position))
	loser._refresh_stack()
	_refresh_stack()
	CartStealEffects.fly_items(self, loser, transferred)
	loser.cart_robbed.emit(self, loser, transferred, spilled)
	if not transferred.is_empty() and _inventory.is_full():
		cart_full.emit(self)


## Robbed: shoved away, stunned, immune, and tipped over (visual).
func _knock_down(away: Vector3) -> void:
	velocity.x = away.x * tuning.knockback_speed
	velocity.z = away.z * tuning.knockback_speed
	_stun_left = tuning.stun_time
	_immune_left = tuning.immune_time
	_is_stunned = true
	_is_immune = true
	_clear_command()
	CartStealEffects.tip_over(self)


## Non-steal bump: keep bounce_keep of the speed and add bounce_speed along `direction`.
func _push(direction: Vector3) -> void:
	velocity.x = velocity.x * tuning.bounce_keep + direction.x * tuning.bounce_speed
	velocity.z = velocity.z * tuning.bounce_keep + direction.z * tuning.bounce_speed


## Snapshot for the steal rule, using the speed from just before this contact.
func _contact_state() -> CartState:
	var state := get_state()
	state.speed = _speed_before_move
	return state


func _pair_key(other: Cart) -> String:
	var a := get_instance_id()
	var b := other.get_instance_id()
	return "%d:%d" % [mini(a, b), maxi(a, b)]


## Flattened unit direction; falls back to this cart's forward if the carts overlap exactly.
func _flat_direction(v: Vector3) -> Vector3:
	v.y = 0.0
	return v.normalized() if v.length() > 0.001 else _forward()
```

Task 2 must not reference `CartStealEffects` yet (that's Task 3): in this task, leave the two `CartStealEffects.*` lines out; Task 3 adds them.

- [ ] **Step 4: run; all passing** (including the cart/01 and cart/02 tests). **Step 5: commit** `cart: resolve ram-steal contacts exactly once`

### Task 3: tip-over and flying items

**Files:** create `systems/cart/cart_steal_effects.gd`; modify `systems/cart/cart_item_stack.gd`, `systems/cart/cart.gd`; test: append.
**Produces:** `CartStealEffects.tip_over(cart: Cart)`, `CartStealEffects.fly_items(winner: Cart, loser: Cart, items: Array[ItemData])`, `CartStealEffects.reset(cart: Cart)`; `CartItemStack.show_items(items, hidden_newest := 0)`; `Cart.item_stack_position() -> Vector3`, `Cart.hold_back_newest(count: int)`, `Cart.reveal_one_held()`.

- [ ] **Step 1: failing test** (append)

```gdscript
func test_loser_upright_after_stun_and_winner_stack_fills() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	var rita := _cart_at(Vector3.ZERO)
	var you := _cart_at(Vector3(0.0, 0.0, -1.5))
	_fill(you, [10, 10, 10, 10, 10, 10])
	rita._speed_before_move = 14.0
	rita._resolve_contact(you)
	var stack := rita.get_node("ItemStackDisplay") as CartItemStack
	assert_lt(stack.visible_count(), 6, "inherited cubes are still in flight")
	await wait_seconds(0.1)
	var visual := you.get_node("Visual") as Node3D
	assert_gt(absf(visual.rotation.z), 0.1, "the robbed cart is tipping over")
	await wait_seconds(1.2)
	assert_almost_eq(visual.rotation.z, 0.0, 0.01, "back upright after the stun")
	assert_eq(stack.visible_count(), 6, "all inherited cubes have landed")
```

- [ ] **Step 2: run; expect failure.** **Step 3: implement.** `CartItemStack.show_items(items: Array[ItemData], hidden_newest: int = 0)` shows the first `items.size() - hidden_newest` cubes. In `cart.gd`: add `var _held_back: int = 0`; `_refresh_stack()` passes `_held_back`; `reset_for_round` sets `_held_back = 0` and calls `CartStealEffects.reset(self)`; add the two `CartStealEffects` calls from Task 2; and:

```gdscript
## World position of the basket's cube stack (flight target and start).
func item_stack_position() -> Vector3:
	return _stack.global_position if _stack != null else global_position + Vector3.UP


## Hide the newest `count` cubes until they land (inherited items in flight).
func hold_back_newest(count: int) -> void:
	_held_back += count
	_refresh_stack()


## One inherited cube landed: show it.
func reveal_one_held() -> void:
	_held_back = maxi(0, _held_back - 1)
	_refresh_stack()
```

`systems/cart/cart_steal_effects.gd`:

```gdscript
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
## staggered; the winner's stack reveals one cube per landing.
static func fly_items(winner: Cart, loser: Cart, items: Array[ItemData]) -> void:
	var world := winner.get_parent()
	if items.is_empty() or world == null:
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
		world.add_child(cube)
		cube.global_position = start
		var fly := func(progress: float) -> void:
			if is_instance_valid(winner):
				cube.global_position = _arc(start, winner.item_stack_position(), t.flight_height, progress)
		var land := func() -> void:
			if is_instance_valid(winner):
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
```

- [ ] **Step 4: run; all passing.** **Step 5: commit** `cart: tip-over and flying-item steal effects`

### Task 4: test scene

**Files:** create `systems/cart/test/test_rammer_driver.gd`; modify `systems/cart/test/cart_drive_test.gd`.

- [ ] `test_rammer_driver.gd` (test-only `Node`, child of a Cart): patrols between two waypoints at 80% gas (about 12 m/s), steering toward the current waypoint (`steer = clamp(signed angle to target × 2, -1, 1)`), switching waypoints within 3 m.
- [ ] `cart_drive_test.gd`: after setting RUSH, spawn target carts (from `cart.tscn`, with profiles `carl`, `bev`, `rita`) at (−12, 0, −6) with 20 items, (−6, 0, −6) with 8 items ($10, $10, then six $15), and (8, 0, −6) empty. Spawn a rammer cart with a `TestRammerDriver` patrolling (−20, 0, −2) ↔ (20, 0, −2). Press **R** to reload the scene. The readout adds "R = reset · targets: 20 / 8 / empty · the rammer patrols in front of you".
- [ ] The scene runs headless for 120 frames with no errors; a rendered frame shows the targets. Suite green. Commit `cart: steal test scene (targets, rammer, reset)`. Rickey's hand check.

### Task 5: docs and handoffs

- [ ] D-019 in DECISIONS; GAME_SPEC §12 rows (steal numbers + effects); PROGRESS Cart section (Done, handoffs for Anthony: listen to `cart_robbed` on each cart, which is **emitted by the loser**, and spawn only `spilled` at `loser.global_position`; for John: `cart_robbed` = retarget, `get_state().is_immune` = don't ram, `is_stunned`). Suite; commit `cart: docs and handoffs for 04-ram-steal`.

## 3. Prompts

```text
Context: Cart feature 04-ram-steal. Read AGENTS.md, docs/features/cart/04-ram-steal/01-spec.md and 02-plan.md.
Task: execute Task <N> exactly: failing test first (run the suite and see it fail), then the code shown,
then the full GUT suite headless (no SCRIPT ERROR; Scripts count = number of test files). Tick Task <N> in
03-todo.md, commit with the message in the task, stop and report the test summary.
```

## 4. Improvements and bugs

1. (none yet)
