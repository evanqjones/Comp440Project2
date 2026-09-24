# Comp440 Project 2

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

Agree on the ownership table in [docs/TEAM.md](docs/TEAM.md) before parallel scene work. Each system owner edits their own scenes and scripts. Coordinate edits to shared project settings and the main scene with the integration owner.
