# Progress Tracker

**Every agent reads this file at the start of every session.** Each owner (and their agent) edits **only their own section**, so four branches can update it without merge conflicts. The **Integration** section and the "On `main`" block are Anthony's (integration owner). Anyone may fix a typo, but not someone else's status.

Status key: 🟢 on track · 🟡 at risk · 🔴 blocked · ⚪ not started · ✅ done

---

## On `main` right now

_Updated 2026-09-23 by Rickey (Claude Code)_

- Godot 4.7.2 project with the Web export preset and a placeholder `systems/core/main.tscn` (a "Godot project ready" label).
- Project docs and specs are on branch `docs/00-project-specs`, **not merged yet**.
- Nothing playable yet.

## Milestones

| Milestone | Date | Status | Notes |
|---|---|---|---|
| M0 Foundation | Wed 09-23 (tonight) | 🟡 | Docs written; foundation code (contract stubs, input map, GUT) next |
| **Demo**: one full round | **Fri 09-25** | ⚪ | See `TODO.md` → Demo |
| **Final** | **Fri 10-02** (freeze Thu 10-01 night) | ⚪ | See `TODO.md` → Final |

---

## Integration: Anthony

**Status:** 🟡 · **Branch:** `docs/00-project-specs` (Rickey drafting) · **Current feature:** M0 foundation · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** Project specs and workflow docs drafted.
- **In progress:** Docs review and merge.
- **Next:** `integration/00-foundation`: `systems/shared/` contract scripts, `Cart` and `RoundManager` stubs, input map, physics layer names, `RoundManager` autoload, GUT + `.gutconfig.json` + a smoke test.
- **Needs from others:** **All four owners:** read `CONTRACTS.md` v0.1 and sign P-001 in `DECISIONS.md` by Thu 09-24 morning.
- **Handoff notes:** —

---

## Player: Rickey

**Status:** ⚪ · **Branch:** — · **Current feature:** — · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** —
- **In progress:** —
- **Next:** `player/01-controller-camera` (Demo), then `player/02-demo-hud`.
- **Needs from others:** Foundation (input actions, `DriveCommand`, `Cart` stub).
- **Handoff notes:** —

---

## Cart: Evan

**Status:** ⚪ · **Branch:** — · **Current feature:** — · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** —
- **In progress:** —
- **Next:** `cart/01-movement` (Demo), then `cart/02-inventory`, `cart/03-ram-steal`.
- **Needs from others:** Foundation (`DriveCommand`, `ItemData`, `CartState`, `Cart` stub).
- **Handoff notes:** —

---

## Rivals: John

**Status:** ⚪ · **Branch:** — · **Current feature:** — · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** —
- **In progress:** —
- **Next:** `rivals/01-basic-bot` (Demo). It can start in a test scene with dummy pickups and a flat navmesh before the store exists.
- **Needs from others:** Foundation (`Cart` stub, `RoundManager` stub with `get_pickups()` and `get_checkout_position()`).
- **Handoff notes:** —

---

## Store / Round Manager: Anthony

**Status:** ⚪ · **Branch:** — · **Current feature:** — · **Updated:** 2026-09-23 (Rickey, Claude Code)

- **Done:** —
- **In progress:** —
- **Next:** `store/01-greybox-store` (Demo), then `store/02-round-flow`, `store/03-spawns-checkout`.
- **Needs from others:** Foundation (`ItemData`, `Cart` stub with `try_add_item` / `take_all_items`).
- **Handoff notes:** —
