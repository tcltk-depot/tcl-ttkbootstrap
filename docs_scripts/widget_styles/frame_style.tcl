# Frame Styles — shows all color and style variants
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "Frame Styles"
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
    ttk::frame $p.fr_$color -style ${color}.TFrame
    ttk::label $p.fr_$color.lbl -text $color -width 10 -anchor center \
        -style ${color}.Inverse.TLabel
    pack $p.fr_$color.lbl -fill y -expand 1 -padx 15 -pady 10
    pack $p.fr_$color -side left -padx 5 -pady 5
}
wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
