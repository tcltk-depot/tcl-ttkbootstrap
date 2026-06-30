# =============================================================================
# ratingbar.tcl — Clickable star (or custom symbol) rating widget
#
# USAGE
#   ttkbootstrap::RatingBar .r \
#       -variable  ::my_rating \
#       -maximum   5 \
#       -bootstyle warning \
#       -command   { puts "rated: $::my_rating" }
#   pack .r
#
#   # Read-only display
#   ttkbootstrap::RatingBar .r2 -value 3.5 -readonly 1
#   pack .r2
#
# OPTIONS
#   -variable   varname  Linked variable (integer 0..maximum)
#   -value      float    Initial value (used if no -variable, supports 0.5 steps)
#   -maximum    int      Number of stars (default: 5)
#   -bootstyle  color    Filled star colour (default: warning)
#   -symbol     string   Character used for stars (default: ★)
#   -size       int      Font size for stars (default: 20)
#   -readonly   0|1      If 1, clicking is disabled (default: 0)
#   -command    script   Called with current value when changed
# =============================================================================

namespace eval ttkbootstrap {

proc RatingBar {w args} {
    array set opts {
        -variable  {}
        -value     0
        -maximum   5
        -bootstyle warning
        -symbol    ★
        -size      20
        -readonly  0
        -command   {}
    }
    array set opts $args

    set ns ::ttkbootstrap::rb::$w
    namespace eval $ns {}
    set ${ns}::opts [array get opts]

    # If variable given, bind to it; else use internal
    if {$opts(-variable) ne {}} {
        set ${ns}::var $opts(-variable)
        if {![info exists $opts(-variable)]} {
            set $opts(-variable) $opts(-value)
        }
    } else {
        set ${ns}::intvar $opts(-value)
        set ${ns}::var    ${ns}::intvar
    }

    set f [frame $w -background [ttkbootstrap::getColor bg] -borderwidth 0]
    set ${ns}::frame $f

    set font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                   [ttkbootstrap::_sf $opts(-size)]]

    set on_hex   [ttkbootstrap::getColor $opts(-bootstyle)]
    set off_hex  [ttkbootstrap::getColor light]
    set bg_hex   [ttkbootstrap::getColor bg]

    for {set i 1} {$i <= $opts(-maximum)} {incr i} {
        set star [label $f.s$i \
            -text       $opts(-symbol) \
            -background $bg_hex \
            -foreground $off_hex \
            -font       $font \
            -padx       [ttkbootstrap::_sp 2] \
            -pady       0 \
            -cursor     [expr {$opts(-readonly) ? {} : "hand2"}]]
        pack $star -side left

        if {!$opts(-readonly)} {
            bind $star <Button-1> [list ttkbootstrap::_rb_click $w $i]
            bind $star <Enter>    [list ttkbootstrap::_rb_hover $w $i 1]
            bind $star <Leave>    [list ttkbootstrap::_rb_hover $w $i 0]
        }
        set ${ns}::star$i $star
    }

    # Trace variable for external updates
    set var [set ${ns}::var]
    trace add variable $var write [list ttkbootstrap::_rb_update $w]

    # Remove the trace and clean up the namespace when the widget is destroyed
    bind $f <Destroy> [list ttkbootstrap::_rb_destroy $w $var]

    bind $f <<ThemeChanged>> [list ttkbootstrap::_rb_restyle $w]

    # Initial draw
    after idle [list ttkbootstrap::_rb_update $w {} {} {}]

    return $f
}

proc _rb_click {w i} {
    set ns ::ttkbootstrap::rb::$w
    array set o [set ${ns}::opts]
    set var [set ${ns}::var]
    # Toggle: clicking current value resets to 0
    set cur [set $var]
    set $var [expr {$cur == $i ? 0 : $i}]
    if {$o(-command) ne {}} { uplevel #0 $o(-command) }
}

proc _rb_hover {w i on} {
    set ns ::ttkbootstrap::rb::$w
    if {![namespace exists $ns]} return
    array set o [set ${ns}::opts]
    set on_hex  [ttkbootstrap::getColor $o(-bootstyle)]
    set off_hex [ttkbootstrap::getColor light]
    set bg_hex  [ttkbootstrap::getColor bg]
    if {$on} {
        for {set j 1} {$j <= $o(-maximum)} {incr j} {
            set star [set ${ns}::star$j]
            $star configure \
                -foreground [expr {$j <= $i ? $on_hex : $off_hex}] \
                -background $bg_hex
        }
    } else {
        _rb_update $w {} {} {}
    }
}

proc _rb_update {w args} {
    set ns ::ttkbootstrap::rb::$w
    if {![namespace exists $ns]} return
    if {![winfo exists $w]} return
    array set o [set ${ns}::opts]
    set var     [set ${ns}::var]
    set val     [set $var]
    set on_hex  [ttkbootstrap::getColor $o(-bootstyle)]
    set half    [ttkbootstrap::Colors::update_hsv $on_hex -sd -0.3 -vd 0.2]
    set off_hex [ttkbootstrap::getColor light]
    set bg_hex  [ttkbootstrap::getColor bg]

    for {set j 1} {$j <= $o(-maximum)} {incr j} {
        set star [set ${ns}::star$j]
        if {$j <= int($val)} {
            set col $on_hex
        } elseif {$j <= $val + 0.5} {
            set col $half
        } else {
            set col $off_hex
        }
        $star configure -foreground $col -background $bg_hex
    }
}

proc _rb_destroy {w var} {
    # Remove the write trace so stale callbacks don't fire after the widget is gone
    catch { trace remove variable $var write [list ttkbootstrap::_rb_update $w] }
    catch { namespace delete ::ttkbootstrap::rb::$w }
}

proc _rb_restyle {w} {
    set ns ::ttkbootstrap::rb::$w
    if {![namespace exists $ns]} return
    array set o [set ${ns}::opts]
    [set ${ns}::frame] configure -background [ttkbootstrap::getColor bg]
    _rb_update $w {} {} {}
}

} ;# end namespace ttkbootstrap
