# Button

Buttons feature solid, outline, and link style types, all available in every theme color.

## Solid button (default)

The default style features a solid background that lightens on hover.

```tcl
# Default primary button
ttk::button .b -text "Button" -style TButton

# Success colored button
ttk::button .b -text "Button" -style [ttkbootstrap::bootstyle success TButton]

# Shorthand — color.TButton also works
ttk::button .b -text "Button" -style primary.TButton
```

## Outline button

Features a thin colored outline. On hover/press it fills with a solid color.

```tcl
# Default outline button
ttk::button .b -text "Button" \
    -style [ttkbootstrap::bootstyle outline TButton]

# Success outline button
ttk::button .b -text "Button" \
    -style [ttkbootstrap::bootstyle success outline TButton]
```

## Link button

Appears as a text link. Useful for non-primary actions.

```tcl
# Default link button
ttk::button .b -text "Click here" -style Link.TButton

# Colored link button
ttk::button .b -text "Click here" \
    -style [ttkbootstrap::bootstyle info Link.TButton]
```

## Disabled button

```tcl
# Create disabled
ttk::button .b -text "Disabled" -state disabled

# Disable after creation
ttk::button .b -text "Button"
.b configure -state disabled

# Re-enable
.b configure -state normal
```

## Menubutton

Solid and outline variants are available.

```tcl
# Solid menubutton
ttk::menubutton .mb -text "Menu" \
    -style [ttkbootstrap::bootstyle secondary TMenubutton]

# Outline menubutton
ttk::menubutton .mb -text "Menu" \
    -style [ttkbootstrap::bootstyle warning outline TMenubutton]
```

## See also

- [docs_scripts/widget_styles/button_style.tcl](../../docs_scripts/widget_styles/button_style.tcl) — live demo
