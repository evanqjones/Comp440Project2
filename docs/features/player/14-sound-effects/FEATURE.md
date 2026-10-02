# 14-sound-effects: Lite feature

| | |
|---|---|
| System / Owner | Player (audio playback) / Rickey |
| Branch | `player/14-sound-effects` (from `main`) |
| Agent / Date | Claude Code / 2026-10-02 |
| Milestone | Final: "Audio: sound effects" (GAME_SPEC.md §9.3, §10) |

## 1. Brainstorm

- Apart from Evan's store music (`StoreMusic`) the game is silent, and there are no sound-effect or PA files in `assets/audio/`.
- Earlier choice (2026-09-30), "Synth now, swap later":
  - reuse the Shopping Cart Derby artifact's synthesized sounds, which the `artifact` branch already ported as `DerbySfx`;
  - use Evan's file instead whenever one exists at its `ASSETS.md` §4 path.
- Only the player's own events make sounds (pickups, steals, checkouts, wheels), so four carts don't turn into noise. Round events (countdown, chimes, deal, hazard) play for everyone.

## 2. Spec

- **`PlayerAudio`** (`systems/player/audio/player_audio.gd`) is created by `PlayerFeedback` (its child), so `main.tscn`/`main.gd` don't change. It has `cart` = the player's cart.
- **Sounds:** each one is Evan's file if `ResourceLoader.exists(path)`, otherwise rendered once from oscillator tones (`render()`, from the artifact port):

  | Event | Sound | File it prefers |
  |---|---|---|
  | player's `item_collected` | `pickup` (blip) | `sfx/pickup_blip.wav` |
  | player in a `cart_robbed`, either side | `crash` (thud) | `sfx/crash_thud.wav` |
  | player inherited | + `steal` (whoosh up) | `sfx/steal_whoosh.wav` |
  | player robbed | + `robbed` (falling buzz) | (none) |
  | player's `checked_out` | `checkout` (register ding-ding) | `sfx/register_ding.wav` |
  | player's `cart_full` | `cart_full` (low double beep) | (none) |
  | `COUNTDOWN` | `beep` at 3, 2, 1 | `sfx/countdown_beep.wav` |
  | `RUSH` | `go` + `doors_open` chime | `sfx/countdown_go.wav`, `pa/doors_open.ogg` |
  | `FINAL_CALL` | `final_call` chime | `pa/final_call.ogg` |
  | `CLOSED` | `store_closed` chime | `pa/store_closed.ogg` |
  | `deal_spawned` | `deal` jingle | `pa/deal_of_the_day.ogg` |
  | `hazard_spawned` | `hazard` alert | `pa/hazard_wet_floor.ogg` |
  | player moving (`RUSH`/`FINAL_CALL`) | `wheel` squeak loop | `sfx/squeaky_wheel_loop.wav` |

- **Wheel loop:** the pitch goes 0.8 → 1.6 and the volume −28 → −14 dB as speed goes 0 → 15 m/s. It's silent below 0.5 m/s and outside gameplay.
- **Playback:** a pool of 8 `AudioStreamPlayer`s. Web audio starts after the title's first key press (Godot's web export resumes audio on the first input).
- `played` keeps the most recent sound names, for tests.
- **Contract changes:** none. It listens to existing signals.

**Done when:**
- [x] GUT (38 scripts, 274/274):
  - every sound renders non-silent audio, and the wheel loops;
  - Evan's file wins when present;
  - player-only pickup, checkout and steal sounds;
  - countdown beeps and the round chimes;
  - wheel pitch and volume follow speed and go quiet when stopped.

  The full suite passes.
- [ ] The full game runs with no audio errors (headless) and the web export boots.

## 3. Plan

1. Tests → `PlayerAudio` → created by `PlayerFeedback` → suite → run → commit → re-export `docs/` → push, PR, merge.
