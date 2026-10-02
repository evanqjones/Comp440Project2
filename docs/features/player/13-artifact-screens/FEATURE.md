# 13-artifact-screens: Lite feature

| | |
|---|---|
| System / Owner | Player / Rickey |
| Branch | `player/12-artifact-screens` (from `player/11-fonts`; folder renumbered 13; its PR opened after fonts merged) |
| Agent / Date | Claude Code / 2026-09-30 |
| Milestone | Final polish |

## 1. Brainstorm

- Rickey: "remember the claude artifact, lets match the starting screen and the receipt in the corner and making it a lot more polish". The reference is `docs/reference/shopping_cart_derby.html` on the `artifact` branch, whose Godot port already rebuilt the card in `systems/derby/derby_hud.gd`.
- Rickey picked (2026-09-30):
  - "the receipt in the corner" = the artifact's top-right **"CHECKED OUT" standings panel**;
  - start flow = **artifact card first, then Grandma's story and "Meet your rivals" as matching paper cards**, with OPEN THE DOORS on the last one (this keeps the Final-scope story and intro screens);
  - extra polish: **card animations, artifact HUD panels, Courier Prime receipt text, a blurred/dimmed store behind the cards**.
- Evan's `hud_layout.tscn` and his cart panel stay untouched. Code only fills and decorates his `%` parts and draws its own panels behind them.

## 2. Spec

- **`CardUi`** (`systems/player/ui/card_ui.gd`, static) holds the artifact's look in one place:
  - the palette: paper #F7F3E8, ink #0B2520, tomato #E4412B, mustard #FFC93C, mint #CFE3D6, muted #5E7A71, aisle #123C33, and the HUD panel color rgba(11,37,32,.86);
  - the paper `card()` (radius 14, 24/22 padding, soft 30 px shadow, 648 px wide);
  - `title()` (Bungee 44, tomato), `part()` tiles (white, 4 px colored top border, eyebrow / title / body), and `tag()` chips (swatch, name, Courier price);
  - `key_line()` with Courier key caps;
  - `go_button()` (Bungee, tomato, dark 4 px bottom edge, lighter on hover, 2 px press-down);
  - `hud_panel()`, `eyebrow()` (11 px, spaced, uppercase, mint), `backdrop()` and `pop_in()`.
- **Backdrop** (`CardBackdrop`): one snapshot of the screen, halved to 144 px wide (each bilinear halving averages 2 × 2 pixels) and stretched back, under the artifact's dim #081A16 at 50%.
  - The title takes it after the first frame of the store; the pause menu takes it just before opening.
  - Headless (tests) shows the dim alone.
  - This replaced a per-frame blur shader. While checking that shader the frame counts looked awful (about 7 fps, and a stall with a mipmapped version), but the window was being throttled at the same time, so those numbers aren't conclusive. A one-time snapshot is cheaper either way.
- **Title flow** (`TitleFlow`): same steps, signals and "any key advances" rule; the backdrop sits behind every card; each card **pops in** (fades from 0 and scales 0.94 → 1 over 0.28 s).
  1. **TITLE**, the artifact menu card:
     - eyebrow "Bumper Crop Market · Grand opening weekend" and title "Checkout Chaos";
     - the artifact lede;
     - three parts (The player / The cart / The rivals: Carl, Bev and Rita);
     - a dark "**Inheritance rule:**" box;
     - six aisle tags with `RoundManager.CATEGORY_VALUES` prices and `CartItemStack.COLORS` swatches;
     - keys (W A S D / arrows, Shift / Space boost, Enter; Esc is shown on the pause card so this line fits on one row);
     - a **LET'S SHOP** button.
  2. **STORY:** "Grandma's Card", with her Shopper ID card beside the story lines (the quote in bold tomato) and a **MEET YOUR RIVALS** button.
  3. **RIVALS:** "Meet your rivals", three tiles in each rival's color (color chip, tier, Courier member number and year, blurb), a dark tip box, and **OPEN THE DOORS**, which calls `start_match()`.
- **HUD** (`PlayerHud`):
  - **Standings:** `%ScoreList` holds one dark panel (234 px, right-aligned) with a mint "CHECKED OUT" eyebrow, then one row per cart, most banked first:
    - a 10 px dot in the profile color, the name, "$banked", and a small mint "+$cart" while the cart holds items;
    - "You" in bold.
    - `show_standings(carts)` and `standings_texts()` are exposed for tests.
  - **Timer panel:** a dark rounded panel is drawn behind `%TimerLabel` + `%RoundLabel`, sized to them each frame. `%RoundLabel` reads "ROUND N · GRAND OPENING" as a mint eyebrow.
  - **Minimap, feed and hint:** they use the artifact colors (minimap panel, radius 8; feed/hint pills rgba(11,37,32,.8), radius 6).
- **Receipt** (`RoundReceipt`): the receipt text parts use Courier Prime (bold title).
- **Pause menu:** the same paper card with a tomato "PAUSED". Resume uses `go_button`; Restart and Quit get a white outlined button. Button names and behavior are unchanged.
- **Fonts:** adds Courier Prime Regular/Bold (SIL OFL 1.1, credited in `ASSETS.md` §6) and `PlayerFonts.COURIER` / `COURIER_BOLD`, `rubik(weight)`, `spaced(font, px)`.
- **Camera fix found while checking these screens** (`ChaseCamera`): its spring arm pivots at 2.6 m instead of 1.0 m.
  - With the 1.3× cart, a wall behind you (for example the storefront above the doors) collapsed the arm to the pivot, inside the basket.
  - The resting spot, 8.5 m back and 5.5 m up, is unchanged.
- **Contract changes:** none.

**Done when:**
- [x] GUT covers:
  - the menu card's title, 3 parts, rule, 6 tags with the right prices, Enter key cap and LET'S SHOP;
  - the buttons advancing TITLE → STORY → RIVALS → finished;
  - Grandma's ID card on STORY;
  - three rival tiles and OPEN THE DOORS;
  - a blur backdrop;
  - the card's pop-in ending fully opaque at scale 1;
  - standings rows sorted with "+$cart" only when carrying, "You" bold, and the "CHECKED OUT" eyebrow;
  - the timer panel enclosing the timer;
  - receipt lines in Courier;
  - the pause card keeping its buttons.

  The full suite passes.
- [ ] Screenshots in the full game.
  - Taken with the first blur version: menu, story and rivals cards; the HUD with the CHECKED OUT panel and timer panel; the pause card.
  - Still to take: the snapshot blur, the raised camera at the doors, and the Courier receipt. The window stopped drawing during the last captures.

## 3. Plan

1. Tests → `CardUi` + fonts → title flow → HUD panels → receipt + pause → docs (credits) → suite → screenshots → commit → merge fonts first, then this.
