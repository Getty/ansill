# ANSILL

ANSILL is the **ANSI Layout Language**: a small, line-oriented, declarative
language for text-mode layouts and terminal art, and its Perl compiler.

## Synopsis

```perl
use ANSILL;

my $source = <<'ANSILL';
ansill 0.2
canvas 30x7
profile ascii

panel 1,1 30,7 style=single title="INFO"
text 3,3 "Status: OK"
text 3,4 "Items: 42"
ANSILL

print ANSILL->new(source => $source, backend => 'plaintext')->compile;
```

```
+- INFO ---------------------+
|                            |
| Status: OK                 |
| Items: 42                  |
|                            |
|                            |
+----------------------------+
```

## Description

An ANSILL source describes a scene structurally: a canvas, a target profile,
palettes, styles and drawing commands. The compiler runs five stages, one
module each: parse, resolve, render, validate, emit. The renderer paints a 2D
grid of cells; a backend turns that grid into the output format. Sources carry
no raw escape sequences, so the same source can target different profiles
(`unicode`, `cp437`, `ascii`) and backends.

The language definition is `spec/ANSILL.md`; the sources under `examples/` show
the language in use.

## Perl API

### new

```perl
my $ansill = ANSILL->new(source => $text, backend => 'plaintext');
```

`source` is the ANSILL text. `backend` is one of `ansi` (default),
`plaintext`, `json` or `html`.

### compile

```perl
my $output = $ansill->compile;
```

Runs the full pipeline and returns the emitted output as a string.

### compile_file

```perl
my $output = ANSILL->compile_file('examples/panel_info.ansill', backend => 'html');
```

Reads a file (UTF-8) and compiles it in one call.

### validate

```perl
my $diagnostics = $ansill->validate;

for my $d (@$diagnostics) {
  printf "%s: %s\n", $d->{level}, $d->{message};
}
```

Returns an array reference of diagnostics, each with `level` and `message`
(and `line` where known).

## Command line

### compile

```bash
ansill compile examples/panel_info.ansill -b plaintext
ansill compile examples/welcome.ansill -o welcome.html
```

Compiles a file. Without `-b` the backend follows the extension of `-o`
(`.html`, `.json`, `.txt`, otherwise ANSI).

### validate

```bash
ansill validate examples/panel_info.ansill
```

Prints diagnostics and exits 1 when the source has errors.

### info

```bash
ansill info examples/panel_info.ansill
```

```
Canvas:  30x7
Profile: ascii
Colors:  ansi16
Policy:  warn-fallback
```

## License

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
