# =============================================================================
# svgwidgets.tcl — SVG-based widget variants
#
# Crisp SVG-rendered widgets using Tk 9's built-in SVG support.
# Each widget is a ttk::label or ttk::frame with SVG background images
# that auto-regenerate on <<ThemeChanged>>.
#
# Widgets:
#   ttkbootstrap::PillButton   — pill-shaped button (solid & outline)
#   ttkbootstrap::SVGButton    — rounded-rect button (solid & outline)
#   ttkbootstrap::SVGCheck     — SVG checkbox
#   ttkbootstrap::SVGRadio     — SVG radio button
#   ttkbootstrap::SVGEntry     — SVG-bordered entry field
#   ttkbootstrap::SVGCombo     — SVG-bordered combobox
#   ttkbootstrap::SVGProgress  — SVG progress bar
#   ttkbootstrap::SVGScale     — SVG scale/slider
#   ttkbootstrap::SVGMeter     — SVG circular meter (replaces canvas meter)
# =============================================================================

namespace eval ttkbootstrap {

# ── Shared SVG helpers ────────────────────────────────────────────────────────

proc _svg_rounded_rect {W H color {rx 6} {opacity 1.0}} {
    return "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'>\
<rect x='0' y='0' width='$W' height='$H' rx='$rx' ry='$rx'\
 fill='$color' opacity='$opacity'/></svg>"
}

proc _svg_rounded_rect_border {W H color bg {rx 6} {sw 2}} {
    return "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'>\
<rect x='[expr {$sw/2}]' y='[expr {$sw/2}]'\
 width='[expr {$W-$sw}]' height='[expr {$H-$sw}]'\
 rx='[expr {$rx-1}]' ry='[expr {$rx-1}]'\
 fill='$bg' stroke='$color' stroke-width='$sw'/></svg>"
}

proc _svg_pill {W H color} {
    set r [expr {$H / 2}]
    return "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'>\
<rect x='0' y='0' width='$W' height='$H' rx='$r' ry='$r' fill='$color'/></svg>"
}

proc _svg_pill_border {W H color} {
    set r [expr {$H / 2}]
    return "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'>\
<rect x='1' y='1' width='[expr {$W-2}]' height='[expr {$H-2}]'\
 rx='[expr {$r-1}]' ry='[expr {$r-1}]'\
 fill='none' stroke='$color' stroke-width='2'/></svg>"
}

# ── SVGButton — rounded-rect button ──────────────────────────────────────────
# Not pill-shaped, just a standard button with nice rounded corners (rx=6)
# and SVG rendering for crisp edges at any DPI.
#
# ttkbootstrap::SVGButton .b -text "Click" -bootstyle success -command { ... }
# ttkbootstrap::SVGButton .b -text "Outline" -bootstyle danger -outline 1

proc SVGButton {w args} {
    array set o {
        -text      "Button"
        -bootstyle primary
        -command   {}
        -outline   0
        -state     normal
        -width     0
        -height    34
        -rx        6
    }
    array set o $args

    set ns ::ttkbootstrap::svgb::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::hover 0
    set ${ns}::press 0

    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 12]
    set font [list $fn $fs bold]
    set ${ns}::font $font

    set tw [font measure $font $o(-text)]
    set W [expr {$o(-width) > 0 ? $o(-width) : $tw + 36}]
    set H $o(-height)
    set ${ns}::W $W
    set ${ns}::H $H

    _svgb_gen $w

    ttk::label $w \
        -image ${w}::n \
        -text $o(-text) \
        -compound center \
        -foreground [_svgb_fg $w] \
        -font $font \
        -cursor [expr {$o(-state) eq "disabled" ? "" : "hand2"}]

    bind $w <Enter>           [list ttkbootstrap::_svgb_ev $w hover 1]
    bind $w <Leave>           [list ttkbootstrap::_svgb_ev $w leave 0]
    bind $w <ButtonPress-1>   [list ttkbootstrap::_svgb_ev $w press 1]
    bind $w <ButtonRelease-1> [list ttkbootstrap::_svgb_ev $w release 0]
    bind $w <<ThemeChanged>>  [list ttkbootstrap::_svgb_theme $w]
    return $w
}

