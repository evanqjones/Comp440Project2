# System ownership and interfaces

This is a proposed division. Replace TBD with actual teammates before parallel implementation; no ownership assignments have been confirmed yet.

| System | Owner | Owned files | Interface crossing the boundary |
| --- | --- | --- | --- |
| Integration and game flow | TBD | `systems/core/`, `project.godot`, `export_presets.cfg` | Instantiates system scenes, connects signals, manages start/restart |
| Player | TBD | `systems/player/` | Exposes movement configuration; emits death/interaction signals |
| World and encounters | TBD | `systems/world/` | Provides spawn points; emits level completion |
| UI and audio | TBD | `systems/ui/`, `systems/audio/` | Receives display state; emits start/restart requests |

Keep scenes, scripts, and system-specific assets together in the owned directory. Create the remaining system directories when adding their first files. If the team has fewer people, one person can own multiple rows.

## Shared rules

- One owner edits a `.tscn` scene at a time. Instance another owner's scene instead of copying or editing its internals.
- Before integration, agree on signal names, parameter types, and public methods with the receiving owner. The interfaces above are proposals, not implemented APIs.
- Prefer signals and explicit public methods over reaching into another scene's node tree.
- The integration owner handles shared settings, input actions, autoloads, and the main scene. Request changes through that owner.
- Include changed interfaces and how to run your scene in each pull request. Pull the merged changes before resuming work.
- Never commit `.godot/`, generated builds, credentials, or personal editor state.
