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
Player: Rickey · Cart: Evan · Rivals: John · Store / Round Manager: Anthony. Anthony is also the **integration owner** (`main.tscn`, `project.godot`, `export_presets.cfg`) because the GDD makes the Store owner the only editor of `Main.tscn`. *Supersedes:* the proposed split in the old `docs/TEAM.md` (Integration / Player / World / UI+Audio). *Affects:* `TEAM.md`, `README.md`.

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
- Player (Rickey): 
- Cart (Evan): 
- Rivals (John): 
- Store (Anthony): 

When all four sign, move this entry to Decided as D-0xx and bump `CONTRACTS.md` to v1.0.

**P-002 · 2026-09-23 · Rickey · Round tie handling**
If two or more shoppers tie for the highest round score, each gets a stamp. If nobody banks anything, no stamp is awarded. Needs: Anthony.

---

## Open questions

**Q-001 · Store name.** Candidates: Bumper Crop Market (the prototype name, used until this is decided), Shop-N-Dash, Big Basket, Aisle Nine Foods, FreshWay, CartMart.

**Q-002 · Where is the Three.js prototype?** Add the link or path to `TECH_STACK.md` → Reference.

**Q-003 · Bot cart colors.** Suggested: Carl teal, Bev pink, Rita silver (the player is yellow). Needs: Rickey, Evan.

**Q-004 · What is "character select"?** There's one human, so this screen probably confirms or customizes your Shopper ID card (name, photo). Needs: Rickey, in the Shopper ID screens feature.

**Q-005 · Commit the godot-mcp addon?** It helps Claude Code users test in a live editor, but enabling the plugin edits `project.godot`. Until decided, keep it local. Needs: Anthony + anyone using it.

**Q-006 · Cart physics body.** `RigidBody3D` (arcade physics) or `CharacterBody3D` (kinematic, our own speed rule). Needs: Evan, in `cart/01-movement`.
