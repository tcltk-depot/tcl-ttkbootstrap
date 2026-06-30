# Button Styles — shows all color and style variants
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "Button Styles"
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
    ttk::button $p.solid_$color -text $color \
        -style [ttkbootstrap::bootstyle $color TButton] -width 10
    pack $p.solid_$color -side left -padx 3 -pady 5
}
ttk::button $bot.solid_dis -text "disabled" -width 10 -state disabled
pack $bot.solid_dis -side left -padx 3 -pady 5

# Outline row
set top2 [ttk::frame $f.top2]; pack $top2 -fill x
set bot2 [ttk::frame $f.bot2]; pack $bot2 -fill x
set i 0
foreach color $colors {
    incr i
    set p [expr {$i <= 4 ? $top2 : $bot2}]
    ttk::button $p.out_$color -text $color -width 10 \
        -style [ttkbootstrap::bootstyle $color outline TButton]
    pack $p.out_$color -side left -padx 3 -pady 5
}
ttk::button $bot2.out_dis -text "disabled" -width 10 -state disabled \
    -style [ttkbootstrap::bootstyle outline TButton]
pack $bot2.out_dis -side left -padx 3 -pady 5

# Link row
set top3 [ttk::frame $f.top3]; pack $top3 -fill x
set bot3 [ttk::frame $f.bot3]; pack $bot3 -fill x
set i 0
foreach color $colors {
    incr i
    set p [expr {$i <= 4 ? $top3 : $bot3}]
    ttk::button $p.lnk_$color -text $color -width 10 -style Link.TButton
    pack $p.lnk_$color -side left -padx 3 -pady 5
}
wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
