# 03-hazard_detection: Plan

| | |
|---|---|
| System / Owner | Rivals / John |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |

## 1. Blueprint

- **Iteration 1: Hazard Tracking & Geometric Path Safety Math**: Wire `BotController` to `RoundManager.hazard_spawned` and implement lifecycle cleanup via `tree_exited`. Build the horizontal 2D (XZ) point-to-segment distance algorithm and path safety evaluator with the 2.5 m danger radius. At the end, bots track active hazards and can determine if any position or path intersects danger.
- **Iteration 2: Candidate Target Filtering & Active Slip Neutralization**: Integrate path/target safety checks into `_evaluate_decisions()` for both `COLLECTING` and `CHASING` states, falling back to safe coasting if all options are blocked. Neutralize output drive commands during cart slip spin-outs. At the end, bots filter out compromised pickups/rivals and handle spinning gracefully.
- **Iteration 3: Event-Driven Rerouting & Banking Standoff Logic**: Trigger immediate decision re-evaluations when a new hazard spawns across the active route or when a blocking hazard despawns. Implement banking standoff at 3.0 m from blocked checkout zones with a final-call desperation rush override ($\le 5.0\text{ s}$). At the end, bots react dynamically to emerging hazards and manage checkout safely.
- **Iteration 4: Test Scene Wiring & Full Integration Check**: Update `systems/rivals/test/rivals_test.tscn` to include toggleable/spawnable mock hazards and test courses for manual visual inspection of bot pathing, rerouting, and checkout standoff.

## 2. Iterations and steps

### Iteration 1: Hazard Tracking & Geometric Path Safety Math
- **Step 1.1**: Hazard Lifecycle Tracking & Test Overrides → test: verify hazard nodes are registered on `hazard_spawned`, auto-removed on `tree_exited`, and cleared on round start/end.
- **Step 1.2**: Horizontal Point-to-Segment Path Safety Check → test: verify point-to-segment distance checks correctly accept safe paths and reject paths intersecting the 2.5 m hazard radius.

### Iteration 2: Candidate Target Filtering & Active Slip Neutralization
- **Step 2.1**: Filter Unsafe Candidate Targets in Decision Evaluation → test: verify high-value pickups and loaded rivals inside hazard zones or behind hazard-blocked paths are skipped in favor of safe options.
- **Step 2.2**: Active Slip Command Neutralization → test: verify drive commands are zeroed out while the cart is slipping (`_slip_left > 0.0` or `is_slipping()`).

### Iteration 3: Event-Driven Rerouting & Banking Standoff Logic
- **Step 3.1**: Immediate Reroute on `hazard_spawned` & Despawn Re-evaluation → test: verify spawning a hazard along the active path immediately triggers a decision tick, distant spawns do not interrupt, and hazard despawn re-evaluates blocked bots.
- **Step 3.2**: Banking Checkout Standoff & Desperation Rush → test: verify banking bots hold 3.0 m outside blocked checkout zones when $> 5.0\text{ s}$ remain, but rush through to checkout when $\le 5.0\text{ s}$ remain.

### Iteration 4: Test Scene Wiring & Full Integration Check
- **Step 4.1**: Wire Hazards into Rivals Test Scene → test: manual in-editor and live run verification of bot avoidance, rerouting, and standoff in `systems/rivals/test/rivals_test.tscn`.

---

## 3. Prompts

### Prompt 1 (Step 1.1): Hazard Lifecycle Tracking & Test Overrides

