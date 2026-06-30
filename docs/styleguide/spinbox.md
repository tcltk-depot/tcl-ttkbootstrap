# Spinbox

## Default spinbox

```tcl
ttk::spinbox .sb -from 0 -to 100 -increment 1

# Colored focus ring
ttk::spinbox .sb -from 0 -to 100 \
    -style [ttkbootstrap::bootstyle success TSpinbox]
```

## Values list

```tcl
ttk::spinbox .sb -values {Small Medium Large} -state readonly
```

