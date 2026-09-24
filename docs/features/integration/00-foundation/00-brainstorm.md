# 00-foundation: Brainstorm

| | |
|---|---|
| System | Integration |
| Owner | Anthony (integration owner). Drafted by Rickey |
| Branch | `integration/00-foundation` (stacked on `docs/00-project-specs` until PR #1 merges) |
| Agent | Claude Code |
| Date | 2026-09-23 |
| Milestone | M0 Foundation |

## Goal

Turn `CONTRACTS.md` v0.1 into code everyone can build against tomorrow: the shared data scripts, stub `Cart` / `RoundManager` / `Pickup` with every signal and method, the input map, physics layer names, the `RoundManager` autoload, and GUT, so all four people can work in parallel from Thursday morning.

## Grounding

- `CONTRACTS.md` §1–§6: the exact classes, signatures, input action names, and physics layers to create
- `TODO.md` → M0: the foundation checklist
- `TECH_STACK.md` → Testing: GUT, headless command, `tests/<system>/` layout

## Q&A

1. **Q:** What physics body is `Cart` (Q-006)?
   **A:** `CharacterBody3D` (kinematic) · *why:* exact speed at contact for the steal rule, no physics jitter (the GDD's #2 risk), easy to test deterministically, matches the prototype. Rickey decided as Cart owner.
2. **Q:** Install GUT from the internet and commit it?
   **A:** Yes, GUT **9.7.1** (the release built for Godot 4.7), from github.com/bitwes/Gut tag v9.7.1, MIT license. Keep only `addons/gut/`.
3. **Q:** How much behavior do the stubs get?
   **A:** Contract-complete but behavior-free: every signal, method, and variable exists with typed signatures, and methods return safe defaults. The only real logic is what's trivially defined by the contract (`is_gameplay_active()`, `register_cart()` / `get_carts()`, `get_state()` snapshotting fields). · *why:* the stubs are the owners' own files, which Rickey and Anthony overwrite in their first features, so behavior added here would be throwaway.
4. **Q:** How are `project.godot` settings (input map, layers, autoload, plugin) written?
   **A:** With a one-off headless GDScript that calls `ProjectSettings.set_setting()` + `save()`, not by hand-editing. · *why:* Godot serializes `InputEvent`s correctly; hand-written input entries are error-prone.
5. **Q:** Scene file naming?
   **A:** snake_case (`systems/cart/cart.tscn`), per the Godot style guide. Mixed-case paths break on case-sensitive systems (like web servers). Docs that said `Cart.tscn` are updated.
6. **Q:** Default profile content?
   **A:** Player "You" (Grandma's Platinum card, yellow), Coupon Carl (Gold, teal), Aunt Bev (Platinum, pink), Rolling Rita (Silver, silver), with blurbs from `GAME_SPEC.md` §2.2. Numbers and years are placeholders Rickey can edit in the ID card feature.

## Decisions

- Cart is `CharacterBody3D` → log as D-015, closing Q-006.
- GUT 9.7.1 committed in `addons/gut/`, plugin enabled.
- Stubs are behavior-free (above).
- A **contract conformance test** checks that every contract signal and method exists on the stubs, so a later change that drops one fails the suite.

## Contract changes needed

- None. This implements v0.1 as written. (File name `cart.tscn` is a naming fix, not a signature change.)

## Open questions

- None blocking.

## Out of scope

- Any real cart movement, inventory, round flow, spawning, bot logic, HUD (those are Demo features)
- Changes to `systems/core/main.tscn` (Anthony wires it at Checkpoint 1)
- Asset placeholders (Evan's `assets/01-placeholders`); the Cart stub uses a temporary box mesh as its `Visual`
