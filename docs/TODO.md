# TODO: Project Backlog

The coarse backlog, by milestone and system. Each owner ticks **only their own items**. Detailed checklists live in each feature's `03-todo.md` (or `FEATURE.md`). When you start an item, link its feature folder.

Scope and numbers for every item come from [`GAME_SPEC.md`](GAME_SPEC.md). Interfaces come from [`CONTRACTS.md`](CONTRACTS.md).

---

## M0: Foundation (Wed 09-23, tonight)

- [ ] **All:** merge `docs/00-project-specs` (this documentation). *(Rickey opens the PR; one teammate reviews)*
- [ ] **All:** read `CONTRACTS.md` v0.1 and sign P-001 in `DECISIONS.md` (or propose changes), by Thu 09-24 morning
- [ ] **Integration** `integration/00-foundation` (Full). *(Rickey drafts, Anthony reviews `project.godot`)*
  - [ ] `systems/shared/`: `game_types.gd`, `drive_command.gd`, `item_data.gd`, `cart_state.gd`, `round_results.gd`, `shopper_profile.gd`, and `profiles/*.tres` for player, Carl, Bev, Rita
  - [ ] Stubs with every contract signal and method (empty bodies): `systems/cart/cart.gd` + `Cart.tscn`, `systems/store/round_manager.gd`, `systems/store/pickup.gd`
  - [ ] `project.godot`: input actions (`drive_gas`, `drive_brake`, `steer_left`, `steer_right`, `boost`, `pause`), physics layer names, `RoundManager` autoload
  - [ ] GUT installed in `addons/gut/`, `.gutconfig.json`, and one passing smoke test in `tests/shared/`
  - [ ] Folders: `systems/{player,cart,rivals,store}/test/`, `tests/{player,cart,rivals,store,shared}/`
  - [ ] GUT version recorded in `TECH_STACK.md`

## Demo: one full round (Fri 09-25)

Integration order (from the GDD): **Cart + Player → Store → Rivals.**

### Cart (Evan)
- [ ] `cart/01-movement`: drive from `DriveCommand` (throttle, brake/reverse, steer), 15 m/s top speed, arcade feel, physics body choice logged in `DECISIONS.md`, test scene with a scripted driver
- [ ] `cart/02-inventory`: `try_add_item`, 24-item cap, 1.2%/item slowdown, `take_all_items`, `get_state`, `item_collected` / `cart_full`, simple stacked-item visuals, `reset_for_round`
- [ ] `cart/03-ram-steal`: steal rule (≥ 5 m/s and ≥ 1.5 m/s faster, at contact), transfer up to cap, deterministic spill list, knockback, 0.7 s stun, 1.6 s immunity, `cart_robbed` exactly once, GUT tests for the 20-into-8 case
- [ ] *(if time)* basic boost: +8 m/s, ~2 s drain, ~8 s refill

### Player (Rickey)
- [ ] `player/01-controller-camera`: input actions → `DriveCommand`, chase cam 8.5 m behind / 5.5 m up / 62° FOV looking ahead, test scene driving the `Cart` stub
- [ ] `player/02-demo-hud` (Lite): timer + round (red during `FINAL_CALL`), scoreboard (banked + current cart value for all 4), cart panel (count / 24, value), plain round-results panel

### Store / Round Manager (Anthony)
- [ ] `store/01-greybox-store`: floor, 6 color-coded aisles, front doors, checkout zone outside, 4 start positions, baked `NavigationRegion3D`; `main.tscn` wired per `CONTRACTS.md` §7
- [ ] `store/02-round-flow`: `RoundManager` single round: `COUNTDOWN` 3 s → `RUSH` → `FINAL_CALL` 20 s → `CLOSED` → `RESULTS` 10 s; `phase_changed`, `round_started`, `round_ended`, `is_gameplay_active`; doors open and close
- [ ] `store/03-spawns-checkout`: `Pickup`, weighted spawns in category aisles, 46 cap, 0.5 s interval, `item_id` assignment, checkout via deferred `take_all_items` + `checked_out`, spill spawning from `cart_robbed`, conservation GUT test

### Rivals (John)
- [ ] `rivals/01-basic-bot`: `BotController` deciding every 0.3 s (value ÷ distance target; bank when greedy or time is short; opportunistic ram), `NavigationAgent3D` pathing (waypoint fallback), 1 s unstick, test scene with dummy pickups

### Integration (Anthony, with each owner)
- [ ] Thu 09-24 evening: merge Cart + Player → drivable cart in `main.tscn`
- [ ] Thu 09-24 evening: merge Store → one solo round playable start to finish
- [ ] Fri 09-25 morning: merge Rivals → 1 human + 3 bots
- [ ] Run the first integration check (`GAME_SPEC.md` §11.2 steps 1–3) in game and in GUT
- [ ] Demo dry run: one full round, no errors in the output panel

## Final (Fri 10-02; code freeze Thu 10-01 night)

### Cart (Evan)
- [ ] Boost meter: +8 m/s, ~2 s drain, ~8 s refill, exposed in `CartState.boost_meter`
- [ ] `apply_slip()` for wet floor: 1 s no steering, sliding
- [ ] Visuals: colored rim, handle and flag from `ShopperProfile`, floating name tag, items fly between carts on a steal

### Player (Rickey)
- [ ] Boost FOV 62° → 72°, camera shake when rammed, controller rumble
- [ ] Popups ("Inherited! +7 items", "Checked out $180") and the event feed using the inheritance wording
- [ ] Minimap under the timer
- [ ] Receipt-style round results and match results with Shopper ID card and stamps
- [ ] Shopper ID card screens: title, character select, bot intro cards; Grandma's Card story intro; card reissued on a match win
- [ ] Audio: muzak (speeds up in the final 20 s), PA calls (doors, Deal of the Day, hazards, final call), SFX (pickup, crash, steal, register, squeaky wheel); audio starts after the first input
- [ ] Pause menu

### Store / Round Manager (Anthony)
- [ ] Best of 3: stamps, tie rules, `RoundResults`, 10 s results between rounds, carts reset empty, `MATCH_OVER`
- [ ] Deal of the Day: gold $100, one at a time, every 14–22 s, light beam, `deal_spawned`; spilled Deal keeps gold and $100
- [ ] Hazards: wet floor (sign + slip), pallet jack (crossing obstacle), falling display (1 s wobble, 5 s block), `hazard_spawned`, more frequent each round
- [ ] Web export built and tested through a local server
- [ ] Art pass on the store: checkered mint-and-cream floor, aisle signs, grand-opening banner

### Rivals (John)
- [ ] Personalities: Carl (rammer), Bev (safe banker), Rita (speed demon) with greed, aggression, boost habit
- [ ] Aggression rises each round
- [ ] Retarget on `cart_robbed`; reroute on `hazard_spawned`; go for Deal of the Day on `deal_spawned`
- [ ] Boost use based on boost habit

### Integration (Anthony, with all)
- [ ] Full match playtest (3 rounds) with notes → tuning pass on `GAME_SPEC.md` §12
- [ ] `GAME_SPEC.md` §11.2 step 4 (Deal of the Day in a spill)
- [ ] Final web build, submission package, README updated

## Stretch (only after Final runs end to end)

- [ ] Sample lady hazard (Store)
- [ ] "Cleanup on aisle X" closures + bot reroute (Store, Rivals)
- [ ] Cart types: heavy, fast, big basket (Cart)
- [ ] Round-winner card perk, e.g. +2 cart slots next round (Store, Cart)
- [ ] Local split-screen: 2 players + 2 bots (Player, Store)
- [ ] Online multiplayer (All)
