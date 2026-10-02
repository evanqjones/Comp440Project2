# 03-hazard_detection: Spec

| | |
|---|---|
| System / Owner | Rivals / John |
| Branch | `rivals/03-hazard_detection` |
| Status | Draft |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Final |

## 1. Overview

This feature integrates dynamic stage hazard detection and path avoidance into the rival bot AI (`BotController`). When stage hazards (slippery puddles and falling pallets) spawn during active gameplay, bots track their positions, immediately evaluate whether their active navigation path is compromised, and reroute to safe alternative pickups or rival targets. If a critical path (such as checkout) is obstructed, bots maintain a safe standoff distance until the hazard clears, while desperate bots in the final seconds of a round will risk running through to bank.

## 2. Player-facing behavior

1. **Intelligent Hazard Avoidance:** When a puddle or falling pallet warning shadow appears in an aisle, human players will observe rival bots deliberately choosing other aisles or navigating around the hazard radius instead of mindlessly driving into it.
2. **Immediate Rerouting Reactions:** If a hazard drops directly in front of an approaching bot or across its line of travel, the bot does not continue forward into the danger; it promptly brakes or swerves toward a different safe item.
3. **Checkout Standoff and Desperation Rush:** If a puddle or falling pallet blocks the approach to the checkout lane, banking bots will halt at a safe distance (~3.0 m away) rather than throwing away their haul. However, if the round timer ticks down into `FINAL_CALL` ($\le 5.0\text{ s}$ remaining), banking bots will make a last-ditch charge across the hazard to attempt banking before the doors close.
4. **Realistic Spin Behavior:** If a bot is caught in a puddle (e.g. pushed from behind or boxed in), it stops sending active steering/throttle inputs during the 3.0 s spin-out, allowing the slip spin physics to resolve cleanly without jittering into walls.

## 3. Rules and numbers

### Constants and Parameters

| Rule / Constant | Value | Source |
|---|---|---|
| Hazard Danger Radius ($R_{\text{hazard}}$) | $2.5\text{ m}$ (horizontal XZ) | `GAME_SPEC.md` §7, `00-brainstorm.md` Q2 |
| Hazard Radius Override | `hazard.danger_radius` if property present on hazard node | `00-brainstorm.md` Q2 |
| Checkout Standoff Distance | $3.0\text{ m}$ from nearest hazard boundary | `00-brainstorm.md` Q4 |
| Checkout Desperation Threshold | $\le 5.0\text{ s}$ remaining in round | `00-brainstorm.md` Q4 |
| Slip Spin Duration | $3.0\text{ s}$ | `GAME_SPEC.md` §7, `cart.gd` |
| Decision Interval | $0.3\text{ s}$ | `GAME_SPEC.md` §4.3 |
| Unstick Velocity Threshold | $< 0.5\text{ m/s}$ for $\ge 1.0\text{ s}$ | `GAME_SPEC.md` §4.3 |

### Algorithms & Decision Logic

#### 1. Horizontal Point-to-Segment Distance Calculation
For each active hazard with center position $H = (h_x, h_z)$ and each navigation path line segment between waypoint $A = (a_x, a_z)$ and waypoint $B = (b_x, b_z)$:
$$AB = B - A$$
$$t = \text{clamp}\left(\frac{(H - A) \cdot AB}{|AB|^2}, 0.0, 1.0\right)$$
$$\text{Closest Point } P = A + t \times AB$$
$$\text{Distance } d = |H - P|$$
If $d < R_{\text{hazard}}$, the path segment is flagged as **intersecting the hazard**.

#### 2. Candidate Filtering (`_evaluate_decisions`)
- During target utility evaluation for pickups (`COLLECTING`) and rivals (`CHASING`):
  - Disqualify any candidate whose horizontal distance to any active hazard is $< R_{\text{hazard}}$.
  - If candidate position is safe, inspect navigation path from `cart.global_position` to candidate: if any path segment comes within $R_{\text{hazard}}$ of any active hazard, disqualify the candidate.
  - Select the highest utility candidate among all remaining safe targets.

