# notebook_style.tcl — shows all color and style variants
# Color shows on the selected (active) tab
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "Notebook Styles"
set colors [list primary secondary success info warning danger light dark]
set f [ttk::frame .f -padding 5]
pack $f -fill both -expand 1
set top [ttk::frame $f.top]
set bot [ttk::frame $f.bot]
pack $top $bot -fill x

set i 0
foreach color $colors {
    incr i
    set p [expr {$i <= 4 ? $top : $bot}]
    ttk::notebook $p.nb_$color
    # Tab frames need a minimum size
    ttk::frame $p.nb_$color.t1 -width 150 -height 50
    ttk::frame $p.nb_$color.t2 -width 150 -height 50
    $p.nb_$color add $p.nb_$color.t1 -text $color
    $p.nb_$color add $p.nb_$color.t2 -text "Tab 2"
    pack $p.nb_$color -padx 5 -pady 5 -side left
}

wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
