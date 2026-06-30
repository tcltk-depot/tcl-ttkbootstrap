# =============================================================================
# colorutils.tcl — Color utilities for ttkbootstrap
#
# Provides HSV/RGB conversion, color manipulation, legacy tk widget styling,
# combobox popdown styling, tooltip style, and meter subtitle label style.
#
# Mirrors Python ttkbootstrap's colorutils module and StyleBuilderTK class.
#
# Public API:
#   ttkbootstrap::Colors::hex_to_rgb hex        → {r g b} (0-255)
#   ttkbootstrap::Colors::rgb_to_hex r g b       → #rrggbb
#   ttkbootstrap::Colors::rgb_to_hsv r g b       → {h s v} (0-1 each)
#   ttkbootstrap::Colors::hsv_to_rgb h s v       → {r g b} (0-255)
#   ttkbootstrap::Colors::hex_to_hsv hex         → {h s v}
#   ttkbootstrap::Colors::hsv_to_hex h s v       → #rrggbb
#   ttkbootstrap::Colors::update_hsv hex ?-hd? ?-sd? ?-vd?  → #rrggbb
#   ttkbootstrap::Colors::make_transparent alpha fg bg       → #rrggbb
#   ttkbootstrap::Colors::brightness hex         → 0.0–1.0
# =============================================================================

namespace eval ttkbootstrap::Colors {

    # ── hex_to_rgb ───────────────────────────────────────────────────────────
    proc hex_to_rgb {hex} {
        set hex [string trimleft $hex "#"]
        if {[string length $hex] == 3} {
            # Expand shorthand #rgb → #rrggbb
            set hex "[string index $hex 0][string index $hex 0]\
[string index $hex 1][string index $hex 1]\
[string index $hex 2][string index $hex 2]"
        }
        scan [string range $hex 0 1] %x r
        scan [string range $hex 2 3] %x g
        scan [string range $hex 4 5] %x b
        return [list $r $g $b]
    }

    # ── rgb_to_hex ───────────────────────────────────────────────────────────
    proc rgb_to_hex {r g b} {
        set r [expr {int($r) < 0 ? 0 : (int($r) > 255 ? 255 : int($r))}]
        set g [expr {int($g) < 0 ? 0 : (int($g) > 255 ? 255 : int($g))}]
        set b [expr {int($b) < 0 ? 0 : (int($b) > 255 ? 255 : int($b))}]
        return [format "#%02x%02x%02x" $r $g $b]
    }

    # ── rgb_to_hsv ───────────────────────────────────────────────────────────
    # Returns h s v each in range 0.0–1.0
    proc rgb_to_hsv {r g b} {
        set r [expr {$r / 255.0}]
        set g [expr {$g / 255.0}]
        set b [expr {$b / 255.0}]

        set maxc [expr {max($r, $g, $b)}]
        set minc [expr {min($r, $g, $b)}]
        set v $maxc
        set delta [expr {$maxc - $minc}]

        if {$maxc == 0.0 || $delta == 0.0} {
            return [list 0.0 0.0 $v]
        }

        set s [expr {$delta / $maxc}]

        if {$r == $maxc} {
            set h [expr {($g - $b) / $delta}]
        } elseif {$g == $maxc} {
            set h [expr {2.0 + ($b - $r) / $delta}]
        } else {
            set h [expr {4.0 + ($r - $g) / $delta}]
        }

        set h [expr {$h / 6.0}]
        if {$h < 0.0} { set h [expr {$h + 1.0}] }
        if {$h > 1.0} { set h [expr {$h - 1.0}] }

        return [list $h $s $v]
    }

    # ── hsv_to_rgb ───────────────────────────────────────────────────────────
    # h s v each in range 0.0–1.0; returns {r g b} in range 0-255
    proc hsv_to_rgb {h s v} {
        if {$s == 0.0} {
            set c [expr {int($v * 255)}]
            return [list $c $c $c]
        }

        set h [expr {$h * 6.0}]
        set i [expr {int(floor($h))}]
        set f [expr {$h - $i}]
        set p [expr {$v * (1.0 - $s)}]
        set q [expr {$v * (1.0 - $s * $f)}]
        set t [expr {$v * (1.0 - $s * (1.0 - $f))}]

        switch -- [expr {$i % 6}] {
            0 { set r $v; set g $t; set b $p }
            1 { set r $q; set g $v; set b $p }
            2 { set r $p; set g $v; set b $t }
            3 { set r $p; set g $q; set b $v }
            4 { set r $t; set g $p; set b $v }
            5 { set r $v; set g $p; set b $q }
        }

        return [list \
            [expr {int($r * 255)}] \
            [expr {int($g * 255)}] \
            [expr {int($b * 255)}]]
    }

