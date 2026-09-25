# 02-round-flow: Brainstorm

| | |
|---|---|
| System / Owner | Store / Anthony |
| Branch | `Anthony-Stores` (explicitly requested by Anthony) |
| Agent / Date | Codex / 2026-09-24 |
| Milestone | Demo: Thursday 09-24 scope |

## Goal

Implement the Demo's single timed round and door lifecycle.

## Grounding

GAME_SPEC.md §3.1 and §12 fix the phase durations; CONTRACTS.md §3 and §8 fix signal names, active phases and the close boundary.

## Q&A

Anthony requested only his Thursday TODO work and branch `Anthony-Stores`. No feature-design answers or approval have been received. Defaults below are proposals for review, not recorded human decisions.

## Decisions

Use the existing gameplay numbers, ownership boundaries and frozen signatures. Build one tested plan step per commit and stop/report as required by AGENTS.md.

## Contract changes needed

None proposed.

## Open questions

Approve the draft specification and its explicitly proposed defaults before building. Dependencies are recorded in Anthony's PROGRESS sections.

## Out of scope

Best-of-three progression, stamps/tie decisions, match winners, HUD/audio implementation, hazards and Deal of the Day.
