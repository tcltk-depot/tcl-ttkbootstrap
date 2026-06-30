# Automatic DPI Scaling

ttkbootstrap 1.4.2 scales automatically to any display — from a small laptop
screen to a large 4K HiDPI monitor — without any changes to your application
code.

## How scaling works

When `ttkbootstrap::Window` or `ttkbootstrap::setTheme` is called, the library
reads `tk scaling` to detect the current display DPI and computes an internal
scale factor:

| Display | DPI  | `tk scaling` | Scale factor |
|---------|------|-------------|--------------|
| Normal  | 96   | 1.334       | 1.0          |
| Laptop  | 120  | 1.668       | 1.3          |
| HiDPI   | 192  | 2.668       | 2.0          |
| 4K      | 288  | 4.002       | 3.0          |

Every pixel value in the package — padding, row heights, slider dimensions,
margins, dialog sizes, Meter canvas sizes — is multiplied by this factor before
being applied to the ttk style engine. Your application code uses baseline
96 dpi values; ttkbootstrap scales them transparently.

## What scales automatically

Everything provided by ttkbootstrap scales without any effort on your part:

- All `ttk::style` padding, borderwidth, rowheight, arrowsize, sliderlength
- Window and dialog sizes passed to `ttkbootstrap::Window`
- Meter, Floodgauge, and DateEntry widget dimensions
- Toast margins and wraplength
- Tooltip cursor offsets
- Treeview and Tableview column widths
- All gallery and demo applications

## Text scaling

Text scaling is handled differently depending on the widget type:

### ttk widgets (ttk::button, ttk::label, ttk::entry etc.)

On Tk 9, the ttk style engine drives text size through Tk's internal
DPI-aware font mechanism. Text in ttk widgets scales correctly on real HiDPI
hardware automatically. No action required.

### Classic Tk widgets (label, text, listbox, entry)

Classic widgets receive explicitly sized fonts via `option add`. ttkbootstrap
uses `_sf` to scale these font sizes with the display DPI. You get correct
text sizes automatically.

### Canvas text items

Canvas `create text` items use point sizes. Tk maps points to physical pixels
via `tk scaling`, so they scale correctly on real HiDPI hardware. Use plain
point sizes — **not** `_sf` — for canvas text.

```tcl
# Correct — Tk scales this to the right number of pixels
$canvas create text $x $y -text "Hello" -font {Helvetica 12}

# Wrong — double-scales at HiDPI
$canvas create text $x $y -text "Hello" \
    -font [list Helvetica [ttkbootstrap::_sf 12]]
```

## Writing HiDPI-aware code

If your application adds its own canvas items, places explicit pixel sizes, or
uses `pack`/`grid` with explicit pixel values, wrap those values with the
ttkbootstrap scaling helpers:

```tcl
package require ttkbootstrap

# Pixel dimensions on a canvas
canvas .c \
    -width  [ttkbootstrap::_sp 400] \
    -height [ttkbootstrap::_sp 300]

# Padding in pack/grid
pack .widget \
    -padx [ttkbootstrap::_sp 10] \
    -pady [ttkbootstrap::_sp 5]

# Font size on a classic widget or ttk widget with explicit -font
label .lbl -font [list Helvetica [ttkbootstrap::_sf 12]]
text  .txt -font [list Helvetica [ttkbootstrap::_sf 10]]

# Two-value padding list
ttk::frame .f -padding [ttkbootstrap::_sp2 10 5]

# Four-value padding list
ttk::frame .f -padding [ttkbootstrap::_sp4 10 5 10 5]
```

## Checking the scale factor

```tcl
set sf [ttkbootstrap::scaleFactor]   ;# 1.0 at 96dpi, 2.0 at 192dpi
```

## Refreshing after a monitor change

`setTheme` re-reads `tk scaling` every time it is called. If your application
needs to respond to the user moving the window to a different monitor, bind to
`<Configure>` and re-apply the current theme:

```tcl
bind . <Configure> [list apply {{} {
    ttkbootstrap::setTheme [ttkbootstrap::currentTheme]
}}]
```

## Limitations

- The scale factor is clamped to the range 1.0–4.0 (≈ 384 dpi maximum).
- Scaling requires a Tk window to exist so that `tk scaling` can be read.
  Calling `ttkbootstrap::_sp` or `_sf` before any window is created returns
  the unscaled value.
- On Xvfb and other virtual framebuffers the reported DPI is fixed regardless
  of `tk scaling`, so visual testing at non-native DPI requires a real display
  or a physical HiDPI screen.
