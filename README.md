# ttkbootstrap 1.5.0 — Native Tcl/Tk Package

A faithful Tcl/Tk port of [israel-dryer/ttkbootstrap](https://github.com/israel-dryer/ttkbootstrap).

Provides Bootstrap-inspired themes and styles for Tk/Ttk applications — no Python,
no Pillow, no pip. Pure Tcl.

---

## Files

```
ttkbootstrap/
├── ttkbootstrap.tcl   ← Main package (source this or put on auto_path)
├── pkgIndex.tcl       ← Tcl package index (for [package require])
├── everything_bagel.tcl ← Full widget demo
└── README.md
```

---

## Installation

Copy the `ttkbootstrap/` directory somewhere on your Tcl `auto_path`, for example:

```tcl
# Option A: add to auto_path at runtime
lappend auto_path /path/to/ttkbootstrap
package require ttkbootstrap

# Option B: source directly
source /path/to/ttkbootstrap/ttkbootstrap.tcl
```

---

## Quick Start

```tcl
package require ttkbootstrap

# Create a window first (required before styling)
wm title . "My App"

# Apply a theme
ttkbootstrap::setTheme flatly       ;# or superhero, darkly, cosmo, ...

# Use themed widgets via standard ttk style names
ttk::button .b1 -text "Primary"   -style "primary.TButton"
ttk::button .b2 -text "Success"   -style "success.TButton"
ttk::button .b3 -text "Outline"   -style "danger.Outline.TButton"
ttk::label  .l1 -text "Info text" -style "info.TLabel"

ttk::progressbar .pb -style "success.Horizontal.TProgressbar" \
    -value 75 -maximum 100 -orient horizontal

pack .b1 .b2 .b3 .l1 .pb -padx 8 -pady 4
```

---

## Available Themes

### Light
| Name       | Description                              |
|------------|------------------------------------------|
| cosmo      | Clean blue, inspired by Bootstrap        |
| flatly     | Dark navy flat design                    |
| litera     | Book-like, Georgia-inspired typography   |
| minty      | Fresh mint greens and pinks              |
| lumen      | Bright, luminous blues                   |
| sandstone  | Earthy blues and tan                     |
| yeti       | Teal and cool greys                      |
| pulse      | Deep purple, vibrant accent colours      |
| united     | Ubuntu orange and magenta                |
| morph      | Soft blue-grey neumorphic style          |
| journal    | Newspaper red, vintage feel              |
| simplex    | Red minimalism                           |
| cerculean  | Sky blue, cerulean tones                 |

### Dark
| Name       | Description                              |
|------------|------------------------------------------|
| darkly     | Dark blue-grey, green accents            |
| superhero  | Navy blue hero aesthetic                 |
| solar      | Solarized dark                           |
| cyborg     | Near-black, electric blue & green        |
| vapor      | Deep purple, neon vaporwave              |

---

## API Reference

### `ttkbootstrap::setTheme name`
Apply a theme to the current Tk application. Must be called after a Tk window exists.

```tcl
ttkbootstrap::setTheme superhero
```

### `ttkbootstrap::themeNames`
Returns a sorted list of all 18 theme names.

```tcl
ttkbootstrap::themeNames
# → cyborg cerculean cosmo darkly flatly journal litera lumen minty morph ...
```

### `ttkbootstrap::lightThemes` / `ttkbootstrap::darkThemes`
Returns only the light or dark theme names.

### `ttkbootstrap::getColors ?themeName?`
Returns the full color dict for a theme (defaults to current).

```tcl
array set c [ttkbootstrap::getColors flatly]
puts $c(primary)   ;# #2c3e50
puts $c(success)   ;# #18bc9c
```

### `ttkbootstrap::getColor key ?themeName?`
Returns a single hex color.

```tcl
ttkbootstrap::getColor primary superhero   ;# → #4c9be8
```

### `ttkbootstrap::bootstyle ?color? ?variant? ?widgetClass?`
Build a ttk style string from keyword args (Bootstrap-style API).

```tcl
ttkbootstrap::bootstyle success                    ;# → success.TButton
ttkbootstrap::bootstyle success outline            ;# → success.Outline.TButton
ttkbootstrap::bootstyle info TLabel                ;# → info.TLabel
ttkbootstrap::bootstyle warning Horizontal TProgressbar  ;# → warning.Horizontal.TProgressbar
```

---

## Widget Style Reference

All styles follow the pattern `{color}.{Variant}.{WidgetClass}`:

### Buttons
```tcl
ttk::button .b -style "primary.TButton"          ;# solid primary
ttk::button .b -style "success.TButton"          ;# solid success
ttk::button .b -style "danger.Outline.TButton"   ;# outline danger
```

### Labels
```tcl
ttk::label .l -style "info.TLabel"
ttk::label .l -style "warning.TLabel"
```

### Progress Bars
```tcl
ttk::progressbar .p -style "success.Horizontal.TProgressbar" \
    -orient horizontal -value 60 -maximum 100
ttk::progressbar .p -style "danger.Vertical.TProgressbar" \
    -orient vertical -value 30 -maximum 100
```

### Checkbutton / Radiobutton
```tcl
ttk::checkbutton .c -style "success.TCheckbutton" -variable myVar
ttk::radiobutton .r -style "info.TRadiobutton"    -variable myVar -value x
```

### Toggle Switches (Round — iOS style)
```tcl
ttkbootstrap::ToggleSwitch .ts \
    -text "Enable feature" \
    -variable myVar \
    -bootstyle success \
    -command { puts "toggled: $myVar" }
pack .ts
```

### Toggle Switches (Square)
```tcl
# Square toggle uses Square.TCheckbutton style
ttk::checkbutton .sq \
    -text "Wi-Fi" \
    -variable ::wifi \
    -style "primary.Square.TCheckbutton"
pack .sq
```

### Rounded Buttons
```tcl
ttk::button .rb -text "Rounded" -style "primary.Round.TButton"
ttk::button .ro -text "Outline" -style "success.Outline.Round.TButton"
pack .rb .ro -side left -padx 4
```

### Menubutton
```tcl
set mb [ttk::menubutton .mb -text "Options" -style "primary.TMenubutton"]
```

### Colors available for all widgets
`primary` `secondary` `success` `info` `warning` `danger` `light` `dark`

---

## Running the Demos

```bash
# Full widget showcase (recommended starting point)
./tclkit-9.0.3-Linux64-intel-tk gallery/showcase.tcl

# MDI desktop — run multiple apps as floating windows
./tclkit-9.0.3-Linux64-intel-tk gallery/mdi.tcl

# Single-file widget demo
./tclkit-9.0.3-Linux64-intel-tk everything_bagel.tcl
```

The showcase covers all 35+ widgets across 11 sections, with a live
theme switcher and a Gallery of standalone demo apps.

---

## Color Helper Utilities (internal, but usable)

```tcl
ttkbootstrap::_darken  "#375a7f" 20   ;# → darker hex
ttkbootstrap::_lighten "#375a7f" 20   ;# → lighter hex
ttkbootstrap::_contrastFg "#2780e3"   ;# → #ffffff or #212529
ttkbootstrap::_luminance "#2780e3"    ;# → 0.0–1.0
```

---

## Automatic DPI Scaling

ttkbootstrap scales automatically to any display — from a small laptop
screen to a large 4K monitor — with no changes to your application code.

### How it works

When you call `ttkbootstrap::Window` or `ttkbootstrap::setTheme`, the library
reads `tk scaling` to determine the current display DPI and sets an internal
scale factor (1.0 at 96 dpi, 2.0 at 192 dpi, and so on). Every pixel-valued
style attribute — padding, row heights, font sizes, slider dimensions, widget
margins — is multiplied by this factor before being applied to the ttk style
engine.

You do not need to do anything. Just use normal values in your code:

```tcl
# These values are in design pixels (96 dpi baseline).
# ttkbootstrap scales them automatically at runtime.
ttkbootstrap::Window -themename flatly -title "My App" -size {800 600}

ttkbootstrap::Meter .m -metersize 200 -amountused 75 -bootstyle success
pack .m
```

On a 192 dpi (2×) display the window opens at 1600×1200, the Meter canvas is
400 px wide, and all padding and fonts are doubled — without any extra code.

### Scaling helpers (advanced use)

If you write your own widgets or place items on a canvas, use these helpers to
keep your sizes consistent with the rest of the UI:

```tcl
# Scale a pixel value to the current DPI
ttkbootstrap::_sp 10       ;# → 10 at 1×, 20 at 2×, 30 at 3×

# Scale a font point size (for explicit -font on classic or canvas widgets)
ttkbootstrap::_sf 10       ;# → 10 at 1×, 20 at 2×, 30 at 3×

# Scale a two-value padding list
ttkbootstrap::_sp2 10 5    ;# → {10 5} at 1×, {20 10} at 2×

# Scale a four-value padding list
ttkbootstrap::_sp4 10 5 10 5  ;# → {10 5 10 5} at 1×, {20 10 20 10} at 2×

# Read the current scale factor
ttkbootstrap::scaleFactor  ;# → 1.0 at 96 dpi, 2.0 at 192 dpi
```

> **Important — canvas text fonts:** If you draw text on a `canvas` widget,
> use plain point sizes (not `_sf`). Tk scales canvas point sizes to physical
> pixels automatically via `tk scaling`. Using `_sf` on a canvas font would
> double-scale the text.
>
> ```tcl
> # CORRECT: plain point size on canvas — Tk handles DPI
> $canvas create text $x $y -text "Hello" -font {Helvetica 12}
>
> # WRONG: _sf on canvas text — double-scaled at HiDPI
> $canvas create text $x $y -text "Hello" -font [list Helvetica [ttkbootstrap::_sf 12]]
>
> # CORRECT: _sf on a classic label or text widget — explicit size needed
> label .lbl -text "Hello" -font [list Helvetica [ttkbootstrap::_sf 12]]
> ```

### Responding to DPI changes

`ttkbootstrap::setTheme` always re-reads `tk scaling` before applying styles,
so if the user moves the window to a display with a different DPI you can
simply call `setTheme` again with the current theme name to refresh all styles:

```tcl
bind . <Configure> [list apply {{} {
    # Re-apply theme when window moves to a different monitor
    ttkbootstrap::setTheme [ttkbootstrap::currentTheme]
}}]
```

---

## Requirements

- Tcl/Tk **9.0** or newer (tclkit 9.0.3 recommended)
- No external dependencies

---

## License

MIT License — see [LICENSE](LICENSE) for full text.

```
Copyright (c) 2021 - 2026 Israel Dryer (original Python library)
```

This project is a Tcl/Tk port of
[ttkbootstrap](https://github.com/israel-dryer/ttkbootstrap) by Israel Dryer.
The MIT License allows free use, modification, and redistribution provided the
copyright notice and license text are included in all copies.