proc _svgb_gen {w} {
    set ns ::ttkbootstrap::svgb::$w
    array set o [set ${ns}::o]
    set W [set ${ns}::W]; set H [set ${ns}::H]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg [ttkbootstrap::getColor bg]
    set rx $o(-rx)
    foreach s {n h p} { catch { image delete ${w}::$s } }
    if {$o(-outline)} {
        image create photo ${w}::n -data [_svg_rounded_rect_border $W $H $hex $bg $rx] -format svg
        image create photo ${w}::h -data [_svg_rounded_rect_border $W $H $hex [_lighten $hex 35] $rx] -format svg
        image create photo ${w}::p -data [_svg_rounded_rect_border $W $H $hex [_lighten $hex 20] $rx] -format svg
    } else {
        image create photo ${w}::n -data [_svg_rounded_rect $W $H $hex $rx] -format svg
        image create photo ${w}::h -data [_svg_rounded_rect $W $H [_darken $hex 10] $rx] -format svg
        image create photo ${w}::p -data [_svg_rounded_rect $W $H [_darken $hex 20] $rx] -format svg
    }
}

proc _svgb_fg {w} {
    set ns ::ttkbootstrap::svgb::$w
    array set o [set ${ns}::o]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    return [expr {$o(-outline) ? $hex : [_contrastFg $hex]}]
}

proc _svgb_ev {w type val} {
    set ns ::ttkbootstrap::svgb::$w
    if {![winfo exists $w]} return
    array set o [set ${ns}::o]
    if {$o(-state) eq "disabled"} return
    switch $type {
        hover   { set ${ns}::hover 1; $w configure -image ${w}::h }
        leave   { set ${ns}::hover 0; set ${ns}::press 0; $w configure -image ${w}::n }
        press   { set ${ns}::press 1; $w configure -image ${w}::p }
        release {
            set ${ns}::press 0
            if {[set ${ns}::hover]} { $w configure -image ${w}::h } else { $w configure -image ${w}::n }
            if {$o(-command) ne {}} { uplevel #0 $o(-command) }
        }
    }
}

proc _svgb_theme {w} {
    if {![winfo exists $w]} return
    _svgb_gen $w
    $w configure -image ${w}::n -foreground [_svgb_fg $w]
}

# ── SVGCheck — checkbox ──────────────────────────────────────────────────────
# ttkbootstrap::SVGCheck .c -text "Enable" -variable ::myvar -bootstyle success

proc SVGCheck {w args} {
    array set o {-text "" -variable "" -bootstyle primary -command {} -state normal}
    array set o $args

    set ns ::ttkbootstrap::svgc::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]

    set sz [ttkbootstrap::_sp 20]
    set ${ns}::sz $sz

    _svgc_gen $w

    ttk::checkbutton $w \
        -text $o(-text) \
        -variable $o(-variable) \
        -image ${w}::off \
        -selectimage ${w}::on \
        -compound left \
        -style "SVGCheck.TCheckbutton" \
        -command $o(-command)

    # Style with no indicator — we provide our own
    catch {
        ttk::style configure SVGCheck.TCheckbutton \
            -indicatorsize 0 \
            -padding {4 4}
    }
    catch {
        ttk::style map SVGCheck.TCheckbutton \
            -background [list active [ttkbootstrap::getColor bg]]
    }

    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgc_theme $w]
    return $w
}

proc _svgc_gen {w} {
    set ns ::ttkbootstrap::svgc::$w
    array set o [set ${ns}::o]
    set sz [set ${ns}::sz]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg [ttkbootstrap::getColor bg]
    set bdr [ttkbootstrap::getColor border]
    set fg [_contrastFg $hex]
    set rx 4

    foreach s {off on} { catch { image delete ${w}::$s } }

    # Unchecked: rounded rect border
    image create photo ${w}::off -format svg -data \
        "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'>\
<rect x='1' y='1' width='[expr {$sz-2}]' height='[expr {$sz-2}]'\
 rx='$rx' ry='$rx' fill='$bg' stroke='$bdr' stroke-width='2'/></svg>"

    # Checked: filled with checkmark
    set m [expr {$sz / 2}]
    set p1 [expr {$sz * 0.25}]
    set p2 [expr {$sz * 0.45}]
    set p3 [expr {$sz * 0.75}]
    set p4 [expr {$sz * 0.35}]
    set p5 [expr {$sz * 0.70}]
    image create photo ${w}::on -format svg -data \
        "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'>\
<rect x='0' y='0' width='$sz' height='$sz'\
 rx='$rx' ry='$rx' fill='$hex'/>\
<polyline points='$p1,$m $p2,$p3 $p5,$p4'\
 fill='none' stroke='$fg' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'/></svg>"
}

