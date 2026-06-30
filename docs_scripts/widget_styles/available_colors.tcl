# Available Colors — shows all color and style variants
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "Available Colors"
set colors [list primary secondary success info warning danger light dark]
set f [ttk::frame .f -padding 5]
pack $f -fill both -expand 1
set top [ttk::frame $f.top]
set bot [ttk::frame $f.bot]
pack $top -fill x
pack $bot -fill x

foreach {i color} [lindex {{} {}} 0 ; lmap c $colors {list $c}] {}
set row1 [ttk::frame $top.r1]
set row2 [ttk::frame $bot.r2]
pack $row1 -fill both -expand 1 -pady {5 0} -padx 5
pack $row2 -fill both -expand 1 -pady {0 5} -padx 5
set i 0
foreach color $colors {
    incr i
    if {$i <= 4} { set p $row1 } else { set p $row2 }
    ttk::button $p.b_$color -text $color \
        -style [ttkbootstrap::bootstyle $color TButton]
    pack $p.b_$color -side left -fill both -expand 1
}
wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
