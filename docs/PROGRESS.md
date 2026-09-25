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

**Status:** 🟢 · **Branch:** `cart/04-ram-steal` (stacked on #7 → #6 → #5 → #4) · **Current feature:** `cart/04-ram-steal`, built and hand-checked · PRs #4 #6 #7 open · `cart/01-movement` in PR #4 · **Updated:** 2026-09-24 (Rickey, Claude Code)

- **Done:** `cart/01-movement` (PR #4), `cart/02-inventory` (PR #6), `cart/03-shopper` (PR #7), `cart/04-ram-steal` built: steals resolve exactly once, the robbed cart tips over, and items fly into the winner. **GUT: 10 scripts, 76/76 passing, no script errors** (includes the GDD §11.2 20-into-8 check: 28 item IDs and $370 conserved, plus a real physics ram).
- **In progress:** PR for `cart/04` (stacked on #7). Rickey confirmed the hand check on 2026-09-25.
- **Next:** `player/02-demo-hud` (timer, scores, cart panel).
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
  - **Ram-steal (cart/04, D-019):**
    - **Anthony (spills):** connect to `cart_robbed(winner, loser, items, spilled)` on **each registered cart**. It's emitted **by the loser**, once per steal, after both inventories update. Spawn **only `spilled`** (the same `ItemData` instances) around `loser.global_position`. `items` are already in the winner's cart.
    - **John (Rivals):** `cart_robbed` is your retarget cue. Don't bother ramming a cart whose `get_state().is_immune` is true (it just got robbed; 1.6 s). A stunned bot (`is_stunned`) has no control for 0.7 s. To steal you need ≥ 5 m/s and ≥ 1.5 m/s more than the target, and reverse never qualifies.
    - **Everyone spawning carts in code:** set the cart's `position` **before** `add_child`. Two carts added at the same spot, even for an instant, get shoved apart by physics.

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

**Status:** 🟡 · **Branch:** `assets/01-fbx-cart-test` · **Current feature:** FBX cart driving preview · **Updated:** 2026-09-25 (Codex)

  - **Done:** Created `assets/test/fbx_cart_test.tscn` with the existing Cart, PlayerController and ChaseCamera. It instances `Blender/man_cart_godot.fbx`, hides placeholder art, adds a compact obstacle course/readout and maps cart direction/steering/boost to imported animation clips. Left turns horizontally mirror the turn pose, clip changes crossfade over 0.2 seconds, all animations play at twice their previous rate, and a subtle speed-driven squash/stretch with lift fades at rest. Fixed a GDScript parse error from an inferred Variant; the preview launches with no new editor errors. Godot MCP is installed and connected locally.
- **In progress:** Focused reverse/braking, collision and camera checks remain; Evan reports the model and animations look good.
- **Next:** Finish focused driving checks, then placeholder assets and demo HUD remain outstanding.
- **Requests in:** see the `ASSETS.md` manifest (rows with status ⬜).
- **Needs from others:** Rickey and Evan to settle bot cart colors (`DECISIONS.md` Q-003).
  - **Handoff notes:** Preview branch is based on `origin/cart/03-shopper`; `main` still has Cart movement stubs. Use `assets/test/fbx_cart_test.tscn` (F6) for the standalone driving preview. The original `man_shopping_cart.fbx` imports without clips; `man_cart_godot.fbx` imports eight baked clips and is the preview source. Runtime state confirms the cart and 186-mesh model instance; the script maps movement states to clips, horizontally mirrors the model during left-turn animation, crossfades clip changes over 0.2 seconds, applies a 2x playback multiplier, and adds a subtle speed-driven squash/stretch and lift. Scene relaunches without new editor errors. Evan reports that the model and animations look good; reverse/braking, obstacle and camera framing checks are still open. Godot MCP is a local-only addon and is enabled in the current project configuration; don't include addon files/config in the game feature PR unless the team agrees to keep the plugin.
