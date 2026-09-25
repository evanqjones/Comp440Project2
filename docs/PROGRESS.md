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

**Status:** 🟢 · **Branch:** `player/02-demo-round`, merged into `integration/01-demo` · **Current feature:** fallback demo round, done · **Updated:** 2026-09-25 (Rickey, Claude Code)

- **Done:** `player/01-controller-camera` (PR #5). `player/02-demo-round`: a **fallback demo** at `systems/player/demo/demo_round.tscn` (open it and press Cmd+R): greybox store, 2:00 round, real cart + controller + chase camera, 3 patrolling rammer bots, checkout pad, spills, plain HUD and results. **GUT: 11 scripts, 78/78 passing.**
- **In progress:** nothing. PR #10 is merged into `integration/01-demo`, and the demo now uses Evan's shoppers (see Cart, `cart/05-evan-shopper`).
- **Next:** `player/03-demo-hud` (the real HUD, filling Evan's `hud_layout.tscn` once it exists).
- **Needs from others:** Evan: `hud_layout.tscn` with the Demo `%` names, for `player/03`.
- **Handoff notes:**
  - **Wiring `main.tscn` (Anthony):** a `Node` named `PlayerController` with `systems/player/player_controller.gd` as a child of the player's Cart (it finds the cart itself); instance `systems/player/chase_camera.tscn` and set **Target** to the player's Cart. See `player_drive_test.tscn` or `demo_round.gd` for working examples.
  - **The fallback demo is a stand-in:** it sets `RoundManager.phase` and time from its own clock, spawns spills itself and uses test-only rammers. Anthony's RoundManager/store and John's bots replace it in `main.tscn`; nothing in `main.tscn` depends on it.

---

## Cart: Rickey

**Status:** 🟢 · **Branch:** `cart/05-evan-shopper`, cut from `integration/01-demo` and merged back into it · **Current feature:** `cart/05-evan-shopper`, built · PRs #4 #6 #7 #9 open (all already in `integration/01-demo`) · **Updated:** 2026-09-25 (Rickey, Claude Code)

- **Done:** `cart/01-movement` (PR #4), `cart/02-inventory` (PR #6), `cart/03-shopper` (PR #7), `cart/04-ram-steal` built: steals resolve exactly once, the robbed cart tips over, and items fly into the winner. **GUT: 10 scripts, 76/76 passing, no script errors** (includes the GDD §11.2 20-into-8 check: 28 item IDs and $370 conserved, plus a real physics ram).
- **cart/05-evan-shopper (D-021):** Evan's animated man-and-cart model (`Blender/man_cart_godot.fbx`) now pushes **every** cart, player and bots, in `cart.tscn` at `Visual/ShopperModel`. `CartShopperAnimator` picks idle/walk/turn/backwards from the cart's motion, plays hit then stunned when robbed (while the cart tips over), tints the shirt and handle with the profile color, and keeps the item cubes in the swinging basket. The box placeholders are hidden, not deleted. **GUT: 11 scripts, 82/82 passing, no script errors.** Render-checked: wheels on the floor, basket over the collision box, four colors, items in the basket through turns, tip-over.
- **In progress:** Rickey's hand check of the combined demo (`systems/player/demo/demo_round.tscn`).
- **Next:** `player/03-demo-hud` (timer, scores, cart panel).
- **cart/03-shopper:** the static box person (`Visual/Shopper`), now hidden and replaced by Evan's model (cart/05).
- **Needs from others:**
  - **Anthony:** aisles **at least 3.5 m wide**; floor/shelves/walls on physics layer 1; start markers facing the store (cart front = −Z).
  - **Evan (cart/05):** code now depends on these parts of `man_cart_godot.fbx`; keep them when you re-export: the clip names (`idle`, `walk`, `turn`, `backwards`, `hit`, `stunned` after the `|`), the materials **"Petrol blue cotton"** and **"Handle orange"** (tinted per shopper) and the **`CART`** bone (the item cubes ride on it). If you move the file to `assets/models/…`, tell Rickey and he'll repoint `cart.tscn`.
  - **Evan (cart/05):** **186 skinned parts per cart** means about 750 draw calls for 4 carts. It's fine on desktop; for the web build, please merge parts that share a material (for example all the steel wires into one mesh).
  - **Evan (cart/05):** your preview `assets/test/fbx_cart_test.tscn` adds its own `FBXCart` to a cart that now already has the model, so it shows two. Delete `FBXCart` (and the model code) from the preview, or drive `demo_round.tscn` instead.
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
  - **Shopper model (cart/05):** set `cart.profile` before `add_child` (or any time; the tint follows profile changes). The man stands about 1 m behind the cart's origin, **outside** the collision box, like the old box person. Model offset: (0, 0, 1.0); Evan's preview lifted it 0.415 m, which floats it, because animated poses already start at y = 0.

---

## Rivals: John

**Status:** 🟢 · **Branch:** `rivals/02-cart-integration` · **Current feature:** `rivals/02-cart-integration` · **Updated:** 2026-09-25 (John, Gemini CLI)

- **Done:** `Step 1.1` (BotPersonality resource script), `Step 1.2` (base BotController and round timer wiring), `Step 2.1` (COLLECTING state utility scoring math), and `Step 2.2` (BANKING state transitions) implemented and tested (89/89 tests passing, 0 script errors).
- **In progress:** Step 3.1: CHASING state target selection and aggression gates.
- **Next:** Implement FSM chasing targets, aggression scaling, stuck recovery, and blacklist.
- **Needs from others:** Foundation (`Cart` stub, `RoundManager` stub with `get_pickups()` and `get_checkout_position()`).
- **Handoff notes:** The `BotController` is now available and fully wired to `RoundManager`'s signals. It automatically starts/stops its 0.3s decision timer on `round_started` and `round_ended`, and locks inputs (throttle/steer/boost to 0) outside active gameplay phases (e.g. `COUNTDOWN`). Teammates can instance `BotController` and assign customized `BotPersonality` resources to customize rival profiles.

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
