# Workflow: spec-driven development

Every feature goes through the same cycle, whichever teammate or agent (Claude, Codex, Gemini) does the work. The cycle is how four people build in parallel without stepping on each other. It is also how each agent learns what the others did.

```
0 Sync → 1 Branch → 2 Brainstorm → 3 Spec → 4 Plan → 5 TODO → 6 Build → 7 Verify → 8 PR
                     00-brainstorm  01-spec   02-plan   03-todo   code+tests  PROGRESS    main
```

Based on the LLM codegen workflow (brainstorm → spec → plan with prompts → TODO), adapted for four owners, shared contracts, and GUT tests.

---

## Full or Lite?

| Use **Full** (four files) when… | Use **Lite** (one `FEATURE.md`) when… |
|---|---|
| It touches `CONTRACTS.md` or `systems/shared/` | It stays inside your own system's folders |
| Another system depends on it (for example, Cart's ram-steal, Store's round flow) | Nobody else consumes it (for example, camera shake, HUD layout) |
| It's more than about a day of work | It's a few hours |

If you're unsure, use Full. Lite still has all four parts (brainstorm, spec, plan, TODO), just shorter and in one file.

## Naming

| Thing | Format | Example |
|---|---|---|
| Feature folder | `docs/features/<system>/<NN>-<slug>/` | `docs/features/cart/03-ram-steal/` |
| Branch | `<system>/<NN>-<slug>` (same as the folder) | `cart/03-ram-steal` |
| Cross-system or contract work | `integration/<NN>-<slug>` | `integration/00-foundation` |
| Docs-only change | `docs/<NN>-<slug>` | `docs/00-project-specs` |
| Commit message | `<system>: <what changed>` | `cart: transfer items up to cap on steal` |

`<system>` is one of `player`, `cart`, `rivals`, `store`, `integration`. `NN` counts up within each system folder (01, 02, …). Check the folder to find the next number.

---

## The steps

Each step has a **prompt** you can paste into any agent. Replace the `<angle brackets>`.

### Step 0: Sync (every time, before anything new)

Always start from the latest `main`. If you skip this, you'll build on stale contracts and get merge conflicts.

```bash
git checkout main && git pull --ff-only
```

**Resuming an existing branch instead?**

```bash
git checkout <branch> && git pull && git merge origin/main
```

> **Prompt, sync:**
> ```text
> I'm <name>, owner of the <System> system. Read AGENTS.md, then docs/PROGRESS.md and docs/CONTRACTS.md.
> Tell me in under 10 lines: what currently works on main, what the other systems finished or changed
> since my last update, anything in "Needs from others" addressed to <System>, and any contract changes
> I need to know about. Don't change any files.
> ```

### Step 1: Branch and folder

```bash
git checkout -b <system>/<NN>-<slug>
```

- **Full:** copy `docs/templates/00-brainstorm.md`, `01-spec.md`, `02-plan.md` and `03-todo.md` into `docs/features/<system>/<NN>-<slug>/`.
- **Lite:** copy `docs/templates/FEATURE-lite.md` to `docs/features/<system>/<NN>-<slug>/FEATURE.md`.
- Set your section of `docs/PROGRESS.md`: **Branch** and **Current feature**.

### Step 2: Brainstorm → `00-brainstorm.md`

> **Prompt, brainstorm:**
> ```text
> I own the <System> system of Checkout Chaos. We're starting feature <NN-slug>: <one-line goal>.
> Read AGENTS.md, docs/GAME_SPEC.md (especially §<section>), docs/CONTRACTS.md and docs/PROGRESS.md first.
>
> Ask me one question at a time so we can develop a thorough, step-by-step spec for this feature.
> Each question should build on my previous answers. Prefer multiple-choice questions with your
> recommendation first. Don't ask what GAME_SPEC or CONTRACTS already answer; quote them instead.
> Cover: player-facing behavior, exact numbers, which contract signals/methods it uses or emits,
> edge cases, how we'll test it, and what's out of scope. The goal is a spec another developer
> (or agent) could implement without asking me anything.
>
> When I say we're done, write the Q&A summary to docs/features/<system>/<NN-slug>/00-brainstorm.md
> using docs/templates/00-brainstorm.md.
> ```

### Step 3: Spec → `01-spec.md`

> **Prompt, spec:**
> ```text
> Now that we've wrapped up the brainstorming, compile our findings into a comprehensive,
> developer-ready specification at docs/features/<system>/<NN-slug>/01-spec.md using
> docs/templates/01-spec.md. Include every requirement and exact number, the contract signals and
> methods it uses or emits (link docs/CONTRACTS.md, don't redefine them), scene and file layout,
> edge cases, a test plan (GUT tests + test-scene checklist) and "Done when" acceptance criteria.
> If the feature needs any contract change, list it under "Contract changes" and stop for my
> decision. Don't assume it's approved.
> ```

**Review gate:** the human reads `01-spec.md` before moving on. If it changes a contract, follow the change protocol in `CONTRACTS.md` §9 first.

### Step 4: Plan → `02-plan.md`

