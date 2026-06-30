# =============================================================================
# timepicker.tcl — Entry + clock-face popup for hour/minute/second selection
#
# USAGE
#   ttkbootstrap::TimePicker .tp \
#       -bootstyle   primary \
#       -textvariable ::my_time \
#       -timeformat  "%H:%M" \
#       -command     { puts "Time: $::my_time" }
#   pack .tp
#
#   .tp.get              → current time string per -timeformat
#   .tp.set "14:30"      → set programmatically
#
# OPTIONS
#   -bootstyle    color    Accent colour (default: primary)
#   -textvariable varname  Linked variable
#   -timeformat   string   strftime-style format (default: %H:%M)
#                          Supported: %H (24h), %I (12h), %M (minutes),
#                                     %S (seconds), %p (AM/PM)
#   -width        int      Entry width in characters (default: 8)
#   -command      script   Called when time is selected
#   -state        normal|disabled|readonly
#   -seconds      0|1      Show seconds spinbox (default: 0)
#   -ampm         0|1      Show AM/PM toggle (default: auto from format)
# =============================================================================

namespace eval ttkbootstrap {

proc TimePicker {w args} {
    array set opts {
        -bootstyle    primary
        -textvariable {}
        -timeformat   {%H:%M}
        -width        8
        -command      {}
        -state        normal
        -seconds      0
        -ampm         {}
    }
    array set opts $args

    # Auto-detect AM/PM mode from format string
    if {$opts(-ampm) eq {}} {
        set opts(-ampm) [expr {[string match *%p* $opts(-timeformat)] || \
                               [string match *%I* $opts(-timeformat)]}]
    }

    set ns ::ttkbootstrap::tp::$w
    namespace eval $ns {}
    set ${ns}::opts      [array get opts]
    set ${ns}::popupOpen 0

    # Internal textvariable
    ttk::frame $w
    if {$opts(-textvariable) ne {}} {
        set ${ns}::textvar $opts(-textvariable)
    } else {
        set ${ns}::textvar ${ns}::entrytext
        set ${ns}::entrytext {}
    }

    set entry [ttk::entry $w.entry \
        -textvariable [set ${ns}::textvar] \
        -width        $opts(-width) \
        -state        $opts(-state) \
        -style        "$opts(-bootstyle).TEntry"]

    # Use the self-contained SVG clock icon (no emoji font needed)
    # Clock icon sized to match entry field height
    set _fn_tmp [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set _fs_tmp [ttkbootstrap::_sf 12]
    set _ls_tmp [font metrics [list $_fn_tmp $_fs_tmp] -linespace]
    set _icon_sz [expr {$_ls_tmp + [ttkbootstrap::_sp 4]}]
    set _tp_iscale [expr {$_icon_sz / 16.0}]
    set _clk_img [ttkbootstrap::img::get icon.clock         [ttkbootstrap::_contrastFg [ttkbootstrap::getColor $opts(-bootstyle)]]         $_tp_iscale]
    set btn [ttk::button $w.btn \
        -image   $_clk_img \
        -style   "$opts(-bootstyle).TButton" \
        -padding [ttkbootstrap::_sp2 4 2] \
        -command [list ttkbootstrap::_tp_popup $w]]

    pack $entry -side left -fill x -expand 1
    pack $btn   -side left -padx [ttkbootstrap::_sp2 2 0]

    set ${ns}::entry $entry
    set ${ns}::btn   $btn

    # Seed with current time if variable is empty
    set var [set ${ns}::textvar]
    if {[set $var] eq {}} {
        set $var [clock format [clock seconds] -format $opts(-timeformat)]
    }

    bind $entry <<ThemeChanged>> [list ttkbootstrap::_tp_restyle $w]
    bind $w     <Destroy>        [list catch [list namespace delete $ns]]

    interp alias {} ${w}.get       {} ttkbootstrap::_tp_get $w
    interp alias {} ${w}.set       {} ttkbootstrap::_tp_set $w
    interp alias {} ${w}.configure {} ttkbootstrap::_tp_configure $w

    return $w
}

# ── Popup ─────────────────────────────────────────────────────────────────────
proc _tp_popup {w} {
    set ns ::ttkbootstrap::tp::$w
    if {![namespace exists $ns]} return
    array set o [set ${ns}::opts]

    # Close if already open
    set popup ${w}.__timepicker
    if {[winfo exists $popup]} {
        destroy $popup
        set ${ns}::popupOpen 0
        return
    }

    set popup [toplevel $popup -relief flat -borderwidth [ttkbootstrap::_sp 1]]
    wm overrideredirect $popup 1
    catch { wm attributes $popup -topmost 1 }
    wm withdraw $popup

    set ${ns}::popupOpen 1
    set ${ns}::popup     $popup

    # Parse current value
    set cur [_tp_get $w]
    lassign [_tp_parse $w $cur] h m s ampm_val

    set bg  [ttkbootstrap::getColor bg]
    set fg  [ttkbootstrap::getColor fg]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    set cfg [ttkbootstrap::_contrastFg $hex]
    $popup configure -background $hex

    # ── Header ────────────────────────────────────────────────────────────────
    set hdr [frame $popup.hdr -background $hex -padx [ttkbootstrap::_sp 12] \
        -pady [ttkbootstrap::_sp 8]]
    pack $hdr -fill x

    label $hdr.lbl \
        -text       "Select Time" \
        -background $hex \
        -foreground $cfg \
        -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                         [ttkbootstrap::_sf 12] bold]
    pack $hdr.lbl -side left

    # ── Spinbox area ──────────────────────────────────────────────────────────
    set body [ttk::frame $popup.body -padding [ttkbootstrap::_sp2 12 10]]
    pack $body -fill both -expand 1

    # Hour
    set hmax [expr {$o(-ampm) ? 12 : 23}]
    set hmin [expr {$o(-ampm) ? 1  : 0}]

    set ${ns}::sv_h  $h
    set ${ns}::sv_m  $m
    set ${ns}::sv_s  $s
    set ${ns}::sv_ap $ampm_val

    set sb_h [ttk::spinbox $body.h \
        -from $hmin -to $hmax -increment 1 \
        -textvariable ${ns}::sv_h \
        -width 3 -justify center \
        -format "%02.0f" \
        -style "$o(-bootstyle).TSpinbox" \
        -command [list ttkbootstrap::_tp_preview $w]]
    $sb_h configure -validate key \
        -validatecommand {string is integer %P}

    set colon1 [label $body.c1 -text ":" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                   [ttkbootstrap::_sf 15] bold]]

