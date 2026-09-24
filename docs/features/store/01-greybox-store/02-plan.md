# 01-greybox-store: Plan

| | |
|---|---|
| System / Owner | Store / Anthony |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |
| Status | Draft; do not build before spec approval |

## 1. Blueprint

- Layout and checkout position.
- Baked navigation and inspection scene.
- Thursday solo-round integration.

## 2. Iterations and steps

- **Step 1.1: Layout and checkout position.** Assert six category regions, four distinct start transforms, collision layers and checkout position. Build the layout using existing approved asset paths. If assets are absent, report the prerequisite before committing a broken scene.
- **Step 1.2: Baked navigation and inspection scene.** Test paths from each start to all aisles and checkout, including obstacle exclusion. Bake navigation with cart clearance, then wire the layout into the Store inspection scene.
- **Step 2.1: Thursday solo-round integration.** Only after explicit main.tscn approval, all three Store features and Rickey's required scenes are available: test cart registration and startup ordering, instance existing owner scenes, assign profiles and references, then call start_match after Store and carts are ready. Do not implement missing owner code or merge PRs.

## 3. Prompts

Prerequisites: approved spec; synced branch; engine from TECH_STACK.md available; required assets present before scene references are introduced. Use only Anthony's files. Read AGENTS.md, this spec and CONTRACTS.md first. Each prompt updates its own TODO and Anthony's PROGRESS section in the same step commit.

### Prompt 1.1: Layout and checkout position

```text
Files: tests/store/test_store_layout.gd; systems/store/store.tscn; systems/store/store.gd; systems/store/round_manager.gd.
Task/test first: Assert six category regions, four distinct start transforms, collision layers and checkout position. Build the layout using existing approved asset paths. If assets are absent, report the prerequisite before committing a broken scene.
Write the named behavior tests first and observe their failure before implementing.
Implement only this step, wire it to the prior step, and run:
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
Check SCRIPT ERROR output and executed script count, not just the summary.
On success tick Step 1.1, update Anthony's handoff, commit "store: build greybox store layout", then stop and report.
On missing prerequisites or test failure, report the real result; do not tick the step.
```

### Prompt 1.2: Baked navigation and inspection scene

```text
Files: tests/store/test_store_layout.gd; systems/store/store.tscn; systems/store/test/store_test.tscn.
Task/test first: Test paths from each start to all aisles and checkout, including obstacle exclusion. Bake navigation with cart clearance, then wire the layout into the Store inspection scene.
Write the named behavior tests first and observe their failure before implementing.
Implement only this step, wire it to the prior step, and run:
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
Check SCRIPT ERROR output and executed script count, not just the summary.
On success tick Step 1.2, update Anthony's handoff, commit "store: add store navigation and test scene", then stop and report.
On missing prerequisites or test failure, report the real result; do not tick the step.
```

### Prompt 2.1: Thursday solo-round integration

```text
Files: tests/store/test_main_integration.gd; systems/core/main.tscn; systems/core/main.gd.
Task/test first: Only after explicit main.tscn approval, all three Store features and Rickey's required scenes are available: test cart registration and startup ordering, instance existing owner scenes, assign profiles and references, then call start_match after Store and carts are ready. Do not implement missing owner code or merge PRs.
Write the named behavior tests first and observe their failure before implementing.
Implement only this step, wire it to the prior step, and run:
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
Check SCRIPT ERROR output and executed script count, not just the summary.
On success tick Step 2.1, update Anthony's handoff, commit "integration: wire Thursday solo round", then stop and report.
On missing prerequisites or test failure, report the real result; do not tick the step.
```

## 4. Improvements and bugs

None implemented. Missing assets, Cart/Player behavior and local engine availability are prerequisites, not permission to build another owner's system.
