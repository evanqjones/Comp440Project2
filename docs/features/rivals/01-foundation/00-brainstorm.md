# 01-foundation: Brainstorm

| | |
|---|---|
| System | Rivals |
| Owner | John |
| Branch | `rivals/01-foundation` |
| Agent | Gemini CLI |
| Date | 2026-09-24 |
| Milestone | Demo |

## Goal

Set up the fundamental AI state-machine and decision framework for the three rival carts (Coupon Carl, Aunt Bev, and Rolling Rita). This establishes the core bot behaviors of collecting, banking, and chasing, enabling them to compete against the player and each other in the Demo milestone.

## Grounding

What the spec already fixes (quote it; don't re-decide it here):
- `GAME_SPEC.md` §4.3: "Three AI shoppers that drive the same Cart through the same DriveCommand a player uses."
- `GAME_SPEC.md` §4.3: "Decisions every 0.3 s: pick the pickup with the best value ÷ distance; or chase a rival carrying a big load (>= 10 items); or head for checkout when greedy enough or when time is short."
- `GAME_SPEC.md` §12: Tuning table:
  - Bot decision interval: `0.3 s`
  - Bot stuck detection: `barely moving for 1 s → reverse and turn`
  - Bot stuck recovery reverse duration: `1.0 s`
  - Carl/Bev/Rita greed, aggression, and boost habit starting values
  - Bot aggression increase per round: `+0.1 per round, capped at 1.0`
- `CONTRACTS.md` §4: "Drivers start sending real input on round_started and send neutral commands (all zero) after round_ended."
- `CONTRACTS.md` §2 & §3: `RoundManager` API (fetching carts, pickups, checkout position, and signals `round_started`, `round_ended`, `deal_spawned`) and `Cart` API (`cart_robbed` signal and `get_state()` snapshot).

## Q&A

1. **Q:** How should the bot prioritize states, and what are the exact criteria/thresholds for switching?
   **A:** Option A (Explicit State Machine with strict priorities: **STUCK** recovery first, **BANKING** second, **CHASING** third, and **COLLECTING** fourth). · *why:* It is highly deterministic, maps perfectly to headless GUT unit testing, and ensures critical behaviors (unsticking, banking on low time or full load) are prioritized.

2. **Q:** How should a bot decide *whether* to chase and *which* rival to chase when multiple qualify?
   **A:** Option A (Roll probability against current `aggression`. If it passes, target the qualifying rival carrying $\ge 10$ items with the highest item count/value, breaking ties by closest distance). · *why:* High-aggression bots like Coupon Carl naturally seek the most lucrative haul first, aligning with the thematic greed and aggression profiles.

3. **Q:** Which specific methods and signals from our contracts should the bot use to update its target and driving inputs?
   **A:** Option 1 (Active subscription and polling. Subscription: listen to `round_started` to begin, `round_ended` to stop and send zero inputs, and both `cart_robbed` and `RoundManager.deal_spawned` to trigger an immediate decision tick. Polling: query `RoundManager` every 0.3 s for carts, pickups, and checkout position). · *why:* Conforms to the 0.3 s decision interval while enabling immediate reactions to critical game events (deals and robberies).

4. **Q:** How are `aggression` and `boost_habit` mathematically applied, and how does the round-by-round difficulty scaling affect them?
   **A:** Option A (On `round_started`, scale aggression additively: `base_aggression + (round_number - 1) * 0.1` capped at 1.0. For boosting, periodically evaluate boost every 1.0 s by rolling against `boost_habit`; hold boost for 1.0 s or until empty if the steering offset to the target is $< 30^\circ$). · *why:* Avoids rapid boost-button flutter, simulates natural straight-line boosting, and scales difficulty as specified in the tuning table.

5. **Q:** How should the bot handle stuck-states, navigation failures, and dynamic target loss?
   **A:** Option A (A bot is stuck if speed $< 0.5\text{ m/s}$ for $\ge 1.0\text{ s}$. Trigger **STUCK** recovery for 1.0 s of reverse-and-turn inputs. Navigation failures add the target to an unreachable blacklist, triggering an immediate retarget. Targets that are collected or checked out are caught during standard polling or via signal connection, triggering immediate re-evaluation). · *why:* Prevents infinite wall-riding loops and ensures bots act intelligently under dynamic world changes.

6. **Q:** How should we structure the automated GUT tests to verify the `BotController` logic deterministically?
   **A:** Option A (Isolated Mock and Inject pattern in headless GUT. Mock out the 3D navigation and physical movement, and inject mock/forced `randf()` results to verify state-transitions, timers, recovery logic, and target selection with 100% determinism). · *why:* Guarantees unit tests run in milliseconds without flaky physical or pathfinding timing jitter, leaving visual feel to visual test scenes.

7. **Q:** What should be explicitly declared OUT OF SCOPE for this first feature (`01-foundation`), and deferred to later features or the Final milestone?
   **A:** Option A (In Scope: decision logic, state transitions, stuck recovery, contract wiring, and unit testing. Out of Scope: obstacle/rival avoidance, advanced boost meter optimization, steering/handling fine-tuning, and wet-floor hazard re-routing). · *why:* Ensures a robust, clean, and reviewable foundation that can easily receive the physics movement code once Rickey merges it.

## Decisions

- **State Hierarchy:** STUCK > BANKING > CHASING > COLLECTING.
- **Rival Target Selection:** Aggression check passes $\rightarrow$ target qualifying rival ($\ge 10$ items) with highest item count/value, break ties by distance.
- **Signal Triggers:** Immediate decision evaluation on `cart_robbed` and `RoundManager.deal_spawned`.
- **Stuck Recovery:** Triggered at speed $< 0.5\text{ m/s}$ for $\ge 1.0\text{ s}$; drives reverse/turn for $1.0\text{ s}$.
- **Unreachable Blacklist:** Target blacklisted on navigation failure; forces immediate retarget.
- **Boost periodic evaluate:** Evaluated every $1.0\text{ s}$ against `boost_habit`; held for $1.0\text{ s}$ if target offset is $< 30^\circ$.
- **Aggression scaling:** Scales by $+0.1$ per round starting from Round 1.
- **GUT Testing:** Done via Isolated Mock & Inject, mocking 3D pathfinding and overriding `randf()` results to guarantee determinism.

## Contract changes needed

- None.

## Open questions

- None.

## Out of scope

- **Local Obstacle/Rival Avoidance:** Raycasting or dynamic collision avoidance (will rely on basic NavigationAgent3D pathing and stuck recovery). (Future TODO)
- **Boost Meter Optimization:** Complex management of boost reserve/refill state. (Future TODO)
- **Advanced Intercept Tracking:** Leading targets or computing intercept vectors (bots drive directly toward current target position). (Future TODO)
- **Dynamic Hazard Routing:** Re-routing around wet-floor zones or falling displays. (Future TODO)
