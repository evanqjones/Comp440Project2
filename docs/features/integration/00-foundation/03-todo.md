# 00-foundation: TODO

Mirrors [02-plan.md](02-plan.md). Tick each box in the same commit as the work.

## Setup
- [x] Synced `main` and created branch `integration/00-foundation` (stacked on `docs/00-project-specs`)
- [x] `00-brainstorm.md` written
- [x] `01-spec.md` written and approved by the owner
- [x] Contract changes approved (none)
- [x] `02-plan.md` written
- [ ] `PROGRESS.md`: branch and current feature set

## Iteration 1: Tooling
- [x] Step 1.1: GUT 9.7.1, plugin enabled, `.gutconfig.json`, smoke test passing

## Iteration 2: Shared data
- [x] Step 2.1: `GameTypes`, `DriveCommand`, `ItemData` + tests
- [ ] Step 2.2: `CartState`, `RoundResults`, `ShopperProfile`, 4 profiles + tests

## Iteration 3: Stubs
- [ ] Step 3.1: `Cart` stub script + `cart.tscn` + conformance tests
- [ ] Step 3.2: `Pickup` + `RoundManager` autoload stubs + conformance tests

## Iteration 4: Project settings
- [ ] Step 4.1: input map + physics layer names + tests

## Iteration 5: Wrap-up
- [ ] Step 5.1: folder skeleton, docs updates, full suite + main scene smoke run

## Verify
- [ ] Full GUT suite passes headless (paste the summary line into PROGRESS)
- [ ] Every "Done when" item in `01-spec.md` is met
- [ ] Hand checks: editor opens clean, F5 runs clean (Rickey)
- [ ] (If integrated) tried in `main.tscn`: n/a

## PR
- [ ] Merged `origin/main` into the branch and re-ran the suite
- [ ] PR opened with summary, interfaces touched, how to test, and test results
- [ ] Reviewed by Anthony (`project.godot` changes)
- [ ] Merged by Anthony

## Post-merge
- [ ] `PROGRESS.md`: feature moved to Done, handoff notes written
- [ ] `TODO.md`: M0 items ticked
- [ ] `DECISIONS.md`: D-015 logged
