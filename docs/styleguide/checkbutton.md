# Checkbutton

Checkbuttons support five style types: default checkbox, toolbutton, outline toolbutton, round toggle, and square toggle.

## Default checkbutton

Square checkbox with checkmark when selected.

```tcl
set ::v 1
ttk::checkbutton .c -text "Option" -variable ::v

# Success colored
ttk::checkbutton .c -text "Option" -variable ::v \
    -style [ttkbootstrap::bootstyle success TCheckbutton]
```

## Solid toolbutton

Rectangular button that toggles between a muted grey (off) and a solid color (on).

```tcl
set ::v 1
ttk::checkbutton .c -text "Tool" -variable ::v \
    -style [ttkbootstrap::bootstyle success Toolbutton.TButton]

# Or with explicit color
ttk::checkbutton .c -text "Tool" -variable ::v \
    -style success.Toolbutton.TButton
```

## Outline toolbutton

Rectangular button that shows an outline when off, solid color when on.

```tcl
set ::v 0
ttk::checkbutton .c -text "Tool" -variable ::v \
    -style [ttkbootstrap::bootstyle success Outline.Toolbutton.TButton]
```

## Round toggle

Pill-shaped toggle with circular knob. Knob moves left (off) or right (on).

```tcl
set ::v 1
ttk::checkbutton .t -text "Enable feature" -variable ::v \
    -style [ttkbootstrap::bootstyle success round TCheckbutton]

# Primary round toggle
ttk::checkbutton .t -text "Enable" -variable ::v \
    -style [ttkbootstrap::bootstyle primary round TCheckbutton]
```

## Square toggle

Rectangular toggle with square knob.

```tcl
set ::v 1
ttk::checkbutton .t -text "Enable feature" -variable ::v \
    -style [ttkbootstrap::bootstyle primary square TCheckbutton]
```

## Disabled state

```tcl
# Disabled checkbutton
ttk::checkbutton .c -text "Disabled" -variable ::v -state disabled
```

## See also

- [docs_scripts/widget_styles/checkbutton_style.tcl](../../docs_scripts/widget_styles/checkbutton_style.tcl)
