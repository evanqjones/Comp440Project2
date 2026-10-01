# 05-performance: Plan

| | |
|---|---|
| Branch | `integration/05-performance` |
| Spec | [01-spec.md](01-spec.md) |
| Status | Implementation complete; verification pending |

## Steps

1. Record baseline: attempted; current device/browser was not available in this session and Godot is not installed/on PATH. Revisit when that runtime is available.
2. Complete: reduce HUD polling and minimap redraw cadence while preserving the smooth arrow animation; add focused coverage for update cadence and existing displayed values.
3. Complete: replace the second directional fill light with color ambient fill and disable static production-art shadow casters at startup.
4. Complete: batch repeated meshes and merge compatible opaque surfaces into 10 m spatial groups; add integration coverage for reduced render instances and retained collision.
5. Pending: run full GUT, launch Run Project and the Web export, record after measurements, update progress handoffs, and list exact visual checks for the human.

## Review gates

- Implement one step at a time, tests first where behavior is covered by rules or timing.
- No push, PR, or merge without explicit authorization.
- If the target device cannot be measured by the agent, leave that acceptance item clearly assigned to the user.