#### 3. Immediate Reroute Reaction (`RoundManager.hazard_spawned`)
- When `RoundManager.hazard_spawned(hazard: Node3D)` emits:
  - Register `hazard` into `active_hazards` and connect its `tree_exited` signal to auto-cleanup.
  - If the bot has an `active_target` or `target_position != Vector3.ZERO`:
    - Compute if the new hazard intersects the current navigation path or is within $R_{\text{hazard}}$ of `target_position`.
    - If compromised: immediately clear `active_target`, invoke `_evaluate_decisions()`, and restart `decision_timer`.

#### 4. Banking Standoff Logic
- When `state == AIState.BANKING`:
  - If `RoundManager.time_left <= 5.0`: ignore hazard blockers and drive directly to checkout (`target_position = RoundManager.get_checkout_position()`).
  - Otherwise, if the path to checkout intersects an active hazard:
    - Set `target_position` to a standoff coordinate located along the path at distance $3.0\text{ m}$ upstream of the hazard intersection.
    - If already within standoff distance or blocked: set throttle to $0.0$, waiting for hazard despawn.

#### 5. Active Slip Command Neutralization
- If the cart is currently slipping (checked via `cart.get("_slip_left") > 0.0` or `cart.is_slipping()`):
  - Command outputs are neutralized: `throttle = 0.0`, `brake = 0.0`, `steer = 0.0`, `boost = false`.

## 4. Interfaces

**Uses** (from other systems; see [docs/CONTRACTS.md](../../CONTRACTS.md)):
- `CONTRACTS.md` §3: `RoundManager.hazard_spawned(hazard: Node3D)`: Connected in `_ready()` to detect new hazards.
- `CONTRACTS.md` §3: `RoundManager.is_gameplay_active() -> bool`: Verifies whether hazards should be evaluated and commands generated.
- `CONTRACTS.md` §3: `RoundManager.time_left: float`: Checked for the $\le 5.0\text{ s}$ final-call checkout desperation rush.
- `CONTRACTS.md` §3: `RoundManager.get_checkout_position() -> Vector3`: Base destination for banking.
- `CONTRACTS.md` §3: `RoundManager.get_pickups() -> Array[Pickup]`: Candidate pickups for collection.
- `CONTRACTS.md` §3: `RoundManager.get_carts() -> Array[Cart]`: Candidate targets for chasing.
- `CONTRACTS.md` §2: `Cart.get_state() -> CartState`: Inspects current cart inventory and speed.
- `CONTRACTS.md` §2: `Cart.apply_command(cmd: DriveCommand)`: Sends navigation drive commands to the cart.

**Provides / Emits:**
- Public test hooks on `BotController`:
  - `var test_hazards_override: Array[Node3D] = []`: Injects mock hazard nodes for headless tests.
  - `var test_nav_path_override: PackedVector3Array = []`: Injects mock path waypoints for headless tests.
  - `func is_path_safe_from_hazards(path: PackedVector3Array) -> bool`: Helper evaluating path safety against active hazards.

**Contract changes:**
- None. This feature strictly consumes existing contract signals and properties.

## 5. Scenes and files

| Path | New / Changed | Purpose |
|---|---|---|
| `systems/rivals/bot_controller.gd` | Changed | Adds hazard list tracking, line-segment collision checks, target filtering, banking standoff, and slip neutralization. |
| `tests/rivals/test_bot_hazard_detection.gd` | New | Comprehensive headless GUT unit tests verifying all hazard detection rules and edge cases. |
| `systems/rivals/test/rivals_test.tscn` | Changed | Interactive test scene providing placed hazards to visually observe bot rerouting and standoff behavior. |

## 6. Edge cases

