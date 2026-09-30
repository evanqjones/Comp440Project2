# 04-stage-hazards: Spec

| | |
|---|---|
| System / Owners | Integration: Store (Anthony) + Cart (Rickey); hazard visuals (Evan) |
| Branch | `integration/04-stage-hazards` |
| Status | Approved by Evan (2026-09-30) |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Final |

## 1. Overview

Add two random environmental hazards to the production Store: slippery puddles and falling pallets. They are readable, avoidable disruptions that make the stage itself a fourth source of competition.

## 2. Player-facing behavior

- Hazards spawn only during RUSH and FINAL_CALL. Every spawn is announced through the existing `RoundManager.hazard_spawned` signal so Player audio and Rivals rerouting can react.
- A puddle appears in a valid floor location. A cart crossing it spins out for 3 seconds: steering is ignored while the cart rotates in place. The effect triggers once per cart per puddle. The cart's entire current inventory is dropped around it as ordinary pickups; the same `ItemData` objects, IDs, values, and deal flags are preserved.
- During the rapid spin-out, the player's chase camera keeps its heading steady while following the cart's position, then smoothly resumes following the cart's facing when the spin ends.
- A falling pallet's ground shadow appears at the landing location 5 seconds before impact. The pallet then falls into the marked location and blocks that location for 5 seconds. Carts cannot pass through the landed pallet; it is removed when the block ends.
- Both hazards affect player and bot carts. Bots receive the same physical effects and can reroute from `hazard_spawned`.

## 3. Rules and proposed numbers

Sources: `docs/GAME_SPEC.md` §§7, 10, 12; requested behavior in this spec.

- Randomly choose between puddle and falling pallet at each hazard spawn. Avoid consecutive same-type hazards when both types have valid spawn locations.
- Proposed cadence: first hazard after 8 active gameplay seconds, then a random 10–16 active seconds between hazards. Reduce the interval by 2 seconds per round, with a 6-second minimum. No catch-up spawns after inactive time or when no valid spawn location exists.
- Proposed puddle lifetime: 12 seconds, or until removed after affecting all four carts (whichever comes first).
- Puddle slip duration: 3 seconds; steering locked, clockwise spin at 360°/second, then normal control resumes. Inventory drops once on entry.
- Pallet warning: 5 seconds; obstacle block after landing: 5 seconds.
- Per-cart overlap guards prevent re-triggering from one puddle. Round end removes active hazards and cancels pending pallet drops.
- Hazard spawn points are authored on open Store floor areas. Runtime selection rejects locations too close to walls/shelves, checkout, a cart, or another active hazard.

## 4. Interfaces

- Uses existing `Cart.apply_slip(duration)` and `Cart.take_all_items()` methods, plus `Cart.get_state()` / registered carts for placement. Store does not mutate Cart inventory directly.
- Store creates normal `Pickup`s for all returned dropped items, preserving object identity and match IDs. These environmental drops ignore the regular floor cap, consistent with ram-steal spills.
- Emits existing `RoundManager.hazard_spawned(hazard)` when the hazard becomes visible. No signatures in `docs/CONTRACTS.md` or `systems/shared/` change.
- Store handles hazard cadence, locations, overlap, floor blockers and cleanup. Cart implements steering lock/spin and its duration timer. Player's chase camera holds its heading during the fast spin and eases back afterward.
- Visual scenes are visual-only assets under `assets/models/hazards/`; Store hazard scenes own Area3D/StaticBody3D collision and behavior.

**Contract changes:** None. The existing API provides each required seam.

## 5. Scenes and files

- `systems/store/round_manager.gd`: random schedule, escalating cadence, cleanup on round transitions, and existing hazard signal.
- Store-owned hazard scenes/scripts under `systems/store/hazards/`: puddle trigger and pallet warning/drop/block lifecycle.
- Store floor scene: authored valid spawn markers, collision for landed pallets, hazard visuals.
- `systems/cart/cart.gd`: implement the existing `apply_slip(duration)` stub as a steering lock plus controlled spin-out; repeated calls extend, not stack, the effect.
- `assets/models/hazards/slippery_puddle_visual.tscn`: puddle-only visual, no behavior or collision.
- `assets/models/hazards/falling_pallet_visual.tscn`: pallet-only visual, no behavior or collision.
- Focused GUT coverage under `tests/store/` and `tests/cart/`; update relevant feature TODO and owner handoffs.

## 6. Edge cases

- Dropped items preserve each original `ItemData` identity and value; no item is duplicated or lost.
- One puddle can affect each cart at most once. Inventory is emptied once per contact.
- A full floor-item registry does not suppress dropped inventory.
- A cart already slipping when it hits another puddle does not get its inventory duplicated; the additional contact refreshes the slip timer but does not drop already-empty contents again.
- If a cart leaves the tree or round closes during a slip, the effect expires/clears without leaving input locked in the next round.
- Pallet collision is enabled only after the warning completes; removal and collision changes use deferred physics-safe operations.
- If no safe spawn point exists, the scheduler skips that event and tries again after the next interval.
- Ending/restarting a round frees warnings, puddles, landed pallets, and their timers.

## 7. Test plan

- Test hazard cadence, round escalation, inactive phases, no catch-up spawns, valid-point rejection, and hazard signal emission.
- Test puddle affects a cart once, calls slip for 3 seconds, drops all item instances exactly once, and preserves item IDs/values through pickup spawning.
- Test repeated puddle entry and multiple carts without duplicate drops.
- Test pallet shadow-to-impact delay (5 seconds), blocker lifetime (5 seconds), and cleanup at round end.
- Test the Player chase camera holds its heading during the 360°/second spin and resumes tracking afterward.
- In the Store hazard test scene, inspect warning visibility, puddle visibility, falling/landed pallet collision and placement. Hand-check player and bot response in the production game.
- Run full headless GUT and inspect output for `SCRIPT ERROR` and skipped test files before claiming completion.

## 8. Out of scope

Pallet knockback or item spill, moving pallet jacks, changing the contract, HUD hazard icons, and new Player audio.

## 9. Done when

- [ ] Both hazards spawn at approved cadence in valid Store floor locations and escalate by round.
- [ ] Puddles cause a 3-second cart spin-out and preserve every dropped item exactly once.
- [ ] Pallets show a 5-second shadow, land, block for 5 seconds, and are removed safely.
- [ ] Existing bot hazard rerouting receives `hazard_spawned`.
- [ ] GUT passes with no script errors or skipped scripts; gameplay hand-checks are recorded.
