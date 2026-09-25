# 01-movement: Plan

> **For agentic workers:** execute one task at a time, test first (`AGENTS.md` Rules 4–5). Steps use checkbox (`- [ ]`) syntax; tick the matching line in [03-todo.md](03-todo.md) as you finish each task.

| | |
|---|---|
| System / Owner | Cart / Rickey |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |

**Goal:** make `Cart` drive from `DriveCommand` with the arcade handling in the spec, unblocking Rivals and Store by Thu noon.

**Architecture:** all handling numbers live in a `CartTuning` resource (`cart_tuning.tres`). All rules are static functions in `CartMotion`, which are pure math and unit-tested. `cart.gd` stores one command per frame, runs `CartMotion`, and calls `move_and_slide()`.

**Tech:** Godot 4.7.2, GDScript (static typing, tabs), `CharacterBody3D`, GUT 9.7.1.

## Global Constraints

- Signatures in `docs/CONTRACTS.md` §2 stay unchanged. `tests/shared/test_contracts.gd` must keep passing.
- Edit only `systems/cart/`, `tests/cart/`, `docs/features/cart/`, Rickey's `PROGRESS.md` sections, a `GAME_SPEC.md` §12 row append, and a `DECISIONS.md` append.
- `reverse_top_speed` must stay < 5.0 (the steal minimum).
- Forward is −Z. Steer +1 = right = clockwise from above (yaw decreases).
- Full suite command (from the repo root; on macOS `godot` = `/Applications/Godot.app/Contents/MacOS/Godot`):
  `godot --headless --path . --import` once, then `godot --headless --path . -s addons/gut/gut_cmdln.gd`
- Any `SCRIPT ERROR` or a `Scripts` count lower than the number of `test_*.gd` files = failure.

## 1. Blueprint

