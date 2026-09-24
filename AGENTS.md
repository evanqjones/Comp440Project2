# Agent instructions: Checkout Chaos

This is the **canonical** instruction file for every AI agent on this repo. Codex reads it directly. `CLAUDE.md` and `GEMINI.md` import it. Edit rules **here**, never in those wrappers.

**The project:** *Checkout Chaos*, a 3D shopping-cart racer in Godot 4.7.2 (GDScript, web export). One human and three bots grab groceries, ram each other to **inherit** hauls, and check out. It's a four-person class project (COMP 440): four code systems plus an assets role, with one shared set of contracts.

| Area | Owner | Folder |
|---|---|---|
| Player (input, camera, HUD, screens, audio playback) | Rickey | `systems/player/` |
| Cart (movement, inventory, ram-steal) | Rickey | `systems/cart/` |
| Rivals (bot AI) | John | `systems/rivals/` |
| Store / Round Manager (+ integration: `main.tscn`, `project.godot`) | Anthony | `systems/store/`, `systems/core/` |
| Assets (models, materials, UI layouts, audio files) | Evan | `assets/` (see `docs/ASSETS.md`) |

**Deadlines:** Demo (one full round) **Fri 2026-09-25**. Final **Fri 2026-10-02**.

---

## Rule 0: Pull before anything new

Before starting any new feature, spec, or task, sync with the repo:

```bash
git checkout main && git pull --ff-only
```

Then create the feature branch. When resuming an existing branch, run `git pull` and then `git merge origin/main` before working. Never start new work from a stale `main`.

## Rule 1: Read before you act (every session)

Read these, in order:
1. [`docs/PROGRESS.md`](docs/PROGRESS.md): what's on `main`, each system's status, **handoff notes** from other agents.
2. [`docs/CONTRACTS.md`](docs/CONTRACTS.md): the exact interfaces between systems.
3. The relevant section of [`docs/GAME_SPEC.md`](docs/GAME_SPEC.md): rules and numbers.
4. The current feature folder, `docs/features/<system>/<NN-slug>/`, especially `03-todo.md` (or `FEATURE.md`).

Reference as needed: [`docs/WORKFLOW.md`](docs/WORKFLOW.md) (the process and prompts), [`docs/TECH_STACK.md`](docs/TECH_STACK.md) (tools and commands), [`docs/ASSETS.md`](docs/ASSETS.md) (asset paths, named parts, audio events), [`docs/DECISIONS.md`](docs/DECISIONS.md) (why things are the way they are), [`docs/TODO.md`](docs/TODO.md) (the backlog), [`docs/TEAM.md`](docs/TEAM.md) (ownership, review pairs, checkpoints).

## Rule 2: Know whose system you're in

- If it isn't clear which teammate you're working for, **ask** before editing.
- Edit only that owner's folders: `systems/<system>/`, `tests/<system>/`, `docs/features/<system>/`, and **their own section** of `docs/PROGRESS.md`. Rickey owns two systems (Player and Cart), so both sets of folders and both sections are his.
- Never edit another owner's scenes or scripts. Instance their scenes, call their public methods, and connect to their signals.
- **Assets are Evan's.** Other owners instance `assets/` paths from day one (as a `Visual` child, or a UI layout) and touch only the **named parts** listed in `docs/ASSETS.md`. Never edit files in `assets/` unless you're working for Evan. To ask for an asset, add a row to the `ASSETS.md` manifest. When working for Evan, follow the visual scene rules in `ASSETS.md` §2: no scripts, collision or lights, keep the path and named parts, and log licenses in §6.
- `systems/core/main.tscn`, `project.godot` and `export_presets.cfg` belong to Anthony (integration owner). Anyone else proposes the change to Anthony.

## Rule 3: Contracts are frozen

