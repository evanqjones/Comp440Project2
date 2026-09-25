# Progress Tracker

**Every agent reads this file at the start of every session.** Each owner (and their agent) edits **only their own section(s)**, so several branches can update it without merge conflicts. The **Integration** section and the "On `main`" block belong to Anthony (integration owner). Anyone may fix a typo, but not someone else's status.

Status key: 🟢 on track · 🟡 at risk · 🔴 blocked · ⚪ not started · ✅ done

---

## On `main` right now

_Updated 2026-09-23 by Rickey (Claude Code)_

- Godot 4.7.2 project with the Web export preset and a placeholder `systems/core/main.tscn` (a "Godot project ready" label).
- Project docs and specs are on branch `docs/00-project-specs`, **not merged yet**.
- Nothing playable yet.

## Milestones and checkpoints

| Milestone | Date | Status | Notes |
|---|---|---|---|
| M0 Foundation | Wed 09-23 (tonight) | 🟡 | Docs written; foundation code (contract stubs, input map, GUT) and asset placeholders next |
| Checkpoint 1 | Thu 09-24, 6 pm | ⚪ | Drivable cart + one solo round in `main` |
| Checkpoint 2 → **Demo** | **Fri 09-25**, 9 am | ⚪ | Bots in, run the 20-into-8 steal check, then demo one full round |
| **Final** | **Fri 10-02** (freeze Thu 10-01 night) | ⚪ | Evening checkpoints Sat 09-26 to Thu 10-01 |

---

## Integration: Anthony

