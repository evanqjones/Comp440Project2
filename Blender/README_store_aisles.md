# Build the Checkout Chaos aisle set

The aisle builder adds six stylized product areas to `Assets.blend` and exports
the visual geometry to `assets/models/store/checkout_chaos_aisles.glb`.

1. Open the repo's `Assets.blend` in Blender 5.2 or newer.
2. Switch to the **Scripting** workspace and use **Open** in the Text Editor to
   open `Blender/build_store_aisles.py`.
3. In the Text Editor, choose **Run Script** (or press **Alt+P** with the mouse
   over that editor).

The script preserves existing scene collections and replaces only its own
generated `CC Aisles` and `CC Aisle Preview` collections if run again. It saves
the `.blend` in place and makes Blender's normal `.blend1` backup. The GLB
contains only the six aisle visuals; the preview camera and lights stay in the
editable Blender scene.

The generated overview is at
`docs/features/assets/02-store-aisles/preview.png`. In Blender's Outliner,
expand `CC Aisles` to inspect `Aisle Produce`, `Aisle Bakery`, `Aisle Dairy`,
`Aisle Snacks`, `Aisle Frozen`, and `Aisle Electronics` individually.

In Godot, open and run `assets/test/store_aisles_preview.tscn` to view the whole
set. Store integration can instance the visual-only scene at
`assets/models/store/aisles_visual.tscn`.
