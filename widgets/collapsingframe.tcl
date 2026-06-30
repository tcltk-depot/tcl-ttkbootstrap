# =============================================================================
# collapsingframe.tcl — Accordion / collapsible panel widget
#
# Creates a vertical stack of titled, collapsible sections.  Each section has
# a coloured header bar containing a title label and a toggle button; clicking
# either shows or hides the child frame below it.
#
# USAGE
#   set cf [ttkbootstrap::CollapsingFrame .cf]
#   pack $cf -fill both -expand 1
#
#   set pane [ttk::frame $cf.pane1 -padding 10]
#   # ... populate $pane ...
#   ttkbootstrap::CollapsingFrame::add $cf $pane "Section title" primary
#
# COMMANDS
#   ttkbootstrap::CollapsingFrame path               — create widget, return path
#   ttkbootstrap::CollapsingFrame::add cf child title ?bootstyle?
#                                                    — add a collapsible section
#   ttkbootstrap::CollapsingFrame::toggle cf child   — open/close a section
#   ttkbootstrap::CollapsingFrame::open   cf child   — ensure section is visible
#   ttkbootstrap::CollapsingFrame::close  cf child   — ensure section is hidden
#
# BOOTSTYLE
#   Any ttkbootstrap colour keyword: primary secondary success info warning
#   danger light dark  (default: primary)
# =============================================================================

namespace eval ttkbootstrap {

proc CollapsingFrame {w args} {
    # Accept optional -bootstyle for the default section colour
    array set opts {-bootstyle primary}
    array set opts $args

    ttk::frame $w
    grid columnconfigure $w 0 -weight 1

    # Namespace holds per-widget state
    set ns ::ttkbootstrap::cf::$w
    namespace eval $ns {}
    set ${ns}::row        0
    set ${ns}::bootstyle  $opts(-bootstyle)
    set ${ns}::children   {}

    # Refresh arrow images when theme changes
    bind $w <<ThemeChanged>> [list ttkbootstrap::_cf_refresh_images $w]

    return $w
}

# ── Internal: build/refresh the two arrow photo-images for widget $w ─────────
proc _cf_images {w color} {
    set scale [ttkbootstrap::img::size]
    set img_open  [ttkbootstrap::img::get arrow.up    $color $scale]
    set img_close [ttkbootstrap::img::get arrow.right $color $scale]
    return [list $img_open $img_close]
}

proc _cf_refresh_images {w} {
    set ns ::ttkbootstrap::cf::$w
    if {![namespace exists $ns]} return
    foreach child [set ${ns}::children] {
        set cns ::ttkbootstrap::cf::${w}::child_$child
        if {![namespace exists $cns]} continue
        set color [set ${cns}::color]
        set fg    [ttkbootstrap::_contrastFg [ttkbootstrap::getColor $color]]
        lassign [_cf_images $w $fg] img_open img_close
        set ${cns}::img_open  $img_open
        set ${cns}::img_close $img_close
        # Update button image to match current open/close state.
        # Use grid slaves rather than winfo viewable — viewable requires
        # all ancestors to be mapped, which fails during theme refresh
        # when the window may be withdrawn.
        set btn [set ${cns}::btn]
        if {[winfo exists $btn]} {
            set is_open [expr {[lsearch [grid slaves [winfo parent $child]] $child] >= 0}]
            if {$is_open} {
                $btn configure -image $img_open
            } else {
                $btn configure -image $img_close
            }
        }
    }
}

} ;# end namespace ttkbootstrap

# ── Public namespace for cf commands ─────────────────────────────────────────
namespace eval ttkbootstrap::CollapsingFrame {}

proc ttkbootstrap::CollapsingFrame::add {w child title {bootstyle {}}} {
    set ns ::ttkbootstrap::cf::$w
    if {![namespace exists $ns]} {
        error "Not a CollapsingFrame: $w"
    }
    if {$bootstyle eq {}} { set bootstyle [set ${ns}::bootstyle] }

    set row [set ${ns}::row]
    set hex [ttkbootstrap::getColor $bootstyle]
    set fg  [ttkbootstrap::_contrastFg $hex]
    lassign [ttkbootstrap::_cf_images $w $fg] img_open img_close

    # Header frame
    set hf [ttk::frame $w.hf$row -style ${bootstyle}.TFrame]
    grid $hf -row $row -column 0 -sticky ew

    ttk::label $hf.lbl \
        -text  $title \
        -style ${bootstyle}.Inverse.TLabel \
        -padding [ttkbootstrap::_sp2 8 4] \
        -anchor w
    pack $hf.lbl -side left -fill both -expand 1

    set btn [ttk::button $hf.btn \
        -image   $img_open \
        -style   ${bootstyle}.TButton \
        -padding [ttkbootstrap::_sp2 4 4] \
        -command [list ttkbootstrap::CollapsingFrame::toggle $w $child]]
    pack $btn -side right

    # Clicking the title label also toggles
    bind $hf.lbl <Button-1> [list ttkbootstrap::CollapsingFrame::toggle $w $child]
    bind $hf.lbl <Enter>    [list $hf.lbl configure -cursor hand2]
    bind $hf.lbl <Leave>    [list $hf.lbl configure -cursor {}]

    # Child sits immediately below its header
    grid $child -row [expr {$row+1}] -column 0 -sticky nsew
    grid rowconfigure $w [expr {$row+1}] -weight 0

    # Per-child state namespace
    set cns ::ttkbootstrap::cf::${w}::child_$child
    namespace eval $cns {}
    set ${cns}::btn       $btn
    set ${cns}::img_open  $img_open
    set ${cns}::img_close $img_close
    set ${cns}::color     $bootstyle

    lappend ${ns}::children $child
    set ${ns}::row [expr {$row + 2}]

    return $child
}

proc ttkbootstrap::CollapsingFrame::toggle {w child} {
    # Use grid slaves rather than winfo viewable so toggle works even
    # when the window is withdrawn or an ancestor is unmapped.
    set is_open [expr {[lsearch [grid slaves [winfo parent $child]] $child] >= 0}]
    if {$is_open} {
        close $w $child
    } else {
        open $w $child
    }
}

proc ttkbootstrap::CollapsingFrame::open {w child} {
    set cns ::ttkbootstrap::cf::${w}::child_$child
    grid $child
    set btn [set ${cns}::btn]
    if {[winfo exists $btn]} {
        $btn configure -image [set ${cns}::img_open]
    }
}

proc ttkbootstrap::CollapsingFrame::close {w child} {
    set cns ::ttkbootstrap::cf::${w}::child_$child
    grid remove $child
    set btn [set ${cns}::btn]
    if {[winfo exists $btn]} {
        $btn configure -image [set ${cns}::img_close]
    }
}
