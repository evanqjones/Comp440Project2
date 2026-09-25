# 01-foundation: TODO

Mirrors [02-plan.md](02-plan.md). Tick each box in the same commit as the work.

## Setup
- [x] Synced `main` and created branch `rivals/01-foundation`
- [x] `00-brainstorm.md` written
- [x] `01-spec.md` written and approved by the owner
- [x] Contract changes approved (or none)
- [x] `02-plan.md` written
- [x] `PROGRESS.md`: branch and current feature set

## Iteration 1: Personalities & Controller Setup
- [x] Step 1.1: Create `BotPersonality` Resource Script
- [x] Step 1.2: Setup basic `BotController` and Round Timer Wiring

## Iteration 2: Core FSM States (Collecting & Banking)
- [x] Step 2.1: Implement COLLECTING State Utility Scoring
- [x] Step 2.2: Implement BANKING State Transitions

## Iteration 3: Chasing & Difficulty Scaling
- [x] Step 3.1: Implement CHASING State Target Selection and Aggression Gates
- [x] Step 3.2: Implement Additive Aggression Scaling per Round

## Iteration 4: Stuck Recovery, Blacklisting, and Boosting
- [x] Step 4.1: Implement Stuck Detection and Recovery Steering
- [x] Step 4.2: Implement Navigation Target Blacklisting on Failure
- [x] Step 4.3: Implement Periodic Boost Evaluation and Straightness Gates

## Iteration 5: Event Responsiveness & Test Scene Integration
- [ ] Step 5.1: Implement Out-of-Band Decision Signals for Responsiveness
- [ ] Step 5.2: Wire into the Test Scene and Implement Test Scene Logic

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
