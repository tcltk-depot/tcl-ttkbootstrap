# input_group.tcl — ttkbootstrap port of development/validatedinput/inputgroup.py
# An InputGroup widget: entry with floating label and contextual help message
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

# ── InputGroup namespace ──────────────────────────────────────────────────────
namespace eval InputGroup {

    # Create an InputGroup widget
    # Options:
    #   -labeltext      text above the entry
    #   -defaultvalue   pre-filled value
    #   -activemessage  hint shown on focus-in
    #   -errormessage   message shown on validation failure
    #   -confirmmessage message shown on valid input
    #   -validatecommand  proc name taking value, returns 1/0
    proc create {master args} {
        array set opts {
            -labeltext      {}
            -defaultvalue   {}
            -activemessage  {}
            -errormessage   {}
            -confirmmessage {}
            -validatecommand {}
            -style          {}
        }
        array set opts $args

        set w $master.ig[incr ::ig_count]
        set outer [ttk::frame $w -padding {10 6}]

        # Label above the entry
        if {$opts(-labeltext) ne {}} {
            ttk::label $outer.lbl \
                -text $opts(-labeltext) \
                -style secondary.TLabel
            pack $outer.lbl -fill x
        }

        # Entry
        ttk::entry $outer.ent
        pack $outer.ent -fill x -ipady 3

        if {$opts(-defaultvalue) ne {}} {
            $outer.ent insert 0 $opts(-defaultvalue)
        }

        # Message label (hidden initially)
        ttk::label $outer.msg -text {} -style secondary.TLabel
        # Don't pack yet — shown on focus

        # Store options on the widget
        foreach key {-activemessage -errormessage -confirmmessage -validatecommand} {
            set ::ig_opt(${w},$key) $opts($key)
        }

        # Bindings
        bind $outer.ent <FocusIn>  [list InputGroup::_on_focus_in  $outer]
        bind $outer.ent <FocusOut> [list InputGroup::_on_focus_out $outer]

        return $outer
    }

    proc _on_focus_in {w} {
        set msg $::ig_opt($w,-activemessage)
        if {$msg ne {}} {
            $w.msg configure -text $msg -style info.TLabel
            pack $w.msg -fill x -after $w.ent
        }
    }

    proc _on_focus_out {w} {
        set val [$w.ent get]
        set vcmd $::ig_opt($w,-validatecommand)

        # Hide active message
        pack forget $w.msg

        if {$vcmd ne {}} {
            if {[{*}$vcmd $val]} {
                # Valid
                set cmsg $::ig_opt($w,-confirmmessage)
                if {$cmsg ne {}} {
                    $w.msg configure -text $cmsg -style success.TLabel
                    pack $w.msg -fill x -after $w.ent
                }
                $w.ent configure -style TEntry
            } else {
                # Invalid
                set emsg $::ig_opt($w,-errormessage)
                if {$emsg ne {}} {
                    $w.msg configure -text $emsg -style danger.TLabel
                    pack $w.msg -fill x -after $w.ent
                }
                $w.ent configure -style danger.TEntry
            }
        }
    }

    # Return the entry value
    proc get {w} {
        return [$w.ent get]
    }
}

set ::ig_count 0

# ── Demo ──────────────────────────────────────────────────────────────────────
ttkbootstrap::Window -themename litera -title "Input Group" -size {350 300}

set f [ttk::frame .igdemo -padding 10]
pack $f -fill both -expand 1

# First name — shows hint on focus, validates non-empty on blur
set g1 [InputGroup::create $f \
    -labeltext      "First Name" \
    -activemessage  "Enter your first name" \
    -errormessage   "First name cannot be empty" \
    -confirmmessage "Looks good!" \
    -validatecommand {apply {{v} { expr {$v ne ""} }}}]
pack $g1 -fill x -pady 5

# Last name
set g2 [InputGroup::create $f \
    -labeltext      "Last Name" \
    -activemessage  "Enter your last name" \
    -errormessage   "Last name cannot be empty" \
    -confirmmessage "Looks good!" \
    -validatecommand {apply {{v} { expr {$v ne ""} }}}]
pack $g2 -fill x -pady 5

# Email — validates @ symbol present
set g3 [InputGroup::create $f \
    -labeltext      "Email" \
    -activemessage  "Enter a valid email address" \
    -errormessage   "Please enter a valid email" \
    -confirmmessage "Email looks valid!" \
    -validatecommand {apply {{v} { expr {[string match *@*.* $v]} }}}]
pack $g3 -fill x -pady 5

# Phone — digits only
set g4 [InputGroup::create $f \
    -labeltext      "Phone (digits only)" \
    -activemessage  "Enter digits only" \
    -errormessage   "Only digits are allowed" \
    -confirmmessage "Valid phone number!" \
    -validatecommand {apply {{v} { expr {$v eq "" || [string is digit -strict $v]} }}}]
pack $g4 -fill x -pady 5

wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
