# Combobox

## Default combobox

```tcl
ttk::combobox .c -values {one two three}

# Colored border on focus
ttk::combobox .c -values {one two three} \
    -style [ttkbootstrap::bootstyle info TCombobox]
```

## Readonly combobox

```tcl
ttk::combobox .c -values [ttkbootstrap::themeNames] -state readonly
.c current 0
```

## Disabled

```tcl
ttk::combobox .c -state disabled
```

