# 04-final-rounds: Spec

| | |
|---|---|
| System / Owner | Store / Anthony |
| Branch | `store/04-final-rounds` |
| Status | Approved (2026-09-30) |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Final |

## 1. Overview

This feature completes Store's Final scope. RoundManager retains its current checkout, score, and pickup behavior while accumulating scores and stamps across three rounds. It also creates the Deal of the Day. Store hazards were removed from this feature and reassigned to Evan. It does not alter frozen contracts or write Cart-owned state directly.

## 2. Player-facing behavior

After a 10-second receipt, rounds one and two reset every cart empty at its start and enter the next 3-second countdown. At the end of round three, the receipt receives cumulative stamps and standings, then the game remains in `MATCH_OVER` for the Player match-results flow.

During RUSH and FINAL_CALL, a gold $100 Deal appears at a random aisle spawn location 14–22 seconds after the previous Deal is collected. Its Store fallback has an emissive gold material, a beam, and a floating `DEAL OF THE DAY!` marker until Evan supplies the final Deal visual. It causes `deal_spawned` so Player audio and Rivals react.

## 3. Rules and numbers

| Rule / constant | Value | Source |
|---|---:|---|
| Rounds per match | 3 | `GAME_SPEC.md` §3.2 |
| Results duration | 10 s | `GAME_SPEC.md` §3.1 |
| Deal value / floor count | $100 / 1 | `GAME_SPEC.md` §6 |
| Deal interval | random 14–22 s | `GAME_SPEC.md` §6 |

- Every registered cart has zero entries by default in match-bank and stamp maps.
- At `CLOSED`, existing deferred checkouts drain before results are built. The highest positive `banked` total wins a round; tied highest totals all win; a zero-only round grants no stamp.
- Results include snapshot copies of `banked`, cumulative `stamps`, and cumulative `match_banked`. On round 3 they set `is_match_over` and `match_winner_ids` using stamps then cumulative banked, retaining exact ties.
- A Deal is a normal `Pickup` with `GameTypes.Category.DEAL`, value 100, and an ordinary unique ID. Its collection deregisters it before a new Deal timer starts. A spilled Deal remains the live Deal until collected.

## 4. Interfaces

**Uses** (from other systems):

- `CONTRACTS.md` §2: `Cart.reset_for_round`, `Cart.cart_robbed`, and Cart item methods through existing Store pickup/checkout paths.
- `CONTRACTS.md` §3: `RoundResults`, `RoundManager.get_match_banked`, and `RoundManager.get_stamps`.
- `CONTRACTS.md` §3: `deal_spawned(pickup)` is emitted by its existing signature.

**Provides / emits:** complete `RoundResults` snapshots, `deal_spawned` once per live Deal, and `MATCH_OVER` after the third result duration.

**Contract changes:** None.

## 5. Scenes and files

| Path | New / changed | Purpose |
|---|---|---|
| `systems/store/round_manager.gd` | Changed | Match progression and Deal timer |
| `systems/store/pickup.gd` / `pickup.tscn` | Changed | Deal visual and lifecycle callback |
| `systems/store/store.gd` / `store.tscn` | Changed | Deal spawn-marker references and final Asset scene instances when available |
| `systems/store/test/final_rounds_test.tscn` | New | Inspect the Deal presentation |
| `tests/store/test_final_rounds.gd` | New | GUT tests for match and Deal rules |

Final visual references use only manifest paths once Evan supplies them. Store test placeholders remain in Store-owned scenes until then.

## 6. Edge cases

| Case | Expected behavior |
|---|---|
| No cart checks out in a round | No stamps; results still advance |
| Tied positive round bank | Every tied cart gains one stamp |
| Tied stamps after round 3 | Highest cumulative bank decides; exact remaining tie shares match victory |
| Restart during result/deferred work | Generation guards discard stale Deal, checkout, and result work |
| Deal spills in a steal | It remains a $100 `DEAL` pickup with its same ID; no replacement spawns until collected |
| Round closes with a Deal active | Clear the Deal and timer before the next countdown; no post-close spawn |

## 7. Test plan

**GUT tests** (headless, automated):

- [ ] Three-round progression, reset, stamps, all tie cases, snapshots, and `MATCH_OVER`.
- [ ] Deal timing, separate cap, identity/value preservation through spill, and one live Deal.
- [ ] Real Cart ↔ Store 20-into-8 acceptance: identities/value, immunity, checkout boundary, and close boundary; Deal spill included.

**Test scene checks** (by hand):

- [ ] In `systems/store/test/final_rounds_test.tscn`, inspect Deal placement, gold beam, and floating marker.
- [ ] In Run Project, play three rounds: bank to see stamps, verify reset/countdown, observe match results, and collect or spill a Deal.

**Integration check:** Anthony wires Store nodes in `main.tscn`; John consumes the Deal signal, and Evan supplies the final Deal visual and owns hazards separately. Build and test the web export through a local server after the full match passes.

## 8. Out of scope

- Cart slip motion, Player UI/audio behavior, Rival navigation reactions, Asset-authoring work, and Evan-owned hazards.
- Stretch closures and perks.

## 9. Done when

- [ ] Three playable rounds produce correct stamps and match winners, then remain in `MATCH_OVER`.
- [ ] Deals meet their timing, identity, cleanup, signal, gold-beam, and floating-marker rules.
- [ ] The real-cart conservation acceptance test covers a spilled Deal.
- [ ] Final Store art is instanced when Evan's manifest paths are available.
- [ ] Full GUT suite passes headless without script errors.
- [ ] Test-scene and full-game hand checks are confirmed by Anthony.
- [ ] The web export runs through a local server.
