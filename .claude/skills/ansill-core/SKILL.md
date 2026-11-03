---
name: ansill-core
description: Load on any change to ansill — the ANSILL layout language compiler in Perl: the parser, resolver, renderer, validator, the three profiles, the four backends, the CLI, the dzil build and the test suite.
---

# ANSILL — project-specific architecture

## What ANSILL is

ANSILL is a declarative text-mode layout language: a small line-oriented
language that compiles to a 2D cell grid and is emitted as ANSI escape
sequences, plain text, JSON or HTML. The Perl distribution `ANSILL` implements
the language specification in `spec/ANSILL.md` (v0.2). The spec is the
reference for the **language**, this skill the reference for the
**implementation**.

## The pipeline

Five stages, one module each:

| Stage | Module | What it does |
|---|---|---|
| Parse | `ANSILL::Parser` | line-oriented source → AST (`ANSILL::AST`) |
| Resolve | `ANSILL::Resolver` | declarations → resolved draw commands |
| Render | `ANSILL::Renderer` | commands → `ANSILL::Grid` of `ANSILL::Cell` |
| Validate | `ANSILL::Validator` | AST and grid against profile and policy |
| Emit | `ANSILL::Backend::*` | grid → output text |

`ANSILL.pm` is the facade: `->new(source => ...)->compile` runs all five
stages, `->validate` returns the diagnostics instead of raising.

## Layout

| Path | Purpose |
|---|---|
| `lib/ANSILL.pm` | facade: `compile`, `validate`, `compile_file` |
| `lib/ANSILL/Parser.pm` | the parser, one `_parse_cmd_<name>` per command |
| `lib/ANSILL/AST.pm` | node classes, one package per node type |
| `lib/ANSILL/Resolver.pm` | palette, styles, symbols, macros, layers, variables |
| `lib/ANSILL/Renderer.pm` | one `_render_<type>` per drawing command |
| `lib/ANSILL/Grid.pm` | the 2D cell grid, bounds, wrap, writing text |
| `lib/ANSILL/Cell.pm` | one cell: glyph, fg, bg, the attribute flags |
| `lib/ANSILL/Color.pm` | color parsing, ANSI16 names, degradation to 16 colors |
| `lib/ANSILL/Profile.pm` | base profile, glyph map, line sets |
| `lib/ANSILL/Profile/{ASCII,CP437,Unicode}.pm` | the three built-in profiles |
| `lib/ANSILL/Validator.pm` | structural and profile validation, the policy |
| `lib/ANSILL/Backend/{ANSI,PlainText,JSON,HTML}.pm` | the four backends |
| `bin/ansill` | the CLI: `compile`, `validate`, `info`, `help` |
| `spec/ANSILL.md` | the language specification (v0.2) |
| `examples/*.ansill` | example documents |
| `t/expected/*.txt` | reference output of the examples |

## The cell model

A cell carries `glyph`, `fg`, `bg` and the flags `bold`, `dim`, `italic`,
`underline`, `blink`, `inverse`, `protect`, plus `layer` and `tag`. Coordinates
are **1-based**; the grid indexes them 0-based internally. `protect` keeps a
later command from overwriting the cell.

Colors are either an ANSI16 index (0–15) or an RGB hash — never a string.
`ANSILL::Color::parse_color` resolves numeric indices, `#rrggbb`, the ANSI16
names (`black` … `bright-white`) and palette references; anything else croaks.

## Profiles and line sets

| Profile | Glyph repertoire |
|---|---|
| `ascii` | printable ASCII only; the abstract glyphs degrade to `-`, `\|`, `+`, `=`, `#` … |
| `cp437` | the classic DOS/BBS set — the default |
| `unicode` | box drawing, blocks, shades and arrows as Unicode |

