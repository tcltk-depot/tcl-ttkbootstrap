# =============================================================================
# scrolled.tcl — ttkbootstrap ScrolledFrame + ScrolledText widgets
#
# ScrolledFrame: a ttk::Frame with automatic scrollbars.
# ScrolledText:  a tk::Text with automatic scrollbars.
#
# Usage:
#   set sf [ttkbootstrap::ScrolledFrame .sf \
#       -bootstyle primary \
#       -autohide 1]
#   # Pack children into [$sf interior]
#   ttk::label [$sf interior].lbl -text "Hello"
#   pack [$sf interior].lbl
#
#   set st [ttkbootstrap::ScrolledText .st \
#       -bootstyle secondary \
#       -width 60 -height 20]
#   [$st text] insert end "Hello world"
#
# Options (ScrolledFrame):
#   -bootstyle   scrollbar color    (default secondary)
#   -orient      both|vertical|horizontal  (default both)
#   -autohide    hide bars when not needed (default 1)
#   -padding     inner frame padding (default 0)
#
# Options (ScrolledText):
#   -bootstyle   scrollbar color    (default secondary)
#   -orient      both|vertical|horizontal  (default both)
#   -autohide    1/0                (default 1)
#   -width       text width chars   (default 80)
#   -height      text height lines  (default 10)
#   -font        text font
#   Plus any tk::text options
# =============================================================================

