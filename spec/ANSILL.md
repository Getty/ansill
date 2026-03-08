# ANSILL Specification v0.2

**ANSILL** stands for **ANSI Layout Language**.

ANSILL is a declarative language for generating textmode art and terminal-oriented
visual layouts. It compiles into multiple output targets:

* classic ANSI / `.ans`
* plain ASCII text
* UTF-8 terminal text
* CP437 grid exports
* JSON cell grids
* HTML preview
* PNG preview images

The core design goal: **separate intent from rendering mechanics**.

Authors describe scenes structurally. A compiler renders them according to a
selected target profile. No raw escape sequences in source.

---

## 1. Design Goals

1. Stable, human-readable, LLM-friendly authoring format
2. Support different visual expectations (ASCII, CP437, Unicode)
3. Deterministic compilation into a cell grid
4. Scene description separated from backend emission
5. Validation before output generation
6. Style portability across target capabilities
7. Support both handcrafted art and AI-generated content
8. Stateless command semantics (no implicit context changes between commands)

---

## 2. Compilation Pipeline

An ANSILL document is compiled in these stages:

1. **Parse** source into AST
2. **Resolve** declarations, symbols, styles, palettes, profiles, macros
3. **Render** commands into an internal 2D cell grid
4. **Validate** against target constraints and degradation policy
5. **Emit** target output

---

## 3. Internal Cell Model

The internal grid consists of cells:

```
Cell {
  glyph       # displayed character or abstract glyph name
  fg          # foreground color
  bg          # background color
  bold        # boolean
  dim         # boolean
  italic      # boolean
  underline   # boolean
  blink       # boolean
  inverse     # boolean
  protect     # boolean, prevents overwrite by later commands
  layer       # layer name (for compositing)
  tag         # optional metadata tag
}
```

---

## 4. Terminology

**Canvas**: Fixed-size 2D cell space with defined dimensions.

**Glyph**: A displayed character token. May be a literal character or an
abstract glyph name that maps to different characters per profile.

**Profile**: Defines allowed glyph repertoire and rendering constraints.

**Backend**: Converts the rendered grid into output format (ANSI, plain text,
JSON, HTML, PNG).

**Style**: Named bundle of visual properties (colors, emphasis, line set).

**Symbol**: Named reusable drawing fragment.

**Layer**: Named compositing plane for z-ordering.

**Policy**: Degradation strategy when source features exceed target capabilities.

---

## 5. Lexical Rules

### 5.1 Encoding

ANSILL source files are UTF-8.

### 5.2 Comments

Line comments begin with `#`:

```ansill
# this is a comment
canvas 80x25  # inline comment
```

### 5.3 Identifiers

```
[A-Za-z_][A-Za-z0-9_-]*
```

### 5.4 Numbers

Integers are base-10. No other bases.

### 5.5 Strings

Double-quoted strings with backslash escaping:

```
"HELLO"
"He said \"hi\""
"Line one\nLine two"
"Tab\there"
```

Escape sequences: `\"` `\\` `\n` `\t`

### 5.6 Coordinates

Point: `x,y` (1-based, no spaces around comma)

Rectangle: `x1,y1 x2,y2`

Size: `WxH` (e.g. `80x25`)

### 5.7 Key-Value Arguments

Commands accept positional arguments followed by optional `key=value` pairs:

```
command arg1 arg2 key=value key=value
```

Values that contain spaces must be quoted:

```
text 4,2 "HELLO WORLD" fg=15 bg=1
```

### 5.8 Block Syntax

Some declarations use braces for multi-line bodies:

```
keyword name {
  statement
  statement
}
```

Opening brace must be on the same line as the keyword.
Closing brace must be alone on its line (ignoring whitespace and comments).

---

## 6. Document Structure

A valid ANSILL document has this order:

1. Version declaration (required, must be first non-comment line)
2. Canvas declaration (required)
3. Profile declaration (optional, defaults to `cp437`)
4. Colors declaration (optional, defaults to `ansi16`)
5. Policy declaration (optional, defaults to `warn-fallback`)
6. Imports (optional)
7. Definitions (palettes, styles, symbols, macros, layers) in any order
8. Drawing commands in any order

### 6.1 Version

```ansill
ansill 0.2
```

Required. Must be the first non-comment statement. Compilers must reject
unsupported major versions and warn on newer minor versions.

### 6.2 Canvas

```ansill
canvas 80x25
```

