# Checkbutton Styles — shows all color and style variants
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename darkly -title "Checkbutton Styles"
set colors [list primary secondary success info warning danger light dark]
set f [ttk::frame .f -padding 5]
pack $f -fill both -expand 1
set top [ttk::frame $f.top]
set bot [ttk::frame $f.bot]
pack $top -fill x
pack $bot -fill x

proc make_check_row {parent style_suffix invoke_it} {
    set colors {primary secondary success info warning danger light dark}
    set top [ttk::frame $parent.top_$style_suffix]
    set bot [ttk::frame $parent.bot_$style_suffix]
    pack $top $bot -fill x
    set i 0
    foreach color $colors {
        incr i
        set p [expr {$i <= 4 ? $top : $bot}]
        set vname ::chk_${style_suffix}_$color
        set $vname 0
        set suf [expr {$style_suffix eq "default" ? "" : $style_suffix}]
        if {$suf eq ""} {
            set style [ttkbootstrap::bootstyle $color TCheckbutton]
        } else {
            set style [ttkbootstrap::bootstyle $color $suf TCheckbutton]
        }
        set w [ttk::checkbutton $p.cb_${style_suffix}_$color \
            -text $color -variable $vname -style $style -width 10]
        pack $w -side left -padx 3 -pady 5
        if {$invoke_it} { $w invoke }
    }
}
make_check_row $f default 1
ttk::separator $f.sep1 -orient horizontal; pack $f.sep1 -fill x -pady 5
make_check_row $f round 1
ttk::separator $f.sep2 -orient horizontal; pack $f.sep2 -fill x -pady 5
make_check_row $f square 1
wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
