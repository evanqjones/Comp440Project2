# 05-evan-shopper: Lite feature

| | |
|---|---|
| System / Owner | Cart / Rickey (uses Evan's asset) |
| Branch | `cart/05-evan-shopper`, cut from `integration/01-demo` (after #10 merged in) and merged back into it: the demo branch is where Rickey's and Evan's work come together |
| Agent / Date | Claude Code / 2026-09-25 |
| Milestone | Demo (Fri 09-25) |

Lite is OK here: no contract changes. It instances Evan's model and drives it from Cart state; Evan's files are untouched.

## 1. Brainstorm

Goal: one cohesive playable demo. Evan's animated shopper-and-cart replaces the grey placeholder on **every** cart, driven by Rickey's cart mechanics.

- **Q:** Where does Evan's shopper appear? **A:** Every cart everywhere: it replaces the placeholder in `cart.tscn`, so the demo round, test scenes and later `main.tscn` all use it.
- **Q:** How do we tell the 4 shoppers apart? **A:** Tint the shirt ("Petrol blue cotton") and handle ("Handle orange") materials with each shopper's profile color at runtime.
- **Q:** What happens when a cart is robbed? **A:** Keep the tip-over and play Evan's `hit` then `stunned` animation during it.
- **Facts found:** `Blender/man_cart_godot.fbx` is one rigged man+cart model: 186 skinned mesh parts, 1 skeleton, clips `idle`, `walk`, `turn`, `backwards`, `boost`, `hit`, `stunned`, `default` (1.96 s loops; `hit` is 1.46 s). Evan's preview picks clips from keyboard input; bots need it driven by **cart motion** instead. Measured with the skeleton posed: the model faces −Z, the man stands at its origin and the cart part sits 0.59–1.44 m ahead of him (basket floor y ≈ 0.64, 0.52 m wide); animated poses already span y ≈ 0–1.8, so the wheels are on the floor with no lift (Evan's preview lifts 0.415 m, the half-height of one steel part's local box; confirm by render).

## 2. Spec

- **Model:** `cart.tscn` → `Visual/ShopperModel` = instance of `res://Blender/man_cart_godot.fbx` at (0, 0, 1.0): shifted back so Evan's basket sits over the cart's collision box (box z −0.6..0.6, basket −0.44..0.41) and the man stands behind it, where the box shopper stood (z 0.95). Height set by render. The grey `PlaceholderMesh`, `Nose` and box `Shopper` stay in the scene but **hidden** (Evan's preview scene still references them). `Visual/ItemStack` moves onto Evan's basket floor, (0, 0.65, 0.03), scaled 0.7 so 3 cubes across fit his 0.52 m basket (a full cart heaps above the rim). No collision on the model; the cart's 0.8 × 1.0 × 1.2 m box is unchanged.
- **`CartShopperAnimator`** (`systems/cart/cart_shopper_animator.gd`, a `Node` child of the Cart, adapted from Evan's `fbx_cart_preview.gd`):
  - Clip choice (pure, testable): `pick_clip(forward_speed, yaw_rate, stunned) -> String` returns `stunned` if stunned; `backwards` if forward < −0.2 m/s; `turn` if moving and |yaw rate| > 0.8 rad/s; `walk` if |forward| > 0.2; else `idle`.
  - Playback: 0.2 s crossfade. Moving clips play at `clamp(|forward| / 3, 0.55, 1.5) × 2` (Evan's pacing); idle at ×2; on entering a stun it plays `hit` at ×3 (≈ 0.49 s) and queues `stunned` for the rest of the 0.7 s stun. Yaw rate comes from the cart's rotation change per frame (negative = turning right, since steering right lowers yaw). Left turns mirror the turn clip (model `scale.x` negative), and there's a speed-scaled squash/bounce, both as in Evan's preview. The loop clips (idle, walk, turn, backwards, boost) are set to loop.
  - Items ride in the basket: each frame the `ItemStackDisplay` follows the rig's `CART` bone (the basket is skinned to it), because Evan's `turn` clip swings the cart part sideways and a fixed stack floated beside it (found in the render check).
  - Look: in `_ready`, surfaces using "Petrol blue cotton" or "Handle orange" get an override material in `profile.color` (cached per color). No profile keeps Evan's colors.
- **Uses:** `Cart.get_state()` (`is_stunned`), `Cart.profile`, `Cart.velocity`, the cart's facing and yaw; Evan's material names ("Petrol blue cotton", "Handle orange"), clip names and `CART` bone. **Contract changes:** none.
- **Files:** `systems/cart/cart.tscn`, `systems/cart/cart_shopper_animator.gd`, `tests/cart/test_cart_shopper.gd` (updated for the model), docs.
- **Edge cases:** FBX has no AnimationPlayer → the animator does nothing (no errors). Clip names are matched by suffix after "|" (Evan's convention). Freed cart → nothing.
- **Known cost (for Evan):** 186 parts per cart means about 750 skinned draw calls for 4 carts. Fine on desktop for the demo; merge parts before the web build.
- **Out of scope:** boost clip (no boost mechanic yet), moving the FBX to the agreed `assets/models/shopper/` path (Evan's call), Evan's preview scene (his; it now shows a second model since `cart.tscn` has one).

**Done when:**
- [x] GUT: `pick_clip` rules (stunned beats everything); items follow the `CART` bone; every cart has `Visual/ShopperModel` with an AnimationPlayer and walk/idle/hit clips; no collision on the model; box placeholders hidden; Carl's cart shirt is teal; cart collision box unchanged. Full suite passes (no `SCRIPT ERROR`, `Scripts` = number of test files)
- [x] Rendered frames: the model sits on the floor over the collision box, cubes sit in the basket, tints differ, the tip-over shows the model
- [ ] Rickey plays the fallback demo round with Evan's shoppers

## 3. Plan

1. Tests for `pick_clip` + model structure + tint → `CartShopperAnimator` + `cart.tscn` changes → suite → commit `cart: Evan's animated shopper on every cart`.
2. Render checks (fit, basket, tints, tip-over), adjust `ItemStack` / offsets → commit.
3. Docs (PROGRESS Cart section, notes for Evan), merge into `integration/01-demo`, push (ask first).

## 4. Checklist

- [x] Branch created
- [x] Step 1: tests + animator + scene
- [x] Step 2: render checks and fit (no lift needed; items now follow the basket bone)
- [x] Step 3: docs; merged into `integration/01-demo` (push: ask first)
