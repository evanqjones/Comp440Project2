# 07-pixelation-filter: Brainstorm

| | |
|---|---|
| System | Integration |
| Owner | Anthony (main-scene wiring) |
| Branch | `integration/07-pixelation-filter` |
| Agent | Codex |
| Date | 2026-10-01 |
| Milestone | Final |

## Goal

Experiment with a subtle pixelated look over the 3D game world while keeping
the interface crisp and the effect easy to tune or remove.

## Grounding

- `docs/TECH_STACK.md`: the Web build uses the Compatibility renderer and
  requires low-overhead, web-compatible rendering features.
- `docs/CONTRACTS.md`: no gameplay contract is involved.
- `docs/GAME_SPEC.md`: no art-style rule or pixelation setting is currently
  specified.

## Q&A

1. **Q:** Which build is the target? **A:** The current Godot game, with the
   Web/Compatibility build treated as required. · *why:* the visual change
   should ship consistently in the browser and desktop run.
2. **Q:** How strong should it be, and should it include the UI? **A:** Subtle
   3×3 display-pixel blocks; user then clarified to pixelate the world only and
   keep all UI crisp. · *why:* preserve interface text legibility while
   applying the pixel treatment to the 3D scene.
3. **Q:** How should the experiment be tunable? **A:** Expose pixel block size
   as a shader/material parameter, defaulting to 3 pixels; setting it to 1
   provides the unpixelated baseline. · *why:* allow quick visual comparison
   without adding an input binding or permanent debug key.

## Decisions

- Use a full-viewport `CanvasLayer` overlay after the 3D world but below all
  interface CanvasLayers; title, HUD, pause and result screens remain crisp.
- Keep it in the Integration feature and outside gameplay systems/contracts.
- Measure/report Web performance honestly; a screen-reading shader adds a
  full-frame sample/copy and may affect the lower-powered device.

## Contract changes needed

- None.

## Open questions

- The spec is awaiting Evan's approval before implementation.

## Out of scope

- Pixel-art asset replacement, camera/posterize effects, changing output
  resolution, quality settings UI, and permanent gameplay changes.
