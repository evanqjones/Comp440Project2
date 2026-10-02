# 04-perimeter-fence: Spec

| | |
|---|---|
| System / Owner | Store / Anthony |
| Branch | `store/04-perimeter-fence` |
| Status | Approved by user (2026-10-01) |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Final |

## 1. Overview

Show a low, dark metal parking-lot fence around the complete playable Store map. The Store already creates invisible `StaticBody3D` collision boundaries in `OutOfBounds`; the new fence visuals follow those same four edges so players can see where the lot ends. Keep the existing collision as the gameplay barrier and do not change the map footprint.

## 2. Player-facing behavior

- A continuous low-poly metal fence is visible around the west, east, back, and front outer boundaries.
- Use evenly spaced vertical posts and two horizontal rails in a dark steel flat color.
- Fence height is 1.8 m, with posts spaced no more than 2 m apart.
- The existing collision boundary stops carts at the same perimeter line. The fence adds no collision bodies of its own.
- The front store entrance and checkout remain accessible; they are inside the outer perimeter.

## 3. Rules and numbers

| Rule / constant | Value | Source |
|---|---:|---|
| Fence height | 1.8 m | User-selected low parking-lot fence; proposed default |
| Maximum post spacing | 2.0 m | Proposed visual spacing |
| Fence sides | 4 continuous sides | Existing `OutOfBounds` geometry in `systems/store/store.gd` |
| Collision | Existing four outer `StaticBody3D` barriers | Existing Store implementation |

The fence visual aligns with the current outer barriers at x = ±30.25 m, z = −20.5 m, and z = 40.125 m. Keep the existing ground, barriers, and navigation unchanged.

## 4. Interfaces

**Uses:**
- No cross-system contract calls are required.

**Provides / emits:**
- No API or signals.

**Contract changes:** None.

## 5. Scenes and files

| Path | New / changed | Purpose |
|---|---|---|
| `systems/store/store.gd` | Changed | Build the fence visual alongside the existing outer collision boundary. |
| `tests/store/test_store_layout.gd` | Changed | Assert the fence visual exists and the perimeter remains collidable. |
| `docs/features/store/04-perimeter-fence/` | New | Brainstorm, approved spec, plan, and checklist. |

The new `MeshInstance3D` visual is a child of the existing `OutOfBounds` node. It uses flat-color Store-owned geometry and does not add physics bodies or alter the `ProductionStoreVisuals` assets.

## 6. Edge cases

| Case | Expected behavior |
|---|---|
| Cart reaches any of the four map edges | Existing collision stops it; fence makes the edge visible. |
| Fence meets at a corner | Rails/posts meet or overlap slightly; no visible gap large enough to suggest an opening. |
| Production Store hides placeholder geometry | Fence stays visible because it is a new child of `OutOfBounds`, not placeholder floor or aisle art. |
| Checkout and entrance routes | Remain open; fencing stays only at the existing outer perimeter. |

## 7. Test plan

**GUT tests:**
- [ ] `test_perimeter_fence_visual_covers_outer_boundary`: the Store creates one visible fence mesh beneath `OutOfBounds`.
- [ ] `test_perimeter_fence_keeps_all_existing_outer_collisions`: physics queries at west, east, back, and front still hit the existing layer-1 barriers.

**Test scene checks:**
- [ ] Run `systems/store/test/store_test.tscn`; confirm the fence reads as a continuous perimeter and does not obscure the Store or checkout.
- [ ] Drive a cart toward each edge; confirm it visibly stops at the fence.

**Integration check:**
- [ ] Run the main game and verify the fence remains visible with production Store art; try the front checkout approach and each outer edge.

## 8. Out of scope

- Changing collision extents or Store ground bounds.
- Adding a fence gate, opening animation, additional boundaries, navigation changes, or a new asset pack.

## 9. Done when

- [ ] Continuous low metal fence visuals follow all four existing map edges.
- [ ] Existing collision still prevents carts from leaving the map, with no new route blockage.
- [ ] Full GUT suite passes without skipped parse-error scripts.
- [ ] Store test scene and main-game visual checks are complete.