**Status:** 🟢 · **Branch:** `integration/00-foundation` (stacked on `docs/00-project-specs`, PR #1) · **Current feature:** M0 foundation, built and awaiting review · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** Project docs (PR #1). `integration/00-foundation` built: shared contract scripts + profiles, `Cart` / `RoundManager` / `Pickup` stubs, input map, physics layer names, `RoundManager` autoload, GUT 9.7.1. **GUT: 3 scripts, 17/17 tests passing, 133 asserts, no script errors.** The main scene runs headless for 120 frames with no errors.
- **In progress:** Review. PR #1 (docs) merges first, then the foundation PR (Anthony reviews `project.godot`).
- **Next:** Assemble `main.tscn` at Checkpoint 1 (Thu 6 pm).
- **Needs from others:** **Everyone:** read `CONTRACTS.md` v0.1 and `ASSETS.md`, and sign P-001 in `DECISIONS.md` by Thu 09-24 morning.
- **Handoff notes (foundation, for everyone):**
  - After pulling: run `godot --headless --import` once, then the GUT command in `TECH_STACK.md`. **A test file with a parse error is skipped silently.** Check for `SCRIPT ERROR` and the `Scripts` count.
  - `tests/shared/test_contracts.gd` checks every contract signal and method (with argument counts) on the stubs. If you change a signature, it fails. That's intended: use the change protocol.
  - **Rickey (Cart):** `systems/cart/cart.gd` + `cart.tscn` are yours now. `CharacterBody3D` (D-015), layer 2 `carts`, mask `world` + `carts` + `hazards`. `Visual` holds an inline placeholder box; swap it for Evan's `cart_visual.tscn` in `cart/01`.
  - **Anthony (Store):** `systems/store/round_manager.gd` (autoload, no `class_name`) and `pickup.gd` are yours now. `Pickup` sets layer 3 / mask 2 in `_init()`. Real logic so far: `register_cart` / `get_carts`, `is_gameplay_active()`.
  - **John (Rivals):** build against the stubs now. `cart.apply_command(cmd)` exists but does nothing until `cart/01-movement` merges (target Thu noon). `RoundManager.get_pickups()` returns `[]` and `get_checkout_position()` returns `Vector3.ZERO` until Store implements them, so use dummy `Pickup.new()` nodes with an `ItemData` in your test scene. Tests may set `RoundManager.phase = GameTypes.Phase.RUSH`.
  - **Evan (Assets):** profile colors in `systems/shared/profiles/*.tres` match the `ASSETS.md` §3 palette. Change both together.

---

## Player: Rickey

**Status:** 🟢 · **Branch:** `player/01-controller-camera` (stacked on `cart/01-movement`) · **Current feature:** `player/01-controller-camera` (Lite), spec written · **Updated:** 2026-09-24 (Rickey, Claude Code)

- **Done:** —
- **In progress:** `player/01-controller-camera`: real PlayerController (keyboard ramp + gamepad) and chase camera with a spring arm.
- **Next:** `player/02-demo-hud` (after `cart/02-inventory`).
- **Needs from others:** Evan: `hud_layout.tscn` with the Demo `%` names, for `player/02`.
- **Handoff notes:** —

---

## Cart: Rickey

**Status:** 🟢 · **Branch:** `cart/01-movement` · **Current feature:** `cart/01-movement`, built and hand-checked, ready for PR · **Updated:** 2026-09-24 (Rickey, Claude Code)

- **Done:** `cart/01-movement` built on its branch: carts drive from `DriveCommand` (arcade handling, 15 m/s, pivot steering, grip, reverse ≤ 4 m/s). **GUT: 5 scripts, 34/34 passing, no script errors.** Drive test scene: `systems/cart/test/cart_drive_test.tscn` (F6).
- **In progress:** PR (reviewer: Anthony). Rickey confirmed the test-scene hand checks on 2026-09-24 (run the scene with Cmd+R on macOS).
- **Next:** `cart/02-inventory` (cap, weight slowdown, `try_add_item`), then `cart/03-ram-steal`.
- **Needs from others:**
  - **Anthony:** aisles **at least 3.5 m wide** (a cart is 0.8 × 1.2 m and pivots in place; two carts must pass). The floor, shelves and walls must be on physics layer 1. Start markers should face the store with the cart's front = −Z.
  - **Evan:** `assets/models/cart/cart_visual.tscn` fitting **0.8 × 1.0 × 1.2 m** (w × h × l), front facing **−Z**, origin at the floor center. `cart.tscn`'s `Visual` currently holds a grey placeholder box with a "nose" on top at the front.
- **Handoff notes (cart/01-movement):**
  - Call `cart.apply_command(cmd)` **every physics frame**. A frame without a call is neutral, so the cart coasts. The cart copies the values; reusing one `DriveCommand` is fine.
  - Steer +1 = right (clockwise). Half gas = half top speed. Brake beats gas. Hold brake below 0.3 m/s to reverse (max 4 m/s, so reversing never steals). The cart pivots in place at 180 °/s when stopped, easing to 90 °/s at 15 m/s.
  - **Carts ignore input unless `RoundManager.phase` is RUSH or FINAL_CALL** (D-017). In test scenes, set `RoundManager.phase = GameTypes.Phase.RUSH`.
  - Handling numbers are in `systems/cart/cart_tuning.tres` (one file for all carts). Rules are in `systems/cart/cart_motion.gd`.
  - Carts block each other on contact (no knockback or steal yet; that's `cart/03`).

---

## Rivals: John

**Status:** ⚪ · **Branch:** — · **Current feature:** — · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** —
- **In progress:** —
- **Next:** `rivals/01-basic-bot` (Demo). Start in a test scene with dummy pickups, a flat navmesh and the `Cart` stub; switch to the real Cart when `cart/01-movement` merges.
- **Needs from others:** Foundation (`Cart` stub, `RoundManager` stub with `get_pickups()` and `get_checkout_position()`).
- **Handoff notes:** —

---

## Store / Round Manager: Anthony

**Status:** ⚪ · **Branch:** — · **Current feature:** — · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** —
- **In progress:** —
- **Next:** `store/01-greybox-store` (Demo), then `store/02-round-flow`, `store/03-spawns-checkout`.
- **Needs from others:** Foundation (`ItemData`, `Cart` stub with `try_add_item` / `take_all_items`). Evan: placeholders for shelf, doors, checkout, and items.
- **Handoff notes:** —

---

## Assets: Evan

**Status:** ⚪ · **Branch:** — · **Current feature:** — · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** —
- **In progress:** —
- **Next:** `assets/01-placeholders` tonight: the `assets/` folders, palette materials, and placeholder visual scenes at every Demo path in the `ASSETS.md` manifest. Then `assets/02-demo-hud-layout` by Thu afternoon.
- **Requests in:** see the `ASSETS.md` manifest (rows with status ⬜).
- **Needs from others:** Rickey and Evan to settle bot cart colors (`DECISIONS.md` Q-003).
- **Handoff notes:** —
