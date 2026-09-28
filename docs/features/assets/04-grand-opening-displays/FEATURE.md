# 04-grand-opening-displays: Lite feature

| | |
|---|---|
| System / Owner | Assets / Evan |
| Branch | `assets/04-grand-opening-displays` |
| Agent / Date | Codex / 2026-09-28 |
| Milestone | Final |

## 1. Brainstorm

Goal: make a festive, modular grand-opening entrance kit that Anthony can
instance after the Store scene is ready.

- **Q:** Separate reusable props, or one combined entrance set? **A:** Separate
  props plus a preview that shows them arranged together.

## 2. Spec

- **Behavior:** Static visual decoration for the store's front entrance and
  checkout area. Assets are independently reusable; a test preview composes
  them into a busy but readable grand-opening setup.
- **Art direction:** Follow `GAME_SPEC.md` §1 and the six aisle assets: friendly
  low-poly geometry, bright flat colors, soft bevels, simple materials, no
  real-world retailer branding. Use mesh lettering for short event signage.
- **Assets:**
  - `assets/models/store/banner_visual.tscn`: overhead `GRAND OPENING!` banner
    with a simple support frame and red / yellow pennant trim.
  - `assets/models/store/grand_opening/balloon_bunch_visual.tscn`: reusable
    bunch of eight balloons with simple strings.
  - `assets/models/store/grand_opening/mascot_standee_visual.tscn`: cheerful
    produce mascot cutout.
  - `assets/models/store/grand_opening/shopper_standee_visual.tscn`: generic
    shopper-with-cart cutout.
  - `assets/models/store/grand_opening/promo_display_visual.tscn`: low sale
    table / stacked-product display with a small sale sign.
  - `assets/models/store/cash_register_visual.tscn`: checkout counter with
    conveyor, register screen, and payment terminal.
- **Preview:** `assets/test/grand_opening_store_preview.tscn` uses the playable
  aisle preview as its base. Place one banner, four balloon bunches (32
  balloons total), two different standees, two promotional displays, and two
  cash registers around the front vestibule. Keep the center entrance and cart
  approach visually clear.
- **Scale and geometry:** 1 Godot unit = 1 m, roots at floor contact, forward
  is −Z. Each independently reusable prop stays under the ~2,000-triangle
  visual-asset guideline in `ASSETS.md` §2.
- **Files:** A dedicated `Blender/build_grand_opening.py` generates only its own
  named collection in the existing `Assets.blend`, exports one GLB per prop,
  and leaves the aisle collection untouched. Godot wrappers contain only the
  GLB instance: no scripts, collision, physics bodies, or lights. Update
  `docs/ASSETS.md` and Evan's section of `docs/PROGRESS.md`.
- **Test:** inspect source and exported bounds / triangle counts; import the
  GLBs in Godot; visually run the preview and confirm it has no scene errors;
  run the full GUT suite. Since these are visual-only assets, no gameplay-rule
  GUT tests are needed.
- **Out of scope:** editing Anthony's Store scenes or `main.tscn`, gameplay
  behavior, door animation, collision, audio, and third-party assets.

**Done when:**

- [ ] The six reusable prop scenes match the existing aisle art style and stay
      within the visual mesh budget.
- [ ] The preview shows the complete celebratory entrance arrangement while
      keeping the center cart route readable.
- [ ] Full GUT suite passes headless and the preview runs without Godot errors.
- [ ] Evan's progress and asset manifest document paths and the handoff to
      Anthony; the production Store scene remains untouched.

## 3. Plan

1. Build and export the overhead banner and reusable balloon bunch; add their
   visual-only Godot wrappers. Verify export paths, scale, and triangle counts.
2. Build and export the two standees; add visual-only wrappers and check their
   mesh budgets.
3. Build and export the promotional display and cash register; add wrappers
   and check their mesh budgets.
4. Arrange one full celebration set in the separate playable preview, run it
   in Godot and check framing / entrance clearance, then run the full GUT suite
   and update the asset manifest and progress handoff.

## 4. Checklist

- [x] Sync latest `main` and create `assets/04-grand-opening-displays`.
- [x] Read asset conventions, game art direction, contracts, and current
      handoffs.
- [x] Evan approves this feature spec before any asset implementation (2026-09-28).
- [x] Step 1: banner and balloon bunch.
- [x] Step 2: produce mascot and shopper standees (2026-09-28).
- [x] Step 3: promotional display and cash register (2026-09-28).
- [ ] Step 4: preview composition, verification, and handoff.
- [x] Full GUT suite passes; 25 scripts, 198/198 tests, 1,520 assertions (2026-09-28).
- [ ] Production Store scene remains unchanged; Anthony can instance the
      individual visual scenes later.
