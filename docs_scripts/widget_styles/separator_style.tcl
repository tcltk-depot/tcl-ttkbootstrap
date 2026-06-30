# separator_style.tcl — shows all color and style variants
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "Separator Styles"
set colors [list primary secondary success info warning danger light dark]
set f [ttk::frame .f -padding 15]
pack $f -fill both -expand 1
set top [ttk::frame $f.top]
set bot [ttk::frame $f.bot]
pack $top $bot -fill x

set i 0
foreach color $colors {
    incr i
    set p [expr {$i <= 4 ? $top : $bot}]
    set fr [ttk::frame $p.fr_$color]
    ttk::label $fr.lbl -text $color -width 10 -anchor center
    set hex [ttkbootstrap::getColor $color]
    set c [canvas $fr.sep -width 120 -height 8 -highlightthickness 0 -bd 0                -bg [ttkbootstrap::getColor bg]]
    $c create line 0 4 120 4 -fill $hex -width 2
    pack $fr.lbl -side top
    pack $fr.sep -pady 3
    pack $fr -side left -padx 8 -pady 10
}

wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
