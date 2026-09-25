# 04-ram-steal: Spec

| | |
|---|---|
| System / Owner | Cart / Rickey |
| Branch | `cart/04-ram-steal` |
| Status | Approved by Rickey (2026-09-25) |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Demo (Fri 09-25) |

## 1. Overview

When two carts touch during the round, the faster one may **inherit** the slower one's haul. `CartSteal` (pure rules) decides the outcome and splits the loot. `cart.gd` detects the contact, resolves it exactly once, updates both inventories instantly, emits `cart_robbed` from the loser, applies knockback, stun and immunity, and plays the tip-over and the flying items.

## 2. Player-facing behavior

- **Steal:** ram a loaded cart hard enough and its items fly in arcs into your basket (landing one by one over ~1 s). The robbed cart and its shopper tip onto their side, slide away, and pop back upright after 0.7 s. You keep ~75% of your speed. If your basket fills, the rest spills onto the floor (Store spawns them).
- **Bounce:** a bump that doesn't qualify pushes both carts apart a little and slows both. Nothing changes hands.
- **Immunity:** for 1.6 s after being robbed, a cart can't be robbed again, but it can still rob others.
- **Stunned carts** can't steal, and their driver has no control for 0.7 s.
- **Empty carts** can't be robbed; hitting one is a bounce.
- **Outside the round** (countdown, closed, results), carts just block each other.

## 3. Rules and numbers

New `CartTuning` fields (added to GAME_SPEC §12):

| Field | Value | Source |
|---|---|---|
| `steal_min_speed` | 5.0 m/s | GDD §5.1 |
| `steal_margin` | 1.5 m/s | GDD §5.1 |
| `stun_time` | 0.7 s | GDD §5.1 |
| `immune_time` | 1.6 s (from the moment of the steal) | GDD §5.1 |
| `winner_keep` | 0.75 (fraction of speed kept) | GDD §5.3 (14 → 10.5) |
| `knockback_speed` | 4.0 m/s (< `steal_min_speed`) | Brainstorm Q1 |
| `stun_grip` | 1.0 per second (slides while stunned) | Brainstorm Q1 |
| `bounce_speed` | 2.0 m/s | Brainstorm Q2 |
| `bounce_keep` | 0.7 | Brainstorm Q2 |
| `pair_cooldown` | 0.2 s | Decisions |
| `tip_time` | 0.15 s (down and up) | Brainstorm Q4 |
| `flight_time` / `flight_stagger` / `flight_height` | 0.4 s / 0.03 s / 1.0 m | Brainstorm Q6 |

**`CartSteal`** (`class_name CartSteal extends RefCounted`, static):
- `enum Outcome { NONE, BOUNCE, A_WINS, B_WINS }`
- `outcome(t: CartTuning, a: CartState, b: CartState) -> Outcome`: let `fast` / `slow` be the carts with the higher / lower `speed` (a tie means BOUNCE). A steal happens if `fast.speed >= steal_min_speed` **and** `fast.speed - slow.speed >= steal_margin` **and** `not fast.is_stunned` **and** `not slow.is_immune` **and** `slow.items.size() > 0`. Then return A_WINS or B_WINS. Otherwise BOUNCE.
- `split(loser_items: Array[ItemData], winner_free_slots: int) -> Array` returns `[transferred: Array[ItemData], spilled: Array[ItemData]]`: the first `winner_free_slots` items (oldest first) transfer, the rest spill. `winner_free_slots` is clamped at 0.

(`speed` in `CartState` is the planar speed just **before** the contact move, from `_speed_before_move`.)

