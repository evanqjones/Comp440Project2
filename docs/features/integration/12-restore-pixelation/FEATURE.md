# 12-restore-pixelation: Lite feature

| | |
|---|---|
| System / Owner | Integration / Anthony |
| Branch | `integration/12-restore-pixelation` |
| Agent / Date | Codex / 2026-10-01 |
| Milestone | Final |

## 1. Goal and approved behavior

The user requested returning the game to the appearance it had with the pixel layer after the Web-only performance cuts did not help. Restore the previously approved subtle 3×3 world pixelation effect and undo the unhelpful Web-only merchandise and no-shadow changes. Keep the crisp UI ordering from the original pixelation spec.

## 2. Changes

- Re-instance `systems/core/pixelation_overlay.tscn` in `systems/core/main.tscn` as it was before pixelation was disabled.
- Revert the Web-only shadow and merchandise changes with inverse commits; desktop and Web use the original full static store art and authored shadow behavior again.
- Regenerate `docs/index.html` and `docs/index.pck` from the restored scene.
- Keep the pre-existing static store batching and HUD/minimap performance work.

## 3. Checklist

- [x] Restore the overlay scene instance in the production main scene.
- [x] Revert the two Web-only performance changes.
- [x] Re-export Web and inspect exporter output (Godot completed the savepack; existing certificate-store, occupied MCP-port, and editor-settings warnings were nonfatal).
- [ ] Run GUT and visually inspect Web/desktop output (not run in this session).

