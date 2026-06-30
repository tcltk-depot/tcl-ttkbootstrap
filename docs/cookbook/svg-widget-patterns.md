# SVG Widget Patterns

The SVG-based widgets in ttkbootstrap (buttons, toggles, search bars, cards,
notification banners, theme swatches, …) all render a small SVG to a Tk photo
image with `image create photo … -format svg`. That approach is powerful but
has a few sharp edges that are easy to get wrong. This page collects the
patterns the widget set uses internally, as minimal standalone snippets you can
copy. The live, fully wired versions are in
[`gallery/showcase.tcl`](../../gallery/showcase.tcl).

---

## 1. Rounded corners without black/white "tips"

**Problem.** nanosvg (the SVG renderer behind `-format svg`) fills the area
*outside* a rounded shape with transparency. When that image is shown on a Tk
widget, the transparent corner pixels composite against whatever is behind them
— which often reads as a black or white square "tip" poking out past the
rounded edge, especially on a contrasting background.

**Two reliable fixes.**

### (a) Keep corners transparent, match the host background

Best when the image sits on a `canvas`, `frame`, or `toplevel` whose `-bg` you
control. Leave the SVG corners transparent and set the host background to the
surrounding colour, so the corners simply show that colour.

```tcl
# A pill-shaped track on a canvas. No background rect in the SVG, so the
# corners stay transparent and the canvas -bg shows through them.
set svg "<svg xmlns='http://www.w3.org/2000/svg' width='44' height='22'>"
append svg "<rect x='1' y='1' width='42' height='20' rx='10' ry='10' fill='#4582ec'/>"
append svg "</svg>"
image create photo track -data $svg -format svg

canvas .c -width 44 -height 22 -highlightthickness 0 -bd 0 \
    -bg [ttkbootstrap::getColor bg]   ;# corners show this colour
.c create image 0 0 -image track -anchor nw
pack .c
```

### (b) Paint the background colour *into* the image

