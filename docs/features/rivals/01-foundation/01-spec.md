# 01-foundation: Spec

| | |
|---|---|
| System / Owner | Rivals / John |
| Branch | `rivals/01-foundation` |
| Status | Approved (2026-09-24) |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Demo |

## 1. Overview

This feature implements the foundational decision-making and driving logic for the three rival bot carts (Coupon Carl, Aunt Bev, Rolling Rita). Using a finite state machine (FSM), the bot evaluates the state of the match, other players, and floor pickups to decide whether to collect items, chase loaded rivals, or head for checkout to bank items. This state machine drives the physical cart using standard `DriveCommand` packets, allowing seamless integration with Rickey's movement system.

## 2. Player-facing behavior

The player observes the following bot behaviors during a round:
1. **Countdown Alignment**: During the countdown, bots align at their designated starting spots and remain stationary.
2. **Opening Rush**: As soon as the round starts ("GO!"), the bots drive into the store towards the aisles, targeting high-value items.
3. **Haul Harvesting**: Carts navigate dynamically from item to item, slowing down as they become more loaded (handled by Cart physics).
4. **Targeted Aggression**: Bots with high aggression (e.g., Coupon Carl) will actively chase the player or other bots carrying heavy hauls ($\ge 10$ items) to crash and inherit their items.
5. **Greedy Banking**: When a bot reaches its personal item count capacity (greed threshold) or when the round enters its final 20 seconds, the bot prioritizes heading out the front doors to bank its items at the checkout zone.
6. **Active Boosting**: Bots periodically emit fiery boosts along straightaways to catch targets or run to checkout.
7. **Collision Recovery**: If a bot hits a shelf, wall, or another cart and gets stuck, it reverses, turns, and re-routes intelligently.

## 3. Rules and numbers

### Core Constants and Settings

| Rule / constant | Value | Source |
|---|---|---|
| Bot decision interval | `0.3 s` | `GAME_SPEC.md` §12 |
| Bot stuck detection threshold | Speed $< 0.5\text{ m/s}$ for $\ge 1.0\text{ s}$ | `GAME_SPEC.md` §12 |
| Bot stuck recovery reverse duration | `1.0 s` | `GAME_SPEC.md` §12 |
| Rival big load chase threshold | $\ge 10$ items | `GAME_SPEC.md` §12 |
| Periodic boost evaluation interval | `1.0 s` | `00-brainstorm.md` Q4 |
| Periodic boost straightness gate | Steering error $< 30^\circ$ | `00-brainstorm.md` Q4 |
| Aggression difficulty scaling | $+0.1$ per round (capped at `1.0`) | `GAME_SPEC.md` §12 |

### Personality Profiles (Starting Values)

| Rival | Greed (banking limit) | Base Aggression | Boost Habit |
|---|---|---|---|
| **Coupon Carl** | 12 items | `0.8` | `0.4` |
| **Aunt Bev** | 6 items | `0.2` | `0.2` |
| **Rolling Rita** | 20 items | `0.9` | `0.9` |

### Finite State Machine (FSM)

The bot operates under a strict priority-based hierarchy evaluated during the `0.3 s` decision tick:

```
[STUCK Recovery] 
       ↓ (Not stuck)
[BANKING] (Count >= Greed OR Round Time Left <= 20.0s)
       ↓ (Not banking)
[CHASING] (Rivals with >= 10 items exist AND Aggression roll passes)
       ↓ (No chase)
[COLLECTING] (Default: Navigate to best Value/Distance world pickup)
```

#### 1. STUCK State (Highest Priority)
- **Trigger**: Speed is $< 0.5\text{ m/s}$ for $\ge 1.0\text{ s}$ continuously.
- **Action**: Lock out standard target tracking for `1.0 s`. Drive backwards (`throttle = 0.0`, `brake = 1.0`) and turn steer in a random direction (`steer = randf() > 0.5 ? 1.0 : -1.0`).

