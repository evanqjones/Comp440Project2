# 00-foundation: Spec

| | |
|---|---|
| System / Owner | Integration / Anthony (drafted by Rickey) |
| Branch | `integration/00-foundation` |
| Status | Approved by Rickey (2026-09-23) |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | M0 Foundation |

## 1. Overview

This feature creates the code skeleton that `CONTRACTS.md` v0.1 describes. After it merges, every owner can write code against real class names, signals, and input actions, and run a GUT suite, even though no gameplay exists yet. Stubs are replaced by their owners' first features (`cart/01-movement`, `store/02-round-flow`, `store/03-spawns-checkout`).

## 2. Player-facing behavior

None. The game still opens to the placeholder main scene. Pressing play must produce **no errors** in the output.

## 3. Rules and numbers

| Item | Value | Source |
|---|---|---|
| GUT version | 9.7.1 | Brainstorm Q2 |
| Cart body | `CharacterBody3D` | Brainstorm Q1 (D-015) |
| Cart collision layer / mask | layer 2 `carts`; mask 1 `world` + 2 `carts` + 4 `hazards` | `CONTRACTS.md` §6 |
| Cart stub collision shape | Box 0.8 × 1.0 × 1.2 m (w × h × l), centered 0.5 m up | Placeholder; Rickey tunes in `cart/01` |
| Pickup layer / mask | layer 3 `pickups`; mask 2 `carts` | `CONTRACTS.md` §6 |
| Axis deadzone (steer, triggers) | 0.2 | Starting value |
| Button deadzone | 0.5 (Godot default) | — |

**Input map** (`CONTRACTS.md` §5, `GAME_SPEC.md` §8):

| Action | Keys (physical) | Gamepad |
|---|---|---|
| `drive_gas` | W, Up | Right trigger (`JOY_AXIS_TRIGGER_RIGHT`, +) |
| `drive_brake` | S, Down | Left trigger (`JOY_AXIS_TRIGGER_LEFT`, +) |
| `steer_left` | A, Left | Left stick X − (`JOY_AXIS_LEFT_X`, −1) |
| `steer_right` | D, Right | Left stick X + (`JOY_AXIS_LEFT_X`, +1) |
| `boost` | Shift, Space | A / Cross (`JOY_BUTTON_A`) |
| `pause` | Escape | Start (`JOY_BUTTON_START`) |

**Physics layer names** (3D): 1 `world`, 2 `carts`, 3 `pickups`, 4 `hazards`, 5 `zones`.

**Autoload:** `RoundManager` → `res://systems/store/round_manager.gd` (singleton enabled).

## 4. Interfaces

**Provides (exactly as `CONTRACTS.md` v0.1):**
- `systems/shared/`: `GameTypes`, `DriveCommand`, `ItemData`, `CartState`, `RoundResults`, `ShopperProfile`; `profiles/player.tres`, `carl.tres`, `bev.tres`, `rita.tres`
- `systems/cart/cart.gd` + `cart.tscn`: `Cart` stub. All three signals; `cart_id`, `profile`; all six methods. `get_state()` returns a real snapshot of the stub's fields. Other methods are no-ops returning defaults (`try_add_item` → `false`, `take_all_items` → `[]`).
- `systems/store/round_manager.gd` (autoload): all six signals, all four variables, all methods. Real: `register_cart` / `get_carts` (list), `is_gameplay_active()` (`phase` is `RUSH` or `FINAL_CALL`). Everything else returns defaults.
- `systems/store/pickup.gd`: `Pickup` extends `Area3D` with `var item: ItemData`.

**Uses:** none.

**Contract changes:** none. File-name fix `Cart.tscn` → `cart.tscn` in the docs.

## 5. Scenes and files

