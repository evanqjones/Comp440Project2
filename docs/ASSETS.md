# Assets: conventions, manifest, credits

**Owner:** Evan. Everything under `assets/` is Evan's. Other owners **instance** assets and never edit them. If you need a change, add a request to the manifest (§5) or to Evan's "Needs from others" in `PROGRESS.md`.

The asset seam works like the code contracts: agreed **paths**, **node names**, and **conventions** let four people work at once. Renaming a path or a listed node name follows the change protocol in [`CONTRACTS.md`](CONTRACTS.md) §9.

---

## 1. Folder layout

```
assets/
  materials/palette/        ← flat-color StandardMaterial3D .tres files (§3); floor_checker.tres beside it
  models/
    cart/                   ← cart_visual.tscn (+ source .glb)
    items/                  ← produce_visual.tscn … electronics_visual.tscn, deal_visual.tscn
    store/                  ← aisle_shelf_visual.tscn, doors_visual.tscn, checkout_visual.tscn, banner_visual.tscn
    hazards/                ← wet_floor_sign_visual.tscn, pallet_jack_visual.tscn, can_display_visual.tscn
  ui/                       ← hud_layout.tscn, receipt_layout.tscn, id_card_layout.tscn, icons, signage textures
  fonts/
  audio/
    music/  pa/  sfx/
```

