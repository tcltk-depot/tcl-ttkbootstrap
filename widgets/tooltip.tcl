# =============================================================================
# tooltip.tcl — ttkbootstrap Tooltip widget
#
# Attaches a themed hover tooltip to any widget.
#
# Usage:
#   ttkbootstrap::Tooltip .mybutton "This is a tooltip"
#
#   # With options:
#   ttkbootstrap::Tooltip .mybutton "Detailed help text" \
#       -bootstyle dark \
#       -delay 600 \
#       -wraplength 200
#
# Options:
#   -bootstyle   color keyword     (default dark)
#   -delay       ms before show    (default 500)
#   -wraplength  wrap pixels       (default 250)
#   -font        tooltip font      (default TkDefaultFont 9)
#   -padding     inner padding     (default {8 4})
#   -alpha       opacity           (default 0.92)
#
# Returns a tooltip id. To remove: ttkbootstrap::TooltipRemove .mywidget
# =============================================================================

namespace eval ttkbootstrap {

# Registry: widget -> tooltip window
variable _tooltips

proc Tooltip {widget message args} {
    variable _tooltips

    array set opts {
        -bootstyle  dark
        -delay      500
        -wraplength 250
        -font       {}
        -padding    {8 4}
        -alpha      0.92
    }
    array set opts $args

    # Remove any existing tooltip on this widget
    TooltipRemove $widget

    set id [list $widget $message [array get opts]]
    set _tooltips($widget) {}

    bind $widget <Enter>   [list ttkbootstrap::_tt_schedule $widget $message [array get opts]]
    bind $widget <Leave>   [list ttkbootstrap::_tt_cancel   $widget]
    bind $widget <Button>  [list ttkbootstrap::_tt_cancel   $widget]
    bind $widget <Destroy> [list ttkbootstrap::TooltipRemove $widget]

    return $id
}

proc TooltipRemove {widget} {
    variable _tooltips
    _tt_cancel $widget
    catch { bind $widget <Enter>   {} }
    catch { bind $widget <Leave>   {} }
    catch { bind $widget <Destroy> {} }
    catch { unset _tooltips($widget) }
}

proc _tt_schedule {widget message optslist} {
    variable _tooltips
    array set opts $optslist
    set _tooltips($widget) [after $opts(-delay) \
        [list ttkbootstrap::_tt_show $widget $message $optslist]]
}

proc _tt_cancel {widget} {
    variable _tooltips
    if {[info exists _tooltips($widget)]} {
        set val $_tooltips($widget)
        # Could be an "after" id (pending show) or a toplevel path (already shown)
        if {$val ne {}} {
            if {[string match after#* $val]} {
                after cancel $val
            } elseif {[winfo exists $val]} {
                destroy $val
            }
        }
        set _tooltips($widget) {}
    }
    # Belt-and-braces: destroy by the name _tt_show would have used
    set tname ".__ttip_[string map {. _ : _} $widget]"
    catch { destroy $tname }
}

proc _tt_show {widget message optslist} {
    variable _tooltips
    array set opts $optslist

    if {![winfo exists $widget]} return

    # Unique toplevel per widget
    set tname ".__ttip_[string map {. _ : _} $widget]"
    catch { destroy $tname }

    set t [toplevel $tname -relief solid -borderwidth 1]
    wm overrideredirect $t 1
    catch { wm attributes $t -topmost 1 }
    wm withdraw $t
    set bg  [ttkbootstrap::getColor $opts(-bootstyle)]
    set fg  [ttkbootstrap::_contrastFg $bg]

    set font $opts(-font)
    if {$font eq {}} {
        set font [list [ttkbootstrap::getColor font] [ttkbootstrap::_sf 11]]
    }

    $t configure -background $bg -borderwidth 1 \
        -highlightbackground [ttkbootstrap::_darken $bg 20]

    frame $t.f -background $bg \
        -padx [lindex $opts(-padding) 0] \
        -pady [lindex $opts(-padding) end]
    pack $t.f -fill both -expand 1

    label $t.f.lbl \
        -text $message \
        -background $bg \
        -foreground $fg \
        -font $font \
        -wraplength $opts(-wraplength) \
        -justify left
    pack $t.f.lbl

    # Position near the mouse pointer
    set mx [winfo pointerx $widget]
    set my [winfo pointery $widget]
    update idletasks
    set tw [winfo reqwidth  $t]
    set th [winfo reqheight $t]
    set sw [winfo screenwidth  .]
    set sh [winfo screenheight .]

    set tx [expr {$mx + [ttkbootstrap::_sp 12]}]
    set ty [expr {$my + [ttkbootstrap::_sp 18]}]
    # Keep on screen
    if {$tx + $tw > $sw} { set tx [expr {$mx - $tw - [ttkbootstrap::_sp 4]}] }
    if {$ty + $th > $sh} { set ty [expr {$my - $th - [ttkbootstrap::_sp 4]}] }

    wm geometry $t "+${tx}+${ty}"
    catch { wm attributes $t -alpha $opts(-alpha) }
    wm deiconify $t
    raise $t

    set _tooltips($widget) $t

    # Auto-dismiss after 4 seconds as a safety net
    after 4000 [list catch [list destroy $t]]
}

} ;# end namespace
