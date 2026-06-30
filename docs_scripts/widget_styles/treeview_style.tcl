# Treeview Styles — shows all color and style variants
package require Tk
lappend auto_path [file join [file dirname [info script]] ../..] 
package require ttkbootstrap
ttkbootstrap::Window -themename litera -title "Treeview Styles"
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
    ttk::treeview $p.tv_$color -height 4 \
        -style [ttkbootstrap::bootstyle $color TTreeview]
    $p.tv_$color heading #0 -text $color -anchor w
    set iid [$p.tv_$color insert {} end -text "parent"]
    $p.tv_$color insert $iid end -text "child 1"
    $p.tv_$color insert $iid end -text "child 2"
    $p.tv_$color item $iid -open 1
    pack $p.tv_$color -side left -padx 5 -pady 5
}
wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
