# Progressbar

## Solid progressbar

```tcl
ttk::progressbar .pb -orient horizontal -value 65

# Success colored
ttk::progressbar .pb -orient horizontal -value 65 \
    -style [ttkbootstrap::bootstyle success TProgressbar]
```

## Striped progressbar

```tcl
ttk::progressbar .pb -orient horizontal -value 75 \
    -style [ttkbootstrap::bootstyle success striped TProgressbar]
```

## Indeterminate (animated)

```tcl
ttk::progressbar .pb -mode indeterminate \
    -style [ttkbootstrap::bootstyle info TProgressbar]
.pb start
```

## Vertical

```tcl
ttk::progressbar .pb -orient vertical -value 50 -length 150 \
    -style [ttkbootstrap::bootstyle warning TProgressbar]
```

