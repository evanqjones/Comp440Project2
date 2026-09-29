# 06-cart-capacity-ui: Feature

| | |
|---|---|
| Owner | Evan (HUD art layout) |
| Branch | `assets/06-cart-capacity-ui` |
| Status | Approved by Evan's direct request (2026-09-29) |

## Spec

Give the player's cart capacity and carried money a playful, easy-to-read
checkout display at the bottom center of the game HUD. Use a warm grocery
receipt palette with a friendly basket illustration for item count and a bright
price-tag/coin illustration for cart value. Keep the dynamic `%CartCountLabel`,
`%CartValueLabel`, and `%BoostBar` names and expected node types so PlayerHud
continues to supply live values. The scene stays script-free and gameplay code
is unchanged.

## Plan

1. Add original small vector icons for the basket and money total.
2. Create `assets/ui/hud_layout.tscn` with a responsive bottom-center checkout
   panel, capacity and money cards, and the existing boost bar.
3. Keep every HUD scene-unique name required by ASSETS §4 with the expected
   types; keep other HUD regions positioned as before.
4. Open the running game and inspect the panel at play resolution. Update the
   asset manifest and Evan's progress notes.

## TODO

- [x] Synced main and created the asset feature branch.
- [x] Spec approved by Evan's direct request.
- [x] Create original basket and money icons.
- [x] Create the responsive HUD layout and preserve contract names/types.
- [x] Inspect the running HUD and record the handoff.
- [ ] Commit the feature branch.
