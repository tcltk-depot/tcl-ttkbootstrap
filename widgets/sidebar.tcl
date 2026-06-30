# =============================================================================
# sidebar.tcl — Collapsible navigation sidebar
#
# USAGE
#   set sb [ttkbootstrap::Sidebar .sb \
#       -bootstyle dark \
#       -width     200 \
#       -minwidth  48 \
#       -position  left]
#   pack $sb -side left -fill y
#
#   # Add navigation items
#   ttkbootstrap::Sidebar::add $sb home    "Home"     -icon ti-home    -command { show_home }
#   ttkbootstrap::Sidebar::add $sb reports "Reports"  -icon ti-chart-bar -badge 3
#   ttkbootstrap::Sidebar::add $sb users   "Users"    -icon ti-users   -command { show_users }
#   ttkbootstrap::Sidebar::separator $sb
#   ttkbootstrap::Sidebar::add $sb settings "Settings" -icon ti-settings
#
#   # Select an item programmatically
#   ttkbootstrap::Sidebar::select $sb home
#
#   # Collapse/expand
#   ttkbootstrap::Sidebar::collapse $sb
#   ttkbootstrap::Sidebar::expand   $sb
#   ttkbootstrap::Sidebar::toggle   $sb
#
# OPTIONS
#   -bootstyle  color   Background colour keyword (default: dark)
#   -width      int     Expanded width in pixels  (default: 200)
#   -minwidth   int     Collapsed width — icons only (default: 48)
#   -position   left|right  Which side (affects animation direction, default: left)
#   -collapsible 0|1   Show collapse toggle button (default: 1)
#
# ITEM OPTIONS  (passed to ::add)
#   -icon    string   Tabler icon name WITHOUT "ti-" prefix (e.g. "home")
#             NOTE: icons require the Tabler webfont; if unavailable a
#             fallback Unicode glyph is shown instead.
#   -command script   Called when item is clicked
#   -badge   int|str  Small badge shown on the right (cleared when 0/{})
#   -state   normal|disabled
# =============================================================================

