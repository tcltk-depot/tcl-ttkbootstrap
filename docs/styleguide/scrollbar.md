# Scrollbar

## Standard scrollbar

```tcl
ttk::scrollbar .sb -orient horizontal
.sb set 0.2 0.8

# Colored
ttk::scrollbar .sb -orient horizontal \
    -style [ttkbootstrap::bootstyle primary TScrollbar]
```

## Round scrollbar

```tcl
ttk::scrollbar .sb -orient horizontal \
    -style [ttkbootstrap::bootstyle danger round TScrollbar]
```

