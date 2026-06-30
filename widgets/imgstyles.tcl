# =============================================================================
# imgstyles.tcl — Image-based ttk widget styles using SVG assets
#
# Provides pixel-perfect, DPI-aware styles for:
#   • TCheckbutton  (custom checkbox with check mark)
#   • TRadiobutton  (custom radio circle)
#   • Round/Square Toolbutton toggles
#   • TScale        (circular knob, flat track)
#   • TScrollbar    (flat rect thumb, Round.TScrollbar pill thumb)
#   • TSizegrip     (dot-grid grip)
#   • Striped.TProgressbar (diagonal stripe tile)
#   • Link.TButton  (hyperlink-style button)
#   • inverse.TLabel (coloured badge labels)
#
# Called automatically by ttkbootstrap::setTheme after base styles are set.
# Requires images.tcl to be loaded first.
# =============================================================================

namespace eval ttkbootstrap {

proc _mk_layout {spec} {
    # Build a ttk layout spec string compatible with Tk 8 and Tk 9.
    #
    # Tk 9 changed the layout parser: options must be FLAT key-value pairs
    # at the same level as the element name, NOT wrapped in a sub-dict.
    # Correct: "elem -side left -sticky nsew"
    # Wrong:   "elem {-side left -sticky nsew}"
    #
    # For -children, the value must be a brace-quoted nested layout string.
    # Correct: "elem -children {child -side left}"
    #
    # Input: alternating list of {elemName {-key val -key val ...}} pairs.
    set out {}
    foreach {elem opts} $spec {
        append out "$elem"
        foreach {k v} $opts {
            if {$k eq "-children"} {
                # Recursively format children — result goes in braces
                append out " -children \{[_mk_layout $v]\}"
            } elseif {$v ne {}} {
                append out " $k $v"
            }
            # Omit options with empty values (e.g. -sticky {})
        }
        append out " "
    }
    return [string trimright $out]
}

proc _applyImageStyles {themeName} {
    variable themes
    array set c $themes($themeName)

    set scale [ttkbootstrap::img::autoScale]

    set isDark [expr {$c(type) eq "dark"}]
    set borderCol   [expr {$isDark ? $c(selectbg) : $c(border)}]
    set disabledCol [expr {$isDark ? $c(selectbg) : $c(border)}]
    set trackCol    [expr {$isDark ? \
        [ttkbootstrap::_darken $c(selectbg) 20] : $c(light)}]

    # Test SVG capability first
    set testSvg "<svg xmlns='http://www.w3.org/2000/svg' width='4' height='4'><rect width='4' height='4' fill='red'/></svg>"
    if {[catch {image create photo ::ttkbs_svg_test -data $testSvg -format {svg -scale 1}} svgErr]} {
        puts stderr "ttkbootstrap: SVG not supported: $svgErr"
        return
    }
    catch {image delete ::ttkbs_svg_test}

    # ── Checkbutton ──────────────────────────────────────────────────────────
    foreach {color hex} [list \
        default $c(primary) \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger)] {

        if {$color eq "default"} {
            set prefix ""
            set styleBase "TCheckbutton"
        } else {
            set prefix "${color}."
            set styleBase "${color}.TCheckbutton"
        }

        # Use ttkbs_ prefix + theme name so each theme gets fresh elements
        set eprefix [string map {. _} "${prefix}ttkbs_${themeName}_check"]

        set img_off  [ttkbootstrap::img::get check.unchecked   $borderCol    $scale]
        set img_on   [ttkbootstrap::img::get check.checked     $hex          $scale]
        set img_ind  [ttkbootstrap::img::get check.indeterminate $hex        $scale]
        set img_dis  [ttkbootstrap::img::get check.disabled    $disabledCol  $scale]

        catch {
            ttk::style element create ${eprefix}.indicator image \
                [list $img_off \
                    selected  $img_on \
                    alternate $img_ind \
                    disabled  $img_dis] \
                -width  [expr {int(16 * $scale)}] \
                -height [expr {int(16 * $scale)}] \
                -sticky w
        }

        ttk::style layout $styleBase [ttkbootstrap::_mk_layout [list \
            ${eprefix}.indicator [list -side left -sticky w] \
            Button.label [list -side left -sticky nsew]]]

        ttk::style configure $styleBase \
            -background $c(bg) -foreground $c(fg) \
            -padding [ttkbootstrap::_sp2 2 2]
        ttk::style map $styleBase \
            -background [list active $c(bg)] \
            -foreground [list disabled $disabledCol]
    }

