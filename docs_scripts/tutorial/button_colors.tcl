# button_colors.tcl — Tutorial: one button per theme color
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "Button Colors"
set f [ttk::frame .f -padding 10]
pack $f -fill both -expand 1
foreach color {primary secondary success info warning danger light dark} {
    ttk::button $f.b_$color -text $color \
        -style [ttkbootstrap::bootstyle $color TButton]
    pack $f.b_$color -side left -padx 3 -pady 5
}
wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
