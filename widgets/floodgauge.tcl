# =============================================================================
# floodgauge.tcl — ttkbootstrap Floodgauge widget
#
# A progressbar with text rendered inside it (the bar "floods" behind the text).
#
# Usage:
#   ttkbootstrap::Floodgauge .fg \
#       -bootstyle info \
#       -value 40 \
#       -maximum 100 \
#       -text "Loading..." \
#       -orient horizontal \
#       -width 300 \
#       -height 40
#
# Options:
#   -value        Current value           (default 0)
#   -maximum      Maximum value           (default 100)
#   -orient       horizontal | vertical   (default horizontal)
#   -bootstyle    color keyword           (default primary)
#   -text         Overlay text            (default {})
#   -font         Text font               (default TkDefaultFont 10 bold)
#   -width        Widget width            (default 300)
#   -height       Widget height           (default 40)
#   -mask         printf-style format     (default {})  e.g. "%.0f%%"
#   -command      Script called on change
# =============================================================================

namespace eval ttkbootstrap {

proc Floodgauge {w args} {
    array set opts [list \
        -value      0 \
        -maximum    100 \
        -orient     horizontal \
        -bootstyle  primary \
        -text       {} \
        -font       {} \
        -width      [ttkbootstrap::_sp 300] \
        -height     [ttkbootstrap::_sp 40] \
        -mask       {} \
        -command    {} \
        -variable   {} \
    ]
    array set opts $args

    set ns ::ttkbootstrap::floodgauge::$w
    namespace eval $ns {}
    set ${ns}::opts [array get opts]

    set bg    [ttkbootstrap::getColor bg]
    set c [canvas $w \
        -width  $opts(-width) \
        -height $opts(-height) \
        -background $bg \
        -highlightthickness 0 \
        -borderwidth 0]

    set ${ns}::canvas $c

    # Variable trace
    if {$opts(-variable) ne {}} {
        upvar #0 $opts(-variable) var
        trace add variable $opts(-variable) write \
            [list ttkbootstrap::_flood_varchange $w]
        # Remove trace when widget is destroyed
        set _fg_var $opts(-variable)
        bind $w <Destroy> [list catch \
            [list trace remove variable $_fg_var write \
                [list ttkbootstrap::_flood_varchange $w]]]
    }

    _flood_draw $w

    bind $c <Configure> [list ttkbootstrap::_flood_resize $w %w %h]

    interp alias {} ${w}.configure {} ttkbootstrap::_flood_configure $w
    interp alias {} ${w}.get       {} ttkbootstrap::_flood_get $w
    interp alias {} ${w}.set       {} ttkbootstrap::_flood_setval $w
    interp alias {} ${w}.step      {} ttkbootstrap::_flood_step $w
    interp alias {} ${w}.start     {} ttkbootstrap::_flood_start $w
    interp alias {} ${w}.stop      {} ttkbootstrap::_flood_stop $w

    return $w
}

proc _flood_draw {w} {
    set ns ::ttkbootstrap::floodgauge::$w
    array set opts [set ${ns}::opts]
    set c [set ${ns}::canvas]

    $c delete all

    set W     [$c cget -width]
    set H     [$c cget -height]
    set val   [expr {double($opts(-value))}]
    set maxv  [expr {double($opts(-maximum))}]
    set maxv  [expr {$maxv == 0 ? 1 : $maxv}]
    set frac  [expr {$val / $maxv}]
    set frac  [expr {$frac < 0 ? 0.0 : ($frac > 1 ? 1.0 : $frac)}]

    set barfg [ttkbootstrap::getColor $opts(-bootstyle)]
    set trof  [ttkbootstrap::getColor light]
    set txtfg [ttkbootstrap::getColor fg]
    set bg    [ttkbootstrap::getColor bg]

    # Background trough
    $c create rectangle 0 0 $W $H \
        -fill $trof -outline {} -tags trough

    # Flood fill
    if {$opts(-orient) eq "horizontal"} {
        set bx [expr {$frac * $W}]
        if {$bx > 0.5} {
            $c create rectangle 0 0 $bx $H \
                -fill $barfg -outline {} -tags bar
        }
    } else {
        set by [expr {(1 - $frac) * $H}]
        if {$by < $H - 0.5} {
            $c create rectangle 0 $by $W $H \
                -fill $barfg -outline {} -tags bar
        }
    }

    # Text overlay
    set font $opts(-font)
    if {$font eq {}} {
        set font [list [ttkbootstrap::getColor font] 10 bold]
    }

    set txt $opts(-text)
    if {$opts(-mask) ne {}} {
        set txt [format $opts(-mask) $val]
    }
    if {$txt ne {}} {
        set cx [expr {$W / 2.0}]
        set cy [expr {$H / 2.0}]
        # Shadow text (trough region) - clipped by bar
        $c create text $cx $cy \
            -text $txt -font $font \
            -fill $barfg -anchor center -tags textbg
        # Foreground text — white on bar portion
        # We simulate clipping with two text items and a clip rect overlay:
        # Simple approach: choose single contrast color
        set contrastfg [ttkbootstrap::_contrastFg $barfg]
        # If bar covers center, use contrast; else use fg
        if {$opts(-orient) eq "horizontal"} {
            set covered [expr {$frac * $W > $cx}]
        } else {
            set covered [expr {(1-$frac) * $H < $cy}]
        }
        set dispfg [expr {$covered ? $contrastfg : $txtfg}]
        $c itemconfigure textbg -fill $dispfg
    }

    # Border drawn last so it sits on top of fill.
    # Draw it at the 100% fill boundary, not full widget width.
    set bw 1
    if {$opts(-orient) eq "horizontal"} {
        set bx [expr {$frac * $W}]
        set bx [expr {$bx < $bw ? $bw : $bx}]
        $c create rectangle $bw $bw [expr {$bx - $bw}] [expr {$H - $bw}] \
            -outline [ttkbootstrap::getColor $opts(-bootstyle)] \
            -fill {} -tags border -width $bw
    } else {
        set by [expr {(1 - $frac) * $H}]
        set by [expr {$by > $H - $bw ? $H - $bw : $by}]
        $c create rectangle $bw $by [expr {$W - $bw}] [expr {$H - $bw}] \
            -outline [ttkbootstrap::getColor $opts(-bootstyle)] \
            -fill {} -tags border -width $bw
    }
}

proc _flood_resize {w nw nh} {
    set ns ::ttkbootstrap::floodgauge::$w
    array set opts [set ${ns}::opts]
    set opts(-width)  $nw
    set opts(-height) $nh
    set ${ns}::opts [array get opts]
    _flood_draw $w
}

proc _flood_setval {w val} {
    set ns ::ttkbootstrap::floodgauge::$w
    array set opts [set ${ns}::opts]
    set opts(-value) $val
    set ${ns}::opts [array get opts]
    _flood_draw $w
    if {$opts(-command) ne {}} { uplevel #0 $opts(-command) $val }
}

proc _flood_step {w {amount 1}} {
    set ns ::ttkbootstrap::floodgauge::$w
    array set opts [set ${ns}::opts]
    _flood_setval $w [expr {$opts(-value) + $amount}]
}

proc _flood_get {w} {
    set ns ::ttkbootstrap::floodgauge::$w
    array set opts [set ${ns}::opts]
    return $opts(-value)
}

proc _flood_varchange {w name1 name2 op} {
    if {![winfo exists $w]} return
    upvar #0 $name1 var
    _flood_setval $w $var
}

proc _flood_start {w {interval 50}} {
    set ns ::ttkbootstrap::floodgauge::$w
    set ${ns}::autoId [after $interval [list ttkbootstrap::_flood_auto $w $interval]]
}

proc _flood_stop {w} {
    set ns ::ttkbootstrap::floodgauge::$w
    if {[info exists ${ns}::autoId]} {
        after cancel [set ${ns}::autoId]
    }
}

proc _flood_auto {w interval} {
    set ns ::ttkbootstrap::floodgauge::$w
    array set opts [set ${ns}::opts]
    set newval [expr {$opts(-value) + 1}]
    if {$newval > $opts(-maximum)} { set newval 0 }
    _flood_setval $w $newval
    set ${ns}::autoId [after $interval [list ttkbootstrap::_flood_auto $w $interval]]
}

proc _flood_configure {w args} {
    set ns ::ttkbootstrap::floodgauge::$w
    array set opts [set ${ns}::opts]
    array set opts $args
    set ${ns}::opts [array get opts]
    _flood_draw $w
}

} ;# end namespace
