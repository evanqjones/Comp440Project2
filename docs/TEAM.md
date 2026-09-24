# Team, ownership, and shared rules

Ownership follows `DECISIONS.md` D-012 (which supersedes the team GDD's split).

| Area | Owner | Owned files | Interface crossing the boundary |
| --- | --- | --- | --- |
| **Player** | Rickey | `systems/player/`, `tests/player/`, `docs/features/player/` | Produces `DriveCommand`; reads `CartState` and `RoundManager` for the HUD; fills Evan's UI layouts; plays Evan's audio |
| **Cart** | Rickey | `systems/cart/`, `tests/cart/`, `docs/features/cart/` | Consumes `DriveCommand`; emits `item_collected`, `cart_robbed`, `cart_full`; provides `try_add_item`, `take_all_items`, `get_state` |
| **Rivals** | John | `systems/rivals/`, `tests/rivals/`, `docs/features/rivals/` | Produces `DriveCommand`; reads pickups, carts, and time from `RoundManager` |
| **Store / Round Manager** | Anthony | `systems/store/`, `tests/store/`, `docs/features/store/` | `RoundManager` autoload: phases, timer, pickups, checkout, spills, scoring; emits round, checkout, and hazard signals |
| **Integration** | Anthony | `systems/core/` (`main.tscn`), `project.godot`, `export_presets.cfg`, `docs/features/integration/` | Wires everything together in `main.tscn`; input map, autoloads, physics layers; web export |
| **Assets** | Evan | `assets/`, `docs/ASSETS.md`, `docs/features/assets/` | Visual scenes, palette materials, UI layouts, and audio at fixed paths with named parts (`ASSETS.md`) |
| **Shared contracts** | All (change protocol) | `systems/shared/`, `tests/shared/`, `docs/CONTRACTS.md` | See `CONTRACTS.md` |

Exact signatures: [`CONTRACTS.md`](CONTRACTS.md). Asset seam: [`ASSETS.md`](ASSETS.md). How to work: [`WORKFLOW.md`](WORKFLOW.md).

## How we work separately but build one game

1. **Nobody waits on anyone's real code.** Contracts exist as code from the foundation feature, with stub `Cart` and `RoundManager` scripts. Build against the stub; the real code later replaces it behind the same interface.
2. **Everyone tests alone with fakes.** Each area has its own test scenes (`systems/<system>/test/`, or an asset preview scene in `assets/`).
3. **Merge small and often.** A small PR merged at noon beats a big one at midnight. Everyone pulls `main` before starting anything new.
4. **Integrate at fixed checkpoints.** Everyone merges what's ready, Anthony assembles `main.tscn`, and the team plays it together:
   - **Checkpoint 1:** Thu 09-24, 6 pm. Drivable cart + one solo round in `main`.
   - **Checkpoint 2:** Fri 09-25, 9 am. Bots in, steal check, then the demo.
   - **Final week:** a checkpoint each evening (Sat 09-26 to Thu 10-01) at a time the team agrees. Code freeze Thu 10-01 night.
5. **Talk through the repo.** `PROGRESS.md` handoff notes and "Needs from others", `DECISIONS.md`, and asset requests in the `ASSETS.md` manifest. Use the group chat for anything urgent, then write it down.

## Review pairs (who reviews whose PRs)

Pairs follow the seams, so each reviewer is the person whose code depends on the change.

| Author | Area | Reviewer | Why |
|---|---|---|---|
| Rickey | Cart | Anthony | `cart_robbed` → spills and checkout are Store's side of the seam |
| Rickey | Player | Evan | HUD and screens use Evan's layouts and audio |
| Anthony | Store / Integration | Rickey | Store calls into Cart; `main.tscn` wires Rickey's scenes |
| John | Rivals | Rickey | Bots drive the Cart |
| Evan | Assets | The owner of the object (see the `ASSETS.md` manifest) | They instance it |

Before the demo, a quick review in the group chat is enough. Anything touching `project.godot`, `export_presets.cfg`, or `main.tscn` is merged by Anthony.

## Shared rules

- **Pull before starting anything new** (`git checkout main && git pull --ff-only`), then branch.
- **One owner edits a `.tscn` scene at a time.** Instance another owner's scene instead of copying it or editing its internals.
- **Signals, public methods, and named parts only.** Don't reach into another scene's node tree.
- **Contracts (and asset paths and named parts) change only through the change protocol** (`CONTRACTS.md` §9).
- **Shared settings go through Anthony:** input actions, autoloads, physics layers, `main.tscn`, export presets.
- **Each PR lists** the interfaces it touched and how to run its test scene. Pull the merged changes before resuming work.
- **Update your own section of `PROGRESS.md`** at the end of every session.
- **Never commit** `.godot/`, `builds/`, credentials, or personal editor state.
