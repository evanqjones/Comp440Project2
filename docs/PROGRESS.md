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

**Status:** 🟢 · **Branch:** — (everything is merged into `main` via #15) · **Current feature:** — · **Updated:** 2026-09-25 (Rickey, Claude Code)

- **Done:** `player/01-controller-camera` (PR #5). `player/02-demo-round`: a **fallback demo** at `systems/player/demo/demo_round.tscn` (open it and press Cmd+R): greybox store, 2:00 round, real cart + controller + chase camera, 3 patrolling rammer bots, checkout pad, spills, plain HUD and results. **GUT: 11 scripts, 78/78 passing.** `player/03-demo-bots` (D-023): John's `BotController` drives Carl, Bev and Rita in the fallback demo (GAME_SPEC personalities), steering on a navmesh baked from the demo store. `DemoRoundManager` stands in for the RoundManager stub while the demo runs, and the demo fires `round_started` / `round_ended`. The HUD shows each bot's state. **GUT: 13 scripts, 109/109 passing.** Headless round: bots collect, chase, rob and check out (with John's two fixes, D-024).
- **In progress:** nothing. The demo with John's bots is on `main`, and Run Project plays it (D-025).
- **Next:** `player/04-demo-hud` (the real HUD, filling Evan's `hud_layout.tscn` once it exists).
- **Needs from others:** Evan: `hud_layout.tscn` with the Demo `%` names, for `player/04`.
- **Handoff notes:**
  - **player/04-feel:** getting robbed = a strong camera shake (0.35 m) plus rumble; robbing someone = a small bump; bot-on-bot = nothing. `ChaseCamera.shake()` and `PlayerFeedback` watch every cart's `cart_robbed`. **GUT: 16 scripts, 129/129.** Checked with Run Project: a real steal from the player shook the camera and faded out.
  - **player/05-pause-menu:** Esc / Start pauses the whole game (clock, carts, bots). `PauseMenu` offers Resume / Restart round / Quit (Quit hidden on web). **GUT: 17 scripts, 135/135.** Checked with Run Project: the clock froze while paused and resumed after; the menu screenshot is in the PR.
  - **player/06-hud:** `PlayerHud` shows:
    - timer (red at final call) and round;
    - a scoreboard sorted by banked, in profile colors;
    - the cart panel (count/cap, value, yellow boost bar);
    - an event feed ("Rita inherited Carl's cart", "Bev checked out $120", "You"/"your" for the player);
    - popups for the player ("Inherited! +7 items", "Knocked out of the sale!", "Checked out $180").

    It uses **Evan's `assets/ui/hud_layout.tscn` automatically once that file exists**; until then, `systems/player/hud/placeholder_hud_layout.tscn` has the same `%` names. The bot-state text from the old demo HUD is gone. **GUT: 18 scripts, 145/145.** Checked with Run Project (screenshot in the PR).
  - **player/07-minimap:** `HudMinimap` in the HUD's `%Minimap`. It reads the level itself (standing box-shaped static bodies on layer 1 = outline, floor skipped) and draws the checkout plus a colored dot per cart; yours is ringed with a facing tick. North-up = the store's back. **No wiring needed for a new store**, as long as walls and shelves are `StaticBody3D` + `BoxShape3D` on layer 1. **GUT: 19 scripts, 149/149.**
  - **player/08-receipt:** `RoundReceipt` shows a receipt at `round_ended` ("BUMPER CROP MARKET / Round N · Day N of the sale", dot-leader lines most banked first, "★ Stamp: …" or "No stamp today", stamp standings) and hides at `round_started`. It uses **Evan's `assets/ui/receipt_layout.tscn` automatically once it exists** (placeholder with the same `%` names until then). The store name lives in `PlayerStrings.STORE_NAME` (Q-001). The demo's stand-in now fills `winner_ids`, `stamps` and `match_banked` with the §3.2 rule. **GUT: 20 scripts, 156/156.**
  - **Anthony (results):** fill `RoundResults.winner_ids` and `stamps` (cumulative) in your `round_ended`, and the receipt shows them. `DemoRoundManager.round_winners()` is the §3.2 / P-002 rule if you want it.
  - **Anthony (HUD data):** the HUD reads `RoundManager.get_round_banked(id)`, `checked_out(cart, value)`, `get_carts()`, `time_left`, `phase` and `round_number`. Your real RoundManager must fill these; the demo's stand-in does it from `TestCheckoutPad`, which now emits `checked_out`.
  - **Evan (HUD layout):** node types the code expects: Labels for `%TimerLabel`, `%RoundLabel`, `%CartCountLabel`, `%CartValueLabel`; a `Range` (ProgressBar or TextureProgressBar) for `%BoostBar`; containers (VBoxContainer) for `%ScoreList` and `%FeedList`, which the code fills with Labels; and a `Control` for `%Minimap`. Popups are drawn by code on top. The placeholder shows one arrangement.
  - **Wiring `main.tscn` (Anthony):** also add `RoundReceipt.new()` (cart = player), `PlayerHud.new()` with `cart` = the player's Cart, `PauseMenu.new()` (or a node with `pause_menu.gd`) and a `PlayerFeedback` node with `cart` = the player's Cart and `camera` = the ChaseCamera (see `demo_round.gd` → `_build_carts`). Then: a `Node` named `PlayerController` with `systems/player/player_controller.gd` as a child of the player's Cart (it finds the cart itself); instance `systems/player/chase_camera.tscn` and set **Target** to the player's Cart. See `player_drive_test.tscn` or `demo_round.gd` for working examples.
  - **The fallback demo is a stand-in:** it sets `RoundManager.phase` and time from its own clock and spawns spills itself. While it runs, it swaps `DemoRoundManager` (a subclass of the stub) onto the `RoundManager` autoload, which answers `get_pickups()` and `get_checkout_position()`, and puts the stub back on exit. Anthony's RoundManager/store replaces all of it in `main.tscn`; nothing in `main.tscn` depends on it.
  - **Anthony:** John's bots need from your RoundManager exactly what `DemoRoundManager` fakes: `get_pickups()` (untaken `Pickup`s on the floor), `get_checkout_position()`, `register_cart()` for all 4 carts, `time_left`, and `round_started` / `round_ended`. They also need a navmesh of the store (a `NavigationRegion3D`; the demo bakes one with a 0.75 m agent radius) and a `NavigationAgent3D` named `NavigationAgent3D` on each bot cart. See `demo_round.gd` → `_spawn_bot` and `_bake_navmesh`.
  - **John:** `TestPickup` (`systems/cart/test/`) now extends `Pickup`, so it works with your controller in test scenes.
  - **Anthony (D-025):** on `integration/02-demo`, `main.tscn` instances the fallback demo (`DemoRound` child) so Run Project plays it. Replace that child with your store wiring when it's ready.

---

## Cart: Rickey

**Status:** 🟢 · **Branch:** — (everything is merged into `main` via #15) · **Current feature:** — · **Updated:** 2026-09-25 (Rickey, Claude Code)

- **Done:** `cart/01-movement` (PR #4), `cart/02-inventory` (PR #6), `cart/03-shopper` (PR #7), `cart/04-ram-steal` built: steals resolve exactly once, the robbed cart tips over, and items fly into the winner. **GUT: 10 scripts, 76/76 passing, no script errors** (includes the GDD §11.2 20-into-8 check: 28 item IDs and $370 conserved, plus a real physics ram).
- **cart/05-evan-shopper (D-021):** Evan's animated man-and-cart model (`Blender/man_cart_godot.fbx`) now pushes **every** cart, player and bots, in `cart.tscn` at `Visual/ShopperModel`. `CartShopperAnimator` picks idle/walk/turn/backwards from the cart's motion, plays hit then stunned when robbed (while the cart tips over), tints the shirt and handle with the profile color, and keeps the item cubes in the swinging basket. The box placeholders are hidden, not deleted. **GUT: 11 scripts, 82/82 passing, no script errors.** Render-checked: wheels on the floor, basket over the collision box, four colors, items in the basket through turns, tip-over.
- **cart/06-boost (D-028):** boost meter. Holding boost adds +8 m/s top speed, counts as full gas, and accelerates at 20 m/s². The meter drains in 2 s and refills in 8 s while the button is up; running dry locks boost until release, and braking cancels it. The chase camera widens 62°→72°, Evan's `boost` clip plays, and the fallback HUD shows `Boost [#####-----]`. `Cart.is_boosting()` is new (additive). **GUT: 14 scripts, 119/119.** Checked in the real game (Run Project): player boost 9→19 m/s in 0.5 s, the meter drains over 2 s, FOV 72°, and Rita boosts.
- **cart/07-name-tags:** each bot's cart shows a floating billboard name (`Visual/NameTag`, `CartNameTag`) in its profile color. There's none over the human's cart (`cart_id` 0), and none without a profile. **GUT: 15 scripts, 123/123.** Checked with Run Project.
- **In progress:** nothing. Next for Final: results receipt, minimap, title and ID card screens (need Evan's layouts and Anthony's best of 3), audio (needs Evan's files).
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
  - **Boost (cart/06, D-028), John:** your bots' `boost` now does something. It counts as **full gas** (throttle forced to 1) with a 20 m/s² kick, braking cancels it, and a bot that runs the meter dry can't boost again until it sends `boost = false` for a frame. `get_state().boost_meter` (0–1) is live, so you can skip boosting when it's low.
  - **Shopper model (cart/05):** set `cart.profile` before `add_child` (or any time; the tint follows profile changes). The man stands about 1 m behind the cart's origin, **outside** the collision box, like the old box person. Model offset: (0, 0, 1.0); Evan's preview lifted it 0.415 m, which floats it, because animated poses already start at y = 0.

---

## Rivals: John

**Status:** ✅ · **Branch:** `rivals/02-cart-integration` · **Current feature:** `rivals/02-cart-integration` · **Updated:** 2026-09-25 (John, Gemini CLI)

- **Done:** All 10 steps completed! Setup `BotPersonality` resource class, FSM `BotController` node with 0.3s decision timer, active round timer and signal wiring, default COLLECTING utility formula (Value / Distance), threshold-triggered BANKING state (Greed or timer <= 20s), probability-gated CHASING state with tie-breaker sorting, round aggression difficulty scaling (+0.1/round), horizontal stuck speed detection and random reverse recovery steering, unreachable target blacklists, periodic straightway boost checks (< 30 degrees angle offset), and out-of-band responsiveness signals. Created `rivals_test_scene.tscn` visual playground with live overlay readouts. Verified 100% passes on all 102 project-wide unit tests (780 asserts, 0 script errors).
- **In progress:** —
- **Next:** Support Rickey with Cart movement tuning, and integrate bot drivers with spawned carts in `main.tscn` for the playtest round.
- **Needs from others:** —
- **Handoff notes:** The `BotController` is 100% complete, fully tested, and ready for full integration! It runs its decision timer dynamically and lock inputs outside of active gameplay. You can configure rival behaviors in the editor by instancing `BotController` and assigning customized `BotPersonality` profiles. Open and play `systems/rivals/test/rivals_test_scene.tscn` to visually verify Coupon Carl and Rolling Rita navigating, collecting pickups, reversing around obstacles, boosting, and running to checkout!

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
