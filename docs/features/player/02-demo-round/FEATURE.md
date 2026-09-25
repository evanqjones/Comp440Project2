# 02-demo-round: Lite feature

| | |
|---|---|
| System / Owner | Player / Rickey |
| Branch | `player/02-demo-round` (stacked on `integration/01-demo`) |
| Agent / Date | Claude Code / 2026-09-25 |
| Milestone | Demo (Fri 09-25, 9 am): **fallback only** |

Lite is OK here: everything lives in `systems/player/demo/` plus Rickey's own test helpers, and nothing else depends on it. It's a **stand-in** for Store's round and store (Anthony) and Rivals' bots (John); their real work replaces it in `main.tscn`.

## 1. Brainstorm

Goal: have something playable at the 9 am demo even if the Store and Rivals code isn't pushed by then.

- **Q:** What goes in the demo branch? **A:** Merge every open PR plus Anthony's branch into `integration/01-demo` (done, D-020), **plus a fallback demo scene**: a 2:00 round with test pickups, a checkout pad and 3 rammer "bots".
- **Q:** godot-mcp autoload? **A:** Keep the plugin, drop the autoload in the demo branch (D-020).
- **Defaults (stated, not asked):** it lives in `systems/player/demo/`. It drives `RoundManager.phase` from the demo script, like the test scenes (Anthony's round flow replaces it). Spills drop as one-off pickups near the loser (Anthony's spill spawner replaces it). Only Rita's patrol crosses the checkout pad, so a bot can bank stolen loot.

## 2. Spec

- **Store:** a 60 × 60 m floor. Store interior z −20 … +10, x ±25, with 2.5 m walls and an **8 m door gap** in the front wall (z +10). **7 cream shelves** (1 m wide, 2 m tall, z −16 … −2) at x = ±22.5, ±15, ±7.5, 0 make **6 lanes 6.5 m wide**. Each lane has a floor stripe in its aisle color (GAME_SPEC §6 order, left to right: produce, bakery, dairy, snacks, frozen, electronics). There are cross-aisles at the front (z −2 … +10) and back (z −20 … −16).
- **Groceries:** 5 pickups per lane (30 total) of that lane's category, respawning 3 s after being taken.
- **Checkout:** a green pad outside the doors at (0, 0, +15), banking per cart, **only while the round is active**.
- **Round** (`DemoRoundClock`, pure): COUNTDOWN 3 s, then RUSH until 20 s left, then FINAL_CALL, then CLOSED at 2:00. Then results. **R** restarts.
- **Carts:** the player (yellow profile) starts outside at (0, 0, +20) facing the doors, with `PlayerController` + `ChaseCamera`. Bots use `test_rammer_driver.gd` patrols: **Carl** across the front cross-aisle (z +3), **Bev** across the back cross-aisle (z −18), **Rita** outside across the checkout pad (z +15).
- **Spills:** on any `cart_robbed`, each `spilled` item becomes a one-off pickup (same `ItemData`) scattered within 1.5 m of the loser.
- **HUD** (labels): top-left: phase, timer (mm:ss, red in final call), your items n/24, cart $, banked $. Top-right: each shopper's banked $ and cart $. Center: countdown, then results (everyone's banked $, winner). Bottom: controls.
- **Files:** `systems/player/demo/demo_round.tscn` + `.gd`, `systems/player/demo/demo_round_clock.gd`, `tests/player/test_demo_round_clock.gd`. Small additions to Rickey's test helpers: `test_pickup.gd` (`aisle_category`, one-off `fixed_item`) and `test_checkout_pad.gd` (per-cart banking, active-round only).
- **Out of scope:** real Store/RoundManager, real bots, the real HUD (`player/03-demo-hud`), `main.tscn`.

**Done when:**
- [ ] GUT: `DemoRoundClock` phases and time left; full suite passes (no `SCRIPT ERROR`, `Scripts` = number of test files)
- [ ] The demo scene runs headless with no errors; rendered frames show the store, lanes, HUD and countdown
- [ ] Rickey plays a full round (Cmd+R on `demo_round.tscn`)

## 3. Plan

1. `DemoRoundClock` + tests → commit `player: demo round clock`.
2. Helper additions (pickups by aisle, one-off spill pickups, per-cart pad) → suite → commit `cart: test helper options for the demo`.
3. `demo_round.tscn` / `.gd` (store, carts, bots, spills, HUD, restart) → headless run + rendered frames → commit `player: fallback demo round`.
4. Docs (PROGRESS Player section, TODO: HUD renumbered to `player/03-demo-hud`) → commit, push, open PR into `integration/01-demo`.

## 4. Checklist

- [x] Branch created (stacked on `integration/01-demo`)
- [x] Step 1: clock + tests
- [ ] Step 2: helper options
- [ ] Step 3: demo scene
- [ ] Step 4: docs, PR
