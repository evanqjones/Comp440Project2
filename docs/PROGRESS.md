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

**Status:** ⚪ · **Branch:** — · **Current feature:** — · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** —
- **In progress:** —
- **Next:** `player/01-controller-camera` (after `cart/01-movement`), then `player/02-demo-hud`, which wires data into Evan's `hud_layout.tscn`.
- **Needs from others:** Evan: `hud_layout.tscn` with the Demo `%` names by Thu afternoon. (Input actions and `DriveCommand` are ready on `integration/00-foundation`.)
- **Handoff notes:** —

---

## Cart: Rickey

**Status:** ⚪ · **Branch:** — · **Current feature:** — · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** —
- **In progress:** —
- **Next:** `cart/01-movement` **first; merge by Thu noon** (everyone depends on it). Then `cart/02-inventory`, `cart/03-ram-steal`.
- **Needs from others:** Evan: `cart_visual.tscn` placeholder. (Stub and shared classes are ready on `integration/00-foundation`; Cart is a `CharacterBody3D` per D-015.)
- **Handoff notes:** —

---

## Rivals: John

**Status:** 🟢 · **Branch:** `rivals/01-foundation` · **Current feature:** `rivals/01-foundation` · **Updated:** 2026-09-24 (John, Gemini CLI)

- **Done:** Step 1.1: `BotPersonality` resource script implemented and unit tested (18/18 tests passing)
- **In progress:** Setup base controller class, FSM decision timer, and test scene (Steps 1.2 to 5.2)
- **Next:** Complete core FSM states, stuck recovery, and wire into the `rivals_test_scene.tscn` flat test scene.
- **Needs from others:** Foundation (`Cart` stub, `RoundManager` stub with `get_pickups()` and `get_checkout_position()`).
- **Handoff notes:** The `BotPersonality` custom resource is registered globals-wide. It exposes greed, base_aggression, and boost_habit fields. You can instantiate it directly in the editor or script.

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
