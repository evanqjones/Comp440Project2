# Decisions Log

Why things are the way they are. **Append new entries at the bottom of the right section.** Don't rewrite old ones; if a decision changes, add a new entry that says "Supersedes D-00X".

- **D-** = decided. **P-** = proposed, waiting for sign-off. **Q-** = open question.
- Format: ID · date · who · decision · why · affects.

---

## Decided

**D-001 · 2026-09-23 · Rickey (confirmed with the team GDD) · Source of truth**
The team GDD (`reference/Checkout Chaos - Four System Team GDD.pdf`) wins when it conflicts with Rickey's earlier GDD. Rickey's GDD supplies extra detail (story directions, hazard details, HUD, audio, multiplayer path). Features the team GDD cut go to the Stretch backlog, not deleted.
*Why:* the team GDD is the later, submitted version with named owners and explicit cuts. *Affects:* `GAME_SPEC.md`.

**D-002 · 2026-09-23 · Team GDD · Round timer is 2:00 every round**
Difficulty rises through hazards and bot aggression, not a shorter timer. *Supersedes:* Rickey's GDD (2:00 / 1:45 / 1:30). *Affects:* Store, Rivals.

**D-003 · 2026-09-23 · Team GDD · No round-winner perk; carts reset empty each round**
The +2 cart slots perk moves to Stretch. *Affects:* Store, Cart.

**D-004 · 2026-09-23 · Team GDD · Match tie-break**
Most stamps wins. On a stamp tie, the highest total banked across all rounds wins. An exact remaining tie is shared. *Affects:* Store, Player (results screen).

**D-005 · 2026-09-23 · Repo setup (Evan) · Engine: Godot 4.7.2 standard, GDScript, Compatibility renderer, Web export with threads off**
*Supersedes:* Rickey's GDD open question "4.3 or newer?". *Why:* pinned in `.godot-version`, and the web target needs the Compatibility renderer. *Affects:* all.

**D-006 · 2026-09-23 · Team GDD · Ownership**
Player: Rickey · Cart: Evan · Rivals: John · Store / Round Manager: Anthony. Anthony is also the **integration owner** (`main.tscn`, `project.godot`, `export_presets.cfg`) because the GDD makes the Store owner the only editor of `Main.tscn`. *Supersedes:* the proposed split in the old `docs/TEAM.md` (Integration / Player / World / UI+Audio). *Affects:* `TEAM.md`, `README.md`. **Superseded by D-012.**

**D-007 · 2026-09-23 · Team GDD · Story: Direction A, Grandma's Card**
Plus the inheritance wording guide from Rickey's GDD (`GAME_SPEC.md` §2.3). *Affects:* Player (screens, feed), all in-game text.

**D-008 · 2026-09-23 · Rickey · Cut features for this build: multiplayer, cart types, sample lady, aisle closures**
All go to Stretch. *Affects:* scope.

**D-009 · 2026-09-23 · Rickey · Milestones**
Demo (one full round) Fri 2026-09-25. Final due Fri 2026-10-02, code freeze Thu 10-01 night. *Affects:* `TODO.md`, `PROGRESS.md`.

**D-010 · 2026-09-23 · Rickey · Docs and agent structure**
`AGENTS.md` is the canonical agent instruction file; `CLAUDE.md` and `GEMINI.md` import it. Docs hub in `docs/`. Spec-driven workflow with Full or Lite feature folders (`WORKFLOW.md`). `PROGRESS.md` has one section per system. *Why:* one place to edit rules, so the three agents can't drift apart; per-section tracking avoids merge conflicts.

**D-011 · 2026-09-23 · Rickey · Testing: GUT + test scenes**
GUT (committed in `addons/gut/`) for rules and numbers, run headless before any step is called done. A playable test scene per system for feel. *Affects:* all.

**D-012 · 2026-09-23 · Rickey (for the team) · New ownership: Evan moves to Assets; Rickey takes Cart**
Player + Cart: Rickey · Assets: Evan · Rivals: John · Store / Round Manager + integration: Anthony. *Supersedes:* D-006. *Why:* Evan moves to the art and audio pipeline. Rickey takes Cart because Player and Cart form the drivable cart, and the team GDD's own grading called Player the thinnest system. *Risk:* the submitted team GDD says "one system per teammate" with Evan on Cart. If grading checks ownership, tell the instructor about the change. *Affects:* `TEAM.md`, `AGENTS.md`, `GAME_SPEC.md` §4 and §12, `CONTRACTS.md`, `PROGRESS.md`, `TODO.md`.

**D-013 · 2026-09-23 · Rickey · Assets seam: fixed paths, visual scenes, named parts**
Every gameplay object instances a visual scene from `assets/` at a fixed path from day one (as a placeholder). Evan upgrades files in place. Visual scenes have no scripts, collision, or lights. Code may touch only the named parts listed in `ASSETS.md`. UI layouts expose `%Name` nodes. Audio is triggered by contract signals (the `ASSETS.md` §4 table). *Why:* Evan and the system owners never edit the same file. *Affects:* all; defined in `ASSETS.md` and `CONTRACTS.md` §7.2.

