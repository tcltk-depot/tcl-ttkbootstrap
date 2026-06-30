# validate_user_input.tcl — ttkbootstrap port of cookbook/validate_user_input.py
# Demonstrates Tk's built-in entry validation using validatecommand
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

ttkbootstrap::Window -themename litera -title "Validate User Input"
wm resizable . 0 0

set f [ttk::frame .vui -padding 10]
pack $f -fill both -expand 1

# ── Validation procs ──────────────────────────────────────────────────────────
proc validate_number {x} {
    # Allow empty string or digits only
    if {$x eq ""} { return 1 }
    if {[string is integer -strict $x]} { return 1 }
    return 0
}

proc validate_alpha {x} {
    # Allow empty string or non-digit characters
    if {$x eq ""} { return 1 }
    if {[string is digit $x]} { return 0 }
    return 1
}

proc on_invalid {widget} {
    # Flash the entry red briefly to signal invalid input
    set orig [$widget cget -foreground]
    $widget configure -foreground red
    after 500 [list $widget configure -foreground $orig]
}

# Register validation commands with Tk
set digit_func [list validate_number %P]
set alpha_func [list validate_alpha %P]

# ── Numeric entry ─────────────────────────────────────────────────────────────
ttk::label $f.lbl_num \
    -text "Enter a number:" \
    -style primary.TLabel
pack $f.lbl_num -fill x -pady {10 2}

ttk::entry $f.num_entry \
    -validate key \
    -validatecommand $digit_func \
    -invalidcommand [list on_invalid $f.num_entry]
pack $f.num_entry -fill x -padx 10 -pady {0 10} -ipady 4

# ── Alpha entry ───────────────────────────────────────────────────────────────
ttk::label $f.lbl_let \
    -text "Enter a letter (no digits):" \
    -style primary.TLabel
pack $f.lbl_let -fill x -pady {10 2}

ttk::entry $f.let_entry \
    -validate key \
    -validatecommand $alpha_func \
    -invalidcommand [list on_invalid $f.let_entry]
pack $f.let_entry -fill x -padx 10 -pady {0 10} -ipady 4

# ── Result label ──────────────────────────────────────────────────────────────
set ::vui_num ""
set ::vui_let ""
trace add variable ::vui_num write {apply {{args} {
    .vui.result configure -text "Number: $::vui_num   Letter: $::vui_let"
}}}
trace add variable ::vui_let write {apply {{args} {
    .vui.result configure -text "Number: $::vui_num   Letter: $::vui_let"
}}}

$f.num_entry configure -textvariable ::vui_num
$f.let_entry configure -textvariable ::vui_let

ttk::label $f.result -text "Number:    Letter: " -style secondary.TLabel
pack $f.result -fill x -pady 10

wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