**Contact resolution** (`cart.gd`):
1. After `move_and_slide()`, for each slide collision whose collider is another `Cart`: if `not RoundManager.is_gameplay_active()`, skip. If this pair was resolved within `pair_cooldown`, skip. Otherwise resolve with the contact normal.
2. Build the two snapshots using each cart's `_speed_before_move` (the other cart's value is from its latest physics step), then compute `CartSteal.outcome`.
3. **Steal:** `loot = loser._inventory.take_all()`, then `split(loot, winner.capacity - winner.count)`. The winner adds `transferred` (oldest first); `spilled` is left for Store. Winner speed ×= `winner_keep`. The loser's planar velocity = `knockback_speed` along the direction from winner to loser (flattened), stun = `stun_time`, immunity = `immune_time`. Visuals: the loser tips over; the flight starts. Then **the loser emits `cart_robbed(winner, loser, transferred, spilled)`**, after both inventories are updated. If `transferred` fills the winner to 24, the winner emits `cart_full`.
4. **Bounce:** each cart's planar velocity = its velocity × `bounce_keep` + `bounce_speed` along the direction away from the other. No signals.
5. Record the pair (both carts' instance IDs) with the current time for the cooldown.

**Stun and immunity timers:** they count down each physics step. While stunned, the command is neutral (as in cart/01) and grip is `stun_grip`. `CartState.is_stunned` / `is_immune` report them.

**Visuals:**
- **Tip-over:** the loser's `Visual` rolls +90° about the cart's forward axis around its bottom-left edge (x = −0.4, y = 0) over `tip_time`, holds, and returns upright over `tip_time`, ending at `stun_time`.
- **Flight:** each transferred item spawns a temporary cube (`CartItemStack.color_for`) at the loser's stack position and follows a parabolic arc (peak `flight_height`) to the winner's stack position over `flight_time`. Starts are staggered by `flight_stagger`. The winner's `CartItemStack` hides its newest not-yet-landed items (`show_items(items, hidden_newest)`) and reveals one per landing. Cubes are freed on landing.

## 4. Interfaces

**Uses:** `RoundManager.is_gameplay_active()`; `CartInventory` / `CartItemStack` (cart/02); `_speed_before_move` (cart/01).

**Provides / emits:** `cart_robbed(winner, loser, items, spilled)`, **emitted by the loser**, once per steal, after both inventories update (CONTRACTS §2, invariant 2). `cart_full` on the winner if the steal filled it. `get_state().is_stunned` / `is_immune`.

**Contract changes:** none. `CartItemStack.show_items` gains an optional `hidden_newest := 0` (Cart-internal class).

## 5. Scenes and files

| Path | New / changed | Purpose |
|---|---|---|
| `systems/cart/cart_steal.gd` | New | `CartSteal` rules |
| `systems/cart/cart_tuning.gd` | Changed | Fields in §3 |
| `systems/cart/cart.gd` | Changed | Contact detection and resolution, timers, stun grip, visuals hooks |
| `systems/cart/cart_item_stack.gd` | Changed | `show_items(items, hidden_newest := 0)`, `stack_position() -> Vector3` |
| `systems/cart/cart_steal_effects.gd` | New | `CartStealEffects` (static helpers): tip-over tween and item flight |
| `systems/cart/test/test_target_cart.gd`, `test_rammer_driver.gd` | New | Test-only: preload items into a parked cart; drive back and forth |
| `systems/cart/test/cart_drive_test.tscn` / `.gd` | Changed | 3 targets (20 / 8 / empty), 1 rammer, R to reset |
| `tests/cart/test_cart_steal.gd` | New | GUT tests |

## 6. Edge cases

| Case | Expected behavior |
|---|---|
| Both carts detect the same contact in one frame | Resolved once (pair lock) |
| Carts keep touching after a bounce | Cooldown 0.2 s, then they may bounce again |
| Repeat hit during the loser's immunity | Bounce; no transfer, no signal |
| Winner already full | All loot spills; `transferred` is empty; `cart_robbed` still fires (the loser lost everything) |
| Loser empty | Bounce, no stun |
| Speeds exactly 5.0 and exactly 1.5 apart | Steal (inclusive) |
| Tie in speed | Bounce |
| Stunned faster cart | Bounce (can't win) |
| Contact after close | Ignored (plain physics block) |
| Loser knocked into a third cart | 4 m/s < 5, and it's stunned: bounce at most |
| Cart freed mid-flight | Flight cubes free themselves; no errors |

## 7. Test plan

**GUT, `tests/cart/test_cart_steal.gd`:**
- [ ] `test_outcome_steal_when_fast_enough_and_margin` (14 vs 6 → A_WINS; 6 vs 14 → B_WINS)
- [ ] `test_outcome_thresholds_inclusive` (5.0 vs 3.5 → steal; 4.99 vs 0 → bounce; 6.0 vs 4.6 → bounce)
- [ ] `test_outcome_bounce_on_tie_stunned_immune_or_empty`
- [ ] `test_split_oldest_first` (8 loot, 4 free → 4 transfer oldest, 4 spill; 0 free → all spill; 24 free → all transfer)
- [ ] `test_gdd_20_into_8_conserves_items_and_value` (§11.2 step 1: winner 24, loser 0, 4 spilled, `cart_robbed` once from the loser, all 28 item IDs and $370 accounted for)
- [ ] `test_repeat_contact_during_immunity_does_nothing` (§11.2 step 2)
- [ ] `test_stun_and_immunity_timers`
- [ ] `test_winner_keeps_75_percent_and_loser_knocked_away`
- [ ] `test_bounce_pushes_apart_without_items_or_signal`
- [ ] `test_no_steal_when_round_not_active`
- [ ] `test_winner_full_everything_spills`
- [ ] `test_real_ram_steals_once` (physics: a driven cart hits a parked 8-item cart; exactly one `cart_robbed`)
- [ ] `test_loser_upright_after_stun_and_winner_stack_fills` (visuals settle)

**Test scene hand checks** (`cart_drive_test.tscn`, Cmd+R):
- [ ] Ramming the 8-item target at speed: cubes fly into your basket; the target tips over and slides
- [ ] Ramming the 20-item target when you already hold some: your basket fills to 24 (overflow is lost in the test scene, since Store's spill spawner isn't here)
- [ ] Ramming the empty target: just a bounce
- [ ] Getting rammed by the rammer: your cart tips, you lose control briefly, and a quick second hit doesn't rob you again
- [ ] R resets

## 8. Out of scope

Spill spawning (Store), popups, shake, sound, rumble (Player, Final), bot behavior (Rivals), Evan's models, boost.

## 9. Done when

- [ ] All §7 GUT tests pass with the existing 62; full suite headless, no `SCRIPT ERROR`, `Scripts` count = number of test files
- [ ] Rickey confirms the hand checks (and the look against his artifact demo when shared)
- [ ] D-019 logged (loser emits `cart_robbed`, pair lock, fair-set rules); GAME_SPEC §12 rows; PROGRESS handoffs for Anthony and John
- [ ] PR opened (stacked on #7; reviewer: Anthony)
