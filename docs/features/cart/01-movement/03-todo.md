# 01-movement: TODO

Mirrors [02-plan.md](02-plan.md). Tick each box in the same commit as the work.

## Setup
- [x] Synced `main` and created branch `cart/01-movement`
- [x] `00-brainstorm.md` written
- [x] `01-spec.md` written and approved by the owner (Rickey, 2026-09-24)
- [x] Contract changes approved (none)
- [x] `02-plan.md` written
- [x] `PROGRESS.md`: branch and current feature set

## Tasks
- [x] Task 1: `CartTuning` + `.tres` + `top_speed` / `turn_rate` (math tests)
- [x] Task 2: `next_forward_speed` (math tests)
- [x] Task 3: `next_yaw` / `fade_sideways` (math tests)
- [x] Task 4: `cart.gd` physics loop + `cart.tscn` tuning and nose (physics tests)
- [x] Task 5: test scene + test-only driver and camera (loads headless)
- [x] Task 6: GAME_SPEC §12 rows, D-017, PROGRESS handoffs

## Verify
- [x] Full GUT suite passes headless (paste the summary line into PROGRESS)
- [ ] Every "Done when" item in `01-spec.md` is met
- [x] Test scene hand checks confirmed by Rickey (2026-09-24)
- [ ] (If integrated) tried in `main.tscn`: n/a until Anthony's Checkpoint 1

## PR
- [ ] Merged `origin/main` into the branch and re-ran the suite
- [ ] PR opened with summary, interfaces touched, how to test, and test results
- [ ] Reviewed by Anthony
- [ ] Merged

## Post-merge
- [ ] `PROGRESS.md`: feature moved to Done, handoff notes written
- [ ] `TODO.md`: item ticked
- [ ] `DECISIONS.md`: D-017 logged
