# 02-inventory: Brainstorm

| | |
|---|---|
| System | Cart |
| Owner | Rickey |
| Branch | `cart/02-inventory` (stacked on `player/01-controller-camera`, PR #5, which is on #4) |
| Agent | Claude Code |
| Date | 2026-09-24 |
| Milestone | Demo (Fri 09-25) |

## Goal

Carts carry groceries: pick up to 24 items, get slower as they fill, show the haul as stacked cubes, and hand it all over at checkout. It unblocks Anthony's pickups and checkout, and gives John's bots the "cart is full" signal.

## Grounding

- `GAME_SPEC.md` §4.2: 24-item cap, 1.2% slowdown per item (~29% when full), items shown stacked in the basket, total value tracked
- `GAME_SPEC.md` §5.5: a stunned cart still collects pickups
- `GAME_SPEC.md` §6: item values and colors by aisle; Deal of the Day is gold, $100
- `CONTRACTS.md` §2: `try_add_item(item) -> bool` (false if full or gameplay inactive), `take_all_items() -> Array[ItemData]`, `item_collected(cart, item)`, `cart_full(cart)`; §3.1 pickup flow (Store's Pickup calls `try_add_item`); §3.2 deferred checkout calls `take_all_items`; §8 invariants 1, 4, 5
- `ASSETS.md` §3 palette; §5: the cart visual's `ItemStack` marker
- `cart/01-movement`: top speed already uses the item count; overspeed eases down at 4 m/s²

## Q&A

1. **Q:** How do carried items show before Evan's models exist?
   **A:** Colored cubes stacked at the cart's `ItemStack` spot, in aisle palette colors (gold for a Deal). · *why:* you can read a rival's haul and value at a glance, which drives "who do I rob". Swap in Evan's models later.
2. **Q:** How do you hand-test before Anthony's store exists?
   **A:** Test-only pickups (30, respawning) and a checkout pad in the cart test scene. · *why:* you can feel the cap, the slowdown and the cubes by driving, today.
3. **Q:** What does `try_add_item` refuse?
   **A:** Refuses when full (24), when the round isn't active, when the item is null, or when it's the same item already in this cart. **A stunned cart still collects.** · *why:* matches the contract and §5.5; the duplicate guard protects invariant 1 if a pickup double-fires.
4. **Q:** When does `cart_full` fire?
   **A:** Once each time the count reaches 24 (from pickups now, inheritance later). It fires again after dropping below and refilling. · *why:* one clean "go bank" event for bots and one HUD flash.

## Decisions

- A pure `CartInventory` helper (like `CartMotion`) holds the list; `cart.gd` adds round gating, signals and visuals.
- `item_cap = 24` lives in `CartTuning` (keeps the "big basket" stretch cheap).
- `take_all_items()` returns items oldest first and isn't phase-locked (Store's deferred checkout can run just after close, invariant 4). `cart/03` uses the same order for spills.
- Signal order on a successful pickup: `item_collected`, then `cart_full` if it just reached 24.
- Log D-018 (rejection rules, `cart_full` timing, oldest-first order).

## Contract changes needed

- None. All behavior is within `CONTRACTS.md` v0.1 §2.

## Open questions

- None blocking.

## Out of scope

- Ram-steal, transfer and spills (`cart/03`), HUD (`player/02`), Evan's item models, Deal of the Day spawning (Store, Final).
