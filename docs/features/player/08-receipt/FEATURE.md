# 08-receipt: Lite feature

| | |
|---|---|
| System / Owner | Player / Rickey (fills Evan's receipt layout) |
| Branch | `player/08-receipt` (from `main`) |
| Agent / Date | Claude Code / 2026-09-25 |
| Milestone | Final (replaces the Demo's plain results) |

## 1. Brainstorm

- GAME_SPEC §3.1 RESULTS (10 s): a round receipt with each shopper's banked total for the round, the stamp awarded, and the standings.
- §3.2: the highest round score gets a stamp. Ties share it. If nobody banked, there's no stamp (P-002, proposed).
- §2: each round is one day of the sale weekend. The store name lives in one constant, "Bumper Crop Market" (Q-001).
- ASSETS §4: Evan's `assets/ui/receipt_layout.tscn` has `%RoundTitle`, `%ReceiptLines`, `%StampRow` and `%Standings`. It doesn't exist yet.

## 2. Spec

- **`PlayerStrings.STORE_NAME`** (`systems/player/player_strings.gd`): the one place the store name lives.
- **`RoundReceipt`** (`systems/player/results/round_receipt.gd`, a `CanvasLayer`), with `cart` = the player's Cart:
  - **Layout:** uses Evan's `assets/ui/receipt_layout.tscn` if it exists, else `systems/player/results/placeholder_receipt_layout.tscn` (same `%` names; a white paper strip).
  - **When:** hidden until `RoundManager.round_ended(results)`, then shown; hidden again on `round_started`.
  - **`%RoundTitle`:** "BUMPER CROP MARKET" / "Round N · Day N of the sale".
  - **`%ReceiptLines`:** one line per shopper, most banked first, "Coupon Carl ........ $480", with "You" for the player. Names come from `RoundManager.get_carts()`.
  - **`%StampRow`:** "★ Stamp: Coupon Carl" (ties list everyone), or "No stamp today" when `winner_ids` is empty.
  - **`%Standings`:** stamps so far per shopper from `results.stamps`, e.g. "Stamps: You 0 · Coupon Carl 1 · …".
  - `footer` (optional text under the receipt): the demo uses "Press R to play again".
- **Demo stand-in:** `DemoRoundManager.round_winners(banked) -> Array[int]` applies the §3.2 rule. The demo's `round_ended` results now fill `winner_ids`, `stamps` and `match_banked`. The receipt replaces the demo's plain results banner.
- **Out of scope:** match results, the Shopper ID card and stamps art (title/ID card feature), and best of 3 (Store).
- **Contract changes:** none. It reads the existing `RoundResults` fields.

**Done when:**
- [x] GUT: layout fallback and the placeholder's names; hidden until `round_ended`, hidden on `round_started`; lines sorted by banked with "You"; stamp row for a winner, a tie, and nobody; standings; the demo's winner rule; the demo shows the receipt at close. Full suite passes
- [x] Wired into the game and working with Run Project: a full real round (run at 6× speed) ended with the receipt listing real totals and stamping the winner; the footer sits at the top center, clear of the HUD

## 3. Plan

1. Tests → strings + placeholder layout + `RoundReceipt` + demo results/winners → suite → Run Project screenshot at close → commit → pull `main` → push, PR, merge, check on `main`.