Extended form:

```ansill
canvas 80x25 wrap=clip
```

`wrap` values: `clip` (default, silently clips), `error` (reject out-of-bounds),
`wrap` (wrap around).

### 6.3 Profile

```ansill
profile cp437
```

If omitted, defaults to `cp437`.

### 6.4 Colors

```ansill
colors ansi16
```

If omitted, defaults to `ansi16`.

### 6.5 Policy

```ansill
policy warn-fallback
```

Values: `strict`, `warn-fallback` (default), `best-effort`.

See Section 16 for full degradation semantics.

### 6.6 Import

```ansill
import "borders.ansill"
import "logo.ansill" as logo
```

Imports bring symbols, styles, palettes, and macros into scope. The `as` form
namespaces all imported names (e.g. `logo.main_border`).

Imports must not create circular dependencies.

---

## 7. Profiles

Profiles define glyph repertoire constraints.

### 7.1 Built-in Profiles

#### `ascii`

Strict printable ASCII (0x20-0x7E).

Box drawing uses `- | + / \`. Shading uses `. : # =`.

Recommended for maximum portability.

#### `cp437`

Full CP437 character set. Box drawing, block elements, shading characters.

Recommended for classic ANSI art and BBS output.

#### `unicode`

Safe subset of Unicode for modern terminals. Includes Box Drawing (U+2500),
Block Elements (U+2580), and Geometric Shapes (U+25A0) blocks.

Recommended for modern terminal output.

### 7.2 Custom Profiles

```ansill
profile mybbs extends cp437 {
  allow "█▓▒░│─┌┐└┘╔╗╚╝"
  deny "☺☻♥♦"
}
```

### 7.3 Profile Color Constraints

Profiles may restrict color models:

```ansill
profile retrobbs extends cp437 {
  colors ansi16
}
```

---

## 8. Color Model

### 8.1 Color Systems

* `mono` - no color
* `ansi16` - standard 16 ANSI colors (8 normal + 8 bright)
* `xterm256` - 256-color palette
* `truecolor` - 24-bit RGB

### 8.2 ANSI16 Color Names

Foreground/background names:

| Index | Name            | Bright variant    |
|-------|-----------------|-------------------|
| 0     | `black`         | `bright-black`    |
| 1     | `red`           | `bright-red`      |
| 2     | `green`         | `bright-green`    |
| 3     | `yellow`        | `bright-yellow`   |
| 4     | `blue`          | `bright-blue`     |
| 5     | `magenta`       | `bright-magenta`  |
| 6     | `cyan`          | `bright-cyan`     |
| 7     | `white`         | `bright-white`    |

Bright variants are indices 8-15.

### 8.3 Color Literals

```ansill
fg=14              # by index
fg=bright-cyan     # by name
fg=#ffaa00         # hex RGB (truecolor)
bg=1               # by index
bg=red             # by name
```

### 8.4 Color Degradation

When the target cannot represent a color, the compiler maps to the nearest
supported color. Truecolor degrades to xterm256 by nearest distance, xterm256
degrades to ansi16 by nearest match.

---

## 9. Abstract Glyph Names

Authors can reference glyphs by abstract name instead of literal character.
The compiler maps abstract names to concrete glyphs based on the active profile.

### 9.1 Lines and Boxes

| Abstract Name | ascii | cp437  | unicode |
|---------------|-------|--------|---------|
| `line-h`      | `-`   | `─`    | `─`     |
| `line-v`      | `\|`  | `│`    | `│`     |
| `corner-tl`   | `+`   | `┌`    | `┌`     |
| `corner-tr`   | `+`   | `┐`    | `┐`     |
| `corner-bl`   | `+`   | `└`    | `└`     |
| `corner-br`   | `+`   | `┘`    | `┘`     |
| `tee-up`      | `+`   | `┴`    | `┴`     |
| `tee-down`    | `+`   | `┬`    | `┬`     |
| `tee-left`    | `+`   | `┤`    | `┤`     |
| `tee-right`   | `+`   | `├`    | `├`     |
| `cross`       | `+`   | `┼`    | `┼`     |

Double-line variants use `d-` prefix: `d-line-h`, `d-corner-tl`, etc.

