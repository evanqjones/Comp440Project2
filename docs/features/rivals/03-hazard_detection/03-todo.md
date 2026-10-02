# 03-hazard_detection: TODO

Mirrors [02-plan.md](02-plan.md). Tick each box in the same commit as the work.

## Setup
- [x] Synced `main` and created branch `rivals/03-hazard_detection`
- [x] `00-brainstorm.md` written
- [x] `01-spec.md` written and approved by the owner
- [x] Contract changes approved (none needed)
- [x] `02-plan.md` written
- [x] `PROGRESS.md`: branch and current feature set

## Iteration 1: Hazard Tracking & Geometric Path Safety Math
- [x] Step 1.1: Hazard Lifecycle Tracking & Test Overrides
- [x] Step 1.2: Horizontal Point-to-Segment Path Safety Check

## Iteration 2: Candidate Target Filtering & Active Slip Neutralization
- [x] Step 2.1: Filter Unsafe Candidate Targets in Decision Evaluation
- [x] Step 2.2: Active Slip Command Neutralization

## Iteration 3: Event-Driven Rerouting & Banking Standoff Logic
- [x] Step 3.1: Immediate Reroute on `hazard_spawned` & Despawn Re-evaluation
- [x] Step 3.2: Banking Checkout Standoff & Desperation Rush

## Iteration 4: Test Scene Wiring & Full Integration Check
- [x] Step 4.1: Wire Hazards into Rivals Test Scene

## Verify
- [x] Full GUT suite passes headless (paste the summary line into PROGRESS)
- [x] Every "Done when" item in `01-spec.md` is met
- [x] Test scene hand checks confirmed by the owner
- [x] Pulled `origin/main` into the branch; feature wired into the game and played with **Run Project** alongside everything else on `main`

## PR
- [ ] Pulled `origin/main` right before pushing; re-ran the suite and Run Project
- [ ] PR opened with summary, interfaces touched, how to test, and test results
- [ ] Reviewed by a teammate
- [ ] Merged (by the owner, or by Anthony if it touches `project.godot` / `main.tscn` / export presets)

## Post-merge
- [ ] Pulled `main` and checked the feature with Run Project on `main` (done = playable on `main`)
- [ ] `PROGRESS.md`: feature moved to Done, handoff notes written
- [ ] `TODO.md`: item ticked
- [ ] `DECISIONS.md`: any cross-system decisions logged
