# =============================================================================
# dateentry.tcl — ttkbootstrap DateEntry + DatePickerDialog widgets
#
# DateEntry: an Entry with a calendar popup button.
# DatePickerDialog: a standalone popup calendar.
#
# Usage:
#   ttkbootstrap::DateEntry .de \
#       -bootstyle primary \
#       -dateformat "%Y-%m-%d" \
#       -firstweekday 0
#
#   set date [ttkbootstrap::DatePickerDialog .root]
#
# Options (DateEntry):
#   -bootstyle    color keyword            (default primary)
#   -dateformat   strftime format string   (default %Y-%m-%d)
#   -firstweekday 0=Mon .. 6=Sun          (default 0)
#   -textvariable linked variable
#   -width        entry width              (default 12)
#   -command      script called on select
# =============================================================================

namespace eval ttkbootstrap {

# ─────────────────────────────────────────────────────────────────────────────
# DateEntry
# ─────────────────────────────────────────────────────────────────────────────
proc DateEntry {w args} {
    array set opts {
        -bootstyle    primary
        -dateformat   {%Y-%m-%d}
        -firstweekday 0
        -textvariable {}
        -width        12
        -command      {}
        -state        normal
    }
    array set opts $args

    set ns ::ttkbootstrap::dateentry::$w
    namespace eval $ns {}
    set ${ns}::opts  [array get opts]
    set ${ns}::popupOpen 0

    # Frame holding entry + button
    ttk::frame $w

    # Internal textvariable
    if {$opts(-textvariable) ne {}} {
        set ${ns}::textvar $opts(-textvariable)
    } else {
        set ${ns}::textvar ${ns}::entrytext
        set ${ns}::entrytext {}
    }

    set entry [ttk::entry $w.entry \
        -textvariable [set ${ns}::textvar] \
        -width $opts(-width) \
        -style "$opts(-bootstyle).TEntry"]

    # Calendar button — SVG calendar icon, scales with DPI
    set _fn_tmp [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set _fs_tmp [ttkbootstrap::_sf 12]
    set _ls_tmp [font metrics [list $_fn_tmp $_fs_tmp] -linespace]
    set _icon_sz [expr {$_ls_tmp + [ttkbootstrap::_sp 4]}]
    set _iscale [expr {$_icon_sz / 22.0}]
    set _hex [ttkbootstrap::getColor $opts(-bootstyle)]
    if {$_hex eq ""} { set _hex [ttkbootstrap::getColor primary] }
    set _cal_svg "<svg xmlns='http://www.w3.org/2000/svg' width='21' height='22'>"
    append _cal_svg "<rect x='1' y='5' width='19' height='16' rx='2' ry='2' fill='none' stroke='white' stroke-width='1.5'/>"
    append _cal_svg "<line x1='1' y1='10' x2='20' y2='10' stroke='white' stroke-width='1.2'/>"
    append _cal_svg "<line x1='7' y1='2' x2='7' y2='7' stroke='white' stroke-width='2' stroke-linecap='round'/>"
    append _cal_svg "<line x1='14' y1='2' x2='14' y2='7' stroke='white' stroke-width='2' stroke-linecap='round'/>"
    append _cal_svg "<rect x='4' y='12' width='2' height='2' rx='0.5' fill='white'/>"
    append _cal_svg "<rect x='8' y='12' width='2' height='2' rx='0.5' fill='white'/>"
    append _cal_svg "<rect x='12' y='12' width='2' height='2' rx='0.5' fill='white'/>"
    append _cal_svg "<rect x='16' y='12' width='2' height='2' rx='0.5' fill='white'/>"
    append _cal_svg "<rect x='4' y='15' width='2' height='2' rx='0.5' fill='white'/>"
    append _cal_svg "<rect x='8' y='15' width='2' height='2' rx='0.5' fill='white'/>"
    append _cal_svg "<rect x='12' y='15' width='2' height='2' rx='0.5' fill='white'/>"
    append _cal_svg "<rect x='16' y='15' width='2' height='2' rx='0.5' fill='white'/>"
    append _cal_svg "<rect x='4' y='18' width='2' height='2' rx='0.5' fill='white'/>"
    append _cal_svg "<rect x='8' y='18' width='2' height='2' rx='0.5' fill='white'/>"
    append _cal_svg "</svg>"
    set _cal_img [image create photo _ttkbs_cal_icon_$w -data $_cal_svg -format [list svg -scale $_iscale]]

    set btn [ttk::button $w.btn \
        -image $_cal_img \
        -style "$opts(-bootstyle).TButton" \
        -padding [ttkbootstrap::_sp2 4 2] \
        -command [list ttkbootstrap::_de_popup $w]]

    pack $entry -side left -fill x -expand 1
    pack $btn   -side left -padx [ttkbootstrap::_sp2 2 0]

    set ${ns}::entry $entry

    interp alias {} ${w}.get       {} ttkbootstrap::_de_get $w
    interp alias {} ${w}.set       {} ttkbootstrap::_de_set $w $opts(-dateformat)
    interp alias {} ${w}.configure {} ttkbootstrap::_de_configure $w

    return $w
}

proc _de_popup {w} {
    set ns ::ttkbootstrap::dateentry::$w
    array set opts [set ${ns}::opts]

    # Get current date from entry if parseable, else today
    set curtext [set [set ${ns}::textvar]]
    set today [_date_today]

    set popup [toplevel ${w}.__datepicker \
        -relief solid -borderwidth 1]
    wm overrideredirect $popup 1
    catch { wm attributes $popup -topmost 1 }
    wm withdraw $popup

    # Build first so we know the popup height
    _dp_build $popup $today $opts(-firstweekday) \
        [list ttkbootstrap::_de_picked $w $popup] \
        $opts(-bootstyle)

    # Position above the date entry field
    update idletasks
    set ex  [winfo rootx $w]
    set ph  [winfo reqheight $popup]
    set pw  [winfo reqwidth  $popup]
    set ey  [expr {[winfo rooty $w] - $ph}]
    # Clamp to screen edges
    if {$ey < 0} { set ey 0 }
    set sw [winfo screenwidth  $popup]
    if {[expr {$ex + $pw}] > $sw} { set ex [expr {$sw - $pw}] }
    if {$ex < 0} { set ex 0 }
    wm geometry $popup "+${ex}+${ey}"

    wm deiconify $popup
    raise $popup
    # On macOS, force the popup above the main window
    catch { wm attributes $popup -topmost 1 }
    focus $popup

    # Make the popup draggable — clamped within the main application window.
    # Drag is only bound on non-interactive widgets (frames, labels) so that
    # button clicks are not intercepted by the drag handler.
    set mainwin [winfo toplevel $w]
    set dragcmd_press [list apply {{pop x y} {
        if {![winfo exists $pop]} return
        set ::_dp_drag_x [expr {$x - [winfo rootx $pop]}]
        set ::_dp_drag_y [expr {$y - [winfo rooty $pop]}]
    }} $popup %X %Y]
    set dragcmd_motion [list apply {{pop mainwin x y} {
        if {![winfo exists $pop]} return
        if {![info exists ::_dp_drag_x]} return
        set nx [expr {$x - $::_dp_drag_x}]
        set ny [expr {$y - $::_dp_drag_y}]
        set mw_x  [winfo rootx  $mainwin]
        set mw_y  [winfo rooty  $mainwin]
        set mw_x2 [expr {$mw_x + [winfo width  $mainwin]}]
        set mw_y2 [expr {$mw_y + [winfo height $mainwin]}]
        set pw    [winfo width  $pop]
        set ph    [winfo height $pop]
        if {$nx < $mw_x}         { set nx $mw_x }
        if {$ny < $mw_y}         { set ny $mw_y }
        if {$nx + $pw > $mw_x2} { set nx [expr {$mw_x2 - $pw}] }
        if {$ny + $ph > $mw_y2} { set ny [expr {$mw_y2 - $ph}] }
        wm geometry $pop "+${nx}+${ny}"
    }} $popup $mainwin %X %Y]

    # Bind drag to popup toplevel and all non-button descendants
    bind $popup <ButtonPress-1> $dragcmd_press
    bind $popup <B1-Motion>     $dragcmd_motion
    foreach child [ttkbootstrap::_all_descendants $popup] {
        set cls [winfo class $child]
        # Skip buttons, labels (day cells), and canvas so their <Button-1>
        # bindings are not overwritten by the drag handler.
        # Label widgets are the day cells built during _dp_build; new labels
        # created after navigation escape this loop, which is why other months
        # appeared to work while the current month did not.
        if {$cls in {TButton Button TCheckbutton TRadiobutton Label TLabel Canvas}} continue
        bind $child <ButtonPress-1> $dragcmd_press
        bind $child <B1-Motion>     $dragcmd_motion
    }

    # Close when focus moves outside the popup entirely.
    # Use 'after idle' so the new focus target has time to settle — clicking
    # a nav button inside the popup briefly defocuses the toplevel, so we
    # must check that the new focus widget is NOT a descendant of $popup.
    bind $popup <FocusOut> [list after idle \
        [list ttkbootstrap::_de_focusout $w $popup]]
}

proc _de_focusout {w popup} {
    # Only close if the popup still exists and focus has moved truly outside it
    if {![winfo exists $popup]} return
    set focus [focus]
    # Focus is empty or on a widget that no longer exists — nav rebuild in progress
    if {$focus eq ""} return
    if {![winfo exists $focus]} return
    # Focus is inside the popup — keep it open
    if {[string match "${popup}*" $focus] || $focus eq $popup} return
    ttkbootstrap::_de_close $w $popup
}

proc _de_picked {w popup dateList} {
    set ns ::ttkbootstrap::dateentry::$w
    array set opts [set ${ns}::opts]

    lassign $dateList year month day
    set formatted [_date_format $year $month $day $opts(-dateformat)]
    set [set ${ns}::textvar] $formatted

    _de_close $w $popup
    if {$opts(-command) ne {}} { uplevel #0 $opts(-command) }
}

proc _de_close {w popup} {
    catch { destroy $popup }
}

proc _de_get {w} {
    set ns ::ttkbootstrap::dateentry::$w
    return [set [set ${ns}::textvar]]
}

proc _de_set {w fmt val} {
    set ns ::ttkbootstrap::dateentry::$w
    set [set ${ns}::textvar] $val
}

proc _de_configure {w args} {
    set ns ::ttkbootstrap::dateentry::$w
    array set opts [set ${ns}::opts]
    array set opts $args
    set ${ns}::opts [array get opts]
}

# ─────────────────────────────────────────────────────────────────────────────
# DatePickerDialog — standalone popup, returns selected date string
# ─────────────────────────────────────────────────────────────────────────────
proc DatePickerDialog {{parent .} {bootstyle primary} {firstweekday 0}} {
    set d [toplevel ${parent}.__dpd_[clock milliseconds] \
        -relief solid -borderwidth 1]
    wm title $d "Select Date"
    wm resizable $d 0 0

    set result {}
    set today [_date_today]

    _dp_build $d $today $firstweekday \
        [list ttkbootstrap::_dpd_done $d result] \
        $bootstyle

    # Center on parent
    update idletasks
    set px [expr {[winfo rootx $parent] + [winfo width $parent]/2 - [winfo reqwidth $d]/2}]
    set py [expr {[winfo rooty $parent] + [winfo height $parent]/2 - [winfo reqheight $d]/2}]
    wm geometry $d "+${px}+${py}"

    grab $d
    tkwait window $d
    return $result
}

proc _dpd_done {dlg resultVar dateList} {
    upvar #0 $resultVar r
    lassign $dateList year month day
    set r [_date_format $year $month $day "%Y-%m-%d"]
    destroy $dlg
}

# ─────────────────────────────────────────────────────────────────────────────
# _dp_build — build the calendar grid inside a frame/toplevel
# ─────────────────────────────────────────────────────────────────────────────
proc _dp_build {parent today firstweekday callback bootstyle} {
    set ns ::ttkbootstrap::dp::$parent
    namespace eval $ns {}

    lassign $today tyear tmonth tday
    set ${ns}::year      $tyear
    set ${ns}::month     $tmonth
    set ${ns}::today     $today
    set ${ns}::firstwd   $firstweekday
    set ${ns}::callback  $callback
    set ${ns}::bootstyle $bootstyle
    set ${ns}::selday    $tday

    set f [ttk::frame $parent.dpf -padding [ttkbootstrap::_sp 6]]
    pack $f -fill both -expand 1
    set ${ns}::frame $f

    set bs $bootstyle
    set primary [ttkbootstrap::getColor $bs]
    set bg      [ttkbootstrap::getColor bg]
    set fg      [ttkbootstrap::getColor fg]

    # ── Header: prev button, month/year label, next button ───────────────
    set hdr [ttk::frame $f.hdr]
    grid $hdr -row 0 -column 0 -columnspan 7 -sticky ew -pady [ttkbootstrap::_sp2 0 4]

    ttk::button $hdr.prev -text "‹" \
        -style "${bs}.TButton" -padding [ttkbootstrap::_sp2 6 2] \
        -command [list ttkbootstrap::_dp_nav $parent prev]
    ttk::button $hdr.next -text "›" \
        -style "${bs}.TButton" -padding [ttkbootstrap::_sp2 6 2] \
        -command [list ttkbootstrap::_dp_nav $parent next]
    ttk::label $hdr.lbl \
        -font [list [ttkbootstrap::getColor font] [ttkbootstrap::_sf 12] bold] \
        -foreground $primary -anchor center
    pack $hdr.prev -side left
    pack $hdr.lbl  -side left -fill x -expand 1
    pack $hdr.next -side right

    # ── Day-of-week header labels ─────────────────────────────────────────
    set dowNames {Mo Tu We Th Fr Sa Su}
    for {set i 0} {$i < 7} {incr i} {
        set dow [lindex $dowNames [expr {($firstweekday + $i) % 7}]]
        ttk::label $f.dow$i -text $dow \
            -width 3 -anchor center \
            -foreground $fg \
            -font [list [ttkbootstrap::getColor font] [ttkbootstrap::_sf 10] bold]
        grid $f.dow$i -row 1 -column $i -padx [ttkbootstrap::_sp 1] -pady [ttkbootstrap::_sp 1]
    }

    # ── Single canvas for all day cells — items pre-created, never deleted ──
    # Cell size 30x26 at 96dpi — scaled to current DPI
    set cw [ttkbootstrap::_sp 30]
    set ch [ttkbootstrap::_sp 26]
    set c [canvas $f.daygrid \
        -width  [expr {7 * $cw}] \
        -height [expr {6 * $ch}] \
        -background $bg \
        -highlightthickness 0 -borderwidth 0]
    grid $c -row 2 -column 0 -columnspan 7 -padx [ttkbootstrap::_sp 1] -pady [ttkbootstrap::_sp 1]
    set ${ns}::canvas $c
    set ${ns}::cellw  $cw
    set ${ns}::cellh  $ch

    # Pre-create all 42 rect+text pairs off-screen — reused on every render
    for {set i 0} {$i < 42} {incr i} {
        $c create rectangle -200 -200 -190 -190 \
            -fill $bg -outline $bg -tags [list day day$i rect$i]
        $c create text -195 -195 -text "" \
            -anchor center -tags [list day day$i txt$i]
    }

    # ── Footer ────────────────────────────────────────────────────────────
    set foot [ttk::frame $f.foot]
    grid $foot -row 3 -column 0 -columnspan 7 -sticky ew -pady [ttkbootstrap::_sp2 4 0]
    ttk::button $foot.today -text "Today" \
        -style "${bs}.Outline.TButton" -padding [ttkbootstrap::_sp2 6 2] \
        -command [list ttkbootstrap::_dp_nav $parent today]
    pack $foot.today -side left

    _dp_render $parent
}

proc _dp_render {parent} {
    set ns ::ttkbootstrap::dp::$parent
    set f   [set ${ns}::frame]
    set bs  [set ${ns}::bootstyle]
    set c   [set ${ns}::canvas]
    set cw  [set ${ns}::cellw]
    set ch  [set ${ns}::cellh]

    set year   [set ${ns}::year]
    set month  [set ${ns}::month]
    set fwd    [set ${ns}::firstwd]
    set selday [set ${ns}::selday]
    lassign [set ${ns}::today] ty tm td

    set primary [ttkbootstrap::getColor $bs]
    set bg      [ttkbootstrap::getColor bg]
    set fg      [ttkbootstrap::getColor fg]
    set light   [ttkbootstrap::getColor light]
    set font    [list [ttkbootstrap::getColor font] 9]

    set monthNames {January February March April May June
                    July August September October November December}
    $f.hdr.lbl configure -text "[lindex $monthNames [expr {$month-1}]] $year"

    set firstDow    [_date_dow $year $month 1]
    set startCol    [expr {($firstDow - $fwd + 7) % 7}]
    set daysInMonth [_date_dim $year $month]

    # Reuse all 42 pre-created rect+text pairs — move off-screen if unused.
    # Never deletes items so the canvas never shows a blank frame.
    for {set i 0} {$i < 42} {incr i} {
        set day [expr {$i - $startCol + 1}]

        if {$day < 1 || $day > $daysInMonth} {
            # Park off-screen
            $c coords rect$i -200 -200 -190 -190
            $c coords txt$i  -195 -195
            $c itemconfigure txt$i -text ""
            $c bind day$i <Button-1> {}
            $c bind day$i <Enter>    {}
            $c bind day$i <Leave>    {}
        } else {
            set col [expr {$i % 7}]
            set row [expr {$i / 7}]
            set _gap [ttkbootstrap::_sp 1]
            set _inset [ttkbootstrap::_sp 3]
            set x1  [expr {$col * $cw + $_gap}]
            set y1  [expr {$row * $ch + $_gap}]
            set x2  [expr {$x1 + $cw - $_inset}]
            set y2  [expr {$y1 + $ch - $_inset}]
            set cx  [expr {($x1 + $x2) / 2}]
            set cy  [expr {($y1 + $y2) / 2}]

            set isToday [expr {$year==$ty && $month==$tm && $day==$td}]
            set isSel   [expr {$day == $selday}]

            if {$isSel} {
                set dbg $primary
                set dfg [ttkbootstrap::_contrastFg $primary]
                set outline $primary
            } elseif {$isToday} {
                set dbg $light
                set dfg $primary
                set outline $primary
            } else {
                set dbg $bg
                set dfg $fg
                set outline $bg
            }

            $c coords rect$i $x1 $y1 $x2 $y2
            $c coords txt$i  $cx $cy
            $c itemconfigure rect$i -fill $dbg -outline $outline
            $c itemconfigure txt$i  -text $day -fill $dfg \
                -font [list [ttkbootstrap::getColor font] 9]

            set restore $dbg
            $c bind day$i <Enter> \
                [list $c itemconfigure rect$i -fill $light]
            $c bind day$i <Leave> \
                [list $c itemconfigure rect$i -fill $restore]
            $c bind day$i <Button-1> \
                [list ttkbootstrap::_dp_select $parent $day]
        }
    }
}

proc _dp_select {parent day} {
    set ns ::ttkbootstrap::dp::$parent
    set ${ns}::selday $day
    set year  [set ${ns}::year]
    set month [set ${ns}::month]
    set cb    [set ${ns}::callback]
    _dp_render $parent
    uplevel #0 $cb [list [list $year $month $day]]
}

proc _dp_nav {parent dir} {
    # Cover the canvas with a solid frame matching the background colour.
    # This prevents X11 from painting intermediate canvas states during
    # the item reposition loop — the cover is a single widget that paints
    # in one expose event, hiding the canvas behind it until done.
    set ns ::ttkbootstrap::dp::$parent
    set c  [set ${ns}::canvas]
    set bg [ttkbootstrap::getColor bg]
    set cover [frame $parent.navcover -bg $bg]
    place $cover -in $c -relx 0 -rely 0 -relwidth 1 -relheight 1
    raise $cover
    update idletasks
    if {$dir eq "next"} {
        _dp_nextmonth $parent
    } elseif {$dir eq "prev"} {
        _dp_prevmonth $parent
    } else {
        _dp_gotoday $parent
    }
    destroy $cover
}

proc _dp_prevmonth {parent} {
    set ns ::ttkbootstrap::dp::$parent
    set year  [set ${ns}::year]
    set month [set ${ns}::month]
    incr month -1
    if {$month < 1} { set month 12; incr year -1 }
    set ${ns}::year  $year
    set ${ns}::month $month
    set ${ns}::selday 0
    _dp_render $parent
}

proc _dp_nextmonth {parent} {
    set ns ::ttkbootstrap::dp::$parent
    set year  [set ${ns}::year]
    set month [set ${ns}::month]
    incr month
    if {$month > 12} { set month 1; incr year }
    set ${ns}::year  $year
    set ${ns}::month $month
    set ${ns}::selday 0
    _dp_render $parent
}

proc _dp_gotoday {parent} {
    set ns ::ttkbootstrap::dp::$parent
    lassign [_date_today] y m d
    set ${ns}::year  $y
    set ${ns}::month $m
    set ${ns}::selday $d
    _dp_render $parent
    set cb [set ${ns}::callback]
    uplevel #0 $cb [list [list $y $m $d]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Date utilities
# ─────────────────────────────────────────────────────────────────────────────
proc _date_today {} {
    set t [clock seconds]
    return [list \
        [clock format $t -format %Y] \
        [clock format $t -format %m] \
        [clock format $t -format %d]]
}

proc _date_format {year month day fmt} {
    set t [clock scan [format "%04d-%02d-%02d" $year $month $day] \
        -format "%Y-%m-%d"]
    return [clock format $t -format $fmt]
}

# Day of week: 0=Monday
proc _date_dow {year month day} {
    set t [clock scan [format "%04d-%02d-%02d" $year $month $day] \
        -format "%Y-%m-%d"]
    set dow [clock format $t -format %u]  ;# 1=Mon .. 7=Sun
    return [expr {$dow - 1}]
}

# Days in month
proc _date_dim {year month} {
    if {$month == 12} {
        set next [clock scan "1 January [expr {$year+1}]" -format "%d %B %Y"]
    } else {
        set next [clock scan "1 [lindex {x January February March April May June July August September October November December} [expr {$month+1}]] $year" -format "%d %B %Y"]
    }
    set first [clock scan [format "%04d-%02d-01" $year $month] -format "%Y-%m-%d"]
    return [expr {int(($next - $first) / 86400)}]
}

} ;# end namespace
