# DateEntry

## Basic DateEntry

```tcl
ttkbootstrap::DateEntry .de
pack .de

# Get the selected date
set date [.de get]
puts "Selected: $date"
```

## Colored DateEntry

```tcl
ttkbootstrap::DateEntry .de -bootstyle success
pack .de
```

## With date range

```tcl
ttkbootstrap::DateEntry .de \
    -startdate "2024-01-01" \
    -enddate   "2024-12-31"
pack .de
```

