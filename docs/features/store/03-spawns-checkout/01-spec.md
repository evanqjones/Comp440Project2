# 03-spawns-checkout: Spec

| | |
|---|---|
| System / Owner | Store / Anthony |
| Branch | `Anthony-Stores` |
| Status | Draft — awaiting Anthony's approval |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Demo: Thursday 09-24 |

## 1. Overview

Spawn groceries, collect them, bank checkout trips and preserve spilled item identities.

## 2. Player-facing behavior

Groceries appear in their category's aisle during active gameplay. Driving over an item asks Cart to collect it. Exiting through checkout banks the cart's current haul once. Overflow reported by a Cart inheritance event reappears on the floor as the same items.

## 3. Rules and numbers

Sources: [GAME_SPEC.md](../../../GAME_SPEC.md) §§3, 6, 10, 12 and [ASSETS.md](../../../ASSETS.md).

- Values for Produce/Bakery/Dairy/Snacks/Frozen/Electronics: $5/$10/$10/$15/$20/$40.
- Spawn weights in that order: 30/25/25/12/6/2 out of 100.
- One regular spawn every 0.5 seconds during active gameplay while regular floor-item count is below 46; spills count toward that floor count and may exceed the cap.
- Proposed initial state: empty floor, first regular item after 0.5 active seconds; no catch-up burst after time spent at cap or in inactive phases.
- Each new regular item gets its own ItemData and a unique monotonically increasing item_id for the match.
- Pickup calls try_add_item only during active gameplay. A success immediately marks it taken and removes it from the live pickup registry before deferred deletion; a rejection leaves it available.
- Checkout accepts an entry only during RUSH or FINAL_CALL, then defers take_all_items so same-frame inheritance resolves first. Coalesce duplicate requests for that cart while one is pending.
- Bank returned items and their total once, then emit checked_out only for a nonempty haul. Retain the same ItemData objects for get_banked_items.
- Accept already queued final-frame checkouts after CLOSED, before round results. Reject new checkout entries after close.
- Spawn only cart_robbed.spilled at the loser position, preserving instances, IDs, values and flags; never respawn transferred items. Spills ignore the floor cap.
- get_pickups returns only live untaken pickups; score/item getters return snapshots with safe empty defaults for unknown cart IDs.

## 4. Interfaces

Existing signatures: [CONTRACTS.md](../../../CONTRACTS.md).

- Uses Cart.try_add_item, take_all_items, get_state and cart_robbed as defined in CONTRACTS.md §2; Store never writes Cart inventory.
- Implements existing Pickup behavior and RoundManager pickup/banking getters; emits checked_out after scores and banked items are updated.
- Connects registered carts once to the spill listener; existing contract requires cart_robbed exactly once per steal.
- Regular category visuals use ASSETS.md's six item paths under a Visual child. Store-private helpers stay within Store; no shared signature changes.

**Contract changes:** None. Any newly discovered need follows §9 before implementation.

## 5. Scenes and files

- systems/store/pickup.gd and pickup.tscn: collection trigger and category visual.
- systems/store/round_manager.gd: live pickup registry, weighted spawning, IDs, score bookkeeping and spills.
- systems/store/checkout.gd and store.tscn: deferred checkout requests.
- systems/store/test/spawns_checkout_test.tscn: standalone diagnostic scene.
- tests/store/test_spawns_checkout.gd and tests/store/support/cart_double.gd: controlled seam tests; the double remains test-only.

## 6. Edge cases

- Two carts touch one pickup: only the first successful collection receives it; full-cart rejection leaves it for the next cart.
- Spill at or above cap: all overflow items spawn, then regular spawning pauses until count is below 46.
- Duplicate checkout callbacks do not bank twice; empty checkout emits no score event.
- Freed/unregistered cart or restarted match before deferred checkout: cancel stale work safely.
- Simultaneous steal/checkout and close/checkout preserve one destination per item and finalized result totals.
- Tests using a fake Cart demonstrate Store's seam only; actual 20-into-8 collision acceptance awaits Rickey's implementation and the scheduled integration check.

## 7. Test plan

- Test category values and deterministic weighted-selection interval boundaries; verify correct aisle placement.
- Test 0.5-second cadence, 46 cap, spills above cap, inactive phases, unique ItemData instances and unique IDs.
- Test accepted/rejected pickup, two-cart contention and registry removal before deletion.
- Test nonempty/empty/duplicate checkout, repeated trips, snapshot getters, pending last-frame checkout and rejection after close.
- Simulate Cart's post-transfer 20-into-8 signal with 24 in winner, 0 in loser and 4 spilled; verify all 28 original IDs and total value across cart/floor/bank. Do not implement Cart's speed, immunity or collision rule.
- In spawns_checkout_test.tscn inspect six visuals, spawn placement and spill positions; use real Cart once merged for pickup/full-cart/checkout hand checks.

Run the full headless GUT suite after every implementation step. Any SCRIPT ERROR or fewer executed scripts than test files is a failure, even if GUT prints success.

## 8. Out of scope

Cart inventory/ram/immune logic, assets, bot behavior, Deal of the Day spawning, hazards and best-of-three scoring.

## 9. Done when

- [ ] Regular spawning respects weights, timing and cap; collection has one winner; checkout banks once after inheritance; spills preserve identity; close-boundary results include accepted pending banking.
- [ ] Full GUT suite passes with no skipped parse-error scripts.
- [ ] Anthony confirms the Store test-scene hand checks.
- [ ] Anthony's PROGRESS handoff records actual verification and dependencies.
