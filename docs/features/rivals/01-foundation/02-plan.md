# 01-foundation: Plan

| | |
|---|---|
| System / Owner | Rivals / John |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |

## 1. Blueprint

- **Iteration 1: Personalities & Controller Core Setup**: Exposes custom Resource scripts for bot personality values and sets up the baseline `BotController` node with simple `RoundManager` wiring. At the end, bots lock/unlock controls on round phase shifts.
- **Iteration 2: Core FSM States (Collecting & Banking)**: Implements the default **COLLECTING** utility search algorithm and the threshold-triggered **BANKING** state. At the end, bots can pick the most valuable nearby items and navigate to checkout when full or when time is short.
- **Iteration 3: Chasing & Difficulty Scaling**: Implements the probability-gated **CHASING** combat state and round-by-round aggression scaling. At the end, high-aggression bots dynamically hunt loaded rivals.
- **Iteration 4: Stuck Recovery, Blacklisting, and Boosting**: Implements stuck-recovery reverses, target blacklists on navigation failures, and straightaway boost checks. At the end, bots recover from physical collisions and use boosts along straightaways.
- **Iteration 5: Event Responsiveness & Test Scene Integration**: Wires up immediate out-of-band decision ticks on `cart_robbed` and `deal_spawned` signals, and creates a visual 3D flat test scene to verify bot pathing and behavior manually.

## 2. Iterations and steps

### Iteration 1: Personalities & Controller Core Setup
- **Step 1.1**: Create `BotPersonality` Resource Script → test: verify resource initialization and default parameter scopes.
- **Step 1.2**: Setup basic `BotController` with round signal connections → test: verify controls are zeroed out during countdown and deactivated when rounds end.

### Iteration 2: Core FSM States (Collecting & Banking)
- **Step 2.1**: Implement **COLLECTING** state utility scoring → test: verify utility math selection (`value / distance`) targeting the best floor pickup.
- **Step 2.2**: Implement **BANKING** state transitions → test: verify state transitions to banking when `greed` item count is met or when round timer drops below $20.0\text{ s}$.

### Iteration 3: Chasing & Difficulty Scaling
- **Step 3.1**: Implement **CHASING** state target selection and aggression gates → test: verify bot chases loaded rivals only when probability rolls succeed.
- **Step 3.2**: Implement additive aggression difficulty scaling → test: verify aggression increases correctly round-by-round and caps at $1.0$.

### Iteration 4: Stuck Recovery, Blacklisting, and Boosting
- **Step 4.1**: Implement speed-accumulation **STUCK** detection and recovery steering → test: verify bot triggers $1.0\text{ s}$ reversing recovery when speed $< 0.5\text{ m/s}$ for $1.0\text{ s}$.
- **Step 4.2**: Implement unreachable blacklist for failed paths → test: verify navigation failure blacklists the target and forces a re-evaluation tick.
- **Step 4.3**: Implement periodic boost evaluation and straightness gates → test: verify boost triggers based on `boost_habit` probability and steering angles $< 30^\circ$.

### Iteration 5: Event Responsiveness & Test Scene Integration
- **Step 5.1**: Implement out-of-band event-driven decision ticks → test: verify immediate target updates on `cart_robbed` and `deal_spawned`.
- **Step 5.2**: Build visual test scene `rivals_test_scene.tscn` → test: manual in-editor verification of bot harvesting, stuck recovery, and banking.

---

## 3. Prompts

### Prompt 1 (Step 1.1): Create BotPersonality Resource Script

```text
Context: Rivals feature 01-foundation. Read AGENTS.md, 01-spec.md §3 (Personality Profiles), and CONTRACTS.md §1.6 (profiles description).
Task: Create the bot personality resource script.
Files: Create `systems/rivals/bot_personality.gd` and `tests/rivals/test_bot_controller.gd`.
Test first: In `tests/rivals/test_bot_controller.gd`, extend `GutTest` and write `test_personality_resource_defaults` asserting that a newly instantiated `BotPersonality` has exported variables with the following types/defaults:
  - `greed`: int = 10
  - `base_aggression`: float = 0.5 (range 0.0 to 1.0)
  - `boost_habit`: float = 0.5 (range 0.0 to 1.0)
Run the headless test suite and verify it fails due to the missing file/properties.
Implement: Create `systems/rivals/bot_personality.gd` extending `Resource` with `class_name BotPersonality` and the three `@export` variables with their ranges and default values.
Finish: Run the full headless GUT suite and confirm all pass, tick Step 1.1 in `docs/features/rivals/01-foundation/03-todo.md`, commit "rivals: create BotPersonality resource script", and report.
```

