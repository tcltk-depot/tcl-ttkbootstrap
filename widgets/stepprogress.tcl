# =============================================================================
# stepprogress.tcl — Horizontal step indicator / wizard progress bar
#
# USAGE
#   set sp [ttkbootstrap::StepProgress .sp \
#       -steps   {"Account" "Profile" "Settings" "Done"} \
#       -current 0 \
#       -bootstyle primary]
#   pack $sp -fill x -padx 20 -pady 10
#
#   # Advance to step 2
#   ttkbootstrap::StepProgressset .sp 1
#   # Or next/prev
#   ttkbootstrap::StepProgress::next .sp
#   ttkbootstrap::StepProgress::prev .sp
#
# OPTIONS
#   -steps      list    Step label strings (required)
#   -current    int     0-based index of current step (default: 0)
#   -bootstyle  color   Active step colour (default: primary)
#   -complete   color   Completed step colour (default: success)
#   -size       int     Circle diameter in pixels (default: 28)
#   -command    script  Called with current index when step changes
#
# METHODS
#   StepProgressset    sp index    — jump to step index
#   StepProgress::next   sp          — advance one step
#   StepProgress::prev   sp          — go back one step
#   StepProgress::current sp         — return current 0-based index
# =============================================================================

namespace eval ttkbootstrap {

proc StepProgress {w args} {
    array set opts {
        -steps     {}
        -current   0
        -bootstyle primary
        -complete  success
        -size      28
        -command   {}
    }
    array set opts $args

    set ns ::ttkbootstrap::sp::$w
    namespace eval $ns {}
    set ${ns}::opts    [array get opts]
    set ${ns}::current $opts(-current)

    set sz  [ttkbootstrap::_sp $opts(-size)]
    set ${ns}::sz $sz

    # Canvas-based drawing — scales cleanly
    set n    [llength $opts(-steps)]
    set cw   680   ;# logical design width
    set ch   [expr {$sz + [ttkbootstrap::_sp 40]}]  ;# circle + label below

    set c [canvas $w \
        -highlightthickness 0 \
        -borderwidth        0 \
        -height             $ch \
        -background         [ttkbootstrap::getColor bg]]
    set ${ns}::canvas $c

    bind $c <Configure> [list ttkbootstrap::_sp_draw $w]
    bind $c <<ThemeChanged>> [list ttkbootstrap::_sp_draw $w]

    # Draw initial state after layout
    after idle [list ttkbootstrap::_sp_draw $w]

    return $c
}

proc _sp_draw {w} {
    set ns ::ttkbootstrap::sp::$w
    if {![namespace exists $ns]} return
    set c [set ${ns}::canvas]
    if {![winfo exists $c]} return

    array set o [set ${ns}::opts]
    set current [set ${ns}::current]
    set sz      [set ${ns}::sz]
    set steps   $o(-steps)
    set n       [llength $steps]
    if {$n == 0} return

    set cw [winfo width  $c]
    set ch [winfo height $c]
    if {$cw < 2} { set cw 400 }

    $c delete all
    $c configure -background [ttkbootstrap::getColor bg]

    # Colours
    set active_hex  [ttkbootstrap::getColor $o(-bootstyle)]
    set done_hex    [ttkbootstrap::getColor $o(-complete)]
    set pending_hex [ttkbootstrap::getColor light]
    set border_hex  [ttkbootstrap::getColor border]
    set bg_hex      [ttkbootstrap::getColor bg]
    set fg_hex      [ttkbootstrap::getColor fg]
    set active_fg   [ttkbootstrap::_contrastFg $active_hex]
    set done_fg     [ttkbootstrap::_contrastFg $done_hex]
    set pending_fg  [ttkbootstrap::_contrastFg $pending_hex]

    set r    [expr {$sz / 2}]
    set cy   [expr {$r + [ttkbootstrap::_sp 4]}]
    set side_pad [ttkbootstrap::_sp 40]
    set step [expr {double($cw - $sz - 2*$side_pad) / max($n - 1, 1)}]
    set font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                   [ttkbootstrap::_sf 11] bold]
    set lblfont [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                      [ttkbootstrap::_sf 11]]

    # Draw connector lines between circles
    for {set i 0} {$i < $n - 1} {incr i} {
        set x1 [expr {int($r + $side_pad + $i * $step + $r)}]
        set x2 [expr {int($r + $side_pad + ($i+1) * $step - $r)}]
        set col [expr {$i < $current ? $done_hex : $border_hex}]
        $c create line $x1 $cy $x2 $cy \
            -fill       $col \
            -width      [ttkbootstrap::_sp 2] \
            -capstyle   round
    }

    # Draw step circles
    for {set i 0} {$i < $n} {incr i} {
        set cx [expr {int($r + $side_pad + $i * $step)}]
        set x1 [expr {$cx - $r}]; set y1 [expr {$cy - $r}]
        set x2 [expr {$cx + $r}]; set y2 [expr {$cy + $r}]

        if {$i < $current} {
            # Done — filled with complete colour, checkmark
            $c create oval $x1 $y1 $x2 $y2 \
                -fill    $done_hex \
                -outline $done_hex
            $c create text $cx $cy \
                -text   "✓" \
                -fill   $done_fg \
                -font   $font \
                -anchor center
        } elseif {$i == $current} {
            # Active — filled with bootstyle colour
            $c create oval $x1 $y1 $x2 $y2 \
                -fill    $active_hex \
                -outline $active_hex
            $c create text $cx $cy \
                -text   [expr {$i + 1}] \
                -fill   $active_fg \
                -font   $font \
                -anchor center
        } else {
            # Pending — light fill, border
            $c create oval $x1 $y1 $x2 $y2 \
                -fill    $pending_hex \
                -outline $border_hex \
                -width   [ttkbootstrap::_sp 1]
            $c create text $cx $cy \
                -text   [expr {$i + 1}] \
                -fill   $fg_hex \
                -font   $font \
                -anchor center
        }

        # Step label below circle
        set label_y [expr {$cy + $r + [ttkbootstrap::_sp 6]}]
        set label_col [expr {$i == $current ? $active_hex : $fg_hex}]
        $c create text $cx $label_y \
            -text   [lindex $steps $i] \
            -fill   $label_col \
            -font   $lblfont \
            -anchor n
    }
}

} ;# end namespace ttkbootstrap

namespace eval ttkbootstrap::StepProgress {}

proc ttkbootstrap::StepProgress::goto {w index} {
    set ns ::ttkbootstrap::sp::$w
    if {![namespace exists $ns]} return
    array set o [set ${ns}::opts]
    set n [llength $o(-steps)]
    if {$index < 0}      { set index 0 }
    if {$index >= $n}    { set index [expr {$n-1}] }
    set ${ns}::current $index
    ttkbootstrap::_sp_draw $w
    if {$o(-command) ne {}} { uplevel #0 $o(-command) }
}

proc ttkbootstrap::StepProgress::next {w} {
    set ns ::ttkbootstrap::sp::$w
    set cur [set ${ns}::current]
    ttkbootstrap::StepProgress::goto $w [expr {$cur + 1}]
}

proc ttkbootstrap::StepProgress::prev {w} {
    set ns ::ttkbootstrap::sp::$w
    set cur [set ${ns}::current]
    ttkbootstrap::StepProgress::goto $w [expr {$cur - 1}]
}

proc ttkbootstrap::StepProgress::current {w} {
    return [set ::ttkbootstrap::sp::${w}::current]
}

# Compatibility alias
proc ttkbootstrap::StepProgressset {args} { ttkbootstrap::StepProgress::goto {*}$args }
