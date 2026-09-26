# 07-name-tags: Lite feature

| | |
|---|---|
| System / Owner | Cart / Rickey |
| Branch | `cart/07-name-tags` (from `main`) |
| Agent / Date | Claude Code / 2026-09-25 |
| Milestone | Final |

## 1. Brainstorm

- GAME_SPEC §4.2 and §9.1 call for a floating name tag over each cart in its shopper's color. The `ShopperProfile` contract has `display_name` and `color` "for UI and name tags". Evan's cart model has no `NameTag` marker, so Cart places one itself.
- **Q:** Does your own cart show a tag? **A:** No, bots only. From the chase cam it would sit in the middle of your view. `cart_id` 0 is the human (Cart contract).

## 2. Spec

- `cart.tscn` → `Visual/NameTag`: a `Label3D` with `CartNameTag` (`systems/cart/cart_name_tag.gd`), at (0, 2.35, 0.5), above the shopper.
  - Billboard (always faces the camera), 64 px text with a black outline.
  - Visual only. It sits under `Visual`, so it tips over with a robbed cart.
- **Shows:** `profile.display_name` in `profile.color`, **only for bots** (`cart_id != 0`). No profile = hidden. It follows later profile or id changes.
- **Contract changes:** none.

**Done when:**
- [x] GUT: Carl's cart shows "Coupon Carl" in teal; the player's cart (id 0) and a cart without a profile show nothing; the tag is a billboard. Full suite passes
- [x] Wired into the game and working with Run Project: tags over Carl (teal), Bev (pink) and Rita (grey), none over you

## 3. Plan

1. Test → `CartNameTag` + `cart.tscn` → suite → Run Project frame → commit → pull `main` → push, PR, merge, check on `main`.