namespace eval ttkbootstrap {

proc Sidebar {w args} {
    array set opts {
        -bootstyle   dark
        -width       200
        -minwidth    48
        -position    left
        -collapsible 1
        -on-toggle   {}
    }
    array set opts $args

    set ns ::ttkbootstrap::sb2::$w
    namespace eval $ns {}
    set ${ns}::opts     [array get opts]
    set ${ns}::items    {}        ;# ordered list of item keys
    set ${ns}::selected {}        ;# currently selected key
    set ${ns}::expanded 1         ;# 1 = full width, 0 = collapsed

    # Colour derivation
    set hex [ttkbootstrap::getColor $opts(-bootstyle)]
    set fg  [ttkbootstrap::_contrastFg $hex]
    set sel [ttkbootstrap::Colors::update_hsv $hex -vd 0.15]   ;# lighter for selection
    set hov [ttkbootstrap::Colors::update_hsv $hex -vd 0.08]   ;# subtle hover

    set ${ns}::hex $hex
    set ${ns}::fg  $fg
    set ${ns}::sel $sel
    set ${ns}::hov $hov

    # Root frame — fixed width, fills height
    frame $w -background $hex -relief flat -borderwidth 0
    set ${ns}::frame $w

    # Inner container (pack-based column)
    set inner [frame $w.inner -background $hex -borderwidth 0]
    pack $inner -fill both -expand 1
    set ${ns}::inner $inner

    # Optional collapse toggle at the top
    if {$opts(-collapsible)} {
        _sb2_build_toggle $w
    }

    # Item container
    set items_f [frame $inner.items -background $hex -borderwidth 0]
    pack $items_f -fill x -side top
    set ${ns}::items_frame $items_f

    # Separator placeholder (bottom spacer)
    frame $inner.bot -background $hex -height 1
    pack $inner.bot -side bottom -fill x

    # Set initial width
    $w configure -width [ttkbootstrap::_sp $opts(-width)]

    bind $w <<ThemeChanged>> [list ttkbootstrap::_sb2_restyle $w]

    return $w
}

proc _sb2_build_toggle {w} {
    set ns  ::ttkbootstrap::sb2::$w
    array set o [set ${ns}::opts]
    set hex [set ${ns}::hex]
    set fg  [set ${ns}::fg]
    set hov [set ${ns}::hov]
    set inner [set ${ns}::inner]

    set tog [frame $inner.tog -background $hex -cursor hand2]
    pack $tog -fill x -side top

    set arrow [label $tog.arrow \
        -text        "‹" \
        -background  $hex \
        -foreground  $fg \
        -font        [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                           [ttkbootstrap::_sf 16]] \
        -anchor      e \
        -padx        [ttkbootstrap::_sp 10] \
        -pady        [ttkbootstrap::_sp 6] \
        -cursor      hand2]
    pack $arrow -fill x

    set ${ns}::toggle_arrow $arrow

    foreach wb [list $tog $arrow] {
        bind $wb <Button-1> [list ttkbootstrap::Sidebar::toggle $w]
        bind $wb <Enter>    [list $wb configure -background $hov]
        bind $wb <Leave>    [list $wb configure -background $hex]
    }
}

proc _sb2_restyle {w} {
    set ns ::ttkbootstrap::sb2::$w
    if {![namespace exists $ns]} return
    array set o [set ${ns}::opts]

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    set fg  [ttkbootstrap::_contrastFg $hex]
    set sel [ttkbootstrap::Colors::update_hsv $hex -vd 0.15]
    set hov [ttkbootstrap::Colors::update_hsv $hex -vd 0.08]

    set ${ns}::hex $hex
    set ${ns}::fg  $fg
    set ${ns}::sel $sel
    set ${ns}::hov $hov

    # Recolour root and inner
    catch { $w configure -background $hex }
    catch { [set ${ns}::inner] configure -background $hex }
    catch { [set ${ns}::items_frame] configure -background $hex }
    catch { [set ${ns}::inner].tog configure -background $hex }
    catch { [set ${ns}::toggle_arrow] configure -background $hex -foreground $fg }

    # Recolour all item rows
    set selected [set ${ns}::selected]
    foreach key [set ${ns}::items] {
        set ins ::ttkbootstrap::sb2::${w}::item_$key
        if {![namespace exists $ins]} continue
        set row  [set ${ins}::row]
        set lbl  [set ${ins}::lbl]
        set ilbl [set ${ins}::ilbl]
        set bg   [expr {$key eq $selected ? $sel : $hex}]
        catch { $row  configure -background $bg }
        catch { $lbl  configure -background $bg -foreground $fg }
        catch { $ilbl configure -background $bg -foreground $fg }
        # Badge
        set badge_w [set ${ins}::badge_w]
        if {[winfo exists $badge_w]} {
            $badge_w configure -background $sel -foreground $fg
        }
    }
}

} ;# end namespace ttkbootstrap

# ── Public namespace ──────────────────────────────────────────────────────────
namespace eval ttkbootstrap::Sidebar {}

proc ttkbootstrap::Sidebar::add {w key label args} {
    array set opts {
        -icon    {}
        -command {}
        -badge   {}
        -state   normal
    }
    array set opts $args

    set ns  ::ttkbootstrap::sb2::$w
    set ins ::ttkbootstrap::sb2::${w}::item_$key

    array set o [set ${ns}::opts]
    set hex      [set ${ns}::hex]
    set fg       [set ${ns}::fg]
    set hov      [set ${ns}::hov]
    set items_f  [set ${ns}::items_frame]
    set expanded [set ${ns}::expanded]

    namespace eval $ins {}
    set ${ins}::key     $key
    set ${ins}::label   $label
    set ${ins}::opts    [array get opts]
    set ${ins}::command $opts(-command)

    # Row frame
    set row [frame $items_f.row_$key \
        -background $hex \
        -cursor     [expr {$opts(-state) eq "normal" ? "hand2" : ""}] \
        -borderwidth 0]
    pack $row -fill x
    set ${ins}::row $row

    # Icon label (Tabler webfont or Unicode fallback)
    set icon_text [expr {$opts(-icon) ne {} ? "\u{e000}" : "•"}]
    # Use a simple text fallback since webfont may not be available
    set icon_char [ttkbootstrap::_sb2_icon_char $opts(-icon)]
    set ilbl [label $row.icon \
        -text       $icon_char \
        -background $hex \
        -foreground $fg \
        -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                         [ttkbootstrap::_sf 14]] \
        -width      2 \
        -anchor     center \
        -padx       [ttkbootstrap::_sp 8] \
        -pady       [ttkbootstrap::_sp 8]]
    pack $ilbl -side left
    set ${ins}::ilbl $ilbl

    # Text label
    set lbl [label $row.lbl \
        -text       $label \
        -background $hex \
        -foreground $fg \
        -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                         [ttkbootstrap::_sf 12]] \
        -anchor     w \
        -padx       0 \
        -pady       [ttkbootstrap::_sp 8]]
    pack $lbl -side left -fill x -expand 1
    set ${ins}::lbl $lbl

    # Badge (optional)
    set badge_w $row.badge
    if {$opts(-badge) ne {} && $opts(-badge) ne "0"} {
        label $badge_w \
            -text       $opts(-badge) \
            -background [set ${ns}::sel] \
            -foreground $fg \
            -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                             [ttkbootstrap::_sf 10]] \
            -padx       [ttkbootstrap::_sp 5] \
            -pady       [ttkbootstrap::_sp 1] \
            -relief     flat
        pack $badge_w -side right -padx [ttkbootstrap::_sp 6]
    }
    set ${ins}::badge_w $badge_w

    # Bindings
    if {$opts(-state) eq "normal"} {
        foreach wb [list $row $ilbl $lbl] {
            bind $wb <Button-1> [list ttkbootstrap::Sidebar::select $w $key]
            bind $wb <Enter>    [list ttkbootstrap::_sb2_hover $w $key 1]
            bind $wb <Leave>    [list ttkbootstrap::_sb2_hover $w $key 0]
        }
    }

    lappend ${ns}::items $key

    # If collapsed, hide text
    if {!$expanded} {
        pack forget $lbl
    }

    return $row
}

