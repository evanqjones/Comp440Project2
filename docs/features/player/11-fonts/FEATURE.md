# 11-fonts: Lite feature

| | |
|---|---|
| System / Owner | Player / Rickey (+ `project.godot` default font, approved exception) |
| Branch | `player/11-fonts` (from `main`) |
| Agent / Date | Claude Code / 2026-09-30 |
| Milestone | Final polish |

## 1. Brainstorm

- Rickey: "can we have cooler fonts". He picked (2026-09-30):
  - **Bungee + Rubik**, the Shopping Cart Derby artifact's pair (both SIL OFL 1.1, already downloaded for the `artifact` branch);
  - **everywhere**, meaning the game's default font set in `project.godot` (Anthony's file; Rickey approved the change as an exception).
- Bungee is very wide, so it's only for big display text. Three bot name tags side by side at the 2 m-apart start line need something narrower: Rubik Bold.

## 2. Spec

- **Files** (`systems/player/fonts/`):
  - `Bungee-Regular.ttf` and `Rubik-Variable.ttf`, plus their `OFL-*.txt` licenses;
  - `ui_font.tres` (Rubik, `wght` 500) and `ui_font_bold.tres` (Rubik, `wght` 700).
- **Default:** `project.godot` → `[gui] theme/custom_font = ui_font.tres`. Every Control without its own font now uses Rubik Medium: HUD lines, feed, scoreboard, receipt, ID cards, pause buttons, and Evan's panel captions.
- **`PlayerFonts`** (`systems/player/player_fonts.gd`) has `DISPLAY` (Bungee), `UI`, `BOLD`, `UI_PATH`, and `display(control)`.
- **Bungee is used for:**
  - the HUD timer (`%TimerLabel`, set from code; Evan's file is untouched);
  - the 3-2-1-GO countdown, the popups (now 40 px, since Bungee runs wider) and the CHECK OUT tag;
  - the "+$N" pops (`Label3D.font`);
  - title-flow headings of 44 px or more (store name, "Meet your rivals");
  - "PAUSED".
- **Rubik Bold** is used for the cart name tags (`CartNameTag`).
- **Credits:** two rows in `ASSETS.md` §6. **Decision:** D-032.

**Done when:**
- [x] GUT:
  - the project default font is the Rubik Medium variation;
  - `DISPLAY` is Bungee and `BOLD` is Rubik 700;
  - the licenses ship;
  - HUD timer, countdown, popup and pop use Bungee while feed lines don't;
  - name tags use Rubik Bold;
  - the title store name and "PAUSED" use Bungee.

  The full suite passes.
- [x] Seen in the full game (1152 × 648): the title (Bungee store name, Rubik card), "Meet your rivals", and the HUD (Bungee timer, popup and "+$" pops; Rubik feed, scoreboard and panel).

## 3. Plan

1. Tests → fonts + `PlayerFonts` + `project.godot` + call sites → credits, decision → suite → screenshots → commit → ask to push / PR / merge.