**D-014 · 2026-09-23 · Rickey · Integration checkpoints and review pairs**
Checkpoint 1 Thu 09-24 6 pm (drivable cart + solo round), Checkpoint 2 Fri 09-25 9 am (bots in, then the demo), then evening checkpoints Sat 09-26 to Thu 10-01. Review pairs follow the seams (`TEAM.md`). *Affects:* all.

**D-015 · 2026-09-23 · Rickey (Cart owner) · Cart is a `CharacterBody3D`**
Kinematic: code sets the velocity. *Why:* exact speed at contact for the steal rule, no physics jitter (the GDD's #2 risk), easy to test deterministically, matches the prototype. Crashes and knockback are coded by hand. *Resolves:* Q-006. *Affects:* Cart, `cart.tscn`.

**D-016 · 2026-09-23 · Rickey · Test framework version: GUT 9.7.1, committed in `addons/gut/`**
*Affects:* all.

**D-017 · 2026-09-24 · Rickey (Cart owner) · Cart handling rules that other systems feel**
(1) Reverse tops out at 4 m/s, below the 5 m/s steal minimum, so backing into a cart never steals. (2) Cart itself treats commands as neutral unless `RoundManager.is_gameplay_active()` (RUSH / FINAL_CALL), so carts coast to a stop during countdown and after close; test scenes set `RoundManager.phase = RUSH` to drive. (3) Commands last one physics frame: a frame with no `apply_command()` call is neutral. (4) Half gas = half top speed. Brake beats gas. The cart pivots in place when stopped. *Why:* `docs/features/cart/01-movement/00-brainstorm.md`. *Affects:* Rivals (bot driving), Store (countdown, close), Player (controller).

**D-018 · 2026-09-24 · Rickey (Cart owner) · Inventory rules other systems rely on**
(1) `try_add_item` refuses when the round isn't active, the cart has 24, the item is null, or that same item is already in the cart; a **stunned cart still collects** (GAME_SPEC §5.5). (2) On success: `item_collected`, then `cart_full` only if this add reached 24 (so it fires once per fill, again after emptying and refilling). (3) `take_all_items` returns items **oldest first** and works in any phase (Store's deferred checkout can land just after close); `cart/04-ram-steal` spills use the same order. (4) Cap is `CartTuning.item_cap` (24). *Why:* `docs/features/cart/02-inventory/00-brainstorm.md`. *Affects:* Store (pickups, checkout), Rivals (`cart_full` = go bank), Player (HUD).

