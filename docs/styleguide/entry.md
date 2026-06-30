# Entry

## Default entry

```tcl
ttk::entry .e

# Colored focus ring
ttk::entry .e -style [ttkbootstrap::bootstyle success TEntry]
```

## Validated entry

```tcl
ttk::entry .e -validate key \
    -validatecommand {string is integer -strict %P}
```

## Disabled / readonly

```tcl
ttk::entry .e -state disabled
ttk::entry .e -state readonly
```

