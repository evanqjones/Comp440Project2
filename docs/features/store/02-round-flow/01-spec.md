# 02-round-flow: Spec

| | |
|---|---|
| System / Owner | Store / Anthony |
| Branch | `Anthony-Stores` |
| Status | Draft — awaiting Anthony's approval |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Demo: Thursday 09-24 |

## 1. Overview

Implement the Demo's single timed round and door lifecycle.

## 2. Player-facing behavior

Start with a three-second countdown and closed doors. Open on GO, run a two-minute round, enter final call for its last twenty seconds, close and lock gameplay at zero, then show results for ten seconds through Player's existing signal-driven UI.

## 3. Rules and numbers

Sources: [GAME_SPEC.md](../../../GAME_SPEC.md) §§3, 6, 10, 12 and [ASSETS.md](../../../ASSETS.md).

- COUNTDOWN: 3 seconds; round_number becomes 1.
- RUSH begins at time_left = 120 seconds; FINAL_CALL begins at 20 seconds remaining.
- is_gameplay_active is true only in RUSH and FINAL_CALL.
- At zero, clamp time_left to zero and enter CLOSED immediately. Reject new gameplay events.
- Build RoundResults one frame after CLOSED so checkouts accepted in the last active frame finish first.
- RESULTS lasts 10 seconds. Proposed Demo ending: enter IDLE, retain the result, and wait for an explicit start_match; do not start a second round or claim a best-of-three match ended.
- phase_changed fires once per transition; round_started fires once on entry to RUSH; round_ended fires once with the finalized result.
- Doors track doors_open; animate only the named LeftDoor/RightDoor parts and manage Store-owned collision separately.
- Repeated start_match calls while a round is running do not reset the round. A new match from IDLE resets Store state and calls Cart.reset_for_round for each registered start.

## 4. Interfaces

Existing signatures: [CONTRACTS.md](../../../CONTRACTS.md).

- Implements existing CONTRACTS.md §3 phase/time/doors fields, start_match and is_gameplay_active; emits phase_changed, round_started and round_ended.
- Uses Cart.reset_for_round through CONTRACTS.md §2, never edits cart inventory directly.
- RoundResults carries round_number and finalized banked scores. Multi-round stamps, match winner logic and P-002 sign-off remain Final work; Demo keeps those fields at defaults and is_match_over false.
- Door scene listens to RoundManager state using Store-owned references. No Player audio, UI or driver implementation.

**Contract changes:** None. Any newly discovered need follows §9 before implementation.

## 5. Scenes and files

- systems/store/round_manager.gd: phase machine, timer, deferred result finalization and restart lifecycle.
- systems/store/store.gd and store.tscn: door animation and collision response.
- systems/store/test/round_flow_test.tscn: diagnostic scene using the Store layout.
- tests/store/test_round_flow.gd: timing, signals, restart and close-boundary tests.

## 6. Edge cases

- Large delta values preserve elapsed time and emit crossed transitions exactly once.
- A new start while active is ignored; a restart after IDLE clears pending work from the previous match.
- No gameplay is accepted during countdown, closed, results or idle.
- Pending accepted checkouts finish before result construction; late requests are rejected.
- A round with no carts still reaches results without errors.

## 7. Test plan

- Test exact boundaries at countdown end, 20 seconds, zero and results end; count every phase and round signal.
- Test oversized deltas, duplicate start calls, restart reset and all inactive-phase gameplay gates.
- Test CLOSED persists until the next frame and accepted pending banking precedes round_ended.
- In round_flow_test.tscn watch doors open on GO and close at zero; inspect signal/timer output and the ten-second results hold. Check the actual HUD only after Rickey's integration.

Run the full headless GUT suite after every implementation step. Any SCRIPT ERROR or fewer executed scripts than test files is a failure, even if GUT prints success.

## 8. Out of scope

Best-of-three progression, stamps/tie decisions, match winners, HUD/audio implementation, hazards and Deal of the Day.

## 9. Done when

- [ ] One countdown, 120-second round, final call, deferred close and ten-second results execute once with correct signals and doors; the Demo returns to idle and can be explicitly restarted.
- [ ] Full GUT suite passes with no skipped parse-error scripts.
- [ ] Anthony confirms the Store test-scene hand checks.
- [ ] Anthony's PROGRESS handoff records actual verification and dependencies.
