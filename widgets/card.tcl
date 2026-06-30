# =============================================================================
# card.tcl — Titled content card
#
# USAGE
#   set c [ttkbootstrap::Card .c \
#       -title     "Summary" \
#       -bootstyle primary \
#       -padding   10]
#   pack $c -fill both -expand 1
#
#   # Access the body frame for packing children into
#   set body [ttkbootstrap::Card::body $c]
#   ttk::label $body.l -text "Hello"
#   pack $body.l
#
#   # Optional footer
#   set foot [ttkbootstrap::Card::footer $c]
#   ttk::button $foot.ok -text "OK"
#   pack $foot.ok -side right
#
# OPTIONS
#   -title      string   Header title text (default: {})
#   -subtitle   string   Smaller text below title (default: {})
#   -bootstyle  color    Accent colour for header stripe (default: primary)
#                        Use {} for a plain (no-colour) header
#   -padding    int      Body padding (default: 10)
#   -relief     flat|groove|solid  Border style (default: flat)
#   -borderwidth int     Border width (default: 1)
#
# METHODS
#   Card::body   c  — returns the body frame path
#   Card::footer c  — returns (creating if needed) the footer frame path
#   Card::title  c ?text?  — get or set the title
# =============================================================================

namespace eval ttkbootstrap {

proc Card {w args} {
    array set opts {
        -title       {}
        -subtitle    {}
        -bootstyle   primary
        -padding     10
        -relief      flat
        -borderwidth 1
    }
    array set opts $args

    set ns ::ttkbootstrap::card::$w
    namespace eval $ns {}
    set ${ns}::opts [array get opts]

    set bg     [ttkbootstrap::getColor bg]
    set border [ttkbootstrap::getColor border]

    # Outer border frame
    set outer [ttk::frame $w \
        -relief      $opts(-relief) \
        -borderwidth [ttkbootstrap::_sp $opts(-borderwidth)]]
    set ${ns}::outer $outer

    # Accent stripe (top border in bootstyle colour)
    if {$opts(-bootstyle) ne {}} {
        set hex [ttkbootstrap::getColor $opts(-bootstyle)]
        frame $outer.stripe \
            -background $hex \
            -height     [ttkbootstrap::_sp 3] \
            -borderwidth 0
        pack $outer.stripe -fill x -side top
        set ${ns}::stripe $outer.stripe
    }

    # Header
    set hdr [ttk::frame $outer.hdr \
        -padding [ttkbootstrap::_sp2 [expr {$opts(-padding)+2}] \
                                     [expr {$opts(-padding)/2}]]]
    pack $hdr -fill x -side top
    set ${ns}::hdr $hdr

    if {$opts(-title) ne {}} {
        set tlbl [ttk::label $hdr.title \
            -text   $opts(-title) \
            -font   [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                         [ttkbootstrap::_sf 12] bold] \
            -anchor w]
        pack $tlbl -fill x
        set ${ns}::title_lbl $tlbl
    }
    if {$opts(-subtitle) ne {}} {
        set slbl [ttk::label $hdr.sub \
            -text       $opts(-subtitle) \
            -foreground [ttkbootstrap::getColor secondary] \
            -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                             [ttkbootstrap::_sf 11]] \
            -anchor     w]
        pack $slbl -fill x
        set ${ns}::subtitle_lbl $slbl
    }

    # Divider under header (only if there's a title)
    if {$opts(-title) ne {}} {
        ttk::separator $outer.div -orient horizontal
        pack $outer.div -fill x -side top
    }

    # Body frame
    set body [ttk::frame $outer.body \
        -padding [ttkbootstrap::_sp $opts(-padding)]]
    pack $body -fill both -expand 1 -side top
    set ${ns}::body $body

    # Footer not created until Card::footer is called
    set ${ns}::footer {}

    bind $outer <<ThemeChanged>> [list ttkbootstrap::_card_restyle $w]

    return $outer
}

proc _card_restyle {w} {
    set ns ::ttkbootstrap::card::$w
    if {![namespace exists $ns]} return
    array set o [set ${ns}::opts]
    if {$o(-bootstyle) ne {} && [winfo exists ${w}.stripe]} {
        ${w}.stripe configure \
            -background [ttkbootstrap::getColor $o(-bootstyle)]
    }
    if {[winfo exists ${w}.hdr.sub]} {
        ${w}.hdr.sub configure \
            -foreground [ttkbootstrap::getColor secondary]
    }
}

} ;# end namespace ttkbootstrap

namespace eval ttkbootstrap::Card {}

proc ttkbootstrap::Card::body {w} {
    return [set ::ttkbootstrap::card::${w}::body]
}

proc ttkbootstrap::Card::footer {w} {
    set ns ::ttkbootstrap::card::$w
    set foot [set ${ns}::footer]
    if {$foot eq {} || ![winfo exists $foot]} {
        # Create separator + footer frame
        ttk::separator ${w}.footsep -orient horizontal
        pack ${w}.footsep -fill x -side bottom
        set foot [ttk::frame ${w}.footer \
            -padding [ttkbootstrap::_sp2 8 6]]
        pack $foot -fill x -side bottom
        set ${ns}::footer $foot
    }
    return $foot
}

proc ttkbootstrap::Card::title {w {text {}}} {
    set ns ::ttkbootstrap::card::$w
    if {$text eq {}} {
        set lbl [set ${ns}::title_lbl]
        return [$lbl cget -text]
    }
    set lbl [set ${ns}::title_lbl]
    $lbl configure -text $text
}
