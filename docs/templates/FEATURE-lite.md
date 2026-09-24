# <NN-slug>: Lite feature

| | |
|---|---|
| System / Owner | <System> / <name> |
| Branch | `<system>/<NN>-<slug>` |
| Agent / Date | <agent> / <YYYY-MM-DD> |
| Milestone | <Demo / Final / Stretch> |

Use Lite only if this stays inside your system and nobody else consumes it (see `WORKFLOW.md`).

## 1. Brainstorm

Goal: <one sentence>

- **Q:** <question> **A:** <answer>
- **Q:** … **A:** …

## 2. Spec

- **Behavior:** <what the player sees, hears, and feels>
- **Numbers:** <values, with the `GAME_SPEC.md` section they come from>
- **Uses:** <contract signals and methods read; no contract changes allowed in Lite>
- **Files:** <paths>
- **Edge cases:** <list>
- **Out of scope:** <list>

**Done when:**
- [ ] <observable criterion>
- [ ] Full GUT suite passes headless (plus new tests if there's logic to test)
- [ ] Owner checked it in the test scene

## 3. Plan

1. <small step> → test: <what>
2. <small step> → test: <what>

<Add a fenced prompt under a step only if the step isn't obvious.>

## 4. Checklist

- [ ] Branch created from a fresh `main`; `PROGRESS.md` updated
- [ ] Step 1
- [ ] Step 2
- [ ] Verified (tests + test scene)
- [ ] PR opened, reviewed, merged
- [ ] `PROGRESS.md` and `TODO.md` updated