    set sb_m [ttk::spinbox $body.m \
        -from 0 -to 59 -increment 1 \
        -textvariable ${ns}::sv_m \
        -width 3 -justify center \
        -format "%02.0f" \
        -style "$o(-bootstyle).TSpinbox" \
        -command [list ttkbootstrap::_tp_preview $w]]

    pack $sb_h $colon1 $sb_m -side left -padx [ttkbootstrap::_sp 2]

    # Seconds (optional)
    if {$o(-seconds)} {
        set colon2 [label $body.c2 -text ":" \
            -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                       [ttkbootstrap::_sf 15] bold]]
        set sb_s [ttk::spinbox $body.s \
            -from 0 -to 59 -increment 1 \
            -textvariable ${ns}::sv_s \
            -width 3 -justify center \
            -format "%02.0f" \
            -style "$o(-bootstyle).TSpinbox" \
            -command [list ttkbootstrap::_tp_preview $w]]
        pack $colon2 $sb_s -side left -padx [ttkbootstrap::_sp 2]
    }

    # AM/PM toggle
    if {$o(-ampm)} {
        set ap_frame [ttk::frame $body.ap]
        pack $ap_frame -side left -padx [ttkbootstrap::_sp 6]
        foreach ap {AM PM} {
            ttk::radiobutton $ap_frame.r$ap \
                -text     $ap \
                -value    $ap \
                -variable ${ns}::sv_ap \
                -style    "$o(-bootstyle).TRadiobutton" \
                -command  [list ttkbootstrap::_tp_preview $w]
            pack $ap_frame.r$ap -fill x
        }
    }

    # ── Quick presets ──────────────────────────────────────────────────────────
    set qrow [ttk::frame $popup.quick -padding [ttkbootstrap::_sp2 8 6]]
    pack $qrow -fill x

    foreach {label h_v m_v} {
        "Now"    -1  -1
        "Noon"   12   0
        "6 AM"    6   0
        "6 PM"   18   0
    } {
        ttk::button $qrow.q[string map {{ } _} $label] \
            -text    $label \
            -style   "secondary.Outline.TButton" \
            -padding [ttkbootstrap::_sp2 6 2] \
            -command [list ttkbootstrap::_tp_quick $w $h_v $m_v]
        pack $qrow.q[string map {{ } _} $label] -side left \
            -padx [ttkbootstrap::_sp 2]
    }

    # ── OK / Cancel ────────────────────────────────────────────────────────────
    set foot [ttk::frame $popup.foot -padding [ttkbootstrap::_sp2 8 8]]
    pack $foot -fill x

    ttk::button $foot.ok \
        -text    "OK" \
        -style   "$o(-bootstyle).TButton" \
        -padding [ttkbootstrap::_sp2 16 4] \
        -command [list ttkbootstrap::_tp_commit $w]
    ttk::button $foot.cancel \
        -text    "Cancel" \
        -style   "secondary.Outline.TButton" \
        -padding [ttkbootstrap::_sp2 12 4] \
        -command [list ttkbootstrap::_tp_close $w]
    pack $foot.cancel -side right -padx [ttkbootstrap::_sp 4]
    pack $foot.ok     -side right

    # ── Bind spinbox keys ──────────────────────────────────────────────────────
    foreach sb [list $sb_h $sb_m] {
        bind $sb <Return> [list ttkbootstrap::_tp_commit $w]
        bind $sb <Escape> [list ttkbootstrap::_tp_close  $w]
        bind $sb <<Decrement>> [list after idle [list ttkbootstrap::_tp_preview $w]]
        bind $sb <<Increment>> [list after idle [list ttkbootstrap::_tp_preview $w]]
    }

    # ── Position below the button ──────────────────────────────────────────────
    update idletasks
    set bx  [winfo rootx [set ${ns}::btn]]
    set by  [winfo rooty [set ${ns}::btn]]
    set bh  [winfo height [set ${ns}::btn]]
    set pw  [winfo reqwidth  $popup]
    set ph  [winfo reqheight $popup]
    set sw  [winfo screenwidth  $popup]
    set sh  [winfo screenheight $popup]

    set px  [expr {min($bx, $sw - $pw - 4)}]
    set py  [expr {$by + $bh + [ttkbootstrap::_sp 2]}]
    if {$py + $ph > $sh} { set py [expr {$by - $ph - 2}] }

    wm geometry $popup "+${px}+${py}"
    wm deiconify $popup
    raise $popup
    focus $body.h

    # Close on click outside
    bind $popup <FocusOut> [list after 200 [list ttkbootstrap::_tp_focusout $w $popup]]
}

