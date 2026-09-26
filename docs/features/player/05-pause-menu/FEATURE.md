# 05-pause-menu: Lite feature

| | |
|---|---|
| System / Owner | Player / Rickey |
| Branch | `player/05-pause-menu` (from `main`) |
| Agent / Date | Claude Code / 2026-09-25 |
| Milestone | Final |

## 1. Brainstorm

- GAME_SPEC §4.1 and §8: pause menu on the `pause` action (Esc / Start). There's no layout for it in the `ASSETS.md` manifest, so it's built in code and Evan can restyle it later.

## 2. Spec

- **`PauseMenu`** (`systems/player/pause_menu.gd`, a `CanvasLayer` that runs while the game is paused):
  - `pause` toggles it: `open()` pauses the whole tree (clock, carts, bots, physics) and `close()` resumes.
  - It shows a dim overlay, "PAUSED", and buttons: **Resume**, **Restart round** (unpauses, then reloads the scene), and **Quit** (hidden on web, where a tab can't quit).
  - Resume gets focus so a gamepad works. Leaving the scene while paused unpauses the tree.
- **Wiring:** the fallback demo adds one. Anthony adds the same to `main.tscn` later (handoff).
- **Contract changes:** none.

**Done when:**
- [x] GUT: pause toggles open/closed and the tree paused state; the menu runs while paused; Restart unpauses; Quit is hidden only on web; freeing it while open unpauses. Full suite passes
- [x] Wired into the game and working with Run Project: the pause action froze the clock (118.98 → 118.98 over 1.5 s) and resuming continued it (→ 117.98 in 1 s); menu screenshot checked

## 3. Plan

1. Tests → `PauseMenu` + demo wiring → suite → Run Project probe → commit → pull `main` → push, PR, merge, check on `main`.
