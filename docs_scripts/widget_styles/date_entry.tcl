# DateEntry Styles — shows all color and style variants
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "DateEntry Styles"
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
    ttk::label $fr.lbl -text $color -anchor center
    pack $fr.lbl -fill x
    ttkbootstrap::DateEntry $fr.de -bootstyle $color
    pack $fr.de -fill x
    pack $fr -side left -padx 3 -pady 10
}
wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
