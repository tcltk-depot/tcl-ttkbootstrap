# stopwatch.tcl — ttkbootstrap port of stopwatch.py
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

ttkbootstrap::Window -themename cosmo -title "Stopwatch"
wm resizable . 0 0

set ::sw_running 0
set ::sw_elapsed 0
set ::sw_afterid ""
set ::sw_text "00:00:00"

set f [ttk::frame .sw]
pack $f -fill both -expand 1

# Display label
ttk::label $f.lbl \
    -font [list TkDefaultFont [ttkbootstrap::_sf 32]] \
    -anchor center \
    -textvariable ::sw_text
pack $f.lbl -side top -fill x -padx 60 -pady 20

# Controls
set ctrl [ttk::frame $f.ctrl -padding 10]
pack $ctrl -fill x

proc sw_increment {} {
    incr ::sw_elapsed
    set c $::sw_elapsed
    set ::sw_text [format "%02d:%02d:%02d" \
        [expr {($c / 100) / 60}] \
        [expr {($c / 100) % 60}] \
        [expr {$c % 100}]]
    set ::sw_afterid [after 100 sw_increment]
}

proc sw_toggle {} {
    if {$::sw_running} {
        # pause
        after cancel $::sw_afterid
        set ::sw_running 0
        .sw.ctrl.start configure -text "Start" \
            -style [ttkbootstrap::bootstyle info TButton]
    } else {
        # start
        set ::sw_running 1
        .sw.ctrl.start configure -text "Pause" \
            -style [ttkbootstrap::bootstyle info outline TButton]
        sw_increment
    }
}

proc sw_reset {} {
    set ::sw_elapsed 0
    set ::sw_text "00:00:00"
}

ttk::button $ctrl.start \
    -text "Start" -width 10 \
    -style [ttkbootstrap::bootstyle info TButton] \
    -command sw_toggle
ttk::button $ctrl.reset \
    -text "Reset" -width 10 \
    -style [ttkbootstrap::bootstyle success TButton] \
    -command sw_reset
ttk::button $ctrl.quit \
    -text "Quit" -width 10 \
    -style [ttkbootstrap::bootstyle danger TButton] \
    -command { foreach id [after info] { after cancel $id }; _close_gallery }

pack $ctrl.start $ctrl.reset $ctrl.quit \
    -side left -fill x -expand 1 -pady 10 -padx 5

wm protocol . WM_DELETE_WINDOW { foreach id [after info] { after cancel $id }; _close_gallery }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
