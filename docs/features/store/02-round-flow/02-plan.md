# 02-round-flow: Plan

| | |
|---|---|
| System / Owner | Store / Anthony |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |
| Status | Draft; do not build before spec approval |

## 1. Blueprint

- Phase machine and signals.
- Reset and door lifecycle.

## 2. Iterations and steps

- **Step 1.1: Phase machine and signals.** Write boundary and signal-count tests first. Implement countdown, rush, final call, one-frame-deferred closed finalization, results and the proposed Demo idle endpoint. Cover large deltas and duplicate start calls.
- **Step 1.2: Reset and door lifecycle.** Test reset calls through a tests/store Cart double and door collision states. Connect doors to phases, guard stale deferred work across a restart, and wire the Store diagnostic scene. Do not implement Player feedback.

## 3. Prompts

Prerequisites: approved spec; synced branch; engine from TECH_STACK.md available; required assets present before scene references are introduced. Use only Anthony's files. Read AGENTS.md, this spec and CONTRACTS.md first. Each prompt updates its own TODO and Anthony's PROGRESS section in the same step commit.

### Prompt 1.1: Phase machine and signals

```text
Files: tests/store/test_round_flow.gd; systems/store/round_manager.gd.
Task/test first: Write boundary and signal-count tests first. Implement countdown, rush, final call, one-frame-deferred closed finalization, results and the proposed Demo idle endpoint. Cover large deltas and duplicate start calls.
Write the named behavior tests first and observe their failure before implementing.
Implement only this step, wire it to the prior step, and run:
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
Check SCRIPT ERROR output and executed script count, not just the summary.
On success tick Step 1.1, update Anthony's handoff, commit "store: implement Demo round phases", then stop and report.
On missing prerequisites or test failure, report the real result; do not tick the step.
```

### Prompt 1.2: Reset and door lifecycle

```text
Files: tests/store/test_round_flow.gd; systems/store/round_manager.gd; systems/store/store.gd; systems/store/store.tscn; systems/store/test/round_flow_test.tscn.
Task/test first: Test reset calls through a tests/store Cart double and door collision states. Connect doors to phases, guard stale deferred work across a restart, and wire the Store diagnostic scene. Do not implement Player feedback.
Write the named behavior tests first and observe their failure before implementing.
Implement only this step, wire it to the prior step, and run:
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
Check SCRIPT ERROR output and executed script count, not just the summary.
On success tick Step 1.2, update Anthony's handoff, commit "store: connect round resets and doors", then stop and report.
On missing prerequisites or test failure, report the real result; do not tick the step.
```

## 4. Improvements and bugs

None implemented. Missing assets, Cart/Player behavior and local engine availability are prerequisites, not permission to build another owner's system.
