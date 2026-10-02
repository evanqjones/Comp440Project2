# 06-deal-of-the-day: Lite feature

| | |
|---|---|
| System / Owner | Store (Anthony's; built by Rickey as an approved exception, D-035) + Rivals one-line fix + Player HUD |
| Branch | `store/06-deal-of-the-day` (from `main`) |
| Agent / Date | Claude Code / 2026-10-02 |
| Milestone | Final: "Deal of the Day" (GAME_SPEC.md §6, §10) |

## 1. Brainstorm

- **Rules** (`GAME_SPEC.md` §6, §9.1, §5.2):
  - a gold **$100** item with a **light beam**;
  - **one on the floor at a time**, spawning **14–22 s** (random) after the previous one leaves the floor;
  - separate from the 46-item cap;
  - announced on the PA;
  - a spilled deal stays gold and keeps $100;
  - the beam is an unshaded mesh, not a real light (web).
- **Already in place:**
  - `GameTypes.Category.DEAL` and `ItemData.is_deal`;
  - Pickup's gold placeholder color (index 6);
  - `CartItemStack.color_for()` makes deals gold in baskets;
  - spills keep the same `ItemData`;
  - `RoundManager.deal_spawned(pickup: Pickup)` (contract);
  - `player/14-sound-effects` plays a jingle on it.
- **A bug in waiting:** `BotController._on_deal_spawned(_deal_item: ItemData)` doesn't match the contract's `Pickup` argument, so every bot would error on the first deal. The fix is a one-word type change in John's file (exception, D-035).
- **Bots:** they already score pickups by value ÷ distance and re-decide on `deal_spawned`, so a $100 item pulls them in.

## 2. Spec

- **`RoundManager`:**
  - `DEAL_VALUE = 100`, with a delay between `DEAL_DELAY_MIN = 14.0` and `DEAL_DELAY_MAX = 22.0`.
  - Each round's `RUSH` draws a delay. The timer counts only during RUSH and FINAL_CALL, and only while no deal is on the floor.
  - At 0 it spawns a deal in a random aisle (`ItemData`: DEAL, $100, `is_deal`, the next match-unique id), emits `deal_spawned(pickup)`, and draws the next delay.
  - Floor clears between rounds remove it.
- **`Store.spawn_pickup(item, aisle_index = -1)`:** −1 keeps the category's aisle; a deal passes a random aisle.
- **`Pickup`:**
  - a deal shows the gold placeholder plus a **Beam**: an unshaded, additive, see-through gold cylinder about 14 m tall, with no shadow and no light;
  - the gold box slowly spins.
- **`BotController._on_deal_spawned(_deal: Pickup)`:** a type fix only.
- **Player HUD:**
  - on `deal_spawned`, a gold popup "DEAL OF THE DAY! $100" and a feed line "Deal of the Day: $100 on the floor";
  - the minimap draws a gold dot at any deal on the floor.
- **Contract changes:** none. It uses the existing signal, category and fields.

**Done when:**
- [x] GUT (38 scripts, 273/273):
  - the first deal comes 14–22 s into a round, at $100, gold, and with `deal_spawned` emitted;
  - only one is on the floor however long you wait;
  - the next one comes 14–22 s after it's collected;
  - the deal visual has a Beam;
  - the bot handler accepts a `Pickup`;
  - the HUD popup and feed line, and the minimap's deal dot.

  The full suite passes.
- [x] Full game (editor run):
  - the first deal appeared 17.5 s into round 1, and Coupon Carl grabbed it within 3 s;
  - the next came 16 s later;
  - a screenshot shows the gold box and beam, the "DEAL OF THE DAY! $100" popup, and the feed line.

## 3. Plan

1. Tests → RoundManager + Store + Pickup → bot type fix → HUD/minimap → suite → full-game check → D-035 → commit → re-export → push, PR, merge.