```text
Context: Rivals feature 03-hazard_detection. Read AGENTS.md, docs/features/rivals/03-hazard_detection/01-spec.md §3, §4, and docs/CONTRACTS.md §3.
Task: Implement active hazard tracking in `BotController` via `RoundManager.hazard_spawned` with automatic `tree_exited` removal and round cleanup.
Files: Edit `systems/rivals/bot_controller.gd`, create `tests/rivals/test_bot_hazard_detection.gd`.
Test first: In `tests/rivals/test_bot_hazard_detection.gd`, extend `GutTest` and write:
  - `test_hazard_spawned_registers_active_hazard`: Mock `RoundManager.hazard_spawned.emit(hazard)` with a mock `Node3D`. Verify `hazard` is present in `controller.get_active_hazards()`.
  - `test_hazard_tree_exited_removes_hazard`: When the hazard emits `tree_exited` (or is freed), assert that it is automatically purged from `controller.get_active_hazards()`.
  - `test_round_end_clears_active_hazards`: Verify that emitting `RoundManager.round_ended` clears all tracked hazards.
  - `test_hazards_override_bypasses_registered`: Setting `controller.test_hazards_override` returns the override array.
Run headless GUT and confirm tests fail due to missing methods/properties.
Implement: In `systems/rivals/bot_controller.gd`:
  - Add `var active_hazards: Array[Node3D] = []` and public `var test_hazards_override: Array[Node3D] = []`.
  - Add public getter `func get_active_hazards() -> Array[Node3D]`.
  - In `_ready()`, connect `RoundManager.hazard_spawned.connect(_on_hazard_spawned)`.
  - In `_on_hazard_spawned(hazard: Node3D)`, append `hazard` to `active_hazards` if valid and connect `hazard.tree_exited.connect(_on_hazard_tree_exited.bind(hazard))` (using `CONNECT_ONE_SHOT` if appropriate).
  - In `_on_hazard_tree_exited(hazard: Node3D)`, remove `hazard` from `active_hazards`.
  - In `_on_round_started` and `_on_round_ended`, clear `active_hazards`.
Finish: Run the full GUT suite headless (`& "C:\Users\John\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`) and confirm all pass. Tick Step 1.1 in `docs/features/rivals/03-hazard_detection/03-todo.md`, commit "rivals: implement hazard lifecycle tracking", and report.
```

### Prompt 2 (Step 1.2): Horizontal Point-to-Segment Path Safety Check

```text
Context: Rivals feature 03-hazard_detection. Read AGENTS.md, docs/features/rivals/03-hazard_detection/01-spec.md §3 (Formulas & Constants), and docs/CONTRACTS.md §3.
Task: Implement 2D XZ point-to-segment distance checking and path safety evaluation in `BotController`.
Files: Edit `systems/rivals/bot_controller.gd` and `tests/rivals/test_bot_hazard_detection.gd`.
Test first: In `tests/rivals/test_bot_hazard_detection.gd`, write:
  - `test_position_inside_hazard_radius_rejected`: A position within 2.5 m of a hazard returns false from `is_position_safe_from_hazards(pos)`; a position at 3.0 m returns true.
  - `test_hazard_custom_danger_radius_respected`: If a hazard node exposes `danger_radius = 4.0`, a position at 3.0 m is rejected.
  - `test_path_segment_crossing_hazard_rejected`: A path segment from (0, 0, 0) to (10, 0, 0) with a hazard at (5, 0, 1.0) returns false from `is_path_safe_from_hazards(path)`.
  - `test_path_segment_clearing_hazard_accepted`: A path segment from (0, 0, 0) to (10, 0, 0) with a hazard at (5, 0, 4.0) returns true from `is_path_safe_from_hazards(path)`.
Run headless GUT and confirm failures.
Implement: In `systems/rivals/bot_controller.gd`:
  - Define `const DEFAULT_HAZARD_RADIUS: float = 2.5`.
  - Implement helper `func get_hazard_radius(hazard: Node3D) -> float` reading `hazard.get("danger_radius")` if float and $> 0$, else `DEFAULT_HAZARD_RADIUS`.
  - Implement `func is_position_safe_from_hazards(pos: Vector3) -> bool`: checks horizontal 2D XZ distance from `pos` to all active hazards.
  - Implement private helper `func _distance_to_segment_xz(point: Vector3, seg_a: Vector3, seg_b: Vector3) -> float`: calculates the minimum distance from point to segment in the horizontal plane.
  - Implement `func is_path_safe_from_hazards(path: PackedVector3Array) -> bool`: verifies all segment intervals along `path` maintain clearance $\ge \text{hazard radius}$.
Finish: Run the full GUT suite headless and confirm all pass. Tick Step 1.2 in `docs/features/rivals/03-hazard_detection/03-todo.md`, commit "rivals: implement geometric hazard path safety checks", and report.
```

### Prompt 3 (Step 2.1): Filter Unsafe Candidate Targets in Decision Evaluation

```text
Context: Rivals feature 03-hazard_detection. Read AGENTS.md, docs/features/rivals/03-hazard_detection/01-spec.md §3 (Candidate Filtering), and docs/CONTRACTS.md §3.
Task: Integrate hazard safety checks into `_evaluate_decisions()` so bots skip pickups and rivals positioned in or behind hazards.
Files: Edit `systems/rivals/bot_controller.gd` and `tests/rivals/test_bot_hazard_detection.gd`.
Test first: In `tests/rivals/test_bot_hazard_detection.gd`, write:
  - `test_candidate_pickup_in_hazard_radius_rejected`: Two pickups available: Pickup A ($50, 5m away, inside hazard radius) and Pickup B ($10, 8m away, safe). Verify `_evaluate_decisions()` selects Pickup B.
  - `test_candidate_pickup_with_blocked_path_rejected`: Pickup is outside hazard radius, but navigation path segment crosses hazard radius. Verify candidate is rejected in favor of an unblocked pickup.
  - `test_chasing_rival_in_hazard_rejected`: Chasing evaluation skips rival carts that sit inside hazard radius or behind hazard segments.
  - `test_all_pickups_blocked_coasts_safely`: If all pickups are blocked, `target_position` becomes `Vector3.ZERO` and throttle outputs `0.0`.
