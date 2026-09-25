# 03-shopper: Lite feature

| | |
|---|---|
| System / Owner | Cart / Rickey |
| Branch | `cart/03-shopper` (stacked on `cart/02-inventory`, PR #6) |
| Agent / Date | Claude Code / 2026-09-24 |
| Milestone | Demo (Fri 09-25), placeholder; Evan's model for Final |

Lite is OK here: no contract changes, no collision, and nobody depends on it.

## 1. Brainstorm

Goal: every cart is pushed by a person, so shoppers read as people from the chase cam.

- **Q:** Who gets a person? **A:** All 4 shoppers (you, Carl, Bev, Rita), so it lives in the shared `cart.tscn` (Cart system).
- **Q:** How big tonight? **A:** Lite. (Animation was the first answer, then dropped by the next one.)
- **Q:** Does the shopper take up space? **A:** Visual only. The cart's 0.8 × 1.0 × 1.2 m collision box is unchanged, so rams, walls, pickups and aisle fit behave exactly as tested.
- **Q:** How should it look? **A:** **Evan handles all shopper visuals.** Build plain boxes only, to be replaced by his model. No styling, skin tones or animation here.

## 2. Spec

- **Behavior:** a static, box-built person (two legs, body, head, two arms reaching forward to the cart handle), about 1.7 m tall, standing behind every cart and facing the same way (−Z). One neutral placeholder color. Moves and turns with the cart because it's part of the cart's `Visual`.
- **Numbers:** shopper origin 0.95 m behind the cart origin (the cart's back face is at 0.6 m, so 0.35 m gap). Legs 0.16 × 0.8 × 0.2 at x = ±0.11. Body 0.44 × 0.6 × 0.26 at y = 1.1. Head 0.26 cube at y = 1.58. Arms 0.1 × 0.1 × 0.46 at x = ±0.27, y = 1.2, reaching forward to the handle.
- **Uses:** nothing new. **Contract changes:** none.
- **Files:** `systems/cart/cart.tscn` (new `Visual/Shopper` with `LeftLeg`, `RightLeg`, `Body`, `Head`, `LeftArm`, `RightArm` meshes); `tests/cart/test_cart_shopper.gd`; `docs/ASSETS.md` (manifest request row for Evan); `docs/TODO.md` (this feature, ram-steal renumbered to `cart/04`).
- **Edge cases:** reversing tight against a shelf may clip the shopper into it (visual only; accepted). The spring-arm camera ignores it (no collision).
- **Out of scope:** real model, skin tones, clothing, walk or push animation (all Evan's model), collision.

**Done when:**
- [ ] GUT: every cart has `Visual/Shopper` behind it (z > 0.6); the shopper has no collision objects or shapes; the cart still has exactly one 0.8 × 1.0 × 1.2 collision box
- [ ] Full suite passes headless: no `SCRIPT ERROR`, `Scripts` count = number of test files
- [x] Rickey sees shoppers pushing carts in the cart and player test scenes
- [ ] Request row for `assets/models/shopper/shopper_visual.tscn` in `ASSETS.md` §5; request noted in the Cart section of `PROGRESS.md`

## 3. Plan

1. Failing tests in `tests/cart/test_cart_shopper.gd` → add `Visual/Shopper` boxes to `cart.tscn` → suite green → commit `cart: add box-placeholder shopper`.
2. ASSETS.md request row + PROGRESS + TODO → render a frame to check it → commit `cart: shopper request for Evan and docs`.

## 4. Checklist

- [x] Branch created (stacked on #6); feature doc written
- [x] Step 1: tests + placeholder shopper
- [x] Step 2: request row, docs, visual check
- [x] Verified (tests + Rickey's look, 2026-09-24)
- [ ] PR opened (stacked on #6), reviewed, merged