proc _svgc_theme {w} {
    if {![winfo exists $w]} return
    _svgc_gen $w
}

# ── SVGRadio — radio button ──────────────────────────────────────────────────
# ttkbootstrap::SVGRadio .r -text "Option A" -variable ::choice -value a -bootstyle info

proc SVGRadio {w args} {
    array set o {-text "" -variable "" -value "" -bootstyle primary -command {} -state normal}
    array set o $args

    set ns ::ttkbootstrap::svgr::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]

    set sz [ttkbootstrap::_sp 20]
    set ${ns}::sz $sz

    _svgr_gen $w

    ttk::radiobutton $w \
        -text $o(-text) \
        -variable $o(-variable) \
        -value $o(-value) \
        -image ${w}::off \
        -selectimage ${w}::on \
        -compound left \
        -style "SVGRadio.TRadiobutton" \
        -command $o(-command)

    catch {
        ttk::style configure SVGRadio.TRadiobutton \
            -indicatorsize 0 \
            -padding {4 4}
    }
    catch {
        ttk::style map SVGRadio.TRadiobutton \
            -background [list active [ttkbootstrap::getColor bg]]
    }

    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgr_theme $w]
    return $w
}

proc _svgr_gen {w} {
    set ns ::ttkbootstrap::svgr::$w
    array set o [set ${ns}::o]
    set sz [set ${ns}::sz]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg [ttkbootstrap::getColor bg]
    set bdr [ttkbootstrap::getColor border]
    set fg [_contrastFg $hex]
    set r [expr {$sz / 2}]
    set ri [expr {$r - 1}]

    foreach s {off on} { catch { image delete ${w}::$s } }

    # Unselected: circle border
    image create photo ${w}::off -format svg -data \
        "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'>\
<circle cx='$r' cy='$r' r='$ri' fill='$bg' stroke='$bdr' stroke-width='2'/></svg>"

    # Selected: filled circle with inner dot
    set dot [expr {$r * 0.4}]
    image create photo ${w}::on -format svg -data \
        "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'>\
<circle cx='$r' cy='$r' r='$ri' fill='$hex' stroke='$hex' stroke-width='2'/>\
<circle cx='$r' cy='$r' r='$dot' fill='$fg'/></svg>"
}

proc _svgr_theme {w} {
    if {![winfo exists $w]} return
    _svgr_gen $w
}

# ── SVGEntry — entry with SVG border ─────────────────────────────────────────
# ttkbootstrap::SVGEntry .e -textvariable ::mytext -bootstyle primary -width 30

proc SVGEntry {w args} {
    array set o {-textvariable "" -bootstyle primary -width 20 -state normal -placeholder ""}
    array set o $args

    set ns ::ttkbootstrap::svge::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]

    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 12]
    set font [list $fn $fs]

    frame $w -highlightthickness 0 -bd 0
    set ${ns}::frame $w

    set sz [ttkbootstrap::_sp 32]
    set ${ns}::H $sz
    _svge_gen $w

    ttk::label $w.bg -image ${w}::n
    place $w.bg -relx 0 -rely 0 -relwidth 1 -relheight 1

    set eopts [list -font $font -width $o(-width)]
    if {$o(-textvariable) ne ""} {
        lappend eopts -textvariable $o(-textvariable)
    }
    entry $w.ent {*}$eopts \
        -relief flat -bd 0 -highlightthickness 0 \
        -bg [ttkbootstrap::getColor inputbg] \
        -fg [ttkbootstrap::getColor inputfg] \
        -insertbackground [ttkbootstrap::getColor fg]
    pack $w.ent -fill x -expand 1 -padx 8 -pady 6

    bind $w.ent <FocusIn>  [list ttkbootstrap::_svge_focus $w 1]
    bind $w.ent <FocusOut> [list ttkbootstrap::_svge_focus $w 0]
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svge_theme $w]
    return $w
}

