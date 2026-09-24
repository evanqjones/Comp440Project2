# Tools and Technologies

Everything the team (and every agent) uses to build Checkout Chaos. If you add a tool, addon, or asset source, add it here in the same PR.

## Engine and language

| Item | Choice | Notes |
|---|---|---|
| Engine | **Godot 4.7.2 stable, standard build** | Pinned in `.godot-version`. Not the .NET build. Version changes need the whole team (log them in `DECISIONS.md`). |
| Language | **GDScript**, statically typed | `var speed: float = 0.0`, `func try_add_item(item: ItemData) -> bool`. Typed arrays and dictionaries (`Array[ItemData]`, `Dictionary[int, int]`). |
| Renderer | **Compatibility** (`gl_compatibility`) | Required for the web export. No SDFGI, volumetric fog, or other Forward+ features. Keep dynamic lights few. Use unshaded or emissive meshes for glow effects (such as the Deal of the Day beam). |
| Physics | Godot's built-in 3D physics (project default) | Changing the physics engine requires a `DECISIONS.md` entry. |
| Navigation | `NavigationRegion3D` (baked in the store scene) + `NavigationAgent3D` per bot | Fallback: hand-placed waypoints at the aisle ends. |
| UI | Godot `Control` nodes under a `CanvasLayer` | HUD and screens are in `systems/player/`. |

### Godot 4 vs Godot 3 (the most common agent mistakes)

Agents often produce Godot 3 code. In Godot 4.7 the correct forms are:
- `@export`, `@onready` (not `export`, `onready`)
- `await` (not `yield`)
- `CharacterBody3D` (not `KinematicBody`), and `velocity` is a built-in property there
- `signal_name.connect(callable)` / `signal_name.emit(args)` (not `connect("name", obj, "method")` / `emit_signal`)
- `Node3D` (not `Spatial`)
- `instantiate()` (not `instance()`)

Check the Godot 4.7 class reference before using an API you're unsure of.

## Web export

- Preset **Web** in `export_presets.cfg`, output `builds/web/index.html` (git-ignored).
- **Threads are disabled** (`variant/thread_support=false`). Don't use `Thread` or `WorkerThreadPool`; everything runs on the main thread.
- **Audio starts only after a user gesture**, so the title screen waits for a key press or click before playing music.
- Test the web build through a local HTTP server, never by opening the HTML file directly:

```bash
cd builds/web && python3 -m http.server 8000
```

Then open http://localhost:8000.

- Export templates: **Editor → Manage Export Templates → Download and Install** for 4.7.2.

## Running Godot from the command line

| OS | Godot binary |
|---|---|
| macOS | `/Applications/Godot.app/Contents/MacOS/Godot` |
| Windows | `Godot_v4.7.2-stable_win64_console.exe` (the `_console` build prints output) |
| Linux | `Godot_v4.7.2-stable_linux.x86_64` |

On macOS, add an alias so the commands below work (put it in `~/.zshrc`):

```bash
alias godot="/Applications/Godot.app/Contents/MacOS/Godot"
```

Useful commands (run from the repo root):

```bash
godot --version
```

```bash
godot --headless --import
```

The second one imports new assets without opening the editor. Run it once after cloning and after pulling new assets, before running tests headless.

```bash
godot --path . res://systems/cart/test/cart_test.tscn
```

That runs one scene; swap in any test scene path.

## Testing: GUT (Godot Unit Test)

- **Addon:** GUT 9.x for Godot 4, installed in `addons/gut/` and **committed**, so every teammate and agent can run tests without installing anything. Record the exact version here when the foundation feature installs it: `GUT version: (filled in by integration/00-foundation)`.
- **Layout:** `tests/<system>/test_<thing>.gd`, each `extends GutTest`. Test functions start with `test_`.
- **Run all tests headless:**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

  The foundation feature also adds a `.gutconfig.json` so that `godot --headless -s addons/gut/gut_cmdln.gd` alone runs everything.
