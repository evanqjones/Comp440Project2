# 00-foundation: Plan

| | |
|---|---|
| System / Owner | Integration / Anthony (drafted by Rickey) |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |

## 1. Blueprint

1. **Tooling:** GUT installed, the plugin enabled, `.gutconfig.json`, one smoke test passing headless. After this, every later step can be test-first.
2. **Shared data:** `GameTypes`, `DriveCommand`, `ItemData`, then `CartState`, `RoundResults`, `ShopperProfile` + four profiles, each with tests.
3. **Stubs:** `Cart` script + scene, then `Pickup` and the `RoundManager` autoload, each with a conformance test.
4. **Project settings:** input map and physics layer names, with tests.
5. **Wrap-up:** folder skeleton, docs (GUT version, D-015, `cart.tscn` naming, PROGRESS, TODO), main scene smoke run.

## 2. Iterations and steps

### Iteration 1: Tooling
- **Step 1.1:** GUT 9.7.1 into `addons/gut/`, enable the plugin, add `.gutconfig.json`, and add `tests/shared/test_smoke.gd` → test: the suite runs headless and reports 1 passing test.

### Iteration 2: Shared data
- **Step 2.1:** `game_types.gd`, `drive_command.gd`, `item_data.gd` → tests: enum order, defaults, independent instances.
- **Step 2.2:** `cart_state.gd`, `round_results.gd`, `shopper_profile.gd`, `profiles/*.tres` → tests: defaults, profiles load.

### Iteration 3: Stubs
- **Step 3.1:** `systems/cart/cart.gd` + `cart.tscn` → test: conformance (class, signals, methods, layer) and `get_state()` returns a copy.
- **Step 3.2:** `systems/store/pickup.gd`, `systems/store/round_manager.gd` + autoload → tests: conformance and `is_gameplay_active()` per phase.

### Iteration 4: Project settings
- **Step 4.1:** input actions + physics layer names via a one-off headless setup script (not committed) → tests: actions and events exist, layer names match.

### Iteration 5: Wrap-up
- **Step 5.1:** folder skeleton, docs updates, full suite + main scene headless smoke run.

## 3. Prompts

### Prompt 1 (Step 1.1): GUT

```text
Context: integration/00-foundation. Read AGENTS.md and 01-spec.md §3, §5.
Task: install GUT 9.7.1 (github.com/bitwes/Gut tag v9.7.1) by copying only addons/gut/ into the project.
Enable the plugin in project.godot. Add .gutconfig.json that runs res://tests/ including subdirectories
and exits. Test first: tests/shared/test_smoke.gd with one passing assert. Run
godot --headless --import, then the GUT command from TECH_STACK.md; confirm 1 passing test.
Tick Step 1.1 in 03-todo.md, commit "integration: add GUT 9.7.1 test framework", stop and report.
```

### Prompt 2 (Step 2.1): enums, DriveCommand, ItemData

```text
Context: CONTRACTS.md §1.1–§1.3. Test first in tests/shared/test_contracts.gd:
test_game_types_enums, test_drive_command_defaults, test_item_data_instances_are_independent.
Watch them fail, then create systems/shared/game_types.gd, drive_command.gd, item_data.gd exactly as the contract shows
(static types, tabs). Run the full suite headless, tick 2.1, commit "integration: add GameTypes, DriveCommand, ItemData".
```

### Prompt 3 (Step 2.2): CartState, RoundResults, ShopperProfile, profiles

```text
Context: CONTRACTS.md §1.4–§1.6, GAME_SPEC.md §2.2, ASSETS.md §3 (colors). Test first: test_round_results_defaults,
test_profiles_load. Then create cart_state.gd, round_results.gd, shopper_profile.gd and
systems/shared/profiles/{player,carl,bev,rita}.tres (names, tiers, colors, blurbs from the spec; placeholder numbers).
Run the suite, tick 2.2, commit "integration: add CartState, RoundResults, ShopperProfile and profiles".
```

### Prompt 4 (Step 3.1): Cart stub

```text
Context: CONTRACTS.md §2, 01-spec.md §5 node tree. Test first: test_cart_conforms_to_contract,
test_cart_state_items_is_a_copy. Then create systems/cart/cart.gd (class_name Cart, extends CharacterBody3D,
3 signals, cart_id and profile exports, 6 methods with typed signatures; behavior-free except get_state())
and systems/cart/cart.tscn per the node tree. Run the suite, tick 3.1, commit "cart: add contract stub".
```

### Prompt 5 (Step 3.2): Pickup and RoundManager stubs

```text
Context: CONTRACTS.md §3, §3.1. Test first: test_pickup_conforms_to_contract, test_round_manager_conforms_to_contract.
Then create systems/store/pickup.gd and systems/store/round_manager.gd (no class_name), and register the
RoundManager autoload. Real logic only for register_cart/get_carts and is_gameplay_active(). Run the suite,
tick 3.2, commit "store: add RoundManager autoload and Pickup stubs".
```

### Prompt 6 (Step 4.1): input map and layers

```text
Context: 01-spec.md §3. Test first in tests/shared/test_project_setup.gd: test_input_actions_exist,
test_physics_layer_names. Then write a one-off headless script in the scratchpad (not committed) that sets the
six input actions (keyboard physical keys + gamepad events, deadzones) and layer names 1–5 through
ProjectSettings and saves. Run it, inspect the project.godot diff, run the suite, tick 4.1, commit
"integration: add input map and physics layer names".
```

### Prompt 7 (Step 5.1): wrap-up

```text
Add .gitkeep folders per 01-spec.md §5. Update the docs: GUT version in TECH_STACK.md, D-015 in DECISIONS.md
(closing Q-006), Cart.tscn → cart.tscn wherever the docs mention it, PROGRESS.md handoff notes for each
owner, tick the M0 items in TODO.md. Run the full suite (long command and .gutconfig.json) and
godot --headless --quit-after 120 on the main scene; report both outputs. Tick 5.1, commit
"integration: foundation docs and skeleton".
```

## 4. Improvements and bugs

1. (none yet)
