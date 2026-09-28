# Six stylized grocery aisles

- Owner: Evan (Assets)
- Branch: `assets/02-store-aisles`, based on current `main` (`0b1f5f2`)
- Status: six aisle sets built in Blender and available as a Godot visual scene; awaiting Store-owner integration and visual review.

## Brainstorm

Evan requests six distinct product-filled supermarket aisles in the supplied
`Assets.blend`: produce, bakery, dairy, snacks, frozen foods, and electronics.
The store should feel like a modern big-box supermarket, with one cohesive
stylized art direction matching the project's cart and category palette.

## Spec

- Add the six aisle environments to the existing `Assets.blend` without
  replacing or deleting the existing scene content.
- Make each aisle recognizable from its fixtures and products:
  - **Produce:** open-front chilled cases with colorful fruit and vegetables in
    crates and bins.
  - **Bakery:** warm-toned baskets and trays with loaves, baguettes, pastries,
    and small cakes.
  - **Dairy:** refrigerated cases with milk cartons/jugs, bottles, and cheese.
  - **Snacks:** shelving stocked with distinct chip bags and cracker boxes.
  - **Frozen:** glass-door freezer cases with frozen-pizza boxes and packaged
    meat products.
  - **Electronics:** shelves and display stands with televisions, game consoles,
    and controllers.
- Use a shared low-poly, friendly game-art style, consistent scale, lighting
  treatment, bevel language, and material finish across all six aisles. Make
  each category distinct with the project's palette: green, orange, white, red,
  blue, and purple, respectively. Use generic packaging and fictional labels;
  no Walmart logo or copied branding.
- Keep aisles modular and visually legible, suitable for a third-person game
  camera and the existing store's approximate 6.5 m lane width and 14 m shelf
  run. Provide enough product variety to read clearly without individually
  modeling tiny text or dense packaging details.
- Organize the Blender scene into six clearly named aisle collections and
  reusable product/fixture subcollections. Preserve any existing collections
  and objects outside the new aisle collection.
- Keep game-ready geometry modest and use simple materials. Export the aisle
  environment as a Godot-friendly GLB under `assets/models/store/` while
  retaining the editable source in `Assets.blend` as Evan requested.
- Deliver a preview showing all six aisle types, plus a short note listing the
  export path and how to inspect each collection.
- No scripts, physics/collision, or gameplay wiring. Do not edit
  `systems/core/main.tscn`, `project.godot`, shared contracts, or other owners'
  files. No third-party assets; all products are modeled from primitives, so no
  external licenses are needed.

## Plan

1. Inspect `Assets.blend` and the existing cart art direction. Preserve the
   original scene and create a six-aisle layout/collection structure.
2. Model and dress produce and bakery aisles; check product readability and
   cohesion in the viewport.
3. Model and dress dairy and frozen refrigerated cases, using consistent case
   geometry and category-specific products.
4. Model and dress snacks and electronics shelves, matching fixture scale and
   material style.
5. Review all six together from an in-game-height camera, adjust color balance
   and spacing, and export the Godot-ready GLB.
6. Verify the exported asset opens in Godot, update Evan's progress handoff, and
   present the preview for Evan's visual review.

## Preview

![Overview of the six stylized aisle sets](preview.png)

## Acceptance checklist

- [x] Evan approves this spec.
- [x] Blender aisle builder drafted and Python syntax checked.
- [ ] All six aisle categories are clear and visibly different (needs visual review).
- [ ] Aisles share one stylized art direction and match the existing cart art (needs visual review).
- [ ] Produce has open chilled cases and recognizable produce; bakery has
      baskets/trays and bread/cakes; dairy has fridges and milk/cheese; snacks
      has chips/crackers; frozen has freezers and pizza/meat; electronics has
      shelves with consoles/controllers/TVs.
- [x] The six aisle collections are present in `Assets.blend` and organized by
      category. The builder preserves collections outside its generated set.
- [x] The exported GLB reimported in Godot; intended scale and visible materials
      still need visual review.
- [x] Generated the six-aisle overview image at `preview.png`.
- [x] Removed the default scene cube, extended sign posts to the aisle floor,
      and aligned products to their supporting trays and shelf surfaces.
- [x] Re-aligned all 144 snack packages within the shelf boards and matched
      package heights to the rack's shelf levels.
- [x] Created the Godot visual wrapper and runnable preview scene; the preview
      ran with all six aisles visible.
- [ ] Evan visually approves the aisle presentation.

## Environment note

`Assets.blend` is at the repository root. Blender 5.2.2 is now available at
`C:\Program Files\Blender Foundation\Blender 5.2\blender.exe`. The builder at
`Blender/build_store_aisles.py` created 1,663 generated aisle objects in six
category collections, saved the source, and exported
`assets/models/store/checkout_chaos_aisles.glb` (about 8.3 MB). Blender 5.2
exposes EEVEE as `BLENDER_EEVEE`, so the builder now selects that engine when
`BLENDER_EEVEE_NEXT` is unavailable. Godot reimported the GLB successfully.
The default scene `Cube` was removed at Evan's request; its original camera and
light remain. Sign-post bottoms and product/shelf contact heights were checked
in Blender. All 144 snack packages fit within their board bounds, sit 3 mm into
their shelf tops, and remain under the rack frame. Godot reimported the GLB;
`assets/models/store/aisles_visual.tscn` wraps it as a visual-only asset, and
`assets/test/store_aisles_preview.tscn` runs the six-aisle preview with its own
camera and lighting. The preview ran successfully. The actual game scene still
needs Store-owner integration, and Evan's visual review remains; `main.tscn` was
not changed.
