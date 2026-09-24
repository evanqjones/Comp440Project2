# 01-movement: Plan

| | |
|---|---|
| System / Owner | Cart / Rickey |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |

## 1. Blueprint

<The whole build in 4–8 bullets, in order. What exists at the end of each part.>

## 2. Iterations and steps

Each iteration leaves the project in a working, tested state. Each step is small enough to implement safely with a test, and big enough to move the feature forward.

### Iteration 1: <name>

- **Step 1.1:** <what> → test: <what the GUT test checks>
- **Step 1.2:** …

### Iteration 2: <name>

- **Step 2.1:** …

## 3. Prompts

Run these one at a time (see `WORKFLOW.md` Step 6). Every prompt follows the same shape: files, test first, implement, run the suite, tick the TODO, commit.

### Prompt 1 (Step 1.1): <name>

```text
Context: <System> feature 01-movement. Read AGENTS.md, 01-spec.md §<n>, and CONTRACTS.md §<n>.
Task: <exactly what to build in this step>.
Files: <create/edit only these paths>.
Test first: in tests/<system>/test_<thing>.gd, write test_<name> asserting <expected>. Run it and confirm it fails.
Implement: <guidance, constraints, numbers from the spec>.
Wire: <how it connects to the previous step; no orphaned code>.
Finish: run the full GUT suite headless and confirm all pass, tick Step 1.1 in 03-todo.md,
commit "<system>: <what>", then stop and report.
```

### Prompt 2 (Step 1.2): <name>

```text
…
```

### Final prompt: wire into the test scene

```text
Context: all steps above are done. Wire the feature into systems/<system>/test/<name>_test.tscn so it
can be tried by hand: <what the scene should let the tester do>. Run the full GUT suite, tick the step,
commit "<system>: test scene for 01-movement", and list the hand checks from 01-spec.md §7.
```

## 4. Improvements and bugs

Add items found during building or playtesting. Each gets a prompt when it's scheduled.

1. <[file or area]: issue or improvement>
