# 11-web-lightweight-store-art: Lite feature

| | |
|---|---|
| System / Owner | Integration / Anthony; assets / Evan (delegated) |
| Branch | `integration/11-web-lightweight-store-art` |
| Agent / Date | Codex / 2026-10-01 |
| Milestone | Final |

## 1. Brainstorm

- The store is the best-supported performance target. Earlier profiling measured about 2,909 production-art geometry instances and 5,156 draw calls before batching; draw calls remained high after repeated-mesh batching, while the final surface-combine runtime profile was never captured.
- Parsing the production GLBs found 1,271 aisle meshes / 161,104 triangles and 388 store-shell meshes / 46,416 triangles. The aisle asset contains hundreds of duplicated shelf merchandise pieces (cheese packets, produce, bakery goods, cartons, snack bags, frozen boxes, and electronics display pieces).
- Evan explicitly prioritizes a playable Web build over visual detail and approved removing expensive visual features. Reduce static shelf merchandise in Web only; preserve desktop visuals, fixtures, lane layout, collision, and actual gameplay pickups.

## 2. Spec

- In Web builds, remove only named, non-interactive merchandise MeshInstance3D nodes from `ProductionStoreVisuals` before static-mesh batching.
- Keep store shell, shelf fixtures, signs, layout, barriers, collision, pickup spawning and collection, carts, bots, UI, and rules unchanged.
- Desktop builds keep all imported store merchandise.
- The Web art becomes intentionally sparse. No frame-rate improvement is claimed until measured on a student browser.

## 3. Plan and checklist

- [x] Inspect GLB node/triangle counts and identify repeated merchandise names.
- [x] Remove the named non-interactive merchandise meshes on Web before batching.
- [x] Re-export the Web build. Godot packed updated `docs/index.html` and `docs/index.pck` (existing root-certificate, occupied MCP port, and editor-settings warnings remain).
- [ ] Run the game and GUT on desktop/Web, visually checking store layout, collision, and live pickups (not run in this session).
- [ ] Compare a warmed 30-second browser sample on the Intel Iris Xe and at least one other student device.

## 4. Scope and limits

The Web startup filter omits 1,042 of 1,271 named aisle mesh instances. Their source meshes total 125,688 of 161,104 aisle triangles. Those counts come directly from the GLB accessors; they are not FPS measurements. The GLB and collision sources remain intact for desktop builds and future re-use.
