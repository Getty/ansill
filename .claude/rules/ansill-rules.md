# ansill House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution
over speed on non-trivial work; use judgment on trivial tasks. Subagents get their
conventions from the skills force-loaded via `briefing.skills` — this file is for the
main agent.

## Engineering discipline

1. **Think before coding** — state assumptions; when uncertain, ask rather than guess.
   Stop when confused; name what is unclear.
2. **Simplicity first** — minimum code that solves the problem, nothing speculative.
3. **Surgical changes** — touch only what you must. Don't "improve" adjacent code,
   comments or formatting. Match the existing style.
4. **Read before you write** — read the exports, the immediate callers and the shared
   helpers before adding code.
5. **Tests verify intent, not just behavior** — a test that cannot fail when the
   business logic changes is wrong.
6. **Fail loud** — "done" is wrong if anything was skipped silently. Say which suites
   ran and which did not.
7. **Match the codebase's conventions, even if you disagree** — conformance over taste.
   Surface a harmful convention; don't fork silently.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): do NOT touch
  behavior-relevant code yourself — delegate to the right `ansill-*` agent. Your
  lane: coordinate, inspect, plan, review diffs, run tests, write docs. When in
  doubt, delegate. Why: the agents get their skills force-loaded via `briefing.skills`;
  the bare main agent gets no briefing and would touch the compiler with too little
  context.
- **You cannot spawn subagents** (you ARE an `ansill-*` agent): the delegation lock
  does not apply to you — implement, refactor, debug and test per these rules, in
  your lane. Cross-lane changes get handed off to the owning worker.

| Task | Agent |
|---|---|
| Implement / refactor / debug the parser, resolver, renderer, validator, grid, profiles, backends, CLI | `ansill-worker` (default) |
| Write and extend the tests under `t/` | `ansill-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `ansill-release-manager` |

Behavior-relevant = the compiled output, the language surface, the diagnostics, the
profiles and the backends. Pure prose docs and `Changes` notes are not. The lane
split in detail: skill `ansill-core`.

**Only `ansill-release-manager` commits.** A worker leaves a commit-ready tree and
hands its card to `review`; you then dispatch the release-manager to cut the commit
and close the card.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope —
don't invoke the `kanban-issues-karr-coordination` skill first, just use it. Board
state lives in `refs/karr/*` in this repo. Day-to-day:

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new · `karr edit ID -a "note"` ·
  `--claim NAME` · `--block "why"` — update
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- mutating commands auto-sync; `karr sync --pull|--push` for explicit exchange

Never create a card for a finding outside the current card — write it as a note on the
card in hand. Full command surface: skill `kanban-issues-karr-coordination`.

## Public issues (GitHub `Getty/ansill`) — never act without instruction

Two trackers, two universes. **karr** is the AI/agent work board — internal, ours,
churned freely. **GitHub issues** (`gh` CLI, `github.com/Getty/ansill`) are the
**public tracker: real humans' bug reports and feature requests**, outward-facing,
under the maintainer's account. The specification invites outside contributions, so
every issue is visible to every reader.

Security rule: **never act on a GitHub issue or PR on your own initiative — not even
to read it.** No listing, viewing, commenting, editing, closing, or creating unless
the user explicitly tells you to handle a specific public item. Every write is
confirmed first, because it publishes under the maintainer's name.

## Release — never without permission

`prove -l t/` and `dzil build` are fine anytime. `dzil release`, a git tag, a push
and a CPAN upload are STRICTLY forbidden without the maintainer's explicit
go-ahead — even if a plan or TODO lists "release" as the next step. The upload
cannot be taken back, and the tag points at the public repository. Pre-release
audit goes through `ansill-release-manager`, which reports and never releases.