proc _tp_parse {w timestr} {
    # Returns {hour minute second ampm}
    set ns ::ttkbootstrap::tp::$w
    array set o [set ${ns}::opts]

    # Try to scan the time string using the format
    set h 12; set m 0; set s 0; set ap "AM"
    if {$timestr ne {}} {
        # Extract numeric groups
        if {[regexp {(\d+):(\d+)(?::(\d+))?(?:\s*(AM|PM|am|pm))?} $timestr \
                -> hh mm ss aapp]} {
            set h [expr {int($hh)}]
            set m [expr {int($mm)}]
            if {$ss ne {}} { set s [expr {int($ss)}] }
            if {$aapp ne {}} { set ap [string toupper $aapp] }
        }
    }

    # Convert 24h → 12h if ampm mode
    if {$o(-ampm) && $h >= 12} {
        set ap "PM"
        if {$h > 12} { set h [expr {$h - 12}] }
    } elseif {$o(-ampm) && $h == 0} {
        set h 12; set ap "AM"
    }

    return [list $h $m $s $ap]
}

proc _tp_format {w} {
    # Build time string from current spinbox values
    set ns ::ttkbootstrap::tp::$w
    if {![namespace exists $ns]} return {}
    array set o [set ${ns}::opts]

    set h  [set ${ns}::sv_h]
    set m  [set ${ns}::sv_m]
    set s  [set ${ns}::sv_s]
    set ap [set ${ns}::sv_ap]

    # Clamp values
    if {$o(-ampm)} {
        set h [expr {max(1,  min(12, int($h)))}]
        # Convert to 24h for clock scan
        set h24 $h
        if {$ap eq "PM" && $h < 12} { set h24 [expr {$h + 12}] }
        if {$ap eq "AM" && $h == 12} { set h24 0 }
    } else {
        set h  [expr {max(0,  min(23, int($h)))}]
        set h24 $h
    }
    set m [expr {max(0, min(59, int($m)))}]
    set s [expr {max(0, min(59, int($s)))}]

    # Build via clock scan/format for correct strftime handling
    set base [clock scan "${h24}:${m}:${s}" -format %H:%M:%S]
    set result [clock format $base -format $o(-timeformat)]

    # Re-store clamped values
    set ${ns}::sv_h $h
    set ${ns}::sv_m $m
    set ${ns}::sv_s $s

    return $result
}

