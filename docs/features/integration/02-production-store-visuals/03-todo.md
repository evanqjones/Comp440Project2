# 02-production-store-visuals: TODO

Mirrors [02-plan.md](02-plan.md). Tick each box in the same commit as the work.

## Setup
- [x] Synced `main` and created branch `integration/02-production-store-visuals`.
- [x] `00-brainstorm.md` written.
- [x] `01-spec.md` approved by Evan's direct integration request.
- [x] Contract changes approved (none).
- [x] `02-plan.md` written.
- [x] Evan's `PROGRESS.md` section records this branch and feature.

## Iteration 1: Production Store art
- [x] Step 1.1: Compose and wire authored art; preserve gameplay geometry.
- [x] Step 1.2: Align floor, perimeter, parking, and aisle fixture collision with the authored model bounds; test shelf contact and cart clearance through the aisle.
- [x] Step 1.3: Move grand-opening displays outside, leave registers inside, and add invisible world-edge and fridge-bank barriers.
- [x] Step 1.4: Move sale displays and cutout standees to the rear interior, close the store-side approaches, and extend parking collision ground through the south barrier; verify with moving cart-sized physics.

## Iteration 2: Verify and record
- [ ] Step 2.1: Final Run Project visual/full-round playtest, editor logs, and final notes.

## Verify
- [x] Full GUT suite passes headless.
- [ ] Open `main.tscn` after the collision realignment; visually confirm the rack colliders line up and personally drive every aisle.
- [x] Grand-opening preview still loads with no new errors.

## PR
- [ ] Pulled `origin/main` before push and reran GUT and Run Project.
- [ ] PR reviewed and merged.

## Post-merge
- [ ] `PROGRESS.md` updated after merged verification.
