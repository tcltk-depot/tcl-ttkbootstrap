# Treeview

## Basic treeview

```tcl
ttk::treeview .tv -columns {name size} -show headings
.tv heading name -text "Name"
.tv heading size -text "Size"
.tv column  name -width 200
.tv column  size -width 80 -anchor e
.tv insert {} end -values {"readme.txt" "4 KB"}
.tv insert {} end -values {"data.csv"   "128 KB"}
pack .tv -fill both -expand 1
```

## Colored header

```tcl
ttk::treeview .tv \
    -style [ttkbootstrap::bootstyle info TTreeview]
```

## With scrollbars

```tcl
ttk::treeview .tv -yscrollcommand {.sby set} \
    -xscrollcommand {.sbx set}
ttk::scrollbar .sby -orient vertical   -command {.tv yview}
ttk::scrollbar .sbx -orient horizontal -command {.tv xview}
pack .sby -side right  -fill y
pack .sbx -side bottom -fill x
pack .tv  -fill both -expand 1
```

