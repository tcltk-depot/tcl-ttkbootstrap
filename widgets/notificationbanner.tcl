# =============================================================================
# notificationbanner.tcl — Persistent coloured notification banner
#
# Unlike Toast (which is timed and floating), NotificationBanner is a
# persistent frame that docks inside the application layout and stays until
# explicitly dismissed by the user or the calling code.
#
# USAGE
#   set nb [ttkbootstrap::NotificationBanner . \
#       -message   "Your session will expire in 10 minutes." \
#       -bootstyle warning \
#       -position  top \
#       -dismiss   1]
#
#   # Later — dismiss programmatically:
#   ttkbootstrap::NotificationBanner::hide $nb
#
# OPTIONS
#   -message    string   Text to display
#   -bootstyle  color    Banner colour (default info)
#   -position   top|bottom   Where to pack (default top)
#   -dismiss    0|1      Show × dismiss button (default 1)
#   -icon       string   Optional Tabler icon name prefix (e.g. "info-circle")
#                        Not used for SVG but kept for API symmetry
#   -command    script   Called when banner is dismissed
#
# COMMANDS
#   NotificationBanner::show    nb           — make visible
#   NotificationBanner::hide    nb           — hide (does not destroy)
#   NotificationBanner::set     nb message   — update message text
#   NotificationBanner::restyle nb ?bootstyle? — re-apply colours
# =============================================================================

namespace eval ttkbootstrap {

proc NotificationBanner {parent args} {
    array set opts {
        -message   {}
        -bootstyle info
        -position  top
        -dismiss   1
        -command   {}
    }
    array set opts $args

    set hex [ttkbootstrap::getColor $opts(-bootstyle)]
    set fg  [ttkbootstrap::_contrastFg $hex]

    # Outer banner frame
    set w ${parent}.__nb_[clock milliseconds]
    set side [expr {$opts(-position) eq "bottom" ? "bottom" : "top"}]

    frame $w -background $hex -relief flat -borderwidth 0

    set ns ::ttkbootstrap::nb::$w
    namespace eval $ns {}
    set ${ns}::opts_arr [array get opts]
    set ${ns}::hex      $hex
    set ${ns}::fg       $fg

    # Message label
    set lbl [label $w.lbl \
        -text       $opts(-message) \
        -background $hex \
        -foreground $fg \
        -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                         [ttkbootstrap::_sf 12]] \
        -wraplength 0 \
        -anchor     w \
        -justify    left \
        -padx       [ttkbootstrap::_sp 12] \
        -pady       [ttkbootstrap::_sp 6]]
    pack $lbl -side left -fill both -expand 1
    set ${ns}::lbl $lbl

    # Dismiss button
    if {$opts(-dismiss)} {
        set xbtn [button $w.x \
            -text       "×" \
            -background $hex \
            -foreground $fg \
            -relief     flat \
            -borderwidth 0 \
            -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                             [ttkbootstrap::_sf 15]] \
            -padx       [ttkbootstrap::_sp 8] \
            -pady       [ttkbootstrap::_sp 4] \
            -cursor     hand2 \
            -command    [list ttkbootstrap::NotificationBanner::hide $w]]
        pack $xbtn -side right
        # Hover effect
        bind $xbtn <Enter> [list $xbtn configure \
            -background [ttkbootstrap::Colors::update_hsv $hex -vd -0.1]]
        bind $xbtn <Leave> [list $xbtn configure -background $hex]
    }

    pack $w -side $side -fill x

    bind $w <<ThemeChanged>> [list ttkbootstrap::_nb_restyle $w]

    return $w
}

proc _nb_restyle {w} {
    set ns ::ttkbootstrap::nb::$w
    if {![namespace exists $ns]} return
    array set o [set ${ns}::opts_arr]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    set fg  [ttkbootstrap::_contrastFg $hex]
    set ${ns}::hex $hex
    set ${ns}::fg  $fg
    if {[winfo exists $w]} { $w configure -background $hex }
    set lbl [set ${ns}::lbl]
    if {[winfo exists $lbl]} { $lbl configure -background $hex -foreground $fg }
    if {[winfo exists $w.x]} { $w.x configure -background $hex -foreground $fg }
}

} ;# end namespace ttkbootstrap

namespace eval ttkbootstrap::NotificationBanner {}

proc ttkbootstrap::NotificationBanner::show {w} {
    if {[winfo exists $w]} { pack $w }
}

proc ttkbootstrap::NotificationBanner::hide {w} {
    ::set ns ::ttkbootstrap::nb::$w
    if {[winfo exists $w]} { pack forget $w }
    if {[namespace exists $ns]} {
        array set o [set ${ns}::opts_arr]
        if {$o(-command) ne {}} { uplevel #0 $o(-command) }
    }
}

proc ttkbootstrap::NotificationBanner::msg {w msg} {
    ::set ns ::ttkbootstrap::nb::$w
    if {![namespace exists $ns]} return
    ::set lbl [set ${ns}::lbl]
    if {[winfo exists $lbl]} { $lbl configure -text $msg }
}

proc ttkbootstrap::NotificationBanner::restyle {w {bootstyle {}}} {
    ::set ns ::ttkbootstrap::nb::$w
    if {![namespace exists $ns]} return
    if {$bootstyle ne {}} {
        array set o [set ${ns}::opts_arr]
        ::set o(-bootstyle) $bootstyle
        ::set ${ns}::opts_arr [array get o]
    }
    ttkbootstrap::_nb_restyle $w
}
