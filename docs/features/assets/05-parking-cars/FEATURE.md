# Parking lot car set: Feature brief

**System / Owner:** Assets / Evan  
**Branch:** `assets/05-parking-cars`  
**Status:** Proposed  
**Related:** `docs/ASSETS.md`, `docs/features/assets/04-grand-opening-displays/FEATURE.md`

## 1. Brainstorm

- **Q:** What vehicle mix should fill the parking lot?  
  **A:** Three distinct everyday silhouettes: a compact hatchback, a family sedan,
  and a small SUV. This gives the lot variety while keeping each vehicle small
  enough for the existing 3 m stalls.

## 2. Spec

### Goal

Add a few friendly, low-poly parked cars to the existing parking-lot preview so
the store entrance feels like an active grand opening.

### Behavior and use

- Cars are static visual props with no scripts, collision, physics bodies, or
  lights. The parking cars preview instances them outside the entrance.
- Place six cars (two of each silhouette) in outer parking stalls. Keep the
  middle approach and the four cart spawn positions clear.
- Point the cars toward the storefront. Keep a centered origin at ground
  contact and Godot's forward direction at -Z.

### Art direction and dimensions

- Match the bright, flat-color, low-poly store and aisle assets. Use original,
  unbranded designs with tinted windows, distinct rooflines, chunky wheels,
  simple headlights and tail lights, and restrained trim.
- Use 1 Blender unit = 1 metre. Fit within the parking stall's 3 m width and
  4.5 m depth: maximum vehicle footprint 1.95 m × 4.2 m and maximum height
  1.7 m. Wheels must touch the ground at y=0.
- Keep each vehicle below the asset guide of about 2,000 triangles.

### Files

- `Blender/build_parking_cars.py`: reproducible Blender model builder and GLB
  exporter. Keep `.blend` source binaries out of the repo per `ASSETS.md` §1.
- Three visual-only scenes under `assets/models/store/parking_cars/`, one each
  for the compact hatchback, family sedan, and small SUV, with their exported
  GLBs.
- Update `assets/test/grand_opening_store_preview.tscn` to show six parked cars
  around the outer stalls, and update the asset manifest and Evan's progress
  handoff.

### Boundaries

- Assets and the separate playable preview only. Do not edit Store gameplay,
  `systems/core/main.tscn`, `project.godot`, or another owner's files.
- The models stay decorative; collision and car-driving behavior are out of
  scope.
- No third-party models or textures.

### Verification

- Check exported triangle counts, world bounds, wheel-floor contact, and scene
  wrappers in Blender / Godot.
- Run the grand-opening preview and confirm the cars sit inside the painted
  stalls without blocking the entrance or center cart route.
- Run the full headless GUT suite and inspect for script/import errors.

### Done when

- [ ] Three reusable car variants are exported and wrapped as visual-only
      Godot scenes.
- [ ] The playable preview shows six cars parked in outer stalls, with the
      entrance and center approach clear.
- [ ] Full GUT passes and the preview launches without script/import errors.
- [ ] `ASSETS.md` and Evan's `PROGRESS.md` handoff document the files and
      placement.

## 3. Plan

1. Build three distinct Blender vehicle models and export one GLB per variant;
   verify scale, contact, and triangle budgets.
2. Add the visual-only Godot wrapper scenes and asset manifest rows.
3. Place two of each car in outer parking stalls in the grand-opening preview;
   check entrance and cart-route clearance in Godot.
4. Run full GUT, fix any import or preview issues, and update Evan's progress
   notes and handoff.
