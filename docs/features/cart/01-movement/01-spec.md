# 01-movement: Spec

| | |
|---|---|
| System / Owner | Cart / Rickey |
| Branch | `cart/01-movement` |
| Status | Not started (brainstorm next) |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Demo (merge by Thu 09-24 noon) |

## 1. Overview

<What this feature is, in 3–5 sentences, and where it sits in the game loop.>

## 2. Player-facing behavior

<What the player sees, hears, and feels, step by step. Include timings.>

## 3. Rules and numbers

| Rule / constant | Value | Source |
|---|---|---|
| <e.g. item cap> | <24> | `GAME_SPEC.md` §12 |

<Formulas, state machines, and decision rules in plain words or pseudocode.>

## 4. Interfaces

**Uses** (from other systems; link, don't redefine):
- `CONTRACTS.md` §<n>: `<signal / method>`: <how this feature uses it>

**Provides / emits:**
- `<signal / method>`: <when, with what values>

**Contract changes:** <None, or the proposed change + `DECISIONS.md` entry ID. Don't build until approved.>

## 5. Scenes and files

| Path | New / changed | Purpose |
|---|---|---|
| `systems/<system>/<file>.gd` | New | <…> |
| `systems/<system>/test/<name>_test.tscn` | New | Test scene with fake inputs |
| `tests/<system>/test_<thing>.gd` | New | GUT tests |

<Node tree sketch for any new scene.>

## 6. Edge cases

| Case | Expected behavior |
|---|---|
| <e.g. two carts touch at equal speed> | <both bounce, nothing transfers> |

## 7. Test plan

**GUT tests** (headless, automated):
- [ ] `test_<name>`: <given / when / then>

**Test scene checks** (by hand; feel and visuals):
- [ ] <what to do in the test scene and what you should see>

**Integration check** (once merged into `main.tscn`, if relevant):
- [ ] <what to try in the full game>

## 8. Out of scope

- <What this feature won't do>

## 9. Done when

- [ ] <Acceptance criterion, observable and testable>
- [ ] Full GUT suite passes headless
- [ ] Test scene checks confirmed by the owner
- [ ] `PROGRESS.md` handoff notes written for any system that consumes this