### Prompt 2 (Step 1.2): Setup basic BotController and Round Timer Wiring

```text
Context: Rivals feature 01-foundation. Read AGENTS.md, 01-spec.md §3, §4 (Interfaces), and CONTRACTS.md §4 (Drivers).
Task: Create the base `BotController` class and wire up core round-transition logic.
Files: Create `systems/rivals/bot_controller.gd`, edit `tests/rivals/test_bot_controller.gd`.
Test first: In `tests/rivals/test_bot_controller.gd`, write tests:
  - `test_countdown_locks_controls`: Verify that when `RoundManager.phase = GameTypes.Phase.COUNTDOWN`, the controller's active `DriveCommand` output contains zero throttle, steer, and boost.
  - `test_round_start_enables_timer`: Mock `RoundManager.round_started` signal emission and verify that the bot's decision timer starts (is active).
  - `test_round_end_neutralizes_commands`: Mock `RoundManager.round_ended` signal emission and verify that the decision timer stops and output commands are neutralized immediately.
Run headless GUT and confirm failures.
Implement: Create `systems/rivals/bot_controller.gd` extending `Node` with `class_name BotController`.
  - Expose `@export var cart: Cart` and `@export var personality: BotPersonality`.
  - Initialize `var _cmd := DriveCommand.new()`.
  - Connect to `RoundManager` autoload signals `round_started` and `round_ended` in `_ready()`.
  - Implement a 0.3s decision timer (using a scene tree Timer or custom delta accumulator).
  - Inside `_physics_process(delta)`, if `RoundManager.is_gameplay_active()` is false, send a clean neutral `_cmd` (throttle=0, steer=0, brake=0, boost=false) to `cart.apply_command(_cmd)`.
Finish: Run headless GUT and confirm all pass, tick Step 1.2 in `docs/features/rivals/01-foundation/03-todo.md`, commit "rivals: setup BotController baseline and round wiring", and report.
```

### Prompt 3 (Step 2.1): Implement COLLECTING State Utility Scoring

```text
Context: Rivals feature 01-foundation. Read AGENTS.md, 01-spec.md §3 (COLLECTING State), and CONTRACTS.md §3.1 (Pickup description).
Task: Implement the default COLLECTING state utility scoring algorithm.
Files: Edit `systems/rivals/bot_controller.gd` and `tests/rivals/test_bot_controller.gd`.
Test first: In `tests/rivals/test_bot_controller.gd`, write test:
  - `test_collecting_utility_targeting`: Mock `RoundManager.get_pickups()` returning a list of mock Pickups with varying values and distances (e.g., Pickup A value=$10, distance=10m vs. Pickup B value=$50, distance=20m). Assert that the bot's chosen navigation target is set to the pickup with the highest `value / distance` score.
Run headless GUT and confirm failure.
Implement: In `BotController`:
  - Add state tracking enums for FSM (STUCK, BANKING, CHASING, COLLECTING).
  - Create a private method `_evaluate_decisions()` triggered every 0.3s decision interval.
  - In COLLECTING state, calculate utility for all pickups in `RoundManager.get_pickups()`.
  - Assign the highest utility pickup as the target position and update navigation path target. (Mock or bypass `NavigationAgent3D` pathfinding if in test mode via dependency injection).
Finish: Run headless GUT and confirm all pass, tick Step 2.1 in `docs/features/rivals/01-foundation/03-todo.md`, commit "rivals: implement COLLECTING state utility scoring", and report.
```

### Prompt 4 (Step 2.2): Implement BANKING State Transitions

