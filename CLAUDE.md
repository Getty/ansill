# ANSILL - ANSI Layout Language

Perl implementation of the ANSILL specification (v0.2).

## Project Structure

```
lib/ANSILL.pm                    # Main module, entry point
lib/ANSILL/Parser.pm             # Parse .ansill source into AST
lib/ANSILL/AST.pm                # AST node definitions
lib/ANSILL/Resolver.pm           # Resolve styles, palettes, symbols, macros, imports
lib/ANSILL/Grid.pm               # 2D cell grid
lib/ANSILL/Cell.pm               # Single cell (glyph, fg, bg, attrs)
lib/ANSILL/Profile.pm            # Profile definitions + abstract glyph mapping
lib/ANSILL/Profile/ASCII.pm      # ASCII profile
lib/ANSILL/Profile/CP437.pm      # CP437 profile
lib/ANSILL/Profile/Unicode.pm    # Unicode profile
lib/ANSILL/Color.pm              # Color parsing, naming, degradation
lib/ANSILL/Renderer.pm           # Render resolved AST into Grid
lib/ANSILL/Validator.pm          # Validate grid against profile/policy
lib/ANSILL/Backend/ANSI.pm       # ANSI escape sequence output
lib/ANSILL/Backend/PlainText.pm  # Plain text output
lib/ANSILL/Backend/JSON.pm       # JSON cell grid export
lib/ANSILL/Backend/HTML.pm       # HTML preview output
bin/ansill                       # CLI tool
spec/ANSILL.md                   # Language specification
```

## Build System

Uses Dist::Zilla with `[@Author::GETTY]` bundle.

## Testing

```bash
prove -l t/
prove -lv t/specific_test.t
```

## Dependencies

- Moo (lightweight OOP)
- Types::Standard
- JSON::MaybeXS (for JSON backend)
- MooX::Options (for CLI)
- namespace::autoclean
