# 11-store-muzak: Spec

| | |
|---|---|
| System / Owner | Player / Rickey; Integration / Anthony; Assets / Evan |
| Branch | `player/11-store-muzak` |
| Status | Approved (2026-10-01; recording rights confirmed by Evan) |
| Brainstorm | [00-brainstorm.md](00-brainstorm.md) |
| Milestone | Final |

## 1. Overview

Add the user-supplied recording as looping supermarket music in the full game. It starts on the first user input so it works in Web builds, blends louder when the player's Cart is inside the store, and becomes quieter outside. The current feature also follows the existing game requirement to speed the music up for the final call.

## 2. Player-facing behavior

1. Music is silent on initial page load/title screen.
2. The first key, gamepad button, or mouse button press starts playback immediately; later title/story input continues to work normally.
3. The player hears music at `0 dB` while their Cart is within the store interior zone, and `-12 dB` outside it. The change blends over `0.5 s`.
4. On entering `FINAL_CALL`, music pitch becomes `1.10`; it returns to `1.00` on the next phase transition.
5. The one music stream loops through menus and rounds without restarting on door crossings or phase changes.

## 3. Rules and numbers

| Rule / constant | Value | Source |
|---|---:|---|
| Indoor music level | 0 dB | Draft choice for review |
| Outdoor music level | -12 dB | Draft choice for review |
| Indoor/outdoor blend | 0.5 s | Draft choice for review |
| Normal / final-call pitch | 1.00 / 1.10 | Final-call phase in `GAME_SPEC.md` §3; pitch amount is a draft choice |
| Audio format | Ogg Vorbis, looping | `ASSETS.md` §4; Godot 4.7 supported import formats |
| Indoor zone footprint | Store floor bounds, centered at (0, 0, -5), 50.5 × 30.5 m | `GAME_SPEC.md` §12 |

The indoor zone detects Cart physics bodies (collision layer 2). The music controller keeps one playback instance alive and tweens its volume target on `body_entered` / `body_exited`; a fresh crossing replaces the previous tween. The music controller listens for the existing `RoundManager.phase_changed` signal to adjust pitch.

## 4. Interfaces

**Uses:**

- `CONTRACTS.md` §3: `RoundManager.phase_changed(phase)` for final-call playback speed.
- `CONTRACTS.md` §4: the player's existing Cart is the body observed by the interior zone.

**Provides / emits:** none.

**Contract changes:** None.

## 5. Scenes and files

| Path | New / changed | Purpose |
|---|---|---|
| `assets/audio/music/store_muzak.ogg` | New | Converted loop source; original root `Recording.m4a` stays untouched |
| `assets/audio/music/store_muzak.ogg.import` | New/import-generated | Enables looping Ogg playback |
| `systems/player/store_music.gd` | New | Starts music from first input; blends volume; responds to phase changes |
| `systems/core/main.tscn` | Changed | Instances player-owned music controller (Anthony integration area) |
| `tests/player/test_store_music.gd` | New | Covers volume target, tween replacement, first-input start and final-call pitch |
| `docs/ASSETS.md` | Changed | Records the audio asset and rights-holder/license information |
| `docs/PROGRESS.md` | Changed | Player and Integration handoff |

The music controller owns an `AudioStreamPlayer`, an `Area3D` with a `BoxShape3D` child (masking Cart layer 2), and a tween for volume. The box is centered at `(0, 0, -5)` and matches the store floor bounds. No new shared API is introduced.

## 6. Edge cases

| Case | Expected behavior |
|---|---|
| Initial page load has no input | Music stays stopped for browser autoplay policy |
| First input also advances title UI | Music starts from `_input`; `TitleFlow` still receives/handles it afterward |
| Player Cart starts outside | Outdoor level is used until the Cart enters the zone |
| Cart crosses the boundary repeatedly during a blend | A new target replaces the active tween; volume moves smoothly without stacking tweens |
| Round phase changes during playback | The same music instance continues; pitch is final-call speed only during `FINAL_CALL` |
| Audio rights cannot be confirmed | Do not add/commit the recording; ask for a cleared replacement |

## 7. Test plan

**GUT tests:**

- [ ] Music does not start before input and starts on the first key/button event.
- [ ] Entering/exiting the interior selects the specified volume targets and replaces an active blend.
- [ ] `FINAL_CALL` changes pitch and the next phase restores normal pitch without restarting music.
- [ ] Music stream is looping and the audio zone only detects Cart layer 2.

**Test scene checks:**

- [ ] In Run Project, press a key on the title screen; music starts while the title advances.
- [ ] Drive across the front doorway in both directions; the level blends louder inside and quieter outside.
- [ ] Reach `FINAL_CALL`; music speeds up and returns to normal after the phase ends.
- [ ] Confirm the loop boundary is clean and the browser build starts audio only after user input.

**Integration check:**

- [ ] `main.tscn` instances the Player-owned controller; run the full game and verify the above behavior.

## 8. Out of scope

PA announcements, gameplay sound effects, audio settings, volume sliders, and music ducking for menus.

## 9. Done when

- [ ] Rights to distribute the user-supplied recording are confirmed and logged.
- [ ] The Ogg music asset loops in the game.
- [ ] First-input start, indoor/outdoor blend, and final-call speed follow this spec.
- [ ] GUT suite and Run Project checks pass.
- [ ] Full game remains playable with the music controller wired into `main.tscn`.
- [ ] Progress handoff is recorded.
