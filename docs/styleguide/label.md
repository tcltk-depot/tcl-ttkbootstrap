# Label

## Colored label

```tcl
# Colored foreground
ttk::label .l -text "Primary" \
    -style [ttkbootstrap::bootstyle primary TLabel]

# Inverse (colored background, contrasting text)
ttk::label .l -text "Primary" \
    -style primary.Inverse.TLabel
```

## All color variants

```tcl
foreach color {primary secondary success info warning danger light dark} {
    ttk::label .l_$color -text $color \
        -style [ttkbootstrap::bootstyle $color TLabel]
    pack .l_$color -side left -padx 3
}
```

