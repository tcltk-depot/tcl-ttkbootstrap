# Panedwindow

## Horizontal panedwindow

```tcl
ttk::panedwindow .pw -orient horizontal
.pw add [ttk::frame .pw.left  -width 200 -height 200]
.pw add [ttk::frame .pw.right -width 200 -height 200]
pack .pw -fill both -expand 1

# Colored sash
ttk::panedwindow .pw -orient horizontal \
    -style [ttkbootstrap::bootstyle info TPanedwindow]
```

