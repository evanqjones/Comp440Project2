# 05-best-of-three: Lite feature

| | |
|---|---|
| System / Owner | Store / Round Manager (Anthony's; built by Rickey as an approved exception, D-034) + Player receipt |
| Branch | `store/05-best-of-three` (from `main`) |
| Agent / Date | Claude Code / 2026-10-01 |
| Milestone | Final: "we can't continue to round 2" |

## 1. Brainstorm

- Today `RESULTS` returns to `IDLE` after round 1, and `get_stamps()` / `get_match_banked()` are stubs returning 0.
- The rules are already decided in `GAME_SPEC.md` §3.2, and the data shape in `CONTRACTS.md` §1.5 (`RoundResults`) and §3.
- Rickey picked (2026-10-01):
  - between rounds the receipt counts down to the next round and hides when its 3-2-1 begins;
  - after round 3 it's a **MATCH OVER** receipt with a **SHOP AGAIN** button (or Enter);
  - Grandma's card is **reissued in your name** beside it when you win.
- Already per-round: bot aggression (`round_started(round_number)`), hazard frequency (`store.gd` reads `round_number`), and hazard cleanup and doors on phase changes.

## 2. Spec

- **`RoundManager`** (`systems/store/round_manager.gd`), with `ROUNDS_PER_MATCH = 3`:
  - **Round end** (`_finalize_round`), in `RoundResults`:
    - `banked` is this round's money.
    - `winner_ids` are the carts with the highest round score if it's above $0; ties each get a stamp, and nobody banking means no stamp.
    - `stamps` and `match_banked` are the running totals.
  - **After round 1's or 2's 10 s `RESULTS`:** the next round starts.
    - `round_number` goes up, carts reset empty at their starts, floor items are cleared, and round money and banked items clear.
    - Item ids keep counting, so they stay unique across the match.
    - Then `COUNTDOWN` 3 s, then `RUSH` at 2:00.
  - **After round 3:** the phase goes straight to **`MATCH_OVER`** (no 10 s wait), and `round_ended` carries `is_match_over = true` and `match_winner_ids`.
    - The match winner has the most stamps; a stamp tie goes to the most banked across all rounds, and an exact tie is shared.
    - The clock stops.
  - **Queries:** `get_stamps(id)` returns the stamps so far. `get_match_banked(id)` returns completed rounds plus the live round (no double count during `RESULTS`/`MATCH_OVER`).
  - **`start_match()`** also works from `MATCH_OVER` (SHOP AGAIN), and it clears stamps and match totals.
- **`RoundReceipt`** (Player):
  - **Between rounds:** the receipt as now, plus a top line "Round N starts in S" counting down `RESULTS_DURATION`. It hides at the next `COUNTDOWN` so the 3-2-1 is visible.
  - **Match over:**
    - title "BUMPER CROP MARKET / Match over · 3 days of the sale";
    - lines sorted by stamps, then match total: "Name ★★ … $total";
    - "★ Winner: …" (shared names on a tie) and the stamp standings;
    - a **SHOP AGAIN** button (`CardUi.go_button`, focused) or Enter, which calls `RoundManager.start_match()`.
  - **Card reissue:** if the player is a match winner, `ShopperIdCard.make(player profile, "", stamps)` is shown beside the receipt with "Reissued in your name".
- **Tests changed:**
  - `test_round_flow.gd`: "results → IDLE" becomes "results → round 2 countdown";
  - the restart test now restarts from `MATCH_OVER`.
- **Contract changes:** none. The fields and methods already exist; this fills them in.

**Done when:**
- [x] GUT (37 scripts, 267/267):
  - round 1 → round 2 (reset, totals kept);
  - stamps, including ties and "nobody banked";
  - the match winner by stamps, then total, then shared;
  - round 3 → `MATCH_OVER`;
  - SHOP AGAIN starts fresh;
  - `get_match_banked` during a round;
  - the receipt countdown and hide, the match-over receipt, the button starting a match, and the card reissued only for a winning player.

  The full suite passes.
- [x] Full game, run from the editor with time skipped and banked money set so the player wins:
  - round 1's receipt shows "★ Stamp: You" and "Round 2 starts in 8";
  - round 2's 3-2-1 has the HUD at "ROUND 2", carts back at the start empty, and the receipt hidden;
  - the MATCH OVER receipt shows You ★★ $425 / Rita ★ $140 / Carl $95 / Bev $60 and "Winner: You", with the reissued card and a focused SHOP AGAIN;
  - Enter starts round 1 with stamps and totals reset.

## 3. Plan

1. Tests → `RoundManager` → receipt → update the old tests → suite → full-game run (time skipped) → D-034 → commit → re-export `docs/` → push, PR, merge.
