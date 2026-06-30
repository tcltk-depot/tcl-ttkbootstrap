# scale_style.tcl — shows all color and style variants using canvas sliders
# (Tk9 ttk::scale renders as solid blocks — canvas used for correct appearance)
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "Scale Styles"
set colors [list primary secondary success info warning danger light dark]
set f [ttk::frame .f -padding 5]
pack $f -fill both -expand 1
set top [ttk::frame $f.top]
set bot [ttk::frame $f.bot]
pack $top $bot -fill x

proc make_scale {parent color} {
    set hex    [ttkbootstrap::getColor $color]
    set border [ttkbootstrap::getColor border]
    set bg     [ttkbootstrap::getColor bg]

    set fr [ttk::frame $parent.fr_$color]
    ttk::label $fr.lbl -text $color -width 10
    pack $fr.lbl -side top

    # Canvas slider: 120px wide track, dot knob
    set cw 130; set ch 24; set knob_r 7; set cy 12; set x0 8; set x1 [expr {$cw-8}]
    set val 35  ;# default value 35%
    set kx [expr {int($x0 + ($val/100.0)*($x1-$x0))}]

    set c [canvas $fr.c -width $cw -height $ch -highlightthickness 0 -bd 0 -bg $bg]
    pack $c -fill x
    $c create line $x0 $cy $x1 $cy -fill $border -width 3 -capstyle round
    $c create line $x0 $cy $kx $cy -fill $hex    -width 3 -capstyle round
    $c create oval [expr {$kx-$knob_r}] [expr {$cy-$knob_r}]                    [expr {$kx+$knob_r}] [expr {$cy+$knob_r}]                    -fill $hex -outline $hex -tags knob

    pack $fr -side left -padx 3 -pady 10
}

set i 0
foreach color $colors {
    incr i
    set p [expr {$i <= 4 ? $top : $bot}]
    make_scale $p $color
}

wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
