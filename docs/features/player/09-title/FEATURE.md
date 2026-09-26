# 09-title: Lite feature

| | |
|---|---|
| System / Owner | Player / Rickey (fills Evan's ID card layout) |
| Branch | `player/09-title` (from `main`) |
| Agent / Date | Claude Code / 2026-09-25 |
| Milestone | Final |

## 1. Brainstorm

- **GAME_SPEC §2:**
  - Grandma's Platinum Shopper ID card and "Don't let Carl win."
  - Each round is a day of the sale; winning the match reissues the card in your name.
  - The card appears on the title screen, and each bot's card is its intro.
- **§2.2:** rival tiers and blurbs. These are already in `systems/shared/profiles/*.tres`: tier, member number, member since, blurb.
- **§9.3:** web audio starts only after the first input, on the title's "press any key".
- **CONTRACTS §3:** `RoundManager.start_match()` is called by Player's title/intro flow.
- **ASSETS §4:** Evan's `assets/ui/id_card_layout.tscn` has `%Name`, `%Photo`, `%MemberNumber`, `%MemberSince`, `%TierBadge`, `%Barcode`, `%LifetimeSavings` and `%StampRow`. It doesn't exist yet.
- **Scope (Rickey):** the title with "press any key", the story intro, the bot intro cards, then the round. Character select is Q-004, still open, and not in this feature.

## 2. Spec

- **`ShopperIdCard`** (`systems/player/screens/shopper_id_card.gd`): `make(profile, name_override, stamps) -> Control` instances Evan's layout, or `placeholder_id_card_layout.tscn` (same `%` names), and fills it:
  - name, tier badge (upper case), "No. 0417-2231", "Member since 1986";
  - a barcode made from the member number, lifetime savings, and stamps "★ ★ ☐" style out of 3;
  - `%Photo` tinted with the profile color.
- **`TitleFlow`** (`systems/player/screens/title_flow.gd`, a `CanvasLayer` over the live store). Its steps:
  1. **TITLE:** store name, "Grand Opening Weekend Sale", Grandma's card (the player profile named "Grandma"), and a blinking "Press any key".
  2. **STORY:** Grandma's Card story (§2), including "Don't let Carl win." and the reissue ending.
  3. **RIVALS:** "Meet your rivals", with Carl, Bev and Rita's cards and blurbs, and "Press any key to start shopping".
  - Any key, gamepad button or click advances (key releases and echoes don't).
  - After RIVALS it emits `finished`, calls `RoundManager.start_match()` and frees itself.
  - A static `seen` flag makes restarts in the same session skip straight to `start_match()`.
- **Demo:** `DemoRound.wait_for_start` (default false). When true, the round sits in IDLE until `RoundManager.start_match()`; the stand-in's `start_match()` starts the countdown. `demo_round.tscn` opened alone still starts right away.
- **`main.tscn`** (the stand-in, D-025): `DemoRound.wait_for_start = true` plus a `TitleFlow` node after it. Logged as D-029.
- **Contract changes:** none. It uses `start_match()` as the contract describes.

**Done when:**
- [x] GUT: the ID card placeholder names and filled values; TITLE → STORY → RIVALS → finished (and `start_match` → the demo's countdown); any key advances but releases don't; the rival cards; `seen` skips; the demo waits for `start_match`; `main.tscn` wiring. Full suite passes
- [x] Wired into the game and working with Run Project: screenshots of the title, story and rivals screens (HUD hidden, 3 cards fit at 1152 px); IDLE on the title, COUNTDOWN after the last key, RUSH 4 s later

## 3. Plan

1. Tests → ID card + placeholder + `TitleFlow` + demo wait + `main.tscn` → suite → Run Project screenshots → commit → pull `main` → push, PR, merge, check on `main`.
