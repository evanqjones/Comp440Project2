# 06-left-turn-transition: preserve shopper mirror state across clip changes

| | |
|---|---|
| System / Owners | Cart / Rickey; preview asset / Evan |
| Branch | `integration/06-left-turn-transition` |
| Agent / Date | Codex / 2026-10-01 |
| Milestone | Final |

## Spec

- **Behavior:** the mirrored left-turn pose must not abruptly flip back while
  the turn clip crossfades into walk, idle, or another non-turn clip. Keep the
  chosen mirror side until the next turn clip selects a new side.
- **Uses:** the existing Cart animation selection and Evan preview adapter;
  no contracts change.
- **Files:** `systems/cart/cart_shopper_animator.gd`,
  `assets/test/fbx_cart_preview.gd`, `tests/cart/test_cart_shopper.gd`, and
  the owners' sections of `docs/PROGRESS.md`.
- **Out of scope:** new animations, imported model edits, crossfade duration,
  movement rules.

**Done when:**
- [x] Mirror state is stable when a turn clip changes to walk/idle.
- [ ] GUT completes without script errors.
- [x] Preview driven through a left turn into walk; transition state stays mirrored.

## Plan

1. Add a pure mirror-state transition helper and regression coverage.
2. Use the helper in the game Cart animator and standalone preview; hand-check.

## Checklist

- [x] Branch created from fresh `main`.
- [x] Implementation and focused regression check.
- [ ] GUT verification (CLI emitted no test summary in this environment).
- [x] In-editor preview driven through turn into walk; duplicate preview model limits visual inspection.
