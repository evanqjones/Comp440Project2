# 04-stage-hazards: TODO

## Setup

- [x] Sync `main` and create `integration/04-stage-hazards`.
- [x] Draft brainstorm and spec.
- [x] Human approves spec and proposed timing/frequency (2026-09-30).
- [x] Confirm integration scope across Cart (Rickey) and Store (Anthony) (2026-09-30).
- [x] No contract changes proposed.

## Build

- [x] Step 1: Cart spin-out and steering lock; full GUT **30 scripts, 226/226 tests, 1,807 assertions**.
- [x] Step 2: Puddle and falling pallet actors; dropped-item preservation; visual placeholder scenes.
- [x] Step 3: Random schedule, safe spawn selection, round escalation, cleanup, signal.
- [x] Spin-out camera comfort: hold chase-camera heading during the rapid spin, then smoothly reacquire the cart; Player GUT **69/69 tests**.
- [ ] Step 4: Hazard visuals and gameplay hand-check.

## Verify

- [x] Full GUT suite passes for Step 1: **30 scripts, 226/226 tests, 1,807 assertions**, no script errors or skipped scripts.
- [ ] Player and bot hazard behavior hand-checked.
- [x] Update Store and Cart progress handoffs with actual verification.
- [x] Full GUT after Store actors, scheduler, and camera comfort: **31 scripts, 233/233 tests, 1,854 assertions**, no script errors or skipped scripts.

## PR

- [ ] Sync `origin/main` and rerun required checks.
- [ ] Push/PR only after explicit authorization.
