# TODO: Project Backlog

The coarse backlog, by milestone and owner. Each owner ticks **only their own items**. Detailed checklists live in each feature's `03-todo.md` (or `FEATURE.md`). When you start an item, link its feature folder.

Scope and numbers for every item come from [`GAME_SPEC.md`](GAME_SPEC.md). Interfaces come from [`CONTRACTS.md`](CONTRACTS.md). Asset paths come from [`ASSETS.md`](ASSETS.md). Review pairs and checkpoints are in [`TEAM.md`](TEAM.md).

---

## M0: Foundation (Wed 09-23, tonight)

- [ ] **All:** merge `docs/00-project-specs` (this documentation). *(Rickey opens the PR; one teammate reviews)*
- [ ] **All:** read `CONTRACTS.md` v0.1 and `ASSETS.md`, and sign P-001 in `DECISIONS.md` (or propose changes), by Thu 09-24 morning
- [ ] **Integration** `integration/00-foundation` (Full). *(Rickey drafts, Anthony reviews `project.godot`)*
  - [x] `systems/shared/`: `game_types.gd`, `drive_command.gd`, `item_data.gd`, `cart_state.gd`, `round_results.gd`, `shopper_profile.gd`, and `profiles/*.tres` for player, Carl, Bev, Rita
  - [x] Stubs with every contract signal and method (empty bodies): `systems/cart/cart.gd` + `cart.tscn`, `systems/store/round_manager.gd`, `systems/store/pickup.gd`
  - [x] `project.godot`: input actions (`drive_gas`, `drive_brake`, `steer_left`, `steer_right`, `boost`, `pause`), physics layer names, `RoundManager` autoload
  - [x] GUT installed in `addons/gut/`, `.gutconfig.json`, and one passing smoke test in `tests/shared/`
  - [x] Folders: `systems/{player,cart,rivals,store}/test/`, `tests/{player,cart,rivals,store,shared}/`
  - [ ] Foundation PR reviewed by Anthony and merged (after PR #1)
  - [x] GUT version recorded in `TECH_STACK.md`
- [ ] **Assets (Evan)** `assets/01-placeholders` (Lite): `assets/` folders, palette materials, and placeholder visual scenes (primitive + palette color, correct root and named parts) at every **Demo** path in the `ASSETS.md` manifest

## Demo: one full round (Fri 09-25)

**Order:** Cart movement first (everyone depends on it) → Cart + Player → Store → Rivals. Evan's visuals swap in any time.

### Cart (Rickey)
- [ ] `cart/01-movement`: drive from `DriveCommand` (throttle, brake/reverse, steer), 15 m/s top speed, arcade feel, physics body choice logged in `DECISIONS.md` (Q-006), `Visual` child instancing `cart_visual.tscn`, test scene with a scripted driver. **Merge by Thu noon.**
- [ ] `cart/02-inventory`: `try_add_item`, 24-item cap, 1.2%/item slowdown, `take_all_items`, `get_state`, `item_collected` / `cart_full`, items stacked at `ItemStack`, `reset_for_round`
- [ ] `cart/03-shopper` (Lite): box-placeholder shopper pushing every cart (visual only); Evan's model replaces it
- [ ] `cart/04-ram-steal`: steal rule (≥ 5 m/s and ≥ 1.5 m/s faster, at contact), transfer up to the cap, deterministic spill list, knockback, 0.7 s stun, 1.6 s immunity, `cart_robbed` exactly once, GUT tests for the 20-into-8 case
- [ ] *(if time)* basic boost: +8 m/s, ~2 s drain, ~8 s refill

### Player (Rickey)
- [ ] `player/01-controller-camera`: input actions → `DriveCommand`, chase cam 8.5 m behind / 5.5 m up / 62° FOV looking ahead, test scene driving the Cart
- [ ] `player/02-demo-round` (Lite): fallback playable demo round in `systems/player/demo/` (stand-in for Store round/store and Rivals bots)
- [ ] `player/03-demo-hud` (Lite): fill Evan's `hud_layout.tscn`: timer + round (red during `FINAL_CALL`), scoreboard (banked + current cart value for all 4), cart panel (count / 24, value); plain round-results panel

### Store / Round Manager (Anthony)
- [ ] [`store/01-greybox-store`](features/store/01-greybox-store/01-spec.md): floor, 6 color-coded aisles (Evan's shelf placeholders), front doors, checkout zone outside, 4 start positions, baked `NavigationRegion3D`; `main.tscn` wired per `CONTRACTS.md` §7.1. Draft on `Anthony-Stores`, awaiting spec approval.
- [ ] [`store/02-round-flow`](features/store/02-round-flow/01-spec.md): `RoundManager` single round: `COUNTDOWN` 3 s → `RUSH` → `FINAL_CALL` 20 s → `CLOSED` → `RESULTS` 10 s; `phase_changed`, `round_started`, `round_ended`, `is_gameplay_active`; doors open and close (`LeftDoor` / `RightDoor`). Draft on `Anthony-Stores`, awaiting spec approval.
- [ ] [`store/03-spawns-checkout`](features/store/03-spawns-checkout/01-spec.md): `Pickup` (with the item's visual), weighted spawns in category aisles, 46 cap, 0.5 s interval, `item_id` assignment, checkout via deferred `take_all_items` + `checked_out`, spill spawning from `cart_robbed`, conservation GUT test. Draft on `Anthony-Stores`, awaiting spec approval.

### Rivals (John)
- [x] [rivals/01-basic-bot](features/rivals/01-foundation/): `BotController` deciding every 0.3 s (value ÷ distance target; bank when greedy or time is short; opportunistic ram), `NavigationAgent3D` pathing (waypoint fallback), 1 s unstick, test scene with dummy pickups

### Assets (Evan)
- [ ] `assets/02-demo-hud-layout` (Lite): `hud_layout.tscn` with `%TimerLabel`, `%RoundLabel`, `%ScoreList`, `%CartCountLabel`, `%CartValueLabel`, plus a plain `receipt_layout.tscn`. **By Thu afternoon**
- [ ] Cart v1 model (rim, handle, flag, basket) in `cart_visual.tscn`
- [ ] Item v1 models ×6 (one recognizable shape per category, aisle colors)
- [ ] Aisle shelf v1 with color sign

### Integration (Anthony, with each owner)
- [ ] **Checkpoint 1, Thu 09-24 6 pm:** merge Cart + Player → drivable cart in `main.tscn`; merge Store → one solo round playable start to finish
- [ ] **Checkpoint 2, Fri 09-25 9 am:** merge Rivals → 1 human + 3 bots
- [ ] Run the first integration check (`GAME_SPEC.md` §11.2 steps 1–3) in game and in GUT
- [ ] Demo dry run: one full round, no errors in the output panel

## Final (Fri 10-02; code freeze Thu 10-01 night)

### Cart (Rickey)
- [ ] Boost meter: +8 m/s, ~2 s drain, ~8 s refill, exposed in `CartState.boost_meter`
- [ ] `apply_slip()` for wet floor: 1 s no steering, sliding
- [ ] Tint `Rim` / `Handle` / `Flag` from `ShopperProfile.color`; name tag at `NameTag`; items fly between carts on a steal
- [ ] Bounce sound and squeaky-wheel loop (pitch follows speed)

### Player (Rickey)
- [ ] Boost FOV 62° → 72°, camera shake when rammed, controller rumble
- [ ] Popups ("Inherited! +7 items", "Checked out $180") and the event feed (`%FeedList`) using the inheritance wording
- [ ] Minimap (`%Minimap`), boost bar (`%BoostBar`)
- [ ] Receipt-style round results and match results with the Shopper ID card and stamps
- [ ] Shopper ID card screens: title, character select, bot intro cards; Grandma's Card story intro; card reissued on a match win
- [ ] Audio playback per the `ASSETS.md` §4 event table; audio starts after the first input
- [ ] Pause menu

### Store / Round Manager (Anthony)
- [ ] Best of 3: stamps, tie rules, `RoundResults`, 10 s results between rounds, carts reset empty, `MATCH_OVER`
- [ ] Deal of the Day: gold $100, one at a time, every 14–22 s, `Beam`, `deal_spawned`; spilled Deal keeps gold and $100
- [ ] Hazards: wet floor (sign + slip), pallet jack (crossing obstacle), falling display (1 s wobble of `Stack`, 5 s block), `hazard_spawned`, more frequent each round
- [ ] Place Evan's final store art (floor, banner, signs) in the store scene
- [ ] Web export built and tested through a local server

### Rivals (John)
- [ ] Personalities: Carl (rammer), Bev (safe banker), Rita (speed demon) with greed, aggression, boost habit
- [ ] Aggression rises each round
- [ ] Retarget on `cart_robbed`; reroute on `hazard_spawned`; go for Deal of the Day on `deal_spawned`
- [ ] Boost use based on boost habit

### Assets (Evan)
- [ ] Final models: cart, 6 items, Deal of the Day (with `Beam`), shelves, doors, checkout, banner, floor checker
- [ ] Hazard models: wet floor sign, pallet jack + employee, can display (`Stack`)
- [ ] UI: full `hud_layout.tscn` (`%BoostBar`, `%FeedList`, `%Minimap`), final `receipt_layout.tscn`, `id_card_layout.tscn`, title and story art, fonts
- [ ] Audio: muzak loop, PA lines, all sound effects in the `ASSETS.md` §4 table
- [ ] Credits table in `ASSETS.md` §6 complete

### Integration (Anthony, with all)
- [ ] Evening checkpoints Sat 09-26 to Thu 10-01
- [ ] Full match playtest (3 rounds) with notes → tuning pass on `GAME_SPEC.md` §12
- [ ] `GAME_SPEC.md` §11.2 step 4 (Deal of the Day in a spill)
- [ ] Final web build, submission package, README updated

## Stretch (only after Final runs end to end)

- [ ] Sample lady hazard (Store, Assets)
- [ ] "Cleanup on aisle X" closures + bot reroute (Store, Rivals)
- [ ] Cart types: heavy, fast, big basket (Cart, Assets)
- [ ] Round-winner card perk, e.g. +2 cart slots next round (Store, Cart)
- [ ] Local split-screen: 2 players + 2 bots (Player, Store)
- [ ] Online multiplayer (All)
