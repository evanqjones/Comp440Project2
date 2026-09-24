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

**Status:** 🟡 · **Branch:** `Anthony-Stores` · **Current feature:** Thursday solo-round integration preparation · **Updated:** 2026-09-24 (Anthony, Codex)

- **Done:** Project docs (PR #1). `integration/00-foundation` built: shared contract scripts + profiles, `Cart` / `RoundManager` / `Pickup` stubs, input map, physics layer names, `RoundManager` autoload, GUT 9.7.1. **GUT: 3 scripts, 17/17 tests passing, 133 asserts, no script errors.** The main scene runs headless for 120 frames with no errors.
- **In progress:** Synced main at `ea20425` (docs and foundation merged) and created Anthony's requested `Anthony-Stores` branch. Drafted Thursday Store specifications; no gameplay changes yet.
- **Next:** Anthony reviews the Store drafts and explicitly approves the planned `main.tscn` edit before integration. Build and verify one approved plan step at a time.
- **Needs from others:** Rickey: actual Cart movement/inventory, Player controller, chase camera and Demo HUD; Evan: Demo visual scenes and palettes. Current checkout has Cart stubs, no Player/Rivals implementations and no `assets/` directory. Existing P-001 signatures remain unsigned in `DECISIONS.md`; this session does not sign for anyone.
- **Handoff notes (2026-09-24):** Thursday integration is Step 2.1 of `docs/features/store/01-greybox-store/02-plan.md`, after all three Store features and required owner dependencies. Friday bot integration and PR merges are not authorized by this task. Full GUT command attempted but did not start: `godot` is not recognized on PATH. The foundation test result below is historical, not a result from this session.
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

**Status:** ⚪ · **Branch:** — · **Current feature:** — · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** —
- **In progress:** —
- **Next:** `rivals/01-basic-bot` (Demo). Start in a test scene with dummy pickups, a flat navmesh and the `Cart` stub; switch to the real Cart when `cart/01-movement` merges.
- **Needs from others:** Foundation (`Cart` stub, `RoundManager` stub with `get_pickups()` and `get_checkout_position()`).
- **Handoff notes:** —

---

## Store / Round Manager: Anthony

**Status:** 🟡 · **Branch:** `Anthony-Stores` · **Current feature:** Thursday Demo Store specs awaiting review · **Updated:** 2026-09-24 (Anthony, Codex)

- **Done:** Synced main and created `Anthony-Stores`. Draft brainstorm/spec/plan/TODO sets prepared in `docs/features/store/01-greybox-store/`, `02-round-flow/`, and `03-spawns-checkout/`. Existing shared signatures and gameplay numbers preserved.
- **In progress:** Human review required by AGENTS.md Rule 4; no feature code written and no Thursday completion boxes ticked.
- **Next:** Approve drafts, then execute greybox Step 1.1 once its asset prerequisites exist. Proposed Demo defaults needing review: floor initially empty (first spawn after 0.5 active seconds); return to IDLE after 10 seconds of results, awaiting an explicit restart. Best-of-three/stamps remain Final scope.
- **Needs from others:** Evan: palette, shelf, doors, checkout and six item visuals at ASSETS.md paths (the entire assets directory is currently absent). Rickey: Cart implementation for actual pickup/checkout hand checks. Local verification needs the pinned Godot console executable; `godot` is not on PATH.
- **Handoff notes:** All three specs are Draft, not approved. Store seam tests may use a controlled Cart double only in `tests/store/`; they must not be described as actual Cart collision verification. Plans preserve deferred checkout, one-frame-delayed close results, item identities and spawning only `spilled`. Full GUT command attempted on 2026-09-24 but could not launch (`godot` not recognized); no pass claimed. Only Anthony's tracking and feature documents changed.

---

## Assets: Evan

**Status:** ⚪ · **Branch:** — · **Current feature:** — · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** —
- **In progress:** —
- **Next:** `assets/01-placeholders` tonight: the `assets/` folders, palette materials, and placeholder visual scenes at every Demo path in the `ASSETS.md` manifest. Then `assets/02-demo-hud-layout` by Thu afternoon.
- **Requests in:** see the `ASSETS.md` manifest (rows with status ⬜).
- **Needs from others:** Rickey and Evan to settle bot cart colors (`DECISIONS.md` Q-003).
- **Handoff notes:** —
