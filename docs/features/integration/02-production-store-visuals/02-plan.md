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

### Prompt 2 (Step 2.1): Verify and document

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
