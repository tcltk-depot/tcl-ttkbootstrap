# solid_outline_button_styles.tcl — Tutorial: solid vs outline buttons
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "Button Styles"
set f [ttk::frame .f -padding 10]
pack $f -fill both -expand 1
ttk::button $f.solid   -text "Solid Button"   -style [ttkbootstrap::bootstyle success TButton]
ttk::button $f.outline -text "Outline Button" -style [ttkbootstrap::bootstyle success outline TButton]
pack $f.solid $f.outline -side left -padx 5 -pady 10
wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
