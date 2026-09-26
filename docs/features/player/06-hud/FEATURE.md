# 06-hud: Lite feature

| | |
|---|---|
| System / Owner | Player / Rickey (fills Evan's layout) |
| Branch | `player/06-hud` (from `main`) |
| Agent / Date | Claude Code / 2026-09-25 |
| Milestone | Demo items + Final (boost bar, feed, popups) |

## 1. Brainstorm

- GAME_SPEC §9.2 HUD:
  - timer and round, top left (red during FINAL_CALL);
  - scoreboard with banked and current cart value for all 4, top right;
  - cart panel with count / 24, value and boost, bottom center;
  - event feed, bottom left;
  - minimap under the timer (later feature).
- Popups use the §2.3 wording: "Inherited! +7 items", "Checked out $180"; a rammed shopper is "knocked out of the sale".
- ASSETS §4: Evan's `assets/ui/hud_layout.tscn` is a script-free `Control` scene. Code reaches `%TimerLabel`, `%RoundLabel`, `%ScoreList`, `%CartCountLabel`, `%CartValueLabel`, `%BoostBar`, `%FeedList` and `%Minimap`. It doesn't exist yet.
- **Q:** Build now or wait for Evan? **A:** Build now against a placeholder layout with the same `%` names. Evan's layout is used automatically once his file exists.

## 2. Spec

- **`PlayerHud`** (`systems/player/hud/player_hud.gd`, a `CanvasLayer`), with `cart` = the player's Cart:
  - **Layout:** instances `assets/ui/hud_layout.tscn` if it exists, otherwise `systems/player/hud/placeholder_hud_layout.tscn` (same `%` names). Expected types: Labels for the text parts, a `Range` for `%BoostBar`, containers for `%ScoreList` and `%FeedList`, and a `Control` for `%Minimap` (left empty for now). A missing or wrong-typed part is skipped.
  - **Timer:** `m:ss` from `RoundManager.time_left` (rounded up), red during FINAL_CALL. **Round:** "Round N".
  - **Scoreboard:** one line per `RoundManager.get_carts()` cart, "Name  $banked banked · $cart cart", in the profile color, sorted by banked. Banked comes from `RoundManager.get_round_banked(id)`.
  - **Cart panel:** "count/cap", "$value", and the boost bar filled by `boost_meter`.
  - **Event feed:**
    - "Rita inherited Carl's cart" (from every cart's `cart_robbed`) and "Bev checked out $120" (from `RoundManager.checked_out`).
    - The player reads as "You" / "your".
    - Newest at the bottom, 5 lines max; each fades out after 6 s.
  - **Popups** (center, float up and fade in 1.6 s), for the player only: "Inherited! +N items", "Knocked out of the sale!", "Checked out $N".
- **Fallback demo:** the old status and score labels are replaced by `PlayerHud`. The countdown/GO/results banner and the help line stay.
- **Store stand-ins:**
  - `DemoRoundManager.get_round_banked(id)` reads the demo pad.
  - `TestCheckoutPad` emits `RoundManager.checked_out(cart, value)` when it banks, as Store's checkout will (CONTRACTS §3.2).
- **Contract changes:** none. It uses the existing `checked_out`, `get_round_banked`, `get_carts`, `time_left`, `phase` and `round_number`.

**Done when:**
- [x] GUT: the layout path falls back to the placeholder; the placeholder has all 8 names; the timer formats and turns red at final call; the cart panel shows count, value and boost; feed and popup wording for robbed, inherited and checkout; the feed caps at 5; the demo shows a `PlayerHud` for the player. Full suite passes
- [x] Wired into the game and working with Run Project: the screenshot shows the timer, sorted colored scoreboard, feed (including a live bot-on-bot inheritance), popups and the cart panel with a yellow boost bar; the real pad's checkout reached `get_round_banked` ($125)

## 3. Plan

1. Tests → placeholder layout + `PlayerHud` + stand-in banked/checked_out + demo swap → suite → Run Project screenshot → commit → pull `main` → push, PR, merge, check on `main`.
