# sizegrip_style.tcl — shows all color and style variants
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "Sizegrip Styles"
set colors [list primary secondary success info warning danger light dark]
set f [ttk::frame .f -padding 5]
pack $f -fill both -expand 1
set top [ttk::frame $f.top]
set bot [ttk::frame $f.bot]
pack $top $bot -fill x

proc draw_sizegrip {parent color} {
    set hex [ttkbootstrap::getColor $color]
    set bg  [ttkbootstrap::getColor bg]
    set fr  [ttk::frame $parent.fr_$color -width 80 -height 60]
    pack propagate $fr 0
    ttk::label $fr.lbl -text $color -anchor center
    pack $fr.lbl -fill x -pady {5 0}
    # Draw colored grip dots on canvas
    set c [canvas $fr.grip -width 16 -height 16 -bg $bg -highlightthickness 0 -bd 0]
    # 3x3 grid of dots (skip top-left 2 rows/cols) — classic sizegrip pattern
    foreach {dx dy} {8 14  12 10  12 14  4 14  8 10  8 6  12 6  4 10  4 6} {
        $c create oval [expr {$dx-2}] [expr {$dy-2}] [expr {$dx+2}] [expr {$dy+2}]             -fill $hex -outline $hex
    }
    pack $fr.grip -side bottom -anchor se
    pack $fr -side left -padx 8 -pady 10
}

set i 0
foreach color $colors {
    incr i
    set p [expr {$i <= 4 ? $top : $bot}]
    draw_sizegrip $p $color
}

wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
