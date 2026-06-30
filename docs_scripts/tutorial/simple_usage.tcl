# simple_usage.tcl — Tutorial: basic ttkbootstrap usage
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "Simple Usage"
set f [ttk::frame .f -padding 10]
pack $f -fill both -expand 1
ttk::button $f.b1 -text "Button 1" -style [ttkbootstrap::bootstyle success TButton]
ttk::button $f.b2 -text "Button 2" -style [ttkbootstrap::bootstyle info outline TButton]
pack $f.b1 $f.b2 -side left -padx 5 -pady 10
wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
