# =============================================================================
# statusbar.tcl — Application status bar
#
# USAGE
#   set sb [ttkbootstrap::StatusBar .]
#
#   ttkbootstrap::StatusBar::msg  $sb "Ready"
#   ttkbootstrap::StatusBar::msg  $sb "Loading..." -progress 40
#   ttkbootstrap::StatusBar::msg  $sb "Done"       -progress 100 -clear 2000
#   ttkbootstrap::StatusBar::right $sb "42 items"
#
# COMMANDS
#   StatusBar path ?-bootstyle color? ?-sizegrip 0|1?
#
#   StatusBar::msg  sb message ?-progress int? ?-bootstyle color? ?-clear ms?
#   StatusBar::right sb text ?index?
#   StatusBar::clear sb
#   StatusBar::progress sb value
# =============================================================================

namespace eval ttkbootstrap {

proc StatusBar {w args} {
    array set opts {
        -bootstyle secondary
        -sizegrip  1
    }
    array set opts $args

    set ns ::ttkbootstrap::sb::$w
    namespace eval $ns {}
    set ${ns}::after_id {}
    set ${ns}::bootstyle $opts(-bootstyle)

    set sep [ttk::separator ${w}.__sbsep -orient horizontal]
    pack $sep -side bottom -fill x

    set bar [ttk::frame ${w}.__sb -padding [ttkbootstrap::_sp2 4 2]]
    pack $bar -side bottom -fill x
    set ${ns}::bar $bar

    set lbl [ttk::label $bar.lbl \
        -text   {} \
        -anchor w \
        -font   [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                      [ttkbootstrap::_sf 11]]]
    pack $lbl -side left -fill x
    set ${ns}::lbl $lbl

    set pb [ttk::progressbar $bar.pb \
        -orient  horizontal \
        -length  [ttkbootstrap::_sp 120] \
        -maximum 100 \
        -value   0 \
        -style   "$opts(-bootstyle).Horizontal.TProgressbar"]
    set ${ns}::pb $pb

    if {$opts(-sizegrip)} {
        ttk::sizegrip $bar.grip
        pack $bar.grip -side right -padx [ttkbootstrap::_sp 2]
    }
    for {set i 2} {$i >= 0} {incr i -1} {
        set rl [ttk::label $bar.rlbl$i \
            -text   {} \
            -anchor e \
            -font   [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                          [ttkbootstrap::_sf 11]]]
        pack $rl -side right -padx [ttkbootstrap::_sp2 6 0]
        set ${ns}::rlbl$i $rl
    }

    bind $bar <<ThemeChanged>> [list ttkbootstrap::_sb_restyle $w]
    return $bar
}

proc _sb_restyle {w} {
    set ns ::ttkbootstrap::sb::$w
    if {![namespace exists $ns]} return
    set bs [set ${ns}::bootstyle]
    set pb [set ${ns}::pb]
    if {[winfo exists $pb]} {
        $pb configure -style "$bs.Horizontal.TProgressbar"
    }
}

} ;# end namespace ttkbootstrap

namespace eval ttkbootstrap::StatusBar {}

proc ttkbootstrap::StatusBar::msg {bar text args} {
    set w  [winfo parent $bar]
    set ns ::ttkbootstrap::sb::$w
    array set o {-progress {} -bootstyle {} -clear {}}
    array set o $args
    set lbl [set ${ns}::lbl]
    set pb  [set ${ns}::pb]
    $lbl configure -text $text
    set aid [set ${ns}::after_id]
    if {$aid ne {}} { catch {after cancel $aid}; set ${ns}::after_id {} }
    if {$o(-progress) ne {}} {
        set bs [expr {$o(-bootstyle) ne {} ? $o(-bootstyle) : [set ${ns}::bootstyle]}]
        $pb configure -value $o(-progress) -style "$bs.Horizontal.TProgressbar"
        if {![winfo ismapped $pb]} { pack $pb -side left -padx [ttkbootstrap::_sp2 6 0] }
    }
    if {$o(-clear) ne {}} {
        set ${ns}::after_id [after $o(-clear) [list ttkbootstrap::StatusBar::clear $bar]]
    }
}

proc ttkbootstrap::StatusBar::clear {bar} {
    set w  [winfo parent $bar]
    set ns ::ttkbootstrap::sb::$w
    set lbl [set ${ns}::lbl]
    set pb  [set ${ns}::pb]
    $lbl configure -text {}
    $pb  configure -value 0
    catch { pack forget $pb }
    set ${ns}::after_id {}
}

proc ttkbootstrap::StatusBar::right {bar text {index 0}} {
    set w  [winfo parent $bar]
    set ns ::ttkbootstrap::sb::$w
    set rl [set ${ns}::rlbl$index]
    $rl configure -text $text
}

proc ttkbootstrap::StatusBar::progress {bar value} {
    set w  [winfo parent $bar]
    set ns ::ttkbootstrap::sb::$w
    set pb [set ${ns}::pb]
    $pb configure -value $value
    if {![winfo ismapped $pb]} { pack $pb -side left -padx [ttkbootstrap::_sp2 6 0] }
}
