# Team, ownership, and shared rules

Ownership comes from the team GDD (see `DECISIONS.md` D-006).

| System | Owner | Owned files | Interface crossing the boundary |
| --- | --- | --- | --- |
| **Player** | Rickey | `systems/player/`, `tests/player/`, `docs/features/player/` | Produces `DriveCommand`; reads `CartState` and `RoundManager` for the HUD; owns screens, audio, and feedback |
| **Cart** | Evan | `systems/cart/`, `tests/cart/`, `docs/features/cart/` | Consumes `DriveCommand`; emits `item_collected`, `cart_robbed`, `cart_full`; provides `try_add_item`, `take_all_items`, `get_state` |
| **Rivals** | John | `systems/rivals/`, `tests/rivals/`, `docs/features/rivals/` | Produces `DriveCommand`; reads pickups, carts, and time from `RoundManager` |
| **Store / Round Manager** | Anthony | `systems/store/`, `tests/store/`, `docs/features/store/` | `RoundManager` autoload: phases, timer, pickups, checkout, spills, scoring; emits round, checkout, and hazard signals |
| **Integration** | Anthony | `systems/core/` (`main.tscn`), `project.godot`, `export_presets.cfg`, `docs/features/integration/` | Wires the four systems together in `main.tscn`; input map, autoloads, physics layers; web export |
| **Shared contracts** | All four (change protocol) | `systems/shared/`, `tests/shared/`, `docs/CONTRACTS.md` | See `CONTRACTS.md` |

Exact signatures: [`CONTRACTS.md`](CONTRACTS.md). How to work: [`WORKFLOW.md`](WORKFLOW.md).

## Shared rules

- **Pull before starting anything new** (`git checkout main && git pull --ff-only`), then branch.
- **One owner edits a `.tscn` scene at a time.** Instance another owner's scene instead of copying it or editing its internals.
- **Signals and public methods only.** Don't reach into another scene's node tree.
- **Contracts change only through the change protocol** (`CONTRACTS.md` §9).
- **Shared settings go through Anthony:** input actions, autoloads, physics layers, `main.tscn`, export presets.
- **Each PR lists** the interfaces it touched and how to run its test scene. Pull the merged changes before resuming work.
- **Update your own section of `PROGRESS.md`** at the end of every session.
- **Never commit** `.godot/`, `builds/`, credentials, or personal editor state.