proc _svge_gen {w} {
    set ns ::ttkbootstrap::svge::$w
    array set o [set ${ns}::o]
    set H [set ${ns}::H]
    set W 200  ;# will stretch via -relwidth
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg [ttkbootstrap::getColor inputbg]
    set bdr [ttkbootstrap::getColor border]

    foreach s {n f} { catch { image delete ${w}::$s } }
    image create photo ${w}::n -format svg -data \
        [_svg_rounded_rect_border $W $H $bdr $bg 6 2]
    image create photo ${w}::f -format svg -data \
        [_svg_rounded_rect_border $W $H $hex $bg 6 2]
}

proc _svge_focus {w focused} {
    if {![winfo exists $w]} return
    $w.bg configure -image ${w}::[expr {$focused ? "f" : "n"}]
}

proc _svge_theme {w} {
    if {![winfo exists $w]} return
    _svge_gen $w
    $w.ent configure \
        -bg [ttkbootstrap::getColor inputbg] \
        -fg [ttkbootstrap::getColor inputfg] \
        -insertbackground [ttkbootstrap::getColor fg]
}

# ── SVGProgress — progress bar ───────────────────────────────────────────────
# ttkbootstrap::SVGProgress .p -bootstyle success -variable ::prog -maximum 100

proc SVGProgress {w args} {
    array set o {-bootstyle primary -variable "" -maximum 100 -length 300 -height 20}
    array set o $args

    set ns ::ttkbootstrap::svgp::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]

    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]

    canvas $w -width $o(-length) -height $o(-height) \
        -highlightthickness 0 -bd 0 \
        -bg [ttkbootstrap::getColor bg]

    _svgp_draw $w

    # Trace variable for updates
    if {$o(-variable) ne ""} {
        trace add variable $o(-variable) write \
            [list apply {{w args} { ttkbootstrap::_svgp_draw $w }} $w]
    }

    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgp_draw $w]
    bind $w <Configure>      [list ttkbootstrap::_svgp_draw $w]
    return $w
}

proc _svgp_draw {w args} {
    set ns ::ttkbootstrap::svgp::$w
    if {![winfo exists $w]} return
    array set o [set ${ns}::o]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg [ttkbootstrap::getColor secondary]

    set W [winfo width $w]
    set H [winfo height $w]
    if {$W < 2} { set W $o(-length) }
    if {$H < 2} { set H $o(-height) }

    set val 0
    if {$o(-variable) ne ""} {
        catch { set val [set $o(-variable)] }
    }
    set pct [expr {min(1.0, max(0.0, double($val) / $o(-maximum)))}]
    set fw [expr {int($W * $pct)}]

    $w delete all
    set rx [expr {$H / 2}]

    # Track background
    catch { image delete ${w}::track }
    image create photo ${w}::track -format svg -data \
        [_svg_rounded_rect $W $H $bg $rx]
    $w create image 0 0 -image ${w}::track -anchor nw

    # Fill bar
    if {$fw > 4} {
        catch { image delete ${w}::fill }
        image create photo ${w}::fill -format svg -data \
            [_svg_rounded_rect $fw $H $hex $rx]
        $w create image 0 0 -image ${w}::fill -anchor nw
    }
}

# ── SVGScale — slider ────────────────────────────────────────────────────────
# ttkbootstrap::SVGScale .s -from 0 -to 100 -bootstyle info -variable ::val

proc SVGScale {w args} {
    array set o {-from 0 -to 100 -bootstyle primary -variable "" -command "" -length 300 -height 30}
    array set o $args

    set ns ::ttkbootstrap::svgs::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::dragging 0

    canvas $w -width $o(-length) -height $o(-height) \
        -highlightthickness 0 -bd 0 -cursor hand2 \
        -bg [ttkbootstrap::getColor bg]

    _svgs_draw $w

    if {$o(-variable) ne ""} {
        trace add variable $o(-variable) write \
            [list apply {{w args} { ttkbootstrap::_svgs_draw $w }} $w]
    }

    bind $w <ButtonPress-1>   [list ttkbootstrap::_svgs_click $w %x]
    bind $w <B1-Motion>       [list ttkbootstrap::_svgs_click $w %x]
    bind $w <ButtonRelease-1> [list ttkbootstrap::_svgs_release $w]
    bind $w <Configure>       [list ttkbootstrap::_svgs_draw $w]
    bind $w <<ThemeChanged>>  [list ttkbootstrap::_svgs_draw $w]
    return $w
}

