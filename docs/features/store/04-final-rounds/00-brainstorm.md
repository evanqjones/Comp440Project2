# 04-final-rounds: Brainstorm

| | |
|---|---|
| System | Store / Round Manager |
| Owner | Anthony |
| Branch | `store/04-final-rounds` |
| Agent | Codex |
| Date | 2026-09-30 |
| Milestone | Final |

## Goal

Turn the existing single-round Store into a complete three-round match, then add the Deal of the Day and escalating hazards. RoundManager remains the only writer of round state, scores, floor pickups, and hazard lifecycle.

## Grounding

- `GAME_SPEC.md` §3.2 fixes three rounds, 10-second results, stamp and match tie rules, and empty cart resets.
- `GAME_SPEC.md` §6 fixes a single $100 Deal on the floor, separate from the regular cap, every 14–22 seconds.
- `GAME_SPEC.md` §7 fixes the three hazards and the falling-display 1-second warning / 5-second block.
- `CONTRACTS.md` §§2–3 fixes `Cart.apply_slip`, `RoundResults`, `deal_spawned`, `hazard_spawned`, and RoundManager getters.

## Q&A

1. **Q:** What schedule should make hazards more frequent by round?
   **A:** One hazard at a time every 35 seconds in round 1, 25 seconds in round 2, and 15 seconds in round 3. · *why:* accepted recommended schedule gives difficulty a clear, testable escalation.
2. **Q:** How should each scheduled hazard choose its type?
   **A:** Choose wet floor, pallet jack, or falling display randomly. · *why:* accepted choice adds variety while preserving the fixed cadence.
3. **Q:** What happens when an interval expires while a hazard is active?
   **A:** Wait for it to clear, then start a fresh full interval. · *why:* preserves one active hazard and avoids surprise back-to-back spawns.
4. **Q:** What durations apply where the game spec has none?
   **A:** Wet floor lasts 8 seconds; pallet jack crosses for 6 seconds; falling display keeps the specified 1-second warning and 5-second block. · *why:* accepted recommended values are long enough to read but leave room for recovery.
5. **Q:** Where does the Deal of the Day appear?
   **A:** At a random valid regular-item spawn marker across the six aisles. · *why:* accepted recommended choice keeps it reachable without a privileged fixed location.
6. **Q:** How should remaining implementation choices be decided?
   **A:** Use the recommended option. · *why:* owner authorization for remaining defaults in this feature.

## Decisions

- A match contains exactly three rounds; every round uses the existing 3-second countdown, 120-second timer, and 10-second results duration.
- Round winners are every cart tied for the highest positive round bank; each receives one stamp.
- Match winners are every cart tied for most stamps, then highest cumulative banked value; an exact tie remains shared.
- Deal timing is randomized inclusively between 14 and 22 seconds after the prior Deal leaves the floor. It is separate from the 46 regular-pickup cap and retains `Category.DEAL`, $100 value, ID, and gold visual through a spill.
- Hazard selection is random; only one hazard is active. A blocked interval restarts after the active hazard clears.
- Hazard defaults are wet floor 8 seconds, pallet jack 6 seconds, and falling display 1-second warning plus 5-second block.

## Contract changes needed

- None. This feature uses the existing Final contracts.

## Open questions

- Evan must provide the Deal and hazard visual scenes at the manifest paths before their final visuals can be wired.
- Rickey must implement Cart's existing `apply_slip(duration)` contract for the wet-floor effect to change cart steering.

## Out of scope

- Implementing Cart slip behavior, Rival rerouting, PA/audio playback, or Asset-owned scenes.
- Stretch hazards and gameplay features.
