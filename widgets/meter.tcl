# =============================================================================
# meter.tcl — ttkbootstrap Meter widget
#
# A circular gauge widget drawn on a Canvas. Mimics ttkbootstrap's Meter.
#
# Usage:
#   ttkbootstrap::Meter .m \
#       -bootstyle success \
#       -amountused 65 \
#       -amounttotal 100 \
#       -metersize 200 \
#       -meterthickness 10 \
#       -subtext "GB Used" \
#       -textfont {Helvetica 24 bold}
#
# Options:
#   -amountused      Current value          (default 0)
#   -amounttotal     Maximum value          (default 100)
#   -metersize       Diameter in pixels     (default 200)
#   -meterthickness  Arc thickness          (default 10)
#   -metertype       full | semi            (default full)
#   -bootstyle       color keyword          (default primary)
#   -subtext         Label below value      (default "")
#   -subtextfont     Font for subtext       (default TkDefaultFont 8)
#   -textfont        Font for center value  (default TkDefaultFont 20 bold)
#   -showvalue       Show numeric value     (default 1)
#   -stripethickness 0 = solid arc, >0 = dashed stripes (default 0)
#   -interactive     Allow mouse dragging   (default 0)
#   -command         Script called on change
# =============================================================================

namespace eval ttkbootstrap {

proc Meter {w args} {
    # Defaults — metersize auto-scales with DPI if not explicitly set
    array set opts [list \
        -amountused      0 \
        -amounttotal     100 \
        -metersize       [ttkbootstrap::_sp 200] \
        -meterthickness  [ttkbootstrap::_sp 10] \
        -metertype       full \
        -bootstyle       primary \
        -subtext         {} \
        -subtextfont     {} \
        -textfont        {} \
        -showvalue       1 \
        -stripethickness 0 \
        -interactive     0 \
        -command         {} \
        -background      {} \
    ]
    array set opts $args

    # Resolve colours from current theme
    set fg     [ttkbootstrap::getColor $opts(-bootstyle)]
    set trof   [ttkbootstrap::getColor light]
    set bg     [expr {$opts(-background) ne {} ? $opts(-background) : [ttkbootstrap::getColor bg]}]
    set textfg [ttkbootstrap::getColor fg]

    set size  $opts(-metersize)
    set thick $opts(-meterthickness)

    # Font sizes: derive from the BASE design size (200px at 1x), not the scaled
    # size, because Tk automatically renders point sizes larger on HiDPI displays.
    # Using _sp(size)/8 would double-scale: once via _sp, once via tk scaling.
    set _base_size 200
    set tfont $opts(-textfont)
    if {$tfont eq {}} { set tfont [list [ttkbootstrap::getColor font] [expr {$_base_size/8}] bold] }
    set sfont $opts(-subtextfont)
    if {$sfont eq {}} { set sfont [list [ttkbootstrap::getColor font] [expr {$_base_size/16}]] }

    # Container frame
    ttk::frame $w
    set c [canvas $w.c \
        -width $size -height $size \
        -background $bg \
        -highlightthickness 0 \
        -borderwidth 0]
    pack $c

    # Store state on the canvas widget
    set ns ::ttkbootstrap::meter::$w
    namespace eval $ns {}
    set ${ns}::opts   [array get opts]
    set ${ns}::fg     $fg
    set ${ns}::trough $trof
    set ${ns}::bg     $bg
    set ${ns}::textfg $textfg
    set ${ns}::tfont  $tfont
    set ${ns}::sfont  $sfont
    set ${ns}::canvas $c

    _meter_draw $w
    _meter_resize $w $size

    # Update colors when theme changes
    bind $w <<ThemeChanged>> [list apply {{widget} {
        set ns ::ttkbootstrap::meter::$widget
        array set opts [set ${ns}::opts]
        set ${ns}::fg     [ttkbootstrap::getColor $opts(-bootstyle)]
        set ${ns}::trough [ttkbootstrap::getColor light]
        set ${ns}::bg     [ttkbootstrap::getColor bg]
        set ${ns}::textfg [ttkbootstrap::getColor fg]
        $widget.c configure -background [ttkbootstrap::getColor bg]
        ttkbootstrap::_meter_draw $widget
    }} $w]

    # Interactive dragging
    if {$opts(-interactive)} {
        bind $c <Button-1>        [list ttkbootstrap::_meter_click $w %x %y]
        bind $c <B1-Motion>       [list ttkbootstrap::_meter_click $w %x %y]
    }

    # Public accessor procs hanging off the widget path
    interp alias {} ${w}.configure {} ttkbootstrap::_meter_configure $w
    interp alias {} ${w}.get       {} ttkbootstrap::_meter_get $w
    interp alias {} ${w}.set       {} ttkbootstrap::_meter_setval $w
    interp alias {} ${w}.step      {} ttkbootstrap::_meter_step $w

    return $w
}

proc _meter_draw {w} {
    set ns ::ttkbootstrap::meter::$w
    array set opts [set ${ns}::opts]
    set c   [set ${ns}::canvas]
    set fg  [set ${ns}::fg]
    set trof [set ${ns}::trough]
    set bg  [set ${ns}::bg]
    set textfg [set ${ns}::textfg]
    set tfont [set ${ns}::tfont]
    set sfont [set ${ns}::sfont]

    $c delete all

    set size  $opts(-metersize)
    set thick $opts(-meterthickness)
    set pad   [expr {$thick + 4}]
    set x0    $pad
    set y0    $pad
    set x1    [expr {$size - $pad}]
    set y1    [expr {$size - $pad}]

    set isFull [expr {$opts(-metertype) eq "full"}]

    if {$isFull} {
        set startAngle 225
        set totalArc   270
    } else {
        set startAngle 180
        set totalArc   180
    }

    set used  [expr {double($opts(-amountused))}]
    set total [expr {double($opts(-amounttotal))}]
    set total [expr {$total == 0 ? 1 : $total}]
    set frac  [expr {$used / $total}]
    set frac  [expr {$frac < 0 ? 0.0 : ($frac > 1 ? 1.0 : $frac)}]

    # Trough arc
    $c create arc $x0 $y0 $x1 $y1 \
        -start $startAngle \
        -extent -$totalArc \
        -style arc \
        -outline $trof \
        -width $thick \
        -tags trough

    # Value arc
    set valExtent [expr {-$frac * $totalArc}]
    if {abs($valExtent) > 0.5} {
        if {$opts(-stripethickness) > 0} {
            set st $opts(-stripethickness)
            set gap [expr {$st / 2}]
            set step [expr {($st + $gap) / ($totalArc * 3.14159 * ($size - 2*$pad) / 2 / 360.0)}]
            set step [expr {$step < 2 ? 2 : $step}]
            for {set a 0} {$a < abs($valExtent)} {set a [expr {$a + $step}]} {
                set segEnd [expr {min($a + $st, abs($valExtent))}]
                $c create arc $x0 $y0 $x1 $y1 \
                    -start [expr {$startAngle - $a}] \
                    -extent [expr {-($segEnd - $a)}] \
                    -style arc \
                    -outline $fg \
                    -width $thick
            }
        } else {
            $c create arc $x0 $y0 $x1 $y1 \
                -start $startAngle \
                -extent $valExtent \
                -style arc \
                -outline $fg \
                -width $thick \
                -tags valuearc
        }
    }

    # Center text
    set cx [expr {$size / 2.0}]
    set cy [expr {$size / 2.0}]
    if {!$isFull} { set cy [expr {$cy * 0.82}] }

    if {$opts(-showvalue)} {
        set dispval [expr {int($opts(-amountused))}]
        $c create text $cx $cy \
            -text $dispval \
            -font $tfont \
            -fill $textfg \
            -anchor center \
            -tags valtext
    }

    if {$opts(-subtext) ne {}} {
        set sy [expr {$cy + $size/5.5}]
        $c create text $cx $sy \
            -text $opts(-subtext) \
            -font $sfont \
            -fill $textfg \
            -anchor center \
            -tags subtext
    }
}

proc _meter_resize {w size} {
    set ns ::ttkbootstrap::meter::$w
    set c [set ${ns}::canvas]
    $c configure -width $size -height $size
}

proc _meter_click {w x y} {
    set ns ::ttkbootstrap::meter::$w
    array set opts [set ${ns}::opts]
    set size $opts(-metersize)
    set cx [expr {$size / 2.0}]
    set cy [expr {$size / 2.0}]

    set dx [expr {$x - $cx}]
    set dy [expr {$cy - $y}]
    set angle [expr {atan2($dy, $dx) * 180 / 3.14159265}]

    if {$opts(-metertype) eq "full"} {
        # Map angle (-225..45) to fraction
        set a [expr {fmod($angle - 225 + 360, 360)}]
        if {$a > 270} { set a 270 }
        set frac [expr {$a / 270.0}]
    } else {
        set a [expr {$angle + 180}]
        if {$a < 0} { set a 0 }
        if {$a > 180} { set a 180 }
        set frac [expr {$a / 180.0}]
    }

    set newval [expr {int($frac * $opts(-amounttotal))}]
    _meter_setval $w $newval
}

proc _meter_setval {w val} {
    set ns ::ttkbootstrap::meter::$w
    array set opts [set ${ns}::opts]
    set opts(-amountused) $val
    set ${ns}::opts [array get opts]
    _meter_draw $w
    if {$opts(-command) ne {}} {
        uplevel #0 $opts(-command) $val
    }
}

proc _meter_step {w {amount 1}} {
    set ns ::ttkbootstrap::meter::$w
    array set opts [set ${ns}::opts]
    _meter_setval $w [expr {$opts(-amountused) + $amount}]
}

proc _meter_get {w} {
    set ns ::ttkbootstrap::meter::$w
    array set opts [set ${ns}::opts]
    return $opts(-amountused)
}

proc _meter_configure {w args} {
    set ns ::ttkbootstrap::meter::$w
    array set opts [set ${ns}::opts]
    array set opts $args
    # Re-resolve color if bootstyle changed
    set ${ns}::fg [ttkbootstrap::getColor $opts(-bootstyle)]
    set ${ns}::opts [array get opts]
    _meter_draw $w
}

} ;# end namespace ttkbootstrap
