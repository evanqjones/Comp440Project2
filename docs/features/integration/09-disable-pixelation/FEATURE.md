# 09-disable-pixelation: Lite feature

| | |
|---|---|
| System / Owner | Integration / Anthony |
| Branch | `integration/09-disable-pixelation` |
| Agent / Date | Codex / 2026-10-01 |
| Milestone | Final |

## 1. Brainstorm

Goal: Turn off the full-screen pixelation pass in the game build to remove its extra screen-texture work while diagnosing low frame rate.

- **Q:** How should it be disabled? **A:** Remove the overlay instance from `main.tscn`; preserve the shader and scene so the experiment can be re-enabled later.
- **Q:** Should the published Web game get the same change? **A:** Yes; regenerate `docs/index.*` and merge it into `main` so GitHub Pages receives the unfiltered build.

## 2. Spec

- **Behavior:** The production game renders with its normal resolution and no pixelation screen pass. The world, UI, and audio remain otherwise unchanged.
- **Numbers:** None.
- **Uses:** None; no contract changes.
- **Files:** `systems/core/main.tscn`; regenerated `docs/index.html` and `docs/index.pck`; `docs/PROGRESS.md`.
- **Edge cases:** Keep `pixelation_overlay.tscn` and its shader in the project for future experiments; do not instance them in the production main scene.
- **Out of scope:** Other rendering or model optimizations.

**Done when:**
- [x] `main.tscn` no longer runs the pixelation overlay.
- [ ] The Web export is regenerated from this scene and deployed through `main` / `docs`.
- [ ] The source overlay scene and shader remain available for later use.

## 3. Plan

1. Remove the pixelation scene reference and instance from `systems/core/main.tscn`.
2. Regenerate the Web export at `docs/index.html`; commit the updated loader and pack.
3. Merge the change to `main` so GitHub Pages serves the unfiltered build.

## 4. Checklist

- [x] Branch created from fresh `main`.
- [x] Spec approved by the user's direct request to disable pixelation.
- [x] Remove production overlay from `main.tscn`.
- [x] Regenerate Web export.
- [ ] Merge to `main`; verify the live build pack matches the refreshed export.