proc ttkbootstrap::_sb2_icon_char {icon} {
    # Map common icon names to Unicode characters as fallback
    # when Tabler webfont is not available
    array set map {
        home        ⌂
        chart-bar   ▦
        users       ☻
        settings    ⚙
        logout      ⏻
        folder      ▸
        file        ▪
        search      ⌕
        bell        ⌂
        mail        ✉
        lock        ⚿
        star        ★
        heart        ♥
        check       ✓
        x           ✕
        plus        ＋
        edit        ✎
        trash       ✗
        download    ↓
        upload      ↑
        refresh     ↻
        info        ⓘ
        alert       ⚠
        user        ☺
        calendar    ◫
        clock       ⊙
        dashboard   ⊞
        reports     ≡
        tools       ⚒
        shield      ⛨
        layers      ◧
        ripple      ◎
        splash      ◎
        calendar    ◫
        table       ⊞
        clock       ⏰
        edit        ✎
    }
    if {[info exists map($icon)]} { return $map($icon) }
    if {$icon ne {}} { return "•" }
    return " "
}

proc ttkbootstrap::_sb2_hover {w key on} {
    set ns  ::ttkbootstrap::sb2::$w
    set ins ::ttkbootstrap::sb2::${w}::item_$key
    if {![namespace exists $ns] || ![namespace exists $ins]} return
    set selected [set ${ns}::selected]
    if {$key eq $selected} return   ;# selected stays selected colour
    set hex [set ${ns}::hex]
    set hov [set ${ns}::hov]
    set bg  [expr {$on ? $hov : $hex}]
    set row [set ${ins}::row]
    set lbl [set ${ins}::lbl]
    set ilbl [set ${ins}::ilbl]
    catch { $row  configure -background $bg }
    catch { $lbl  configure -background $bg }
    catch { $ilbl configure -background $bg }
}

