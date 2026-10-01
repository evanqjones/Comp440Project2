# 11-store-muzak: Brainstorm

| | |
|---|---|
| System | Player / Integration / Assets |
| Owner | Rickey (playback), Anthony (main scene), Evan (recording) |
| Branch | `player/11-store-muzak` |
| Agent | Codex |
| Date | 2026-10-01 |
| Milestone | Final |

## Goal

Use Evan's supplied recording as the store's looping music. Keep it clearly louder while the player is in the store and quieter outside, so crossing the doorway sounds like leaving the music behind.

## Grounding

- `GAME_SPEC.md` §9.3: upbeat supermarket music; it speeds up in the final 20 seconds; web audio starts only after first user input.
- `CONTRACTS.md` §3: `RoundManager.phase_changed(phase)` reports phase transitions.
- `ASSETS.md` §4: music files use Ogg Vorbis; Player owns playback and Evan supplies audio files.
- User request: use `Recording.m4a`, make it quieter outside and louder inside.

## Q&A

1. **Q:** Which music file and inside/outside behavior?
   **A:** Use the supplied `Recording.m4a`; play it as store music, with a quieter outdoor level and a louder indoor level.
2. **Q:** Can this recording be included in a distributed class project?
   **A:** Yes; Evan owns it or has distribution rights. The user approved the draft spec and its proposed values on 2026-10-01.

## Decisions

- Preserve the user-supplied original recording; make a separate Ogg Vorbis game asset because Godot's supported import formats include Ogg Vorbis, MP3 and WAV, not M4A.
- Use a Cart-masked `Area3D` for the existing store interior footprint. Blend between outdoor `-12 dB` and indoor `0 dB` over `0.5 s` so crossing the doorway does not cause an abrupt volume jump.
- Start playback in the first input event, before `TitleFlow` consumes it, to meet the browser audio gesture requirement.
- Use the existing `RoundManager.phase_changed` signal to raise pitch to `1.10` during `FINAL_CALL` (the last 20 seconds) and restore it outside that phase.
- No contract changes.

## Contract changes needed

- None.

## Open questions

- The proposed gain levels and final-call pitch were approved on 2026-10-01.

## Out of scope

- PA announcements, pickup/crash/checkout sound effects, pause-menu music controls, or new audio settings.
- Editing or replacing the supplied `Recording.m4a`.
