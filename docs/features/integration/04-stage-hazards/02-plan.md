# 04-stage-hazards: Plan

| | |
|---|---|
| System / Owners | Store (Anthony) + Cart (Rickey); visuals (Evan) |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |
| Status | Approved by Evan (2026-09-30) |

## 1. Blueprint

Implement Cart slip first, then Store hazard lifecycle and random scheduling, then visuals and integration. Preserve the item-conservation contract throughout.

## 2. Steps

1. **Cart spin-out (complete):** tests first; implement `apply_slip()` steering lock, controlled yaw spin, timer extension, and reset cleanup.
2. **Store hazard actors:** build puddle and pallet warning/impact/block scenes; wire per-cart contact; route dropped items through Store's normal Pickup creation.
3. **Random schedule (complete):** use authored safe aisle points, random type/point selection, active-time cadence and round escalation; emit `hazard_spawned` on each spawn and clean up outside gameplay.
4. **Visuals and gameplay pass:** hazard visual-only scenes exist and are wired; Player chase camera holds its heading during the spin-out; inspect hazards in the running game, refine readability/placement if needed, run full GUT, then hand-check player and bot behavior.

## 3. Workflow prompts

- Work one step at a time. Write meaningful GUT tests before implementation, run the complete required suite, update the matching TODO and owner handoff, and stop after each step for review.
- Use only the files owned by each system; do not edit `main.tscn`, `project.godot`, `systems/shared/`, or `docs/CONTRACTS.md`.
- Commits use `integration: <what changed>` after the step is verified. No push without explicit authorization.

## 4. Improvements and bugs

None.