proc _svgs_draw {w args} {
    set ns ::ttkbootstrap::svgs::$w
    if {![winfo exists $w]} return
    array set o [set ${ns}::o]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg [ttkbootstrap::getColor secondary]

    set W [winfo width $w]
    set H [winfo height $w]
    if {$W < 2} { set W $o(-length) }
    if {$H < 2} { set H $o(-height) }

    set val $o(-from)
    if {$o(-variable) ne ""} { catch { set val [set $o(-variable)] } }
    set range [expr {$o(-to) - $o(-from)}]
    set pct [expr {$range > 0 ? (double($val) - $o(-from)) / $range : 0}]
    set pct [expr {min(1.0, max(0.0, $pct))}]

    set trackH 6
    set trackY [expr {($H - $trackH) / 2}]
    set thumbSz 18
    set margin 10
    set trackW [expr {$W - $margin * 2}]
    set thumbX [expr {$margin + int($trackW * $pct)}]

    $w delete all

    # Track bg
    catch { image delete ${w}::trk }
    image create photo ${w}::trk -format svg -data \
        [_svg_rounded_rect $trackW $trackH $bg 3]
    $w create image $margin $trackY -image ${w}::trk -anchor nw

    # Track fill
    set fillW [expr {int($trackW * $pct)}]
    if {$fillW > 2} {
        catch { image delete ${w}::trkf }
        image create photo ${w}::trkf -format svg -data \
            [_svg_rounded_rect $fillW $trackH $hex 3]
        $w create image $margin $trackY -image ${w}::trkf -anchor nw
    }

    # Thumb
    set ty [expr {$H / 2}]
    set tr [expr {$thumbSz / 2}]
    catch { image delete ${w}::thumb }
    image create photo ${w}::thumb -format svg -data \
        "<svg xmlns='http://www.w3.org/2000/svg' width='$thumbSz' height='$thumbSz'>\
<circle cx='$tr' cy='$tr' r='[expr {$tr-1}]' fill='$hex' stroke='white' stroke-width='2'/></svg>"
    $w create image $thumbX $ty -image ${w}::thumb -anchor center
}

proc _svgs_click {w x} {
    set ns ::ttkbootstrap::svgs::$w
    if {![winfo exists $w]} return
    array set o [set ${ns}::o]
    set ${ns}::dragging 1
    set W [winfo width $w]
    set margin 10
    set trackW [expr {$W - $margin * 2}]
    set pct [expr {max(0.0, min(1.0, double($x - $margin) / $trackW))}]
    set val [expr {$o(-from) + $pct * ($o(-to) - $o(-from))}]
    if {$o(-variable) ne ""} {
        set $o(-variable) $val
    }
    if {$o(-command) ne ""} {
        uplevel #0 $o(-command) $val
    }
}

proc _svgs_release {w} {
    set ns ::ttkbootstrap::svgs::$w
    set ${ns}::dragging 0
}

# ── SVGMeter — circular SVG meter ────────────────────────────────────────────
# Uses SVG arcs instead of canvas arcs for crisp rendering.
# ttkbootstrap::SVGMeter .m -bootstyle info -amountused 72 -amounttotal 100

proc SVGMeter {w args} {
    array set o {
        -amountused 0 -amounttotal 100
        -metersize 180 -meterthickness 12
        -metertype arc -bootstyle primary
        -subtext "" -textright ""
        -showvalue 1 -interactive 0
    }
    array set o $args

    set ns ::ttkbootstrap::svgm::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]

    set sz $o(-metersize)
    ttk::label $w -compound center
    _svgm_draw $w

    if {$o(-interactive)} {
        bind $w <ButtonPress-1>  [list ttkbootstrap::_svgm_drag $w %x %y]
        bind $w <B1-Motion>      [list ttkbootstrap::_svgm_drag $w %x %y]
    }
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgm_draw $w]
    return $w
}

