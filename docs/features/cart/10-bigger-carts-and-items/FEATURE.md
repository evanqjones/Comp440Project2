# 10-bigger-carts-and-items: Lite feature

| | |
|---|---|
| System / Owner | Cart / Rickey (+ Store pickups, approved exception) |
| Branch | `cart/10-bigger-carts-and-items` (from `main`) |
| Agent / Date | Claude Code / 2026-09-30 |
| Milestone | Final polish |

## 1. Brainstorm

- Rickey: "make the player and the items that spawn bigger". He picked (2026-09-30):
  - "All carts 1.3×, look + hitbox": every shopper and cart, player and bots, 30% bigger, with the collision box grown to match so bumps still line up;
  - "Items 1.6×, I do it": floor items' models and pickup radius 1.6×, in `systems/store/` (the Store system, now Evan's to finish) as an **approved exception** to the own-part rule.
- Room check:
  - start slots are 2 m apart (x = −3, −1, 1, 3) and a 1.04 m-wide cart leaves about 1 m between them;
  - the doors are 8 m wide and aisles at least 3.5 m;
  - the bots' 0.75 m navigation radius still covers the cart's 0.52 m half-width.
- The tip-over on a steal sets `Visual.transform` directly, which would snap the scale back to 1. It has to keep the scale.

## 2. Spec

- **`Cart.SIZE_SCALE := 1.3`** (`cart.gd`), the one place the number lives:
  - `cart.tscn`'s `Visual` is scaled uniformly by it: shopper model, basket and item stack marker all grow together.
  - The name tag rides 1.3× higher but keeps its old text size (local scale 1/1.3); at full size the three bot tags ran together at the 2 m-apart start line.
  - The collision box becomes **1.04 × 1.3 × 1.56 m** (0.8 × 1.0 × 1.2 × 1.3), centered at y = 0.65.
- **Tip-over** (`CartStealEffects`):
  - It rolls the scaled visual about the scaled bottom edge (x = −0.52).
  - Upright and reset leave `Visual` at scale 1.3, not 1.
- **The item cubes** already follow the basket marker's global transform, so they scale with it. Swapping them for Evan's item models is `cart/09`.
- **Floor items** (`systems/store/pickup.tscn`, exception):
  - The `Visual` is scaled 1.6×, so Evan's item models and the placeholder cube both grow.
  - The trigger sphere radius goes 0.6 → **0.96 m**.
  - `pickup.gd` and spawning are unchanged.
- **Tuning table:** `GAME_SPEC.md` §12 "Cart size" → 1.04 × 1.3 × 1.56 m (1.3×). Pickup radius row added. Both logged as D-031.
- **Not changed:**
  - motion numbers (speed, turning, steal rule);
  - the camera;
  - `main.gd`'s bot navigation radius (Anthony's).

**Done when:**
- [x] GUT:
  - `SIZE_SCALE` is 1.3;
  - the box and its height match it;
  - a new cart's `Visual` is at 1.3;
  - a pickup's `Visual` is at 1.6 with a 0.96 m trigger;
  - on its side, the tip-over keeps the scale and pivots on the scaled edge;
  - after reset it's upright at 1.3.

  The full suite passes, including the real-physics steal tests.
- [ ] Run Project: floor items look bigger and are easier to grab; carts look bigger, fit through the doors and aisles, bump and steal normally, and bots still navigate.

## 3. Plan

1. Tests → scene + tip-over change → docs (§12, D-031) → suite → probe round → commit → ask to push / PR / merge.
