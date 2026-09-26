# 07-minimap: Lite feature

| | |
|---|---|
| System / Owner | Player / Rickey |
| Branch | `player/07-minimap` (from `main`) |
| Agent / Date | Claude Code / 2026-09-25 |
| Milestone | Final |

## 1. Brainstorm

- GAME_SPEC §9.2: a store minimap under the timer. The HUD layout has a `%Minimap` Control slot (ASSETS §4).
- To need no wiring from the store owner, the map reads the level itself: standing static boxes on the world layer (walls, shelves) become its outline.

## 2. Spec

- **`HudMinimap`** (`systems/player/hud/hud_minimap.gd`, a `Control`): `PlayerHud` puts one inside `%Minimap`, filling it.
  - **Outline:** on its first frame, it scans the scene for `StaticBody3D`s on physics layer 1 with a `BoxShape3D` whose box stands above the floor (top above y 0.5, bottom below it). Each becomes a rectangle on the map; the floor slab is skipped. Other shapes are ignored.
  - **Bounds:** the outline plus the checkout and every cart's starting spot, with a 3 m margin, fitted into the slot with the aspect ratio kept. North-up: the store's back (−Z) is up, matching the chase cam's starting view.
  - **Draws:**
    - a dark translucent panel with light grey outline boxes;
    - a green checkout square (`RoundManager.get_checkout_position()`);
    - one dot per cart (`RoundManager.get_carts()`) in its profile color;
    - the player's dot bigger, with a white ring and a facing tick.

    It redraws every frame.
- **Pure math:** `HudMinimap.world_to_map(point, world_rect, size) -> Vector2`.
- **Contract changes:** none.

**Done when:**
- [x] GUT: mapping keeps aspect and is north-up; the scan finds a shelf but not the floor; the HUD puts a `HudMinimap` in `%Minimap`; one marker per cart. Full suite passes
- [x] Wired into the game and working with Run Project: the screenshot shows walls with the door gap, 7 shelves, the green pad, you (ringed, facing into the store) and the 3 bots where the camera sees them

## 3. Plan

1. Tests → `HudMinimap` + HUD hookup → suite → Run Project screenshot → commit → pull `main` → push, PR, merge, check on `main`.