proc _svgm_draw {w} {
    set ns ::ttkbootstrap::svgm::$w
    if {![winfo exists $w]} return
    array set o [set ${ns}::o]

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg [ttkbootstrap::getColor bg]
    set fgc [ttkbootstrap::getColor fg]
    set trk [ttkbootstrap::getColor secondary]

    set sz $o(-metersize)
    set th $o(-meterthickness)
    set cx [expr {$sz / 2}]
    set cy [expr {$sz / 2}]
    set r  [expr {$sz / 2 - $th}]

    set pct [expr {$o(-amounttotal) > 0 ? double($o(-amountused)) / $o(-amounttotal) : 0}]
    set pct [expr {min(1.0, max(0.0, $pct))}]

    if {$o(-metertype) eq "arc"} {
        set startA 135
        set sweepMax 270
    } else {
        set startA 90
        set sweepMax 360
    }
    set sweepFill [expr {$sweepMax * $pct}]

    # Build SVG path for arcs
    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs_big [ttkbootstrap::_sf 24]
    set fs_sm  [ttkbootstrap::_sf 11]

    # Value and subtext
    set valtext [expr {int($o(-amountused))}]
    if {$o(-textright) ne ""} { append valtext $o(-textright) }

    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'>"
    # Background circle
    append svg "<circle cx='$cx' cy='$cy' r='$r' fill='none' stroke='$trk' stroke-width='$th'/>"

    # Filled arc — use stroke-dasharray trick
    if {$pct > 0} {
        set circ [expr {2 * 3.14159265 * $r}]
        set fillLen [expr {$circ * $pct}]
        set gapLen  [expr {$circ - $fillLen}]
        if {$o(-metertype) eq "arc"} {
            set arcCirc [expr {$circ * $sweepMax / 360.0}]
            set fillLen [expr {$arcCirc * $pct}]
            set gapLen  [expr {$circ - $fillLen}]
        }
        # Rotate to start position
        set rotDeg [expr {$startA - 90}]
        append svg "<circle cx='$cx' cy='$cy' r='$r' fill='none'\
 stroke='$hex' stroke-width='$th'\
 stroke-dasharray='$fillLen $gapLen'\
 stroke-linecap='round'\
 transform='rotate($rotDeg $cx $cy)'/>"
    }

    # Center text
    if {$o(-showvalue)} {
        append svg "<text x='$cx' y='[expr {$cy - 2}]'\
 text-anchor='middle' dominant-baseline='middle'\
 font-family='$fn' font-size='${fs_big}px' font-weight='bold'\
 fill='$fgc'>$valtext</text>"
    }
    if {$o(-subtext) ne ""} {
        append svg "<text x='$cx' y='[expr {$cy + $fs_big/2 + 6}]'\
 text-anchor='middle' dominant-baseline='middle'\
 font-family='$fn' font-size='${fs_sm}px'\
 fill='$fgc'>$o(-subtext)</text>"
    }

    append svg "</svg>"

    catch { image delete ${w}::meter }
    image create photo ${w}::meter -format svg -data $svg
    $w configure -image ${w}::meter
}

proc _svgm_drag {w x y} {
    set ns ::ttkbootstrap::svgm::$w
    if {![winfo exists $w]} return
    array set o [set ${ns}::o]
    set sz $o(-metersize)
    set cx [expr {$sz / 2.0}]
    set cy [expr {$sz / 2.0}]
    set dx [expr {$x - $cx}]
    set dy [expr {$cy - $y}]
    set angle [expr {atan2($dx, $dy) * 180 / 3.14159265}]
    if {$angle < 0} { set angle [expr {$angle + 360}] }
    set pct [expr {min(1.0, max(0.0, $angle / 360.0))}]
    set val [expr {int($pct * $o(-amounttotal))}]
    lset ${ns}::o [lsearch [set ${ns}::o] -amountused] -amountused
    # Update opts
    array set newo [set ${ns}::o]
    set newo(-amountused) $val
    set ${ns}::o [array get newo]
    _svgm_draw $w
}

} ;# end namespace ttkbootstrap