1. `CartTuning` + `.tres` + `CartMotion.top_speed` / `turn_rate` (math tests)
2. `CartMotion.next_forward_speed` (math tests)
3. `CartMotion.next_yaw` / `fade_sideways` (math tests)
4. `cart.gd` physics loop + `cart.tscn` tuning and nose (physics-frame tests)
5. Test scene + test-only driver and camera (loads headless; Rickey's hand checks)
6. Docs: GAME_SPEC §12 rows, D-017, PROGRESS handoffs

## 2. Tasks

### Task 1: CartTuning and top speed / turn rate

**Files:** create `systems/cart/cart_tuning.gd`, `systems/cart/cart_tuning.tres`, `systems/cart/cart_motion.gd`; test `tests/cart/test_cart_motion.gd`.

**Produces:** `CartTuning` (fields in the spec §3), `CartMotion.top_speed(t: CartTuning, item_count: int, boosting: bool) -> float`, `CartMotion.turn_rate(t: CartTuning, speed: float) -> float` (degrees/s).

- [ ] **Step 1: failing tests** (`tests/cart/test_cart_motion.gd`)

```gdscript
extends GutTest
## CartMotion math (docs/features/cart/01-movement/01-spec.md §3, §7). Pure functions: no physics.

const DT := 1.0 / 60.0
var t: CartTuning


func before_each() -> void:
	t = CartTuning.new()



func test_top_speed_formula() -> void:
	assert_almost_eq(CartMotion.top_speed(t, 0, false), 15.0, 0.001, "empty cart")
	assert_almost_eq(CartMotion.top_speed(t, 24, false), 10.68, 0.001, "full cart is ~29% slower")
	assert_almost_eq(CartMotion.top_speed(t, 0, true), 23.0, 0.001, "boost adds 8 before weight")
	assert_almost_eq(CartMotion.top_speed(t, 24, true), 16.376, 0.001, "boost with a full cart")


func test_reverse_top_speed_below_steal_minimum() -> void:
	var shipped := load("res://systems/cart/cart_tuning.tres") as CartTuning
	assert_not_null(shipped, "cart_tuning.tres loads as CartTuning")
	assert_lt(shipped.reverse_top_speed, 5.0, "reversing can never reach the 5 m/s steal minimum")


func test_turn_rate_180_stopped_90_at_top_and_above() -> void:
	assert_almost_eq(CartMotion.turn_rate(t, 0.0), 180.0, 0.001)
	assert_almost_eq(CartMotion.turn_rate(t, 7.5), 135.0, 0.001)
	assert_almost_eq(CartMotion.turn_rate(t, 15.0), 90.0, 0.001)
	assert_almost_eq(CartMotion.turn_rate(t, 23.0), 90.0, 0.001, "boosting doesn't turn slower than 90")
	assert_almost_eq(CartMotion.turn_rate(t, -4.0), 156.0, 0.001, "reverse speed uses its size")
```

- [ ] **Step 2: run the suite; expect `Parse Error: Identifier "CartTuning" not declared`.**

- [ ] **Step 3: implement** `systems/cart/cart_tuning.gd`

```gdscript
class_name CartTuning
extends Resource
## Handling numbers shared by every cart (docs/features/cart/01-movement/01-spec.md §3).
## cart_tuning.tres holds the values all four carts use. Keep GAME_SPEC.md §12 in sync.

## m/s, before weight and boost.
@export var base_top_speed: float = 15.0
## Fraction of top speed lost per carried item (0.012 = 1.2%).
@export var slowdown_per_item: float = 0.012
## m/s added to top speed while boosting (the boost meter comes in a later feature).
@export var boost_bonus: float = 8.0
## m/s² when speeding up forward.
@export var acceleration: float = 10.0
## m/s² when braking forward motion (also gas while reversing).
@export var brake_deceleration: float = 25.0
## m/s² when easing off: no input, or above the target speed.
@export var coast_deceleration: float = 4.0
## m/s. Must stay below 5.0 (the steal minimum) so reversing can never steal.
@export var reverse_top_speed: float = 4.0
## m/s² when speeding up in reverse.
@export var reverse_acceleration: float = 8.0
## m/s. Holding brake below this forward speed starts reversing.
@export var reverse_threshold: float = 0.3
## Degrees per second when stopped (the cart pivots in place).
@export var turn_rate_stopped: float = 180.0
## Degrees per second at base_top_speed and above.
@export var turn_rate_at_top: float = 90.0
## Per second. Higher means sideways slide fades faster.
@export var grip: float = 8.0
```

`systems/cart/cart_motion.gd`

```gdscript
class_name CartMotion
extends RefCounted
## Pure movement math for Cart: no nodes, no physics, so every rule is unit-testable
## (docs/features/cart/01-movement/01-spec.md §3). Speeds in m/s, times in seconds.


## (base + boost) × (1 − slowdown × items), never below 0.
static func top_speed(t: CartTuning, item_count: int, boosting: bool) -> float:
	var base := t.base_top_speed + (t.boost_bonus if boosting else 0.0)
	return maxf(0.0, base * (1.0 - t.slowdown_per_item * item_count))


## Degrees per second: turn_rate_stopped at 0 m/s, easing to turn_rate_at_top at base_top_speed and above.
static func turn_rate(t: CartTuning, speed: float) -> float:
	var weight := clampf(absf(speed) / t.base_top_speed, 0.0, 1.0)
	return lerpf(t.turn_rate_stopped, t.turn_rate_at_top, weight)
```

`systems/cart/cart_tuning.tres` is generated so Godot writes the format: a throwaway headless script (not committed) does `ResourceSaver.save(CartTuning.new(), "res://systems/cart/cart_tuning.tres")`. Run `--import` first so the class is registered.

- [ ] **Step 4: run the suite; expect all passing (17 old + 3 new).**
- [ ] **Step 5: commit** `cart: add CartTuning and top speed / turn rate math`

### Task 2: forward speed rules

**Consumes:** `CartTuning`. **Produces:** `CartMotion.next_forward_speed(t: CartTuning, speed: float, throttle: float, brake: float, top: float, dt: float) -> float`.

- [ ] **Step 1: failing tests** (append to `tests/cart/test_cart_motion.gd`)

```gdscript
## Runs next_forward_speed for `seconds` at a fixed DT and returns the final speed.
func _run(speed: float, throttle: float, brake: float, top: float, seconds: float) -> float:
	for _i: int in roundi(seconds / DT):
		speed = CartMotion.next_forward_speed(t, speed, throttle, brake, top, DT)
	return speed


func test_full_throttle_reaches_5_at_half_second_and_15_at_1_5s() -> void:
	assert_almost_eq(_run(0.0, 1.0, 0.0, 15.0, 0.5), 5.0, 0.01)
	assert_almost_eq(_run(0.0, 1.0, 0.0, 15.0, 1.5), 15.0, 0.01)
	var speed := 0.0
	for _i: int in 300:
		speed = CartMotion.next_forward_speed(t, speed, 1.0, 0.0, 15.0, DT)
		assert_true(speed <= 15.0 + 0.0001, "never exceeds top speed")
		if speed > 15.0 + 0.0001:
			break


func test_half_throttle_settles_at_half_top_speed() -> void:
	assert_almost_eq(_run(0.0, 0.5, 0.0, 15.0, 3.0), 7.5, 0.01)


func test_brake_stops_from_15_within_0_6s() -> void:
	var speed := _run(15.0, 0.0, 1.0, 15.0, 0.6)
	assert_true(speed <= 0.3 and speed >= -0.5, "stopped (about to reverse) after 0.6 s, got %s" % speed)


func test_brake_then_reverse_caps_at_4() -> void:
	assert_almost_eq(_run(0.0, 0.0, 1.0, 15.0, 2.0), -4.0, 0.01)


func test_coast_loses_4_per_second() -> void:
	assert_almost_eq(_run(15.0, 0.0, 0.0, 15.0, 1.0), 11.0, 0.01)
	assert_almost_eq(_run(-4.0, 0.0, 0.0, 15.0, 0.5), -2.0, 0.01, "coasting in reverse also eases at 4 m/s²")


func test_brake_beats_throttle() -> void:
	assert_lt(CartMotion.next_forward_speed(t, 10.0, 1.0, 1.0, 15.0, DT), 10.0)


func test_throttle_while_reversing_brakes_first() -> void:
	var speed := _run(-4.0, 1.0, 0.0, 15.0, 10.0 * DT)
	assert_almost_eq(speed, 0.0, 0.001, "25 m/s² brings -4 to 0 in 10 frames without overshooting")
	assert_almost_eq(_run(speed, 1.0, 0.0, 15.0, 0.5), 5.0, 0.01, "then accelerates forward at 10 m/s²")


func test_overspeed_eases_down_to_top() -> void:
	assert_almost_eq(_run(15.0, 1.0, 0.0, 10.68, 0.5), 13.0, 0.01, "eases at 4 m/s², no snap")
	assert_almost_eq(_run(15.0, 1.0, 0.0, 10.68, 5.0), 10.68, 0.01)
```

- [ ] **Step 2: run; expect failures (`next_forward_speed` not found).**
- [ ] **Step 3: implement** (append to `cart_motion.gd`)

```gdscript
## New signed forward speed (+ forward, − reverse) after one step of dt seconds.
## Brake beats gas. Braking below reverse_threshold reverses. Gas while reversing brakes first.
## Analog gas sets the target (half gas = half top speed).
static func next_forward_speed(t: CartTuning, speed: float, throttle: float, brake: float, top: float, dt: float) -> float:
	if brake > 0.0:
		if speed > t.reverse_threshold:
			return move_toward(speed, 0.0, t.brake_deceleration * brake * dt)
		var reverse_target := -t.reverse_top_speed * brake
		if speed > reverse_target:
			return move_toward(speed, reverse_target, t.reverse_acceleration * dt)
		return move_toward(speed, reverse_target, t.coast_deceleration * dt)
	if throttle > 0.0 and speed < 0.0:
		return move_toward(speed, 0.0, t.brake_deceleration * throttle * dt)
	var target := top * throttle
	if speed >= 0.0 and speed < target:
		return move_toward(speed, target, t.acceleration * dt)
	return move_toward(speed, target, t.coast_deceleration * dt)
```

- [ ] **Step 4: run; all passing.**
- [ ] **Step 5: commit** `cart: add forward speed rules`

### Task 3: steering and grip

**Produces:** `CartMotion.next_yaw(t: CartTuning, yaw: float, steer: float, speed: float, dt: float) -> float` (radians), `CartMotion.fade_sideways(t: CartTuning, sideways: Vector3, dt: float) -> Vector3`.

- [ ] **Step 1: failing tests** (append)

```gdscript
func test_steer_right_is_clockwise_forward_and_reverse() -> void:
	var step := deg_to_rad(180.0) * DT
	assert_almost_eq(CartMotion.next_yaw(t, 0.0, 1.0, 0.0, DT), -step, 0.00001, "right lowers yaw (clockwise)")
	assert_lt(CartMotion.next_yaw(t, 0.0, 1.0, -4.0, DT), 0.0, "still clockwise while reversing")
	assert_gt(CartMotion.next_yaw(t, 0.0, -1.0, 10.0, DT), 0.0, "left raises yaw")
	assert_eq(CartMotion.next_yaw(t, 1.0, 0.0, 10.0, DT), 1.0, "no steer, no turn")


func test_sideways_fades_with_grip() -> void:
	var faded := CartMotion.fade_sideways(t, Vector3(1.0, 0.0, 0.0), 0.125)
	assert_almost_eq(faded.x, exp(-1.0), 0.0001, "grip 8/s: ~37% left after 0.125 s")
```

- [ ] **Step 2: run; expect failures.**
- [ ] **Step 3: implement** (append)

```gdscript
## New yaw in radians after steering for dt. steer +1 = right = clockwise from above.
## Godot's +yaw is counterclockwise, so right steering lowers yaw, forward or reverse.
static func next_yaw(t: CartTuning, yaw: float, steer: float, speed: float, dt: float) -> float:
	return yaw - steer * deg_to_rad(turn_rate(t, speed)) * dt


## Sideways velocity after grip fades it for dt seconds (the slide after a turn).
static func fade_sideways(t: CartTuning, sideways: Vector3, dt: float) -> Vector3:
	return sideways * exp(-t.grip * dt)
```

- [ ] **Step 4: run; all passing.**
- [ ] **Step 5: commit** `cart: add steering and grip math`

### Task 4: Cart physics loop

**Files:** modify `systems/cart/cart.gd`, `systems/cart/cart.tscn`; test `tests/cart/test_cart_movement.gd`.
**Consumes:** Tasks 1–3, `RoundManager.is_gameplay_active()`. **Produces:** a working `apply_command` with the spec §2 behavior; `@export var tuning: CartTuning`; internal `_speed_before_move: float` for `cart/03`.

- [ ] **Step 1: failing tests** (`tests/cart/test_cart_movement.gd`)

```gdscript
extends GutTest
## Cart movement with real physics frames (docs/features/cart/01-movement/01-spec.md §7).
## Each test builds its own floor; RoundManager.phase is restored afterward.

const CART_SCENE := "res://systems/cart/cart.tscn"


## Test-only driver: sends `cmd` to the cart every physics frame while enabled.
## (Named without the "Test" prefix so GUT doesn't treat it as a test class.)
class ScriptedDriver:
	extends Node

	var cart: Cart
	var cmd := DriveCommand.new()
	var enabled := true

	func _physics_process(_delta: float) -> void:
		if enabled and cart != null:
			cart.apply_command(cmd)


var _saved_phase: GameTypes.Phase
var _cart: Cart
var _driver: ScriptedDriver


func before_each() -> void:
	_saved_phase = RoundManager.phase
	RoundManager.phase = GameTypes.Phase.RUSH
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(200.0, 1.0, 200.0))
	_cart = (load(CART_SCENE) as PackedScene).instantiate() as Cart
	add_child_autofree(_cart)
	_driver = ScriptedDriver.new()
	_driver.cart = _cart
	add_child_autofree(_driver)


func after_each() -> void:
	RoundManager.phase = _saved_phase


## A static box on layer 1 (world), like the store's floor and walls.
func _add_box(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = center
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)


func _speed() -> float:
	return _cart.get_state().speed


func test_full_throttle_drives_forward_to_top_speed() -> void:
	_driver.cmd.throttle = 1.0
	await wait_physics_frames(95)
	assert_almost_eq(_speed(), 15.0, 0.5, "reaches ~15 m/s after ~1.5 s")
	assert_lt(_cart.position.z, -5.0, "drove toward -Z, the cart's front")


func test_ignores_input_when_round_not_active() -> void:
	RoundManager.phase = GameTypes.Phase.IDLE
	_driver.cmd.throttle = 1.0
	await wait_physics_frames(30)
	assert_almost_eq(_speed(), 0.0, 0.01, "no driving outside RUSH / FINAL_CALL")


func test_coasts_when_commands_stop() -> void:
	_driver.cmd.throttle = 1.0
	await wait_physics_frames(60)
	var before := _speed()
	_driver.enabled = false
	await wait_physics_frames(30)
	assert_almost_eq(_speed(), before - 2.0, 0.5, "no commands = neutral: coasts at ~4 m/s²")


func test_wall_stops_cart_without_stored_speed() -> void:
	_add_box(Vector3(0.0, 1.0, -6.0), Vector3(10.0, 2.0, 1.0))
	_driver.cmd.throttle = 1.0
	await wait_physics_frames(90)
	assert_lt(_speed(), 0.5, "head-on into the wall stops the cart")
	var pinned_z := _cart.position.z
	_driver.cmd.throttle = 0.0
	_driver.cmd.brake = 1.0
	await wait_physics_frames(30)
	assert_gt(_cart.position.z, pinned_z + 0.5, "brake reverses away from the wall right away")
```

- [ ] **Step 2: run; expect the throttle, coast and wall tests to fail (the stub doesn't move).**
- [ ] **Step 3: implement.** In `cart.gd`, add the tuning export, the command fields and the physics loop, and replace the `apply_command` and `reset_for_round` bodies:

```gdscript
const DEFAULT_TUNING := preload("res://systems/cart/cart_tuning.tres")

## Shared handling numbers. Empty falls back to cart_tuning.tres.
@export var tuning: CartTuning

# Latest command, copied in apply_command and consumed by the next physics step.
var _throttle: float = 0.0
var _brake: float = 0.0
var _steer: float = 0.0
var _boost: bool = false
## Planar speed just before the last move_and_slide(); cart/03 compares these at contact.
var _speed_before_move: float = 0.0


func _ready() -> void:
	if tuning == null:
		tuning = DEFAULT_TUNING as CartTuning


## Called by the driver every physics frame. Values are copied; the command object isn't kept.
## A frame with no call counts as neutral.
func apply_command(cmd: DriveCommand) -> void:
	_throttle = clampf(cmd.throttle, 0.0, 1.0)
	_brake = clampf(cmd.brake, 0.0, 1.0)
	_steer = clampf(cmd.steer, -1.0, 1.0)
	_boost = cmd.boost


func _physics_process(delta: float) -> void:
	var active := RoundManager.is_gameplay_active() and not _is_stunned
	var throttle := _throttle if active else 0.0
	var brake := _brake if active else 0.0
	var steer := _steer if active else 0.0
	_clear_command()

	var planar := Vector3(velocity.x, 0.0, velocity.z)
	rotation.y = CartMotion.next_yaw(tuning, rotation.y, steer, planar.length(), delta)
	var forward := _forward()
	var speed := planar.dot(forward)
	var sideways := planar - forward * speed
	var top := CartMotion.top_speed(tuning, _items.size(), false)
	speed = CartMotion.next_forward_speed(tuning, speed, throttle, brake, top, delta)
	sideways = CartMotion.fade_sideways(tuning, sideways, delta)
	planar = forward * speed + sideways
	velocity.x = planar.x
	velocity.z = planar.z
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	_speed_before_move = planar.length()
	move_and_slide()


## The cart's front on the floor plane (Godot's forward is -Z).
func _forward() -> Vector3:
	var forward := -global_basis.z
	forward.y = 0.0
	return forward.normalized()


func _clear_command() -> void:
	_throttle = 0.0
	_brake = 0.0
	_steer = 0.0
	_boost = false
```

`reset_for_round` also calls `_clear_command()` and sets `_speed_before_move = 0.0`. In `cart.tscn`, add the tuning resource and the nose:

```
[ext_resource type="Resource" path="res://systems/cart/cart_tuning.tres" id="2_tuning"]
[sub_resource type="BoxMesh" id="BoxMesh_nose"]
size = Vector3(0.4, 0.2, 0.2)
# on the Cart root node:
tuning = ExtResource("2_tuning")
[node name="Nose" type="MeshInstance3D" parent="Visual"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.8, -0.6)
mesh = SubResource("BoxMesh_nose")
```

- [ ] **Step 4: run; all passing (including `test_contracts.gd`). Check the output for GDScript warnings too.**
- [ ] **Step 5: commit** `cart: drive from DriveCommand with arcade handling`

### Task 5: test scene

**Files:** create `systems/cart/test/cart_drive_test.tscn`, `cart_drive_test.gd`, `debug_keyboard_driver.gd`, `debug_follow_camera.gd`.

- [ ] **Step 1:** `debug_keyboard_driver.gd`

```gdscript
extends Node
## TEST-ONLY driver for systems/cart/test/. Replaced by the real PlayerController in player/01.
## Reads the input actions into a DriveCommand and sends it to the cart every physics frame.

@export var cart: Cart

var _cmd := DriveCommand.new()


func _physics_process(_delta: float) -> void:
	if cart == null:
		return
	_cmd.throttle = Input.get_action_strength("drive_gas")
	_cmd.brake = Input.get_action_strength("drive_brake")
	_cmd.steer = Input.get_axis("steer_left", "steer_right")
	_cmd.boost = Input.is_action_pressed("boost")
	cart.apply_command(_cmd)
```

- [ ] **Step 2:** `debug_follow_camera.gd`

```gdscript
extends Camera3D
## TEST-ONLY follow camera for systems/cart/test/. The real chase camera comes in player/01.

@export var target: Node3D
@export var distance: float = 8.5
@export var height: float = 5.5
@export var smoothing: float = 6.0


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var behind := target.global_basis.z # +Z is behind the cart (its front is -Z)
	behind.y = 0.0
	var wanted := target.global_position + behind.normalized() * distance + Vector3.UP * height
	global_position = global_position.lerp(wanted, 1.0 - exp(-smoothing * delta))
	look_at(target.global_position + Vector3.UP)
```

- [ ] **Step 3:** `cart_drive_test.gd` (builds the arena in code) and `cart_drive_test.tscn` (root `Node3D` with this script, a `Cart` instance, a `DebugKeyboardDriver` node, and a `DebugFollowCamera` `Camera3D` at (0, 5.5, 8.5), FOV 62, current)

```gdscript
extends Node3D
## TEST-ONLY scene for cart/01-movement hand checks. Builds a floor, walls and pillars,
## unlocks driving by setting the round phase to RUSH (allowed in test code only),
## and shows a live speed readout.

@onready var _cart: Cart = $Cart
@onready var _driver: Node = $DebugKeyboardDriver
@onready var _camera: Camera3D = $DebugFollowCamera

var _readout: Label


func _ready() -> void:
	RoundManager.phase = GameTypes.Phase.RUSH
	_driver.set("cart", _cart)
	_camera.set("target", _cart)
	_build_arena()
	_build_readout()


func _build_arena() -> void:
	var floor_color := Color("#BDEBD3")
	var wall_color := Color("#FFF6E0")
	var pillar_color := Color("#8E24AA")
	_add_box(Vector3(0.0, -0.5, 0.0), Vector3(60.0, 1.0, 60.0), floor_color)
	_add_box(Vector3(0.0, 1.0, -30.5), Vector3(62.0, 2.0, 1.0), wall_color)
	_add_box(Vector3(0.0, 1.0, 30.5), Vector3(62.0, 2.0, 1.0), wall_color)
	_add_box(Vector3(-30.5, 1.0, 0.0), Vector3(1.0, 2.0, 62.0), wall_color)
	_add_box(Vector3(30.5, 1.0, 0.0), Vector3(1.0, 2.0, 62.0), wall_color)
	# A 3.5 m-wide "aisle" between two shelves, plus pillars to weave around.
	_add_box(Vector3(-2.25, 1.0, -15.0), Vector3(1.0, 2.0, 12.0), wall_color)
	_add_box(Vector3(2.25, 1.0, -15.0), Vector3(1.0, 2.0, 12.0), wall_color)
	for x: float in [-12.0, -6.0, 6.0, 12.0]:
		_add_box(Vector3(x, 1.0, 8.0), Vector3(1.0, 2.0, 1.0), pillar_color)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	add_child(sun)


## A static box on layer 1 (world) with a flat-colored mesh.
func _add_box(center: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = center
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	box_mesh.material = material
	mesh.mesh = box_mesh
	body.add_child(mesh)
	add_child(body)


func _build_readout() -> void:
	var layer := CanvasLayer.new()
	_readout = Label.new()
	_readout.position = Vector2(16.0, 16.0)
	layer.add_child(_readout)
	add_child(layer)


func _process(_delta: float) -> void:
	var planar := Vector3(_cart.velocity.x, 0.0, _cart.velocity.z)
	var forward := -_cart.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var forward_speed := planar.dot(forward)
	var sideways_speed := (planar - forward * forward_speed).length()
	var top := CartMotion.top_speed(_cart.tuning, 0, false)
	_readout.text = "speed %.1f m/s   forward %.1f   sideways %.1f   top %.1f\nW/Up gas · S/Down brake (hold when stopped to reverse) · A/D steer" % [
		_cart.get_state().speed, forward_speed, sideways_speed, top]
```

- [ ] **Step 4: verify it loads and runs headless without errors:** `godot --headless --path . --quit-after 120 res://systems/cart/test/cart_drive_test.tscn`. Then run the full suite.
- [ ] **Step 5: commit** `cart: add drive test scene`, then ask Rickey to do the hand checks (spec §7) with F6.

### Task 6: docs and handoffs

- [ ] **Step 1:** append the new `CartTuning` rows to `GAME_SPEC.md` §12 (owner Rickey, source "cart/01-movement").
- [ ] **Step 2:** append **D-017** to `DECISIONS.md`: reverse is capped at 4 m/s (can't steal in reverse); Cart forces neutral outside RUSH/FINAL_CALL; commands last one frame.
- [ ] **Step 3:** update Rickey's Cart section of `PROGRESS.md`: Done, Next (`cart/02-inventory`), **Handoff notes** for John and Anthony, **Needs from others** (Anthony: aisles ≥ 3.5 m, floor on layer 1; Evan: cart model within 0.8 × 1.0 × 1.2 m, front −Z, origin at floor center).
- [ ] **Step 4:** full suite; commit `cart: docs and handoffs for 01-movement`. Then, with Rickey's OK, push and open the PR (reviewer: Anthony).

## 3. Prompts

Each task above is one prompt. Paste into any agent:

```text
Context: Cart feature 01-movement. Read AGENTS.md, docs/features/cart/01-movement/01-spec.md and 02-plan.md.
Task: execute Task <N> from 02-plan.md exactly: failing test first (run the suite and see it fail), then the
code shown, then the full GUT suite headless (no SCRIPT ERROR; Scripts count = number of test files).
Tick Task <N> in 03-todo.md, commit with the message in the task, stop and report the test summary.
```

## 4. Improvements and bugs

1. Fixed during Task 1: the `_run` helper was in Task 1's test block but calls Task 2's `next_forward_speed`, so the whole test file failed to parse and GUT skipped it. Moved to Task 2.