> **Prompt, plan:**
> ```text
> Read docs/features/<system>/<NN-slug>/01-spec.md. Draft a detailed, step-by-step blueprint for
> building it. Then break the blueprint into small iterative chunks that build on each other.
> Then break those chunks down one more round into small steps: small enough to implement
> safely with a test, big enough to move the feature forward. Iterate until the steps are the
> right size.
>
> Then write one prompt per step for a code-generation agent, each in a fenced text block. Every
> prompt must: name the files to create or edit (only systems/<system>/ and tests/<system>/ unless
> the spec lists an approved contract change); write the GUT test first and watch it fail;
> implement; run the full GUT suite headless; tick the step in 03-todo.md; and commit with
> "<system>: <what>". No orphaned code: each step wires into the previous ones, and the last
> step wires the feature into the system's test scene.
> Save it to docs/features/<system>/<NN-slug>/02-plan.md using docs/templates/02-plan.md.
> ```

### Step 5: TODO → `03-todo.md`

> **Prompt, TODO:**
> ```text
> Create docs/features/<system>/<NN-slug>/03-todo.md from docs/templates/03-todo.md: a checklist that
> mirrors every iteration and step in 02-plan.md, plus the Verify, PR and Post-merge sections.
> Then add this feature to docs/TODO.md under the right milestone if it isn't there, and commit
> the four docs with "<system>: spec and plan for <NN-slug>".
> ```

### Step 6: Build (one prompt at a time)

> **Prompt, build a step:**
> ```text
> Read AGENTS.md, then docs/features/<system>/<NN-slug>/03-todo.md and 02-plan.md.
> Execute Prompt <k> from 02-plan.md exactly: test first, then implementation, then the full GUT suite
> headless. If a test fails, fix it before moving on. When it passes, tick the step in 03-todo.md,
> commit, and stop. Tell me what changed, the test result, and how I can see it in the test scene.
> ```

Rules while building:
- **One step, one commit.** Don't batch several prompts into one commit.
- **Stay in your lane.** Only your system's folders, unless the spec lists an approved contract change.
- **The plan is a guide, not a cage.** If a step turns out wrong, update `02-plan.md` and `03-todo.md` first, then continue.
- **Update `PROGRESS.md`** (your section) at least at the end of every work session.

### Step 7: Verify

> **Prompt, verify:**
> ```text
> Verify feature <NN-slug> against the "Done when" list in 01-spec.md. Run the full GUT suite
> headless and report the output. List the test-scene checks from the spec's test plan that I need
> to do by hand (feel, camera, visuals). If this feature is already wired into main.tscn, tell me what
> to try in the full game. Update my section of docs/PROGRESS.md with the result. Don't open a PR yet.
> ```

The human plays the test scene and confirms the hand checks.

### Step 8: Pull request

```bash
git fetch origin && git merge origin/main
```

Re-run the GUT suite after merging, then open the PR.

> **Prompt, PR:**
> ```text
> Merge origin/main into this branch, re-run the full GUT suite headless, and fix anything that broke.
> Then write a PR description with: Summary; Interfaces touched (contract items used/emitted/changed);
> How to test (test scene path + what to do); Test results; Screens/notes. Update my section of
> docs/PROGRESS.md (move the feature to Done, add handoff notes other systems need) and tick the
> item in docs/TODO.md. Commit, then show me the PR text. Only push or open the PR if I say so.
> ```

- **One teammate reviews.** Before the demo (Fri 09-25), a quick review in the group chat is enough.
- **Merging:** the owner merges their own system's PR after review. Anything touching `project.godot`, `export_presets.cfg`, or `systems/core/main.tscn` is merged by Anthony.
- After the merge, everyone runs Step 0 before their next feature.

---

## Lite features

Same cycle, one file. Use this single prompt for Steps 2–5:

> **Prompt, Lite:**
> ```text
> I own <System>. Small feature <NN-slug>: <one-line goal>. Read AGENTS.md, the relevant section of
> docs/GAME_SPEC.md, and docs/CONTRACTS.md. Ask me 3–5 questions, one at a time, then fill in
> docs/features/<system>/<NN-slug>/FEATURE.md from docs/templates/FEATURE-lite.md: a short brainstorm
> summary, a spec with "Done when" criteria, a plan of small steps (a prompt for each only if a step
> isn't obvious), and a checklist. Stop for my review before building.
> ```

Then build, verify and PR exactly as for Full (Steps 6–8).

---

## Session start and end (every session)

> **Prompt, resume:**
> ```text
> Read AGENTS.md, then docs/PROGRESS.md and docs/features/<system>/<NN-slug>/03-todo.md (or FEATURE.md).
> Tell me where we are, what the next unchecked step is, and whether main has changed in a way that
> affects this feature. Don't change files yet.
> ```

> **Prompt, end of session:**
> ```text
> Update my section of docs/PROGRESS.md: Status, Updated (today's date and your agent name), Done,
> In progress, Next, Needs from others, and Handoff notes (facts other systems' agents must know,
> e.g. signal timing or a helper they can call). Commit with "<system>: progress update".
> ```

---

## How agents learn from each other

Agents don't share memory. They share **the repo**. Knowledge moves through these files:

| File | Written by | Read by | Carries |
|---|---|---|---|
| `docs/PROGRESS.md` | Each owner's agent, own section only | Everyone, at every sync | Status, what's done, **handoff notes**, what you need from others |
| `docs/CONTRACTS.md` | Change protocol only | Everyone | The exact interfaces |
| `docs/DECISIONS.md` | Anyone (append a new entry) | Everyone | Why things are the way they are |
| `docs/features/**` | The feature's owner | Anyone integrating with that feature | Full reasoning, spec, and test plan |
| `docs/TODO.md` | Owners tick their own items | Everyone | What's left per milestone |

**Rule of thumb:** if another system's agent would need to know it, put it in your PROGRESS handoff notes. If it's a decision someone might question later, put it in DECISIONS.
