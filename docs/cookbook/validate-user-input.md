# Validate User Input

Use Tk's built-in `validatecommand` to restrict what users can type into entry widgets.

## Source: [cookbook/validate_user_input.tcl](../../cookbook/validate_user_input.tcl)

## How it works

The `validatecommand` option accepts a Tcl command that is called on each keystroke. If it returns `0`, the input is rejected. The `%P` substitution provides the *proposed* value after the edit.

```tcl
# Register a validation proc
proc validate_number {proposed} {
    if {$proposed eq ""} { return 1 }          ;# allow empty
    if {[string is integer -strict $proposed]} { return 1 }  ;# allow digits
    return 0                                    ;# reject anything else
}

# Apply to an entry
ttk::entry .e -validate key \
    -validatecommand {validate_number %P}
```

## Full example

```tcl
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

ttkbootstrap::Window -themename litera -title "Validate Input"

set f [ttk::frame .f -padding 10]
pack $f -fill both -expand 1

# Digits only
proc validate_number {x} {
    expr {$x eq "" || [string is integer -strict $x]}
}

# Letters only (no digits)
proc validate_alpha {x} {
    expr {$x eq "" || ![string is digit $x]}
}

ttk::label $f.lnum -text "Numbers only:"
pack $f.lnum -fill x

ttk::entry $f.num -validate key -validatecommand {validate_number %P}
pack $f.num -fill x -padx 10 -pady {0 10}

ttk::label $f.llet -text "Letters only:"
pack $f.llet -fill x

ttk::entry $f.let -validate key -validatecommand {validate_alpha %P}
pack $f.let -fill x -padx 10 -pady {0 10}

vwait forever
```

## Validation triggers

| `-validate` option | When validation fires                        |
|--------------------|----------------------------------------------|
| `key`              | On every keystroke                           |
| `focus`            | When widget gains or loses focus             |
| `focusin`          | When widget gains focus                      |
| `focusout`         | When widget loses focus                      |
| `all`              | On all of the above                          |

## Substitution variables

| Variable | Meaning                                      |
|----------|----------------------------------------------|
| `%P`     | The proposed value if the edit were accepted |
| `%s`     | The current value before the edit            |
| `%S`     | The string being inserted or deleted         |
| `%i`     | Index of the insert/delete position          |
| `%d`     | Type: 1=insert, 0=delete, -1=other           |
| `%v`     | The current `-validate` setting              |
| `%W`     | The widget path name                         |

## Regular expression validation

```tcl
# Allow only hex characters (0-9, a-f, A-F)
proc validate_hex {x} {
    expr {$x eq "" || [regexp {^[0-9a-fA-F]+$} $x]}
}

ttk::entry .e -validate key -validatecommand {validate_hex %P}
```

## Float validation

```tcl
proc validate_float {x} {
    if {$x eq "" || $x eq "-" || $x eq "."} { return 1 }
    string is double -strict $x
}

ttk::entry .e -validate key -validatecommand {validate_float %P}
```
