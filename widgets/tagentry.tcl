# =============================================================================
# tagentry.tcl — Entry that converts text into removable pill/chip tags
#
# USAGE
#   ttkbootstrap::TagEntry .te \
#       -bootstyle   primary \
#       -separator   {, } \
#       -tags        {Python Tcl Go} \
#       -command     {puts "tags: [.te get]"}
#   pack .te -fill x
#
#   .te get           → list of current tags
#   .te add  "Rust"   → add a tag programmatically
#   .te remove "Go"   → remove a tag
#   .te clear         → remove all tags
#
# OPTIONS
#   -tags       list     Initial tags (default {})
#   -bootstyle  color    Pill colour (default primary)
#   -separator  string   Characters that trigger tag creation (default {, })
#   -maxitems   int      Maximum number of tags (0=unlimited, default 0)
#   -command    script   Called with current tag list whenever tags change
#   -width      int      Approx width in characters (default 30)
# =============================================================================

namespace eval ttkbootstrap {

proc TagEntry {w args} {
    array set opts {
        -tags      {}
        -bootstyle primary
        -separator {,}
        -maxitems  0
        -command   {}
        -width     30
    }
    array set opts $args

    set ns ::ttkbootstrap::te::$w
    namespace eval $ns {}
    set ${ns}::tags     {}
    set ${ns}::bootstyle $opts(-bootstyle)
    set ${ns}::maxitems  $opts(-maxitems)
    set ${ns}::command   $opts(-command)
    set ${ns}::separator $opts(-separator)

    # Outer frame acts as the widget boundary
    set outer [ttk::frame $w -style TFrame]
    catch { $outer configure -background [ttkbootstrap::getColor bg] }
    set ${ns}::outer $outer

    # Inner canvas — scrolls horizontally, holds pill frames + entry
    set c [canvas $outer.c \
        -highlightthickness 0 \
        -borderwidth        0 \
        -height             [expr {[font metrics [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] [ttkbootstrap::_sf 12]] -linespace] + [ttkbootstrap::_sp 18]}] \
        -background         [ttkbootstrap::getColor inputbg]]
    pack $c -fill both -expand 1 -padx [ttkbootstrap::_sp 2] -pady [ttkbootstrap::_sp 2]
    set ${ns}::canvas $c

    # A frame embedded in the canvas to hold pills + entry side by side
    set inner [ttk::frame $c.inner -style TFrame]
    $c create window 0 0 -anchor nw -window $inner -tags inner
    set ${ns}::inner $inner

    # The actual text entry at the end of the pill row
    set entry [ttk::entry $inner.entry \
        -width [ttkbootstrap::_sp 8] \
        -style "$opts(-bootstyle).TEntry"]
    set ${ns}::entry $entry

    bind $entry <KeyPress>   [list ttkbootstrap::_te_keypress  $w %K %A]
    bind $entry <BackSpace>  [list ttkbootstrap::_te_backspace $w]
    bind $inner  <Configure> [list ttkbootstrap::_te_resize    $w]
    bind $c      <Button-1>  [list focus $entry]
    bind $outer <<ThemeChanged>> [list ttkbootstrap::_te_restyle $w]

    # Pack entry last (always at the end)
    pack $entry -side left -padx [ttkbootstrap::_sp 2] -pady [ttkbootstrap::_sp 2]

    # Add initial tags (deferred so widget is fully realized for SVG rendering)
    after idle [list apply {{w tags} {
        foreach tag $tags { ttkbootstrap::_te_add_internal $w $tag }
    }} $w $opts(-tags)]

    return $w
}

proc _te_resize {w} {
    set ns ::ttkbootstrap::te::$w
    set c     [set ${ns}::canvas]
    set inner [set ${ns}::inner]
    update idletasks
    set rw [winfo reqwidth  $inner]
    set rh [winfo reqheight $inner]
    $c configure -scrollregion [list 0 0 $rw $rh]
    # Scroll to show the entry (far right)
    $c xview moveto 1.0
}

proc _te_keypress {w key char} {
    set ns ::ttkbootstrap::te::$w
    set sep [set ${ns}::separator]

    # Tag separators: comma, space (if configured), Return
    if {$key eq "Return" || $char in [split $sep {}]} {
        set entry [set ${ns}::entry]
        set text  [string trim [$entry get]]
        $entry delete 0 end
        if {$text ne {}} { _te_add_internal $w $text }
        # Swallow the separator character
        return -code break
    }
}

proc _te_backspace {w} {
    set ns ::ttkbootstrap::te::$w
    set entry [set ${ns}::entry]
    if {[$entry get] eq {} && [llength [set ${ns}::tags]] > 0} {
        # Remove last tag
        set tags [set ${ns}::tags]
        set last [lindex $tags end]
        _te_remove_internal $w $last
        return -code break
    }
}

