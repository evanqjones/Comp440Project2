# 06-boost: Lite feature

| | |
|---|---|
| System / Owner | Cart + Player / Rickey |
| Branch | `cart/06-boost` (from `main`) |
| Agent / Date | Claude Code / 2026-09-25 |
| Milestone | Final |

Lite: no contract changes. `DriveCommand.boost` and `CartState.boost_meter` already exist in CONTRACTS v0.1. One additive public method, `Cart.is_boosting()`, is read only by Rickey's camera and animator.

## 1. Brainstorm

- **Facts found:**
  - `PlayerController` already sends `boost` (Shift/Space), and John's bots already press it.
  - `CartMotion.top_speed(..., boosting)` and `boost_bonus = 8` exist.
  - `CartState.boost_meter` exists but is always 1.0, and the cart never uses the flag.
  - Evan's model has a `boost` clip.
- **Q:** What if the meter runs empty while boost is held? **A:** It locks until you let go. The meter refills only while the button is up.
- **Q:** How should it feel? **A:** Auto-gas plus a kick: boost counts as full gas, accelerates at 20 m/s² (normal is 10), and braking cancels it.

## 2. Spec

- **Meter (GAME_SPEC §4.2, §12):**
  - Holding boost with meter > 0, not locked, and not braking = boosting.
  - A full meter drains in **2 s** while boosting and refills in **8 s** while the button is up; holding the button without boosting does neither.
  - Hitting 0 while held **locks** boost until release.
  - `reset_for_round` refills it and unlocks.
  - Stunned or round inactive = no boost (the meter refills, since the button counts as up).
- **Drive:**
  - While boosting: top speed = `(15 + 8) × (1 − 0.012 × items)`, throttle counts as 1.0, and forward acceleration is **20 m/s²**.
  - After boost, the cart coasts back down at the normal 4 m/s².
  - Boosted speed counts for ram-steals (it's the real speed).
- **Pure rules:** `CartBoost` (`systems/cart/cart_boost.gd`): `is_boosting(meter, held, locked, braking)`, `next_meter(t, meter, boosting, held, dt)`, `next_locked(locked, meter, held)`.
- **Tuning** (`CartTuning` + GAME_SPEC §12): `boost_drain_time` 2.0 s, `boost_refill_time` 8.0 s, `boost_acceleration` 20 m/s² (new).
- **Cart API (additive, Player/Cart only):** `is_boosting() -> bool`.
- **Camera:** `ChaseCamera` FOV eases from 62° to **72°** while its target is boosting, and back afterwards (`fov_normal`, `fov_boost`, `fov_rate` 40°/s ≈ 0.25 s).
- **Shopper:** `CartShopperAnimator.pick_clip(..., boosting)` returns `boost` while boosting forward. Priority: stunned > backwards > boost > turn > walk > idle, as in Evan's preview.
- **HUD (fallback demo):** the status line shows the player's meter, `Boost [#####-----]`. The real `%BoostBar` comes with the HUD feature.
- **Files:** `cart_boost.gd`, `cart_tuning.gd`, `cart_motion.gd` (optional boosting acceleration), `cart.gd`, `cart_shopper_animator.gd`, `chase_camera.gd`, `demo_round.gd`, tests, GAME_SPEC §12, docs.
- **Out of scope:** boost particles and sound (Evan's audio), the real HUD bar.

**Done when:**
- [x] GUT:
  - meter drains in 2 s, refills in 8 s, doesn't refill while held;
  - locks at empty until release; brake cancels boost;
  - a boosting cart passes 15 m/s toward 23 without gas;
  - boost stops when the meter empties;
  - the camera FOV widens while boosting;
  - `pick_clip` returns `boost`;
  - the full suite passes.
- [x] Wired into the game and working with Run Project (on the branch, with `main` pulled in): player boost 9.4 → 19.3 m/s in 0.5 s, the meter drains over 2 s and locks empty, FOV 62↔72°, Rita boosts 2 s, and the HUD shows the meter. To recheck on `main` after merging

## 3. Plan

1. Tests → `CartBoost` + tuning + cart wiring + camera FOV + animator clip + demo HUD → suite → commit.
2. Pull `main`, then Run Project headless and check bot boosting and the player's meter → docs (GAME_SPEC §12, PROGRESS, D-028) → push, PR into `main`, merge, check on `main`.

## 4. Checklist

- [x] Branch created from a fresh `main`
- [x] Step 1
- [x] Step 2
- [x] Verified (tests + Run Project, with `main` pulled in)
- [ ] Pulled `main` right before pushing; PR merged; checked on `main`