#### 2. BANKING State
- **Trigger**: `cart.get_state().items.size() >= personality.greed` OR `RoundManager.time_left <= 20.0`.
- **Action**: Set navigation target to `RoundManager.get_checkout_position()`.

#### 3. CHASING State
- **Trigger**: At least one other cart has $\ge 10$ items, AND a random roll `randf() <= current_aggression` passes.
- **Action**: Set navigation target to the eligible cart carrying the **highest item count** (break ties by **closest distance**).

#### 4. COLLECTING State (Default)
- **Trigger**: Default state.
- **Action**: Score all available world pickups using the utility function:
  $$\text{Utility} = \frac{\text{item.value}}{\text{distance\_to(item)}}$$
  Set navigation target to the pickup with the highest utility score. If no pickups are available, set target to a random idle aisle waypoint.

## 4. Interfaces

**Uses** (from other systems):
- `CONTRACTS.md` §2: `Cart API`:
  - `cart.get_state() -> CartState`: Polls the bot's own speed, items, and status.
  - `cart.apply_command(cmd: DriveCommand)`: Sends steering, throttle, and boost signals to the physical cart body.
- `CONTRACTS.md` §3: `RoundManager API`:
  - `RoundManager.get_carts() -> Array[Cart]`: Queries coordinates and hauls of other shoppers.
  - `RoundManager.get_pickups() -> Array[Pickup]`: Inspects items currently on the sales floor.
  - `RoundManager.get_checkout_position() -> Vector3`: Fetches banking coordinates.
  - `RoundManager.round_started`: Connects to enable AI and starts decision timers.
  - `RoundManager.round_ended`: Connects to disable AI and applies neutral commands.
  - `RoundManager.deal_spawned` & `cart.cart_robbed`: Connects to trigger immediate decision ticks for high responsiveness.

**Provides / emits:**
- `DriveCommand`: Evaluated and applied to the bot's owned `Cart` during `_physics_process`.

**Contract changes:**
- None.

## 5. Scenes and files

| Path | New / changed | Purpose |
|---|---|---|
| `systems/rivals/bot_controller.gd` | New | Main driver controller connecting AI state decisions to `Cart.apply_command()`. |
| `systems/rivals/bot_personality.gd` | New | Resource definition script holding greed, aggression, and boost habit properties. |
| `systems/shared/profiles/*.tres` | Changed | Profiles are initialized; bot personalities will be injected or instanced here. |
| `systems/rivals/test/rivals_test_scene.tscn` | New | 3D flat test environment containing a navigation region, spawn markers, and debug labels. |
| `systems/rivals/test/rivals_test_scene.gd` | New | Test scene script spawning dummy pickups and controlling test state. |
| `tests/rivals/test_bot_controller.gd` | New | Headless GUT unit tests covering the decision machine, stuck states, and event reactions. |

### Node Tree for `rivals_test_scene.tscn`
```
RivalsTestScene (Node3D)
├── DirectionalLight3D
├── WorldEnvironment
├── Ground (StaticBody3D)              ← Floor on physics layer 1 with GridMap or MeshInstance
├── NavigationRegion3D                 ← Baked flat navmesh covering the floor
│   └── WallObstacles (StaticBody3D)   ← Inner partitions to test stuck recovery
├── Carts (Node3D)
│   ├── TestBotRita (Cart stub)        ← Attached BotController with Rita's personality
│   └── TestBotCarl (Cart stub)        ← Attached BotController with Carl's personality
├── PickupSpawners (Node3D)            ← Spawns dummy ItemData pickups to test utility math
└── UI (CanvasLayer)                   ← Overlay showing states, speeds, and targets for debug
```

## 6. Edge cases

