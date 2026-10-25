# ansill House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

ANSI Layout Language — declarative textmode art compiler (parse → resolve → render → validate
→ emit). Read first: the exports, the immediate callers and the shared helpers.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug the parser, resolver, renderer, validator, grid, profiles, backends, CLI | `ansill-worker` (default) |
| Write and extend the tests under `t/` | `ansill-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `ansill-release-manager` |
| Read-only research, audit, gap analysis | `ansill-worker` ("read-only, change nothing") |

Behavior-relevant = the compiled output, the language surface, the diagnostics, the profiles
and the backends. Pure prose docs and `Changes` notes are not. The lane split in detail: skill
`ansill-core`.

## Release

`prove -l t/` is the test command. A git tag points at the public repository; the
pre-release audit goes through `ansill-release-manager`, which reports and never releases.

## Deviations from the house rules

- **No new cards for side findings.** Never create a card for a finding outside the current
  card — write it as a note on the card in hand.
- **Public tracker:** GitHub `Getty/ansill`. The specification invites outside contributions,
  so every issue is visible to every reader.
