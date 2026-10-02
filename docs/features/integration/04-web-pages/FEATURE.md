# 04-web-pages: Lite feature

| | |
|---|---|
| System / Owner | Integration (web export; done by Rickey at his request) |
| Branch | `integration/04-web-pages` (from `main`) |
| Agent / Date | Claude Code / 2026-09-30 |
| Milestone | Final: "Web export tested through a local server" + a public link that opens on another team's machine |

## 1. Brainstorm

- Rickey's instructions (2026-09-30):
  - export `index.html` into a `docs/` folder that holds an empty `.gdignore`;
  - serve Pages from `main`, `/docs`;
  - keep Thread Support unchecked under Variant in the Web preset, or the game runs locally but shows a blank screen for everyone else;
  - the live link plays the **last export**, not the latest code, so **export again after every change**;
  - test in a private window on a machine that isn't yours; it has to open on another team's machine.
- This replaces the GitHub Actions idea (the local `integration/04-github-pages` branch, never pushed).
- The repo owner (Evan) set Pages; the source must be **Deploy from a branch → `main` → `/docs`**.

## 2. Spec

- **`export_presets.cfg`** (Web): `export_path` goes from `builds/web/index.html` to **`docs/index.html`**.
  - `variant/thread_support=false` is unchanged: a no-threads build needs no COOP/COEP headers, which GitHub Pages can't send.
  - `exclude_filter` already has `docs/*`, so an old export never gets packed into a new one.
- **`docs/.gdignore`** (empty): Godot doesn't import the exported `.wasm`, `.pck`, `.png` or anything else under `docs/`.
- **`docs/.nojekyll`** (empty): Pages serves the files as they are. Jekyll would otherwise try to render the project's Markdown docs.
- **The export** (`index.html`, `.js`, `.wasm`, `.pck`, icons and audio worklets) is committed in `docs/` next to the project docs. `index.html` becomes the site's home page: `https://evanqjones.github.io/Comp440Project2/`.
- **Re-exporting** is part of "done = playable on `main`" (D-033): after a change merges, run the export below and commit `docs/` again.

  ```bash
  godot --headless --export-release "Web" docs/index.html
  ```

- **Contract changes:** none.

**Done when:**
- [x] The export loads from a local server in a browser: title card, then a round starting, with no console errors. Checked 2026-09-30 in the browser pane: title → story → rivals → countdown → round at 1:39, player picked 2 items, bots banked, no console errors, single-threaded WebGL 2.
- [ ] Merged. Pages (`main`, `/docs`) serves the game at the URL above, and it loads in a fresh private browser session.
- [ ] Rickey: opens it in a private window on a machine that isn't his.

## 3. Plan

1. Install the web templates → export → serve `docs/` locally → load in the browser pane.
2. Commit `docs/` + preset + decision → pull `main` → push, PR, merge → check the live URL.
