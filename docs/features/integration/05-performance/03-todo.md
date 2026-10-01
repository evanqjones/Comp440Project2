# 05-performance: TODO

## Setup

- [x] Sync latest `main` and create `integration/05-performance`.
- [x] Inspect production scene, render setup, HUD update loops, and model sizes.
- [x] Human approves this spec (2026-10-01).

## Build

- [x] Capture an in-editor baseline and a same-runtime interim profile before final surface combining; target-device browser comparison remains pending.
- [x] Throttle HUD data refresh to 10 Hz and minimap redraw to 15 Hz, retaining responsive animation.
- [x] Replace directional fill with color ambient and disable static production-art shadow casting.
- [x] Add focused coverage for HUD/minimap update cadence and production render setup.
- [x] Batch repeated static-art meshes and combine compatible opaque surfaces by material and 10 m spatial cell; integration coverage checks render batches and Store collision remains present.

## Verify

- [ ] Full GUT suite passes with no script errors or skipped files (attempted with Godot 4.7.2, but launcher exited after the engine banner without a GUT summary; no pass is claimed).
- [ ] Run Project and inspect lighting, minimap, and HUD.
- [ ] Record comparable target-device frame-time results (awaiting access to the target browser/device; editor runtime profile is only an interim datapoint).
- [x] Update owner handoffs in `docs/PROGRESS.md`.

## Measurements observed in the editor runtime

- Before optimization: 18 FPS / 55.7 ms average frame, about 5,156 average draw calls, 1.46 ms physics, and 2,909 production-art geometry instances.
- After repeated-mesh MultiMesh batching only: 18.5 FPS / 53.81 ms average frame, about 4,510 average draw calls. 943 sources were folded into 165 MultiMesh groups; 1,966 MeshInstance3D nodes remained.
- SurfaceTool combining was prototyped on the runtime scene (1,832 sources into 227 compatible groups, about 0.32 s combine time), then implemented permanently. A valid post-combine runtime profile was not obtained. These editor results are not the target device/browser comparison.
