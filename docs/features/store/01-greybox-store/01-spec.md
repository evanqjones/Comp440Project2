# 01-greybox-store: Spec

| | |
|---|---|
| System / Owner | Store / Anthony |
| Branch | `Anthony-Stores` |
| Status | Draft — awaiting Anthony's approval |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Demo: Thursday 09-24 |

## 1. Overview

Build the Demo store layout and prepare Anthony's Thursday solo-round integration.

## 2. Player-facing behavior

The store has six clearly labeled category aisles, solid shelves and walls, a front entrance, an outside checkout zone, and four non-overlapping cart starts facing into the store. A NavigationRegion3D holds a baked navigation mesh: the walkable surface bots will later use to find paths.

## 3. Rules and numbers

Sources: [GAME_SPEC.md](../../../GAME_SPEC.md) §§3, 6, 10, 12 and [ASSETS.md](../../../ASSETS.md).

- Six aisles: Produce, Bakery, Dairy, Snacks, Frozen, Electronics; colors from ASSETS.md §3.
- Four start markers indexed by cart_id 0–3, outside the doors.
- World collision layer 1; checkout trigger layer 5, detecting carts on layer 2.
- Proposed layout: parallel aisle lanes connected by front and rear cross-aisles; navigation excludes shelves and walls and connects each aisle to checkout.
- Shelf, door and checkout appearances instance Evan's fixed asset paths as Visual children. Only Sign, LeftDoor and RightDoor are accessed by gameplay code.
- Collision, markers, navigation and lighting belong to Store. Do not create substitute asset files.

## 4. Interfaces

Existing signatures: [CONTRACTS.md](../../../CONTRACTS.md).

- Uses Cart scene and profile resources by instancing; calls register_cart for each available cart through CONTRACTS.md §3.
- Implements the existing get_checkout_position getter with the actual checkout center.
- Store owns its layout references; RoundManager receives them within systems/store. No cross-owner node traversal or new shared API.
- Proposed main.tscn edit: replace the welcome screen with Store, four profiled Cart instances, and Rickey's controller/camera/HUD when those dependencies exist. Only the human controller is required for Thursday; Friday bot wiring is deferred.
- main.tscn remains unchanged until Anthony explicitly approves that edit. No project.godot or export preset changes are proposed.

**Contract changes:** None. Any newly discovered need follows §9 before implementation.

## 5. Scenes and files

- systems/store/store.tscn and store.gd: world, six aisles, doors, checkout, spawn markers and navigation.
- systems/store/round_manager.gd: existing checkout-position getter.
- systems/store/test/store_test.tscn: layout inspection scene with a fixed diagnostic camera.
- tests/store/test_store_layout.gd: layout, starts, layers and navigation reachability.
- systems/core/main.tscn and main.gd: Thursday integration, subject to explicit approval and dependency availability.

## 6. Edge cases

- Missing visual assets: record the dependency; do not commit unresolved scene references or build Evan's assets.
- Missing Player/Cart behavior: Store tests can use local test doubles, but the solo-round checkpoint remains incomplete.
- Navigation routes must run around shelves and through the open entrance, never across solid obstacles.
- Duplicate registration must not create duplicate carts.

## 7. Test plan

- Assert six category regions, four distinct starts, correct world/zone layers and an actual checkout-center getter.
- After navigation synchronization, verify routes from all starts to each aisle and checkout without crossing shelf footprints.
- In store_test.tscn inspect aisle colors/signs, shelf clearance, four starts, entrance and outside checkout.
- Once dependencies arrive, drive through every aisle and back outside in main.tscn; verify solid collisions and readable camera view.

Run the full headless GUT suite after every implementation step. Any SCRIPT ERROR or fewer executed scripts than test files is a failure, even if GUT prints success.

## 8. Out of scope

Cart movement, Player input/camera/HUD implementations, bot AI, asset creation, Friday bot integration and Final features.

## 9. Done when

- [ ] Six aisles and four starts exist; checkout position is correct; baked navigation reaches all aisles and checkout; required assets are instanced; Thursday integration is verified only after its dependencies and main.tscn approval are present.
- [ ] Full GUT suite passes with no skipped parse-error scripts.
- [ ] Anthony confirms the Store test-scene hand checks.
- [ ] Anthony's PROGRESS handoff records actual verification and dependencies.
