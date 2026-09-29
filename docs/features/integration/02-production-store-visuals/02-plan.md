# 02-production-store-visuals: Plan

| | |
|---|---|
| System / Owner | Integration / Evan |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |

## 1. Blueprint

- Compose the shell, aisle, grand-opening, and parking scenes into one reusable
  production visual scene.
- Write Store integration tests first for the composed art and preserved
  gameplay seams.
- Instance the composition in Store and hide only generated presentation meshes
  that it replaces.
- Run GUT, run the actual main scene, and verify gameplay interactions and bots.
- Update the asset manifest and Evan's progress notes with the result.

## 2. Iterations and steps

### Iteration 1: Production Store art

- **Step 1.1:** Compose and instance authored visuals, hide covered greybox
  meshes, preserve collision/navigation/gameplay, and fit the four starts through
  the open doorway. Test: Store GUT verifies the visual composition, hidden-mesh/
  active-collision boundary, and start clearance.
- **Step 1.2:** Match Store-owned floor, perimeter, and fixture colliders to the
  authored shell and aisle footprints. Test first: assert the 50.5 × 30.5 m
  shell floor, 7.5 m aisle centers, 14 m shelf runs, and collision rows centered
  on the visible fixtures. Preserve open lanes and the 8 m entrance.
- **Step 1.3:** Place grand-opening props beyond the storefront while keeping
  registers inside; add invisible lot-edge and rear-fridge collision barriers.
  Test first: assert each display's side of the storefront, register positions,
  solid collision at each boundary/fridge wall, and cart clearance in front of
  the fridge bank.
- **Step 1.4:** Follow the playtest correction: move the two sale displays and
  two cutout standees to the rear interior corridor. Close the side approaches
  around the store, support the reachable lot edges, and verify a moving cart
  cannot pass or fall below the south and side barriers. Keep entrance access.
  Test first with cart-sized physics queries and a real Cart drive against edges.

### Iteration 2: Verify and record

- **Step 2.1:** Run full GUT and Run Project, inspect logs, verify the separate
  preview, and update asset/progress notes.

## 3. Prompts

### Prompt 1 (Step 1.1): Wire production visuals

```text
Context: Integration feature 02-production-store-visuals. Read AGENTS.md,
01-spec.md, 02-plan.md, and CONTRACTS.md §§2–3, 7–8.
Task: Test first, compose the authored store visuals, then instance them in
systems/store/store.tscn. Hide replaced placeholder render meshes only; preserve
all collision bodies, navigation sources, door visuals/animation, checkout, and
pickup behavior. Do not change main.tscn or contracts.
Files: tests/store/test_store_asset_visuals.gd, assets/models/store/
production_store_visuals.tscn, systems/store/store.tscn, systems/store/store.gd.
Test first: Assert the production composition, six outer-stall cars, hidden
replaced placeholder meshes, enabled collisions, visible dynamic doors and
checkout, category spawn regions, and cart-width doorway clearance. Run and
confirm the new assertions fail.
Implement: Use the positions from the already-approved grand-opening preview.
Keep production_store_visuals.tscn visual-only.
Finish: Run full headless GUT, tick Step 1.1, commit
"integration: wire store asset visuals", and stop.
```

### Prompt 2 (Step 1.2): Align gameplay collision to visible store art

```text
Context: Integration feature 02-production-store-visuals. Read AGENTS.md,
01-spec.md, 02-plan.md, 03-todo.md, and CONTRACTS.md §2–3, 7–8.
Task: Fix the production Store collision/art mismatch. Keep the visual aisle
composition centered at the same z as the gameplay fixture run, move aisle
centers and fixture collision rows to the authored 7.5 m pitch/fixture positions,
and match the production floor and walls to the store-shell GLB bounds. Leave
clear cart-sized travel lanes between shelf runs and keep physical shelves solid.
Test first: Add Store GUT assertions for shell bounds and fixture collider
centers/sizes; run them and confirm failure before implementing.
Files: tests/store/test_store_asset_visuals.gd, systems/store/store.gd,
assets/models/store/production_store_visuals.tscn, GAME_SPEC.md and Evan's
PROGRESS.md section.
Finish: Run full headless GUT and play main.tscn; verify the player cannot cross
visible shelves/walls, can drive through the aisle lanes and open entrance, and
bots still navigate. Record any limitation, tick Step 1.2, commit, stop.
```

### Prompt 3 (Step 2.1): Verify and document

```text
Context: Integration feature 02-production-store-visuals. Read AGENTS.md,
01-spec.md, and 03-todo.md.
Task: Run full headless GUT; run main.tscn; test start, movement, aisle access,
pickup, checkout, and bot navigation; inspect editor errors; confirm the separate
grand-opening preview still runs. Update docs/ASSETS.md and Evan's section of
docs/PROGRESS.md with results.
Files: docs/ASSETS.md, Evan's section of docs/PROGRESS.md,
docs/features/integration/02-production-store-visuals/03-todo.md.
Finish: Tick Step 2.1 and verification; commit "integration: verify production
store visuals", then stop. Do not push, open a PR, or merge.
```

## 4. Improvements and bugs

1. Add an authored sliding-door visual after the manifest asset exists; preserve
   the existing Store door animation contract.