Run headless GUT and confirm failures.
Implement: In `systems/rivals/bot_controller.gd`:
  - Add public property `var test_nav_path_override: PackedVector3Array = []`.
  - In `_get_pickups()`, filter out pickups where `not is_position_safe_from_hazards(p.global_position)`.
  - During pickup utility evaluation, check path safety (using `nav_agent.get_current_navigation_path()` or `test_nav_path_override` or direct segment from cart to pickup).
  - In `_evaluate_chasing()`, filter out rival carts where position or path violates hazard safety.
  - If no safe target is found, set `target_position = Vector3.ZERO` and ensure `build_command()` outputs neutral throttle when `target_position == Vector3.ZERO`.
Finish: Run the full GUT suite headless and confirm all pass. Tick Step 2.1 in `docs/features/rivals/03-hazard_detection/03-todo.md`, commit "rivals: filter hazard-blocked targets during decision ticks", and report.
```

### Prompt 4 (Step 2.2): Active Slip Command Neutralization

```text
Context: Rivals feature 03-hazard_detection. Read AGENTS.md, docs/features/rivals/03-hazard_detection/01-spec.md §3 (Slip Neutralization), and docs/CONTRACTS.md §2.
Task: Neutralize bot driving inputs while the cart is spinning out from a slippery puddle.
Files: Edit `systems/rivals/bot_controller.gd` and `tests/rivals/test_bot_hazard_detection.gd`.
Test first: In `tests/rivals/test_bot_hazard_detection.gd`, write:
  - `test_slip_spin_neutralizes_commands`: Set up an active cart and trigger `cart.apply_slip(3.0)`. Run `build_command(delta)` and assert that `throttle == 0.0`, `brake == 0.0`, `steer == 0.0`, and `boost == false`.
  - `test_slip_expiration_restores_commands`: After simulating delta time exceeding slip duration, assert that normal drive commands resume.
Run headless GUT and confirm failures.
Implement: In `systems/rivals/bot_controller.gd`:
  - Add private helper `func _is_cart_slipping() -> bool`:
    - Checks `cart.has_method("is_slipping")` or inspects `cart.get("_slip_left") > 0.0`.
  - In `build_command(delta)`:
    - If `_is_cart_slipping()`, immediately neutralize `_cmd` (`throttle = 0.0`, `brake = 0.0`, `steer = 0.0`, `boost = false`) and return `_cmd`.
  - In `_physics_process(delta)`:
    - If slipping, pause stuck accumulator and boost timers.
Finish: Run the full GUT suite headless and confirm all pass. Tick Step 2.2 in `docs/features/rivals/03-hazard_detection/03-todo.md`, commit "rivals: neutralize driving inputs during cart slip spin", and report.
```

### Prompt 5 (Step 3.1): Immediate Reroute on `hazard_spawned` & Despawn Re-evaluation

```text
Context: Rivals feature 03-hazard_detection. Read AGENTS.md, docs/features/rivals/03-hazard_detection/01-spec.md §3 (Reaction Logic), and docs/CONTRACTS.md §3.
Task: Trigger immediate out-of-band decision ticks when an incoming hazard threatens the current path, and re-evaluate when a blocking hazard despawns.
Files: Edit `systems/rivals/bot_controller.gd` and `tests/rivals/test_bot_hazard_detection.gd`.
Test first: In `tests/rivals/test_bot_hazard_detection.gd`, write:
  - `test_immediate_reroute_on_threatening_hazard_spawn`: Bot is driving toward Target A. Emit `RoundManager.hazard_spawned` with a hazard intersecting the route to Target A. Assert that `_evaluate_decisions()` executes immediately without waiting for the 0.3 s timer, switching to safe Target B.
  - `test_distant_hazard_spawn_does_not_interrupt_target`: Emit `RoundManager.hazard_spawned` with a hazard far away from the bot's route. Assert that `active_target` is NOT cleared and target remains Target A.
  - `test_hazard_despawn_triggers_reevaluation_if_holding`: When a bot is holding (`target_position == Vector3.ZERO`), freeing a blocking hazard triggers `_evaluate_decisions()`.
