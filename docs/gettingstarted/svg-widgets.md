# SVG Widgets Guide

## What Are SVG Widgets?

SVG widgets use Tk 9's native SVG rendering to draw crisp, resolution-independent
UI elements. Unlike bitmap-based widgets, SVG widgets look perfect at any DPI —
from 96dpi laptops to 4K HiDPI monitors.

## Architecture

All SVG widgets follow the same pattern:

1. **No text in SVG** — font names with spaces break Tk's SVG parser. Text is
   always drawn via Tk labels or canvas text items.
2. **`-compound center`** — text overlaid on SVG images using `label -image -compound center`.
   This clips text to the image bounds with no rectangular background leaking.
3. **`<<ThemeChanged>>` binding** — every SVG widget regenerates its SVG images
   when the theme changes, using `ttkbootstrap::getColor` for fresh colours.
4. **`_sp`/`_sf` scaling** — all pixel sizes use `_sp` and font sizes use `_sf`
   for automatic DPI scaling.

## SVG vs Original

| Feature | Original | SVG |
|---------|----------|-----|
| Rendering | Native ttk | SVG images via Tk 9 |
| Corners | Square (Tk limitation) | Rounded (`rx`/`ry`) |
| DPI | Scales via `_sp`/`_sf` | Crisp at any DPI natively |
| Theme | Via ttk style maps | Regenerates SVG on change |
| Text | Native ttk labels | `-compound center` overlay |

## Creating Your Own SVG Widget

```tcl
proc MySVGWidget {w args} {
    array set o {-bootstyle primary -text ""}
    array set o $args

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    set fg  [ttkbootstrap::_contrastFg $hex]
    set bg  [ttkbootstrap::getColor bg]

    # Build SVG
    set W [ttkbootstrap::_sp 100]
    set H [ttkbootstrap::_sp 30]
    set r [ttkbootstrap::_sp 6]
    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'>"
    append svg "<rect x='0' y='0' width='$W' height='$H' rx='$r' ry='$r' fill='$hex'/>"
    append svg "</svg>"

    # Create image
    image create photo ${w}::img -data $svg -format {svg}

    # Single label with image + text overlay
    label $w -image ${w}::img -text $o(-text) -compound center \
        -fg $fg -bg $bg -bd 0

    # Respond to theme changes
    bind $w <<ThemeChanged>> [list MySVGWidget_retheme $w]
    return $w
}
```

## Limitations

- **No SVG filters** — Tk 9's nanosvg renderer doesn't support `<filter>`,
  `<feGaussianBlur>`, `<feDropShadow>`, or other filter effects.
- **No SVG gradients** — `<linearGradient>` and `<radialGradient>` may not
  render correctly in all Tk builds.
- **No SVG text** — font names with spaces break parsing. Always use Tk's
  own text rendering.
- **No SVG `<clipPath>`** — may be ignored by nanosvg. Use overlapping shapes
  instead (as done in SVGCard headers).
