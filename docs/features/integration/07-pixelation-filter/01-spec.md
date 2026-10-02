# 07-pixelation-filter: Spec

| | |
|---|---|
| System / Owner | Integration / Anthony (scene wiring), Evan (visual approval) |
| Branch | `integration/07-pixelation-filter` |
| Status | Approved by user (2026-10-01) |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Final |

## 1. Overview

Add a subtle, tunable pixelation experiment to the 3D world. A screen-reading
overlay snaps its sample position to a regular pixel grid before any interface
CanvasLayers draw. The default grid is 3×3 output pixels, giving the store and
carts a light pixel texture without redesigning art or reducing interface
clarity. The existing Compatibility renderer and web export remain in use.

## 2. Player-facing behavior

- The 3D store and carts receive the same subtle pixelation.
- HUD, title, pause, receipt, and results UI render above the filter and remain
  crisp.
- The effect starts enabled at 3 output pixels per block.
- Set the block size to 1 pixel to show the unfiltered baseline; larger values
  strengthen the look for visual experiments.
- It does not change gameplay, input, camera movement, screen resolution, or
  interface layout.

## 3. Rules and numbers

| Rule / constant | Value | Source |
|---|---:|---|
| Default pixel block width/height | 3 × 3 output pixels | User-selected subtle strength |
| Unfiltered baseline | 1 × 1 output pixel | Experiment comparison setting |
| Renderer | Compatibility | `docs/TECH_STACK.md` |

For each screen coordinate, quantize to the center of its containing block and
sample the screen texture once. Clamp UVs at viewport edges. Block size is a
positive exported/material parameter, not a gameplay setting.

## 4. Interfaces

**Uses:**
- Godot CanvasItem `hint_screen_texture` and `SCREEN_UV`; no gameplay APIs.

**Provides / emits:**
- No API or signals.

**Contract changes:** None.

## 5. Scenes and files

| Path | New / changed | Purpose |
|---|---|---|
| `systems/core/pixelation_overlay.tscn` | New | Full-viewport CanvasLayer and ColorRect between the 3D world and UI layers. |
| `systems/core/pixelation_overlay.gdshader` | New | Compatibility-friendly pixel-grid screen sample. |
| `systems/core/main.tscn` | Changed | Instance the overlay below interface CanvasLayers. |
| `tests/integration/test_pixelation_overlay.gd` | New | Check scene wiring and configurable default/material values. |
| `tests/player/test_player_hud.gd` | Changed | Wait for the HUD's actual 10 Hz refresh interval in an existing timing assertion. |
| `docs/features/integration/07-pixelation-filter/` | New | Brainstorm, spec, plan, and checklist. |

No `project.godot`, export preset, input map, gameplay system, or shared
contract changes are included.

## 6. Edge cases

| Case | Expected behavior |
|---|---|
| Window is resized or runs at a different display resolution | Pixel blocks remain 3 physical output pixels across, with the viewport edge clamped. |
| UI appears in a higher CanvasLayer | UI draws after the world filter and remains crisp. |
| Block size is set to 1 | Image looks unpixelated and provides an A/B baseline. |
| Web Compatibility renderer | Shader compiles and samples the screen without Forward+-only features. |
| Lower-powered device | Record observed frame-rate impact; do not claim a performance improvement. |

## 7. Test plan

**GUT tests:**
- [ ] `test_main_pixelates_world_before_drawn_ui_layers`: overlay exists in
  `main.tscn`, fills the viewport, and draws below title/HUD/menu CanvasLayers.
- [ ] `test_pixelation_default_and_baseline_values`: default is 3 pixels and
  the effect parameter accepts 1 for the baseline.

**Test scene checks:**
- [ ] Run `main.tscn`; compare 1-pixel and 3-pixel settings on the 3D world in
  active gameplay.
- [ ] Confirm fine HUD text and menu labels stay crisp while diagonal rails and
  moving carts show the world effect.

**Integration check:**
- [ ] Run Project with the 3-pixel default; 3D gameplay is pixelated and title,
  HUD, pause, and results remain crisp and usable.
- [ ] Export/run the Web build in a browser and compare the target device with
  the 1-pixel baseline. Record measured frame time only when directly observed.

## 8. Out of scope

- New pixel-art assets, palette/posterization treatment, low-resolution render
  targets, an in-game settings menu, extra input actions, and changes to game
  rules or project renderer.

## 9. Done when

- [ ] Subtle 3×3 pixelation affects the 3D world only; 1-pixel baseline
  restores the unfiltered world and UI remains crisp.
- [ ] Overlay remains full-frame and correctly ordered through window resize
  and screen changes.
- [x] Full GUT passes without skipped parse-error scripts.
- [x] Main scene is visually checked and the Web Compatibility export compiles.
- [ ] Browser rendering and performance impact are measured on the target
  device; assigned to Evan because no browser surface is available here.