A profile maps **abstract glyph names** (`line-h`, `corner-tl`, `d-line-h`,
`shade-light`, `block-full`, `bullet`, `arrow-right` …) to concrete characters.
`resolve_glyph` maps a name through the profile; an unknown name stays as it
is. The **line sets** `ascii`, `single` and `double` pick the abstract names
for `box`, `line` and `panel`.

## The language in one screen

Declarations: `ansill <version>`, `canvas WxH [wrap=…]`, `profile`, `colors`,
`policy`, `palette`, `style`, `symbol`, `macro`, `layer`, `let`, `meta`,
`import`.

Drawing commands: `put X,Y`, `text X,Y "…"`, `fill X1,Y1 X2,Y2`, `line`,
`box`, `panel` (a box plus a title), `repeat` (fills with a pattern), `blit`
(a symbol), `clear`.

Key-value arguments are appended to a command: `fg=bright-yellow bg=blue
style=titlebar`. A dash in a key becomes an underscore in the attribute name.
`style=` on `box`, `line` and `panel` selects the **line set**, not a named
style; on every other command it names a style whose attributes are the
defaults and can be overridden inline.

## Backends and the CLI

| Backend | Output |
|---|---|
| `ansi` | SGR escape sequences, reset at every line end, optional SAUCE record |
| `plaintext` | the raw glyph grid, no colors |
| `json` | width, height and one object per cell |
| `html` | a `<pre>` preview with inline colors |

`bin/ansill compile FILE [-o OUT] [-b BACKEND]` guesses the backend from the
output extension. `ansill validate FILE` prints the diagnostics and exits 1 on
an error, `ansill info FILE` prints canvas, profile, colors, policy and the
meta block.

## Build and test

```bash
prove -l t/               # the suite: 7 files, 107 tests
prove -lv t/05_parser.t
dzil build                # the distribution build
dzil test                 # build plus test
```

`prove -l` is mandatory: without it the installed `ANSILL` release is loaded
instead of `lib/`. `t/20_examples.t` compiles every `examples/*.ansill` and
compares the result against `t/expected/<name>.txt` — **every change in the
rendering changes those reference files**, and they are only regenerated
deliberately.

**`dist.ini` and `cpanfile` drive the build.** `dist.ini` carries the metadata
header and the `[@Author::GETTY]` bundle; `cpanfile` holds the prerequisites,
which the bundle reads through `[Prereqs::FromCPANfile]`.

## House rules for this repository

- **Moo with `Types::Standard`** — the stack the code is written in; keep new
  classes on it.
- **`croak` for unusable input, not `die`** — the message names the offending
  value.
- **Attributes are `is => 'ro'` unless the object mutates itself** — `Cell`,
  `Grid` and the AST nodes pick `ro` or `rw` deliberately.
- **The pipeline reports through `diagnostics`**, a list of `{level, message}`
  — not through exceptions.
- **Do not change `spec/ANSILL.md` to match the implementation** — the spec is
  the language definition; changing it changes the language.

## Known drift — reported, not fixed

Facts about the current tree, found by reading it. Findings for the maintainer,
not work items to repair on the side.

- **`macro` is parsed and stored, but never invoked.** Nothing expands a macro
  in the resolver or the renderer.
- **`import` is parsed, not resolved** — the resolver carries a TODO, and the
  imported symbols, styles, palettes and macros never arrive.
- **`blit` renders nothing.** The renderer looks the symbol up and then
  discards its commands; the offset by the blit position is a TODO.
- **`layer` is declared and numbered, but never composited.** The cell has a
  `layer` attribute, no drawing command sets it, nothing z-orders it.
- **The `png` backend of the specification does not exist.**
- **The line set `round` of the specification is missing** from the profile's
  line-set table — `style=round` croaks with `Unknown line set`.
- **The canvas wrap mode `wrap` is missing** — the grid implements `clip` and
  `error`, `wrap` behaves like `clip`.
- **`--profile` and `--policy` on the CLI have no effect.** The options are
  parsed but never handed to the compiler; the profile and the policy come
  from the document.
