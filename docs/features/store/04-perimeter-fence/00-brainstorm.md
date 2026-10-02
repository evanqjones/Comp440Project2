# 04-perimeter-fence: Brainstorm

| | |
|---|---|
| System | Store |
| Owner | Anthony (Store) |
| Branch | `store/04-perimeter-fence` |
| Agent | Codex |
| Date | 2026-10-01 |
| Milestone | Final |

## Goal

Make the existing map edge obvious to the player and keep carts inside the playable lot. The Store already has invisible collision boundaries; this feature adds matching visible perimeter fencing without changing those gameplay bounds.

## Grounding

- `GAME_SPEC.md` §9.1: art direction is low-poly shapes and bright flat colors.
- `GAME_SPEC.md` §10: Store owns the level layout and collision.
- `CONTRACTS.md` §3: no contract API is needed; the fence uses existing Store world geometry.

## Q&A

1. **Q:** What fence style should mark the existing map perimeter?
   **A:** Low metal parking-lot fence. *Why:* it fits the asphalt parking area and low-poly art direction.

## Decisions

- Place visible metal fence geometry along the four existing outer `OutOfBounds` boundaries.
- Retain the existing collision barriers and their positions; add no gameplay gaps at the perimeter.
- Keep the checkout approach, storefront entrance, and parking stalls inside the fence.
- Build simple flat-color geometry in Store code; add no asset pack, contract, or new external asset dependency.

## Contract changes needed

- None.

## Open questions

- None.

## Out of scope

- Changing the map footprint, collision dimensions, Store entrances, checkout flow, or navigation.
- Adding a gate animation, fence damage, or other gameplay interaction.
