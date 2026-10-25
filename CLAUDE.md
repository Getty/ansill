# CLAUDE.md — ANSILL

**ANSILL is a declarative text-mode layout language.** A small line-oriented
language compiles to a 2D cell grid and is emitted as ANSI escape sequences,
plain text, JSON or HTML. The Perl distribution `ANSILL` implements the
language specification in `spec/ANSILL.md` (v0.2).

The compiler runs five stages — parse → resolve → render → validate → emit —
one module each. **The specification is the language definition, the code is the
implementation**; where the two differ, that is a finding for the maintainer,
not a licence to quietly align one to the other.

**`dist.ini` is the truth for the build and the release.** It carries the name
and the `[@Author::GETTY]` bundle; `cpanfile` is generated from it and is never
edited by hand.

Project knowledge — the pipeline, the cell and color model, the profiles, the
language surface, the backends, the known drift — lives in skill `ansill-core`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it
yourself — principle in the shared house rules (skilletor bundle
`getty-cpan-dist@getty`), lanes in `.claude/rules/ansill-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug the parser, resolver, renderer, validator, grid, profiles, backends, CLI | `ansill-worker` (default) |
| Write/extend the tests under `t/` | `ansill-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `ansill-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the
main agent delegates rather than loading them. Skill sources live under
`.claude/skills/`.

## Tests

```bash
prove -l t/               # the suite: 7 files, 107 tests
prove -lv t/05_parser.t   # one file, verbose
```

`prove -l` is mandatory: without it the installed `ANSILL` release is loaded
instead of `lib/`. `dzil build` and `dzil test` currently abort — the
distribution has no `LICENSE` file yet.

## Skills

| Skill | Source | Purpose |
|---|---|---|
| `ansill-core` | this repository | project knowledge — architecture, language surface, known drift |
| `getty-perl-core`, `getty-perl-moo`, `getty-perl-distribution`, `getty-git-commit-style`, `getty-git-usage`, `perl-release-dist-ini` | installed by `skilletor` | shared library conventions |
| `kanban-issues-karr-coordination`, `kanban-issues-karr-ticket` | installed by `skilletor` | the karr board |

The installed skills are build artefacts of `skilletor sync` — never edit them
here; change the source.
