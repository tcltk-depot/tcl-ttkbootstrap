# =============================================================================
# breadcrumb.tcl — Clickable navigation path widget
#
# USAGE
#   ttkbootstrap::Breadcrumb .bc \
#       -items   {"Home" "Settings" "Users"} \
#       -command { puts "clicked: $idx $label" } \
#       -bootstyle primary
#   pack .bc
#
#   # Update path
#   ttkbootstrap::Breadcrumbset .bc {"Home" "Files" "Documents" "Report.pdf"}
#
#   # Get current path list
#   ttkbootstrap::Breadcrumb::get .bc
#
# OPTIONS
#   -items      list    Initial path segments (default: {})
#   -command    script  Called with idx and label when a segment is clicked
#   -separator  string  Separator character (default: ›)
#   -bootstyle  color   Active/hover link colour (default: primary)
#   -font       font    Override font
# =============================================================================

namespace eval ttkbootstrap {

proc Breadcrumb {w args} {
    array set opts {
        -items     {}
        -command   {}
        -separator "›"
        -bootstyle primary
        -font      {}
    }
    array set opts $args

    set ns ::ttkbootstrap::bc::$w
    namespace eval $ns {}
    set ${ns}::opts  [array get opts]
    set ${ns}::items $opts(-items)

    set f [ttk::frame $w]
    set ${ns}::frame $f

    bind $f <<ThemeChanged>> [list ttkbootstrap::_bc_rebuild $w]

    _bc_rebuild $w

    return $f
}

proc _bc_rebuild {w} {
    set ns ::ttkbootstrap::bc::$w
    if {![namespace exists $ns]} return
    set f [set ${ns}::frame]
    if {![winfo exists $f]} return

    array set o [set ${ns}::opts]
    set items [set ${ns}::items]

    # Clear existing
    foreach child [winfo children $f] { destroy $child }

    set link_hex [ttkbootstrap::getColor $o(-bootstyle)]
    set fg_hex   [ttkbootstrap::getColor fg]
    set sep_hex  [ttkbootstrap::getColor secondary]
    set bg_hex   [ttkbootstrap::getColor bg]

    set fnt $o(-font)
    if {$fnt eq {}} {
        set fnt [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                      [ttkbootstrap::_sf 12]]
    }

    set n [llength $items]
    for {set i 0} {$i < $n} {incr i} {
        set lbl [lindex $items $i]
        set is_last [expr {$i == $n - 1}]

        if {$is_last} {
            # Current page — plain text, not a link
            label $f.seg$i \
                -text       $lbl \
                -foreground $fg_hex \
                -background $bg_hex \
                -font       $fnt \
                -padx       [ttkbootstrap::_sp 2] \
                -pady       0
        } else {
            # Clickable segment
            set cmd $o(-command)
            label $f.seg$i \
                -text       $lbl \
                -foreground $link_hex \
                -background $bg_hex \
                -font       $fnt \
                -cursor     hand2 \
                -padx       [ttkbootstrap::_sp 2] \
                -pady       0
            bind $f.seg$i <Button-1> [list apply {{cmd idx label} {
                # Make $idx and $label available in the caller's global scope
                uplevel #0 [list set idx $idx]
                uplevel #0 [list set label $label]
                uplevel #0 $cmd
            }} $cmd $i $lbl]
            bind $f.seg$i <Enter> [list $f.seg$i configure \
                -foreground [ttkbootstrap::Colors::update_hsv $link_hex -vd -0.15]]
            bind $f.seg$i <Leave> [list $f.seg$i configure \
                -foreground $link_hex]
        }
        pack $f.seg$i -side left

        # Separator
        if {!$is_last} {
            label $f.sep$i \
                -text       $o(-separator) \
                -foreground $sep_hex \
                -background $bg_hex \
                -font       $fnt \
                -padx       [ttkbootstrap::_sp 4] \
                -pady       0
            pack $f.sep$i -side left
        }
    }
}

} ;# end namespace ttkbootstrap

namespace eval ttkbootstrap::Breadcrumb {}

proc ttkbootstrap::Breadcrumb::load {w items} {
    set ns ::ttkbootstrap::bc::$w
    set ${ns}::items $items
    ttkbootstrap::_bc_rebuild $w
}

proc ttkbootstrap::Breadcrumb::get {w} {
    return [set ::ttkbootstrap::bc::${w}::items]
}

proc ttkbootstrap::Breadcrumb::push {w label} {
    set ns ::ttkbootstrap::bc::$w
    lappend ${ns}::items $label
    ttkbootstrap::_bc_rebuild $w
}

proc ttkbootstrap::Breadcrumb::pop {w} {
    set ns ::ttkbootstrap::bc::$w
    set items [set ${ns}::items]
    if {[llength $items] > 0} {
        set ${ns}::items [lrange $items 0 end-1]
        ttkbootstrap::_bc_rebuild $w
    }
}

# Compatibility alias
proc ttkbootstrap::Breadcrumbset {args} { ttkbootstrap::Breadcrumb::load {*}$args }
