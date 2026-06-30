# Menubutton Styles — shows all color and style variants
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "Menubutton Styles"
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
    ttk::menubutton $p.mb_$color -text $color -width 12 \
        -style [ttkbootstrap::bootstyle $color TMenubutton]
    pack $p.mb_$color -side left -padx 3 -pady 10
}
ttk::menubutton $bot.mb_dis -text "disabled" -width 12 -state disabled
pack $bot.mb_dis -side left -padx 3

set top2 [ttk::frame $f.top2]; pack $top2 -fill x
set bot2 [ttk::frame $f.bot2]; pack $bot2 -fill x
set i 0
foreach color $colors {
    incr i
    set p [expr {$i <= 4 ? $top2 : $bot2}]
    ttk::menubutton $p.mb_out_$color -text $color -width 12 \
        -style [ttkbootstrap::bootstyle $color outline TMenubutton]
    pack $p.mb_out_$color -side left -padx 3 -pady 10
}
wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
