# 03-spawns-checkout: Brainstorm

| | |
|---|---|
| System / Owner | Store / Anthony |
| Branch | `Anthony-Stores` (explicitly requested by Anthony) |
| Agent / Date | Codex / 2026-09-24 |
| Milestone | Demo: Thursday 09-24 scope |

## Goal

Spawn groceries, collect them, bank checkout trips and preserve spilled item identities.

## Grounding

GAME_SPEC.md §6 and §12 fix values, weights, cap and interval; CONTRACTS.md §3.1–3.2 and §8 fix pickup ownership, deferred checkout and conservation.

## Q&A

Anthony requested only his Thursday TODO work and branch `Anthony-Stores`. No feature-design answers or approval have been received. Defaults below are proposals for review, not recorded human decisions.

## Decisions

Use the existing gameplay numbers, ownership boundaries and frozen signatures. Build one tested plan step per commit and stop/report as required by AGENTS.md.

## Contract changes needed

None proposed.

## Open questions

Approve the draft specification and its explicitly proposed defaults before building. Dependencies are recorded in Anthony's PROGRESS sections.

## Out of scope

Cart inventory/ram/immune logic, assets, bot behavior, Deal of the Day spawning, hazards and best-of-three scoring.
