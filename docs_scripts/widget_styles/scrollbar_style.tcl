# Scrollbar Styles — shows all color and style variants
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "Scrollbar Styles"
set colors [list primary secondary success info warning danger light dark]
set f [ttk::frame .f -padding 5]
pack $f -fill both -expand 1
set top [ttk::frame $f.top]
set bot [ttk::frame $f.bot]
pack $top -fill x
pack $bot -fill x

set i 0
foreach color $colors {
    incr i
    set p [expr {$i <= 4 ? $top : $bot}]
    set fr [ttk::frame $p.fr_$color]
    ttk::label $fr.lbl -text $color -width 12
    ttk::scrollbar $fr.sb -orient horizontal \
        -style [ttkbootstrap::bootstyle $color round TScrollbar]
    $fr.sb set 0.1 0.9
    pack $fr.lbl -side top
    pack $fr.sb  -fill x
    pack $fr -side left -padx 3 -pady 10 -fill x
}
wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