| Case | Expected Behavior |
|---|---|
| Hazard spawns directly under or ahead of moving bot ($< 2.5\text{ m}$) | Immediate path invalidation; bot brakes/reroutes to an alternate target. If already in radius, bot drives outward to clear the area. |
| All available pickups in the store are within hazard danger zones | Bot targets `Vector3.ZERO`, cuts throttle to $0.0$, and waits safely for either a new item spawn or hazard expiration. |
| Hazard blocks checkout path with $> 5\text{ s}$ left in round | Bot holds at a $3.0\text{ m}$ standoff upstream of the hazard until it despawns. |
| Hazard blocks checkout path with $\le 5\text{ s}$ left in round | Bot enters desperation mode and drives directly through the hazard toward checkout to try banking before store closes. |
| Hazard node despawns or is freed via `queue_free()` | Hazard is automatically removed from `active_hazards` via `tree_exited`; bot immediately re-evaluates decisions if previously waiting or holding. |
| Round transitions (`round_ended`, `round_started`) | `active_hazards` is cleared to prevent stale references across rounds. |
| Multiple hazards overlap or sit adjacent in an aisle | Point-to-segment algorithm tests against all active hazards; if any hazard is violated, the path is rejected. |
| Cart enters slip spin (`apply_slip`) | Bot outputs neutral commands (`throttle = 0.0`, `steer = 0.0`, `brake = 0.0`, `boost = false`) until slip expires. |

## 7. Test plan

**GUT tests** (headless, automated in `tests/rivals/test_bot_hazard_detection.gd`):
- [ ] `test_candidate_pickup_in_hazard_radius_rejected`: High-value pickup within 2.5 m of a hazard is skipped in favor of a safe pickup.
- [ ] `test_path_segment_crossing_hazard_rejected`: Pickup itself is outside danger radius, but navigation path segment passes within 2.5 m of a hazard; target is disqualified.
- [ ] `test_immediate_reroute_on_hazard_spawned`: Spawning a hazard across current path immediately triggers a decision tick and redirects bot.
- [ ] `test_unrelated_distant_hazard_does_not_interrupt_path`: Spawning a hazard far away from bot's path does not abort current target.
- [ ] `test_hazard_despawn_clears_blacklist`: Freeing a hazard via `tree_exited` allows the bot to re-select previously blocked items.
- [ ] `test_banking_standoff_outside_hazard`: When checkout path is blocked and timer $> 5.0\text{ s}$, bot holds position outside 2.5 m radius.
- [ ] `test_banking_desperation_rush_at_final_call`: When checkout path is blocked but timer $\le 5.0\text{ s}$, bot charges through toward checkout.
- [ ] `test_slip_spin_neutralizes_commands`: While cart is slipping, drive commands are neutralized.
- [ ] `test_round_end_clears_active_hazards`: Ending a round purges all tracked active hazards.

**Test scene checks** (by hand in `systems/rivals/test/rivals_test.tscn`):
- [ ] Place a mock puddle in an aisle; verify bot steers into adjacent aisle to reach pickups behind it.
- [ ] Spawn a hazard in front of an active bot; verify it immediately swerves or redirects without crashing into the hazard.
- [ ] Block the checkout pad with a puddle; verify banking bot stops outside the puddle until it clears, or rushes it during final call.

**Integration check** (`res://systems/core/main.tscn`):
- [ ] Run full project (`main.tscn`) through a complete round where stage hazards spawn (`RUSH` phase).
- [ ] Observe bots successfully avoiding puddles and falling pallet warning shadows while continuing to collect items and bank hauls.

## 8. Out of scope

- Implementing hazard spawning timers, random schedules, or spawn point validation (owned by Store / Anthony).
- Creating hazard visual assets or collision shapes (owned by Assets / Store).
- Cart slip mechanics, angular spin formulas, or recovery timers (owned by Cart / Rickey).
- Dynamic obstacle prediction for moving objects (pallet jack employee in backlog).
- HUD hazard warnings or PA voice announcements (owned by Player / Evan).

## 9. Done when

- [ ] `BotController` tracks active hazards and connects to `RoundManager.hazard_spawned`.
- [ ] Point-to-segment distance check accurately prevents bots from traversing within 2.5 m of active hazards.
- [ ] `hazard_spawned` immediately reroutes bots if the new hazard threatens their active route.
- [ ] Banking bots execute standoff outside blocked checkout zones, with a $\le 5.0\text{ s}$ desperation override.
- [ ] Driving inputs are neutralized during `Cart` slip spin-out.
- [ ] Full GUT suite passes headless with 0 errors (`godot --headless -s addons/gut/gut_cmdln.gd`).
- [ ] Manual verification passes in `systems/rivals/test/rivals_test.tscn` and in `main.tscn`.
- [ ] `docs/PROGRESS.md` Rivals section updated with handoff notes.
