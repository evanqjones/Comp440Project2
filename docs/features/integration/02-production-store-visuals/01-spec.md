# 02-production-store-visuals: Spec

| | |
|---|---|
| System / Owner | Integration / Evan |
| Branch | `integration/02-production-store-visuals` |
| Status | Approved (2026-09-28; directly requested by Evan) |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Final |

## 1. Overview

Replace the production Store's visible greybox presentation with Evan's authored
store assets. `main.tscn` continues to instance the same Store scene, so Run
Project displays the production art without changing startup flow. All existing
collision, navigation, door animation, checkout, pickup spawning, and item
transfer behavior remains in place.

## 2. Player-facing behavior

- Show the storefront, rear fridges, tiled interior, parking lot, and painted
  stalls before and during rounds.
- Show the six aisle models and their signs at the existing shelf locations.
- Show the grand-opening banner, balloons, standees, sale displays, cash
  registers, and six parked cars in the arrangement already previewed.
- Keep the green checkout zone visible. Doors continue to open and close by
  Store phase.
- Item pickups and cart loads continue to use the existing shelf-matched item
  scenes.

## 3. Rules and numbers

| Rule / constant | Value | Source |
|---|---|---|
| Aisle art offset | `(0, 0, -5)` | Center fixture run on production collision run and shell interior |
| Aisle center x positions | `-18.75, -11.25, -3.75, 3.75, 11.25, 18.75` m | Authored aisle spacing (7.5 m) |
| Store shell floor bounds | `50.5 × 30.5 m`, centered at `(0, -5)` in X/Z | `store_shell.glb` floor foundation |
| Parking car count | 6: two of each model variant | Approved parking-car feature |
| Parking positions | Existing `grand_opening_store_preview.tscn` placements | Approved parking-car feature |
| Cart start x positions | `-3, -1, 1, 3` m; each cart's 0.4 m half-width fits within the 4 m half-width open door | Doorway playtest; `GAME_SPEC.md` §12 |
| Collision, navigation, doors, checkout | Unchanged | `CONTRACTS.md` §§2–3, 7–8 |

The production Store hides only generated presentation meshes covered by the
authored scenery. Store-owned floor, wall, and fixture collision shapes match
the shell floor extents and the visible aisle footprints. It retains collision,
navigation, and dynamic door/checkout behavior. Dynamic door panels and the
checkout marker remain visible.

## 4. Interfaces

**Uses:**
- `CONTRACTS.md` §7.1: `main.tscn` already instances the Store scene.
- `CONTRACTS.md` §7.2: visual scenes are static; gameplay collision and
  behavior remain in gameplay scenes.

**Provides / emits:** None.

**Contract changes:** None.

## 5. Scenes and files

| Path | New / changed | Purpose |
|---|---|---|
| `assets/models/store/production_store_visuals.tscn` | New | Static shell, aisle, grand-opening, and parking composition |
| `systems/store/store.tscn` | Changed | Instance authored visuals without changing `main.tscn` |
| `systems/store/store.gd` | Changed | Hide replaced placeholder meshes while retaining gameplay bodies |
| `tests/store/test_store_asset_visuals.gd` | New | Protect visual wiring and retained gameplay seams |
| `docs/ASSETS.md` | Changed | Document the production visual composition |
| `docs/PROGRESS.md` | Changed | Update Evan's progress and integration notes |

Composition:

```text
ProductionStoreVisuals (Node3D)
├── StoreShellVisual
├── AislesVisual (offset z = -5)
├── CelebrationSet
└── ParkingCars (six visual-only car scenes)
```

## 6. Edge cases

| Case | Expected behavior |
|---|---|
| Store is instantiated for GUT | Art loads and gameplay geometry remains valid |
| Decorative assets have no collision | Existing Store collision and navmesh still constrain carts and bots |
| Store starts before the first round | Shell, aisles, doors, and checkout are visible |
| A regular pickup spawns | Existing item visual and category spawn region remain active |

## 7. Test plan

**GUT tests:**
- [x] Production Store instances `ProductionStoreVisuals`.
- [x] Six parked cars remain in outer stalls and outside the center route.
- [x] Covered greybox meshes are hidden while their collision shapes stay enabled.
- [x] Dynamic doors, checkout marker, aisle regions, and pickup visuals remain available.
- [x] Cart starts clear the closed doors and fit through the 8 m open entrance.
- [x] Store floor and perimeter colliders meet the authored shell bounds; aisle fixture colliders sit under the visible racks with cart-clear lanes between them.

**Test scene checks:**
- [ ] Run `assets/test/grand_opening_store_preview.tscn`; confirm arrangement is unchanged.
- [ ] Run Project; confirm the production Store displays art before and during a round.

**Integration check:**
- [x] `systems/core/main.tscn` is unchanged; its existing Store instance receives the new visuals.
- [ ] Start a match, drive through the doorway and aisles, test a pickup and checkout, and confirm bots navigate.

## 8. Out of scope

- New item, cart, door, collision, navigation, or round behavior.
- Modifying `systems/core/main.tscn`, `project.godot`, contracts, or asset source models.
- Pushing, opening a PR, or merging this branch.

## 9. Done when

- [ ] Production Store uses the new visual composition.
- [ ] Existing gameplay bodies, navigation, doors, checkout, and pickups remain active.
- [ ] Full GUT suite passes headless.
- [ ] Run Project visual/gameplay checks pass with no new editor errors.
- [ ] `ASSETS.md` and Evan's `PROGRESS.md` document the integration.