| Case | Expected behavior |
|---|---|
| Target pickup collected by someone else mid-route | The pickup is deleted $\rightarrow$ `RoundManager` pickup lists change. The bot's `0.3 s` decision tick (or instant trigger) detects the missing target and selects the next best pickup. |
| Bot gets stuck against an obstacle | Speed is $< 0.5\text{ m/s}$ for $1.0\text{ s} \rightarrow$ Enters **STUCK** state, reversing and turning for $1.0\text{ s}$, then re-routes. |
| Pathfinding target is unreachable | If navigation path is incomplete/unreachable, the target is added to a temporary `unreachable_blacklist` and a decision tick is forced immediately to find an alternative. |
| Multi-cart robbery event in vicinity | `cart_robbed` signal triggers an immediate, out-of-band decision tick. The bot immediately evaluates whether to chase the newly loaded winner or harvest the spilled floor pickups. |
| Countdown / Game Over controls | In `COUNTDOWN` phase, driving controls are locked. At `CLOSED`, controls are immediately neutralized, halting bots in place. |

## 7. Test plan

**GUT tests** (headless, automated):
- [ ] `test_countdown_locks_inputs`: Given the match is in the `COUNTDOWN` phase, the controller must output zero inputs (`throttle = 0.0`, `steer = 0.0`, `boost = false`).
- [ ] `test_decision_stuck_triggers_recovery`: Mock speed at $0.0\text{ m/s}$ for $1.0\text{ s}$; verify state changes to **STUCK** and outputs reverse steering inputs.
- [ ] `test_greed_triggers_banking`: Mock cart items count $\ge$ greed limit; verify state changes to **BANKING** and targets the checkout position.
- [ ] `test_time_left_forces_banking`: Mock low items count but `RoundManager.time_left <= 20.0`; verify state changes to **BANKING**.
- [ ] `test_aggression_roll_success_triggers_chase`: Inject mock randomizer where `randf() <= aggression` succeeds; verify target is set to the qualifying rival with the highest haul.
- [ ] `test_aggression_roll_fail_bypasses_chase`: Inject mock randomizer where `randf() > aggression` fails; verify bot ignores rival and continues collecting.
- [ ] `test_target_unreachable_blacklist`: Trigger a navigation failure; verify the target is blacklisted and an immediate retarget tick is executed.
- [ ] `test_boost_periodic_checks`: Mock straight driving segment and check boost is triggered only periodically based on `boost_habit` roll.

**Test scene checks** (by hand; feel and visuals):
- [ ] Open `systems/rivals/test/rivals_test_scene.tscn` in the Godot Editor.
- [ ] Click "Play Scene" to execute the test scene.
- [ ] Observe bots successfully harvesting spawned dummy pickups based on proximity and value.
- [ ] Block a bot with a spawned obstacle; observe it triggering stuck recovery, reversing, and successfully navigating around the obstacle.
- [ ] Spawn a rival cart with 12 items nearby; observe high-aggression bot Carl break off collection to chase and collide with the loaded rival.
- [ ] Trigger the `FINAL_CALL` phase via the debug UI; observe all bots immediately breaking off activity and driving directly to the checkout zone.

**Integration check** (in Anthony's full `main.tscn` once merged):
- [ ] Start a standard game round.
- [ ] Verify Carl, Bev, and Rita behave according to their distinct profiles (Bev banks early, Rita holds out, Carl rams).
- [ ] Verify bot difficulty scales up (aggression increases by $+0.1$ in rounds 2 and 3).

## 8. Out of scope

- **Dynamic Raycast Obstacle Avoidance**: Bots will rely strictly on pathfinding routes and stuck recovery; they will not steer proactively around unbaked obstacles (deferred to future TODO).
- **Steer Fine-Tuning / Drifting**: Simple forward steering towards path points (deferred to movement integration).
- **Leading Trajectories**: Chasing is direct-target pursuit, not predictive intercept (deferred to final polish).

## 9. Done when

- [ ] All 8 specified FSM and state-transition unit tests pass in headless GUT.
- [ ] The `BotController` executes correctly inside `systems/rivals/test/rivals_test_scene.tscn` under all state paths.
- [ ] Bot behaviors conform exactly to their distinct starting greed, aggression, and boost profiles.
- [ ] Headless test suite contains 0 SCRIPT ERRORs and correctly imports all class names.
- [ ] `PROGRESS.md` Rivals section updated with handoff notes for Rickey (Cart/Player) and Anthony (Integration).
