# 01-movement: Spec

| | |
|---|---|
| System / Owner | Cart / Rickey |
| Branch | `cart/01-movement` |
| Status | Draft, awaiting Rickey's approval |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Demo (merge by Thu 09-24 noon) |

## 1. Overview

The cart turns each frame's `DriveCommand` into arcade movement: gas, brake and reverse, pivot steering, and a slight slide in sharp turns, capped by the GDD's top-speed formula. Every handling number lives in one `CartTuning` resource. The rules live in a pure-math `CartMotion` helper so they can be tested without physics. This unblocks Rivals and Store today, and gives `player/01` a cart to control.

## 2. Player-facing behavior

- **Gas** accelerates forward: 5 m/s after 0.5 s, 15 m/s after about 1.5 s. Half gas settles at half top speed.
- **Letting go** coasts down at 4 m/s².
- **Brake** stops you from 15 m/s in about 0.6 s. Keep holding it below 0.3 m/s and you reverse, up to 4 m/s.
- **Gas while reversing** brakes first, then drives forward. Brake and gas together = brake.
- **Steer** turns the cart: 180°/s when stopped (it pivots in place), easing to 90°/s at 15 m/s. Right is always clockwise, including in reverse.
- **Sharp turns at speed** have a small slide that fades quickly (grip).
- **Walls and shelves:** you slide along them. Head-on, you stop.
- **Round locked** (countdown, closed, results, idle): the cart ignores input and coasts to a stop.

## 3. Rules and numbers

`CartTuning` defaults (`systems/cart/cart_tuning.tres`), added to `GAME_SPEC.md` §12:

| Constant | Value | Source |
|---|---|---|
| `base_top_speed` | 15.0 m/s | GAME_SPEC §12 |
| `slowdown_per_item` | 0.012 | GAME_SPEC §12 |
| `boost_bonus` | 8.0 m/s (formula only; boost off in this feature) | GAME_SPEC §12 |
| `acceleration` | 10.0 m/s² | Brainstorm Q4 |
| `brake_deceleration` | 25.0 m/s² | Brainstorm Q4 |
| `coast_deceleration` | 4.0 m/s² | Brainstorm Q4 |
| `reverse_top_speed` | 4.0 m/s (must stay < 5.0, the steal minimum) | Brainstorm Q5 |
| `reverse_acceleration` | 8.0 m/s² | Brainstorm Q5 |
| `reverse_threshold` | 0.3 m/s | Brainstorm Q5 |
| `turn_rate_stopped` | 180 °/s | Brainstorm Q3 |
| `turn_rate_at_top` | 90 °/s | Brainstorm Q3 |
| `grip` | 8.0 per second | Brainstorm Q2 |

**Formulas** (`CartMotion`, all static):

- `top_speed(t, item_count, boosting) = (t.base_top_speed + (t.boost_bonus if boosting else 0)) × (1 − t.slowdown_per_item × item_count)`
- `turn_rate(t, speed) = lerp(turn_rate_stopped, turn_rate_at_top, clamp(|speed| / base_top_speed, 0, 1))` (degrees/s; converted to radians when applied)
- `next_forward_speed(t, s, throttle, brake, top, dt)`, where `s` is signed (+ forward):
  1. `brake > 0` and `s > reverse_threshold` → `move_toward(s, 0, brake_deceleration × brake × dt)`
  2. `brake > 0` otherwise → target `−reverse_top_speed × brake`; if `s > target`, `move_toward(s, target, reverse_acceleration × dt)`, else `move_toward(s, target, coast_deceleration × dt)`
  3. `throttle > 0` and `s < 0` → `move_toward(s, 0, brake_deceleration × throttle × dt)`
  4. otherwise → target `top × throttle`; if `0 ≤ s < target`, `move_toward(s, target, acceleration × dt)`, else `move_toward(s, target, coast_deceleration × dt)` (this also covers coasting down from reverse at 4 m/s² when nothing is pressed)
