# 05-performance: Brainstorm

## Goal

Improve frame rate on the slower device while preserving the current look and game rules.

## Findings before implementation

- `systems/core/main.tscn` enables shadows on the main directional light and adds a second directional fill light.
- The production scene includes a large static aisle GLB (about 7.9 MB) and store shell GLB (about 2.4 MB). File size signals load/memory cost, not runtime frame cost by itself.
- `HudMinimap._process()` queues a redraw every rendered frame even though it only displays four moving carts over static obstacle geometry.
- `PlayerHud._process()` refreshes readouts and scoreboard text each rendered frame, including sorting carts and asking for state repeatedly.
- A live Godot profiler run on this session's production scene averaged 18 FPS / 55.7 ms per frame, with about 5,156 render draw calls. Runtime inspection found 2,909 static production-art mesh instances; 1,236 use a repeated mesh resource (175 repeat groups, up to 120 instances per mesh).
- The project uses the Compatibility renderer and targets Web.

## Working assumptions

- Keep the existing art, camera, and gameplay rules.
- Prefer reducing repeated HUD work and avoidable shadow work before changing model detail or render resolution.
- Batch repeated static art meshes into spatially bounded MultiMesh groups after profiling exposed high draw-call count.
- Compare a representative gameplay segment on the slower device with the Godot profiler or browser performance tools. Do not claim a frame-rate improvement without an on-device comparison.
- Treat the Browser/Web export as the priority; check desktop for regressions.

## Out of scope

- Gameplay/physics/navigation changes.
- Removing store decorations, changing camera framing, or lowering output resolution.
- Replacing or decimating authored models without evidence they dominate the frame.
- Changing contracts or gameplay tuning.
