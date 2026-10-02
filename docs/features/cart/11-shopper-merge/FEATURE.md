# 11-shopper-merge: Lite feature

| | |
|---|---|
| System / Owner | Cart / Rickey |
| Branch | `cart/11-shopper-merge` (from `main`) |
| Agent / Date | Claude Code / 2026-10-01 |
| Milestone | Final: the live web build is "really really laggy" |

## 1. Root cause (measured 2026-10-01, current `main`, native M2 Pro, in the store)

| Change (everything else equal) | Draw calls | Frames in 2 s |
|---|---|---|
| All 4 shopper models shown (normal game) | 1,536 | 71 (≈ 35 fps) |
| All 4 shopper models hidden | **170** | **371 (≈ 185 fps)** |
| Player's shopper: animation frozen / hidden | — | 241 / 240 (vs 107–120 normal) |
| Player's shopper: skinning off | — | 191 |
| Player's shopper: shadows off | — | 126 (no real change) |

- Evan's `Blender/man_cart_godot.fbx` imports as **186 separate skinned `MeshInstance3D`s** per shopper, so 4 shoppers come to about 750 skinned objects and about 1,400 draw calls with their shadows.
  - Every part is **rigid**: each follows exactly one bone (40 bones used of 51).
  - There are only **12 materials** (106 parts are "Brushed steel" cart wires) and 22,825 vertices.
- Animation and skeleton math cost about 0.01–0.03 ms per cart (timed). The cost is the renderer skinning and drawing 186 separate pieces per shopper every frame.
- WebGL charges far more per draw call than native, which is why the GitHub Pages build crawls.
- **Ruled out by measurement:**
  - store music;
  - `main.gd` batching (store art only);
  - lights (there's only the sun);
  - camera collapse;
  - HUD, minimap and bots;
  - per-cart animation evaluation;
  - shopper shadows.

## 2. Spec

- **`CartShopperMerge.merge(skeleton)`** (`systems/cart/cart_shopper_merge.gd`), called once from `CartShopperAnimator._ready()`:
  - It replaces the skeleton's skinned parts with **one skinned `MeshInstance3D` ("MergedShopper") with one surface per material** (12): same skeleton, same animations, same look.
  - **Vertices:** each rigid part's vertices are re-expressed against one unified bind pose per bone, `unified⁻¹ × part_bind`, which is exact for single-bone weights. Normals and tangents use the matching basis.
  - **Skin:** the unified `Skin` has one named bind per skeleton bone.
  - **Cache:** the merged mesh and skin are built once and shared by every cart. The per-cart shirt and handle tint stays a surface override.
  - **Safety:** if any part isn't rigid, single-bone and triangles, nothing is merged (the original parts stay).
- **Effect:** draw calls per shopper go from 186 to 12 (plus the same for shadows), and skinning runs per material instead of per part.
- **Not changed:**
  - Evan's FBX and `cart.tscn`;
  - animations, mirroring, bounce, tint, the item stack riding the basket bone, tip-over;
  - gameplay and collision.

**Done when:**
- [x] GUT (33 scripts, 243/243):
  - one merged mesh with a surface per material and the same vertex count;
  - skinned positions match the original parts at a non-rest pose (AABB and centroid within 1 mm);
  - the mesh is shared between carts;
  - the existing shopper tests (clips, tint, basket) pass;
  - the merged mesh is bound to the skeleton. This was added after the first in-game look showed unposed shoppers: a new `MeshInstance3D`'s skeleton path is empty by default.
- [x] Native (M2 Pro, editor run, 2 s windows):

  | Spot | Draw calls before → after | Frames in 2 s before → after |
  |---|---|---|
  | In the store | 1,536–2,957 → **574–693** | 71 → **164–240** (240 is the 120 Hz cap) |
  | At the start line | ~3,424 → **694** | |

  A close-up screenshot shows the merged shoppers fully drawn and tinted, including Carl mid tip-over.
- [ ] Web: re-export `docs/`; the live build is visibly smoother.

## 3. Plan

1. Tests → merge → wire into the animator → suite → native measure + screenshot → commit → pull `main` → re-export `docs/` → push, PR, merge → live check.