Run headless GUT and confirm failures.
Implement: In `systems/rivals/bot_controller.gd`:
  - In `_on_hazard_spawned(hazard: Node3D)`:
    - After registering the hazard, if `active_target != null` or `target_position != Vector3.ZERO`:
      - Check if the new hazard is within its danger radius of `target_position` or intersects the current navigation path.
      - If compromised: clear `active_target`, call `_evaluate_decisions()`, and restart `decision_timer`.
  - In `_on_hazard_tree_exited(hazard: Node3D)`:
    - After removing the hazard, if `state == AIState.BANKING` or `target_position == Vector3.ZERO`:
      - Call `_evaluate_decisions()` and restart `decision_timer`.
Finish: Run the full GUT suite headless and confirm all pass. Tick Step 3.1 in `docs/features/rivals/03-hazard_detection/03-todo.md`, commit "rivals: trigger immediate rerouting on threatening hazard spawns", and report.
```

### Prompt 6 (Step 3.2): Banking Checkout Standoff & Desperation Rush

```text
Context: Rivals feature 03-hazard_detection. Read AGENTS.md, docs/features/rivals/03-hazard_detection/01-spec.md §3 (Banking Standoff), and docs/CONTRACTS.md §3.
Task: Implement safe standoff outside blocked checkout zones with a final-call desperation rush override ($\le 5.0\text{ s}$).
Files: Edit `systems/rivals/bot_controller.gd` and `tests/rivals/test_bot_hazard_detection.gd`.
Test first: In `tests/rivals/test_bot_hazard_detection.gd`, write:
  - `test_banking_standoff_outside_hazard`: Cart has full inventory (state = BANKING) and checkout path is blocked by a puddle with `RoundManager.time_left = 15.0`. Assert that `target_position` stops at least 2.5 m outside the hazard, or throttle is set to 0.0 to hold position.
  - `test_banking_desperation_rush_at_final_call`: Checkout path is blocked by a puddle, but `RoundManager.time_left = 4.0` ($\le 5.0\text{ s}$). Assert that bot ignores the hazard, sets `target_position` directly to checkout, and drives forward with full throttle.
Run headless GUT and confirm failures.
Implement: In `systems/rivals/bot_controller.gd`:
  - Define `const CHECKOUT_STANDOFF_DISTANCE: float = 3.0` and `const CHECKOUT_DESPERATION_TIME: float = 5.0`.
  - In `_evaluate_decisions()` under `state == AIState.BANKING`:
    - If `RoundManager.time_left <= CHECKOUT_DESPERATION_TIME`:
      - `target_position = RoundManager.get_checkout_position()` (rush mode).
    - Else:
      - Check if path to `RoundManager.get_checkout_position()` intersects any active hazard.
      - If blocked: compute standoff coordinate 3.0 m upstream of the nearest hazard or clamp `target_position` outside the danger zone; if bot is already at standoff, stop throttle.
Finish: Run the full GUT suite headless and confirm all pass. Tick Step 3.2 in `docs/features/rivals/03-hazard_detection/03-todo.md`, commit "rivals: implement checkout standoff and desperation rush", and report.
```

### Final prompt (Step 4.1): Wire into the Rivals Test Scene

```text
Context: All hazard detection logic and unit tests are complete. Wire mock hazards into `systems/rivals/test/rivals_test.tscn` to enable visual and interactive verification.
Task: Update `systems/rivals/test/rivals_test.tscn` (and `systems/rivals/test/rivals_test.gd` if applicable) to instance mock hazard zones in aisles and in front of checkout.
Files: Edit `systems/rivals/test/rivals_test.tscn`, `systems/rivals/test/rivals_test.gd`.
Implement:
  - Add mock hazards (Area3D / visual discs representing puddles or pallet blockers) in test aisles.
  - Provide a toggle key or UI button to spawn/despawn a hazard directly in front of an active rival cart.
  - Add a toggleable puddle in front of the checkout pad to observe checkout standoff vs. final call rush.
Verify: Run the full GUT suite headless, open the test scene, and perform the manual checks from 01-spec.md §7:
  1. Observe bot steering into an adjacent aisle when an aisle pickup is blocked by a hazard.
  2. Spawn a hazard in front of an approaching bot; observe immediate swerve/reroute.
  3. Observe banking bot stopping before a puddle blocking checkout, then rushing through when round time drops $\le 5.0\text{ s}$.
Finish: Tick Step 4.1 and all acceptance criteria in `docs/features/rivals/03-hazard_detection/03-todo.md`, commit "rivals: wire hazard detection into rivals test scene", update `docs/PROGRESS.md`, and report.
```

## 4. Improvements and bugs

1. *Dynamic obstacle avoidance against moving rivals (RVO)*: Tracked in backlog; moving obstacles will be addressed in future iterations.