| Abstract Name  | ascii | cp437  | unicode |
|----------------|-------|--------|---------|
| `d-line-h`     | `=`   | `═`    | `═`     |
| `d-line-v`     | `\|`  | `║`    | `║`     |
| `d-corner-tl`  | `+`   | `╔`    | `╔`     |
| `d-corner-tr`  | `+`   | `╗`    | `╗`     |
| `d-corner-bl`  | `+`   | `╚`    | `╚`     |
| `d-corner-br`  | `+`   | `╝`    | `╝`     |

### 9.2 Shading and Blocks

| Abstract Name      | ascii | cp437  | unicode |
|---------------------|-------|--------|---------|
| `shade-light`       | `.`   | `░`    | `░`     |
| `shade-medium`      | `:`   | `▒`    | `▒`     |
| `shade-dark`        | `#`   | `▓`    | `▓`     |
| `block-full`        | `#`   | `█`    | `█`     |
| `block-half-top`    | `~`   | `▀`    | `▀`     |
| `block-half-bottom` | `_`   | `▄`    | `▄`     |
| `block-half-left`   | `[`   | `▌`    | `▌`     |
| `block-half-right`  | `]`   | `▐`    | `▐`     |

### 9.3 Decorative

| Abstract Name  | ascii | cp437 | unicode |
|----------------|-------|-------|---------|
| `bullet`       | `*`   | `∙`   | `•`     |
| `diamond`      | `*`   | `♦`   | `◆`     |
| `arrow-left`   | `<`   | `◄`   | `◀`     |
| `arrow-right`  | `>`   | `►`   | `▶`     |
| `arrow-up`     | `^`   | `▲`   | `▲`     |
| `arrow-down`   | `v`   | `▼`   | `▼`     |

### 9.4 Explicit Glyph Pinning

If the author uses a literal character, the compiler preserves it unless
forbidden by the target profile:

```ansill
put 10,10 glyph="█"
```

In `ascii` profile with `strict` policy: validation error.
In `ascii` profile with `warn-fallback`: warning, replaced by `#`.

---

## 10. Palette

Named color sets for semantic color usage:

```ansill
palette retro {
  primary   = bright-cyan
  accent    = bright-yellow
  danger    = bright-red
  bg-main   = blue
  subtle    = bright-black
}
```

Usage:

```ansill
text 3,2 "HELLO" fg=primary bg=bg-main
```

Palette names follow identifier rules. Palette references are resolved at
compile time.

---

## 11. Styles

Styles bundle visual properties:

```ansill
style titlebar {
  fg = bright-white
  bg = blue
  bold = true
}

style frame {
  fg = bright-cyan
  line-set = single
}

style heavy-frame {
  fg = bright-yellow
  line-set = double
}
```

### 11.1 Line Sets

The `line-set` property selects abstract line glyph variants:

* `ascii` - ASCII characters only (`- | +`)
* `single` - single-line box drawing (default)
* `double` - double-line box drawing
* `round` - rounded corners (where profile supports it, otherwise degrades to single)

Line sets are used by `box`, `line`, and `panel` commands.

### 11.2 Style Usage

```ansill
text 2,1 "MY BOARD" style=titlebar
box 1,1 80,25 style=frame
```

Style properties can be overridden inline:

```ansill
text 2,1 "MY BOARD" style=titlebar fg=bright-yellow
```

---

## 12. Drawing Commands

All drawing commands are stateless. Each command fully specifies its visual
properties (or inherits from a referenced style). There is no implicit
"current color" or "current position".

### 12.1 `put`

Write a single cell:

```ansill
put 10,5 glyph="A" fg=bright-white bg=blue
put 20,5 glyph=diamond fg=bright-yellow
```

### 12.2 `text`

Write a string at position:

```ansill
text 4,2 "WELCOME TO THE BBS" fg=bright-white bg=blue
text 40,2 "CENTERED" fg=bright-white align=center
```

Options:
* `align=left|center|right` - text alignment relative to the x coordinate.
  `center`: x is the center point. `right`: x is the right edge.
* `clip=true|false` - clip text at canvas edge (default: true)
* `transparent=true|false` - spaces in text do not overwrite cells (default: false)

### 12.3 `fill`

Fill a rectangle:

```ansill
fill 1,1 80,25 glyph=" " fg=white bg=black
fill 3,8 30,10 glyph=shade-light fg=green bg=black
```

### 12.4 `line`

Draw a horizontal or vertical line:

```ansill
line 1,1 80,1 style=single fg=bright-cyan
line 5,3 5,20 style=double fg=bright-yellow
```

Lines must be orthogonal (horizontal or vertical). Diagonal lines are not
supported in this version.

