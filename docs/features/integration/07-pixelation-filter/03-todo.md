# 07-pixelation-filter: TODO

Mirrors [02-plan.md](02-plan.md). Tick each box in the same commit as the work.

## Setup
- [x] Synced `main` and created branch `integration/07-pixelation-filter`
- [x] `00-brainstorm.md` written
- [x] `01-spec.md` drafted
- [x] `01-spec.md` approved by user
- [x] Contract changes: none
- [x] `02-plan.md` and `03-todo.md` written
- [ ] `PROGRESS.md`: branch and current feature set after spec approval

## Iteration 1: Screen filter and main-scene integration
- [x] Step 1.1: overlay coverage tests (`tests/integration/test_pixelation_overlay.gd`)
- [x] Step 1.2: shader and overlay implementation
- [x] Step 1.3: main scene wiring below crisp UI layers

## Iteration 2: Visual and Web verification
- [x] Step 2.1: full GUT, Run Project, Web export and visual readability checks
- [x] Step 2.2: target-device performance comparison explicitly assigned to user; local Web browser surface unavailable

## Verify
- [x] Full GUT suite passes headless: 32 scripts, 239 tests, 2,414 assertions
- [x] Compare the 1-pixel baseline with the 3-pixel default
- [ ] Run Web build in browser on the target device and compare performance

## PR
- [ ] Pull `origin/main`; rerun suite and Run Project
- [ ] Push and open PR only after user authorization
- [ ] Reviewed and merged by the correct owner

## Post-merge
- [ ] Pull `main` and verify the effect in the full game
- [ ] Update `PROGRESS.md` and `TODO.md`
