# 04-stage-hazards: Brainstorm

## Goal

Add visible, random stage hazards that create short, readable disruptions without changing the frozen Cart or RoundManager contracts.

## Agreed behavior

- Slippery puddles appear during active gameplay. Any cart that drives through one spins out for 3 seconds, cannot steer during the effect, and drops its carried items as normal pickups with their original identities and values.
- Falling pallets have a visible ground shadow warning for 5 seconds, then fall into the marked spot and block it for 5 seconds.
- Hazards are active in RUSH and FINAL_CALL, and hazard frequency rises each round as required by GAME_SPEC.md §7.
- Reuse `Cart.apply_slip(duration)`, `Cart.take_all_items()`, and `RoundManager.hazard_spawned(hazard)`; do not change contracts.

## Open questions / defaults for the spec

- Initial hazard cadence, escalation, and hazard lifetime will be proposed in `01-spec.md` for human approval.
- Spawn positions will come from safe Store floor points; runtime random selection avoids carts, checkout, shelves, and other active hazards.
- The puddle spin effect is Cart-owned; Store owns spawning, overlap handling, and spawning dropped ItemData back onto the floor.
