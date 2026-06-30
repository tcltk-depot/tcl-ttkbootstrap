# =============================================================================
# autocomplete.tcl — Entry with a live-filtered suggestion dropdown
#
# USAGE
#   ttkbootstrap::AutocompleteEntry .ac \
#       -values      {Apple Banana Cherry Grape Mango} \
#       -bootstyle   primary \
#       -textvariable myVar \
#       -command     {puts "selected: $myVar"}
#   pack .ac -fill x
#
# OPTIONS
#   -values       list        Static list of suggestions
#   -valuescmd    script      Dynamic: called with current text, must return list
#   -textvariable varname     Linked variable (updated on selection)
#   -bootstyle    color       Entry and highlight colour (default primary)
#   -completevalue 0|1        If 1, select first match on Tab/Return (default 1)
#   -maxitems     int         Max rows shown in dropdown (default 8)
#   -command      script      Called when user selects a value
#   -width        int         Entry width in characters (default 20)
#   -state        normal|disabled|readonly
#
# METHODS
#   $w get                 — current entry text
#   $w set value           — set entry text programmatically
#   $w configure ?opts?
#   $w cget option
# =============================================================================

namespace eval ttkbootstrap {

proc AutocompleteEntry {w args} {
    array set opts {
        -values        {}
        -valuescmd     {}
        -textvariable  {}
        -bootstyle     primary
        -completevalue 1
        -maxitems      8
        -command       {}
        -width         20
        -state         normal
    }
    array set opts $args

    set ns ::ttkbootstrap::ac::$w
    namespace eval $ns {}
    array set ${ns}::opts [array get opts]
    set ${ns}::popup    {}
    set ${ns}::after_id {}
    set ${ns}::inhibit  0  ;# prevent trace firing during programmatic set

    # Private textvariable if none supplied
    if {$opts(-textvariable) eq {}} {
        set ${ns}::text {}
        set ${ns}::opts(-textvariable) ${ns}::text
    }

    set entry [ttk::entry $w \
        -textvariable $opts(-textvariable) \
        -width        $opts(-width) \
        -style        "$opts(-bootstyle).TEntry" \
        -state        $opts(-state)]

    set ${ns}::entry $entry

    # Trace on the variable to trigger filtering
    trace add variable $opts(-textvariable) write [list ttkbootstrap::_ac_trace $w]

    # Remove trace and close popup when entry widget is destroyed
    bind $entry <Destroy> [list ttkbootstrap::_ac_destroy $w $opts(-textvariable)]

    bind $entry <KeyRelease>   [list ttkbootstrap::_ac_keyrelease $w %K]
    bind $entry <FocusOut>     [list after 200 [list ttkbootstrap::_ac_close $w]]
    bind $entry <Escape>       [list ttkbootstrap::_ac_close $w]
    bind $entry <Return>       [list ttkbootstrap::_ac_complete_first $w]
    bind $entry <Tab>          [list ttkbootstrap::_ac_complete_first $w]
    bind $entry <<ThemeChanged>> [list ttkbootstrap::_ac_restyle $w]

    return $w
}

proc _ac_trace {w args} {
    set ns ::ttkbootstrap::ac::$w
    if {![namespace exists $ns]} return
    if {![winfo exists $w]} return
    if {[set ${ns}::inhibit]} return
    # Debounce: schedule filter on idle
    set aid [set ${ns}::after_id]
    if {$aid ne {}} { catch {after cancel $aid} }
    set ${ns}::after_id [after 50 [list ttkbootstrap::_ac_filter $w]]
}

proc _ac_keyrelease {w key} {
    # Down arrow moves focus into the listbox
    if {$key eq "Down"} {
        set ns ::ttkbootstrap::ac::$w
        set pop [set ${ns}::popup]
        if {$pop ne {} && [winfo exists $pop]} {
            focus $pop.lb
            $pop.lb selection set 0
            $pop.lb activate 0
        }
    }
}

proc _ac_filter {w} {
    set ns ::ttkbootstrap::ac::$w
    set ${ns}::after_id {}
    array set o [array get ${ns}::opts]

    set text [string tolower [set $o(-textvariable)]]

    # Get candidate list
    if {$o(-valuescmd) ne {}} {
        set candidates [uplevel #0 $o(-valuescmd) [list $text]]
    } else {
        set candidates {}
        foreach v $o(-values) {
            if {$text eq {} || [string match -nocase "*${text}*" $v]} {
                lappend candidates $v
            }
        }
    }

    if {$candidates eq {} || $text eq {}} {
        _ac_close $w
        return
    }

    _ac_show $w $candidates
}

proc _ac_show {w candidates} {
    set ns ::ttkbootstrap::ac::$w
    array set o [array get ${ns}::opts]
    set entry [set ${ns}::entry]

    set pop [set ${ns}::popup]

    # Create or reuse popup toplevel
    if {$pop eq {} || ![winfo exists $pop]} {
        set pop [toplevel ${w}.__acpop -relief flat -borderwidth 0]
        wm overrideredirect $pop 1
        catch { wm attributes $pop -topmost 1 }
        set ${ns}::popup $pop

        # Scrolled listbox
        set lb [listbox $pop.lb \
            -selectmode   single \
            -activestyle  none \
            -relief       flat \
            -borderwidth  0 \
            -highlightthickness 0 \
            -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                        [ttkbootstrap::_sf 12]]]
        set sb [ttk::scrollbar $pop.sb \
            -orient  vertical \
            -style   "$o(-bootstyle).Vertical.TScrollbar" \
            -command [list $lb yview]]
        $lb configure -yscrollcommand [list $sb set]

        pack $lb -side left  -fill both -expand 1
        pack $sb -side right -fill y

        bind $lb <ButtonRelease-1> [list ttkbootstrap::_ac_select $w]
        bind $lb <Return>          [list ttkbootstrap::_ac_select $w]
        bind $lb <Escape>          [list ttkbootstrap::_ac_close  $w]
        bind $lb <FocusOut>        [list after 200 [list ttkbootstrap::_ac_close $w]]
    }

    set lb $pop.lb

    # Apply theme colours
    set bg  [ttkbootstrap::getColor inputbg]
    set fg  [ttkbootstrap::getColor inputfg]
    set sel [ttkbootstrap::getColor primary]
    set sfc [ttkbootstrap::_contrastFg $sel]
    $lb configure -background $bg -foreground $fg \
        -selectbackground $sel -selectforeground $sfc

    # Populate
    $lb delete 0 end
    set shown [expr {min([llength $candidates], $o(-maxitems))}]
    foreach c [lrange $candidates 0 [expr {$shown-1}]] {
        $lb insert end $c
    }

    # Size and position below the entry
    set ew  [winfo width  $entry]
    set eh  [winfo height $entry]
    set ex  [winfo rootx  $entry]
    set ey  [winfo rooty  $entry]
    set rh  [expr {[ttkbootstrap::_sf 12] * 2 + [ttkbootstrap::_sp 4]}]
    set ph  [expr {$shown * $rh + [ttkbootstrap::_sp 4]}]
    set pw  [expr {max($ew, [ttkbootstrap::_sp 120])}]

    # Show scrollbar only if truncated
    if {[llength $candidates] > $o(-maxitems)} {
        pack $pop.sb -side right -fill y
    } else {
        pack forget $pop.sb
    }

    wm geometry $pop "${pw}x${ph}+${ex}+[expr {$ey+$eh}]"
    wm deiconify $pop
    raise $pop
}

proc _ac_select {w} {
    set ns ::ttkbootstrap::ac::$w
    set pop [set ${ns}::popup]
    if {$pop eq {} || ![winfo exists $pop]} return
    set lb $pop.lb
    set sel [$lb curselection]
    if {$sel eq {}} return
    set val [$lb get [lindex $sel 0]]
    _ac_set_value $w $val
    _ac_close $w
    focus [set ${ns}::entry]
}

proc _ac_complete_first {w} {
    set ns ::ttkbootstrap::ac::$w
    array set o [array get ${ns}::opts]
    if {!$o(-completevalue)} return
    set pop [set ${ns}::popup]
    if {$pop eq {} || ![winfo exists $pop]} return
    set lb $pop.lb
    if {[$lb size] > 0} {
        set val [$lb get 0]
        _ac_set_value $w $val
        _ac_close $w
    }
}

proc _ac_set_value {w val} {
    set ns ::ttkbootstrap::ac::$w
    array set o [array get ${ns}::opts]
    set ${ns}::inhibit 1
    set $o(-textvariable) $val
    set ${ns}::inhibit 0
    if {$o(-command) ne {}} { uplevel #0 $o(-command) }
}

proc _ac_close {w} {
    set ns ::ttkbootstrap::ac::$w
    if {![namespace exists $ns]} return
    set pop [set ${ns}::popup]
    if {$pop ne {} && [winfo exists $pop]} {
        wm withdraw $pop
    }
}

proc _ac_destroy {w var} {
    catch { trace remove variable $var write [list ttkbootstrap::_ac_trace $w] }
    catch { ttkbootstrap::_ac_close $w }
    catch { namespace delete ::ttkbootstrap::ac::$w }
}

proc _ac_restyle {w} {
    set ns ::ttkbootstrap::ac::$w
    if {![namespace exists $ns]} return
    array set o [array get ${ns}::opts]
    set entry [set ${ns}::entry]
    if {[winfo exists $entry]} {
        $entry configure -style "$o(-bootstyle).TEntry"
    }
}

} ;# end namespace ttkbootstrap
