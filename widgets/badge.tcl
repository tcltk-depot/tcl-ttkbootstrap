# =============================================================================
# badge.tcl — Small coloured count or status pill label
#
# USAGE
#   # Standalone badge
#   ttkbootstrap::Badge .b -text "42" -bootstyle danger
#   pack .b
#
#   # Attach badge to any existing widget (floating overlay)
#   set btn [ttk::button .b1 -text "Messages"]
#   pack .b1
#   ttkbootstrap::Badge::attach .b1 "5" -bootstyle danger
#
#   # Update or clear
#   ttkbootstrap::Badge::set .b1 "12"
#   ttkbootstrap::Badge::clear .b1
#
# OPTIONS
#   -text       string   Badge text (default: {})
#   -bootstyle  color    Colour keyword (default: danger)
#   -font       font     Override font
#   -width      int      Minimum character width (default: 0 = auto)
#
# METHODS (for attached badges)
#   Badge::attach widget text ?options?  — create floating badge on widget
#   Badge::set    widget text            — update text
#   Badge::clear  widget                 — hide badge
# =============================================================================

namespace eval ttkbootstrap {

proc Badge {w args} {
    array set opts {
        -text      {}
        -bootstyle danger
        -font      {}
        -width     0
    }
    array set opts $args

    set hex [ttkbootstrap::getColor $opts(-bootstyle)]
    set fg  [ttkbootstrap::_contrastFg $hex]

    if {$opts(-font) eq {}} {
        set opts(-font) [list \
            [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
            [ttkbootstrap::_sf 10] bold]
    }

    set lbl [label $w \
        -text       $opts(-text) \
        -background $hex \
        -foreground $fg \
        -font       $opts(-font) \
        -padx       [ttkbootstrap::_sp 6] \
        -pady       [ttkbootstrap::_sp 2] \
        -relief     flat \
        -borderwidth 0]
    if {$opts(-width) > 0} { $lbl configure -width $opts(-width) }

    # Round appearance via compound padding trick (no canvas needed)
    set ns ::ttkbootstrap::badge::$w
    namespace eval $ns {}
    set ${ns}::opts [array get opts]

    bind $lbl <<ThemeChanged>> [list ttkbootstrap::_badge_restyle $w]

    return $lbl
}

proc _badge_restyle {w} {
    set ns ::ttkbootstrap::badge::$w
    if {![namespace exists $ns]} return
    array set o [set ${ns}::opts]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    set fg  [ttkbootstrap::_contrastFg $hex]
    catch { $w configure -background $hex -foreground $fg }
}

} ;# end namespace ttkbootstrap

namespace eval ttkbootstrap::Badge {}

proc ttkbootstrap::Badge::attach {widget text args} {
    array set opts {-bootstyle danger}
    array set opts $args

    ::set bw ${widget}.__badge
    if {[winfo exists $bw]} {
        $bw configure -text $text
        return $bw
    }

    ::set hex [ttkbootstrap::getColor $opts(-bootstyle)]
    ::set fg  [ttkbootstrap::_contrastFg $hex]

    label $bw \
        -text       $text \
        -background $hex \
        -foreground $fg \
        -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                         [ttkbootstrap::_sf 10] bold] \
        -padx       [ttkbootstrap::_sp 5] \
        -pady       [ttkbootstrap::_sp 1] \
        -relief     flat \
        -borderwidth 0

    # Position after first layout pass — then update on subsequent resizes
    after idle [list ttkbootstrap::_badge_reposition $widget $bw]
    bind $widget <Map> [list after idle [list ttkbootstrap::_badge_reposition $widget $bw]]

    ::set ns ::ttkbootstrap::badge::$bw
    namespace eval $ns {}
    ::set ${ns}::opts [list -bootstyle $opts(-bootstyle)]
    bind $bw <<ThemeChanged>> [list ttkbootstrap::_badge_restyle $bw]

    return $bw
}

proc ttkbootstrap::_badge_reposition {widget bw} {
    if {![winfo exists $widget] || ![winfo exists $bw]} return
    set x [expr {[winfo x $widget] + [winfo width $widget] - [winfo reqwidth $bw] / 2}]
    set y [expr {[winfo y $widget] - [winfo reqheight $bw] / 2}]
    place $bw -in [winfo parent $widget] -x $x -y $y -anchor nw
    raise $bw
}

proc ttkbootstrap::Badge::msg {widget text} {
    ::set bw ${widget}.__badge
    if {[winfo exists $bw]} {
        $bw configure -text $text
        if {$text ne {} && $text ne "0"} {
            raise $bw
        } else {
            place forget $bw
        }
    }
}

proc ttkbootstrap::Badge::clear {widget} {
    ::set bw ${widget}.__badge
    catch { place forget $bw }
}

# Compatibility alias
proc ttkbootstrap::Badge::set {widget text} { ttkbootstrap::Badge::msg $widget $text }
