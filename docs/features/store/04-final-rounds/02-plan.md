# 04-final-rounds: Plan

| | |
|---|---|
| System / Owner | Store / Anthony |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |

## 1. Blueprint

- Add match-bank and stamp snapshots, then make results advance rounds one and two or end the match after round three.
- Add a Deal pickup lifecycle separate from regular spawning and test its identity through spills.
- Add one Store hazard lifecycle and the three scheduled hazard behaviors.
- Wire the Final Store diagnostic scene and test the real Cart ↔ Store conservation seam.
- Add final Asset references only when their owned paths exist, then verify the full game and web export.

## 2. Iterations and steps

### Iteration 1: Match results

- **Step 1.1:** Implement match bank/stamp accounting and `RoundResults` snapshots → test winner and tie rules.
- **Step 1.2:** Advance results into next-round reset/countdown or `MATCH_OVER` → test all three transitions and stale-work guards.

### Iteration 2: Deal of the Day

- **Step 2.1:** Add Deal creation, random 14–22-second timer, single-live-deal guard, and signal → test cap separation and timing bounds.
- **Step 2.2:** Preserve Deal identity/value/visual category through Cart spill and collection → test the Final conservation seam with real Cart.

### Iteration 3: Hazards

- **Step 3.1:** Add Store hazard lifecycle, 35/25/15-second cadence, random selection, and close/reset cleanup → test scheduling and durations.
- **Step 3.2:** Add wet floor, pallet jack, and falling display gameplay scenes → test slip call, crossing/blocking, and warning/block lifecycle.

### Iteration 4: Integration and verification

- **Step 4.1:** Wire the diagnostic scene and available final Asset paths → verify visual states by hand.
- **Step 4.2:** Pull main, run full GUT and Run Project, perform three-round and real-cart checks, then test web export through a local server.

## 3. Prompts

### Prompt 1 (Step 1.1): Match accounting

```text
Context: Store feature 04-final-rounds. Read AGENTS.md, 01-spec.md §§3–4, and CONTRACTS.md §§1 and 3.
Task: Write GUT tests first for positive winner, zero-bank, tied-round, stamp, and cumulative-bank snapshots. Implement only RoundManager match accounting and RoundResults population.
Files: tests/store/test_final_rounds.gd; systems/store/round_manager.gd.
Test first: run the new test and confirm failure before implementation.
Finish: run full headless GUT, tick Step 1.1, commit "store: score final match rounds", then stop.
```

### Prompt 2 (Step 1.2): Round progression

```text
Context: Store feature 04-final-rounds. Read 01-spec.md §§2–3.
Task: Test and implement the results-duration transition: first two rounds reset carts then count down; round three enters MATCH_OVER with final winner IDs. Guard stale deferred work across resets.
Files: tests/store/test_final_rounds.gd; systems/store/round_manager.gd.
Test first, then implement. Run full headless GUT, tick Step 1.2, commit "store: advance final match rounds", then stop.
```

### Prompt 3 (Step 2.1): Deal lifecycle

```text
Context: Store feature 04-final-rounds. Read 01-spec.md §3 and CONTRACTS.md §3.
Task: Test and implement one Deal pickup at a random Store marker after 14–22 active seconds, separate from the regular cap, emitting deal_spawned exactly once.
Files: tests/store/test_final_rounds.gd; systems/store/round_manager.gd; systems/store/pickup.gd; systems/store/pickup.tscn; systems/store/store.gd.
Test first, then implement. Run full headless GUT, tick Step 2.1, commit "store: spawn deal of the day", then stop.
```

### Prompt 4 (Step 2.2): Deal conservation

```text
Context: Store feature 04-final-rounds. Read 01-spec.md §§3 and 6.
Task: Write a real Cart and Store acceptance test with a Deal in the spilled list. Implement only missing Store handling so the Deal keeps ID, category, $100 value, and single-live-deal tracking until collected.
Files: tests/store/test_final_rounds.gd; systems/store/round_manager.gd; systems/store/pickup.gd.
Test first, then implement. Run full headless GUT, tick Step 2.2, commit "store: preserve spilled deal", then stop.
```

### Prompt 5 (Step 3.1): Hazard scheduling

```text
Context: Store feature 04-final-rounds. Read 01-spec.md §§2–3.
Task: Test and implement one-active-hazard lifecycle, random type selection, 35/25/15-second cadence, restart-after-clear behavior, and reset/close cleanup.
Files: tests/store/test_final_rounds.gd; systems/store/round_manager.gd; systems/store/hazards/hazard.gd.
Test first, then implement. Run full headless GUT, tick Step 3.1, commit "store: schedule final hazards", then stop.
```

### Prompt 6 (Step 3.2): Hazard behaviors

```text
Context: Store feature 04-final-rounds. Read 01-spec.md §§2, 3, and 6 plus CONTRACTS.md §2.
Task: Test first, then create Store-owned wet-floor, pallet-jack, and falling-display scenes. Call Cart.apply_slip(1.0) only through its public contract; use 8 s, 6 s, and 1 s + 5 s lifecycles.
Files: tests/store/test_final_rounds.gd; systems/store/hazards/*; systems/store/store.gd; systems/store/store.tscn.
Run full headless GUT, tick Step 3.2, commit "store: add final hazards", then stop.
```

### Prompt 7 (Step 4.1): Diagnostic scene and art

```text
Context: Store feature 04-final-rounds. Read 01-spec.md §§5 and 7 plus ASSETS.md §5.
Task: Wire systems/store/test/final_rounds_test.tscn. Instance only available Asset-owned final visual paths; retain Store-owned placeholders for missing paths and record the dependency in PROGRESS.
Files: systems/store/test/final_rounds_test.tscn; systems/store/test/final_rounds_test.gd; systems/store/store.tscn; systems/store/store.gd; docs/PROGRESS.md.
Run full headless GUT, tick Step 4.1, commit "store: add final rounds test scene", then stop.
```

### Prompt 8 (Step 4.2): Full-game and web verification

```text
Context: Store feature 04-final-rounds. Read 01-spec.md §7 and WORKFLOW.md Step 7.
Task: Pull origin/main, resolve and test integration, then run full GUT and Run Project. Perform the three-round, Deal-spill, and hazard hand checks. Build the web export and test it through a local server. Update PROGRESS with real results; do not push or open a PR.
```

## 4. Improvements and bugs

1. Verify the Rivals Deal signal handler uses the frozen `Pickup` signal payload; historical notes identify a possible ItemData/Pickup mismatch owned by John.