proc ttkbootstrap::Sidebar::select {w key} {
    set ns  ::ttkbootstrap::sb2::$w
    if {![namespace exists $ns]} return
    set hex [set ${ns}::hex]
    set sel [set ${ns}::sel]
    set fg  [set ${ns}::fg]
    set prev [set ${ns}::selected]

    # Deselect previous
    if {$prev ne {} && $prev ne $key} {
        set pins ::ttkbootstrap::sb2::${w}::item_$prev
        if {[namespace exists $pins]} {
            set pr [set ${pins}::row]
            set pl [set ${pins}::lbl]
            set pi [set ${pins}::ilbl]
            catch { $pr configure -background $hex }
            catch { $pl configure -background $hex }
            catch { $pi configure -background $hex }
        }
    }

    set ${ns}::selected $key

    # Highlight new selection
    set ins ::ttkbootstrap::sb2::${w}::item_$key
    if {[namespace exists $ins]} {
        set row  [set ${ins}::row]
        set lbl  [set ${ins}::lbl]
        set ilbl [set ${ins}::ilbl]
        catch { $row  configure -background $sel }
        catch { $lbl  configure -background $sel }
        catch { $ilbl configure -background $sel }

        # Fire command
        set cmd [set ${ins}::command]
        if {$cmd ne {}} { uplevel #0 $cmd }
    }
}

proc ttkbootstrap::Sidebar::separator {w} {
    set ns ::ttkbootstrap::sb2::$w
    set items_f [set ${ns}::items_frame]
    set hex     [set ${ns}::hex]
    set sep_col [ttkbootstrap::Colors::update_hsv $hex -vd 0.2]
    frame $items_f.sep[incr ::_sb2_sep_id] \
        -background $sep_col -height 1
    pack $items_f.sep$::_sb2_sep_id -fill x \
        -padx [ttkbootstrap::_sp 12] \
        -pady [ttkbootstrap::_sp 4]
}

proc ttkbootstrap::Sidebar::badge {w key value} {
    set ins ::ttkbootstrap::sb2::${w}::item_$key
    if {![namespace exists $ins]} return
    set ns ::ttkbootstrap::sb2::$w
    set badge_w [set ${ins}::badge_w]
    if {$value eq {} || $value eq "0"} {
        catch { pack forget $badge_w }
    } else {
        if {![winfo exists $badge_w]} {
            set row [set ${ins}::row]
            set fg  [set ${ns}::fg]
            set sel [set ${ns}::sel]
            label $badge_w \
                -text       $value \
                -background $sel \
                -foreground $fg \
                -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                                 [ttkbootstrap::_sf 10]] \
                -padx       [ttkbootstrap::_sp 5] \
                -pady       [ttkbootstrap::_sp 1]
        }
        $badge_w configure -text $value
        pack $badge_w -in [set ${ins}::row] -side right \
            -padx [ttkbootstrap::_sp 6]
    }
}

proc ttkbootstrap::Sidebar::collapse {w} {
    set ns ::ttkbootstrap::sb2::$w
    if {![namespace exists $ns]} return
    array set o [set ${ns}::opts]
    set ${ns}::expanded 0
    $w configure -width [ttkbootstrap::_sp $o(-minwidth)]
    # Hide all text labels and badges
    foreach key [set ${ns}::items] {
        set ins ::ttkbootstrap::sb2::${w}::item_$key
        if {![namespace exists $ins]} continue
        catch { pack forget [set ${ins}::lbl] }
        catch { pack forget [set ${ins}::badge_w] }
    }
    # Flip toggle arrow
    catch { [set ${ns}::toggle_arrow] configure -text "›" }
    # Notify any -on-toggle callback that the sidebar is now collapsed (0).
    if {$o(-on-toggle) ne {}} {
        catch { uplevel #0 [list {*}$o(-on-toggle) 0] }
    }
}

proc ttkbootstrap::Sidebar::expand {w} {
    set ns ::ttkbootstrap::sb2::$w
    if {![namespace exists $ns]} return
    array set o [set ${ns}::opts]
    set ${ns}::expanded 1
    $w configure -width [ttkbootstrap::_sp $o(-width)]
    # Show all text labels
    foreach key [set ${ns}::items] {
        set ins ::ttkbootstrap::sb2::${w}::item_$key
        if {![namespace exists $ins]} continue
        catch { pack [set ${ins}::lbl] -side left -fill x -expand 1 \
            -in [set ${ins}::row] -after [set ${ins}::ilbl] }
        # Restore badge if it has content
        set badge_w [set ${ins}::badge_w]
        if {[winfo exists $badge_w] && [$badge_w cget -text] ne {}} {
            catch { pack $badge_w -in [set ${ins}::row] -side right \
                -padx [ttkbootstrap::_sp 6] }
        }
    }
    catch { [set ${ns}::toggle_arrow] configure -text "‹" }
    # Notify any -on-toggle callback that the sidebar is now expanded (1).
    if {$o(-on-toggle) ne {}} {
        catch { uplevel #0 [list {*}$o(-on-toggle) 1] }
    }
}

proc ttkbootstrap::Sidebar::toggle {w} {
    set ns ::ttkbootstrap::sb2::$w
    if {[set ${ns}::expanded]} {
        collapse $w
    } else {
        expand $w
    }
}

proc ttkbootstrap::Sidebar::current {w} {
    return [set ::ttkbootstrap::sb2::${w}::selected]
}

# Initialise separator counter
set ::_sb2_sep_id 0
