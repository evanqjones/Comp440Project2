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

**Status:** 🟡 · **Branch:** `docs/00-project-specs` (Rickey drafting) · **Current feature:** M0 foundation · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** Project specs and workflow docs drafted.
- **In progress:** Docs review and merge.
- **Next:** `integration/00-foundation` (Rickey drafts, Anthony reviews the `project.godot` changes). Then assemble `main.tscn` at Checkpoint 1.
- **Needs from others:** **Everyone:** read `CONTRACTS.md` v0.1 and `ASSETS.md`, and sign P-001 in `DECISIONS.md` by Thu 09-24 morning.
- **Handoff notes:** —

---

## Player: Rickey

**Status:** ⚪ · **Branch:** — · **Current feature:** — · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** —
- **In progress:** —
- **Next:** `player/01-controller-camera` (after `cart/01-movement`), then `player/02-demo-hud`, which wires data into Evan's `hud_layout.tscn`.
- **Needs from others:** Foundation (input actions, `DriveCommand`). Evan: `hud_layout.tscn` with the Demo `%` names by Thu afternoon.
- **Handoff notes:** —

---

## Cart: Rickey

**Status:** ⚪ · **Branch:** — · **Current feature:** — · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** —
- **In progress:** —
- **Next:** `cart/01-movement` **first; merge by Thu noon** (everyone depends on it). Then `cart/02-inventory`, `cart/03-ram-steal`.
- **Needs from others:** Foundation (`DriveCommand`, `ItemData`, `CartState`, `Cart` stub). Evan: `cart_visual.tscn` placeholder.
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
