# Scale

## Horizontal scale

```tcl
ttk::scale .s -orient horizontal -from 0 -to 100 -value 50

# Colored
ttk::scale .s -orient horizontal -from 0 -to 100 -value 50 \
    -style [ttkbootstrap::bootstyle success TScale]
```

## Vertical scale

```tcl
ttk::scale .s -orient vertical -from 0 -to 100 -value 75 \
    -style [ttkbootstrap::bootstyle info TScale]
```

