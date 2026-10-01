# 11-store-muzak: Plan

| | |
|---|---|
| System / Owner | Player / Rickey; Integration / Anthony; Assets / Evan |
| Spec | [01-spec.md](01-spec.md) |
| TODO | [03-todo.md](03-todo.md) |

## 1. Blueprint

- Confirm rights to include the supplied recording, then transcode a copy to Ogg Vorbis without changing the source file.
- Import and configure the Ogg asset to loop.
- Build the Player music controller with the user-input gate, Cart interior zone, smooth level blend, and phase-based pitch.
- Wire the controller into `main.tscn`.
- Add focused tests, run the full suite, and do the Run Project plus Web behavior checks.
- Record asset credit and handoff notes.

## 2. Iterations and steps

### Iteration 1: Music asset and controller

- **Step 1.1:** Add the approved, looping Ogg asset and credit → test that it imports and loops.
- **Step 1.2:** Add controller and interior zone → test start gate, target levels, blend replacement, and final-call pitch.

### Iteration 2: Main-game integration

- **Step 2.1:** Instance controller in `main.tscn` → test first input and gameplay transitions in the running project.
- **Step 2.2:** Run full GUT and Web export/runtime checks; update docs and handoff.

## 3. Prompts

Implementation starts only after `01-spec.md` approval and rights confirmation.

### Prompt 1 (Step 1.1): music asset

```text
Context: Player feature 11-store-muzak. Read AGENTS.md and docs/features/player/11-store-muzak/01-spec.md.
Task: Preserve Recording.m4a and create the approved looping Ogg Vorbis asset at assets/audio/music/store_muzak.ogg; log the confirmed author/license in docs/ASSETS.md.
Files: assets/audio/music/store_muzak.ogg, its import settings, docs/ASSETS.md.
Check: confirm Godot recognizes the resource and the stream loops. Do not alter the source recording.
Finish: summarize asset format, duration and credit entry.
```

### Prompt 2 (Step 1.2): Player music controller

```text
Context: Player feature 11-store-muzak. Read AGENTS.md and docs/features/player/11-store-muzak/01-spec.md.
Task: Add systems/player/store_music.gd with a first-input start, Cart-only interior detection, 0 dB inside / -12 dB outside targets blended over 0.5 s, and 1.10 pitch only during FINAL_CALL.
Files: systems/player/store_music.gd, tests/player/test_store_music.gd.
Test first: cover the gates, target levels, replacement of active blends, pitch phase behavior, and looping stream expectations.
Implement: keep one playback instance alive across transitions; don't add contracts or touch other Player scripts.
Finish: run focused and full GUT, tick the TODO, and report.
```

### Prompt 3 (Step 2.1): integrate and verify

```text
Context: Player feature 11-store-muzak. Read AGENTS.md and docs/features/player/11-store-muzak/01-spec.md.
Task: Instance the music controller into systems/core/main.tscn, verify the full game and Web behavior, and update docs/PROGRESS.md.
Files: systems/core/main.tscn, docs/PROGRESS.md, docs/features/player/11-store-muzak/03-todo.md.
Check: full GUT suite, Run Project title/input/interior/outdoor/final-call behavior, and Web start-after-input behavior.
Finish: report exact checks and any remaining human listening check.
```

## 4. Improvements and bugs

1. PA announcements and gameplay sound effects remain future work.
