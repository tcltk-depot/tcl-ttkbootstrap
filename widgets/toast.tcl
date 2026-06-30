# =============================================================================
# toast.tcl — ttkbootstrap Toast widget
#
# A transient popup notification that auto-dismisses after a duration.
#
# Usage:
#   ttkbootstrap::Toast "File saved successfully" \
#       -bootstyle success \
#       -duration 3000 \
#       -position bottom-right
#
# Options:
#   -bootstyle   color keyword              (default dark)
#   -duration    ms before auto-dismiss     (default 3000, 0=no auto)
#   -position    top-left | top-right |
#                bottom-left | bottom-right |
#                top-center | bottom-center (default bottom-right)
#   -alpha       0.0-1.0 opacity            (default 0.92)
#   -padding     inner padding              (default {16 10})
#   -font        text font                  (default TkDefaultFont 10)
#   -icon        optional prefix text       (default "")
#   -parent      parent window              (default .)
# =============================================================================

namespace eval ttkbootstrap {

proc Toast {message args} {
    array set opts {
        -bootstyle  dark
        -duration   3000
        -position   bottom-right
        -alpha      0.92
        -padding    {16 10}
        -font       {}
        -icon       {}
        -parent     .
    }
    array set opts $args

    set parent $opts(-parent)
    # Scale padding if it wasn't explicitly overridden as scaled
    if {[llength $opts(-padding)] == 2 && [string is integer [lindex $opts(-padding) 0]]} {
        set opts(-padding) [ttkbootstrap::_sp2 [lindex $opts(-padding) 0] [lindex $opts(-padding) 1]]
    }

    set t [toplevel .__toast_[clock milliseconds] \
        -relief flat \
        -borderwidth 0]
    wm overrideredirect $t 1
    catch { wm attributes $t -topmost 1 }
    wm withdraw $t
    set bg  [ttkbootstrap::getColor $opts(-bootstyle)]
    set fg  [ttkbootstrap::_contrastFg $bg]

    set font $opts(-font)
    if {$font eq {}} {
        set font [list [ttkbootstrap::getColor font] [ttkbootstrap::_sf 12]]
    }

    $t configure -background $bg

    set frame [frame $t.f \
        -background $bg \
        -padx [lindex $opts(-padding) 0] \
        -pady [lindex $opts(-padding) end]]
    pack $frame -fill both -expand 1

    # Icon + message
    set txt $message
    if {$opts(-icon) ne {}} { set txt "$opts(-icon)  $message" }

    label $frame.msg \
        -text $txt \
        -background $bg \
        -foreground $fg \
        -font $font \
        -wraplength [ttkbootstrap::_sp 320] \
        -justify left
    pack $frame.msg -side left -fill x -expand 1

    # Close button
    label $frame.close \
        -text "✕" \
        -background $bg \
        -foreground $fg \
        -font $font \
        -cursor hand2
    pack $frame.close -side right -padx {8 0}
    bind $frame.close <Button-1> [list ttkbootstrap::_toast_dismiss $t]

    # Position relative to the parent window (or screen if parent not specified)
    update idletasks
    set W [winfo reqwidth  $t]
    set H [winfo reqheight $t]
    set margin [ttkbootstrap::_sp 16]

    # Get parent window bounds
    set par $opts(-parent)
    if {$par ne {} && [winfo exists $par]} {
        set px [winfo rootx  $par]
        set py [winfo rooty  $par]
        set pw [winfo width  $par]
        set ph [winfo height $par]
    } else {
        set px 0; set py 0
        set pw [winfo screenwidth  $t]
        set ph [winfo screenheight $t]
    }

    switch -- $opts(-position) {
        top-left      { set x [expr {$px + $margin}]
                        set y [expr {$py + $margin}] }
        top-right     { set x [expr {$px + $pw - $W - $margin}]
                        set y [expr {$py + $margin}] }
        bottom-left   { set x [expr {$px + $margin}]
                        set y [expr {$py + $ph - $H - $margin}] }
        bottom-right  { set x [expr {$px + $pw - $W - $margin}]
                        set y [expr {$py + $ph - $H - $margin}] }
        top-center    { set x [expr {$px + ($pw - $W) / 2}]
                        set y [expr {$py + $margin}] }
        bottom-center { set x [expr {$px + ($pw - $W) / 2}]
                        set y [expr {$py + $ph - $H - $margin}] }
        default       { set x [expr {$px + $pw - $W - $margin}]
                        set y [expr {$py + $ph - $H - $margin}] }
    }

    wm geometry $t "+${x}+${y}"

    # Opacity
    catch { wm attributes $t -alpha 0.0 }
    wm deiconify $t
    raise $t

    # Fade in
    _toast_fadein $t $opts(-alpha) 0.0

    # Auto-dismiss
    if {$opts(-duration) > 0} {
        after $opts(-duration) [list ttkbootstrap::_toast_fadeout $t]
    }

    return $t
}

proc _toast_fadein {t targetAlpha current} {
    set step 0.08
    set next [expr {min($current + $step, $targetAlpha)}]
    catch { wm attributes $t -alpha $next }
    if {$next < $targetAlpha} {
        after 20 [list ttkbootstrap::_toast_fadein $t $targetAlpha $next]
    }
}

proc _toast_fadeout {t} {
    if {![winfo exists $t]} return
    catch {
        set current [wm attributes $t -alpha]
        set next [expr {$current - 0.08}]
        if {$next <= 0} {
            _toast_dismiss $t
        } else {
            wm attributes $t -alpha $next
            after 20 [list ttkbootstrap::_toast_fadeout $t]
        }
    }
}

proc _toast_dismiss {t} {
    catch { destroy $t }
}

} ;# end namespace
