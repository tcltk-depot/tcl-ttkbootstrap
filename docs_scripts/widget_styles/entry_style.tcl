# entry_style.tcl — shows all color and style variants with colored borders
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "Entry Styles"
set colors [list primary secondary success info warning danger light dark]
set f [ttk::frame .f -padding 5]
pack $f -fill both -expand 1
set top  [ttk::frame $f.top]
set bot  [ttk::frame $f.bot]
set bot2 [ttk::frame $f.bot2]
pack $top $bot $bot2 -fill x

# Create always-colored entry styles (border visible without focus)
foreach color $colors {
    set hex [ttkbootstrap::getColor $color]
    ttk::style configure colored_${color}.TEntry \
        -bordercolor $hex -lightcolor $hex -darkcolor $hex \
        -fieldbackground #ffffff -relief solid -borderwidth 1
}

set i 0
foreach color $colors {
    incr i
    set p [expr {$i <= 4 ? $top : $bot}]
    ttk::entry $p.e_$color -width 12 -style colored_${color}.TEntry
    $p.e_$color insert end $color
    pack $p.e_$color -side left -padx 3 -pady 10
}

ttk::entry $bot2.dis -width 12
$bot2.dis insert end "disabled"
pack $bot2.dis -side left -padx 3 -pady 5
$bot2.dis configure -state disabled

ttk::entry $bot2.ro -width 12
$bot2.ro insert end "readonly"
pack $bot2.ro -side left -padx 3 -pady 5
$bot2.ro configure -state readonly

wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
