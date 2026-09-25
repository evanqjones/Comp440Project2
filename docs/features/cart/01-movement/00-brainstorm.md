# 01-movement: Brainstorm

| | |
|---|---|
| System | Cart |
| Owner | Rickey |
| Branch | `cart/01-movement` |
| Agent | Claude Code |
| Date | 2026-09-24 |
| Milestone | Demo (merge by Thu 09-24 noon) |

## Goal

Make the cart drive from a `DriveCommand` with arcade handling at the GDD's 15 m/s, so Rivals (John) and Store (Anthony) can drive real carts in their work today and Player (`player/01`) has something to control.

## Grounding

- `GAME_SPEC.md` §4.2: top speed about 15 m/s, 1.2% slowdown per item, boost +8 m/s (Final); formula `top_speed = (BASE + boost) × (1 − 0.012 × items)`
- `GAME_SPEC.md` §5.1: steals need the faster cart at ≥ 5 m/s and ≥ 1.5 m/s faster, compared at contact
- `CONTRACTS.md` §1.2: `DriveCommand` throttle 0..1, brake 0..1 (brakes, then reverses once stopped), steer −1..1 (−1 left, +1 right), boost; Cart must not keep the command object
- `CONTRACTS.md` §2: `Cart` API; §8 invariant 4: nothing accepted after close
- `DECISIONS.md` D-015: Cart is a `CharacterBody3D`

## Q&A

1. **Q:** What does `cart/01-movement` include?
   **A:** Driving (throttle, brake/reverse, steer) plus the full top-speed formula, with items = 0 until `cart/02` and boost off until the boost feature. · *why:* the smallest thing that unblocks John and Anthony by noon, without cart/02 reworking the speed code.
2. **Q:** Handling model?
   **A:** Grip with a slight slide: the cart faces where you steer, and sideways velocity fades at a grip rate. · *why:* arcade and readable, and the Final wet-floor slip is just "low grip for 1 s".
3. **Q:** Turning when stopped?
   **A:** Pivot in place. Turn rate is 180°/s at 0 m/s, tapering to 90°/s at 15 m/s and above. · *why:* shopping-cart feel, easy in narrow aisles, easy for bots to unstick; high-speed turns stay wide.
4. **Q:** Acceleration and braking?
   **A:** Arcade: 10 m/s² (0→15 in ~1.5 s, 5 m/s in 0.5 s), brakes 25 m/s², coasting 4 m/s². · *why:* responsive while still rewarding a running start into a ram.
5. **Q:** Reverse?
   **A:** Max 4 m/s, and steering always rotates the same way (right = clockwise). · *why:* 4 m/s is below the 5 m/s steal threshold, so backing into someone never steals; same-way steering has no jump at 0 m/s when combined with pivoting.
6. **Q:** Who blocks driving outside RUSH / FINAL_CALL?
   **A:** Cart enforces it: commands count as neutral when `RoundManager.is_gameplay_active()` is false, so the cart coasts to a stop. Drivers should still go neutral too. · *why:* one guaranteed place for invariant 4 and the countdown lock. Test scenes set `RoundManager.phase = RUSH`.
7. **Q:** How is the test scene driven?
   **A:** A test-only keyboard driver and follow camera in `systems/cart/test/`, replaced by the real `PlayerController` and chase cam in `player/01`. · *why:* hand-testable today while keeping `cart/01` small.
8. **Q:** Where do tuning numbers live?
   **A:** One `CartTuning` resource (`systems/cart/cart_tuning.tres`) shared by all carts. · *why:* one file to tune, no per-instance drift, and Inspector-editable.
9. **Q:** Walls and shelves?
   **A:** Slide along them (`move_and_slide`): glancing hits keep speed, head-on hits stop you. · *why:* predictable; no pinballing for bots.
10. **Q:** Cart size?
    **A:** Keep 0.8 × 1.0 × 1.2 m (w × h × l). · *why:* close to real and readable from the chase cam. Ask Anthony for aisles ≥ 3.5 m, and Evan for a model that fits the box.

## Decisions

- Approach A: pure-math `CartMotion` helper + thin `cart.gd`. Numbers are unit-tested without physics.
- Commands last one frame (cleared after each physics step): no driver means neutral.
- Velocity is split into forward and sideways parts. Grip fades only the sideways part, so acceleration is exact.
- Actual velocity is re-read after `move_and_slide()` (walls remove the head-on part: no stored-up speed).
- Planar speed is recorded before each move, for `cart/03`'s steal rule.
- Brake beats gas. Gas while reversing brakes first. Analog gas sets the target speed (half gas = half top speed).
- Log D-017 (reverse cap, Cart enforces phase, commands last one frame).

## Contract changes needed

- None. Signatures stay as in `CONTRACTS.md` v0.1.

## Open questions

- None blocking. Feel numbers get tuned in the test scene; changes go into `cart_tuning.tres` and `GAME_SPEC.md` §12.

## Out of scope

- Inventory, item cap, weight in practice (`cart/02`), steal/knockback/stun/immunity (`cart/03`), boost meter (boost feature), wet-floor slip behavior (Final), `PlayerController` and chase camera (`player/01`), Evan's cart model.
