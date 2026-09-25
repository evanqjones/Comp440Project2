# FBX cart driving preview

- Owner: Evan (Assets)
- Branch: `assets/01-fbx-cart-test`, based on user-approved `origin/cart/03-shopper`
- Updated: 2026-09-25, Codex
- Status: preview scene implemented; manual runtime check is incomplete.

## Brainstorm

Evan supplied `Blender/man_shopping_cart.fbx`, containing a model and animation,
and requested a separate scene using the existing game cart movement. Evan
approved using `origin/cart/03-shopper` because main still has movement stubs.
Use the real Cart, PlayerController and ChaseCamera through scene instances
and existing public APIs. The original FBX remains intact.

Evan later added `Blender/man_cart_godot.fbx` and its export report. The report
lists eight baked actions (`backwards`, `boost`, `default`, `hit`, `idle`,
`stunned`, `turn`, `walk`). Godot imports the eight clips on an AnimationPlayer;
the original `man_shopping_cart.fbx` has no animation player or baked clips.

## Spec

- Create `assets/test/fbx_cart_test.tscn`, a standalone driving preview with
  a floor, simple obstacles, lighting, and the existing chase camera.
- Instance `systems/cart/cart.tscn` and use the existing player controller,
  tuning resource, collision, and movement code. Hide the placeholder art only
  in this preview and attach the imported FBX model to the preview cart.
- Put any test-only setup and animation adapter in `assets/test/`. These are
  preview harness files, not reusable visual scenes; reusable visual wrappers
  remain free of scripts, collision, physics bodies and lights per ASSETS §2.
- Fit and orient `man_cart_godot.fbx` with the cart facing -Z and the wheel base
  at floor height. Keep its 51-bone rig and imported animation tracks.
- Loop `idle` while stopped, `walk` while moving forward, `backwards` while
  reversing, `turn` while steering under forward motion, and `boost` when boost
  is held. Scale playback rate with speed. The `walk` clip has constant MASTER
  position/rotation tracks, so it does not move the animated model away from
  the physics Cart.
- Use existing throttle, steering and brake/reverse bindings. Enable the RUSH
  phase in this test harness as existing system tests do. No new handling rules
  or boost implementation: this branch's movement does not implement boost yet.
- Provide brief on-screen controls and animation status for inspection.
- No contract changes. No edits to other owners' scenes/scripts, main scene,
  project settings, or shared data. No addon installation in this feature.

## Plan

One implementation step after spec approval:

1. Connect to the open Godot editor with its existing MCP addon enabled; inspect
   the FBX hierarchy, dimensions, materials and animation tracks. Import assets.
2. Create the standalone preview and test-only adapter, reusing existing Cart,
   PlayerController and ChaseCamera resources. Add focused checks for scene
   loading, original movement reuse and imported animation availability.
3. Run the full headless GUT suite. Check every SCRIPT ERROR and confirm the
   Scripts count equals the number of test files. Run the preview and verify
   movement and animation through MCP, then inspect a rendered frame.
4. Update this checklist and Evan's PROGRESS section; commit the completed step
   using `assets: add animated FBX cart driving preview`. Stop and report.

## Acceptance and manual check

- [x] Branch created from the approved movement branch.
- [x] Spec and plan prepared.
- [x] Evan approves this spec.
- [x] Godot MCP connected and `man_cart_godot.fbx` imported; eight clips inspected.
- [x] Preview scene instances original Cart movement, PlayerController and chase camera.
- [x] Model faces travel direction, wheels meet floor, placeholders are hidden (Evan visual check).
- [x] Preview adapter maps movement state to walk/backwards/turn/boost clips and idle at rest.
- [x] Manual visual check confirms animation and model alignment while driving (Evan reports it looks good).
- [ ] Full GUT suite passes with no skipped scripts or script errors (not run).
- [ ] Evan checks S/Down braking and reversing, obstacle collision, idle pose,
      animation pace and camera framing with F6 on the scene. WASD and Space
      animation responses were already confirmed.
- [ ] Handoff updated and implementation committed; no push or PR requested.

## Current limitations

The preview script initially failed parsing because an inferred variable came
from `Array.pop_back()` (a Variant); it is now explicitly typed as `Node`. The
scene launches after that fix with no new editor errors. Runtime state confirms
the cart and imported model are present. Evan visually checked the preview
after the squash-and-stretch update and reports that everything looks good.
Reverse/braking, obstacle collision and detailed camera framing still need a
focused check. The full GUT suite has not been run.
