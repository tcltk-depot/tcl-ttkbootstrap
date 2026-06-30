# Frame

## Colored frame

```tcl
# Primary colored background
ttk::frame .f -style primary.TFrame
pack .f -fill both -expand 1

# Put inverse label inside
ttk::label .f.l -text "Content" \
    -style primary.Inverse.TLabel
pack .f.l
```

## Colored labelframe

```tcl
ttk::labelframe .lf -text "Section" \
    -style [ttkbootstrap::bootstyle info TLabelframe]
pack .lf -fill both -expand 1 -padx 10 -pady 10
```