Keep Blender `.blend` source files **out of the repo** (they're large binaries); commit the exported `.glb`. If a source file must be shared, link it in the manifest.

## 2. Visual scene convention (the seam)

A **visual scene** is the look of one gameplay object, with no behavior.

1. **Path is fixed from day one.** Every visual in the manifest exists as a **placeholder** (a primitive mesh with a palette material) at its final path. Owners instance that path in their gameplay scene right away, as a child named `Visual`.
2. **Evan upgrades the file in place.** Same path, same root name, same origin and orientation, same listed child names. The owner's scene never changes, so there are no merge conflicts.
3. **Rules for every visual scene:**
   - Root is a `Node3D` named after the object (for example `CartVisual`).
   - **No scripts, no collision shapes, no physics bodies, no lights.** Collision and behavior belong to the owner's gameplay scene.
   - Scale: 1 unit = 1 m. Forward is **−Z** (Godot's forward). Origin at the center of the floor contact.
   - Materials come from `assets/materials/palette/`, flat colors, and no textures except signage.
   - Web budget: under about 2,000 triangles per prop and about 3,000 for the cart. Signage textures 512 px or smaller.
4. **Named children are a contract.** When gameplay code needs to reach a part (to tint it, animate it, or attach something), that part has an agreed name listed in the manifest. Code reaches only those names.

## 3. Palette (starting values; Evan tunes them)

| Material file | Use | Color |
|---|---|---|
| `aisle_produce.tres` | Produce aisle, produce items | Green `#4CAF50` |
| `aisle_bakery.tres` | Bakery | Orange `#FF9800` |
| `aisle_dairy.tres` | Dairy | White `#F5F5F5` |
| `aisle_snacks.tres` | Snacks | Red `#E53935` |
| `aisle_frozen.tres` | Frozen | Blue `#1E88E5` |
| `aisle_electronics.tres` | Electronics | Purple `#8E24AA` |
| `deal_gold.tres` | Deal of the Day (+ emissive beam) | Gold `#E6B422` |
| `cart_player.tres` | Player cart rim, handle, flag | Yellow `#FFE135` |
| `cart_carl.tres` / `cart_bev.tres` / `cart_rita.tres` | Bot carts (`DECISIONS.md` Q-003) | Teal `#00897B` / Pink `#EC407A` / Silver `#B0BEC5` |
| `floor_mint.tres` / `floor_cream.tres` | Checkered linoleum | `#BDEBD3` / `#FFF6E0` |
| `banner_red.tres` / `banner_yellow.tres` | Grand-opening banner | `#D32F2F` / `#FFD600` |

Cart colors must match the `color` in each `ShopperProfile` (`systems/shared/profiles/`). Cart code tints the cart's named parts from the profile, so the profile is the source of truth for cart colors.

## 4. UI layouts and audio

**UI layout scenes** (`assets/ui/*_layout.tscn`) are `Control` scenes with **no scripts**. Every node that code fills in is marked as a **scene unique name** (`%Name`). Rickey's Player code instances the layout and reaches those nodes with `layout.get_node("%TimerLabel")`. The names in the manifest are the contract.

**Audio files** use `.ogg` for music and PA lines (set **Loop** in the Import dock for music) and `.wav` for short sound effects. Rickey's Player code plays them in response to these events:

| Event (signal) | Sound | Path |
|---|---|---|
| Title → first input | Music starts | `audio/music/muzak_loop.ogg` |
| `phase_changed(RUSH)` | PA: doors opening | `audio/pa/doors_open.ogg` |
| `phase_changed(FINAL_CALL)` | PA: final call + music speeds up (`pitch_scale` about 1.15) | `audio/pa/final_call.ogg` |
| `phase_changed(CLOSED)` | PA: store closed | `audio/pa/store_closed.ogg` |
| `deal_spawned` | PA: Deal of the Day | `audio/pa/deal_of_the_day.ogg` |
| `hazard_spawned` | PA: hazard (one per type) | `audio/pa/hazard_wet_floor.ogg`, `hazard_pallet_jack.ogg`, `hazard_display.ogg` |
| `item_collected` | Pickup blip | `audio/sfx/pickup_blip.wav` |
| `cart_robbed` | Crash thud + steal whoosh | `audio/sfx/crash_thud.wav`, `audio/sfx/steal_whoosh.wav` |
| Bounce with no steal (Cart) | Crash thud | `audio/sfx/crash_thud.wav` |
| `checked_out` | Register ding | `audio/sfx/register_ding.wav` |
| Cart moving (Cart) | Squeaky wheel loop, pitch follows speed | `audio/sfx/squeaky_wheel_loop.wav` |
| Countdown (Store phase) | Beeps | `audio/sfx/countdown_beep.wav`, `audio/sfx/countdown_go.wav` |

PA lines can be recorded by the team or made with a text-to-speech tool whose license allows use in a class project. Log the source in §6.

## 5. Manifest

Status: ⬜ not started · 🟫 placeholder at path · 🟨 v1 (usable) · ✅ final. **Owners instance these paths from day one.**

| Asset | Path | For (owner) | Named parts (contract) | Status | Milestone |
|---|---|---|---|---|---|
| Palette materials | `assets/materials/palette/*.tres` | All | — | ⬜ | Demo |
| Cart | `assets/models/cart/cart_visual.tscn` | Cart (Rickey) | `Rim`, `Handle`, `Flag` (MeshInstance3D, tinted by code); `ItemStack`, `NameTag` (Marker3D) | ⬜ | Demo (placeholder), Final |
| Shopper pushing the cart (request from Rickey, 2026-09-24) | `assets/models/shopper/shopper_visual.tscn` | Cart (Rickey) | None required. Root at the feet, facing −Z, ~1.7 m tall, hands forward ~0.35 m at ~1.0–1.2 m high (the cart handle). `cart.tscn` places it 0.95 m behind the cart origin at `Visual/Shopper`. Visual only, no collision. Optional later: an `AnimationPlayer` with a `push_walk` loop that Cart can speed up with the cart's speed. Box placeholder in `cart.tscn` until then. | ⬜ | Final |
| Items ×6 | `assets/models/items/<category>_visual.tscn` (`produce`, `bakery`, `dairy`, `snacks`, `frozen`, `electronics`) | Store (Anthony), Cart (stack) | — | ⬜ | Demo (placeholder), Final |
| Deal of the Day | `assets/models/items/deal_visual.tscn` | Store (Anthony) | `Beam` (MeshInstance3D, emissive, unshaded) | ⬜ | Final |
| Aisle shelf | `assets/models/store/aisle_shelf_visual.tscn` | Store (Anthony) | `Sign` (MeshInstance3D, takes the aisle material) | ⬜ | Demo (placeholder), Final |
| Front doors | `assets/models/store/doors_visual.tscn` | Store (Anthony) | `LeftDoor`, `RightDoor` (Node3D, animated by Store code) | ⬜ | Demo (placeholder), Final |
| Checkout zone | `assets/models/store/checkout_visual.tscn` | Store (Anthony) | — | ⬜ | Demo (placeholder), Final |
| Floor | `assets/materials/floor_checker.tres` | Store (Anthony) | — | ⬜ | Final |
| Grand-opening banner | `assets/models/store/banner_visual.tscn` | Store (Anthony) | — | ⬜ | Final |
| Wet floor sign | `assets/models/hazards/wet_floor_sign_visual.tscn` | Store (Anthony) | — | ⬜ | Final |
| Pallet jack + employee | `assets/models/hazards/pallet_jack_visual.tscn` | Store (Anthony) | — | ⬜ | Final |
| Can display | `assets/models/hazards/can_display_visual.tscn` | Store (Anthony) | `Stack` (Node3D; Store code wobbles and topples it) | ⬜ | Final |
| HUD layout | `assets/ui/hud_layout.tscn` | Player (Rickey) | `%TimerLabel`, `%RoundLabel`, `%ScoreList`, `%CartCountLabel`, `%CartValueLabel`, `%BoostBar`, `%FeedList`, `%Minimap` | ⬜ | Demo (first 5), Final (rest) |
| Round receipt layout | `assets/ui/receipt_layout.tscn` | Player (Rickey) | `%RoundTitle`, `%ReceiptLines`, `%StampRow`, `%Standings` | ⬜ | Demo (plain), Final |
| Shopper ID card layout | `assets/ui/id_card_layout.tscn` | Player (Rickey) | `%Name`, `%Photo`, `%MemberNumber`, `%MemberSince`, `%TierBadge`, `%Barcode`, `%LifetimeSavings`, `%StampRow` | ⬜ | Final |
| Title / story art | `assets/ui/title/…` | Player (Rickey) | — | ⬜ | Final |
| Fonts | `assets/fonts/…` | Player (Rickey) | — | ⬜ | Final |
| Audio (§4 table) | `assets/audio/…` | Player (Rickey) | — | ⬜ | Final |

**Requests:** add a row here (Status ⬜) and ping Evan in `PROGRESS.md` → Assets → "Requests in".

## 6. Credits and licenses

Every third-party asset (model, texture, sound, music, font) gets a row **in the same PR that adds it**. No assets with unclear licenses. Prefer CC0 (for example, Kenney.nl).

| Asset | Path | Author | License | Source URL |
|---|---|---|---|---|
| | | | | |
