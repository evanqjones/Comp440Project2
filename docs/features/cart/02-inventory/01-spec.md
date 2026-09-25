# 02-inventory: Spec

| | |
|---|---|
| System / Owner | Cart / Rickey |
| Branch | `cart/02-inventory` |
| Status | Draft, awaiting Rickey's approval |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Demo (Fri 09-25) |

## 1. Overview

Each cart holds up to 24 `ItemData` in pickup order, shows them as colored cubes in the basket, slows by 1.2% per item, and gives them all up at checkout. The list lives in a pure `CartInventory` helper. `cart.gd` adds the round-phase check, the signals and the visuals.

## 2. Player-facing behavior

- Driving over a pickup during the round adds it to your cart: a colored cube appears in the basket (green produce, orange bakery, white dairy, red snacks, blue frozen, purple electronics, gold Deal of the Day).
- Every item makes the cart 1.2% slower. A full cart (24) tops out at about 10.7 m/s instead of 15. When an item pushes you over the new top speed, you ease down rather than snapping.
- At 24 items the cart is full: further pickups stay on the floor.
- During countdown, after close and during results, pickups stay on the floor.
- A stunned cart still collects (you can grab back your spill).
- Checking out empties the cart (the cubes disappear) and returns everything to Store.

## 3. Rules and numbers

| Rule / constant | Value | Source |
|---|---|---|
| `CartTuning.item_cap` | 24 | GAME_SPEC §12 |
| Slowdown per item | 1.2% (already in `CartMotion.top_speed`) | GAME_SPEC §12 |
| Cube size / spacing | 0.22 m / 0.24 m | Brainstorm Q1 |
| Stack layout | 3 across (x) × 2 deep (z) × 4 high (y) = 24, filled bottom layer first, row by row | Brainstorm Q1 |
| Cube colors | `ASSETS.md` §3: produce `#4CAF50`, bakery `#FF9800`, dairy `#F5F5F5`, snacks `#E53935`, frozen `#1E88E5`, electronics `#8E24AA`, Deal `#E6B422` | ASSETS §3 |

**`CartInventory`** (`class_name CartInventory extends RefCounted`):
- `_init(capacity: int)`
- `try_add(item: ItemData) -> bool`: false if `item == null`, `is_full()`, or `has(item)`; otherwise appends and returns true
- `take_all() -> Array[ItemData]`: returns the items in the order added (oldest first) and empties
- `items() -> Array[ItemData]` (copy), `count() -> int`, `value() -> int` (sum of `value`), `is_full() -> bool`, `has(item: ItemData) -> bool` (same instance)

**`Cart`** (contract signatures unchanged):
- `try_add_item(item)`: if `not RoundManager.is_gameplay_active()` → false. Else if `_inventory.try_add(item)` is false → false. Else update cubes, emit `item_collected(self, item)`, and if `_inventory.is_full()`, emit `cart_full(self)`. Return true. (Stun is not checked.)
- `take_all_items()`: `_inventory.take_all()`, update cubes, return the items. Works in any phase.
- `get_state()`: `items` = copy, `value` = sum (from the inventory).
- `reset_for_round()`: empties the inventory and the cubes.
- Top speed uses `_inventory.count()`.

**Why `cart_full` fires once:** it only fires on a successful add that reaches the cap, so it can't fire while already full. Emptying and refilling fires it again.

## 4. Interfaces

**Uses:** `RoundManager.is_gameplay_active()` (`CONTRACTS.md` §3); `ItemData` (§1.3); `GameTypes.Category` (§1.1).

**Provides / emits:** `try_add_item`, `take_all_items`, `get_state().items/.value`, `item_collected`, `cart_full`, as in `CONTRACTS.md` §2 with the rules above. Internal for `cart/03`: `_inventory` (oldest-first order).

**Contract changes:** none.

## 5. Scenes and files

