# 03-demo-bots: Lite feature

| | |
|---|---|
| System / Owner | Player / Rickey (uses John's `BotController`) |
| Branch | `player/03-demo-bots`, cut from `integration/02-demo` (01-demo + John's #14) and merged back into it |
| Agent / Date | Claude Code / 2026-09-25 |
| Milestone | Demo |

Lite is OK here: no contract changes. It only touches the fallback demo (`systems/player/demo/`) and Rickey's test pickup. John's and Anthony's files are untouched.

## 1. Brainstorm

Goal: John's real bots drive in the fallback demo instead of the test rammers, so the demo shows all of our work together.

- **Facts found:**
  - John's `BotController` (child of a Cart) collects by value ÷ distance, chases carts with ≥ 10 items, and banks when greedy or when `time_left` ≤ 20 s. It pathfinds with a `NavigationAgent3D` named `NavigationAgent3D` on the cart.
  - It needs `RoundManager.get_pickups()`, `get_checkout_position()`, `get_carts()`, `time_left`, `is_gameplay_active()`, and the `round_started` / `round_ended` signals.
  - Anthony's `RoundManager` is still the foundation stub: `get_pickups()` returns nothing and `get_checkout_position()` returns (0, 0, 0). So the demo needs a stand-in, just as it already stands in for the clock and the store.
- **Q:** How do the bots find their way around the shelves and front wall? **A:** A runtime navmesh: the demo bakes the store when it loads, and each bot cart gets a `NavigationAgent3D`.

## 2. Spec

- **Stand-in RoundManager** (`systems/player/demo/demo_round_manager.gd`, `DemoRoundManager`, extends Anthony's stub): while `demo_round.tscn` runs, the demo swaps this script onto the `RoundManager` autoload and puts the stub back on exit. It adds only two things:
  - `get_pickups()` returns the visible `Pickup`s under the demo (untaken ones, including spills).
  - `get_checkout_position()` returns the green pad.
- **Round signals:** the demo registers all 4 carts (`register_cart`), emits `phase_changed` on each phase change, `round_started(1)` when RUSH begins, and `round_ended(results)` (round 1, banked per cart) when the store closes.
- **Test pickups:** `TestPickup` now extends the contract's `Pickup` (it's already an `Area3D` holding `item`), so `get_pickups()` can return it.
- **Bots:** Carl, Bev and Rita each get a `NavigationAgent3D` and a `BotController`. Their personalities come from the GAME_SPEC §12 table: Carl 12 / 0.8 / 0.4, Bev 6 / 0.2 / 0.2, Rita 20 / 0.4 / 0.9 (greed items / aggression / boost habit). All four carts start in a row outside the door, facing the store. The test rammers are gone from the demo; `TestRammerDriver` stays for the cart test scene.
- **Navmesh:** the floor, walls and shelves sit under a `NavigationRegion3D`. It's baked synchronously on load (no threads, so it's web-safe) from static colliders on layer 1, with a 0.8 m agent radius (the cart is 0.8 × 1.2 m).
- **HUD:** each bot's score line also shows its state (collecting / chasing / banking / stuck), to make the hand check easier.
- **Contract changes:** none.
- **Files:** `systems/player/demo/demo_round.gd`, `systems/player/demo/demo_round_manager.gd`, `systems/cart/test/test_pickup.gd`, `tests/player/test_demo_bots.gd`, docs.
- **Edge cases:** taken pickups are hidden and aren't offered; spills are offered as soon as they land. Restart (R) and leaving the scene restore Anthony's stub. Bots get no path until the navmesh syncs (first frames), so they idle briefly.
- **Out of scope:** changes to John's `BotController` (bugs are reported to him), Anthony's store and RoundManager, and boost (Cart has no boost yet).

**Done when:**
- [x] GUT: `TestPickup` is a `Pickup`; `DemoRoundManager` offers only visible pickups and the pad position; the demo bakes a navmesh, gives each bot a `BotController` + `NavigationAgent3D` with its GAME_SPEC personality, registers 4 carts, and restores the stub on exit. Full suite passes (no `SCRIPT ERROR`, `Scripts` = number of test files)
- [x] Headless run: bots collect items and check out at the pad during a round, with no errors. This needed two fixes in John's `bot_controller.gd` (steer sign; `cart_robbed` spilled type), applied on `integration/02-demo` at Rickey's request (D-024). Without them, the bots drive away from their targets. Result: Carl $1,425, Bev $1,525, Rita $425, with chases and steals
- [ ] Rickey plays the demo with John's bots

## 3. Plan

1. Tests → `TestPickup extends Pickup`, `DemoRoundManager`, demo wiring (navmesh, bots, signals, HUD states) → suite → commit `player: John's bots in the fallback demo`.
2. Headless run to watch bot states, items and banking; fix what shows up → commit.
3. Docs (PROGRESS Player, D-023, notes for John and Anthony), merge into `integration/02-demo`, push (ask first).

## 4. Checklist

- [x] Branch created
- [x] Step 1: tests + stand-in + wiring
- [x] Step 2: headless run (found John's steer-sign and `cart_robbed` type bugs)
- [x] Step 3: docs; merged into `integration/02-demo` (push: ask first)
