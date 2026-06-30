# =============================================================================
# timeline.tcl — Vertical list of timestamped events
#
# USAGE
#   set tl [ttkbootstrap::Timeline .tl]
#   pack $tl -fill both -expand 1
#
#   ttkbootstrap::Timeline::add $tl \
#       -title     "Deployed v2.0" \
#       -timestamp "2024-05-10 14:32" \
#       -body      "All services updated and running." \
#       -bootstyle success \
#       -icon      "✓"
#
#   ttkbootstrap::Timeline::add $tl \
#       -title     "Build failed" \
#       -timestamp "2024-05-10 12:15" \
#       -body      "Tests failed in module auth." \
#       -bootstyle danger \
#       -icon      "✗"
#
#   ttkbootstrap::Timeline::clear $tl
#
# EVENT OPTIONS
#   -title     string   Event title (bold)
#   -timestamp string   Date/time string (shown muted)
#   -body      string   Event description (optional)
#   -bootstyle color    Dot/icon colour (default: primary)
#   -icon      string   Single char shown in the dot (default: •)
# =============================================================================

namespace eval ttkbootstrap {

proc Timeline {w args} {
    array set opts {}
    array set opts $args

    set ns ::ttkbootstrap::tl::$w
    namespace eval $ns {}
    set ${ns}::count 0

    set sf [ttkbootstrap::ScrolledFrame $w]
    # Store the ScrolledFrame path; resolve interior fresh on each operation
    # because the widget may be destroyed and recreated between calls
    set ${ns}::sf_path $w
    set ${ns}::sf $sf

    bind $sf <<ThemeChanged>> [list ttkbootstrap::_tl_restyle $w]

    return $sf
}

proc _tl_restyle {w} {
    # Theme changes propagate to child labels via option add
}

} ;# end namespace ttkbootstrap

namespace eval ttkbootstrap::Timeline {}

proc ttkbootstrap::Timeline::add {w args} {
    array set opts {
        -title     {}
        -timestamp {}
        -body      {}
        -bootstyle primary
        -icon      •
    }
    array set opts $args

    set ns  ::ttkbootstrap::tl::$w
    set sf_path [set ${ns}::sf_path]
    set inner [${sf_path}.interior]
    set i     [incr ${ns}::count]

    set hex [ttkbootstrap::getColor $opts(-bootstyle)]
    set fg  [ttkbootstrap::_contrastFg $hex]
    set bg  [ttkbootstrap::getColor bg]
    set sfg [ttkbootstrap::getColor secondary]
    set tbg [ttkbootstrap::getColor light]

    # Row frame
    set row [frame $inner.row$i -background $bg -borderwidth 0]
    pack $row -fill x -pady [ttkbootstrap::_sp 2]

    # Left column: dot + vertical line
    set left [frame $row.left -background $bg -width [ttkbootstrap::_sp 32]]
    pack $left -side left -fill y
    $left configure -width [ttkbootstrap::_sp 32]

    # Dot
    label $left.dot \
        -text       $opts(-icon) \
        -background $hex \
        -foreground $fg \
        -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                         [ttkbootstrap::_sf 11] bold] \
        -width      2 \
        -anchor     center \
        -padx       [ttkbootstrap::_sp 4] \
        -pady       [ttkbootstrap::_sp 4] \
        -relief     flat
    place $left.dot -anchor n -relx 0.5 -y [ttkbootstrap::_sp 4]

    # Connector line (below dot)
    # Only draw if not the first item
    if {$i > 1} {
        set prev_row $inner.row[expr {$i-1}]
        if {[winfo exists $prev_row.left.line]} {
            # Already has line
        }
    }
    frame $left.line \
        -background [ttkbootstrap::getColor border] \
        -width      [ttkbootstrap::_sp 1]
    place $left.line \
        -anchor n \
        -relx   0.5 \
        -y      [ttkbootstrap::_sp 28] \
        -width  [ttkbootstrap::_sp 1] \
        -relheight 1.0

    # Right column: title, timestamp, body
    set right [frame $row.right -background $bg -padx [ttkbootstrap::_sp 8]]
    pack $right -side left -fill both -expand 1 \
        -pady [ttkbootstrap::_sp2 4 8]

    # Title + timestamp row
    set top [frame $right.top -background $bg]
    pack $top -fill x

    if {$opts(-title) ne {}} {
        label $top.title \
            -text       $opts(-title) \
            -background $bg \
            -foreground [ttkbootstrap::getColor fg] \
            -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                             [ttkbootstrap::_sf 12] bold] \
            -anchor     w
        pack $top.title -side left
    }

    if {$opts(-timestamp) ne {}} {
        label $top.ts \
            -text       $opts(-timestamp) \
            -background $bg \
            -foreground $sfg \
            -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                             [ttkbootstrap::_sf 10]] \
            -anchor     e
        pack $top.ts -side right
    }

    # Body text
    if {$opts(-body) ne {}} {
        label $right.body \
            -text       $opts(-body) \
            -background $tbg \
            -foreground [ttkbootstrap::getColor fg] \
            -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                             [ttkbootstrap::_sf 11]] \
            -anchor     w \
            -justify    left \
            -wraplength [ttkbootstrap::_sp 300] \
            -padx       [ttkbootstrap::_sp 8] \
            -pady       [ttkbootstrap::_sp 4] \
            -relief     flat
        pack $right.body -fill x -pady [ttkbootstrap::_sp2 4 0]
    }

    return $row
}

proc ttkbootstrap::Timeline::clear {w} {
    set ns ::ttkbootstrap::tl::$w
    set sf_path [set ${ns}::sf_path]
    set inner [${sf_path}.interior]
    foreach child [winfo children $inner] { destroy $child }
    set ${ns}::count 0
}