- `next_yaw(t, yaw, steer, speed, dt) = yaw − steer × deg_to_rad(turn_rate(t, speed)) × dt` (Godot's +yaw is counterclockwise seen from above, so steer +1 decreases yaw = clockwise)
- `fade_sideways(t, sideways, dt) = sideways × exp(−grip × dt)`

**Per physics frame** (`Cart._physics_process`):

1. Command = stored command, or neutral (all zero) if `not RoundManager.is_gameplay_active()` or `_is_stunned`.
2. `rotation.y = next_yaw(...)` using the current planar speed.
3. `forward = −global_basis.z` (flattened); split planar velocity into `s = v · forward` and `sideways = v − forward × s`.
4. `s = next_forward_speed(...)` with `top = top_speed(t, _items.size(), false)`.
5. `sideways = fade_sideways(...)`; planar velocity = `forward × s + sideways`; add gravity to `velocity.y` when not on the floor.
6. `_speed_before_move = planar speed`; `move_and_slide()`.
7. Velocity is now the real post-collision velocity (read again next frame); clear the stored command.

`apply_command(cmd)` copies `throttle`, `brake`, `steer`, `boost` into private fields (clamped to their ranges) and keeps no reference.

## 4. Interfaces

**Uses:**
- `CONTRACTS.md` §1.2 `DriveCommand` (read and copied per frame)
- `CONTRACTS.md` §3 `RoundManager.is_gameplay_active()`

**Provides / emits:**
- `Cart.apply_command()` now drives the cart, with the semantics in §2–§3 (signature unchanged)
- `Cart.get_state().speed` = real horizontal speed
- `Cart.reset_for_round()` also zeroes velocity and clears the stored command
- Internal for `cart/03`: `_speed_before_move` (not public API)

**Contract changes:** none.

## 5. Scenes and files

| Path | New / changed | Purpose |
|---|---|---|
| `systems/cart/cart_tuning.gd` | New | `class_name CartTuning extends Resource`, exported numbers from §3 |
| `systems/cart/cart_tuning.tres` | New | Default values |
| `systems/cart/cart_motion.gd` | New | `class_name CartMotion extends RefCounted`, static math from §3 |
| `systems/cart/cart.gd` | Changed | `@export var tuning: CartTuning`, command storage, physics loop |
| `systems/cart/cart.tscn` | Changed | `tuning = cart_tuning.tres`; `Nose` mesh on the placeholder (front, −Z) |
| `systems/cart/test/cart_drive_test.tscn` + `.gd` | New | Floor, walls, pillars, light, cart, readout; sets phase to RUSH on ready |
| `systems/cart/test/debug_keyboard_driver.gd` | New | Test-only: input actions → `DriveCommand` → `apply_command` |
| `systems/cart/test/debug_follow_camera.gd` | New | Test-only: simple camera behind the cart |
| `tests/cart/test_cart_motion.gd` | New | Math tests |
| `tests/cart/test_cart_movement.gd` | New | Physics-frame tests |
| `docs/GAME_SPEC.md` §12, `docs/DECISIONS.md`, `docs/PROGRESS.md` (Cart section) | Changed | Tuning rows, D-017, handoffs |

`cart.tscn` after this feature:
```
Cart (CharacterBody3D, cart.gd, tuning = cart_tuning.tres, layer 2, mask 1+2+4)
├── CollisionShape3D (Box 0.8 × 1.0 × 1.2, y = 0.5)
└── Visual (Node3D)                 ← Evan's cart_visual.tscn replaces the contents later
    ├── PlaceholderMesh (Box 0.8 × 1.0 × 1.2, y = 0.5)
    └── Nose (Box 0.4 × 0.2 × 0.2, at front: y = 0.8, z = −0.6)
```

## 6. Edge cases

| Case | Expected behavior |
|---|---|
| No `apply_command` this frame | Neutral: coast to a stop |
| Round not active (IDLE, COUNTDOWN, CLOSED, RESULTS, MATCH_OVER) | Input ignored; coast to a stop |
| Brake + gas together | Brake wins |
| Gas while reversing | Brakes to 0 at 25 m/s², then accelerates forward |
| Top speed drops below current speed (items added later) | Eases down at 4 m/s², no snap |
| Head-on wall at speed | Forward speed ~0 after contact; no stored-up speed; reverse works next frame |
| Steer while stopped | Pivots at 180 °/s |
| Command values out of range (e.g. throttle 2.0) | Clamped to the `DriveCommand` ranges |
| `tuning` left empty on an instance | Falls back to `cart_tuning.tres` |
| Off the floor | Gravity pulls it down; no steering change |

## 7. Test plan

**GUT, `tests/cart/test_cart_motion.gd`** (pure math, fixed dt = 1/60):
- [ ] `test_top_speed_formula`: 15.0 (0 items), 10.68 (24), 23.0 (boost, 0), 16.376 (boost, 24)
- [ ] `test_full_throttle_reaches_5_at_half_second_and_15_at_1_5s`, never exceeding top
- [ ] `test_half_throttle_settles_at_half_top_speed`
- [ ] `test_brake_stops_from_15_within_0_6s`
- [ ] `test_brake_then_reverse_caps_at_4`
- [ ] `test_reverse_top_speed_below_steal_minimum` (tuning default < 5.0)
- [ ] `test_coast_loses_4_per_second`
- [ ] `test_brake_beats_throttle`
- [ ] `test_throttle_while_reversing_brakes_first`
- [ ] `test_overspeed_eases_down_to_top`
- [ ] `test_turn_rate_180_stopped_90_at_top_and_above`
- [ ] `test_steer_right_is_clockwise_forward_and_reverse` (yaw decreases)
- [ ] `test_sideways_fades_with_grip` (≈ 0.368 after 0.125 s)

**GUT, `tests/cart/test_cart_movement.gd`** (real physics frames; floor + wall built in the test; restores `RoundManager.phase` after each test):
- [ ] `test_full_throttle_drives_forward_to_top_speed`: phase RUSH, 90 frames → speed 15 ± 0.5, position moved toward −Z
- [ ] `test_ignores_input_when_round_not_active`: phase IDLE → speed stays ~0
- [ ] `test_coasts_when_commands_stop`
- [ ] `test_wall_stops_cart_without_stored_speed`: head-on into a wall → speed ~0; brake immediately reverses

**Test scene hand checks** (`systems/cart/test/cart_drive_test.tscn`, press F6):
- [ ] Gas feels arcade-y: quick to 5 m/s, about 1.5 s to 15 m/s (see readout)
- [ ] Pivot in place when stopped; wide turns at top speed with a small slide
- [ ] Brake stops fast; holding it reverses, and reverse never shows more than 4 m/s
- [ ] Sliding along walls and pillars; head-on stops you
- [ ] Nose shows the front

## 8. Out of scope

Inventory and item cap (`cart/02`), steal, knockback, stun and immunity (`cart/03`), boost meter, wet-floor slip, `PlayerController` / chase camera (`player/01`), Evan's model.

## 9. Done when

- [ ] All §7 GUT tests pass, along with the existing 17. Full suite headless, no `SCRIPT ERROR`, `Scripts` count = number of test files
- [ ] Rickey confirms the test-scene hand checks
- [ ] `GAME_SPEC.md` §12 rows added, D-017 logged, Cart handoff notes + requests to Anthony and Evan written in `PROGRESS.md`
- [ ] PR opened (reviewer: Anthony, per `TEAM.md`)
