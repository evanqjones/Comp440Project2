# 07-pixelation-filter: Plan

| | |
|---|---|
| Branch | `integration/07-pixelation-filter` |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |

## 1. Blueprint

- Add a small screen-reading CanvasItem shader with an adjustable block size.
- Wrap it in a full-viewport CanvasLayer scene, defaulting to 3 pixels.
- Draw it after the 3D world and below the existing title/game UI layers.
- Add GUT coverage for default value, baseline value, and main-scene wiring.
- Run the suite, main scene, and Web build; assess text readability and measured
  performance on available hardware.

## 2. Iterations and steps

### Iteration 1: Screen filter and main-scene integration

- **Step 1.1:** Add GUT assertions for overlay setup/wiring and strength values.
- **Step 1.2:** Implement shader and full-viewport overlay; set default to 3px
  and expose the block size for A/B comparison.
- **Step 1.3:** Instance the overlay below interface CanvasLayers and verify
  viewport resizing and UI ordering.

### Iteration 2: Visual and Web verification

- **Step 2.1:** Run full GUT, main scene, Web build, and inspect UI readability.
- **Step 2.2:** Record observed device/browser performance or mark it pending.

## 3. Prompts

### Prompt 1 (Step 1.1): overlay coverage

```text
Context: Integration feature 07-pixelation-filter. Read AGENTS.md, 01-spec.md,
and CONTRACTS.md. Write focused GUT coverage for the overlay's default 3-pixel
size, 1-pixel baseline, full-viewport setup, and world-before-UI ordering. Run focused
tests and confirm the assertions fail before implementation. Do not change any
other system files. Then implement only the files in 01-spec.md, run full GUT,
check main.tscn, tick this step in 03-todo.md, commit
"integration: add adjustable pixelation overlay", and stop.
```

### Prompt 2 (Step 2.1): verification

```text
Read AGENTS.md, 01-spec.md, and 03-todo.md. Pull origin/main into this branch;
resolve and review any conflicts. Run the full GUT suite and check all script
errors and test counts, then run Project and export/run the Web build. Compare
the 1-pixel baseline with the default 3-pixel effect on gameplay, and confirm UI
remains crisp on title, pause, and results. Do not invent device performance results. Update this feature's
TODO and the Integration section of PROGRESS.md, commit the verification notes,
and stop without pushing or opening a PR.
```

## 4. Improvements and bugs

1. **Found and fixed during verification:** `tests/player/test_player_hud.gd`
   waited seven frames for a 10 Hz HUD refresh. Under uncapped headless
   rendering, that could be less than 100 ms; the assertion now awaits 1.5 HUD
   refresh intervals.
2. Record any shimmer discovered during the visual check.