    # ── Radiobutton ──────────────────────────────────────────────────────────
    foreach {color hex} [list \
        default $c(primary) \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger)] {

        if {$color eq "default"} {
            set styleBase "TRadiobutton"
            set eprefix "ttkbs_${themeName}_radio"
        } else {
            set styleBase "${color}.TRadiobutton"
            set eprefix "${color}_${themeName}_radio"
        }

        set img_off  [ttkbootstrap::img::get radio.unchecked $borderCol   $scale]
        set img_on   [ttkbootstrap::img::get radio.checked   $hex         $scale]
        set img_dis  [ttkbootstrap::img::get radio.disabled  $disabledCol $scale]

        catch {
            ttk::style element create ${eprefix}.indicator image \
                [list $img_off \
                    selected $img_on \
                    disabled $img_dis] \
                -width  [expr {int(16 * $scale)}] \
                -height [expr {int(16 * $scale)}] \
                -sticky w
        }

        ttk::style layout $styleBase [ttkbootstrap::_mk_layout [list \
            ${eprefix}.indicator [list -side left -sticky w] \
            Button.label [list -side left -sticky nsew]]]

        ttk::style configure $styleBase \
            -background $c(bg) -foreground $c(fg) \
            -padding [ttkbootstrap::_sp2 2 2]
        ttk::style map $styleBase \
            -background [list active $c(bg)] \
            -foreground [list disabled $disabledCol]
    }

    # ── Round Toggle (Toolbutton style) ──────────────────────────────────────
    foreach {color hex} [list \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger)] {

        set styleBase "${color}.Round.Toggle"
        set eprefix "${color}_${themeName}_rtoggle"

        set img_off [ttkbootstrap::img::get toggle.round.off $hex $scale]
        set img_on  [ttkbootstrap::img::get toggle.round.on  $hex $scale]

        catch {
            ttk::style element create ${eprefix}.indicator image \
                [list $img_off selected $img_on] \
                -width  [expr {int(32 * $scale)}] \
                -height [expr {int(18 * $scale)}] \
                -sticky w \

        }

        set _toggle_layout [ttkbootstrap::_mk_layout [list \
            ${eprefix}.indicator [list -side left -sticky w] \
            Button.label [list -side left -sticky nsew]]]

        # Register under both name conventions
        ttk::style layout $styleBase $_toggle_layout
        ttk::style layout "${color}.Round.TCheckbutton" $_toggle_layout

        ttk::style configure $styleBase \
            -background $c(bg) -foreground $c(fg) -padding [ttkbootstrap::_sp2 2 4]
        ttk::style configure "${color}.Round.TCheckbutton" \
            -background $c(bg) -foreground $c(fg) -padding [ttkbootstrap::_sp2 2 4]
    }

    # ── Square Toggle ────────────────────────────────────────────────────────
    foreach {color hex} [list \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger)] {

        set styleBase "${color}.Square.Toggle"
        set eprefix "${color}_${themeName}_stoggle"

        set img_off [ttkbootstrap::img::get toggle.square.off $hex $scale]
        set img_on  [ttkbootstrap::img::get toggle.square.on  $hex $scale]

        catch {
            ttk::style element create ${eprefix}.indicator image \
                [list $img_off selected $img_on] \
                -width  [expr {int(32 * $scale)}] \
                -height [expr {int(18 * $scale)}] \
                -sticky w \

        }

        set _toggle_layout [ttkbootstrap::_mk_layout [list \
            ${eprefix}.indicator [list -side left -sticky w] \
            Button.label [list -side left -sticky nsew]]]

        # Register under both name conventions
        ttk::style layout $styleBase $_toggle_layout
        ttk::style layout "${color}.Square.TCheckbutton" $_toggle_layout

        ttk::style configure $styleBase \
            -background $c(bg) -foreground $c(fg) -padding [ttkbootstrap::_sp2 2 4]
        ttk::style configure "${color}.Square.TCheckbutton" \
            -background $c(bg) -foreground $c(fg) -padding [ttkbootstrap::_sp2 2 4]
    }

    # ── TScale ───────────────────────────────────────────────────────────────
    foreach {color hex} [list \
        default $c(primary) \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger)] {

        if {$color eq "default"} {
            set hs "Horizontal.TScale"
            set vs "Vertical.TScale"
            set ep "ttkbs_${themeName}_scale"
        } else {
            set hs "${color}.Horizontal.TScale"
            set vs "${color}.Vertical.TScale"
            set ep "${color}_${themeName}_scale"
        }

        set sl_n  [ttkbootstrap::img::get scale.slider          $hex         $scale]
        set sl_h  [ttkbootstrap::img::get scale.slider.hover    $hex         $scale]
        set sl_d  [ttkbootstrap::img::get scale.slider.disabled $disabledCol $scale]

        set sz [expr {int(16 * $scale)}]

        # Create only the slider knob as a custom image element.
        # Use clam's Scale.trough for the track (avoids layout issues).
        # The trough color is set via configure -troughcolor.
        catch {
            ttk::style element create ${ep}.slider image \
                [list $sl_n disabled $sl_d pressed $sl_h active $sl_h] \
                -width $sz -height $sz
        }

        # Layout: use clam's trough element directly (Scale.focus may not exist in Tk9)
        ttk::style layout $hs [ttkbootstrap::_mk_layout [list \
            Horizontal.Scale.trough [list -sticky nsew -children [list \
                ${ep}.slider [list -side left] \
            ]]]]

        ttk::style layout $vs [ttkbootstrap::_mk_layout [list \
            Vertical.Scale.trough [list -sticky nsew -children [list \
                ${ep}.slider [list -side top] \
            ]]]]

        # Configure trough color and slider appearance
        set trough [ttkbootstrap::Colors::update_hsv $hex -sd -0.3 -vd \
            [expr {$isDark ? -0.3 : 0.3}]]
        ttk::style configure $hs \
            -background $c(bg) -troughcolor $trough \
            -darkcolor $trough -lightcolor $trough \
            -sliderlength $sz -sliderthickness $sz \
            -borderwidth 0
        ttk::style configure $vs \
            -background $c(bg) -troughcolor $trough \
            -darkcolor $trough -lightcolor $trough \
            -sliderlength $sz -sliderthickness $sz \
            -borderwidth 0
    }

    # ── TScrollbar (flat) ────────────────────────────────────────────────────
    set thumbBase [expr {$isDark ? $c(secondary) : $c(border)}]
    set thumbPres [ttkbootstrap::_darken $thumbBase 15]
    set thumbAct  [ttkbootstrap::_lighten $thumbBase 10]

    foreach {color hex} [list \
        default $thumbBase \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger) \
        light   $c(light)   dark   $c(dark)] {

        if {$color eq "default"} {
            set hs "Horizontal.TScrollbar"
            set vs "Vertical.TScrollbar"
            set ep "ttkbs_${themeName}_scrollbar"
        } else {
            set hs "${color}.Horizontal.TScrollbar"
            set vs "${color}.Vertical.TScrollbar"
            set ep "${color}_${themeName}_scrollbar"
        }

        set pres [ttkbootstrap::_darken $hex 15]
        set act  [ttkbootstrap::_lighten $hex 10]

        set th_h  [ttkbootstrap::img::get scrollbar.thumb.h $hex  $scale]
        set th_hp [ttkbootstrap::img::get scrollbar.thumb.h $pres $scale]
        set th_ha [ttkbootstrap::img::get scrollbar.thumb.h $act  $scale]
        set th_v  [ttkbootstrap::img::get scrollbar.thumb.v $hex  $scale]
        set th_vp [ttkbootstrap::img::get scrollbar.thumb.v $pres $scale]
        set th_va [ttkbootstrap::img::get scrollbar.thumb.v $act  $scale]

        catch {
            ttk::style element create ${ep}.h.thumb image \
                [list $th_h pressed $th_hp active $th_ha] \
                -border [list [ttkbootstrap::_sp 4] 0] -sticky ew -padding 0
        }
        catch {
            ttk::style element create ${ep}.v.thumb image \
                [list $th_v pressed $th_vp active $th_va] \
                -border [list 0 [ttkbootstrap::_sp 4]] -sticky ns -padding 0
        }

        ttk::style layout $hs [ttkbootstrap::_mk_layout [list \
            Horizontal.Scrollbar.trough [list -sticky we -children [list \
                Horizontal.Scrollbar.leftarrow  [list -side left] \
                Horizontal.Scrollbar.rightarrow [list -side right] \
                ${ep}.h.thumb               [list -expand 1 -sticky nswe] \
            ]]]]

        ttk::style layout $vs [ttkbootstrap::_mk_layout [list \
            Vertical.Scrollbar.trough [list -sticky ns -children [list \
                Vertical.Scrollbar.uparrow   [list -side top] \
                Vertical.Scrollbar.downarrow [list -side bottom] \
                ${ep}.v.thumb           [list -expand 1 -sticky nswe] \
            ]]]]

        set troughCol [expr {$isDark ? \
            [ttkbootstrap::_darken $c(bg) 8] : \
            [ttkbootstrap::_darken $c(light) 5]}]
        ttk::style configure $hs \
            -troughcolor $troughCol -borderwidth 0 -relief flat \
            -arrowcolor $hex -arrowsize [expr {int(11 * $scale)}]
        ttk::style configure $vs \
            -troughcolor $troughCol -borderwidth 0 -relief flat \
            -arrowcolor $hex -arrowsize [expr {int(11 * $scale)}]
        ttk::style map $hs \
            -arrowcolor [list pressed $pres active $act]
        ttk::style map $vs \
            -arrowcolor [list pressed $pres active $act]
    }

    # ── Round.TScrollbar ─────────────────────────────────────────────────────
    foreach {color hex} [list \
        default $thumbBase \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger) \
        light   $c(light)   dark   $c(dark)] {

        if {$color eq "default"} {
            set hs "Round.Horizontal.TScrollbar"
            set vs "Round.Vertical.TScrollbar"
            set ep "ttkbs_${themeName}_round_scrollbar"
        } else {
            set hs "${color}.Round.Horizontal.TScrollbar"
            set vs "${color}.Round.Vertical.TScrollbar"
            set ep "${color}_${themeName}_round_scrollbar"
        }

        set pres [ttkbootstrap::_darken $hex 15]
        set act  [ttkbootstrap::_lighten $hex 10]

        set th_h  [ttkbootstrap::img::get scrollbar.round.thumb.h $hex  $scale]
        set th_hp [ttkbootstrap::img::get scrollbar.round.thumb.h $pres $scale]
        set th_ha [ttkbootstrap::img::get scrollbar.round.thumb.h $act  $scale]
        set th_v  [ttkbootstrap::img::get scrollbar.round.thumb.v $hex  $scale]
        set th_vp [ttkbootstrap::img::get scrollbar.round.thumb.v $pres $scale]
        set th_va [ttkbootstrap::img::get scrollbar.round.thumb.v $act  $scale]

        catch {
            ttk::style element create ${ep}.h.thumb image \
                [list $th_h pressed $th_hp active $th_ha] \
                -border [list [ttkbootstrap::_sp 5] 0] -sticky ew -padding 0
        }
        catch {
            ttk::style element create ${ep}.v.thumb image \
                [list $th_v pressed $th_vp active $th_va] \
                -border [list 0 [ttkbootstrap::_sp 5]] -sticky ns -padding 0
        }

        ttk::style layout $hs [ttkbootstrap::_mk_layout [list \
            Horizontal.Scrollbar.trough [list -sticky we -children [list \
                ${ep}.h.thumb [list -expand 1 -sticky nswe] \
            ]]]]

        ttk::style layout $vs [ttkbootstrap::_mk_layout [list \
            Vertical.Scrollbar.trough [list -sticky ns -children [list \
                ${ep}.v.thumb [list -expand 1 -sticky nswe] \
            ]]]]

        ttk::style configure $hs \
            -troughcolor $trackCol -borderwidth 0 -relief flat
        ttk::style configure $vs \
            -troughcolor $trackCol -borderwidth 0 -relief flat
    }

    # ── TSizegrip ─────────────────────────────────────────────────────────────
    set sgImg [ttkbootstrap::img::get sizegrip $c(secondary) $scale]
    catch {
        ttk::style element create custom.sizegrip image $sgImg -sticky se
    }
    ttk::style layout TSizegrip [ttkbootstrap::_mk_layout [list \
        custom.sizegrip {-side bottom -sticky se}]]

    # ── Striped.TProgressbar ─────────────────────────────────────────────────
    foreach {color hex} [list \
        default $c(primary) \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger) \
        light $c(light)] {

        if {$color eq "default"} {
            set hs "Striped.Horizontal.TProgressbar"
            set vs "Striped.Vertical.TProgressbar"
            set ep "ttkbs_${themeName}_striped"
        } else {
            set hs "${color}.Striped.Horizontal.TProgressbar"
            set vs "${color}.Striped.Vertical.TProgressbar"
            set ep "${color}_${themeName}_striped"
        }

        # For the light color on light themes use bg as the lighter variant
        if {$color eq "light"} {
            set lighter [ttkbootstrap::_lighten $hex 5]
        } else {
            set lighter [ttkbootstrap::_lighten $hex 15]
        }
        set stH [ttkbootstrap::img::get progress.stripe.h $lighter $scale]
        set stV [ttkbootstrap::img::get progress.stripe.v $lighter $scale]

        # Darker base for stripe background
        set darker [ttkbootstrap::_darken $hex 12]
        set stHd [ttkbootstrap::img::get progress.stripe.h $darker $scale]
        set stVd [ttkbootstrap::img::get progress.stripe.v $darker $scale]

        set thickness [expr {int(12 * $scale)}]

        # Trough (background) elements
        catch {
            ttk::style element create ${ep}.h.trough image $stHd \
                -sticky nsew
        }
        catch {
            ttk::style element create ${ep}.v.trough image $stVd \
                -sticky nsew
        }
        # Pbar (foreground stripe tile) elements
        catch {
            ttk::style element create ${ep}.h.pbar image $stH \
                -width $thickness -sticky ew
        }
        catch {
            ttk::style element create ${ep}.v.pbar image $stV \
                -width $thickness -sticky ns
        }

        ttk::style layout $hs [ttkbootstrap::_mk_layout [list \
            ${ep}.h.trough [list -sticky nsew -children [list \
                ${ep}.h.pbar [list -side left -sticky ns] \
            ]]]]
        ttk::style layout $vs [ttkbootstrap::_mk_layout [list \
            ${ep}.v.trough [list -sticky nsew -children [list \
                ${ep}.v.pbar [list -side bottom -sticky ew] \
            ]]]]

        ttk::style configure $hs \
            -troughcolor $trackCol -borderwidth [ttkbootstrap::_sp 1] \
            -bordercolor $trackCol -thickness $thickness
        ttk::style configure $vs \
            -troughcolor $trackCol -borderwidth [ttkbootstrap::_sp 1] \
            -bordercolor $trackCol -thickness $thickness
    }


    # ── Link.TButton ─────────────────────────────────────────────────────────
    ttk::style configure Link.TButton \
        -foreground  $c(primary) \
        -background  $c(bg) \
        -darkcolor   $c(bg) \
        -lightcolor  $c(bg) \
        -bordercolor $c(bg) \
        -borderwidth [ttkbootstrap::_sp 1] \
        -padding [ttkbootstrap::_sp2 4 2] \
        -relief flat \
        -anchor center
    ttk::style map Link.TButton \
        -foreground  [list active [ttkbootstrap::_darken $c(primary) 15]] \
        -background  [list active $c(bg) disabled $c(bg)] \
        -darkcolor   [list active $c(bg)] \
        -lightcolor  [list active $c(bg)] \
        -relief      [list active flat]

    foreach {color hex} [list \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger)] {

        set styleBase "${color}.Link.TButton"
        ttk::style configure $styleBase \
            -foreground  $hex \
            -background  $c(bg) \
            -darkcolor   $c(bg) \
            -lightcolor  $c(bg) \
            -bordercolor $c(bg) \
            -borderwidth [ttkbootstrap::_sp 1] \
            -padding [ttkbootstrap::_sp2 4 2] \
            -relief flat \
            -anchor center
        ttk::style map $styleBase \
            -foreground  [list active [ttkbootstrap::_darken $hex 15]] \
            -background  [list active $c(bg)] \
            -darkcolor   [list active $c(bg)] \
            -lightcolor  [list active $c(bg)] \
            -relief      [list active flat]
    }

    # ── inverse.TLabel (coloured background badges) ───────────────────────
    foreach {color hex} [list \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger) \
        light $c(light) dark $c(dark)] {

        set fg [ttkbootstrap::_contrastFg $hex]
        ttk::style configure "inverse.${color}.TLabel" \
            -background $hex \
            -foreground $fg \
            -padding [ttkbootstrap::_sp2 6 3]
    }

    # ── TToolbutton ──────────────────────────────────────────────────────────
    # Styles named *.Toolbutton.TButton inherit TButton's layout automatically
    # since they end in TButton — no layout registration needed.
    foreach {color hex} [list \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger)] {

        set activeHex   [ttkbootstrap::_darken $hex 8]
        set selectedHex [ttkbootstrap::_darken $hex 15]

        # Solid toolbutton
        ttk::style configure "${color}.Toolbutton.TButton" \
            -background $hex \
            -foreground [ttkbootstrap::_contrastFg $hex] \
            -borderwidth [ttkbootstrap::_sp 1] \
            -bordercolor $hex \
            -darkcolor   $hex \
            -lightcolor  $hex \
            -padding [ttkbootstrap::_sp2 8 4] \
            -relief flat \
            -anchor center
        ttk::style map "${color}.Toolbutton.TButton" \
            -background [list selected $selectedHex active $activeHex \
                              pressed  $selectedHex] \
            -darkcolor  [list selected $selectedHex active $activeHex] \
            -lightcolor [list selected $selectedHex active $activeHex] \
            -relief     [list selected sunken pressed sunken]

        # Outline toolbutton — explicit TButton layout for visible border
        set _tb_layout [ttk::style layout TButton]
        catch { ttk::style layout "${color}.Outline.Toolbutton.TButton" $_tb_layout }
        ttk::style configure "${color}.Outline.Toolbutton.TButton" \
            -background $c(bg) \
            -foreground $hex \
            -borderwidth [ttkbootstrap::_sp 1] \
            -bordercolor $hex \
            -darkcolor   $hex \
            -lightcolor  $hex \
            -padding [ttkbootstrap::_sp2 8 4] \
            -relief groove \
            -anchor center
        ttk::style map "${color}.Outline.Toolbutton.TButton" \
            -background [list selected $hex active $hex pressed $hex] \
            -foreground [list selected [ttkbootstrap::_contrastFg $hex] \
                              active   [ttkbootstrap::_contrastFg $hex]] \
            -darkcolor  [list selected $hex active $hex] \
            -lightcolor [list selected $hex active $hex] \
            -relief     [list selected sunken pressed sunken]
    }

    # Default (no color prefix)
    ttk::style configure Toolbutton.TButton \
        -background $c(primary) \
        -foreground [ttkbootstrap::_contrastFg $c(primary)] \
        -borderwidth 1 -bordercolor $c(primary) \
        -darkcolor $c(primary) -lightcolor $c(primary) \
        -padding [ttkbootstrap::_sp2 8 4] -relief flat -anchor center
    ttk::style map Toolbutton.TButton \
        -background [list selected [ttkbootstrap::_darken $c(primary) 15] \
                          active   [ttkbootstrap::_darken $c(primary) 8]] \
        -darkcolor  [list selected [ttkbootstrap::_darken $c(primary) 15]] \
        -lightcolor [list selected [ttkbootstrap::_darken $c(primary) 15]] \
        -relief     [list selected sunken]

    set _tb_layout [ttk::style layout TButton]
    catch { ttk::style layout "Outline.Toolbutton.TButton" $_tb_layout }
    ttk::style configure Outline.Toolbutton.TButton \
        -background $c(bg) -foreground $c(primary) \
        -borderwidth 1 -bordercolor $c(primary) \
        -darkcolor $c(primary) -lightcolor $c(primary) \
        -padding [ttkbootstrap::_sp2 8 4] -relief solid -anchor center
    ttk::style map Outline.Toolbutton.TButton \
        -background [list selected $c(primary) active $c(primary)] \
        -foreground [list selected [ttkbootstrap::_contrastFg $c(primary)] \
                          active   [ttkbootstrap::_contrastFg $c(primary)]] \
        -darkcolor  [list selected $c(primary) active $c(primary)] \
        -lightcolor [list selected $c(primary) active $c(primary)] \
        -relief     [list selected sunken]

    # ── Separator image elements ─────────────────────────────────────────────
    # Python uses a 1px solid-colour image for separators; we do the same via
    # SVG so they match the theme exactly rather than using the clam default.
    foreach {orient imgname stickyval} [list \
        Horizontal sep.h.img ew \
        Vertical   sep.v.img ns] {

        set sepColor [expr {$isDark ? $c(selectbg) : $c(border)}]
        set sepSvg [ttkbootstrap::img::get [expr {$orient eq "Horizontal" \
            ? "sep.horizontal" : "sep.vertical"}] $sepColor $scale]
        catch {
            ttk::style element create $imgname image $sepSvg \
                -sticky $stickyval
        }
        ttk::style layout "${orient}.TSeparator" [ttkbootstrap::_mk_layout [list \
            $imgname [list -sticky $stickyval]]]
        ttk::style configure "${orient}.TSeparator" -background $sepColor
    }

    # Per-color separator variants
    foreach {color hex} [list \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger)] {
        ttk::style configure "${color}.Horizontal.TSeparator" -background $hex
        ttk::style configure "${color}.Vertical.TSeparator"   -background $hex
    }

    # ── Default Floodgauge (no color prefix) ─────────────────────────────────
    # Python registers Horizontal.TFloodgauge and Vertical.TFloodgauge using
    # clam-derived trough+pbar elements; mirror that here so bare Floodgauge
    # widgets work without a -bootstyle argument.
    set fg_flood [ttkbootstrap::_contrastFg $c(primary)]
    set trough_flood [ttkbootstrap::Colors::update_hsv $c(primary) -sd -0.3 -vd 0.8]
    catch {
        ttk::style element create def_flood.h.trough from clam
        ttk::style element create def_flood.h.pbar   from default
        ttk::style element create def_flood.v.trough from clam
        ttk::style element create def_flood.v.pbar   from default
    }
    ttk::style layout Horizontal.TFloodgauge [ttkbootstrap::_mk_layout [list \
        def_flood.h.trough [list -sticky nsew -children [list \
            def_flood.h.pbar  [list -sticky ns] \
            Floodgauge.label  [list] \
        ]]]]
    ttk::style layout Vertical.TFloodgauge [ttkbootstrap::_mk_layout [list \
        def_flood.v.trough [list -sticky nsew -children [list \
            def_flood.v.pbar  [list -sticky ew] \
            Floodgauge.label  [list] \
        ]]]]
    ttk::style configure Horizontal.TFloodgauge \
        -thickness [ttkbootstrap::_sp 50] -borderwidth 1 -bordercolor $c(primary) \
        -lightcolor $c(primary) -pbarrelief flat \
        -troughcolor $trough_flood \
        -background $c(primary) -foreground $fg_flood \
        -justify center -anchor center \
        -font [list [ttkbootstrap::_safeFont $c(font)] [ttkbootstrap::_sf 15]]
    ttk::style configure Vertical.TFloodgauge \
        -thickness [ttkbootstrap::_sp 50] -borderwidth 1 -bordercolor $c(primary) \
        -lightcolor $c(primary) -pbarrelief flat \
        -troughcolor $trough_flood \
        -background $c(primary) -foreground $fg_flood \
        -justify center -anchor center \
        -font [list [ttkbootstrap::_safeFont $c(font)] [ttkbootstrap::_sf 15]]
}

} ;# end namespace