```text
Context: Rivals feature 01-foundation. Read AGENTS.md, 01-spec.md §3 (BANKING State), and CONTRACTS.md §1.4 & §3.
Task: Implement transition logic for the BANKING state.
Files: Edit `systems/rivals/bot_controller.gd` and `tests/rivals/test_bot_controller.gd`.
Test first: In `tests/rivals/test_bot_controller.gd`, write tests:
  - `test_greed_threshold_triggers_banking`: Mock the bot's own cart state to have items size $\ge$ `personality.greed`. Run the decision tick and assert that the FSM transitions to BANKING state and sets its target to `RoundManager.get_checkout_position()`.
  - `test_low_timer_forces_banking`: Mock the bot's cart items below greed, but set `RoundManager.time_left = 19.0` (inside FINAL_CALL). Assert that the FSM transitions to BANKING state.
Run headless GUT and confirm failures.
Implement: In `BotController._evaluate_decisions()`:
  - Read `cart.get_state()` snapshot.
  - If cart items count $\ge$ `personality.greed` OR `RoundManager.time_left <= 20.0`, transition FSM to BANKING.
  - Set navigation target coordinates to `RoundManager.get_checkout_position()`.
Finish: Run headless GUT and confirm all pass, tick Step 2.2 in `docs/features/rivals/01-foundation/03-todo.md`, commit "rivals: implement BANKING state transitions", and report.
```

### Prompt 5 (Step 3.1): Implement CHASING State Target Selection and Aggression Gates

```text
Context: Rivals feature 01-foundation. Read AGENTS.md, 01-spec.md §3 (CHASING State), and CONTRACTS.md §1.4.
Task: Implement the probability-gated CHASING state target selection.
Files: Edit `systems/rivals/bot_controller.gd` and `tests/rivals/test_bot_controller.gd`.
Test first: In `tests/rivals/test_bot_controller.gd`, write tests:
  - `test_chasing_aggression_roll_success`: Mock other carts in play, with one cart carrying 12 items. Override/mock the randomizer to return $0.0$ (ensuring `randf() <= current_aggression` succeeds). Assert that FSM transitions to CHASING state and targets the loaded cart.
  - `test_chasing_aggression_roll_fail`: Override/mock the randomizer to return $1.0$ (ensuring `randf() > current_aggression` fails). Assert that the bot remains in COLLECTING (or BANKING) and ignores the loaded cart.
  - `test_chasing_targets_highest_haul`: Mock two other loaded carts ($\ge 10$ items). Verify the bot targets the one with the highest item count/value, breaking ties by closest distance.
Run headless GUT and confirm failures.
Implement: In `BotController`:
  - Expose a way to inject or override random floats for test determinism (e.g., a test-only `_randf_override` variable).
  - In `_evaluate_decisions()`, if not banking, search `RoundManager.get_carts()` for eligible target carts (items size $\ge 10$, excluding itself).
  - Roll probability `_randf()` against `current_aggression`. If it passes and eligible carts exist, transition to CHASING and target the qualified cart with the highest item count/value (break ties by distance).
Finish: Run headless GUT and confirm all pass, tick Step 3.1 in `docs/features/rivals/01-foundation/03-todo.md`, commit "rivals: implement CHASING state and aggression gates", and report.
```

### Prompt 6 (Step 3.2): Implement Additive Aggression Scaling per Round

```text
Context: Rivals feature 01-foundation. Read AGENTS.md, 01-spec.md §3 (Core Constants), and CONTRACTS.md §3.
Task: Implement round-by-round aggression difficulty scaling.
Files: Edit `systems/rivals/bot_controller.gd` and `tests/rivals/test_bot_controller.gd`.
Test first: In `tests/rivals/test_bot_controller.gd`, write tests:
  - `test_aggression_scaling_round_1`: Mock `RoundManager.round_started` signal with round 1, verify `current_aggression` equals `personality.base_aggression`.
  - `test_aggression_scaling_round_2`: Mock signal with round 2, verify `current_aggression` is `personality.base_aggression + 0.1` (clamped at 1.0).
Run headless GUT and confirm failures.
Implement: In `BotController`:
  - Declare a class variable `var current_aggression: float`.
  - On receiving `round_started(round_number)`, compute:
    `current_aggression = clamp(personality.base_aggression + (round_number - 1) * 0.1, 0.0, 1.0)`.
Finish: Run headless GUT and confirm all pass, tick Step 3.2 in `docs/features/rivals/01-foundation/03-todo.md`, commit "rivals: implement round aggression scaling", and report.
```

