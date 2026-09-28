# Plan: Parking lot car set

Feature spec: [`FEATURE.md`](FEATURE.md)  
Branch: `assets/05-parking-cars`

Build one step at a time: test or inspect first, implement, verify, tick the
matching TODO, commit, and report the result.

## Step 1 — Blender models

- Implement `Blender/build_parking_cars.py` for the compact hatchback, family
  sedan, and small SUV.
- Export one GLB per car to `assets/models/store/parking_cars/`.
- Check vehicle dimensions, floor contact, unbranded materials, and triangle
  budgets.

## Step 2 — Godot visual scenes

- Add one wrapper scene per exported car, each with only its root `Node3D` and
  GLB instance.
- Document the three variants in `docs/ASSETS.md`.

## Step 3 — Parking preview

- Instance six cars in outer painted stalls in
  `assets/test/grand_opening_store_preview.tscn`.
- Preserve the center route and keep the entrance clear.
- Run the preview and inspect placement in Godot.

## Step 4 — Verification and handoff

- Run the full headless GUT suite and inspect Godot logs.
- Update Evan's `docs/PROGRESS.md` status and handoff notes.
