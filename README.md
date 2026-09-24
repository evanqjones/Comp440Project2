# Comp440 Project 2: Checkout Chaos

A 3D shopping-cart racer: one human and three bots grab groceries, ram each other to inherit hauls, and check out before the store closes. Built in Godot 4.7.2 by Rickey (Player), Evan (Cart), John (Rivals), and Anthony (Store / Round Manager).

**Demo:** Fri 2026-09-25 · **Final:** Fri 2026-10-02

## Start here

| Read | For |
|---|---|
| [docs/GAME_SPEC.md](docs/GAME_SPEC.md) | The full game spec: rules, numbers, systems, scope |
| [docs/CONTRACTS.md](docs/CONTRACTS.md) | The exact interfaces between the four systems |
| [docs/WORKFLOW.md](docs/WORKFLOW.md) | How we build every feature (branch → spec → plan → TODO → build → PR), with copy-paste agent prompts |
| [docs/PROGRESS.md](docs/PROGRESS.md) | Where everyone is right now |
| [docs/TODO.md](docs/TODO.md) | The backlog, by milestone and system |
| [docs/TECH_STACK.md](docs/TECH_STACK.md) | Tools, commands, testing |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Why things are the way they are, plus open questions |
| [docs/TEAM.md](docs/TEAM.md) | Ownership and shared rules |

**AI agents:** [AGENTS.md](AGENTS.md) is the canonical instruction file (Codex reads it directly). [CLAUDE.md](CLAUDE.md) and [GEMINI.md](GEMINI.md) import it.

## Shared setup

Use **Godot 4.7.2 stable, standard build**, with GDScript. The version is pinned in `.godot-version`; coordinate any version change with the whole team. Do not use the .NET build for this web-targeted project.

1. Clone `https://github.com/evanqjones/Comp440Project2.git`.
2. Import `project.godot` into Godot 4.7.2.
3. Choose **Editor > Manage Export Templates > Download and Install** for this exact editor version.
4. Press **F6** to run an open scene or **F5** to run the starter main scene.
5. For a browser build, create `builds/web`, choose **Project > Export > Web**, and export to `builds/web/index.html`. Serve the output through a local HTTP server; do not open the HTML as a local file.

The project uses the Compatibility renderer and a Web preset with threading disabled. `.godot/` and `builds/` are ignored; commit source scenes, scripts, assets, `.uid` files, `project.godot`, and `export_presets.cfg`.

## Git identity and collaboration

Run `git config user.email` and confirm that address is verified in your own GitHub account under Settings > Emails. To correct it for this repository, run `git config --local user.email "YOUR_VERIFIED_EMAIL"` and `git config --local user.name "YOUR_NAME"`.

When contributing on a teammate's laptop, add a blank line followed by this trailer to the commit message:

```text
Co-authored-by: Your Name <your verified email>
```

The repository owner must add teammates under GitHub Settings > Collaborators; each teammate accepts the invitation and clones the repository. Use a branch per feature, pull before starting, and review changes before merging.

Ownership is set in [docs/TEAM.md](docs/TEAM.md). Each system owner edits their own scenes and scripts. Coordinate edits to shared project settings and the main scene with the integration owner, **Anthony**.

Always pull before starting anything new (`git checkout main && git pull --ff-only`), then follow [docs/WORKFLOW.md](docs/WORKFLOW.md).
