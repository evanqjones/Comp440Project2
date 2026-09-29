# 03-store-skybox: Feature

| | |
|---|---|
| Owner | Evan (asset and production Store integration) |
| Branch | `integration/03-store-skybox` |
| Status | Approved by Evan's request to create and implement a skybox (2026-09-29) |

## Spec

The production Store shows a cheerful daylight sky above the parking lot and
storefront, matching the project's bright, simple art style. Use a reusable
Godot sky resource with a blue upper sky and pale warm horizon. The sky does not
add scene lights, collision, scripts, or gameplay changes. The production Store
scene owns one `WorldEnvironment`, so the existing `main.tscn` receives the sky
through its Store instance without editing Anthony's main scene. The separate
demo preview can retain its existing environment.

## Plan

1. Add an integration test that loads the production Store through the main
   scene and checks for one active sky environment. Confirm it fails first.
2. Create the sky resource under `assets/environment/` and instance it from
   `systems/store/store.tscn` using a `WorldEnvironment` node.
3. Run Store tests, full headless GUT, and a main-scene smoke run. Inspect the
   rendered sky if a graphical Godot session is available.
4. Update `ASSETS.md` and Evan's `PROGRESS.md` section, then commit this step.

## TODO

- [x] Synced main and created the feature branch.
- [x] Spec and plan approved by the direct user request.
- [x] Sky integration test fails before implementation.
- [x] Daylight sky resource and Store scene wiring.
- [x] Store tests, full GUT, and main scene load pass.
- [x] Visual check and handoff notes recorded.
- [x] Commit the feature branch.