- Don't change `docs/CONTRACTS.md` or anything in `systems/shared/` except through the change protocol (`CONTRACTS.md` §9): propose → `DECISIONS.md` entry → sign-off → one `integration/` PR.
- If your task seems to need a contract change, **stop and tell the human**. Never change a signature silently to make your code compile.
- Respect the invariants in `CONTRACTS.md` §8, especially item conservation and "one steal per contact".

## Rule 4: Follow the workflow (spec before code)

Every feature: branch → brainstorm → spec → plan → TODO → build → verify → PR, as described in `docs/WORKFLOW.md`.
- **Don't write feature code before `01-spec.md` and `02-plan.md` exist** (or the Lite `FEATURE.md` equivalent) and the human has approved the spec.
- When brainstorming, ask **one question at a time**, multiple choice with your recommendation first, grounded in `GAME_SPEC.md`.
- Build **one plan step at a time**: test first, implement, run the suite, tick `03-todo.md`, commit, stop and report.
- Branch names: `<system>/<NN>-<slug>`. Commits: `<system>: <what changed>`.

## Rule 5: Test before claiming done

- Write the GUT test first for any rule or number (steal rule, cap, slowdown, scoring, phases, bot target scoring).
- Run the **full** suite headless before you say a step works:
  ```bash
  godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
  ```
  (On macOS, `godot` is `/Applications/Godot.app/Contents/MacOS/Godot`. See `TECH_STACK.md`. GUT is installed by `integration/00-foundation`. Until that's merged, say that tests can't run yet instead of skipping silently.)
- Report the real result. If tests fail, say so and show the failure. Never claim success you didn't see.
- Feel and visuals need the human to check in the system's test scene (`systems/<system>/test/`). Tell them exactly what to try.

## Rule 6: Leave a trail for the next agent

The other agents don't share your memory. They share the repo.
- At the end of every session (or when asked), update **your owner's section** of `docs/PROGRESS.md`: Status, Updated (date + your agent name), Done, In progress, Next, Needs from others, **Handoff notes**.
- Put anything another system's agent must know in **Handoff notes** (signal timing, units, a helper they can call, a known bug).
- Log decisions others might question in `docs/DECISIONS.md` (append, never rewrite).
- If you change a tuning number, update the tuning table in `GAME_SPEC.md` §12 in the same commit.

## Rule 7: Godot 4.7 and GDScript

- **Godot 4 syntax only.** `@export`, `@onready`, `await`, `CharacterBody3D`, `Node3D`, `instantiate()`, `signal.connect(callable)`, `signal.emit()`. No Godot 3 forms. If unsure, check the Godot 4.7 docs before writing engine code.
- **Static typing everywhere:** typed variables, parameters, returns, `Array[ItemData]`, `Dictionary[int, int]`.
- **Signals and public methods across systems.** No `get_node("../../OtherSystem/...")` into someone else's scene.
- **Web limits:** Compatibility renderer (no Forward+ features, few dynamic lights); **no threads**; audio starts only after the first user input.
- Keep scenes, scripts and assets for a system together in its folder. Tabs for indentation in `.gd` (`.editorconfig`).
- Don't name anything `round`: it shadows the built-in `round()`. Use `round_number`.
- The team is new to Godot. Briefly explain engine terms the first time you use them in a session.

## Ask first

- Deleting or renaming files
- Installing an addon, plugin, or asset pack
- Changing `project.godot`, `export_presets.cfg`, or `main.tscn` (Anthony's)
- Any contract change
- `git push`, opening or merging PRs

## Never

- Commit `.godot/`, `builds/`, credentials, or personal editor state
- Add features that aren't in the approved spec (log ideas in the plan's "Improvements and bugs" or `TODO.md` Stretch instead)
- Edit another owner's section of `PROGRESS.md` or their system's files
- Skip Rule 0 or Rule 5

## Agent-specific notes

- **Codex:** your sandbox may block running Godot. Request approval for the headless GUT command rather than skipping tests.
- **Claude Code:** see `CLAUDE.md`.
- **Gemini CLI:** see `GEMINI.md`.