The compiler selects appropriate line glyphs from the profile based on the
line-set (defaulting to `single`).

### 12.5 `box`

Draw a rectangular border:

```ansill
box 1,1 80,25 style=double fg=bright-cyan bg=blue
```

The `style` on box selects line-set: `ascii`, `single`, `double`, `round`.

The `bg` fills the interior. If no `bg` is specified, interior is not filled
(transparent).

### 12.6 `panel`

High-level convenience: box with optional title:

```ansill
panel 3,8 30,14 style=single title="STATUS" fg=bright-green bg=black
```

Title is rendered on the top border. Title position can be controlled:

```ansill
panel 3,8 30,14 style=single title="STATUS" title-align=center fg=bright-green
```

`title-align`: `left` (default), `center`, `right`.

### 12.7 `repeat`

Repeat a pattern string across a horizontal span:

```ansill
repeat 3,9 28,9 pattern="-=" fg=bright-yellow
```

The pattern tiles left-to-right, clipped at the end coordinate.

### 12.8 `blit`

Stamp a named symbol at a position:

```ansill
blit logo at 40,12
blit logo at 40,12 transparent=true
```

### 12.9 `clear`

Reset a region to default (space, default colors):

```ansill
clear 1,1 80,25
```

---

## 13. Layers

Layers provide z-ordering for compositing.

### 13.1 Declaration

```ansill
layer background
layer chrome
layer content
```

Layers are rendered bottom-to-top in declaration order.

### 13.2 Usage

Each drawing command can specify its layer:

```ansill
fill 1,1 80,25 glyph=shade-light fg=blue bg=black layer=background
box 1,1 80,25 style=double fg=bright-cyan layer=chrome
text 5,5 "Hello" fg=bright-white layer=content
```

If no `layer` is specified, commands render to a default implicit layer that
sits above all declared layers.

### 13.3 Compositing

Later layers overwrite earlier layers cell-by-cell. If a cell in a higher
layer has `transparent=true` and its glyph is a space, the lower layer shows
through.

A cell with `protect=true` cannot be overwritten by higher layers.

---

## 14. Symbols

Named reusable drawing fragments:

### 14.1 Definition

```ansill
symbol logo 11x2 {
  text 1,1 "XX╗  XX╗XX╗"
  text 1,2 "XX║  XX║XX║"
}
```

The size (`11x2`) defines the symbol's local coordinate space.

### 14.2 Profile-Aware Variants

```ansill
symbol divider 18x1 {
  variant ascii {
    text 1,1 "+----------------+"
  }
  variant cp437 {
    text 1,1 "┌────────────────┐"
  }
}
```

Compiler picks the best matching variant.

---

## 15. Macros

Macros allow parameterized drawing sequences:

### 15.1 Definition

```ansill
macro titled_box x1 y1 x2 y2 title {
  box $x1,$y1 $x2,$y2 style=single fg=bright-cyan
  text $x1+2,$y1 "$title" fg=bright-white
}
```

Parameters are referenced with `$name`. Arithmetic on parameters is supported.

### 15.2 Invocation

```ansill
titled_box 2 2 40 10 "SYSTEM STATUS"
```

---

## 16. Degradation Policy

Controls compiler behavior when source features exceed target capabilities.

### 16.1 `strict`

Unsupported glyphs, colors, or features are errors. Compilation stops.

### 16.2 `warn-fallback`

Compiler emits warnings and substitutes nearest supported representation.
This is the default.

### 16.3 `best-effort`

Compiler silently maps to the best available approximation.

### 16.4 Example

Source:

```ansill
fill 1,1 10,1 glyph=block-full
```

Results:
* `cp437`: `██████████`
* `ascii` + `warn-fallback`: `##########` (with warning)
* `ascii` + `strict`: error

---

## 17. Expressions

Minimal expression system for computed positions:

```ansill
let mid = 40
let margin = 3
text $mid,$margin "CENTER"
text $margin+2,$margin+4 "OFFSET"
```

Supported operators: `+ - * /`, parentheses, `min()`, `max()`.

All expressions evaluate to integers (floor division).

---

## 18. SAUCE Metadata

Optional metadata for ANSI backend:

```ansill
meta title = "WELCOME"
meta author = "Getty"
meta group = "HI"
meta date = "2026-03-05"
```

Metadata is only emitted by backends that support it (e.g., ANSI with SAUCE).

---