namespace eval ttkbootstrap {

# ─────────────────────────────────────────────────────────────────────────────
# ScrolledFrame
# ─────────────────────────────────────────────────────────────────────────────
proc ScrolledFrame {w args} {
    array set opts {
        -bootstyle  secondary
        -orient     both
        -autohide   1
        -padding    0
    }
    array set opts $args

    set ns ::ttkbootstrap::sf::$w
    namespace eval $ns {}
    set ${ns}::opts    [array get opts]
    set ${ns}::autohide $opts(-autohide)

    set outer [ttk::frame $w]

    set sbstyle_v "$opts(-bootstyle).Vertical.TScrollbar"
    set sbstyle_h "$opts(-bootstyle).Horizontal.TScrollbar"

    # Canvas is the scroll viewport
    set c [canvas $outer.c \
        -highlightthickness 0 \
        -borderwidth 0 \
        -background [ttkbootstrap::getColor bg]]

    # Scrollbars
    set vsb {}; set hsb {}
    if {$opts(-orient) in {both vertical}} {
        set vsb [ttk::scrollbar $outer.vsb \
            -orient vertical \
            -style $sbstyle_v \
            -command [list $c yview]]
        $c configure -yscrollcommand [list ttkbootstrap::_sf_scroll $w vsb $vsb]
    }
    if {$opts(-orient) in {both horizontal}} {
        set hsb [ttk::scrollbar $outer.hsb \
            -orient horizontal \
            -style $sbstyle_h \
            -command [list $c xview]]
        $c configure -xscrollcommand [list ttkbootstrap::_sf_scroll $w hsb $hsb]
    }

    set ${ns}::canvas $c
    set ${ns}::vsb    $vsb
    set ${ns}::hsb    $hsb
    set ${ns}::outer  $outer

    # Interior frame — this is what users pack into
    set interior [ttk::frame $c.interior -padding $opts(-padding)]
    set win [$c create window 0 0 -anchor nw -window $interior]
    set ${ns}::interior $interior
    set ${ns}::win      $win


    # Layout
    if {$vsb ne {}} { grid $vsb -row 0 -column 1 -sticky ns }
    if {$hsb ne {}} { grid $hsb -row 1 -column 0 -sticky ew }
    grid $c -row 0 -column 0 -sticky nsew
    grid columnconfigure $outer 0 -weight 1
    grid rowconfigure    $outer 0 -weight 1

    bind $interior <Configure> [list ttkbootstrap::_sf_interior_resize $w]
    # Re-inject mousewheel bindtag whenever children change

    bind $c        <Configure> [list ttkbootstrap::_sf_canvas_resize   $w]

    # Mouse wheel — redirect all wheel events from any child widget to this canvas.
    # Strategy: bind <Enter>/<Leave> on the outer frame to register/unregister
    # a global binding tag that forwards wheel events to our canvas.
    # This works correctly on all platforms when the mouse is over any child widget.
    # Register for mousewheel scrolling (Scrollutil approach)
    ttkbootstrap::_sf_register $w $c
    ttkbootstrap::_sf_bind_all

    interp alias {} ${w}.interior {} set ${ns}::interior
    interp alias {} ${w}.canvas   {} set ${ns}::canvas
    interp alias {} ${w}.xview    {} $c xview
    interp alias {} ${w}.yview    {} $c yview



    return $w
}

proc _sf_interior_resize {w} {
    set ns ::ttkbootstrap::sf::$w
    set c        [set ${ns}::canvas]
    set interior [set ${ns}::interior]
    set win      [set ${ns}::win]

    set W [winfo reqwidth  $interior]
    set H [winfo reqheight $interior]
    $c configure -scrollregion [list 0 0 $W $H]
    $c itemconfigure $win -width  [expr {max($W, [winfo width  $c])}]
}

proc _sf_canvas_resize {w} {
    set ns ::ttkbootstrap::sf::$w
    set c        [set ${ns}::canvas]
    set interior [set ${ns}::interior]
    set win      [set ${ns}::win]

    set cW [winfo width $c]
    set iW [winfo reqwidth $interior]
    $c itemconfigure $win -width [expr {max($iW, $cW)}]
}

proc _sf_scroll {w bar sbw first last} {
    set ns ::ttkbootstrap::sf::$w
    array set opts [set ${ns}::opts]

    if {$opts(-autohide)} {
        if {$first == 0.0 && $last == 1.0} {
            grid remove $sbw
        } else {
            if {$bar eq "vsb"} {
                grid $sbw -row 0 -column 1 -sticky ns
            } else {
                grid $sbw -row 1 -column 0 -sticky ew
            }
        }
    }
    $sbw set $first $last
}

# ─────────────────────────────────────────────────────────────────────────────
# ScrolledText
# ─────────────────────────────────────────────────────────────────────────────
proc ScrolledText {w args} {
    array set opts {
        -bootstyle  secondary
        -orient     both
        -autohide   1
        -width      80
        -height     10
        -font       {}
        -wrap       word
    }
    # Split our options from text widget options
    set textOpts {}
    set myKeys   {-bootstyle -orient -autohide}
    foreach {k v} $args {
        if {$k in $myKeys} {
            set opts($k) $v
        } else {
            lappend textOpts $k $v
        }
    }

    set ns ::ttkbootstrap::st::$w
    namespace eval $ns {}
    set ${ns}::opts    [array get opts]
    set ${ns}::autohide $opts(-autohide)

    set outer [ttk::frame $w]
    set sbstyle_v "$opts(-bootstyle).Vertical.TScrollbar"
    set sbstyle_h "$opts(-bootstyle).Horizontal.TScrollbar"

    set bg    [ttkbootstrap::getColor bg]
    set fg    [ttkbootstrap::getColor fg]
    set selbg [ttkbootstrap::getColor selectbg]
    set selfg [ttkbootstrap::getColor selectfg]
    set inputbg [ttkbootstrap::getColor inputbg]

    set font $opts(-font)
    if {$font eq {}} { set font [list [ttkbootstrap::getColor font] [ttkbootstrap::_sf 12]] }

    set txt [text $outer.txt \
        -width  $opts(-width) \
        -height $opts(-height) \
        -wrap   $opts(-wrap) \
        -font   $font \
        -background $inputbg \
        -foreground $fg \
        -insertbackground $fg \
        -selectbackground $selbg \
        -selectforeground $selfg \
        -borderwidth 1 \
        -relief flat \
        -highlightthickness 1 \
        -highlightbackground [ttkbootstrap::getColor border] \
        -highlightcolor [ttkbootstrap::getColor primary] \
        {*}$textOpts]

    set vsb {}; set hsb {}
    if {$opts(-orient) in {both vertical}} {
        set vsb [ttk::scrollbar $outer.vsb \
            -orient vertical \
            -style $sbstyle_v \
            -command [list $txt yview]]
        $txt configure -yscrollcommand \
            [list ttkbootstrap::_st_scroll $w vsb $vsb]
    }
    if {$opts(-orient) in {both horizontal}} {
        set hsb [ttk::scrollbar $outer.hsb \
            -orient horizontal \
            -style $sbstyle_h \
            -command [list $txt xview]]
        $txt configure -xscrollcommand \
            [list ttkbootstrap::_st_scroll $w hsb $hsb]
    }

    set ${ns}::text $txt
    set ${ns}::vsb  $vsb
    set ${ns}::hsb  $hsb

    grid $txt -row 0 -column 0 -sticky nsew
    if {$vsb ne {}} { grid $vsb -row 0 -column 1 -sticky ns }
    if {$hsb ne {}} { grid $hsb -row 1 -column 0 -sticky ew }
    grid columnconfigure $outer 0 -weight 1
    grid rowconfigure    $outer 0 -weight 1

    interp alias {} ${w}.text  {} set ${ns}::text
    interp alias {} ${w}.insert {} $txt insert
    interp alias {} ${w}.get    {} $txt get
    interp alias {} ${w}.delete {} $txt delete

    return $w
}

proc _st_scroll {w bar sbw first last} {
    set ns ::ttkbootstrap::st::$w
    array set opts [set ${ns}::opts]

    if {$opts(-autohide)} {
        if {$first == 0.0 && $last == 1.0} {
            grid remove $sbw
        } else {
            if {$bar eq "vsb"} {
                grid $sbw -row 0 -column 1 -sticky ns
            } else {
                grid $sbw -row 1 -column 0 -sticky ew
            }
        }
    }
    $sbw set $first $last
}


# ── ScrolledFrame mousewheel — Scrollutil approach ───────────────────────────
# Registry of scrollable frames: list of {outer_path canvas_path}
variable _sf_canvases {}

proc _sf_register {w c} {
    variable _sf_canvases
    lappend _sf_canvases [list $w $c]
    bind $w <Destroy> [list ttkbootstrap::_sf_unregister $w]
    # Bind on the toplevel containing this SF.
    # On X11, button (scroll) events go to the window under the pointer.
    # They bubble: child → ChildClass → TopLevel → all.
    # Binding on the toplevel is the most reliable catch point.
    set top [winfo toplevel $w]
    ttkbootstrap::_sf_bind_toplevel $top
}

proc _sf_unregister {w} {
    variable _sf_canvases
    set new {}
    foreach pair $_sf_canvases {
        if {[lindex $pair 0] ne $w} { lappend new $pair }
    }
    set _sf_canvases $new
}

# Track which toplevels already have bindings
variable _sf_bound_toplevels {}

proc _sf_bind_toplevel {top} {
    variable _sf_bound_toplevels
    if {$top in $_sf_bound_toplevels} return
    lappend _sf_bound_toplevels $top
    set ws [tk windowingsystem]
    # Bind MouseWheel on ALL platforms.
    # Tk 9 on X11 sends <MouseWheel> with D=±120 (not Button-4/5).
    # Older Tk/WMs on X11 send Button-4/5. Bind both to cover all cases.
    # D=-120 → scroll down (+3 units), D=+120 → scroll up (-3 units)
    bind $top <MouseWheel> \
        {+ ttkbootstrap::_sf_on_wheel %W %X %Y [expr {int(%D / -40)}] 0 }
    bind $top <Shift-MouseWheel> \
        {+ ttkbootstrap::_sf_on_wheel %W %X %Y [expr {int(%D / -40)}] 1 }
    if {$ws eq "x11"} {
        # Also handle legacy Button-4/5 for older Tk versions
        bind $top <Button-4>        {+ ttkbootstrap::_sf_on_wheel %W %X %Y -3 0 }
        bind $top <Button-5>        {+ ttkbootstrap::_sf_on_wheel %W %X %Y  3 0 }
        bind $top <Shift-Button-4>  {+ ttkbootstrap::_sf_on_wheel %W %X %Y -3 1 }
        bind $top <Shift-Button-5>  {+ ttkbootstrap::_sf_on_wheel %W %X %Y  3 1 }
    }
}

proc _sf_on_wheel {W rootx rooty delta horiz} {
    # Find the widget under the pointer (use root coords, not focused widget)
    set w [winfo containing $rootx $rooty]
    if {$w eq {}} {
        # Fall back to the event widget
        set w $W
    }
    ttkbootstrap::_sf_find_and_scroll $w $delta $horiz
}

proc _sf_find_and_scroll {w delta horiz} {
    variable _sf_canvases
    if {$w eq {} || $w eq "."} return
    # Walk up the ancestor chain
    set cur $w
    while {$cur ne {} && $cur ne "."} {
        foreach pair $_sf_canvases {
            lassign $pair outer canvas
            if {$cur eq $outer} {
                if {[winfo exists $canvas]} {
                    if {$horiz} {
                        $canvas xview scroll $delta units
                    } else {
                        $canvas yview scroll $delta units
                    }
                }
                return
            }
        }
        set cur [winfo parent $cur]
    }
}

# Also bind on "all" as belt-and-suspenders (catches cases where
# toplevel binding misses, e.g. sub-toplevels created after SF)
proc _sf_bind_all {} {
    variable _sf_all_bound
    if {[info exists _sf_all_bound] && $_sf_all_bound} return
    set _sf_all_bound 1
    set ws [tk windowingsystem]
    # Tk 9 on X11 sends <MouseWheel> D=±120; older Tk sends Button-4/5. Bind both.
    bind all <MouseWheel> \
        {+ ttkbootstrap::_sf_on_wheel %W %X %Y [expr {int(%D / -40)}] 0 }
    bind all <Shift-MouseWheel> \
        {+ ttkbootstrap::_sf_on_wheel %W %X %Y [expr {int(%D / -40)}] 1 }
    if {$ws eq "x11"} {
        bind all <Button-4>        {+ ttkbootstrap::_sf_on_wheel %W %X %Y -3 0 }
        bind all <Button-5>        {+ ttkbootstrap::_sf_on_wheel %W %X %Y  3 0 }
        bind all <Shift-Button-4>  {+ ttkbootstrap::_sf_on_wheel %W %X %Y -3 1 }
        bind all <Shift-Button-5>  {+ ttkbootstrap::_sf_on_wheel %W %X %Y  3 1 }
    }
}

} ;# end namespace
