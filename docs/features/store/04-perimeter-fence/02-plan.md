# 04-perimeter-fence: Plan

| | |
|---|---|
| System / Owner | Store / Anthony |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |

## 1. Blueprint

- Extend the existing Store visual-boundary test to require a visible fence at `OutOfBounds` while preserving all four existing collision checks.
- Build a single combined low-poly fence mesh following the four `OutOfBounds` edges, using evenly spaced posts and two horizontal rails.
- Verify the Store inspection and production composition keep the fence visible without obstructing the entrance or checkout route.

## 2. Iterations and steps

### Iteration 1: Visible perimeter

- **Step 1.1:** Add the fence-presence and boundary-collision assertions to `test_invisible_boundaries_and_rear_fridge_barrier_stop_cart_shape`; then build the combined flat-color fence mesh under `OutOfBounds`. The test confirms the visible mesh is present and the existing collision remains at each edge.

## 3. Prompts

### Prompt 1 (Step 1.1): Visible perimeter

```text
Context: Store feature 04-perimeter-fence. Read AGENTS.md, 01-spec.md, and CONTRACTS.md §3.
Files: systems/store/store.gd, tests/store/test_store_asset_visuals.gd, docs/features/store/04-perimeter-fence/03-todo.md.
Test first: update test_invisible_boundaries_and_rear_fridge_barrier_stop_cart_shape to require one visible PerimeterFenceVisual MeshInstance3D with a committed mesh, while retaining all four cart-shape collision queries. Run the focused Store GUT test and confirm the visual assertion fails before implementation.
Implement: in Store._build_invisible_boundaries, add one combined flat-color metal fence mesh child at the same four existing extents. Use 1.8 m posts at no more than 2 m spacing and two horizontal rails. Do not add collisions or change barriers, floor, navigation, entrance, or checkout.
Wire: the Store builds its world during _ready, so the visible fence is present in both StoreTest and the production Store scene.
Finish: run full GUT headless and check for skipped or error scripts; tick Step 1.1 only with evidence, update Anthony's PROGRESS handoff, commit `store: add perimeter fence`, then stop and report the manual visual checks.
```

## 4. Improvements and bugs

1. None found during spec review.
