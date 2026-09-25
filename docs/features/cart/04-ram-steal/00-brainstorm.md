# 04-ram-steal: Brainstorm

| | |
|---|---|
| System | Cart |
| Owner | Rickey |
| Branch | `cart/04-ram-steal` (stacked on `cart/03-shopper`, PR #7 → #6 → #5 → #4) |
| Agent | Claude Code |
| Date | 2026-09-24 / 25 |
| Milestone | Demo (Fri 09-25) |

## Goal

The inheritance mechanic. When a fast cart rams a slower loaded cart, the winner inherits the haul, the overflow spills, and the loser tips over for a moment. It must resolve **exactly once** per contact and conserve every item, because the GDD predicts this is the seam that breaks first (`GAME_SPEC.md` §11.2).

## Grounding

- `GAME_SPEC.md` §5.1: the faster cart wins only if it's going ≥ 5 m/s **and** ≥ 1.5 m/s faster, compared at contact. The loser loses all items (up to the winner's 24 cap), is knocked back, stunned 0.7 s, immune 1.6 s. Speeds too close means both bounce and nothing changes hands. Each contact resolves exactly once.
- `GAME_SPEC.md` §5.2: overflow spills as normal pickups (Store spawns them); the order must be deterministic (oldest first).
- `GAME_SPEC.md` §5.3: worked example. Rita 20 items ($260) at 14 m/s rams you, 8 items ($110) at 6 m/s. Rita ends with 24 ($310), you with 0, and the floor gets 4 items ($60); the total of $370 is conserved. Rita goes 14 → 10.5 m/s.
- `GAME_SPEC.md` §5.5 defaults: empty loser = bounce; winner full = everything spills; steal before checkout; contacts after close are ignored.
- `CONTRACTS.md` §2: `cart_robbed(winner, loser, items, spilled)` emitted once per steal after both inventories update; Rickey picks which cart emits. §8 invariants 1, 2, 4, 6.
- Earlier features: `_speed_before_move` (cart/01, D-017), inventory oldest first (cart/02, D-018), reverse ≤ 4 m/s (never steals).

## Q&A

1. **Q:** What happens to motion on a steal?
   **A:** GDD-style: the winner keeps 75% of its speed; the loser is shoved away at 4 m/s (below 5, so it can't chain-steal) and slides for the 0.7 s stun with no control.
2. **Q:** A bump that doesn't qualify?
   **A:** Push apart: each cart is pushed 2 m/s away along the contact and keeps 70% of its speed. No stun, no items.
3. **Q:** Edge rules?
   **A:** The fair set: an immune cart can't be robbed but can rob others; a stunned cart can't win a steal; hitting an empty cart is just a bounce (no stun, no signal); bots and the player follow identical rules.
4. **Q:** How does the stunned cart look?
   **A:** The robbed cart **tips over onto its side** for the stun, and its **items fly into the winner's cart** (Rickey will share an artifact demo to match).
5. **Q:** What about the shopper on a tip-over?
   **A:** **Both fall over:** the whole `Visual` (cart and shopper) rolls onto its side, then pops back up.
6. **Q:** How do the items fly?
   **A:** Quick arcs, landing one by one: each transferred item flies as its colored cube in a ~1 m arc (0.4 s, staggered 0.03 s), and the winner's stack fills as each lands. Spilled items are Store's (they appear via the spill spawner).
7. **Q:** Hand-test setup?
   **A:** Parked targets (20 items, 8 items, empty) and a scripted rammer at ~12 m/s. R resets.

## Decisions

- A pure `CartSteal` helper decides the winner and splits the loot; `cart.gd` detects contacts, applies results, and drives visuals.
- Detection: after `move_and_slide()`, check slide collisions with other `Cart`s. **Whichever cart detects the contact resolves it** (a parked cart can't detect being hit). A pair lock (0.2 s per pair) guarantees one resolution per contact.
- **The loser emits `cart_robbed`** (the cart that was robbed). Logged as D-019.
- The data moves instantly (invariants hold at every moment); the flight and tip-over are visual only.
- New tuning numbers go in `CartTuning` and GAME_SPEC §12.

## Contract changes needed

- None. (Choosing the emitting cart is left to Rickey by `CONTRACTS.md` §2.)

## Open questions

- Rickey's artifact demo for the flight and tip-over look: match it when shared.

## Out of scope

- Spill spawning and positions (Store), popups, camera shake, sounds (Player, Final), bot retargeting (Rivals), Evan's models.
