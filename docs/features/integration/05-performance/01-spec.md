# 05-performance: Spec

| | |
|---|---|
| System / Owners | Integration (main scene), Player (HUD), Assets (static visuals) |
| Branch | `integration/05-performance` |
| Status | Approved by user (2026-10-01) |
| Milestone | Final |

## 1. Overview

Reduce avoidable CPU and GPU work in the Browser/Web build so it runs more smoothly on the lower-powered device. Keep game rules, controls, camera behavior, and the authored store composition intact. Desktop is a regression check.

## 2. Player-facing behavior

- Gameplay and HUD information remain the same.
- Cart markers on the minimap continue to move smoothly enough to track all four carts.
- HUD labels and score lines may refresh at a capped 10 updates per second. The checkout arrow and animated effects remain frame-updated.
- Static decorative store meshes do not need to cast real-time shadows; the sun continues to light the store and carts, with shadows retained for gameplay-critical carts if feasible.

## 3. Implementation scope

- In `systems/core/main.tscn`, retain a single shadow-casting directional light. Keep the fill contribution using a cheaper ambient/environment contribution if it can preserve the current readable appearance in Compatibility rendering; otherwise remove the fill light and review the result.
- In `systems/player/hud/player_hud.gd`, cache cart snapshots/state for one update pass and refresh text/readouts at 10 Hz. Keep smooth checkout-arrow movement and time-sensitive animation on the render frame.
- In `systems/player/hud/hud_minimap.gd`, refresh cart marker data and queue redraw at 15 Hz; the obstacle scan remains one-time. Keep the latest marker positions available to its existing draw method.
- At production startup, disable shadow casting for GeometryInstance3D nodes under `ProductionStoreVisuals`, without changing their materials, collision, or other gameplay nodes.
- At production startup, batch repeated static production-art meshes that share the same mesh/material setup into MultiMesh instances, grouped by 10 m X/Z cells to retain useful frustum culling. Keep the original visual assets and collision scene unchanged.
- Add a reproducible before/after measurement note: same device and browser, same Web build settings, same store location, all four carts active, and a 30-second gameplay sample after warm-up. Aim for a sustained 30 FPS on the identified device. Record median frame time/FPS and observed visual differences. If the current device cannot be profiled from this environment, mark the device check for the user instead of inventing results.

## 4. Constraints and invariants

- Do not change `docs/CONTRACTS.md`, `systems/shared/`, physics, navigation, item spawning, scoring, or input behavior.
- Keep project renderer on Compatibility and Web export enabled.
- Preserve existing named nodes, scene paths, and asset ownership boundaries.
- No new addons or external assets.

## 5. Verification

- Run the full headless GUT suite and inspect for script errors or skipped scripts.
- Export/run the Web build and compare the same 30-second sample before/after on the target device where possible.
- Confirm minimap cart markers remain readable and responsive, HUD values update within 100 ms, lighting remains readable, and the full round still plays.
- Report measured values only when directly observed. A headless test is not a rendering performance measurement.

## 6. Out of scope

- Model decimation, texture compression/export changes, resolution scaling, dynamic resolution, reduced gameplay object counts, and bot AI scheduling. Consider these only if profiling identifies them as bottlenecks.

## 7. Done when

- [ ] Avoidable per-frame HUD/minimap work is reduced without affecting gameplay information or responsiveness; HUD values refresh at least 10 Hz and minimap markers at least 15 Hz.
- [ ] Shadow/light work is reduced while preserving readable scene lighting and gameplay-relevant shadows.
- [ ] Repeated static art is spatially batched, with substantially fewer production art render instances and no change to collision or visual placement.
- [ ] Full GUT passes without script errors or skipped scripts.
- [ ] Before/after frame-time results are recorded for the target Web device, or explicitly marked as awaiting the device owner’s run.