**D-019 · 2026-09-25 · Rickey (Cart owner) · How ram-steal resolves**
(1) **The loser emits `cart_robbed(winner, loser, items, spilled)`**, once per steal, after both inventories update (CONTRACTS §2 left the choice to the Cart owner). (2) **Whichever cart detects the contact resolves it** (a parked cart can't detect being hit). A pair lock of `pair_cooldown` (0.2 s, counted in physics frames) makes each contact resolve once, even when both carts detect it. (3) The fair set: an immune cart can't be robbed but can rob; a stunned cart can't win; an empty loser means a bounce (no stun, no signal); thresholds are inclusive (≥ 5 m/s, ≥ 1.5 m/s faster); a tie is a bounce. (4) Winner keeps 75% speed; loser knocked back 4 m/s (below the steal minimum, so no chain steals), stunned 0.7 s with low grip, immune 1.6 s. Non-steal bump: both pushed apart 2 m/s, keeping 70% speed. (5) A full winner still steals: everything spills. (6) The tip-over and flying items are visual only; data moves instantly. *Why:* `docs/features/cart/04-ram-steal/00-brainstorm.md`. *Affects:* Store (spill spawning), Rivals (retarget, avoid immune carts), Player (popups).

**D-020 · 2026-09-25 · Rickey (for the Demo) · Demo branch `integration/01-demo`**
Combined branch for the Friday demo, created from `Anthony-Stores` with every open PR merged in: #3 (Rickey's P-001 signature), #4–#7 (cart movement, PlayerController + chase camera, inventory, shopper placeholder), #8 (Evan's shopper model + preview, which sat on `cart/03-shopper`) and #9 (ram-steal). **Evan's `MCPGameBridge` autoload is left out** of this branch so the exported game doesn't start an MCP server; the godot-mcp editor plugin and files are kept. Needs Anthony (owner of `project.godot`) and the team to settle Q-005. John's and Anthony's code merges in when pushed. *Affects:* all.

**D-021 · 2026-09-25 · Rickey (Cart) · Evan's shopper model on every cart**
`cart.tscn` instances Evan's `Blender/man_cart_godot.fbx` at `Visual/ShopperModel`, **offset (0, 0, 1.0), no lift**, so his basket sits over the 0.8 × 1.0 × 1.2 m collision box and the man stands behind it. Measured with the skeleton posed, the animated model already starts at y = 0, so the 0.415 m lift in his preview floats it. `CartShopperAnimator` (Cart system) drives his clips from cart motion instead of keys, so bots animate too. When robbed, the cart tips over and plays `hit` then `stunned`. The shirt and handle are tinted with `ShopperProfile.color`, and the item cubes follow his `CART` bone. The box placeholders stay in the scene, hidden, because his preview references them. No contract change. *Affects:* Evan (named clips, materials and bone now used by code), Anthony (`main.tscn` gets it for free by instancing `cart.tscn`).

**D-020 correction · 2026-09-25 · Rickey (Claude Code)**
The `MCPGameBridge` autoload is **still in** `integration/01-demo`: the commit meant to remove it (a5e3f78) only changed this file. Removing it can't stick while the godot-mcp plugin is enabled, because `addons/godot_mcp/plugin.gd` adds the autoload back every time the editor opens. It is also harmless in a build: the bridge returns early unless the game runs under the editor's debugger (`EngineDebugger.is_active()`), so an exported game starts nothing. The real choice is Q-005: keep the plugin (and its autoload) or remove both. Settle it before this branch merges to `main`.

**D-022 · 2026-09-25 · Rickey (for the Demo) · Keep the godot-mcp plugin (resolves Q-005)**
Keep Evan's `addons/godot_mcp/` with the plugin enabled **and** its `MCPGameBridge` autoload in `project.godot`. The plugin re-adds the autoload on every editor start, so the two can't be separated, and the bridge only runs under the editor's debugger, so exported builds are unaffected. This replaces D-020's "drop the autoload". Anthony, as `project.godot` owner, confirms when reviewing #12. *Affects:* all (don't strip the autoload or plugin lines from `project.godot`).

**D-023 · 2026-09-25 · Rickey (Player, for the Demo) · John's bots in the fallback demo**
`integration/02-demo` = `integration/01-demo` + John's `rivals/02-cart-integration` (#14) + `player/03-demo-bots`. In the fallback demo, John's `BotController` replaces the test rammers, with GAME_SPEC §12 personalities and a navmesh baked at load (synchronous, so it's web-safe). Anthony's `RoundManager` is still a stub (no pickups, checkout at the origin), so while `demo_round.tscn` runs it swaps `DemoRoundManager` (`systems/player/demo/`, a subclass of the stub) onto the autoload and restores the stub on exit. Anthony's file isn't touched, and nothing outside the demo sees the swap. `TestPickup` now extends `Pickup`. No contract change. *Affects:* John (his bots run in the demo), Anthony (the list of what his RoundManager must provide is in PROGRESS → Player).

---

## Proposed (need sign-off)

**P-001 · 2026-09-23 · Rickey · `CONTRACTS.md` v0.1**
Adopt `CONTRACTS.md` v0.1, including these additions to the GDD's contract:
- `ItemData.item_id` (unique per match) for identity-based conservation tests
- `GameTypes` enums (`Category`, `Phase`)
- `CartState`: `cart_id`, `display_name`, `color`, `position`, `boost_meter`, `is_immune`
- `RoundResults` and `ShopperProfile` resources
- Cart methods `apply_command`, `try_add_item`, `take_all_items`, `reset_for_round`, `get_state`, `apply_slip`
- RoundManager: `phase_changed` and `deal_spawned` signals, `round_number` naming, the listed getters, `start_match()`
- Pickup flow (Store's `Pickup` calls `cart.try_add_item`), deferred checkout, physics layer names, `main.tscn` wiring

Sign-off (write your name and date, or a linked change request):
- Player + Cart (Rickey): ✅ signed 2026-09-23
- Rivals (John): 
- Store / integration (Anthony): 
- Assets (Evan), for `CONTRACTS.md` §7.2 and `ASSETS.md` named parts: 

When all four sign, move this entry to Decided as D-0xx and bump `CONTRACTS.md` to v1.0.

**P-002 · 2026-09-23 · Rickey · Round tie handling**
If two or more shoppers tie for the highest round score, each gets a stamp. If nobody banks anything, no stamp is awarded. Needs: Anthony.

---

## Open questions

**Q-001 · Store name.** Candidates: Bumper Crop Market (the prototype name, used until this is decided), Shop-N-Dash, Big Basket, Aisle Nine Foods, FreshWay, CartMart.

**Q-002 · Where is the Three.js prototype?** Add the link or path to `TECH_STACK.md` → Reference.

**Q-003 · Bot cart colors.** Suggested: Carl teal, Bev pink, Rita silver (the player is yellow). Needs: Rickey, Evan.

**Q-004 · What is "character select"?** There's one human, so this screen probably confirms or customizes your Shopper ID card (name, photo). Needs: Rickey, in the Shopper ID screens feature.

**Q-005 · Commit the godot-mcp addon?** Resolved by D-022: keep it.

**Q-006 · Cart physics body.** Resolved by D-015: `CharacterBody3D`.
