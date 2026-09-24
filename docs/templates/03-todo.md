# <NN-slug>: TODO

Mirrors [02-plan.md](02-plan.md). Tick each box in the same commit as the work.

## Setup
- [ ] Synced `main` and created branch `<system>/<NN>-<slug>`
- [ ] `00-brainstorm.md` written
- [ ] `01-spec.md` written and approved by the owner
- [ ] Contract changes approved (or none)
- [ ] `02-plan.md` written
- [ ] `PROGRESS.md`: branch and current feature set

## Iteration 1: <name>
- [ ] Step 1.1: <what>
- [ ] Step 1.2: <what>

## Iteration 2: <name>
- [ ] Step 2.1: <what>

## Verify
- [ ] Full GUT suite passes headless (paste the summary line into PROGRESS)
- [ ] Every "Done when" item in `01-spec.md` is met
- [ ] Test scene hand checks confirmed by the owner
- [ ] (If integrated) tried in `main.tscn`

## PR
- [ ] Merged `origin/main` into the branch and re-ran the suite
- [ ] PR opened with summary, interfaces touched, how to test, and test results
- [ ] Reviewed by a teammate
- [ ] Merged (by the owner, or by Anthony if it touches `project.godot` / `main.tscn` / export presets)

## Post-merge
- [ ] `PROGRESS.md`: feature moved to Done, handoff notes written
- [ ] `TODO.md`: item ticked
- [ ] `DECISIONS.md`: any cross-system decisions logged
