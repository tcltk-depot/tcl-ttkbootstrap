# =============================================================================
# window.tcl — ttkbootstrap Window, Toplevel, i18n, and <<ThemeChanged>>
#
# Window   — drop-in replacement for tk::Tk that auto-applies theming,
#            manages DPI scaling, and fires <<ThemeChanged>> on theme change.
#
# Toplevel — themed toplevel that inherits the current theme.
#
# i18n     — DatePickerDialog locale (day/month names in other languages).
#
# ThemeChanged event — broadcast to all widgets on theme switch.
# =============================================================================

namespace eval ttkbootstrap {

# ─────────────────────────────────────────────────────────────────────────────
# Window — wrapper around the root Tk window
#   Creates the root window if it doesn't exist, applies a theme, and
#   sets up event infrastructure.
#
# Usage:
#   ttkbootstrap::Window -themename flatly -title "My App" -size {800 600}
#
# Returns the root window path "."
# ─────────────────────────────────────────────────────────────────────────────
proc Window {args} {
    array set opts {
        -themename  flatly
        -title      {}
        -size       {}
        -minsize    {}
        -resizable  {1 1}
        -alpha      1.0
        -position   {}
        -iconphoto  {}
        -hdpi       1
    }
    array set opts $args

    # Detect DPI scale first so -size and -minsize use the correct factor
    ttkbootstrap::_updateScale

    # Configure root window
    if {$opts(-title) ne {}} {
        wm title . $opts(-title)
    }
    if {$opts(-size) ne {}} {
        lassign $opts(-size) w h
        set w [ttkbootstrap::_sp $w]
        set h [ttkbootstrap::_sp $h]
        wm geometry . "${w}x${h}"
    }
    if {$opts(-minsize) ne {}} {
        set _ms [lmap v $opts(-minsize) {ttkbootstrap::_sp $v}]
        wm minsize . {*}$_ms
    }
    wm resizable . {*}$opts(-resizable)
    # On macOS (aqua), -alpha must be set after the window is mapped
    if {[tk windowingsystem] eq "aqua"} {
        set _alpha $opts(-alpha)
        after idle [list catch [list wm attributes . -alpha $_alpha]]
    } else {
        catch { wm attributes . -alpha $opts(-alpha) }
    }

    if {$opts(-position) ne {}} {
        lassign $opts(-position) x y
        wm geometry . "+${x}+${y}"
    }

    # HiDPI auto-scaling
    if {$opts(-hdpi)} {
        ttkbootstrap::img::autoScale
    }

    # Apply theme (triggers image style generation too)
    ttkbootstrap::setTheme $opts(-themename)

    # Bind Ctrl+Shift+T to cycle themes for development convenience
    bind . <Control-Shift-T> ttkbootstrap::_cycle_theme

    return .
}

# ─────────────────────────────────────────────────────────────────────────────
# Themed Toplevel
# ─────────────────────────────────────────────────────────────────────────────
proc Toplevel {path args} {
    array set opts {
        -title    {}
        -parent   .
        -size     {}
        -modal    0
        -alpha    1.0
    }
    array set opts $args

    toplevel $path
    if {$opts(-title) ne {}} { wm title $path $opts(-title) }
    if {$opts(-size)  ne {}} {
        set _tw [ttkbootstrap::_sp [lindex $opts(-size) 0]]
        set _th [ttkbootstrap::_sp [lindex $opts(-size) 1]]
        wm geometry $path "${_tw}x${_th}"
    }
    wm transient $path $opts(-parent)
    catch { wm attributes $path -alpha $opts(-alpha) }
    $path configure -background [ttkbootstrap::getColor bg]

    if {$opts(-modal)} {
        grab $path
    }

    # Listen for theme changes
    bind $path <<ThemeChanged>> [list ttkbootstrap::_toplevel_retheme $path]

    return $path
}

proc _toplevel_retheme {path} {
    catch { $path configure -background [ttkbootstrap::getColor bg] }
}

# ─────────────────────────────────────────────────────────────────────────────
# Enhanced setTheme — fires <<ThemeChanged>> to all widgets
# ─────────────────────────────────────────────────────────────────────────────

# setTheme is enhanced by patching after load
# The patch is applied via _install_setTheme_patch called at end of this file

proc _broadcast_theme_changed {w} {
    catch { event generate $w <<ThemeChanged>> }
    foreach child [winfo children $w] {
        _broadcast_theme_changed $child
    }
}

proc _cycle_theme {} {
    variable currentTheme
    set names [ttkbootstrap::themeNames]
    set idx [lsearch -exact $names $currentTheme]
    set next [lindex $names [expr {($idx + 1) % [llength $names]}]]
    ttkbootstrap::setTheme $next
    # Show toast notification if available
    catch {
        ttkbootstrap::Toast "Theme: $next" \
            -bootstyle dark -duration 1500 -position top-center
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# DPI scaling utilities
# ─────────────────────────────────────────────────────────────────────────────
proc scale_size {size} {
    set factor [ttkbootstrap::img::size]
    if {[string is integer -strict $size] || [string is double -strict $size]} {
        return [expr {int(ceil($size * $factor))}]
    }
    set result {}
    foreach s $size {
        lappend result [expr {int(ceil($s * $factor))}]
    }
    return $result
}

# ─────────────────────────────────────────────────────────────────────────────
# i18n — DatePicker localization
# ─────────────────────────────────────────────────────────────────────────────
namespace eval i18n {

    variable _locale en
    variable _locales

    # Built-in locale data
    array set _locales {
        en {
            months {January February March April May June
                    July August September October November December}
            days   {Mo Tu We Th Fr Sa Su}
            firstweekday 0
        }
        de {
            months {Januar Februar März April Mai Juni
                    Juli August September Oktober November Dezember}
            days   {Mo Di Mi Do Fr Sa So}
            firstweekday 0
        }
        fr {
            months {Janvier Février Mars Avril Mai Juin
                    Juillet Août Septembre Octobre Novembre Décembre}
            days   {Lu Ma Me Je Ve Sa Di}
            firstweekday 0
        }
        es {
            months {Enero Febrero Marzo Abril Mayo Junio
                    Julio Agosto Septiembre Octubre Noviembre Diciembre}
            days   {Lu Ma Mi Ju Vi Sa Do}
            firstweekday 0
        }
        pt {
            months {Janeiro Fevereiro Março Abril Maio Junho
                    Julho Agosto Setembro Outubro Novembro Dezembro}
            days   {Se Te Qu Qu Se Sá Do}
            firstweekday 0
        }
        it {
            months {Gennaio Febbraio Marzo Aprile Maggio Giugno
                    Luglio Agosto Settembre Ottobre Novembre Dicembre}
            days   {Lu Ma Me Gi Ve Sa Do}
            firstweekday 0
        }
        ja {
            months {1月 2月 3月 4月 5月 6月
                    7月 8月 9月 10月 11月 12月}
            days   {月 火 水 木 金 土 日}
            firstweekday 0
        }
        zh {
            months {一月 二月 三月 四月 五月 六月
                    七月 八月 九月 十月 十一月 十二月}
            days   {一 二 三 四 五 六 日}
            firstweekday 0
        }
        ko {
            months {1월 2월 3월 4월 5월 6월
                    7월 8월 9월 10월 11월 12월}
            days   {월 화 수 목 금 토 일}
            firstweekday 0
        }
        ar {
            months {يناير فبراير مارس أبريل مايو يونيو
                    يوليو أغسطس سبتمبر أكتوبر نوفمبر ديسمبر}
            days   {ن ث ث خ ج س أ}
            firstweekday 6
        }
        ru {
            months {Январь Февраль Март Апрель Май Июнь
                    Июль Август Сентябрь Октябрь Ноябрь Декабрь}
            days   {Пн Вт Ср Чт Пт Сб Вс}
            firstweekday 0
        }
        us {
            months {January February March April May June
                    July August September October November December}
            days   {Su Mo Tu We Th Fr Sa}
            firstweekday 6
        }
    }

    proc set_locale {locale} {
        variable _locale
        variable _locales
        if {![info exists _locales($locale)]} {
            error "Unknown locale: $locale. Available: [array names _locales]"
        }
        set _locale $locale
    }

    proc get_locale {} {
        variable _locale
        return $_locale
    }

    proc month_name {n} {
        variable _locale
        variable _locales
        array set ld $_locales($_locale)
        return [lindex $ld(months) [expr {$n - 1}]]
    }

    proc day_names {} {
        variable _locale
        variable _locales
        array set ld $_locales($_locale)
        return $ld(days)
    }

    proc first_weekday {} {
        variable _locale
        variable _locales
        array set ld $_locales($_locale)
        return $ld(firstweekday)
    }

    proc register_locale {name monthsList daysList {firstweekday 0}} {
        variable _locales
        set _locales($name) [list months $monthsList days $daysList firstweekday $firstweekday]
    }

    proc available_locales {} {
        variable _locales
        return [lsort [array names _locales]]
    }
}

} ;# end namespace ttkbootstrap

# ─────────────────────────────────────────────────────────────────────────────
# Patch DatePicker to use i18n
# ─────────────────────────────────────────────────────────────────────────────
proc ttkbootstrap::_dp_render_i18n {parent} {
    set ns ::ttkbootstrap::dp::$parent
    set f  [set ${ns}::frame]
    set bs [set ${ns}::bootstyle]

    set year   [set ${ns}::year]
    set month  [set ${ns}::month]
    set fwd    [set ${ns}::firstwd]
    lassign [set ${ns}::today] ty tm td

    # Use i18n locale if available, otherwise fall back
    if {[catch {set fwd [ttkbootstrap::i18n::first_weekday]}]} {
        set fwd [set ${ns}::firstwd]
    }

    foreach child [winfo children $f] { destroy $child }

    set primary  [ttkbootstrap::getColor $bs]
    set bg       [ttkbootstrap::getColor bg]
    set fg       [ttkbootstrap::getColor fg]
    set light    [ttkbootstrap::getColor light]

    # Header
    set hdr [ttk::frame $f.hdr]
    grid $hdr -row 0 -column 0 -columnspan 7 -sticky ew -pady [ttkbootstrap::_sp2 0 4]

    # Use i18n month name if available
    if {[catch {set mlbl [ttkbootstrap::i18n::month_name $month]} err]} {
        set monthNames {January February March April May June
                        July August September October November December}
        set mlbl [lindex $monthNames [expr {$month-1}]]
    }

    set scale [ttkbootstrap::img::size]
    set prevImg [catch {ttkbootstrap::img::get cal.prev $primary $scale} pi]
    set nextImg [catch {ttkbootstrap::img::get cal.next $primary $scale} ni]

    ttk::button $hdr.prev -text "‹" \
        -style "${bs}.TButton" -padding [ttkbootstrap::_sp2 6 2] \
        -command [list ttkbootstrap::_dp_prevmonth $parent]
    ttk::button $hdr.next -text "›" \
        -style "${bs}.TButton" -padding [ttkbootstrap::_sp2 6 2] \
        -command [list ttkbootstrap::_dp_nextmonth $parent]

    ttk::label $hdr.lbl -text "$mlbl $year" \
        -font [list [ttkbootstrap::getColor font] [ttkbootstrap::_sf 12] bold] \
        -foreground $primary -anchor center

    pack $hdr.prev -side left
    pack $hdr.lbl  -side left -fill x -expand 1
    pack $hdr.next -side right

    # Day-of-week headers with i18n
    if {[catch {set dowNames [ttkbootstrap::i18n::day_names]} err]} {
        set dowNames {Mo Tu We Th Fr Sa Su}
    }
    set orderedDow {}
    for {set i 0} {$i < 7} {incr i} {
        lappend orderedDow [lindex $dowNames [expr {($fwd + $i) % 7}]]
    }
    set col 0
    foreach dow $orderedDow {
        ttk::label $f.dow$col -text $dow \
            -width 3 -anchor center \
            -foreground $fg \
            -font [list [ttkbootstrap::getColor font] [ttkbootstrap::_sf 10] bold]
        grid $f.dow$col -row 1 -column $col -padx [ttkbootstrap::_sp 1] -pady [ttkbootstrap::_sp 1]
        incr col
    }

    # Calendar grid
    set firstDow [ttkbootstrap::_date_dow $year $month 1]
    set startCol [expr {($firstDow - $fwd + 7) % 7}]
    set daysInMonth [ttkbootstrap::_date_dim $year $month]

    set row 2
    set col $startCol
    for {set day 1} {$day <= $daysInMonth} {incr day} {
        set isToday  [expr {$year==$ty && $month==$tm && $day==$td}]
        set isSel    [expr {$day == [set ${ns}::selday]}]

        if {$isSel} {
            set dbg $primary
            set dfg [ttkbootstrap::_contrastFg $primary]
            set relief solid
        } elseif {$isToday} {
            set dbg $light
            set dfg $primary
            set relief groove
        } else {
            set dbg $bg
            set dfg $fg
            set relief flat
        }

        set btn [label $f.day${day} \
            -text $day -width 2 -anchor center \
            -background $dbg -foreground $dfg \
            -relief $relief -borderwidth 1 -cursor hand2 \
            -font [list [ttkbootstrap::getColor font] [ttkbootstrap::_sf 11]]]

        bind $btn <Button-1> \
            [list ttkbootstrap::_dp_select $parent $day]
        bind $btn <Enter> [list $btn configure -background $light]
        bind $btn <Leave> [list $btn configure -background $dbg]

        grid $btn -row $row -column $col -padx [ttkbootstrap::_sp 1] -pady [ttkbootstrap::_sp 1] -sticky nsew
        incr col
        if {$col >= 7} { set col 0; incr row }
    }

    # Today button
    set foot [ttk::frame $f.foot]
    grid $foot -row [expr {$row+1}] -column 0 -columnspan 7 -sticky ew -pady [ttkbootstrap::_sp2 4 0]
    ttk::button $foot.today -text "Today" \
        -style "${bs}.Outline.TButton" -padding [ttkbootstrap::_sp2 6 2] \
        -command [list ttkbootstrap::_dp_gotoday $parent]
    pack $foot.today -side left
}

# Override the original _dp_render with the i18n-aware version
# Override _dp_render with i18n-aware version
proc ttkbootstrap::_dp_render {parent} {
    ttkbootstrap::_dp_render_i18n $parent
}

# ── Install setTheme enhancement patch ─────────────────────────────────────
# Wraps the original setTheme to also apply SVG image styles and fire events
proc ttkbootstrap::_setTheme_enhanced {name} {
    # Call original setTheme (base ttk styles)
    set result [ttkbootstrap::_setTheme_original $name]
    # Apply extra ttk styles
    catch { ttkbootstrap::_applyExtraStyles $name }
    # Apply legacy tk widget styles
    catch { ttkbootstrap::_applyLegacyStyles $name }
    # Apply SVG image styles — report errors to stderr for debugging
    if {[catch { ttkbootstrap::_applyImageStyles $name } imgErr]} {
        puts stderr "ttkbootstrap: _applyImageStyles failed: $imgErr"
    }
    # Broadcast <<ThemeChanged>> event
    catch {
        foreach w [winfo children .] { ttkbootstrap::_broadcast_theme_changed $w }
        event generate . <<ThemeChanged>>
    }
    catch { . configure -background [ttkbootstrap::getColor bg] }
    return $result
}

# Only install patch once
if {[info procs ttkbootstrap::_setTheme_original] eq ""} {
    rename ttkbootstrap::setTheme ttkbootstrap::_setTheme_original
    rename ttkbootstrap::_setTheme_enhanced ttkbootstrap::setTheme
}