## 19. AI Generation Guidelines

ANSILL is explicitly designed as an LLM target language.

### 19.1 Recommended Safe Subset

For AI generation, prefer this command subset:

* `ansill`, `canvas`, `profile`, `colors`, `policy`
* `palette`, `style`
* `fill`, `box`, `text`, `panel`, `repeat`, `put`
* `blit` (with pre-defined symbols)

Avoid in AI output: `macro`, `import`, complex expressions.

### 19.2 Best Practices for AI

1. Always emit `ansill`, `canvas`, `profile` declarations
2. Use abstract glyph names over literal special characters
3. Use named styles for consistent appearance
4. Use palette colors for semantic color usage
5. Keep coordinates within canvas bounds
6. Prefer `panel` over manual `box` + `text` combinations

---

## 20. Validation

### 20.1 Structural Validation

* `ansill` version present and supported
* `canvas` declared
* All coordinates within canvas bounds (respecting `wrap` mode)
* All rectangles have x1 <= x2 and y1 <= y2
* All referenced styles, symbols, palettes exist
* No circular imports
* No duplicate definitions

### 20.2 Profile Validation

* Literal glyphs allowed in current profile
* Line sets available or degradable
* Colors supported or degradable

### 20.3 Diagnostic Levels

* `error` - compilation must stop
* `warning` - compilation continues with fallback
* `note` - informational

---

## 21. Backend Model

### 21.1 `ansi`

Classic ANSI text with SGR escape sequences.

Options:
* `sgr-mode=16color|256color|truecolor`
* `optimize=none|sgr|cursor` (SGR dedup, cursor movement optimization)
* `sauce=true|false`

### 21.2 `plaintext`

Raw glyph grid, no escape sequences, no color.

### 21.3 `json`

Machine-readable cell grid. Each cell as object with glyph, fg, bg, attrs.

### 21.4 `html`

HTML table or span-based preview with CSS colors.

### 21.5 `png`

Rendered bitmap using a fixed-width font.

---

## 22. File Extension

Source: `.ansill`

Output extensions match the backend: `.ans`, `.txt`, `.json`, `.html`, `.png`

---

## 23. CLI Interface

Reference implementation CLI:

```
ansill compile input.ansill -o output.ans
ansill compile input.ansill -o output.ans --backend ansi --profile cp437
ansill compile input.ansill -o output.txt --backend plaintext --profile ascii
ansill validate input.ansill
ansill validate input.ansill --profile cp437 --policy strict
ansill info input.ansill   # show parsed metadata
```

---

## 24. Complete Example

```ansill
ansill 0.2
canvas 80x25
profile cp437
colors ansi16
policy warn-fallback

palette retro {
  title-fg = bright-white
  title-bg = blue
  border   = bright-cyan
  panel    = bright-green
  subtle   = bright-black
}

style titlebar {
  fg = title-fg
  bg = title-bg
  bold = true
}

layer background
layer chrome
layer content

fill 1,1 80,25 glyph=" " fg=white bg=black layer=background
box 1,1 80,25 style=double fg=border bg=title-bg layer=chrome
text 3,2 "WELCOME TO HANDY INTELLIGENCE" style=titlebar layer=content
panel 3,5 35,14 style=single title="STATUS" fg=panel bg=black layer=content
fill 5,7 20,12 glyph=shade-light fg=green bg=black layer=content
text 5,16 "[ESC] Quit" fg=subtle layer=content
```

### 24.1 Same Intent, ASCII Profile

```ansill
ansill 0.2
canvas 80x25
profile ascii
colors ansi16
policy warn-fallback

fill 1,1 80,25 glyph=" " fg=white bg=black
box 1,1 80,25 style=ascii fg=bright-cyan bg=blue
text 3,2 "WELCOME TO HANDY INTELLIGENCE" fg=bright-white bg=blue
panel 3,5 35,14 style=ascii title="STATUS" fg=bright-green bg=black
fill 5,7 20,12 glyph=shade-light fg=green bg=black
text 5,16 "[ESC] Quit" fg=bright-black
```

---

## 25. Future Extensions

Potential additions for future versions:

* Animation frames and timing
* Palette cycling
* Procedural effects (gradients, noise fills)
* Symbol packs / font imports
* Conditional rendering (`if profile == ascii`)
* Grid snapping and alignment constraints
* REXPaint tile backend
* Editor interchange format
* Regions (named coordinate rectangles)