- **In the editor:** the GUT panel at the bottom (enable the plugin in Project Settings → Plugins).
- **What gets a GUT test:** rules and numbers: the steal rule, inventory cap, slowdown math, boost meter, conservation, scoring and ties, round phase transitions, bot target scoring.
- **What gets a test scene instead:** feel (handling, camera, bot behavior on the navmesh). Each system keeps playable test scenes with fake inputs in `systems/<system>/test/`. For example, Cart driven by a scripted `DriveCommand`, or Rivals chasing dummy pickups.
- **Rule:** a step isn't done until the full GUT suite passes headless.

## Repository layout

```
AGENTS.md  CLAUDE.md  GEMINI.md  README.md
project.godot  export_presets.cfg  .godot-version
addons/gut/                  ← test framework (committed)
assets/   (Evan)             ← visual scenes, palette materials, UI layouts, audio, fonts (see ASSETS.md)
systems/
  shared/                    ← contract scripts + shopper profiles (jointly owned; change protocol)
  player/   (Rickey)         ← PlayerController, chase camera, HUD, screens, audio
  cart/     (Rickey)         ← Cart.tscn, cart.gd
  rivals/   (John)           ← BotController, personalities
  store/    (Anthony)        ← RoundManager autoload, store scene, pickups, hazards, checkout
  core/     (Anthony)        ← main.tscn
  <system>/test/             ← that system's test scenes
tests/<system>/              ← GUT tests
docs/                        ← specs, workflow, tracking (see AGENTS.md)
builds/                      ← export output (git-ignored)
```

**Committed:** scenes, scripts, assets, `.uid` files, `.import` files, `project.godot`, `export_presets.cfg`, `addons/gut/`.
**Never committed:** `.godot/`, `builds/`, export credentials, personal editor settings, secrets.

## Source control

- **Git + GitHub:** https://github.com/evanqjones/Comp440Project2
- Branch per feature, PR into `main`, one teammate reviews. See [`WORKFLOW.md`](WORKFLOW.md).
- **`gh` CLI** (optional): lets agents open PRs (`gh pr create`). Each teammate authenticates it themselves.
- Line endings are LF (`.gitattributes`), and `.gd` files use tabs (`.editorconfig`).

## AI agents

All three read the same rules. [`AGENTS.md`](../AGENTS.md) is canonical; the other two import it.

| Agent | Instruction file | Notes |
|---|---|---|
| **Claude Code** | `CLAUDE.md` (imports `AGENTS.md`) | Optional **godot-mcp** (drives a live editor: run scenes, inspect nodes, read runtime state, look up docs). Optional superpowers skills (brainstorming, writing-plans, TDD) match our workflow steps. |
| **Codex** (CLI / IDE) | `AGENTS.md` (read natively) | Its sandbox may block running Godot. Approve the headless test command when asked. |
| **Gemini CLI** | `GEMINI.md` (imports `AGENTS.md`) | Run `/memory show` to confirm the import loaded. |

**godot-mcp is local-only for now.** It needs its addon in the project and the plugin enabled, which edits `project.godot`. Until the team decides (open question in `DECISIONS.md`), don't commit `addons/godot_mcp/` or the `project.godot` line that enables it.

## Assets and licenses

Evan owns the asset pipeline. The conventions, manifest, and credits are in [`ASSETS.md`](ASSETS.md).

- **Tools:** Godot primitives and CSG for placeholders and the greybox. Blender (or any tool that exports `.glb`) for low-poly models. Any editor that exports `.ogg` / `.wav` for audio (for example, Audacity).
- **Sources:** make it yourself or use **CC0** packs (for example, Kenney.nl for low-poly models and UI sounds).
- Every third-party asset gets a row in `ASSETS.md` §6 (credits) in the same PR that adds it. No assets with unclear licenses.

## Reference

- [`reference/`](reference/): both GDD PDFs.
- **Three.js prototype:** the earlier browser version. Location to be added (open question in `DECISIONS.md`). Use it for feel, tuning, and the waypoint and kinematic fallbacks.
