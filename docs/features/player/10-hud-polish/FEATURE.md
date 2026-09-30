# 10-hud-polish: Lite feature

| | |
|---|---|
| System / Owner | Player / Rickey |
| Branch | `player/10-hud-polish` (from `main`) |
| Agent / Date | Claude Code / 2026-09-30 |
| Milestone | Final polish |

## 1. Brainstorm

- A scripted round on `main` (2026-09-30) showed:
  - nothing on screen during the 3 s countdown;
  - no cue when the cart is full;
  - the event feed (Evan's `%FeedList`, x 16–560) running into his new cart panel (x 311–841 at the 1152 × 648 base size).
- Rickey picked (one batch, 2026-09-30):
  - countdown + hints;
  - pickup and checkout pops;
  - a checkout arrow;
  - feed/HUD readability.
- Boost/motion effects go to `cart/09`, sounds to `player/12`.
- Evan's `assets/ui/hud_layout.tscn` isn't edited. Only the lines our code puts into `%FeedList` / `%ScoreList` change, plus new nodes that `PlayerHud` adds on top.

## 2. Spec

All in `PlayerHud` (`systems/player/hud/player_hud.gd`) plus small helper nodes in `systems/player/hud/`.

- **Countdown:**
  - While `RoundManager.phase` is COUNTDOWN, a big centered number counts "3", "2", "1", starting from `RoundManager.COUNTDOWN_DURATION` when the phase begins.
  - When RUSH starts, it shows "GO!" for 0.8 s.
  - `countdown_text()` returns what's shown ("" when hidden).
- **Hint line** (bottom center just above Evan's cart panel, pill background, wraps at 560 px; `hint_text()`):
  - For 2.5 s after the start of RUSH (round start), it shows "Doors open! Grab items, then check out outside."
  - At FINAL_CALL it shows "Final call! 20 seconds left" for 2.5 s.
  - While the player's cart is full (RUSH/FINAL_CALL), it shows "Cart full! Drive out the doors to check out", staying up until the cart isn't full.
- **Checkout arrow:**
  - Shown while the player's cart is full, or during FINAL_CALL with at least one item.
  - It sits over the shopper's head (screen center, a little up) with a "CHECK OUT" tag, and turns toward `RoundManager.get_checkout_position()` relative to the active camera's flat forward direction: up = straight ahead, right = to the right.
  - It bobs gently. `arrow_visible()` and `arrow_angle()` (radians, 0 = ahead, + = right) are exposed for tests.
- **Pickup pop:**
  - On the player's `item_collected`, a billboard `Label3D` reading "+$N" in the item's category color (`CartItemStack.color_for`) rises 1.2 m over the cart and fades in 0.9 s; pops that land together stack 0.55 m apart.
  - Bots get none.
- **Checkout confetti:**
  - The existing "Checked out $N" popup stays.
  - On the player's own checkout, a one-shot `CPUParticles2D` burst (web-safe, no threads) fires from the popup, using the six aisle colors.
- **Feed and scoreboard readability:**
  - Each feed line becomes a rounded, soft dark pill (`PanelContainer` + `Label`, 17 px) that shrinks to its text.
  - Feed lines wrap at `FEED_MAX_WIDTH` = 284 px, so they stay left of the cart panel at the 1152 base width.
  - Each scoreboard line gets the same pill, right-aligned.
  - `feed_lines()` still returns the texts.
- **Contract changes:** none. It uses `phase`, `COUNTDOWN_DURATION`, `get_checkout_position()`, `item_collected`, `checked_out` and `cart_full` state (`get_state().items.size()` vs `tuning.item_cap`).

**Done when:**
- [x] GUT covers:
  - countdown 3 → 1 → "GO!" → hidden;
  - the doors, final-call and full-cart hints, and the full-cart hint clearing;
  - the arrow shown only when full or during final call with items, and its angle pointing right for a checkout to the camera's right and ahead for one in front;
  - a pickup pop only for the player's own pickups, with "+$N";
  - confetti only on the player's checkout;
  - feed lines at most 284 px wide, with `feed_lines()` still working.

  The full suite passes.
- [ ] Run Project on `main`: the countdown, hints, arrow, pops, confetti and a feed that clears the cart panel are all visible in the full game.

## 3. Plan

1. Tests → implement → suite → windowed screenshots in the full game → commit → pull `main` → ask to push / PR / merge → check on `main`.
