# 10-web-low-cost-rendering: Lite feature

| | |
|---|---|
| System / Owner | Integration / Anthony (delegated by Evan) |
| Branch | `integration/10-web-low-cost-rendering` |
| Agent / Date | Codex / 2026-10-01 |
| Milestone | Final |

## 1. Brainstorm

- Students report that the browser build lags on more than one Windows computer; they should not need to change browser or graphics-driver settings to play.
- The current WebGL device reported is Intel Iris Xe with hardware acceleration enabled. This rules out software-rendering fallback on that device, but does not prove the GPU is the only bottleneck.
- Earlier editor profiling found about 5,156 draw calls and 2,909 production-store geometry instances. Repeated-mesh batching reduced an interim sample to about 4,510 calls. The final combined-scene and student-browser frame time have not been measured.
- The existing performance feature already batches static store art, disables static-art shadow casters, replaces the fill light with ambient light, and throttles HUD/minimap refresh.

## 2. Spec

- Prefer reliable Web play over shadows and visual polish.
- Disable the main directional light's realtime shadow-map pass only in Web exports. Keep the desktop build's current shadow behavior.
- Preserve gameplay rules, physics, navigation, cart animations, controls, and UI.
- Do not require students to change browser settings or install a graphics driver.
- Do not claim a frame-rate improvement without a comparable browser measurement. Target-device measurement remains open because this session has no browser UI attached.

## 3. Plan and checklist

- [x] Branch from current `main`.
- [x] Gate the shadow-map pass off for the Web platform while retaining desktop shadows.
- [x] Re-export the Web build; Godot packed the updated HTML/PCK (existing certificate-store, occupied MCP port, and editor-settings warnings remain).
- [ ] Run full GUT and check the full game visually on Web and desktop (not run in this session).
- [ ] Compare the same 30-second store gameplay sample on student hardware; report measured results only.

## 4. Known performance costs

- Production store static art was the measured render hotspot: thousands of mesh instances/draw calls before batching. Batching/combine code is already in `systems/core/main.gd`, but its final draw-call count has no valid recorded profile.
- The main directional light still requested realtime shadows for dynamic geometry; the Web export now skips that pass.
- Four animated shopper/cart rigs and up to 46 floor pickups are plausible additional render/animation costs, but no measurement isolates either, so this change does not alter them.
- The available editor capture recorded 1.46 ms physics time against 55.7 ms total frame time; that capture suggests physics was not the dominant cost in that runtime, but it is not a student-browser measurement.
