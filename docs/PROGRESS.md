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

**Status:** 🟢 · **Branch:** `player/01-controller-camera` (stacked on `cart/01-movement`, PR #4) · **Current feature:** `player/01-controller-camera` (Lite), built and hand-checked, PR open · **Updated:** 2026-09-24 (Rickey, Claude Code)

- **Done:** `player/01-controller-camera` built: real `PlayerController` and `ChaseCamera`. **GUT: 7 scripts, 44/44 passing, no script errors.** Test scene: `systems/player/test/player_drive_test.tscn` (Cmd+R on macOS).
- **In progress:** PR #5 (stacked on #4). Rickey confirmed the hand check on 2026-09-24.
- **Next:** `cart/02-inventory`, then `cart/04-ram-steal`, then `player/02-demo-hud`.
- **Needs from others:** Evan: `hud_layout.tscn` with the Demo `%` names, for `player/02`.
- **Handoff notes (player/01-controller-camera):**
  - **Anthony, wiring `main.tscn`** (as in `player_drive_test.tscn`): add a `Node` named `PlayerController` with `systems/player/player_controller.gd` **as a child of the player's Cart**. It finds its cart automatically. Instance `systems/player/chase_camera.tscn` as `ChaseCamera` and set **Target** to the player's Cart in the Inspector. Its `Camera3D` is already `current`.
  - The controller sends neutral outside RUSH / FINAL_CALL. The camera needs nothing from `RoundManager`.
  - The camera's spring arm only collides with layer 1 (world), so keep store geometry on layer 1. Tall walls are fine: the camera pulls in instead of clipping.
  - Keyboard steering eases in over 0.15 s. The gamepad stick is direct.

---

## Cart: Rickey

**Status:** 🟢 · **Branch:** `cart/03-shopper` (stacked on #6 → #5 → #4) · **Current feature:** `cart/03-shopper` (box placeholder) · `cart/02-inventory` in PR #6 · `cart/01-movement` in PR #4 · **Updated:** 2026-09-24 (Rickey, Claude Code)

- **Done:** `cart/01-movement` (PR #4): arcade driving. `cart/02-inventory` built: 24-item cap, 1.2%/item slowdown, colored item cubes, real `try_add_item` / `take_all_items`. **GUT: 8 scripts, 59/59 passing, no script errors.** Test scene `systems/cart/test/cart_drive_test.tscn` now has 30 test pickups and a green checkout pad (Cmd+R).
- **In progress:** PR #6 for `cart/02` (stacked on #5). Rickey confirmed the hand check on 2026-09-24.
- **Next:** `cart/04-ram-steal` (steal rule, transfer, spills, stun/immunity).
- **cart/03-shopper:** every cart has a static box person pushing it (`Visual/Shopper`, visual only, no collision). Evan's model replaces it.
- **Needs from others:**
  - **Anthony:** aisles **at least 3.5 m wide**; floor/shelves/walls on physics layer 1; start markers facing the store (cart front = −Z).
  - **Evan (new, cart/03-shopper):** `assets/models/shopper/shopper_visual.tscn`: the person pushing every cart. The spec is in the ASSETS.md §5 manifest row. A box placeholder is in `cart.tscn` at `Visual/Shopper` until then; keep it slim, because from the chase cam it stands between the camera and the cart.
  - **Evan:** `assets/models/cart/cart_visual.tscn` fitting **0.8 × 1.0 × 1.2 m**, front **−Z**, origin at floor center, with a **Marker3D `ItemStack`** on top of the basket (items stack up to ~1 m above it) plus `Rim`, `Handle`, `Flag`, `NameTag` per ASSETS.md §5.
- **Handoff notes:**
  - **Driving (cart/01, D-017):** call `cart.apply_command(cmd)` every physics frame (no call = neutral). Steer +1 = right. Half gas = half speed. Hold brake below 0.3 m/s to reverse (max 4 m/s, never steals). Carts ignore input unless `RoundManager.phase` is RUSH or FINAL_CALL; in test scenes set `RoundManager.phase = GameTypes.Phase.RUSH`. Carts block each other on contact (no steal until cart/04-ram-steal).
  - **Carrying (cart/02, D-018):**
    - **Anthony (Pickup):** call `cart.try_add_item(item)`; if it returns **false** (full, round locked, duplicate), leave the pickup on the floor. On true, `item_collected(cart, item)` has already fired.
    - **Anthony (checkout):** `cart.take_all_items()` returns the same `ItemData` instances oldest first and empties the cart; it works in any phase, so your deferred checkout after close is fine.
    - **John (Rivals):** `cart_full(cart)` fires once when a cart reaches 24 — your "go bank" trigger. `cart.get_state()` gives `items.size()`, `value`, `speed`, `position` for deciding whom to ram.
  - Handling and cap numbers: `systems/cart/cart_tuning.tres`. Rules: `cart_motion.gd`, `cart_inventory.gd`.

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
