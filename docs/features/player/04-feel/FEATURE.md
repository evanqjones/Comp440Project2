# 04-feel: Lite feature

| | |
|---|---|
| System / Owner | Player / Rickey |
| Branch | `player/04-feel` (from `main`) |
| Agent / Date | Claude Code / 2026-09-25 |
| Milestone | Final |

## 1. Brainstorm

- GAME_SPEC §4.1 and §8 call for a brief camera shake when rammed and controller rumble. `cart_robbed(winner, loser, …)` is emitted by the loser, once per steal (CONTRACTS §2).
- **Q:** When does it shake? **A:** Getting robbed = a strong shake plus rumble; robbing someone = a small bump; bounces, wall hits and bot-on-bot steals = nothing, so traffic doesn't jitter the camera.

## 2. Spec

- **`ChaseCamera.shake(strength, duration)`:** random camera offsets up to `strength` meters, fading to zero over `duration`. `current_shake()` reports the live strength. A new shake replaces a weaker one and never cuts a stronger one short.
- **`PlayerFeedback`** (`systems/player/player_feedback.gd`, a `Node`), with `cart` (the player's) and `camera`:
  - It watches `cart_robbed` on every cart in `RoundManager.get_carts()`, picking up late registrations too. `watch(cart)` adds one by hand.
  - **You were robbed:** shake 0.35 m for 0.35 s, and rumble on every connected pad (weak 0.5, strong 1.0, 0.35 s).
  - **You robbed someone:** shake 0.12 m for 0.15 s, and rumble (weak 0.4, strong 0, 0.15 s).
- **Wiring:** the fallback demo adds a `PlayerFeedback` next to the camera. Anthony adds the same to `main.tscn` later (handoff note).
- **Contract changes:** none.

**Done when:**
- [x] GUT: the camera offset appears and fades; robbed = big shake, robbing = small, bot-on-bot = none; carts registered later are watched. Full suite passes
- [x] Wired into the game and working with Run Project: Carl's real `_steal_from(player)` moved 5 items and the shake went 0.35 → 0.15 (0.2 s) → 0, with no errors

## 3. Plan

1. Tests → `shake()` + `PlayerFeedback` + demo wiring → suite → Run Project probe (a bot's real `_steal_from(player)`) → commit → pull `main` → push, PR, merge, check on `main`.