    # ── hex_to_hsv ───────────────────────────────────────────────────────────
    proc hex_to_hsv {hex} {
        lassign [hex_to_rgb $hex] r g b
        return [rgb_to_hsv $r $g $b]
    }

    # ── hsv_to_hex ───────────────────────────────────────────────────────────
    proc hsv_to_hex {h s v} {
        lassign [hsv_to_rgb $h $s $v] r g b
        return [rgb_to_hex $r $g $b]
    }

    # ── update_hsv ───────────────────────────────────────────────────────────
    # Adjust hue, saturation, and/or value deltas on a hex color.
    # Options: -hd delta -sd delta -vd delta   (each clamped to 0.0–1.0)
    proc update_hsv {hex args} {
        array set opts {-hd 0.0  -sd 0.0  -vd 0.0}
        array set opts $args
        lassign [hex_to_hsv $hex] h s v
        set h [expr {max(0.0, min(1.0, $h + $opts(-hd)))}]
        set s [expr {max(0.0, min(1.0, $s + $opts(-sd)))}]
        set v [expr {max(0.0, min(1.0, $v + $opts(-vd)))}]
        return [hsv_to_hex $h $s $v]
    }

    # ── make_transparent ─────────────────────────────────────────────────────
    # Blend a foreground color over a background at alpha 0.0–1.0
    proc make_transparent {alpha fg bg} {
        lassign [hex_to_rgb $fg] fr fg_ fb
        lassign [hex_to_rgb $bg] br bg_ bb
        set r [expr {int($br + ($fr - $br) * $alpha)}]
        set g [expr {int($bg_ + ($fg_ - $bg_) * $alpha)}]
        set b [expr {int($bb + ($fb - $bb) * $alpha)}]
        return [rgb_to_hex $r $g $b]
    }

    # ── brightness ───────────────────────────────────────────────────────────
    # Returns the HSV Value component (0.0–1.0) for a hex color.
    proc brightness {hex} {
        lassign [hex_to_hsv $hex] h s v
        return $v
    }

    # ── lightcolor / darkcolor (from Python's Colors.update_hsv shortcuts) ──
    # Generate a lighter/darker version using HSV, like Python does internally
    proc lighter {hex {amount 0.1}} {
        return [update_hsv $hex -vd $amount]
    }

    proc darker {hex {amount 0.1}} {
        return [update_hsv $hex -vd [expr {-$amount}]]
    }
}

# =============================================================================
# StyleBuilderTK — Legacy tk (non-ttk) widget styles
#
# Python ttkbootstrap also styles the classic tk widgets so they fit the theme.
# We mirror that here for tk::Button, tk::Label, tk::Entry, tk::Listbox, etc.
# =============================================================================

