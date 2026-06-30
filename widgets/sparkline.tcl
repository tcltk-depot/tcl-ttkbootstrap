# =============================================================================
# sparkline.tcl — Inline canvas mini-chart (single data series, no axes)
#
# USAGE
#   ttkbootstrap::SparkLine .sl \
#       -data      {12 34 28 45 39 52 61 48 55 63} \
#       -bootstyle primary \
#       -width     80 \
#       -height    24 \
#       -type      line
#   pack .sl -side left
#
#   # Update data live
#   ttkbootstrap::SparkLineset .sl {23 45 12 67 34 78}
#
#   # Append a single value (scrolling window)
#   ttkbootstrap::SparkLine::push .sl 72 -maxpoints 20
#
# OPTIONS
#   -data       list    Data values (default: {})
#   -bootstyle  color   Line/bar colour (default: primary)
#   -width      int     Canvas width  (default: 80)
#   -height     int     Canvas height (default: 24)
#   -type       line|bar  Chart type (default: line)
#   -filled     0|1     Fill area under line (default: 1 for line)
#   -smooth     0|1     Smooth the line (default: 1)
#   -minval     {}|num  Y-axis minimum (default: auto)
#   -maxval     {}|num  Y-axis maximum (default: auto)
#   -dot        0|1     Show dot at last value (default: 1)
#
# METHODS
#   SparkLineset       sl data          — replace data and redraw
#   SparkLine::push      sl value ?-maxpoints n? — append and redraw
#   SparkLine::get       sl               — return current data list
# =============================================================================

namespace eval ttkbootstrap {

proc SparkLine {w args} {
    array set opts {
        -data      {}
        -bootstyle primary
        -width     80
        -height    24
        -type      line
        -filled    1
        -smooth    1
        -minval    {}
        -maxval    {}
        -dot       1
    }
    array set opts $args

    set ns ::ttkbootstrap::sl::$w
    namespace eval $ns {}
    set ${ns}::opts [array get opts]
    set ${ns}::data $opts(-data)

    set cw [ttkbootstrap::_sp $opts(-width)]
    set ch [ttkbootstrap::_sp $opts(-height)]

    set c [canvas $w \
        -width              $cw \
        -height             $ch \
        -highlightthickness 0 \
        -borderwidth        0 \
        -background         [ttkbootstrap::getColor bg]]
    set ${ns}::canvas $c

    bind $c <<ThemeChanged>> [list ttkbootstrap::_sl_draw $w]
    after idle [list ttkbootstrap::_sl_draw $w]

    return $c
}

proc _sl_draw {w} {
    set ns ::ttkbootstrap::sl::$w
    if {![namespace exists $ns]} return
    set c [set ${ns}::canvas]
    if {![winfo exists $c]} return

    array set o [set ${ns}::opts]
    set data [set ${ns}::data]

    $c delete all
    $c configure -background [ttkbootstrap::getColor bg]

    if {[llength $data] < 2} return

    set cw [winfo width  $c]
    set ch [winfo height $c]
    if {$cw < 2} { set cw [ttkbootstrap::_sp $o(-width)] }
    if {$ch < 2} { set ch [ttkbootstrap::_sp $o(-height)] }

    set hex  [ttkbootstrap::getColor $o(-bootstyle)]
    set fill [ttkbootstrap::Colors::update_hsv $hex -sd -0.3 -vd 0.3]

    # Value range
    set mn [expr {$o(-minval) ne {} ? $o(-minval) : [tcl::mathfunc::min {*}$data]}]
    set mx [expr {$o(-maxval) ne {} ? $o(-maxval) : [tcl::mathfunc::max {*}$data]}]
    if {$mn == $mx} { set mx [expr {$mn + 1.0}] }

    set n   [llength $data]
    set pad [ttkbootstrap::_sp 2]
    set aw  [expr {$cw - 2*$pad}]
    set ah  [expr {$ch - 2*$pad}]

    proc _sl_y {v mn mx ah pad} {
        expr {$pad + $ah * (1.0 - ($v - $mn) / double($mx - $mn))}
    }

    if {$o(-type) eq "bar"} {
        set bw [expr {double($aw) / $n}]
        set gap [expr {max(1, int($bw * 0.15))}]
        for {set i 0} {$i < $n} {incr i} {
            set v  [lindex $data $i]
            set x1 [expr {$pad + $i * $bw + $gap}]
            set x2 [expr {$pad + ($i+1) * $bw - $gap}]
            set y1 [_sl_y $v $mn $mx $ah $pad]
            set y2 [expr {$pad + $ah}]
            $c create rectangle $x1 $y1 $x2 $y2 \
                -fill $hex -outline {} -width 0
        }
    } else {
        # Build coordinate list
        set pts {}
        for {set i 0} {$i < $n} {incr i} {
            set v [lindex $data $i]
            set x [expr {$pad + $i * double($aw) / ($n - 1)}]
            set y [_sl_y $v $mn $mx $ah $pad]
            lappend pts $x $y
        }

        # Filled polygon
        if {$o(-filled)} {
            set poly_pts [list $pad [expr {$pad+$ah}]]
            foreach {x y} $pts { lappend poly_pts $x $y }
            lappend poly_pts [expr {$pad+$aw}] [expr {$pad+$ah}]
            $c create polygon {*}$poly_pts \
                -fill    $fill \
                -outline {} \
                -smooth  [expr {$o(-smooth) ? 1 : 0}]
        }

        # Line
        $c create line {*}$pts \
            -fill       $hex \
            -width      [ttkbootstrap::_sp 2] \
            -capstyle   round \
            -joinstyle  round \
            -smooth     [expr {$o(-smooth) ? 1 : 0}]

        # Dot at last point
        if {$o(-dot) && [llength $pts] >= 2} {
            set lx [lindex $pts end-1]
            set ly [lindex $pts end]
            set r  [ttkbootstrap::_sp 3]
            $c create oval \
                [expr {$lx-$r}] [expr {$ly-$r}] \
                [expr {$lx+$r}] [expr {$ly+$r}] \
                -fill $hex -outline [ttkbootstrap::getColor bg] \
                -width [ttkbootstrap::_sp 1]
        }
    }

    rename _sl_y {}
}

} ;# end namespace ttkbootstrap

namespace eval ttkbootstrap::SparkLine {}

proc ttkbootstrap::SparkLine::load {w data} {
    set ns ::ttkbootstrap::sl::$w
    set ${ns}::data $data
    ttkbootstrap::_sl_draw $w
}

proc ttkbootstrap::SparkLine::push {w value args} {
    array set opts {-maxpoints 50}
    array set opts $args
    set ns ::ttkbootstrap::sl::$w
    set data [set ${ns}::data]
    lappend data $value
    if {[llength $data] > $opts(-maxpoints)} {
        set data [lrange $data end-[expr {$opts(-maxpoints)-1}] end]
    }
    set ${ns}::data $data
    ttkbootstrap::_sl_draw $w
}

proc ttkbootstrap::SparkLine::get {w} {
    return [set ::ttkbootstrap::sl::${w}::data]
}

# Compatibility alias
proc ttkbootstrap::SparkLineset {args} { ttkbootstrap::SparkLine::load {*}$args }