### Prompt 7 (Step 4.1): Implement Stuck Detection and Recovery Steering

```text
Context: Rivals feature 01-foundation. Read AGENTS.md, 01-spec.md §3 (STUCK State).
Task: Implement stuck speed accumulators and reverse-recovery driving inputs.
Files: Edit `systems/rivals/bot_controller.gd` and `tests/rivals/test_bot_controller.gd`.
Test first: In `tests/rivals/test_bot_controller.gd`, write tests:
  - `test_stuck_accumulation_triggers_recovery`: Inject a slow cart speed ($0.1\text{ m/s}$) over a mocked $1.0\text{ s}$ elapsed time. Verify that FSM transitions to STUCK state.
  - `test_stuck_recovery_outputs_reversing`: Verify that while in STUCK state, the controller's emitted `DriveCommand` has `throttle = 0.0`, `brake = 1.0` (for reversing), and a non-zero `steer`.
  - `test_stuck_recovery_expires_after_1s`: Simulate $1.0\text{ s}$ inside STUCK recovery; verify the FSM transitions back to normal evaluation.
Run headless GUT and confirm failures.
Implement: In `BotController`:
  - Track speed in `_physics_process(delta)` using `cart.get_state().speed`.
  - Accumulate elapsed time if horizontal speed is $< 0.5\text{ m/s}$ and gameplay is active. Reset accumulator if speed $\ge 0.5\text{ m/s}$.
  - If accumulator $\ge 1.0\text{ s}$, transition FSM to STUCK state.
  - Lock out `_evaluate_decisions()` standard ticks during STUCK recovery.
  - In STUCK recovery, output a `DriveCommand` with `throttle = 0.0`, `brake = 1.0` to reverse, and steer locked to a random direction (either -1.0 or 1.0, picked on transition) for exactly `1.0 s`.
Finish: Run headless GUT and confirm all pass, tick Step 4.1 in `docs/features/rivals/01-foundation/03-todo.md`, commit "rivals: implement stuck detection and recovery", and report.
```

### Prompt 8 (Step 4.2): Implement Navigation Target Blacklisting on Failure

```text
Context: Rivals feature 01-foundation. Read AGENTS.md, 01-spec.md §3, §6 (Edge Cases).
Task: Implement unreachable-target blacklisting on navigation pathing failures.
Files: Edit `systems/rivals/bot_controller.gd` and `tests/rivals/test_bot_controller.gd`.
Test first: In `tests/rivals/test_bot_controller.gd`, write test:
  - `test_navigation_failure_blacklists_target`: Mock a target pickup, set a mock navigation failure state, and assert that the target is added to `unreachable_blacklist` and a decision tick is forced immediately.
Run headless GUT and confirm failure.
Implement: In `BotController`:
  - Initialize an `Array` or `Dictionary` for `unreachable_blacklist`.
  - Integrate a check on the `NavigationAgent3D` reference (if active/not null). If `is_target_reachable()` is false (or during path construction failure), retrieve the targeted pickup/rival ID.
  - Add the target to the `unreachable_blacklist` (which COLLECTING will filter out).
  - Trigger an immediate `_evaluate_decisions()` tick to bypass the 0.3s timer wait.
  - Clear the blacklist on round ended.
Finish: Run headless GUT and confirm all pass, tick Step 4.2 in `docs/features/rivals/01-foundation/03-todo.md`, commit "rivals: implement navigation blacklisting", and report.
```

### Prompt 9 (Step 4.3): Implement Periodic Boost Evaluation and Straightness Gates