namespace eval ttkbootstrap {

proc _applyLegacyStyles {themeName} {
    variable themes
    array set c $themes($themeName)

    # ── tk::Button ────────────────────────────────────────────────────────────
    option add *Button.background        $c(primary)       startupFile
    option add *Button.foreground        [_contrastFg $c(primary)] startupFile
    option add *Button.activeBackground  [_darken $c(primary) 15] startupFile
    option add *Button.activeForeground  [_contrastFg $c(primary)] startupFile
    option add *Button.relief            flat              startupFile
    option add *Button.borderWidth       [ttkbootstrap::_sp 1] startupFile
    option add *Button.highlightThickness 0               startupFile
    option add *Button.padX              [ttkbootstrap::_sp 10] startupFile
    option add *Button.padY              [ttkbootstrap::_sp 5]  startupFile
    option add *Button.cursor            hand2            startupFile

    # ── tk::Label ─────────────────────────────────────────────────────────────
    option add *Label.background         $c(bg)           startupFile
    option add *Label.foreground         $c(fg)           startupFile
    option add *Label.font [list [_safeFont $c(font)] [ttkbootstrap::_sf 12]] startupFile

    # ── tk::Entry ─────────────────────────────────────────────────────────────
    option add *Entry.background         $c(inputbg)      startupFile
    option add *Entry.foreground         $c(inputfg)      startupFile
    option add *Entry.insertBackground   $c(inputfg)      startupFile
    option add *Entry.selectBackground   $c(selectbg)     startupFile
    option add *Entry.selectForeground   $c(selectfg)     startupFile
    option add *Entry.highlightColor     $c(primary)      startupFile
    option add *Entry.highlightThickness 1                startupFile
    option add *Entry.relief             flat             startupFile
    option add *Entry.font [list [_safeFont $c(font)] [ttkbootstrap::_sf 12]] startupFile

    # ── tk::Text ──────────────────────────────────────────────────────────────
    option add *Text.background          $c(inputbg)      startupFile
    option add *Text.foreground          $c(inputfg)      startupFile
    option add *Text.insertBackground    $c(inputfg)      startupFile
    option add *Text.selectBackground    $c(selectbg)     startupFile
    option add *Text.selectForeground    $c(selectfg)     startupFile
    option add *Text.highlightColor      $c(primary)      startupFile
    option add *Text.highlightThickness  1                startupFile
    option add *Text.relief              flat             startupFile
    option add *Text.font [list [_safeFont $c(font)] [ttkbootstrap::_sf 12]] startupFile
    option add *Text.borderWidth         1               startupFile

    # ── tk::Listbox ───────────────────────────────────────────────────────────
    option add *Listbox.background       $c(inputbg)      startupFile
    option add *Listbox.foreground       $c(inputfg)      startupFile
    option add *Listbox.selectBackground $c(selectbg)     startupFile
    option add *Listbox.selectForeground $c(selectfg)     startupFile
    option add *Listbox.highlightColor   $c(primary)      startupFile
    option add *Listbox.highlightThickness 1              startupFile
    option add *Listbox.relief           flat             startupFile
    option add *Listbox.font [list [_safeFont $c(font)] [ttkbootstrap::_sf 12]] startupFile
    option add *Listbox.borderWidth      1               startupFile

    # ── tk::Canvas ────────────────────────────────────────────────────────────
    option add *Canvas.background        $c(bg)           startupFile
    option add *Canvas.highlightThickness 0               startupFile

    # ── tk::Frame ─────────────────────────────────────────────────────────────
    option add *Frame.background         $c(bg)           startupFile

    # ── tk::Menu / tk::Menubutton ─────────────────────────────────────────────
    option add *Menu.background          $c(bg)           startupFile
    option add *Menu.foreground          $c(fg)           startupFile
    option add *Menu.activeBackground    $c(selectbg)     startupFile
    option add *Menu.activeForeground    $c(selectfg)     startupFile
    option add *Menu.selectColor         $c(primary)      startupFile
    option add *Menu.relief              flat             startupFile
    option add *Menu.borderWidth         1               startupFile
    option add *Menu.font [list [_safeFont $c(font)] [ttkbootstrap::_sf 12]] startupFile
    option add *Menubutton.background    $c(bg)           startupFile
    option add *Menubutton.foreground    $c(fg)           startupFile
    option add *Menubutton.activeBackground $c(selectbg)  startupFile
    option add *Menubutton.activeForeground $c(selectfg)  startupFile
    option add *Menubutton.relief        flat             startupFile

    # ── tk::Scrollbar ─────────────────────────────────────────────────────────
    option add *Scrollbar.background     $c(secondary)    startupFile
    option add *Scrollbar.troughColor    $c(light)        startupFile
    option add *Scrollbar.activeBackground [_lighten $c(secondary) 15] startupFile
    option add *Scrollbar.relief         flat             startupFile
    option add *Scrollbar.borderWidth    0               startupFile

    # ── Checkbutton / Radiobutton ─────────────────────────────────────────────
    option add *Checkbutton.background   $c(bg)           startupFile
    option add *Checkbutton.foreground   $c(fg)           startupFile
    option add *Checkbutton.activeBackground $c(bg)       startupFile
    option add *Checkbutton.activeForeground $c(fg)       startupFile
    option add *Checkbutton.selectColor  $c(primary)      startupFile
    option add *Checkbutton.relief       flat             startupFile
    option add *Radiobutton.background   $c(bg)           startupFile
    option add *Radiobutton.foreground   $c(fg)           startupFile
    option add *Radiobutton.activeBackground $c(bg)       startupFile
    option add *Radiobutton.activeForeground $c(fg)       startupFile
    option add *Radiobutton.selectColor  $c(primary)      startupFile
    option add *Radiobutton.relief       flat             startupFile

    # ── tk::Scale ─────────────────────────────────────────────────────────────
    option add *Scale.background         $c(bg)           startupFile
    option add *Scale.foreground         $c(fg)           startupFile
    option add *Scale.troughColor        $c(light)        startupFile
    option add *Scale.activeBackground   $c(primary)      startupFile
    option add *Scale.highlightThickness 0               startupFile

    # ── Spinbox ───────────────────────────────────────────────────────────────
    option add *Spinbox.background       $c(inputbg)      startupFile
    option add *Spinbox.foreground       $c(inputfg)      startupFile
    option add *Spinbox.selectBackground $c(selectbg)     startupFile
    option add *Spinbox.selectForeground $c(selectfg)     startupFile
    option add *Spinbox.insertBackground $c(inputfg)      startupFile
    option add *Spinbox.relief           flat             startupFile
    option add *Spinbox.font [list [_safeFont $c(font)] [ttkbootstrap::_sf 12]] startupFile

    # ── Toplevel / root background ────────────────────────────────────────────
    option add *background               $c(bg)           startupFile
    option add *foreground               $c(fg)           startupFile
    option add *font                     [_safeFont $c(font)] startupFile
}

# =============================================================================
# Extra TTK styles not covered in the main setTheme proc
# =============================================================================

proc _applyExtraStyles {themeName} {
    variable themes
    array set c $themes($themeName)

    set isDark [expr {$c(type) eq "dark"}]

    # ── Combobox popdown (dropdown listbox) ───────────────────────────────────
    # Style the listbox that appears when a Combobox is opened.
    # Use 'interactive' priority so options apply to existing widgets too.
    catch {
        # Ensure the combobox field text has enough contrast
        # For morph and similar themes with grey inputfg on grey inputbg
        set combofg $c(inputfg)
        set combobg $c(inputbg)

        option add *TCombobox*Listbox.background     $combobg     interactive
        option add *TCombobox*Listbox.foreground     $combofg     interactive
        option add *TCombobox*Listbox.selectBackground $c(selectbg) interactive
        option add *TCombobox*Listbox.selectForeground $c(selectfg) interactive
        option add *TCombobox*Listbox.font [list [_safeFont $c(font)] [ttkbootstrap::_sf 12]] interactive
        option add *TCombobox*Listbox.relief         flat         interactive
        option add *TCombobox*Listbox.borderWidth    1            interactive

        # Also update any existing combobox popdown listboxes
        foreach w [winfo children .] {
            catch {
                if {[winfo class $w] eq "Toplevel"} {
                    foreach lb [winfo children $w] {
                        if {[winfo class $lb] eq "Frame"} {
                            foreach item [winfo children $lb] {
                                if {[winfo class $item] eq "Listbox"} {
                                    $item configure \
                                        -background $combobg \
                                        -foreground $combofg \
                                        -selectbackground $c(selectbg) \
                                        -selectforeground $c(selectfg)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    # ── Tooltip TLabel style ──────────────────────────────────────────────────
    # Used by the Tooltip widget and any other popup tooltip
    if {$isDark} {
        set ttbg "#3a3a3a"
        set ttfg "#f5f5f5"
        set ttbd "#555555"
    } else {
        set ttbg "#fffddd"
        set ttfg "#333333"
        set ttbd "#aaaaaa"
    }
    catch {
        ttk::style configure tooltip.TLabel \
            -background  $ttbg \
            -foreground  $ttfg \
            -bordercolor $ttbd \
            -borderwidth 1 \
            -darkcolor   $ttbg \
            -lightcolor  $ttbg \
            -relief      raised \
            -padding     [ttkbootstrap::_fontPad 6]
    }

    # ── Meter label styles ─────────────────────────────────────────────────────
    # meter.TLabel  — the large value/text label in the center of the meter
    # metersubtxt.TLabel — smaller subtitle below the value
    foreach {color hex} [list \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger)] {

        set fg [_contrastFg $hex]

        # Meter center value label
        catch {
            ttk::style configure "meter.${color}.TLabel" \
                -background $c(bg) \
                -foreground $hex \
                -font [list [_safeFont $c(font)] [ttkbootstrap::_sf 20] bold]
        }

        # Meter subtitle/subtext label
        catch {
            ttk::style configure "metersubtxt.${color}.TLabel" \
                -background $c(bg) \
                -foreground $c(secondary) \
                -font [list [_safeFont $c(font)] [ttkbootstrap::_sf 12]]
        }
    }

    # Default meter styles (no color prefix)
    catch {
        ttk::style configure "meter.TLabel" \
            -background $c(bg) \
            -foreground $c(primary) \
            -font [list [_safeFont $c(font)] [ttkbootstrap::_sf 20] bold]
    }
    catch {
        ttk::style configure "metersubtxt.TLabel" \
            -background $c(bg) \
            -foreground $c(secondary) \
            -font [list [_safeFont $c(font)] [ttkbootstrap::_sf 12]]
    }

    # ── Table.Treeview — raised-border style for Tableview ────────────────────
    set borderCol [expr {$isDark ? $c(selectbg) : $c(border)}]

    ttk::style configure "Table.Treeview" \
        -background     $c(inputbg) \
        -foreground     $c(inputfg) \
        -fieldbackground $c(inputbg) \
        -bordercolor    $borderCol \
        -borderwidth    2 \
        -rowheight      [expr {[font metrics [list [ttkbootstrap::_safeFont $c(font)] [ttkbootstrap::_sf 12]] -linespace] + [ttkbootstrap::_sp 10]}] \
        -relief         raised
    ttk::style map "Table.Treeview" \
        -background [list selected $c(selectbg) disabled $c(light)] \
        -foreground [list selected $c(selectfg) disabled $c(secondary)]

    ttk::style configure "Table.Treeview.Heading" \
        -background  $c(inputbg) \
        -foreground  $c(inputfg) \
        -relief      raised \
        -borderwidth 1 \
        -bordercolor $borderCol \
        -padding     [ttkbootstrap::_sp2 8 5]
    ttk::style map "Table.Treeview.Heading" \
        -background [list active [expr {$isDark ? \
            [_lighten $c(inputbg) 10] : [_darken $c(inputbg) 8]}]]

    # Colored Table.Treeview variants
    foreach {color hex} [list \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger)] {

        set hfg [_contrastFg $hex]
        set hbg [_darken $hex 10]

        ttk::style configure "${color}.Table.Treeview.Heading" \
            -background  $hex \
            -foreground  $hfg \
            -relief      raised \
            -borderwidth 1 \
            -bordercolor $hex \
            -padding     [ttkbootstrap::_sp2 8 5]
        ttk::style map "${color}.Table.Treeview.Heading" \
            -background [list active $hbg] \
            -foreground [list active $hfg]

        ttk::style configure "${color}.Table.Treeview" \
            -background     $c(inputbg) \
            -foreground     $c(inputfg) \
            -fieldbackground $c(inputbg) \
            -bordercolor    $hex \
            -borderwidth    2 \
            -rowheight      [expr {[font metrics [list [ttkbootstrap::_safeFont $c(font)] [ttkbootstrap::_sf 12]] -linespace] + [ttkbootstrap::_sp 10]}] \
            -relief         raised
        ttk::style map "${color}.Table.Treeview" \
            -background [list selected $c(selectbg)] \
            -foreground [list selected $c(selectfg)]
    }

    # ── symbol.Link.TButton — for Tableview sort header links ─────────────────
    catch {
        ttk::style configure "symbol.Link.TButton" \
            -font [list [_safeFont $c(font)] [ttkbootstrap::_sf 15]] \
            -background $c(bg) \
            -foreground $c(secondary) \
            -relief flat \
            -padding [ttkbootstrap::_sp 2] \
            -borderwidth 0
        ttk::style map "symbol.Link.TButton" \
            -foreground [list active $c(primary)]
    }

    # ── Entry TLabel style ─────────────────────────────────────────────────────
    # Per-color TEntry styles (colored focus ring)
    foreach {color hex} [list \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger)] {

        ttk::style configure "${color}.TEntry" \
            -fieldbackground $c(inputbg) \
            -foreground      $c(inputfg) \
            -bordercolor     $c(border) \
            -insertcolor     $c(inputfg) \
            -padding         [ttkbootstrap::_fontPad 6] \
            -relief          flat
        ttk::style map "${color}.TEntry" \
            -fieldbackground [list focus $c(inputbg) disabled $c(light)] \
            -bordercolor     [list focus $hex disabled $c(border)] \
            -foreground      [list disabled $c(secondary)]

        ttk::style configure "${color}.TSpinbox" \
            -fieldbackground $c(inputbg) \
            -foreground      $c(inputfg) \
            -bordercolor     $c(border) \
            -arrowcolor      $c(secondary) \
            -padding         [ttkbootstrap::_fontPad 6] \
            -relief          flat
        ttk::style map "${color}.TSpinbox" \
            -fieldbackground [list focus $c(inputbg) disabled $c(light)] \
            -bordercolor     [list focus $hex disabled $c(border)]

        ttk::style configure "${color}.TCombobox" \
            -fieldbackground $c(inputbg) \
            -foreground      $c(inputfg) \
            -bordercolor     $c(border) \
            -arrowcolor      $c(secondary) \
            -padding         [ttkbootstrap::_fontPad 6] \
            -relief          flat
        ttk::style map "${color}.TCombobox" \
            -fieldbackground [list focus $c(inputbg) disabled $c(light)] \
            -bordercolor     [list focus $hex disabled $c(border)] \
            -arrowcolor      [list focus $hex]
    }

    # ── Colored Treeview variants ─────────────────────────────────────────────
    foreach {color hex} [list \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger)] {

        set hfg [_contrastFg $hex]

        ttk::style configure "${color}.Treeview.Heading" \
            -background  $hex \
            -foreground  $hfg \
            -relief      flat \
            -padding     [ttkbootstrap::_fontPad 8]
        ttk::style map "${color}.Treeview.Heading" \
            -background [list active [_darken $hex 10]] \
            -foreground [list active $hfg]

        ttk::style configure "${color}.Treeview" \
            -background  $c(inputbg) \
            -foreground  $c(inputfg) \
            -fieldbackground $c(inputbg) \
            -bordercolor $hex \
            -rowheight   [expr {[font metrics [list [ttkbootstrap::_safeFont $c(font)] [ttkbootstrap::_sf 12]] -linespace] + [ttkbootstrap::_sp 10]}]
        ttk::style map "${color}.Treeview" \
            -background [list selected $c(selectbg)] \
            -foreground [list selected $c(selectfg)]
    }

    # ── Colored TNotebook variants ─────────────────────────────────────────────
    foreach {color hex} [list \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger)] {

        set tfg [_contrastFg $hex]

        ttk::style configure "${color}.TNotebook" \
            -background $c(light) \
            -bordercolor $hex \
            -tabmargins {0 0 0 0}
        ttk::style configure "${color}.TNotebook.Tab" \
            -background $c(light) \
            -foreground $c(secondary) \
            -padding    [ttkbootstrap::_fontPad 12] \
            -bordercolor $hex
        ttk::style map "${color}.TNotebook.Tab" \
            -background [list selected $c(bg) active $c(bg)] \
            -foreground [list selected $hex active $hex]
    }

    # ── Striped Treeview (alternate row colors) ────────────────────────────────
    # Register tag styles that Tableview uses for row striping
    # (Applied per-widget via .tag configure, not here)

    # ── Disabled state for TButton ─────────────────────────────────────────────
    # Ensure disabled buttons are visually muted across all color styles
    set disabledBg [expr {$isDark ? $c(selectbg) : $c(border)}]
    set disabledFg [expr {$isDark ? $c(secondary) : $c(secondary)}]

    foreach {color hex} [list \
        primary $c(primary) secondary $c(secondary) \
        success $c(success) info $c(info) \
        warning $c(warning) danger $c(danger) \
        light $c(light) dark $c(dark)] {

        # Add disabled state to existing map
        # (don't overwrite the full map, just add disabled entries)
        set existing [ttk::style map "${color}.TButton" -background]
        # Check if disabled already handled
        if {[lsearch $existing disabled] < 0} {
            lappend existing disabled $disabledBg
            ttk::style map "${color}.TButton" -background $existing
        }
    }
}

} ;# end namespace ttkbootstrap
