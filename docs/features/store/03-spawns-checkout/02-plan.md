# 03-spawns-checkout: Plan

| | |
|---|---|
| System / Owner | Store / Anthony |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |
| Status | Draft; do not build before spec approval |

## 1. Blueprint

- Pickup collection and floor registry.
- Weighted regular spawning.
- Deferred checkout and close boundary.
- Spills and conservation diagnostic.

## 2. Iterations and steps

- **Step 1.1: Pickup collection and floor registry.** Test acceptance, full-cart rejection, two-cart contention and immediate removal from get_pickups. Implement Pickup with Evan's existing item visual and a taken guard; keep the controlled fake Cart under tests/store only.
- **Step 1.2: Weighted regular spawning.** Test selection boundaries, values, aisle placement, IDs, instances, 0.5-second cadence and 46 cap. Add spawning during active phases with explicit state reset and no backlog burst.
- **Step 2.1: Deferred checkout and close boundary.** Test duplicate/empty checkout, repeat trips, same-frame inheritance ordering, already-accepted checkout at CLOSED and finalized round totals. Add deferred requests and banked-item snapshots; never write Cart inventory.
- **Step 2.2: Spills and conservation diagnostic.** Test the 20-into-8 post-transfer seam with four spills by identity and value, including cap and checkout boundaries. Connect cart_robbed once, spawn only its spilled list, and wire the diagnostic scene. Clearly distinguish fake-Cart coverage from real collision integration.

## 3. Prompts

Prerequisites: approved spec; synced branch; engine from TECH_STACK.md available; required assets present before scene references are introduced. Use only Anthony's files. Read AGENTS.md, this spec and CONTRACTS.md first. Each prompt updates its own TODO and Anthony's PROGRESS section in the same step commit.

### Prompt 1.1: Pickup collection and floor registry

```text
Files: tests/store/test_spawns_checkout.gd; tests/store/support/cart_double.gd; systems/store/pickup.gd; systems/store/pickup.tscn; systems/store/round_manager.gd.
Task/test first: Test acceptance, full-cart rejection, two-cart contention and immediate removal from get_pickups. Implement Pickup with Evan's existing item visual and a taken guard; keep the controlled fake Cart under tests/store only.
Write the named behavior tests first and observe their failure before implementing.
Implement only this step, wire it to the prior step, and run:
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
Check SCRIPT ERROR output and executed script count, not just the summary.
On success tick Step 1.1, update Anthony's handoff, commit "store: implement pickup collection", then stop and report.
On missing prerequisites or test failure, report the real result; do not tick the step.
```

### Prompt 1.2: Weighted regular spawning

```text
Files: tests/store/test_spawns_checkout.gd; systems/store/round_manager.gd; systems/store/store.gd.
Task/test first: Test selection boundaries, values, aisle placement, IDs, instances, 0.5-second cadence and 46 cap. Add spawning during active phases with explicit state reset and no backlog burst.
Write the named behavior tests first and observe their failure before implementing.
Implement only this step, wire it to the prior step, and run:
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
Check SCRIPT ERROR output and executed script count, not just the summary.
On success tick Step 1.2, update Anthony's handoff, commit "store: add weighted grocery spawning", then stop and report.
On missing prerequisites or test failure, report the real result; do not tick the step.
```

### Prompt 2.1: Deferred checkout and close boundary

```text
Files: tests/store/test_spawns_checkout.gd; systems/store/checkout.gd; systems/store/store.tscn; systems/store/round_manager.gd.
Task/test first: Test duplicate/empty checkout, repeat trips, same-frame inheritance ordering, already-accepted checkout at CLOSED and finalized round totals. Add deferred requests and banked-item snapshots; never write Cart inventory.
Write the named behavior tests first and observe their failure before implementing.
Implement only this step, wire it to the prior step, and run:
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
Check SCRIPT ERROR output and executed script count, not just the summary.
On success tick Step 2.1, update Anthony's handoff, commit "store: bank deferred checkout trips", then stop and report.
On missing prerequisites or test failure, report the real result; do not tick the step.
```

### Prompt 2.2: Spills and conservation diagnostic

```text
Files: tests/store/test_spawns_checkout.gd; systems/store/round_manager.gd; systems/store/test/spawns_checkout_test.tscn.
Task/test first: Test the 20-into-8 post-transfer seam with four spills by identity and value, including cap and checkout boundaries. Connect cart_robbed once, spawn only its spilled list, and wire the diagnostic scene. Clearly distinguish fake-Cart coverage from real collision integration.
Write the named behavior tests first and observe their failure before implementing.
Implement only this step, wire it to the prior step, and run:
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
Check SCRIPT ERROR output and executed script count, not just the summary.
On success tick Step 2.2, update Anthony's handoff, commit "store: preserve spilled item identities", then stop and report.
On missing prerequisites or test failure, report the real result; do not tick the step.
```

## 4. Improvements and bugs

None implemented. Missing assets, Cart/Player behavior and local engine availability are prerequisites, not permission to build another owner's system.
