# Radiobutton

## Default radiobutton

```tcl
set ::rv 1
ttk::radiobutton .r1 -text "Option A" -variable ::rv -value 1
ttk::radiobutton .r2 -text "Option B" -variable ::rv -value 2

# Colored
ttk::radiobutton .r1 -text "Option A" -variable ::rv -value 1 \
    -style [ttkbootstrap::bootstyle success TRadiobutton]
```

## Toolbutton style

```tcl
ttk::radiobutton .r1 -text "Left"   -variable ::rv -value 1 \
    -style [ttkbootstrap::bootstyle primary Toolbutton.TButton]
ttk::radiobutton .r2 -text "Center" -variable ::rv -value 2 \
    -style [ttkbootstrap::bootstyle primary Toolbutton.TButton]
ttk::radiobutton .r3 -text "Right"  -variable ::rv -value 3 \
    -style [ttkbootstrap::bootstyle primary Toolbutton.TButton]
```