Best when the image sits on a `label` (which can't easily be made transparent),
or when the surface colour is fixed. Draw a full-canvas rect in the surface
colour **behind** the rounded shape, so the antialiased corner blends
`shape-colour → surface-colour` inside the image itself.

```tcl
set W 120; set H 44; set r 6
set surface [ttkbootstrap::getColor bg]
set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'>"
append svg "<rect x='0' y='0' width='$W' height='$H' fill='$surface'/>"   ;# behind
append svg "<rect x='0' y='0' width='$W' height='$H' rx='$r' ry='$r' fill='#fff' stroke='#ccc'/>"
append svg "</svg>"
image create photo swatch -data $svg -format svg

# Use -bd 0 on the host label: a square border would re-expose the corners.
label .l -image swatch -bd 0 -highlightthickness 0 -bg $surface
pack .l
```

> Rule of thumb: never put a `-relief solid`/`-bd 1` border around a rounded
> SVG image — the square border frames exactly the corner gaps you are trying
> to hide.

---

## 2. Cached SVG images and live theme changes

**Problem.** An `image create photo` from SVG is a *snapshot*: it bakes in
whatever theme colours were current when it was created. Switching the theme
fires the virtual event `<<ThemeChanged>>`, and ttk widgets restyle
automatically — but a cached photo does **not**. Its colours (including any
background colour painted in via pattern 1b) go stale, which is the usual cause
of "white corner tips appear after I switch to a dark theme".

**Fix.** Rebind `<<ThemeChanged>>` on the hosting widget and regenerate the
image with the new theme colours.

```tcl
proc make_swatch {theme} {
    set surface [ttkbootstrap::getColor bg]
    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='110' height='40'>"
    append svg "<rect x='0' y='0' width='110' height='40' fill='$surface'/>"
    append svg "<rect x='0' y='0' width='110' height='40' rx='6' ry='6' \
                 fill='[dict get [ttkbootstrap::getColors $theme] bg]'/>"
    append svg "</svg>"
    return [image create photo _sw_$theme -data $svg -format svg]
}

label .l -image [make_swatch litera] -bd 0 -bg [ttkbootstrap::getColor bg]
pack .l

# Regenerate whenever the live theme changes, so corners keep matching the page.
bind .l <<ThemeChanged>> {
    .l configure -image [make_swatch litera] -bg [ttkbootstrap::getColor bg]
}
```

If your widget instead reads `ttkbootstrap::getColor …` *every time it draws*
(rather than caching), you only need to trigger a redraw on `<<ThemeChanged>>`
— there is no stale snapshot to rebuild.

---

## 3. A popup that slides in from a window edge

**Problem.** You want a notification to slide in from the side of your
application window. A separate `toplevel` cannot be clipped by another window,
so animating one in from off-window just shows it floating in empty space next
to the app; starting it inside the window means it never looks "hidden first".

**Fix.** Render the popup as a `place`-managed **child** of the frame you want
it to emerge from. That frame clips anything outside its bounds, so you can
start the child fully off the edge (hidden) and animate its `place -x` inward.

```tcl
# $parent is, e.g., your main content frame.
proc slide_in {parent} {
    set f $parent.banner
    catch { destroy $f }
    label $f -text "  Saved!  " -bg "#28a745" -fg white -padx 16 -pady 12
    update idletasks

    set pw [winfo width $parent]
    set bw [winfo reqwidth $f]
    set pad 20
    set target [expr {$pw - $bw - $pad}]   ;# resting position
    set start  $pw                          ;# just off the right edge (clipped)

    place $f -x $start -y $pad
    raise $f
    _slide $f $start $target $pad 0 14
    after 2500 [list catch [list destroy $f]]
}

proc _slide {f start target y step steps} {
    if {![winfo exists $f]} return
    if {$step >= $steps} { place $f -x $target -y $y; return }
    set t    [expr {($step + 1.0) / $steps}]
    set ease [expr {1.0 - (1.0 - $t) * (1.0 - $t)}]   ;# ease-out
    place $f -x [expr {int($start + ($target - $start) * $ease)}] -y $y
    after 16 [list _slide $f $start $target $y [expr {$step + 1}] $steps]
}
```

`ttkbootstrap::SVGNotificationBanner::show` implements exactly this when you
pass it `-parent <frame>`; without `-parent` it falls back to a floating
toplevel. In the showcase it is parented to the page area (below the title bar)
so it does not cover the theme controls.

---

## 4. Always scale sizes — never hard-code pixels

Every size in a ttkbootstrap UI should pass through the scaling helpers so it
looks right on HiDPI displays and large desktops:

| Helper | Use for | Example |
|--------|---------|---------|
| `ttkbootstrap::_sp N` | a single pixel size (padding, width, radius) | `-padx [ttkbootstrap::_sp 16]` |
| `ttkbootstrap::_sp2 a b` | a `{pad pad}` pair | `-pady [ttkbootstrap::_sp2 14 4]` |
| `ttkbootstrap::_sf N` | a font point size | `-font [list $fn [ttkbootstrap::_sf 12]]` |

When you build an SVG, scale its `width`/`height`/`rx` the same way, then the
rendered image matches the rest of the UI at any DPI.

---

## 5. Anatomy of a `build_` proc

The showcase is organised as one `build_<section>` proc per sidebar entry, all
following the same shape. Understanding one teaches you all of them. Here is
`build_buttons` (from [`gallery/showcase.tcl`](../../gallery/showcase.tcl)),
trimmed to its skeleton and annotated.

```tcl
proc build_buttons {f} {
    # (1) Get a scrollable interior to build into. page_sf wraps $f in a
    #     ScrolledFrame and returns its interior frame. ALWAYS add your widgets
    #     to $p, never to $f directly, so long pages scroll.
    set p [page_sf $f]

    # (2) Introduce each group with a section header (bold title + grey sub).
    section_hdr $p "Buttons (Original)" \
        "Every bootstyle variant shown in solid, outline, and link modes."

    # (3) Lay out the widgets. Build rows as frames packed -fill x; pack the
    #     widgets inside them -side left. Every size goes through _sp / _sp2.
    foreach bs {primary secondary success info warning danger light dark} {
        set row [ttk::frame $p.br$bs -padding [ttkbootstrap::_sp2 16 3]]
        pack $row -fill x
        foreach {variant suffix} {Solid "" Outline ".Outline" Link ".Link"} {
            # bootstyle + variant compose into a ttk style name: e.g.
            #   primary.TButton   primary.Outline.TButton   primary.Link.TButton
            # (use a plain word like $variant in the widget PATH — a Tk path
            #  cannot contain the dots that appear in the style name.)
            ttk::button $row.b$variant \
                -text    $variant \
                -style   "${bs}${suffix}.TButton" \
                -padding [ttkbootstrap::_sp2 10 4] \
                -command [list ttkbootstrap::StatusBar::msg $::sbbar \
                    "Button: $bs $variant" -clear 2000]    ;# (4) status-bar feedback
            pack $row.b$variant -side left -padx [ttkbootstrap::_sp 3]
        }
    }

    # (5) Separate groups with ONE horizontal separator, then the next header.
    ttk::separator $p.sep_sb -orient horizontal
    pack $p.sep_sb -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Square Buttons (SVG — New)" \
        "SVG-rendered buttons with square corners."

    # (6) For SVG widgets that you create in a loop, name them with an
    #     incrementing counter so several can coexist (.sb1, .sb2, ...). The
    #     counter (here ::svg_idx) MUST be in the reset list in show_page, or
    #     the widgets will accumulate every time the page is revisited.
    set sqbrow [ttk::frame $p.sqbrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $sqbrow -fill x
    foreach bs {primary success info warning danger secondary} {
        ttkbootstrap::SVGButton $sqbrow.sb[incr ::svg_idx] \
            -text [string totitle $bs] -bootstyle $bs -radius 0 \
            -command [list ttkbootstrap::StatusBar::msg $::sbbar \
                "Square SVG: $bs" -clear 2000]
        pack $sqbrow.sb$::svg_idx -side left -padx [ttkbootstrap::_sp 4]
    }

    # ... more groups, each: separator -> section_hdr -> rows of widgets ...
}
```

### The seven conventions every `build_` proc follows

1. **Start with `set p [page_sf $f]`** and build into `$p`, so the page scrolls.
2. **One `section_hdr` per group**, with a one-line description as the subtitle.
3. **Rows are frames** packed `-fill x`; widgets inside pack `-side left`. This
   gives consistent left-aligned, wrapping-free rows.
4. **Wire `-command` to the status bar** (`StatusBar::msg $::sbbar … -clear N`)
   so clicking anything gives visible feedback — handy in a demo, and a good
   habit generally.
5. **Exactly one separator between groups.** Two stacked separators (or a
   separator with no following header) is the usual cause of "double line"
   visual bugs — keep it to `separator → section_hdr → widgets`.
6. **Indexed paths for looped widgets** via `[incr ::some_idx]`, and register
   that counter in `show_page`'s reset list (see the file header) so revisiting
   the page reuses paths instead of leaking new ones.
7. **All sizes through `_sp` / `_sp2` / `_sf`.** No raw pixel or point numbers.

To add a brand-new page: write `build_mywidgets {f}` following this shape, add a
`Sidebar::add` entry near the bottom of the file that calls
`show_page mywidgets`, add the label to the `$::lmap` array, and register any
new index counter in `show_page`. That is the entire contract.

---

## See also

- [`gallery/showcase.tcl`](../../gallery/showcase.tcl) — every pattern above,
  wired into a live application. The file header lists where each one is used.
- [Getting started: SVG widgets](../gettingstarted/svg-widgets.md)
- [Widget reference](../widgets.md)
