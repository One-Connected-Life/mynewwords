---
name: work
description: Lean lifecycle orchestrator for Polyglot — classify the work, plan briefly, write a failing spec first (TDD), implement to green, commit + push, deploy to mynewwords.org, and verify on the live URL. Solo, ship-fast, no ceremony.
argument-hint: <what we're doing — or bare to be asked>
user-invocable: true
---

# /work — Polyglot lifecycle (lean)

A forcing function: the process made visible, sized for a **solo, ship-fast repo**. It
adapts steps by work type, prints a colored phase header at each transition, and refuses
to let specs go unwritten, commits go unstaged, or a build go undeployed. Keep the
discipline (test → ship → verify); drop the bureaucracy. This is a one-person repo that
values momentum.

> Polyglot has **none of OCL's session infra** — no kanban board, no manifests/heartbeats,
> no module system, no `gh` failover wrapper, no WIP limits. Raw `gh` is fine. GitHub
> issues are **optional**, not mandatory ceremony (see below).

## Culture (from CLAUDE.md — internalize)
- **Build then deploy immediately, no asking.** Once it builds and tests pass, ship it.
- Commit and push **freely** — never gate those on permission.
- The bar is **green, not broken**: deploy working code, never something that 500s.
- Deploy is **manual**: `bin/kamal deploy` — load `.env` into the shell first
  (`KAMAL_REGISTRY_PASSWORD` lives there). There is **no `rake deploy`**. Pushing to `main`
  only runs CI; it does **not** deploy. So actually run the deploy — don't assume a push shipped it.
- **Product invariant:** practice is always available. FSRS orders/retires, never gates
  ("no words due" must never happen). Don't ship a change that violates this.

## Invocation
```
/work                  bare → ask what we're doing
/work fix the streak   concrete task → auto-classify
/work bug <desc>       broken behavior → route to /bug-fix
/work feature <desc>   new capability
```
Skip the "what are we doing?" question if the invocation already names a verb + object.

## Classify (quick)

| Type | When | Path |
|---|---|---|
| **Quick fix** | <5 lines, no behavior change ("typo", "tweak copy") | code → test → ship |
| **Bug** | Broken behavior | **route to `/bug-fix`** (reproduce-first TDD) |
| **Feature** | New user-facing capability | brief plan → TDD → ship |
| **Chore** | Refactor, tech debt, infra | light plan → TDD if behavior changes → ship |

For a **non-trivial feature or bug**, offer to open a lightweight
`One-Connected-Life/polyglot` issue (raw `gh issue create`) — useful as a tracking anchor,
not required. For small changes, **just do it and ship** — no issue, no plan ceremony.

## Phase headers

Print a colored bar at each transition so the process is visible (chat only — no manifest,
no footer stamp). Replace `<CODE>`/`<emoji>`/`<NAME>`:

```bash
echo -e "\033[<CODE>m━━━ <emoji> <NAME> ━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
```

| Phase | Code | Emoji |
|---|---|---|
| PLAN | `32` (green) | 🟢 |
| TEST (red→green) | `31` (red) | 🔴 |
| IMPLEMENT | `97` (white) | ⚪ |
| SHIP | `34` (blue) | 🔵 |
| VERIFY | `33` (yellow) | 🟡 |

Status icons: `⬜` pending · `🔵` in progress · `✅` done · `⏭️` skipped.

## Phases

### 🟢 PLAN (green)
Keep it to a paragraph. Name what changes, the files you expect to touch, and the
acceptance check ("after this, X works / Y is fixed"). For a quick fix, this is one line.
Non-trivial work → offer the optional issue here. Then move.

### 🔴 TEST — failing spec FIRST (red)
Polyglot's testing convention is **TDD**: write the RSpec spec that captures the desired
behavior, **run it, watch it fail (RED)** before touching implementation. This is the gate
`/work` does not skip — even quick fixes get a test where behavior is observable.
- Bugs go through `/bug-fix`, which owns the reproduce-first red-green cycle — invoke it,
  don't freelance an ad-hoc bug process here. Never fix on a *theorized* cause; confirm first.
- Feature spec on the real user path when the change is user-visible (renders the real page
  through persisted data) — it crosses seams an in-memory unit spec hides.
- `bundle exec rspec <files>` — diff-scoped, not the whole suite. CI runs the full suite on push.

### ⚪ IMPLEMENT (white)
Write the code to turn the spec **GREEN**. Re-run the spec to confirm. If views/CSS/JS
changed, rebuild Tailwind (`bin/rails tailwindcss:build`). Check the product invariant still
holds (practice always available). Keep it scoped to the one thing — side work becomes its
own cycle, not a rider on this commit.

### 🔵 SHIP — commit, push, deploy (blue)
This phase is **non-negotiable**: uncommitted / unpushed / undeployed = not done.
1. `git status` then `git diff --cached --stat` — stage **only this change's files** with
   explicit paths. `git add` any NEW files (specs!).
2. Commit with explicit paths: `git commit <file1> <file2> ... -m "..."`. End the message
   with the Co-Authored-By line. Reference an issue `#NNN` if one exists (optional).
3. `git push` (bare).
4. **Deploy:** load `.env`, then `bin/kamal deploy`. Actually run it — a push is not a deploy.

### 🟡 VERIFY — confirm it actually shipped (yellow)
The forcing function that makes /work worth running. After deploy:
1. **Deployed SHA == HEAD.** Confirm the running app is on your commit
   (`git rev-parse HEAD` vs what Kamal reports / what prod serves). A **"nothing to deploy"
   or no-op deploy is a RED FLAG** — investigate, don't shrug.
2. **Acceptance-test on the live prod URL** — `https://mynewwords.org` — exercise the actual
   change in the browser/curl. Local green is not shipped-green.
3. Report what you verified. If it's broken on prod, you are not done (green, not broken).

## Rules
1. **Never skip the test.** Failing spec first, even on quick fixes where behavior is observable.
2. **Never skip shipping.** Commit + push + `bin/kamal deploy`, in that order, every cycle.
3. **Never skip verify.** Deployed SHA == HEAD and acceptance-test on `mynewwords.org`. A
   no-op deploy is a red flag, not a success.
4. **Announce phase transitions** with the colored header — keep the process visible.
5. **Clean commits, explicit paths.** Stage only this change's files; `git commit a b -m`,
   never bare `git commit -m`. One change per cycle — side work spins a fresh cycle.
6. **Ship fast, don't ask.** Build then deploy immediately. Commit/push/deploy never need
   permission. The only bar is green-not-broken.
7. **Issues are optional.** Offer one for non-trivial work; skip the ceremony for small stuff.
8. **Hold the product invariant.** Practice is always available — never ship "no words due".
9. **Info requests get info-only replies.** If a message asks you to look/show/explain rather
   than build, end with the answer — no "want me to ship it?" nudge. Build resumes on a build verb.
