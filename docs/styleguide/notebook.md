# Notebook

## Default notebook

```tcl
ttk::notebook .nb

ttk::frame .nb.t1
ttk::frame .nb.t2
.nb add .nb.t1 -text "Tab 1"
.nb add .nb.t2 -text "Tab 2"
pack .nb -fill both -expand 1
```

## Colored notebook

```tcl
ttk::notebook .nb -style [ttkbootstrap::bootstyle info TNotebook]
```