proc _te_add_internal {w tag} {
    set ns ::ttkbootstrap::te::$w
    set tags    [set ${ns}::tags]
    set maxitems [set ${ns}::maxitems]

    if {$tag in $tags} return
    if {$maxitems > 0 && [llength $tags] >= $maxitems} return

    set inner [set ${ns}::inner]
    set bs    [set ${ns}::bootstyle]
    set hex   [ttkbootstrap::getColor $bs]
    set fg    [ttkbootstrap::_contrastFg $hex]

    # Build a pill: SVG rounded background with text overlay (like SVGBadge)
    set safe [string map {. _ / _ : _ " " _} $tag]
    set pill $inner.pill_$safe
    if {[winfo exists $pill]} return

    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 12]
    set pfont [list $fn $fs]

    # Measure text to size the SVG pill
    set fulltxt "$tag  ×"
    set tw [font measure $pfont $fulltxt]
    set th [font metrics $pfont -linespace]
    set pw [expr {$tw + [ttkbootstrap::_sp 14]}]
    set ph [expr {$th + [ttkbootstrap::_sp 6]}]
    set pr [expr {$ph / 2}]

    # SVG pill background
    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$pw' height='$ph'>"
    append svg "<rect x='0' y='0' width='$pw' height='$ph' rx='$pr' ry='$pr' fill='$hex'/>"
    append svg "</svg>"
    catch { image delete ${pill}::bg }
    image create photo ${pill}::bg -data $svg -format {svg}

    # Single label: SVG pill image + text via -compound center
    label $pill -image ${pill}::bg -text $fulltxt -compound center \
        -fg $fg -font $pfont -bd 0 -highlightthickness 0 \
        -bg [ttkbootstrap::getColor bg] -cursor hand2

    bind $pill <Button-1> [list ttkbootstrap::_te_remove_internal $w $tag]

    # Insert before the entry
    pack $pill -side left -padx [ttkbootstrap::_sp 2] -pady [ttkbootstrap::_sp 2] \
        -before [set ${ns}::entry]

    lappend ${ns}::tags $tag
    _te_notify $w
}

proc _te_remove_internal {w tag} {
    set ns ::ttkbootstrap::te::$w
    set inner [set ${ns}::inner]
    set safe  [string map {. _ / _ : _ " " _} $tag]
    set pill  $inner.pill_$safe
    catch { destroy $pill }
    set ${ns}::tags [lsearch -all -inline -not -exact [set ${ns}::tags] $tag]
    _te_notify $w
}

proc _te_notify {w} {
    set ns ::ttkbootstrap::te::$w
    set cmd [set ${ns}::command]
    if {$cmd ne {}} { uplevel #0 $cmd [list [set ${ns}::tags]] }
    _te_resize $w
}

proc _te_restyle {w} {
    set ns ::ttkbootstrap::te::$w
    if {![namespace exists $ns]} return
    set bg [ttkbootstrap::getColor bg]
    set inputbg [ttkbootstrap::getColor inputbg]
    # Update canvas and outer frame backgrounds
    set c [set ${ns}::canvas]
    if {[winfo exists $c]} {
        $c configure -background $inputbg
        # Ensure the frame around the canvas matches page bg
        catch { [winfo parent $c] configure -background $bg }
        catch { [winfo parent [winfo parent $c]] configure -background $bg }
    }
    # Rebuild all pills with new theme colours
    set bs    [set ${ns}::bootstyle]
    set hex   [ttkbootstrap::getColor $bs]
    set fg    [ttkbootstrap::_contrastFg $hex]
    set inner [set ${ns}::inner]
    set tags  [set ${ns}::tags]
    # Destroy old pills and recreate
    foreach child [winfo children $inner] {
        if {[string match "*.pill_*" $child]} {
            catch { 
                set imgname ${child}::bg
                image delete $imgname
            }
            destroy $child
        }
    }
    # Recreate pills
    set ${ns}::tags {}
    foreach tag $tags {
        _te_add_internal $w $tag
    }
}

} ;# end namespace ttkbootstrap

# Public dispatch — make $w act as a command
namespace eval ttkbootstrap::TagEntry {}
proc ttkbootstrap::TagEntry::_dispatch {w cmd args} {
    switch -- $cmd {
        get    { return [set ::ttkbootstrap::te::${w}::tags] }
        add    { foreach t $args { ttkbootstrap::_te_add_internal    $w $t } }
        remove { foreach t $args { ttkbootstrap::_te_remove_internal $w $t } }
        clear  {
            foreach t [set ::ttkbootstrap::te::${w}::tags] {
                ttkbootstrap::_te_remove_internal $w $t
            }
        }
        configure {
            array set o $args
            if {[info exists o(-bootstyle)]} {
                set ::ttkbootstrap::te::${w}::bootstyle $o(-bootstyle)
            }
            if {[info exists o(-command)]} {
                set ::ttkbootstrap::te::${w}::command $o(-command)
            }
        }
        default { error "Unknown TagEntry command: $cmd" }
    }
}
