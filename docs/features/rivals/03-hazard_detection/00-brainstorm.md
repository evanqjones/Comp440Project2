# 03-hazard_detection: Brainstorm

| | |
|---|---|
| System | Rivals |
| Owner | John |
| Branch | `rivals/03-hazard_detection` |
| Agent | Gemini CLI |
| Date | 2026-09-29 |
| Milestone | Final |

## Goal

Enable rival bot shoppers to detect active stage hazards (such as slippery puddles and falling pallets), immediately reroute away from compromised paths and unsafe targets, and execute safe standoff maneuvers when approaching blocked destinations like checkout. This prevents bots from blindly spinning out and makes them compete intelligently in the Final milestone.

## Grounding

What the spec already fixes (quote it; don't re-decide it here):
- `GAME_SPEC.md` §4.3: "Reactions (Final): retarget on `cart_robbed`; reroute on `hazard_spawned`."
- `GAME_SPEC.md` §7: "Stage hazards are a fourth source of competition in the Final build. Their frequency rises each round, so players must read the floor as well as watch rivals."
- `CONTRACTS.md` §4: `signal hazard_spawned(hazard: Node3D)` on `RoundManager`.
- `CONTRACTS.md` §6: Cart physics layer 2 `carts`, mask `world` (1) + `carts` (2) + `hazards` (4).

## Q&A

1. **Q:** How should `BotController` detect and avoid hazards along its path?
   **A:** Option A: Active Hazard Tracking + Waypoint/Path Proximity Check. `BotController` connects to `RoundManager.hazard_spawned(hazard: Node3D)` and maintains an array of currently active hazards. During path evaluation and decision ticks, the bot evaluates distance to hazards along the navigation path and filters unsafe targets. · *why:* Directly adheres to `GAME_SPEC.md` §4.3 ("reroute on `hazard_spawned`"), works seamlessly with `NavigationAgent3D`, and allows deterministic, headless GUT unit testing.

2. **Q:** What exact danger radius should `BotController` enforce around a hazard’s `global_position` when checking if a target or path is unsafe?
   **A:** Option A: Uniform 2.5 m radius (in the horizontal XZ plane, ignoring vertical Y). If a hazard exposes a `danger_radius: float` property, use that; otherwise default to 2.5 m. · *why:* 2.5 m covers the full area of a puddle or falling pallet warning shadow plus cart clearance (~1.2 m), without falsely blocking adjacent aisles through walls.

3. **Q:** When and how should `BotController` check for hazard conflicts on its path?
   **A:** Option A: Immediate check on `hazard_spawned` + path validation on each 0.3 s decision tick. If a newly spawned hazard intersects the current target or navigation path, drop target and recalculate immediately. On every regular 0.3 s decision tick, filter candidate pickups/rivals within 2.5 m of any active hazard or whose path intersects a hazard. · *why:* Reacts with zero latency when a hazard spawns in front of the bot, while preventing path planning into hazards during regular navigation.

4. **Q:** How should `BotController` behave if its path to checkout or its only available goals are blocked by a hazard?
   **A:** Option A: Standoff outside the hazard radius, then proceed when cleared or during final call. The bot holds at a safe waypoint 3.0 m away from the hazard until it despawns, unless the round clock enters `FINAL_CALL` ($\le 5\text{ s}$ left), in which case it charges through to attempt banking before the doors close. · *why:* Protects banked hauls from spinning out right at the checkout pad while preventing permanent lockups as time expires.

5. **Q:** How should `BotController` maintain its active hazard list and compute path intersection?
   **A:** Option A: `tree_exited` tracking + horizontal line-segment distance check. Connect each hazard's `tree_exited` to automatically purge it from `active_hazards`, and check the minimum distance from each hazard to each consecutive line segment of `nav_agent.get_current_navigation_path()`. · *why:* Navigation waypoints can be 4–6 meters apart along straight aisles; point-to-segment math ensures hazards between waypoints are never missed.

6. **Q:** How should `BotController` handle state transitions and driving commands while slipping or when completely hemmed in by hazards?
   **A:** Option A: Neutralize commands during active slip, and fallback to coasting/unsticking if trapped. When `cart.is_slipping()` is true, output neutral controls (`throttle = 0.0`, `boost = false`, `brake = 0.0`). If no valid paths exist, coast outside hazard zones; if speed $< 0.5\text{ m/s}$ for $\ge 1.0\text{ s}$, normal stuck recovery safely repositions the bot. · *why:* Trying to steer while steering is locked by `apply_slip` is ineffective; neutral control lets Cart physics resolve the spin naturally.

7. **Q:** How should we structure unit tests for hazard detection, and what test overrides should `BotController` provide?
   **A:** Option A: Provide `test_hazards_override` and `test_nav_path_override` for isolated, deterministic GUT testing in `tests/rivals/test_bot_hazard_detection.gd`. · *why:* Allows microsecond-fast, reliable unit testing of all geometric checks, rerouting triggers, and state edge cases without waiting on physics ticks or NavigationServer threads.

8. **Q:** What items should be explicitly defined as In Scope vs. Out of Scope?
   **A:** Option A: Rivals bot detection and path avoidance in `systems/rivals/`. Out of scope: hazard spawning/lifecycles (Store/Anthony), cart slip mechanics (Cart/Rickey), and HUD/audio warnings (Player/Evan). · *why:* Preserves system boundaries and adheres strictly to Rule 2 and Rule 3 of `AGENTS.md`.

## Decisions

- Track hazards via `RoundManager.hazard_spawned` and `hazard.tree_exited`.
- Horizontal (XZ) danger radius is 2.5 m (or `hazard.danger_radius` if specified).
- Path collision uses point-to-line-segment distance testing against `get_current_navigation_path()`.
- Reroute immediately if an incoming hazard intersects the current path; filter candidate targets during regular 0.3 s decision ticks.
- Standoff 3.0 m from checkout if blocked, charging through if $\le 5.0\text{ s}$ remain in the round.
- Neutralize driving commands while `cart.is_slipping()`.
- Unit tests use test overrides (`test_hazards_override`, `test_nav_path_override`) in `tests/rivals/test_bot_hazard_detection.gd`.

## Contract changes needed

- None. All behavior builds on existing `RoundManager.hazard_spawned(hazard: Node3D)`, `RoundManager.is_gameplay_active()`, and `Cart.is_slipping()` / `Cart.get_state()`.

## Open questions

- None.

## Out of scope

- Creating hazard scenes, collision meshes, or spawning timers (Anthony / `integration/04-stage-hazards`).
- Cart slip physics and spin implementation (Rickey / Cart).
- Moving obstacle trajectory extrapolation (Pallet Jack in backlog).
- HUD hazard indicators or PA voice announcements.
