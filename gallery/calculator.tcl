# calculator.tcl — ttkbootstrap port of calculator.py
# Author: Israel Dryer (original Python), ported to Tcl/Tk
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

ttkbootstrap::Window -themename flatly -title "Calculator" -size {350 450}
wm resizable . 0 0

set ::calc_display 0
set ::calc_x 0.0
set ::calc_y 0.0
set ::calc_op "+"

ttk::style configure TButton -font [list TkFixedFont [ttkbootstrap::_sf 12]]

set f [ttk::frame .calc -padding 10]
pack $f -fill both -expand 1

# Display
set disp_frame [ttk::frame $f.disp -padding 2]
pack $disp_frame -fill x -pady 20
ttk::label $disp_frame.lbl \
    -font [list TkFixedFont [ttkbootstrap::_sf 14]] \
    -textvariable ::calc_display \
    -anchor e
pack $disp_frame.lbl -fill x

# Numpad
set pad [ttk::frame $f.pad -padding 2]
pack $pad -fill both -expand 1

set matrix {
    {% C CE /}
    {7 8 9 *}
    {4 5 6 -}
    {1 2 3 +}
    {± 0 . =}
}

proc calc_on_press {txt} {
    set display $::calc_display
    # strip leading operator
    if {[string length $display] > 0 && [string index $display 0] in {/ * - +}} {
        set display [string range $display 1 end]
    }
    if {$txt in {CE C}} {
        set ::calc_display ""
        set ::calc_x 0.0; set ::calc_y 0.0; set ::calc_op "+"
    } elseif {[string is integer -strict $txt]} {
        if {$display eq "0" || $display eq ""} {
            set ::calc_display $txt
        } else {
            set ::calc_display "$display$txt"
        }
    } elseif {$txt eq "." && "." ni [split $display ""]} {
        set ::calc_display "$display."
    } elseif {$txt eq "±"} {
        if {[string index $display 0] eq "-"} {
            if {[string length $display] > 1} {
                set ::calc_display [string range $display 1 end]
            } else {
                set ::calc_display ""
            }
        } else {
            set ::calc_display "-$display"
        }
    } elseif {$txt in {/ * - +}} {
        set ::calc_op $txt
        if {$display ne ""} {
            if {$::calc_x != 0} {
                set ::calc_y [expr {double($display)}]
            } else {
                set ::calc_x [expr {double($display)}]
            }
        }
        set ::calc_display $txt
    } elseif {$txt eq "="} {
        if {$display ne ""} {
            if {$::calc_x != 0} {
                set ::calc_y [expr {double($display)}]
            } else {
                set ::calc_x [expr {double($display)}]
            }
        }
        set x $::calc_x; set y $::calc_y; set op $::calc_op
        if {$x != 0 && $y != 0 && $op ne ""} {
            if {$op eq "/" && $y == 0} {
                set ::calc_display "Error"
            } else {
                set result [expr "$x $op $y"]
                # Format: remove trailing .0 for integers
                if {$result == int($result)} {
                    set ::calc_display [expr {int($result)}]
                } else {
                    set ::calc_display $result
                }
            }
            set ::calc_x 0.0; set ::calc_y 0.0; set ::calc_op "+"
        }
    }
}

for {set i 0} {$i < [llength $matrix]} {incr i} {
    set row [lindex $matrix $i]
    grid rowconfigure $pad $i -weight 1
    for {set j 0} {$j < [llength $row]} {incr j} {
        grid columnconfigure $pad $j -weight 1
        set txt [lindex $row $j]
        if {$txt eq "="} {
            set style [ttkbootstrap::bootstyle success TButton]
        } elseif {![string is integer -strict $txt]} {
            set style [ttkbootstrap::bootstyle secondary TButton]
        } else {
            set style [ttkbootstrap::bootstyle primary TButton]
        }
        set btn [ttk::button $pad.b${i}_${j} \
            -text $txt \
            -style $style \
            -width 2 \
            -padding 10 \
            -command [list calc_on_press $txt]]
        grid $btn -row $i -column $j -sticky nsew -padx 1 -pady 1
    }
}

wm protocol . WM_DELETE_WINDOW { foreach id [after info] { after cancel $id }; _close_gallery }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