| Path | New / changed | Purpose |
|---|---|---|
| `systems/cart/cart_inventory.gd` | New | `CartInventory` |
| `systems/cart/cart_item_stack.gd` | New | `class_name CartItemStack extends Node3D`: `show_items(items: Array[ItemData])` rebuilds the cubes |
| `systems/cart/cart_tuning.gd` / `.tres` | Changed | `item_cap: int = 24` |
| `systems/cart/cart.gd` | Changed | Uses `CartInventory` + `CartItemStack`, real `try_add_item` / `take_all_items` |
| `systems/cart/cart.tscn` | Changed | `Visual/ItemStack` marker (y = 1.0, on top of the placeholder); `ItemStackDisplay` (`CartItemStack`) as a child of the Cart root |
| `systems/cart/test/test_pickup.gd`, `test_checkout_pad.gd` | New | Test-only pickup and checkout pad |
| `systems/cart/test/cart_drive_test.gd` | Changed | Spawns 30 test pickups + a pad; readout adds items, value, top speed, banked $ |
| `tests/cart/test_cart_inventory.gd` | New | GUT tests |

`ItemStackDisplay` follows the `Visual/ItemStack` marker's position each time it rebuilds, so Evan's model can move the marker without code changes. If the marker is missing, it uses (0, 1.0, 0).

Test pickups (test-only): an `Area3D` on layer 3 with mask 2. Each has a random category using the GAME_SPEC §12 weights (30/25/25/12/6/2) and the matching value ($5/$10/$10/$15/$20/$40), plus a unique `item_id` from a counter. On a `Cart` entering, it calls `try_add_item`. If that returns true, it hides and respawns with a new item after 3 s. Checkout pad: an `Area3D` that calls `take_all_items` on a `Cart` entering and adds the value to a banked total.

## 6. Edge cases

| Case | Expected behavior |
|---|---|
| 25th item | Refused; stays on the floor; `cart_full` not re-emitted |
| Same `ItemData` offered twice | Second call refused |
| `null` item | Refused |
| Round not active | Refused (nothing changes, no signals) |
| Stunned cart | Collects normally |
| `take_all_items` on an empty cart | Returns `[]`, no errors |
| `take_all_items` after close | Works (Store's deferred checkout) |
| Empty to 24, checkout, back to 24 | `cart_full` fires twice total |
| 24 items at 15 m/s | Eases down to ~10.68 m/s at 4 m/s² |

## 7. Test plan

**GUT, `tests/cart/test_cart_inventory.gd`:**
- [ ] `test_inventory_holds_24_then_refuses`
- [ ] `test_inventory_refuses_null_and_duplicates`
- [ ] `test_inventory_take_all_is_oldest_first_and_empties`
- [ ] `test_inventory_value_and_count`
- [ ] `test_cart_refuses_when_round_not_active`
- [ ] `test_cart_collects_while_stunned`
- [ ] `test_item_collected_emitted_with_cart_and_item`
- [ ] `test_cart_full_emitted_once_at_24_and_again_after_refill`
- [ ] `test_take_all_items_returns_same_instances_and_empties`
- [ ] `test_state_items_copy_and_value`
- [ ] `test_reset_for_round_empties`
- [ ] `test_stack_shows_one_cube_per_item`
- [ ] `test_full_cart_tops_out_near_10_7` (physics frames)

**Test scene hand checks** (`cart_drive_test.tscn`, Cmd+R):
- [ ] Driving over pickups adds colored cubes; the count and value go up
- [ ] At 24 you can't pick up more, and the cart is noticeably slower (~10.7 m/s)
- [ ] Driving onto the green pad empties the cart and adds to banked $

## 8. Out of scope

Ram-steal, transfer and spills (`cart/03`), HUD (`player/02`), Evan's item models, Deal of the Day spawning.

## 9. Done when

- [ ] All §7 GUT tests pass with the existing 44; full suite headless, no `SCRIPT ERROR`, `Scripts` count = number of test files
- [ ] Rickey confirms the hand checks
- [ ] D-018 logged; PROGRESS Cart handoffs for Anthony and John
- [ ] PR opened (stacked on #5; reviewer: Anthony)
