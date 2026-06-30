# Separator

## Horizontal separator

```tcl
ttk::separator .sep -orient horizontal
pack .sep -fill x

# Colored
ttk::separator .sep -orient horizontal \
    -style [ttkbootstrap::bootstyle primary TSeparator]
```

## Vertical separator

```tcl
ttk::separator .sep -orient vertical \
    -style [ttkbootstrap::bootstyle info TSeparator]
```

