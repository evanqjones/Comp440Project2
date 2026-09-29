# 02-production-store-visuals: Brainstorm

| | |
|---|---|
| System | Integration |
| Owner | Evan |
| Branch | `integration/02-production-store-visuals` |
| Agent | Codex |
| Date | 2026-09-28 |
| Milestone | Final |

## Goal

Show Evan's store, aisle, grand-opening, and parking assets in the production
Store used by `main.tscn`, while preserving the playable Store behavior Anthony
merged to `main`.

## Grounding

- `CONTRACTS.md` §7.1: `Main.tscn` instances the Store-owned `systems/store/store.tscn`.
- `CONTRACTS.md` §7.2 and `docs/ASSETS.md` §2: visuals are static presentation; collision and behavior stay in gameplay scenes.
- `GAME_SPEC.md` §11.2: verify the full playable round and its integration seams.

## Q&A

1. **Q:** Where should the store assets appear?  
   **A:** In the production Store instance used by `main.tscn`, using the same
   positions checked in the grand-opening preview. *why:* Evan asked to connect
   the existing assets to Anthony's merged Store.
2. **Q:** What happens to the greybox gameplay?  
   **A:** Hide only presentation meshes replaced by authored art; keep collision
   shapes, doors, checkout logic, spawn regions, and baked navigation. *why:*
   asset scenes are visual-only and gameplay must remain functional.
3. **Q:** Which assets are included?  
   **A:** Store shell and parking ground, six-aisle environment, banner,
   balloons, both standees, promo displays, cash registers, and six parked cars.
   Existing pickup-item visuals remain wired through Store's current pickup path.
4. **Q:** Should this change `main.tscn` or contracts?  
   **A:** No. Instance the visual set in `systems/store/store.tscn`; do not
   change `main.tscn`, `project.godot`, or contracts.

## Decisions

- Add one visual-only composition scene and instance it from the production Store.
- Preserve gameplay collision, navigation, doors, checkout, and item pickups.
- Keep the existing grand-opening preview as a separate playable preview.

## Contract changes needed

- None.

## Open questions

- None. Evan requested production integration after Anthony's Store changes
  landed on `main`.

## Out of scope

- New gameplay systems, collision on decorative assets, new door mechanics,
  editing `main.tscn`, or changing any contract.