| Path | New / changed | Purpose |
|---|---|---|
| `addons/gut/` | New | GUT 9.7.1 |
| `.gutconfig.json` | New | Run all of `res://tests/` with subdirectories, exit when done |
| `project.godot` | Changed | Input map, physics layer names, `RoundManager` autoload, GUT plugin enabled |
| `systems/shared/*.gd`, `systems/shared/profiles/*.tres` | New | Contract data classes and shopper profiles |
| `systems/cart/cart.gd`, `systems/cart/cart.tscn` | New | Cart stub (Rickey's files from here on) |
| `systems/store/round_manager.gd`, `systems/store/pickup.gd` | New | Store stubs (Anthony's files from here on) |
| `systems/{player,cart,rivals,store}/test/.gitkeep`, `tests/{player,cart,rivals,store}/.gitkeep` | New | Folder skeleton |
| `tests/shared/test_contracts.gd` | New | Data-class tests + contract conformance tests |
| `tests/shared/test_project_setup.gd` | New | Input actions, layer names, autoload present |
| `docs/TECH_STACK.md`, `docs/DECISIONS.md`, `docs/PROGRESS.md`, `docs/TODO.md`, docs mentioning `Cart.tscn` | Changed | GUT version, D-015, handoff notes, ticks, file name |

`cart.tscn` node tree:
```
Cart (CharacterBody3D, script cart.gd, layer 2, mask 1+2+4)
├── CollisionShape3D (BoxShape3D 0.8 × 1.0 × 1.2, y = 0.5)
└── Visual (Node3D)          ← cart/01 swaps this for assets/models/cart/cart_visual.tscn
    └── PlaceholderMesh (MeshInstance3D, BoxMesh, same size)
```

## 6. Edge cases

| Case | Expected behavior |
|---|---|
| Two `ItemData.new()` | Independent instances; changing one doesn't change the other |
| `CartState.items` mutated by a reader | The cart's own list is unchanged (it's a copy) |
| `RoundManager.phase` set directly in a test | `is_gameplay_active()` follows it (tests may set it; game code must not) |
| Autoload script with `class_name` | Not allowed (clashes with the autoload name); `round_manager.gd` has none |
| Headless run with no GPU | Suite and main scene run with `--headless` without errors |

## 7. Test plan

**GUT tests** (headless):
- [ ] `test_drive_command_defaults`: all zero / false
- [ ] `test_item_data_instances_are_independent`
- [ ] `test_cart_state_items_is_a_copy`: a snapshot from `Cart.get_state()` can be mutated without affecting the cart
- [ ] `test_game_types_enums`: `Category` has 7 entries, `Phase` has 7 entries, in contract order
- [ ] `test_round_results_defaults`
- [ ] `test_profiles_load`: 4 profiles load with a name, tier, and color
- [ ] `test_cart_conforms_to_contract`: `cart.tscn` instantiates as `Cart`; has the 3 signals and 6 methods; layer 2 set
- [ ] `test_round_manager_conforms_to_contract`: autoload present; 6 signals; the variables and methods exist; `is_gameplay_active()` true only in `RUSH` / `FINAL_CALL`
- [ ] `test_pickup_conforms_to_contract`: `Pickup` is an `Area3D` with `item`
- [ ] `test_input_actions_exist`: all 6 actions, each with at least one keyboard and one gamepad event
- [ ] `test_physics_layer_names`: layers 1–5 named per contract

**Hand checks:**
- [ ] Open the project in the Godot editor: no errors in the output, GUT panel visible, `RoundManager` listed under Project Settings → Globals
- [ ] Press F5: placeholder main scene runs with no errors

## 8. Out of scope

Everything listed in the brainstorm's "Out of scope".

## 9. Done when

- [ ] All files in §5 exist and match `CONTRACTS.md` v0.1 signatures
- [ ] Full GUT suite passes headless, using both the long command and `.gutconfig.json`
- [ ] `godot --headless --quit-after 120` on the main scene prints no errors
- [ ] D-015 logged, `TECH_STACK.md` has the GUT version, `PROGRESS.md` handoff notes written for Rickey (Cart), Anthony (Store), John (Rivals), Evan (Assets)
- [ ] PR opened for Anthony's review (`project.godot` changes)
