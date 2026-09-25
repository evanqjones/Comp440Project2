@AGENTS.md

## Claude Code notes

All project rules are in `AGENTS.md` (imported above). Edit rules there, not here.

- **godot-mcp** (if its tools are available and the editor is open with the addon enabled): use `godot_docs` to check Godot 4.7 APIs before writing engine code, and run scenes and read runtime state to verify changes yourself instead of asking the human to look. The addon and its enabled plugin are committed (`DECISIONS.md` D-022). The plugin re-adds the `MCPGameBridge` autoload whenever the editor opens; that's expected, so leave it in `project.godot`.
- **Skills:** the superpowers `brainstorming`, `writing-plans`, and `test-driven-development` skills fit `WORKFLOW.md` steps 2–6. When a skill's default file location differs, **`WORKFLOW.md` wins**: specs and plans go in `docs/features/<system>/<NN-slug>/`, not `docs/superpowers/`.
- **Personal preferences** (explanation style, verbosity) go in `CLAUDE.local.md`, which is git-ignored, not in this file.