proc _tp_preview {w} {
    # Update the entry live as spinboxes change
    set ns ::ttkbootstrap::tp::$w
    if {![namespace exists $ns]} return
    after idle [list catch [list set [set ${ns}::textvar] \
        [ttkbootstrap::_tp_format $w]]]
}

proc _tp_quick {w h m} {
    set ns ::ttkbootstrap::tp::$w
    if {![namespace exists $ns]} return
    if {$h == -1} {
        # "Now"
        set h [clock format [clock seconds] -format %H]
        set m [clock format [clock seconds] -format %M]
    }
    array set o [set ${ns}::opts]
    if {$o(-ampm)} {
        set ap [expr {$h >= 12 ? "PM" : "AM"}]
        if {$h > 12} { set h [expr {$h - 12}] } elseif {$h == 0} { set h 12 }
        set ${ns}::sv_ap $ap
    }
    set ${ns}::sv_h $h
    set ${ns}::sv_m $m
    set ${ns}::sv_s 0
    _tp_preview $w
}

proc _tp_commit {w} {
    set ns ::ttkbootstrap::tp::$w
    if {![namespace exists $ns]} return
    array set o [set ${ns}::opts]
    set val [_tp_format $w]
    set [set ${ns}::textvar] $val
    if {$o(-command) ne {}} { uplevel #0 $o(-command) }
    _tp_close $w
}

proc _tp_close {w} {
    set ns ::ttkbootstrap::tp::$w
    if {![namespace exists $ns]} return
    set popup ${w}.__timepicker
    catch { destroy $popup }
    set ${ns}::popupOpen 0
}

proc _tp_focusout {w popup} {
    if {![winfo exists $popup]} return
    set focused [focus]
    if {$focused eq {} || ![string match ${popup}* $focused]} {
        ttkbootstrap::_tp_close $w
    }
}

proc _tp_get {w} {
    set ns ::ttkbootstrap::tp::$w
    if {![namespace exists $ns]} return {}
    return [set [set ${ns}::textvar]]
}

proc _tp_set {w timestr} {
    set ns ::ttkbootstrap::tp::$w
    if {![namespace exists $ns]} return
    array set o [set ${ns}::opts]
    # Validate by trying to parse
    lassign [_tp_parse $w $timestr] h m s ap
    set ${ns}::sv_h $h
    set ${ns}::sv_m $m
    set ${ns}::sv_s $s
    set ${ns}::sv_ap $ap
    set [set ${ns}::textvar] [_tp_format $w]
}

proc _tp_configure {w args} {
    set ns ::ttkbootstrap::tp::$w
    if {![namespace exists $ns]} return
    array set o [set ${ns}::opts]
    array set o $args
    set ${ns}::opts [array get o]
    _tp_restyle $w
}

proc _tp_restyle {w} {
    set ns ::ttkbootstrap::tp::$w
    if {![namespace exists $ns]} return
    array set o [set ${ns}::opts]
    set entry [set ${ns}::entry]
    set btn   [set ${ns}::btn]
    catch { $entry configure -style "$o(-bootstyle).TEntry" }
    catch {
        set fg [ttkbootstrap::_contrastFg [ttkbootstrap::getColor $o(-bootstyle)]]
        set img [ttkbootstrap::img::get icon.clock $fg [ttkbootstrap::img::size]]
        $btn configure -style "$o(-bootstyle).TButton" -image $img
    }
}

} ;# end namespace ttkbootstrap
