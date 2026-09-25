# 01-controller-camera: Lite feature

| | |
|---|---|
| System / Owner | Player / Rickey |
| Branch | `player/01-controller-camera` (stacked on `cart/01-movement`, PR #4) |
| Agent / Date | Claude Code / 2026-09-24 |
| Milestone | Demo (Fri 09-25) |

Lite is OK here: no contract changes, and nobody depends on the internals. Anthony only instances the scenes in `main.tscn`.

## 1. Brainstorm

Goal: the human drives their cart in the real game. `PlayerController` turns input into a `DriveCommand` every frame, and a chase camera follows behind (`GAME_SPEC.md` §4.1, §8).

- **Q:** Full or Lite? **A:** Lite: saves time before the 9 am demo, same test-first build.
- **Q:** How does the camera follow? **A:** Smoothly behind the cart's **nose** (catches up in about 0.2 s). It swings around when you pivot or reverse, so "up = forward on screen" always holds.
- **Q:** Walls between the camera and the cart? **A:** A **SpringArm3D** (Godot node that shortens its arm when something blocks it) pulls the camera toward the cart. It collides with world geometry only (layer 1), so other carts never make it jump.
- **Q:** Keyboard steering? **A:** A **quick ramp**: keys ease from 0 to full steer over 0.15 s (and back), so taps make small corrections. The gamepad stick stays direct, based on which device steered last.
- **Defaults (not asked, obvious):** the controller sends neutral outside RUSH/FINAL_CALL (belt and braces with D-017). If `cart` is empty and the controller's parent is a `Cart`, it uses the parent (easy wiring for Anthony). Boost input is passed through (Cart ignores it until the boost feature). FOV widening and camera shake are Final.

## 2. Spec

**Behavior**
- Gas / brake / steer / boost come from the input actions in `CONTRACTS.md` §5 (keyboard + gamepad). Gas and brake are analog on triggers.
- Keyboard steer ramps at 1 / 0.15 s per second toward the pressed direction (0.15 s from 0 to full, 0.3 s full left → full right). Stick steer is used as-is.
- Outside RUSH / FINAL_CALL the controller sends a neutral command and resets the steer ramp to 0.
- Camera: pivot 1.0 m above the cart. Arm pointing back and up, so the unobstructed camera is **8.5 m behind and 5.5 m above** the cart. It looks at a point **4 m ahead** of the cart, 1 m up. FOV **62°**. Position and yaw ease toward the target at rate 15/s (about 95% caught up after 0.2 s). It snaps into place on the first frame (no swoop from the origin).
- Spring arm: sphere shape radius 0.3 m, margin 0.2 m, collision mask = layer 1 (world) only.

**Numbers** (added to `GAME_SPEC.md` §12): steer ramp 0.15 s; camera pivot 1.0 m, look-ahead 4.0 m, follow rate 15/s; spring-arm radius 0.3 m. Camera offset and FOV are already in §12.

**Uses:** `Cart.apply_command()` (`CONTRACTS.md` §2), `RoundManager.is_gameplay_active()` (§3), input actions (§5). No contract changes.

**Files**
| Path | Purpose |
|---|---|
| `systems/player/player_controller.gd` | `class_name PlayerController extends Node`: `@export var cart: Cart`, `@export var steer_ramp_time := 0.15`, `build_command(delta) -> DriveCommand`, sends it in `_physics_process` |
| `systems/player/chase_camera.gd` + `chase_camera.tscn` | `ChaseCamera` (Node3D) → `Arm` (SpringArm3D) → `CameraSpot` (Marker3D); `Camera3D` (top-level, current, FOV 62) copies the spot's position and looks ahead. Export `target: Node3D` |
| `systems/player/test/player_drive_test.tscn` + `.gd` | Arena with normal 2 m walls, a 3.5 m aisle, and one **8 m-tall wall** to see the spring arm pull in. Cart + PlayerController + ChaseCamera. Sets phase RUSH. Readout of speed and arm length |
| `tests/player/test_player_controller.gd`, `tests/player/test_chase_camera.gd` | GUT tests |

The camera isn't a direct child of the spring arm, because SpringArm3D rewrites its children's transforms each physics frame. The arm moves `CameraSpot`, and the camera follows the spot.

**Edge cases:** no cart assigned and parent isn't a Cart → does nothing (no errors). Target freed → camera stops following. Yaw wrap-around (±180°) uses `lerp_angle`. Direction reversal on keys passes through 0 (0.3 s).

**Out of scope:** FOV 62→72 on boost, shake on ram, rumble, HUD (`player/02`), pause.

**Done when:**
- [ ] GUT: controller maps gas/brake/steer; neutral when the round isn't active; keyboard ramp reaches full in 0.15 s; stick is direct; drives a real cart forward. Camera sits ≈ 8.5 m behind / 5.5 m above; a tall wall behind the cart pulls it in; FOV 62.
- [ ] Full suite passes headless: no `SCRIPT ERROR`, `Scripts` count = number of test files
- [ ] Rickey drives `player_drive_test.tscn` (Cmd+R): the camera feels smooth, the tall wall pulls the camera in, and taps give small steers
- [ ] PROGRESS handoff: how Anthony wires `PlayerController` and `ChaseCamera` in `main.tscn`

## 3. Plan

1. `PlayerController` → tests: gas/brake map, neutral when inactive, keyboard ramp 0.15 s, stick direct, parent-cart fallback, drives a real cart ≥ 5 m/s in 60 frames. Commit `player: add PlayerController`.
2. `ChaseCamera` scene + script → tests: rest position ≈ (0, 5.5, 8.5) behind a cart at the origin facing −Z; a tall wall at z = +4 pulls the camera in front of it; FOV 62. Commit `player: add ChaseCamera with spring arm`.
3. Test scene → loads headless for 120 frames with no errors; render a frame to check the view. Commit `player: add drive test scene`.
4. Docs: GAME_SPEC §12 rows, PROGRESS (Player section) handoff + wiring for Anthony. Commit `player: docs and handoffs for 01-controller-camera`.

## 4. Checklist

- [x] Branch created (stacked on `cart/01-movement`); `PROGRESS.md` updated
- [ ] Step 1: PlayerController + tests
- [ ] Step 2: ChaseCamera + tests
- [ ] Step 3: test scene
- [ ] Step 4: docs and handoffs
- [ ] Verified (tests + Rickey's test-scene check)
- [ ] PR opened (after #4 merges, or stacked on it), reviewed, merged
- [ ] `PROGRESS.md` and `TODO.md` updated