```text
Context: Rivals feature 01-foundation. Read AGENTS.md, 01-spec.md §3 (Rules and numbers).
Task: Implement straightaway boost checks.
Files: Edit `systems/rivals/bot_controller.gd` and `tests/rivals/test_bot_controller.gd`.
Test first: In `tests/rivals/test_bot_controller.gd`, write tests:
  - `test_boost_periodic_roll_success`: Override/mock the randomizer to return $0.0$ (ensuring `randf() <= boost_habit` succeeds) and mock a straight target path (angular offset $10^\circ$). Verify `boost = true` in the output command.
  - `test_boost_gate_fails_on_turn`: Override/mock randomizer to return $0.0$ but set steering offset to $45^\circ$ (exceeding the $30^\circ$ limit). Verify `boost = false`.
Run headless GUT and confirm failures.
Implement: In `BotController`:
  - Track elapsed time since last boost check in `_physics_process`.
  - Every $1.0\text{ s}$, if not stuck and target is assigned, evaluate `randf() <= personality.boost_habit`.
  - If successful, check the steering angle offset between the cart's forward vector and the target direction. If angle offset $< 30^\circ$, set `_cmd.boost = true` and keep it active for `1.0 s` continuously (or until boost meter in `cart.get_state().boost_meter` hits 0).
Finish: Run headless GUT and confirm all pass, tick Step 4.3 in `docs/features/rivals/01-foundation/03-todo.md`, commit "rivals: implement periodic boost gates", and report.
```

### Prompt 10 (Step 5.1): Implement Out-of-Band Decision Signals for Responsiveness

```text
Context: Rivals feature 01-foundation. Read AGENTS.md, 01-spec.md §4 (Interfaces).
Task: Connect events to trigger immediate decision-making ticks.
Files: Edit `systems/rivals/bot_controller.gd` and `tests/rivals/test_bot_controller.gd`.
Test first: In `tests/rivals/test_bot_controller.gd`, write test:
  - `test_cart_robbed_forces_immediate_tick`: Spy on `_evaluate_decisions` or mock the decision timer, emit `cart_robbed` signal from any Cart, and assert that a decision tick is executed instantly, resetting the 0.3s timer.
  - `test_deal_spawned_forces_immediate_tick`: Emit `RoundManager.deal_spawned`, and assert that a decision tick is executed instantly.
Run headless GUT and confirm failures.
Implement: In `BotController`:
  - Connect to `RoundManager.deal_spawned` and `cart.cart_robbed` inside `_ready()` (or when cart is assigned).
  - When either signal is received, execute `_evaluate_decisions()` immediately and reset the 0.3s polling timer accumulator so the next tick is scheduled 0.3s from now.
Finish: Run headless GUT and confirm all pass, tick Step 5.1 in `docs/features/rivals/01-foundation/03-todo.md`, commit "rivals: implement immediate signal decision ticks", and report.
```

### Final Prompt (Step 5.2): Wire into the Test Scene and Implement Test Scene Logic

```text
Context: All previous steps are completed and verified by tests. Let's create the 3D test scene to verify pathing, FSM transitions, and behavior manually.
Task: Create the 3D flat test scene containing a navigation mesh, floor obstacles, and debug UI.
Files: Create `systems/rivals/test/rivals_test_scene.tscn`, `systems/rivals/test/rivals_test_scene.gd`.
Test first: Verify that the test scene script compiles without warnings or errors. Ensure GUT can still run headless without parse errors.
Implement: Create the 3D visual test scene according to the layout in `01-spec.md` §5.
  - Attach `rivals_test_scene.gd` to the root node.
  - Instantiate a flat `NavigationRegion3D` containing a flat floor `StaticBody3D` (layer 1, mask 1).
  - Spawn two dummy carts using `systems/cart/cart.tscn` (or a stub if Rickey's movement is not merged).
  - Spawn mock `Pickup` nodes with random values at different locations in the room.
  - Add a debug CanvasLayer overlay showing the current active state, speed, target coordinate, and blacklists of each bot.
  - Implement basic steering in `BotController` to orient the cart towards `NavigationAgent3D.get_next_path_position()` and apply throttle.
Finish: Run the full GUT headless test suite, tick Step 5.2 in `docs/features/rivals/01-foundation/03-todo.md`, commit "rivals: test scene for 01-foundation", and report.
```

## 4. Improvements and bugs

Add items found during building or playtesting. Each gets a prompt when it's scheduled.

1. `[systems/rivals/bot_controller.gd]`: Steering overshoot damping: Adjust bot steering scale when near target to prevent endless circling.
2. `[systems/rivals/bot_controller.gd]`: Smooth acceleration: Dampen throttle ramps for better traction.
